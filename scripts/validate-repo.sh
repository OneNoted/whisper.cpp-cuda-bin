#!/usr/bin/env bash
set -euo pipefail

bash -n PKGBUILD scripts/*.sh

generated=$(mktemp)
trap 'rm -f "$generated"' EXIT

print_srcinfo() {
  if [[ ${EUID} -ne 0 ]]; then
    makepkg --printsrcinfo
    return
  fi

  local temp_home
  temp_home=$(mktemp -d)
  trap 'rm -rf "$temp_home"' RETURN
  mkdir -p "$temp_home"/build "$temp_home"/log "$temp_home"/pkg "$temp_home"/src "$temp_home"/srcpkg
  chown -R 65534:65534 "$temp_home"
  HOME="$temp_home" \
  BUILDDIR="$temp_home/build" \
  LOGDEST="$temp_home/log" \
  PKGDEST="$temp_home/pkg" \
  SRCDEST="$temp_home/src" \
  SRCPKGDEST="$temp_home/srcpkg" \
    setpriv --reuid 65534 --regid 65534 --clear-groups makepkg --printsrcinfo
}

print_srcinfo > "$generated"

diff -u .SRCINFO "$generated"
