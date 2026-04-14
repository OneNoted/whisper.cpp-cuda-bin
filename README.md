# whisper.cpp-cuda-bin

Binary AUR packaging repo for `whisper.cpp-cuda-bin`.

This repo builds a precompiled `x86_64` `whisper.cpp` package, links it against
the published `libggml-cuda-bin` release, publishes the asset on GitHub
Releases, and syncs the AUR package from the same workflow.

## Release flow

- `validate.yml` checks packaging metadata
- `release.yml` tracks upstream `whisper.cpp` and the latest published
  `libggml-cuda-bin` release
- when a release is needed, it builds and smoke-tests
  `whisper.cpp-cuda-bin-<pkgver>-<pkgrel>-x86_64.tar.zst`
- the workflow updates `PKGBUILD` and `.SRCINFO`, commits them to `main`,
  publishes the GitHub release, and pushes the flat AUR snapshot

## Package details

- target: `x86_64`
- linked against: `libggml-cuda-bin=<validated version>`
- runtime deps: `cuda`, `nvidia-utils`, `sdl2-compat`

## Maintainer

Jonatan Jonasson `<notes@madeingotland.com>`
