#!/usr/bin/env bash
set -euo pipefail

version="${1:-0.22.1}"
dest="${2:-.bin}"
version="${version#v}"

if [[ ! "$version" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then
    echo "invalid Zola version: $version" >&2
    exit 1
fi

case "$(uname -s)" in
    Darwin)
        os="apple-darwin"
        ;;
    Linux)
        os="unknown-linux-gnu"
        ;;
    *)
        echo "unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    x86_64 | amd64)
        arch="x86_64"
        ;;
    arm64 | aarch64)
        arch="aarch64"
        ;;
    *)
        echo "unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

url="https://github.com/getzola/zola/releases/download/v${version}/zola-v${version}-${arch}-${os}.tar.gz"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$dest"
if [[ -x "$dest/zola" ]] && [[ "$("$dest/zola" --version)" == "zola $version" ]]; then
    "$dest/zola" --version
    exit 0
fi

curl --fail --show-error --silent --location \
    --connect-timeout 20 \
    --max-time 300 \
    --retry 3 \
    --retry-delay 2 \
    --retry-all-errors \
    "$url" \
    -o "$tmp_dir/zola.tar.gz"
tar -xzf "$tmp_dir/zola.tar.gz" -C "$tmp_dir"
test -x "$tmp_dir/zola"
install -m 0755 "$tmp_dir/zola" "$dest/zola"
"$dest/zola" --version
