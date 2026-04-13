#!/usr/bin/env bash
set -euo pipefail

bash -n PKGBUILD scripts/*.sh

generated=$(mktemp)
trap 'rm -f "$generated"' EXIT

makepkg --printsrcinfo > "$generated"
diff -u .SRCINFO "$generated"

