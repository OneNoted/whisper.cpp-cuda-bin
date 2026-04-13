#!/usr/bin/env bash
set -euo pipefail

whisper_asset=${1:?usage: smoke-asset.sh <whisper-asset> <libggml-asset>}
libggml_asset=${2:?usage: smoke-asset.sh <whisper-asset> <libggml-asset>}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

bsdtar -xf "$libggml_asset" -C "$root"
bsdtar -xf "$whisper_asset" -C "$root"

required_paths=(
  "usr/bin/whisper-cli"
  "usr/lib/libwhisper.so"
  "usr/share/licenses/whisper.cpp-cuda-bin/LICENSE"
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "$root/$path" ]]; then
    printf 'missing required path: %s\n' "$path" >&2
    exit 1
  fi
done

export LD_LIBRARY_PATH="$root/usr/lib:$root/usr/lib/glibc-hwcaps/x86-64-v3"
"$root/usr/bin/whisper-cli" --help >/dev/null
printf 'Asset smoke check passed for %s\n' "$whisper_asset"

