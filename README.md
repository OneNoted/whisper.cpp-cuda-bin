# whisper.cpp-cuda-bin

Binary-packaging repo for the Arch User Repository package
`whisper.cpp-cuda-bin`.

This repo builds a Linux `x86_64` release asset from upstream `whisper.cpp`,
links it against the separately published `libggml-cuda-bin` install tree, and
keeps the AUR metadata next to the release automation so GitHub Actions can
publish both the GitHub release and the AUR update from this repo.

## Why this exists

`whisper.cpp-cuda` currently builds from source in the AUR and depends on a
source-built `libggml-cuda-git`. This repo converts that into a binary package
that depends on a validated `libggml-cuda-bin` release instead.

## Repository layout

- `PKGBUILD`: AUR package recipe
- `.SRCINFO`: generated AUR metadata
- `scripts/build-asset.sh`: build a prepackaged `/usr` tree
- `scripts/detect-release.sh`: resolve the latest `whisper.cpp` release and
  the latest published `libggml-cuda-bin` dependency release
- `scripts/publish-aur.sh`: publish a flat `PKGBUILD`/`.SRCINFO` snapshot to
  the AUR repo
- `scripts/smoke-asset.sh`: verify the built asset against a matching
  `libggml-cuda-bin` asset
- `scripts/update-aur-metadata.sh`: refresh package metadata and checksum
- `.github/workflows/release.yml`: scheduled and manual GitHub-driven release
  workflow
- `.github/workflows/validate.yml`: metadata and shell validation

## Version coupling

This package intentionally tracks a validated `libggml-cuda-bin` release.

The `PKGBUILD` stores:

- the `whisper.cpp` upstream version and `pkgrel`
- the exact `libggml-cuda-bin` `pkgver` and `pkgrel` that were used to build it

That keeps the two repos separate while still making the runtime contract
explicit.

The release workflow polls both upstream `whisper.cpp` and the latest GitHub
release from `OneNoted/libggml-cuda-bin`. If either changes, it rebuilds the
binary package, commits the updated metadata back to `main`, publishes a GitHub
Release, and syncs the AUR package.

To let GitHub Actions publish to AUR, add an `AUR_SSH_PRIVATE_KEY` repository
secret containing a private key authorized for the package on
`aur.archlinux.org`.

## Runtime contract

The installed package depends on:

- `libggml-cuda-bin=<validated version>`
- `cuda`
- `nvidia-utils`
- `sdl2-compat`
