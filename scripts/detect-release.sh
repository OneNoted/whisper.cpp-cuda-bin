#!/usr/bin/env bash
set -euo pipefail

current_pkgver=$(awk -F= '/^pkgver=/{print $2; exit}' PKGBUILD)
current_pkgrel=$(awk -F= '/^pkgrel=/{print $2; exit}' PKGBUILD)
current_libggml_pkgver=$(awk -F= '/^_libggml_pkgver=/{print $2; exit}' PKGBUILD)
current_libggml_pkgrel=$(awk -F= '/^_libggml_pkgrel=/{print $2; exit}' PKGBUILD)

force_release=${FORCE_RELEASE:-false}
pkgrel_override=${PKGREL_OVERRIDE:-}
upstream_version_override=${UPSTREAM_VERSION_OVERRIDE:-}
libggml_release_override=${LIBGGML_RELEASE_OVERRIDE:-}
upstream_release_api=${UPSTREAM_RELEASE_API:-https://api.github.com/repos/ggml-org/whisper.cpp/releases?per_page=100}
libggml_release_api=${LIBGGML_RELEASE_API:-https://api.github.com/repos/OneNoted/libggml-cuda-bin/releases/latest}
release_download_url=${RELEASE_DOWNLOAD_URL:-https://github.com/OneNoted/whisper.cpp-cuda-bin/releases/download}

if [[ -n "$upstream_version_override" ]]; then
  latest_pkgver=${upstream_version_override#v}
else
  latest_pkgver=$(
    curl --retry 3 -fsSL "$upstream_release_api" |
      jq -er 'map(select(.draft == false and .prerelease == false and (.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$")))) | first | .tag_name' |
      sed 's/^v//'
  )
fi

if [[ -n "$libggml_release_override" ]]; then
  latest_libggml_release=${libggml_release_override#v}
else
  latest_libggml_release=$(
    curl --retry 3 -fsSL "$libggml_release_api" |
      jq -er '.tag_name' |
      sed 's/^v//'
  )
fi

if [[ ! "$latest_pkgver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ||
      ! "$latest_libggml_release" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[1-9][0-9]*$ ||
      ( -n "$pkgrel_override" && ! "$pkgrel_override" =~ ^[1-9][0-9]*$ ) ]]; then
  printf 'Invalid release version or pkgrel; refusing to build\n' >&2
  exit 1
fi

latest_libggml_pkgver=${latest_libggml_release%-*}
latest_libggml_pkgrel=${latest_libggml_release##*-}

should_release=false
reason="already aligned with latest upstream releases"

if [[ "$latest_pkgver" != "$current_pkgver" ]]; then
  desired_pkgrel=${pkgrel_override:-1}
  should_release=true
  reason="upstream whisper.cpp release changed"
elif [[ "$latest_libggml_pkgver" != "$current_libggml_pkgver" || "$latest_libggml_pkgrel" != "$current_libggml_pkgrel" ]]; then
  desired_pkgrel=${pkgrel_override:-$((10#$current_pkgrel + 1))}
  should_release=true
  reason="libggml-cuda-bin dependency changed"
elif [[ -n "$pkgrel_override" && "$pkgrel_override" != "$current_pkgrel" ]]; then
  desired_pkgrel=$pkgrel_override
  should_release=true
  reason="pkgrel override requested"
elif [[ "$force_release" == "true" ]]; then
  desired_pkgrel=${pkgrel_override:-$((10#$current_pkgrel + 1))}
  should_release=true
  reason="forced rebuild requested"
else
  desired_pkgrel=$current_pkgrel
fi

# Metadata can reach main before publication finishes. Check the public assets
# even when versions match; use a new pkgrel so published binaries stay immutable.
if [[ "$should_release" == false ]]; then
  current_asset="whisper.cpp-cuda-bin-${current_pkgver}-${current_pkgrel}-x86_64.tar.zst"
  for asset in "$current_asset" "$current_asset.sha256" PKGBUILD default.SRCINFO; do
    status=$(curl --retry 3 -sSLI -o /dev/null -w '%{http_code}' \
      "$release_download_url/v${current_pkgver}-${current_pkgrel}/$asset")
    case "$status" in
      200) ;;
      404)
        desired_pkgrel=$((10#$current_pkgrel + 1))
        should_release=true
        reason="repair missing published release asset: $asset"
        break
        ;;
      *)
        printf 'Cannot verify release asset %s: HTTP %s\n' "$asset" "$status" >&2
        exit 1
        ;;
    esac
  done
fi

release_tag="v${latest_pkgver}-${desired_pkgrel}"
asset_name="whisper.cpp-cuda-bin-${latest_pkgver}-${desired_pkgrel}-x86_64.tar.zst"

cat <<EOF
current_pkgver=$current_pkgver
current_pkgrel=$current_pkgrel
current_libggml_pkgver=$current_libggml_pkgver
current_libggml_pkgrel=$current_libggml_pkgrel
pkgver=$latest_pkgver
pkgrel=$desired_pkgrel
libggml_pkgver=$latest_libggml_pkgver
libggml_pkgrel=$latest_libggml_pkgrel
release_tag=$release_tag
asset_name=$asset_name
should_release=$should_release
reason=$reason
EOF
