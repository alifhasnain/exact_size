---
id: ADR-002
title: Image encoder — bundled, pinned libjpeg-turbo (FFI) for JPEG; pure-Dart `image` package for PNG
status: Approved
version: 1.0
updated: 2026-11-20
links: [FEAT-004, ADR-001, ADR-003]
---

# ADR-002 — Image encoder choice and pinning

Format: lightweight [MADR](https://adr.github.io/madr/).

## Context
FEAT-004 encodes the same pixels up to ~10 times per export to find the highest JPEG quality inside a KB window [Fact](FEAT-004 FR-5, NFR-1). It needs: integer quality 1–100; chroma 4:2:0 and 4:4:4; optimised Huffman on/off; JPEG comment (COM) segments for padding; PNG at maximum lossless compression; DPI fields; byte-identical output on a device for a given app version (Must) and across devices (Should) [Fact](FEAT-004 FR-8, FR-9, FR-14, FR-15, FR-21). Budget: ≤ 3 s median, ≤ 8 s p95 at 2 MP on a ~2 GB RAM device, i.e. ≤ ~300 ms per pass [Fact](FEAT-004 NFR-1).

## Decision drivers
- Settings control required by FR-8 (levers 2 and 3) and FR-14.
- Determinism: output must not change when the OS updates (FR-15 "same app version").
- Speed per encode pass on low-end ARM.
- Amount of native code a solo developer maintains.
- Fully offline, no downloadable codec (NFR-6).

## Options considered
### Option A — Android OS encoder (`Bitmap.compress`, directly or via a plugin such as `flutter_image_compress`)
- Good: no native build; hardware-tuned; least code.
- Bad: no chroma, Huffman or COM control, so FR-8 levers 2–3 are impossible [Assumption: `Bitmap.compress` exposes only format and quality](https://developer.android.com/reference/android/graphics/Bitmap#compress(android.graphics.Bitmap.CompressFormat,%20int,%20java.io.OutputStream)); PNG ignores the quality argument, so "highest compression" is not selectable; bytes depend on the device's Skia/libjpeg build and can change with OS or Play system updates, which breaks FR-15 across OS updates and FR-21 outright; JPEG of a transparent bitmap is not flattened onto white.

### Option B — Pure Dart `image` package for JPEG and PNG
- Good: no native code; identical bytes on every device for a given app build (same Dart code); supports quality, 4:4:4/4:2:0 [Assumption: verify on the pinned version] and PNG level 9; COM padding can be spliced in Dart.
- Bad: no optimised-Huffman switch (lever 3 becomes a no-op); likely 5–20× slower than libjpeg-turbo per pass [Hypothesis], which risks NFR-1 on low-end devices.

### Option C — Bundled libjpeg-turbo (pinned release, built from vendored source) via Dart FFI for JPEG; `image` package for PNG
- Good: full control through the TurboJPEG v3 API (quality, subsampling, optimise, density) with plain error returns, so no C shim is needed for setjmp/longjmp error handling [Assumption: verify parameter list on the pinned release](https://libjpeg-turbo.org/Documentation/Documentation); SIMD (NEON) speed; bytes change only when the app changes the pinned version; the C library builds for iOS later. PNG is encoded once per export (no search), so pure Dart speed is acceptable there and its deflate output is fixed per app build [Hypothesis].
- Bad: NDK/CMake build for 3 ABIs; 16 KB page-size alignment for Google Play [Fact](https://developer.android.com/guide/practices/page-sizes); licence notices (IJG, BSD, zlib) [Fact](https://github.com/libjpeg-turbo/libjpeg-turbo/blob/main/LICENSE.md); SIMD paths on different ABIs (NEON arm64/armv7, SSE/AVX x86_64) must be shown to give identical bytes [Hypothesis: libjpeg-turbo's accurate integer DCT SIMD code is bit-exact with its C code].

## Decision
Recommend **Option C**, gated by a ≤ 1-day spike on the slowest R1 device that measures one 2 MP encode pass for B and C:
- If C passes ≤ 300 ms per pass and B does not: C (expected).
- If B also passes with margin (≤ 200 ms per pass p95): choose B instead, to avoid native code, and accept lever 3 as a no-op.
Pinning rule: the encoder version is part of the app version; any upgrade regenerates the golden files (FEAT-004 NFR-9). If cross-ABI goldens differ, first try a build with SIMD disabled for the differing step; if that is too slow, keep SIMD and downgrade FR-21 to "both in window" (allowed by AC-6.4). Final once the Product Owner approves.

## Consequences
- Easier: FR-8 levers, FR-15 and very likely FR-21; same-device output immune to OS updates.
- Harder: native build and CI for 3 ABIs; a security watch on the pinned libjpeg-turbo version (CVE feed) with update = golden refresh.
- Main alternative: Option B (no native code) if the spike shows it is fast enough.
- Follow-up: vendor source at a pinned tag with checksum (no prebuilt binaries from third parties); add licences to the in-app licence page.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-20 | First draft |
| 1.0 | 2026-11-20 | Approved by Product Owner |
