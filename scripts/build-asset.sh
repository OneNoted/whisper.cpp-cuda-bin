#!/usr/bin/env bash
set -euo pipefail

pkgver=${1:?usage: build-asset.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> [out-dir]}
pkgrel=${2:?usage: build-asset.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> [out-dir]}
libggml_pkgver=${3:?usage: build-asset.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> [out-dir]}
libggml_pkgrel=${4:?usage: build-asset.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> [out-dir]}
out_dir=${5:-"$PWD/dist"}

pkgname="whisper.cpp-cuda-bin"
libggml_pkgname="libggml-cuda-bin"
libggml_owner="OneNoted"
upstream_repo="https://github.com/ggml-org/whisper.cpp"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

src_dir="$work_dir/whisper.cpp-$pkgver"
sysroot="$work_dir/sysroot"
install_root="$work_dir/install-root"
asset_name="${pkgname}-${pkgver}-${pkgrel}-x86_64.tar.zst"
asset_path="${out_dir}/${asset_name}"
libggml_asset="${libggml_pkgname}-${libggml_pkgver}-${libggml_pkgrel}-x86_64.tar.zst"
libggml_url="https://github.com/${libggml_owner}/${libggml_pkgname}/releases/download/v${libggml_pkgver}-${libggml_pkgrel}/${libggml_asset}"

mkdir -p "$out_dir" "$sysroot" "$install_root"

curl -fsSL "${upstream_repo}/archive/refs/tags/v${pkgver}.tar.gz" | tar -xz -C "$work_dir"
curl -fsSL "$libggml_url" -o "$work_dir/$libggml_asset"
bsdtar -xf "$work_dir/$libggml_asset" -C "$sysroot"

# talk-llama vendors llama.cpp sources tied to whisper.cpp's bundled ggml.
# It is not compatible with WHISPER_USE_SYSTEM_GGML and is not packaged.
sed -i '/^[[:space:]]*add_subdirectory(talk-llama)[[:space:]]*$/d' \
  "$src_dir/examples/CMakeLists.txt"

cmake \
  -B "$work_dir/build" \
  -S "$src_dir" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_PREFIX_PATH="$sysroot/usr" \
  -DWHISPER_SDL2=ON \
  -DWHISPER_BUILD_SERVER=OFF \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_USE_SYSTEM_GGML=ON

cmake --build "$work_dir/build"
DESTDIR="$install_root" cmake --install "$work_dir/build"

rm -rf "$install_root/usr/share/licenses/whisper.cpp"
install -Dm644 "$src_dir/LICENSE" "$install_root/usr/share/licenses/$pkgname/LICENSE"

TZ=UTC LC_ALL=C tar \
  --sort=name \
  --mtime='UTC 1970-01-01' \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --zstd \
  -cf "$asset_path" \
  -C "$install_root" \
  usr

sha256sum "$asset_path" > "${asset_path}.sha256"
printf 'Built %s\n' "$asset_path"
