#!/usr/bin/env bash
set -euo pipefail

pkgver=${1:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> <asset>}
pkgrel=${2:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> <asset>}
libggml_pkgver=${3:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> <asset>}
libggml_pkgrel=${4:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> <asset>}
asset=${5:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <libggml-pkgver> <libggml-pkgrel> <asset>}
checksum=$(sha256sum "$asset" | awk '{print $1}')

perl -0pi -e "s/^pkgver=.*/pkgver=${pkgver}/m; s/^pkgrel=.*/pkgrel=${pkgrel}/m; s/^_libggml_pkgver=.*/_libggml_pkgver=${libggml_pkgver}/m; s/^_libggml_pkgrel=.*/_libggml_pkgrel=${libggml_pkgrel}/m; s/^sha256sums=\('[^']*'\)/sha256sums=('${checksum}')/m" PKGBUILD

print_srcinfo() {
  if [[ ${EUID} -ne 0 ]]; then
    makepkg --printsrcinfo
    return
  fi

  local temp_home
  temp_home=$(mktemp -d)
  trap 'rm -rf "$temp_home"' RETURN
  HOME="$temp_home" \
  BUILDDIR="$temp_home/build" \
  LOGDEST="$temp_home/log" \
  PKGDEST="$temp_home/pkg" \
  SRCDEST="$temp_home/src" \
  SRCPKGDEST="$temp_home/srcpkg" \
    setpriv --reuid 65534 --regid 65534 --clear-groups makepkg --printsrcinfo
}

print_srcinfo > .SRCINFO

printf 'Updated PKGBUILD and .SRCINFO for %s-%s\n' "$pkgver" "$pkgrel"
