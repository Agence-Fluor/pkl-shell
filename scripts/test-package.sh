#!/bin/sh
set -eu

repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
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
"$temp/serve-package" "$repo/pkg" >"$temp/server.log" 2>&1 &
server_pid=$!

attempt=0
until curl --silent --fail http://127.0.0.1:8765/pkl-shell@0.1.0 >/dev/null; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 20 ] || ! kill -0 "$server_pid" 2>/dev/null; then
    cat "$temp/server.log" >&2
    echo "Package server did not start" >&2
    exit 1
  fi
  sleep 0.1
done

cat > "$temp/PklProject" <<'EOF'
amends "pkl:Project"

dependencies {
  ["shell"] {
    uri = "package://raw.githubusercontent.com/Agence-Fluor/pkl-shell/main/pkg/pkl-shell@0.1.0"
  }
}

evaluatorSettings {
  moduleCacheDir = ".pkl-cache"
  http {
    rewrites {
      ["https://raw.githubusercontent.com/Agence-Fluor/pkl-shell/main/pkg/"] = "http://127.0.0.1:8765/"
    }
  }
  externalResourceReaders {
    ["shell"] {
      executable = "sh"
      arguments {
        "-ec"
        "reader=.pkl-shell/0.1.0/reader; if [ ! -x \"$reader\" ]; then pkl run @shell/install.pkl >/dev/null; chmod +x \"$reader\"; fi; exec \"$reader\""
      }
    }
  }
}
EOF
cat > "$temp/example.pkl" <<'EOF'
import "@shell/shell.pkl"

result = shell.run("printf self-contained")
EOF

cd "$temp"
pkl project resolve
result=$(pkl eval example.pkl)
test "$result" = 'result = "self-contained"'
test -x .pkl-shell/0.1.0/reader
echo "$result"
