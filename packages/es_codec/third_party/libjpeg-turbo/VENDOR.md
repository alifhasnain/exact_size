# Vendored libjpeg-turbo

- Version: **3.2.1** (tag `3.2.1`, released 2026-10-27), pinned per ADR-002.
- Source: `libjpeg-turbo-3.2.1.tar.gz` from https://github.com/libjpeg-turbo/libjpeg-turbo/releases/tag/3.2.1
- SHA-256 of the tarball: `c27ad72a68da151177929aa969ae773a2da5ac2af9ce946079314fdac8cece7f`
- Signature: `libjpeg-turbo-3.2.1.tar.gz.sig` verified with GnuPG ("Good signature") against
  "The libjpeg-turbo Project (Signing key for official binaries)", fingerprint
  `0338 C8D8 D9FD A62C F9C4 21BD 7EC2 DBB6 F4DB F434` (key fetched from keys.openpgp.org; not
  cross-certified, trust on first use).
- Copied unchanged: `src/`, `LICENSE.md`, `README.ijg`, `README.md`. Nothing else from the tarball.
- Build: not with CMake. `packages/es_codec/hook/build.dart` compiles the source list from the upstream
  `CMakeLists.txt` (`JPEG_SOURCES` + `TURBOJPEG_SOURCES`, bundled spng and zlib) with
  `native_toolchain_c`. The CMake-generated headers are hand-written in `../libjpeg-turbo-config/`.
- SIMD: off (`WITH_SIMD` undefined). T04 kept libjpeg-turbo without it; enabling NEON/SSE needs its own decision.
- Licences: IJG (README.ijg), Modified BSD and zlib (LICENSE.md), plus spng (BSD-2) and zlib for the
  bundled PNG support. All must appear on the in-app licence page (FEAT-004-T07).
- Build-time pin: `hook/build.dart` checks a SHA-256 over every file in this directory except this note
  (`lib/src/vendor_checksum.dart`, `pinnedLibjpegTurboChecksum`) and fails the build on any change.
- Upgrading: replace the files, run any build (the error prints the new checksum), update the pin,
  this note and the tarball SHA-256, and rerun the golden tests (ADR-002).
