#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
mkdir -p dist

if [ "$#" -eq 0 ]; then
  targets="linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 freebsd/amd64 freebsd/arm64"
elif [ "$#" -eq 1 ] && [ "$1" = "--host" ]; then
  case $(uname -s) in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    FreeBSD) os=freebsd ;;
    *) echo "Unsupported operating system: $(uname -s)" >&2; exit 1 ;;
  esac
  case $(uname -m) in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
  targets="$os/$arch"
else
  echo "Usage: $0 [--host]" >&2
  exit 2
fi

for target in $targets; do
  os=${target%/*}
  arch=${target#*/}
  output="dist/pkl-shell-$os-$arch"
  echo "Building $output"
  CGO_ENABLED=0 GOOS="$os" GOARCH="$arch" go build -trimpath -buildvcs=false -o "$output" .
done
