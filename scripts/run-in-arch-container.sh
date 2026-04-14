#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  printf 'usage: %s <shell-command>\n' "${0##*/}" >&2
  exit 1
fi

image=${ARCH_CONTAINER_IMAGE:-archlinux:base-devel}
workspace=/workspace

docker run --rm \
  --network host \
  --volume "$PWD":"$workspace" \
  --workdir "$workspace" \
  --env CI=true \
  --env HOME=/tmp/home \
  "$image" \
  bash -lc "$*"
