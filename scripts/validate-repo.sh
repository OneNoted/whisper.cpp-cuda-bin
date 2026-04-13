#!/usr/bin/env bash
set -euo pipefail

bash -n PKGBUILD scripts/*.sh

generated=$(mktemp)
trap 'rm -f "$generated"' EXIT

if [[ ${EUID} -eq 0 ]]; then
  su nobody -s /bin/sh -c 'makepkg --printsrcinfo' > "$generated"
else
  makepkg --printsrcinfo > "$generated"
fi

diff -u .SRCINFO "$generated"
