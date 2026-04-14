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
  HOME="$temp_home" setpriv --reuid 65534 --regid 65534 --clear-groups \
    makepkg --printsrcinfo
}

print_srcinfo > "$generated"

diff -u .SRCINFO "$generated"
