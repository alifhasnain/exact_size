# Vendored stb_image_resize2

- Version: **2.51** (`stb_image_resize2.h`, header line "v2.51"), pinned per ADR-005.
- Source: https://github.com/nothings/stb_image_resize at commit
  `a4f303e34a92d1410d510cbe85a1781ce4b8c9fd` (2026-11-17, "2.51 - VC6 compatiblity").
  Fetched from `https://raw.githubusercontent.com/nothings/stb_image_resize/<commit>/stb_image_resize2.h`
  and `.../LICENSE` on 2026-11-21.
- Upstream move: on 2026-10-19 the author moved the library out of `nothings/stb` (where ADR-005
  cites it, last there as 2.18b) into its own repository; the copy left in `nothings/stb/deprecated/`
  is only a pointer. Same author and licence. We pin the maintained repository so security fixes
  can be taken.
- Integrity: the downloaded header's git blob id `6892c7244be7556c5cf18b783dd48b6d24e23d8d` matches
  the one GitHub reports for that commit. SHA-256 as downloaded (CRLF line endings):
  `stb_image_resize2.h` `9a653683b5fafba0f5c7911d163ede7d92c64dcd1e482407bd8b44aa155925ce`,
  `LICENSE` `bebfe904b14301657e4e5d655c811d51fd31b97c455b9cc2d8600d6bac6cff63`.
  Git stores them with LF (`.gitattributes`); the build-time check normalises line endings.
- Copied unchanged: `stb_image_resize2.h`, `LICENSE`. Nothing else.
- Licence: dual, "choose whichever you prefer": MIT or public domain (Unlicense). We use the
  **MIT** option; the text is on the in-app licence page (`lib/src/licenses.dart`).
- Build: compiled once by `../../src/es_stb_resize.c` (`STB_IMAGE_RESIZE_IMPLEMENTATION`) through
  `hook/build.dart`. SIMD: stb's default (SSE2 on x86_64, NEON on arm64). ADR-005 accepts that
  output may differ per ABI; `STBIR_NO_SIMD` is the fallback.
- Build-time pin: `hook/build.dart` checks a SHA-256 over every file in this directory except this
  note (`lib/src/vendor_checksum.dart`, `pinnedVendorChecksums['third_party/stb']`) and fails the
  build on any change.
- Upgrading: replace the files from a new upstream commit, run any build (the error prints the new
  checksum), update the pin and this note, and regenerate the resampler goldens (ADR-005).
