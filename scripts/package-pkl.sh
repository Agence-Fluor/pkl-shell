#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
output_path=${1:-pkg}
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT HUP INT TERM

mkdir -p "$stage/lib/bin"
cp lib/PklProject lib/shell.pkl lib/install.pkl "$stage/lib/"

for os in linux darwin freebsd; do
  for arch in amd64 arm64; do
    binary="dist/pkl-shell-$os-$arch"
    if [ ! -x "$binary" ]; then
      echo "Missing $binary; run sh scripts/build-unix.sh first" >&2
      exit 1
    fi
    cp "$binary" "$stage/lib/bin/"
  done
done

pkl project package --skip-publish-check --output-path "$output_path" "$stage/lib"
