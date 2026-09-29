#!/bin/sh
set -eu

repo=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
package_dir=${1:-"$repo/dist/package"}
version=$(pkl eval --no-project -x 'package.version' "$repo/lib/PklProject")
temp=$(mktemp -d)
server_pid=
cleanup() {
  if [ -n "$server_pid" ]; then
    kill "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$temp"
}
trap cleanup EXIT HUP INT TERM

go build -o "$temp/serve-package" "$repo/scripts/serve-package.go"
"$temp/serve-package" "$package_dir" "$temp/address" >"$temp/server.log" 2>&1 &
server_pid=$!

attempt=0
until [ -s "$temp/address" ]; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 20 ] || ! kill -0 "$server_pid" 2>/dev/null; then
    cat "$temp/server.log" >&2
    echo "Package server did not start" >&2
    exit 1
  fi
  sleep 0.1
done
address=$(cat "$temp/address")
curl --silent --fail "http://$address/pkl-shell@$version" >/dev/null

cat > "$temp/PklProject.template" <<'EOF'
amends "pkl:Project"

dependencies {
  ["shell"] {
    uri = "package://pkg.pkl-lang.org/github.com/Agence-Fluor/pkl-shell/pkl-shell@@VERSION@"
  }
}

evaluatorSettings {
  moduleCacheDir = ".pkl-cache"
  http {
    rewrites {
      ["https://pkg.pkl-lang.org/github.com/Agence-Fluor/pkl-shell/"] = "http://@ADDRESS@/"
      ["https://github.com/Agence-Fluor/pkl-shell/releases/download/pkl-shell@@VERSION@/"] = "http://@ADDRESS@/"
    }
  }
  externalResourceReaders {
    ["shell"] {
      executable = "sh"
      arguments {
        "-ec"
        "reader=.pkl-shell/@VERSION@/reader; if [ ! -x \"$reader\" ]; then pkl run @shell/install.pkl >/dev/null; chmod +x \"$reader\"; fi; exec \"$reader\""
      }
    }
  }
}
EOF
sed -e "s/@VERSION@/$version/g" -e "s/@ADDRESS@/$address/g" "$temp/PklProject.template" > "$temp/PklProject"
cat > "$temp/example.pkl" <<'EOF'
import "@shell/shell.pkl"

result = shell.run("printf self-contained")
EOF

cd "$temp"
pkl project resolve
result=$(pkl eval example.pkl)
test "$result" = 'result = "self-contained"'
test -x ".pkl-shell/$version/reader"
echo "$result"
