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
upstream_release_api=${UPSTREAM_RELEASE_API:-https://api.github.com/repos/ggml-org/whisper.cpp/releases/latest}
libggml_release_api=${LIBGGML_RELEASE_API:-https://api.github.com/repos/OneNoted/libggml-cuda-bin/releases/latest}

if [[ -n "$upstream_version_override" ]]; then
  latest_pkgver=${upstream_version_override#v}
else
  latest_pkgver=$(
    curl -fsSL "$upstream_release_api" |
      jq -r '.tag_name' |
      sed 's/^v//'
  )
fi

if [[ -n "$libggml_release_override" ]]; then
  latest_libggml_release=${libggml_release_override#v}
else
  latest_libggml_release=$(
    curl -fsSL "$libggml_release_api" |
      jq -r '.tag_name' |
      sed 's/^v//'
  )
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
