# Changelog

Implementation changes, one line per finished task. Format: `- FEAT-nnn-Tnn: what changed`.

## [Unreleased]
- FEAT-004-T05: es_codec productionised. The build hook verifies a SHA-256 over the vendored libjpeg-turbo tree (pinned in lib/src/vendor_checksum.dart) and fails on any change (checked by appending one byte to jcapimin.c). arm64-v8a, armeabi-v7a and x86_64 build with identical flags, including -z max-page-size=16384 in the build and the release link. tool/check_16kb_alignment.sh (zipalign -c -P 16, ELF LOAD alignment >= 0x4000) passes for every .so of the main and probe APKs, 32-bit included (CI run 44768311063). T02 C probe removed; tree-shaking check now shows unused TurboJPEG functions (tj3Get, tj3Decompress8) stripped. Found: native_toolchain_c reuses the static archive across builds, so after removing a source file a local rebuild failed with duplicate symbols until `flutter clean`; clean CI checkouts are not affected.
- FEAT-004-T04: profile-mode encoder benchmark (integration_test/encoder_benchmark.dart via flutter drive --profile), 2 MP synthetic image, 2 warm-up + 20 timed runs per case, on the 2 GB emulator profile (x86_64, 2 vCPU, API 36.1). Timings are informational only: emulator CPU does not represent low-end phones (Product Owner, 2026-11-20); libjpeg-turbo runs without SIMD and the time includes copying pixels into native memory. Gate G1 recorded: libjpeg-turbo builds and runs, so ADR-002 Option C is kept. Option B (pure Dart) was 3.5-6x slower in every case.

  | Encoder, config | q | median ms | p95 ms | bytes |
  |---|---|---|---|---|
  | libjpeg-turbo (C), 4:2:0 + optimised Huffman | 40 | 131.7 | 277.7 | 87,885 |
  | libjpeg-turbo (C), 4:4:4 + standard Huffman | 40 | 123.0 | 282.4 | 192,158 |
  | image package (B), 4:2:0 + standard Huffman* | 40 | 511.9 | 1029.0 | 104,580 |
  | image package (B), 4:4:4 + standard Huffman | 40 | 541.3 | 977.7 | 191,686 |
  | libjpeg-turbo (C), 4:2:0 + optimised Huffman | 75 | 195.8 | 266.4 | 236,352 |
  | libjpeg-turbo (C), 4:4:4 + standard Huffman | 75 | 133.9 | 261.5 | 443,682 |
  | image package (B), 4:2:0 + standard Huffman* | 75 | 730.1 | 917.2 | 255,960 |
  | image package (B), 4:4:4 + standard Huffman | 75 | 966.6 | 1261.9 | 440,845 |
  | libjpeg-turbo (C), 4:2:0 + optimised Huffman | 100 | 333.8 | 571.7 | 1,712,220 |
  | libjpeg-turbo (C), 4:4:4 + standard Huffman | 100 | 233.8 | 391.8 | 4,162,407 |
  | image package (B), 4:2:0 + standard Huffman* | 100 | 957.3 | 1392.7 | 1,853,432 |
  | image package (B), 4:4:4 + standard Huffman | 100 | 1443.9 | 1980.5 | 4,134,192 |

  *The image package has no optimised-Huffman switch.
- FEAT-004-T03: libjpeg-turbo 3.2.1 vendored in packages/es_codec/third_party (tarball SHA-256 c27ad72a...cece7f, GPG signature checked against the project key 0338C8D8...F4DBF434) and built with the Dart build hook from the upstream source list (no CMake; hand-written jconfig.h/jconfigint.h/jversion.h; SIMD off); FFIgen bindings for tj3InitVersion/tj3Set/tj3Get/tj3Compress8/tj3Free/tj3Destroy/tj3GetErrorStr/tj3GetErrorCode plus TJ enums; spike encoder encodeRgba8ToJpeg. The 2 MP synthetic image (1600x1250) encodes at q85 and decodes back to 1600x1250 with package:image on the host (MSVC) and on the 2 GB emulator (x86_64, API 36.1); CI adds API 28. arm64 emulator not available on this PC.
- FEAT-004-T02: GitHub Actions CI (generated-code check, analyze, tests, release APK for arm/arm64/x64, record_use tree-shaking check, API 28 emulator interop test) green on main (run 44748990934). Gate G0 passed: Flutter 3.50.1 default minSdk 24 <= 28 (FlutterExtension.kt; flutter.dev/blog/whats-new-in-flutter-3-50); FFIgen and JNIgen stable per the 3.50 blog; FFIgen @Native binding and JNIgen Build.VERSION.SDK_INT return correct values on the API 28 emulator; release builds tree-shake native code via record_use (main app ships no libes_codec.so; probe keeps es_probe_add, drops es_probe_unused, checked with readelf because no official verification doc exists). Findings: native code is built with Dart build/link hooks (native_toolchain_c), not the CMake plugin layout ADR-001 describes; FFIgen 23 uses the Visitor/Input API; jnigen 1.1.0 output warns against jni 1.2.1, so it is excluded from analysis.
- FEAT-004-T01: Flutter 3.50.1 app scaffold (Android only, minSdk 28 confirmed in merged manifest); pinned flutter_riverpod 3.5.0, get_it 9.3.0, injectable 3.0.0 (+ injectable_generator, build_runner), material_ui/cupertino_ui; gen-l10n with en, es, pt, pt_BR, hi, id, ar (localization delegates listed in app.dart because generated defaults are deprecated in 3.50); empty compression module and es_codec package; no riverpod_generator (plain providers, one less codegen step); Flutter 3.50.1 default minSdk is 24 (FlutterExtension.kt), below our 28. Placeholder applicationId com.exactsize.exact_size must be confirmed before the first Play upload.
