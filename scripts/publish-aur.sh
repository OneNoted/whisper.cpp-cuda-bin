#!/usr/bin/env bash
set -euo pipefail

aur_remote=${1:?usage: publish-aur.sh <aur-remote>}
pkgname=$(awk -F= '/^pkgname=/{print $2; exit}' PKGBUILD)
pkgver=$(awk -F= '/^pkgver=/{print $2; exit}' PKGBUILD)
pkgrel=$(awk -F= '/^pkgrel=/{print $2; exit}' PKGBUILD)
max_attempts=${AUR_PUBLISH_ATTEMPTS:-10}
retry_delay=${AUR_PUBLISH_RETRY_DELAY:-60}
work_dir=$(mktemp -d)
repo_dir="$work_dir/aur"
trap 'rm -rf "$work_dir"' EXIT

for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  rm -rf "$repo_dir"

  if git clone --depth 1 "$aur_remote" "$repo_dir"; then
    find "$repo_dir" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
    cp PKGBUILD .SRCINFO "$repo_dir/"

    git -C "$repo_dir" config user.name "${GIT_AUTHOR_NAME:-Jonatan Jonasson}"
    git -C "$repo_dir" config user.email "${GIT_AUTHOR_EMAIL:-notes@madeingotland.com}"
    git -C "$repo_dir" add PKGBUILD .SRCINFO

    if git -C "$repo_dir" diff --cached --quiet; then
      printf 'AUR metadata already up to date for %s %s-%s\n' "$pkgname" "$pkgver" "$pkgrel"
      exit 0
    fi

    git -C "$repo_dir" commit -m "update to ${pkgver}-${pkgrel}"
    if git -C "$repo_dir" push origin HEAD:master; then
      printf 'Published %s %s-%s to AUR\n' "$pkgname" "$pkgver" "$pkgrel"
      exit 0
    fi
  fi

  if ((attempt < max_attempts)); then
    printf 'AUR publish attempt %d/%d failed; retrying in %d seconds\n' \
      "$attempt" "$max_attempts" "$retry_delay" >&2
    sleep "$retry_delay"
  fi
done

printf 'AUR publish failed after %d attempts\n' "$max_attempts" >&2
exit 1
