# whisper.cpp-cuda-bin

Binary-packaging repo for the Arch User Repository package
`whisper.cpp-cuda-bin`.

This repo builds a Linux `x86_64` release asset from upstream `whisper.cpp`,
links it against the separately published `libggml-cuda-bin` install tree, and
keeps the AUR metadata next to the release automation.

## Why this exists

`whisper.cpp-cuda` currently builds from source in the AUR and depends on a
source-built `libggml-cuda-git`. This repo converts that into a binary package
that depends on a validated `libggml-cuda-bin` release instead.

## Repository layout

- `PKGBUILD`: AUR package recipe
- `.SRCINFO`: generated AUR metadata
- `scripts/build-asset.sh`: build a prepackaged `/usr` tree
- `scripts/smoke-asset.sh`: verify the built asset against a matching
  `libggml-cuda-bin` asset
- `scripts/update-aur-metadata.sh`: refresh package metadata and checksum
- `.github/workflows/release.yml`: manual build-and-release workflow
- `.github/workflows/validate.yml`: metadata and shell validation

## Version coupling

This package intentionally tracks a validated `libggml-cuda-bin` release.

The `PKGBUILD` stores:

- the `whisper.cpp` upstream version and `pkgrel`
- the exact `libggml-cuda-bin` `pkgver` and `pkgrel` that were used to build it

That keeps the two repos separate while still making the runtime contract
explicit.

## Runtime contract

The installed package depends on:

- `libggml-cuda-bin=<validated version>`
- `cuda`
- `nvidia-utils`
- `sdl2-compat`

