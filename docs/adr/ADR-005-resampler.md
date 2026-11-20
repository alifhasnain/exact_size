---
id: ADR-005
title: Resampler — vendored stb_image_resize2 in es_codec (C), Catmull-Rom, alpha-aware, single pass to exact W×H
status: Approved
version: 1.0
updated: 2026-11-20
links: [FEAT-002, ADR-001, ADR-002, ADR-003, ADR-004]
---

# ADR-005 — Resampling algorithm and where it runs

Format: lightweight [MADR](https://adr.github.io/madr/).

## Context
FEAT-002 FR-9 requires one pinned, anti-aliased algorithm, chosen in Stage 6 and recorded in an ADR, that resamples once from the decoded region to exactly W×H, with alpha handled in premultiplied form (no fringes, AC-6.3). Linear-light and PSNR targets were removed by the PO [Fact](FEAT-002 prd.md FR-9). FR-8 allows separate x/y scales only to absorb integer rounding. Sizes run from a 1×1 source enlarged to a 24 MP target, down to a 50 MP region reduced to 140×60. Budget: render ≤ 2 s median for 12 MP → ≤ 2 MP on the low-end device (NFR-1). Output goes into the ADR-003 native buffer, and the decoded region is already in native memory (ADR-004).

## Decision drivers
- Anti-aliased downscale (AC-2.3) and acceptable upscale (AC-5.6); thin signature strokes stay crisp.
- Correct alpha edges.
- Speed on low-end ARM at up to 24 MP output.
- Works on native memory with no copy into the Dart heap (ADR-003).
- Same-device determinism (FR-12); cross-device is Should (OQ-12).
- Least code to own and test.

## Options considered
### Option A — Vendored `stb_image_resize2.h` (single header, public domain / MIT) compiled into `es_codec`
- Good: area-correct filtering in both directions (the kernel widens with the reduction factor, so downscale is anti-aliased) and separate x/y scales [Fact](https://github.com/nothings/stb/blob/master/stb_image_resize2.h). Pixel layouts handle alpha: with `STBIR_RGBA` (straight alpha in) it premultiplies internally in float and returns straight alpha, which meets AC-6.3 without our own code and keeps more precision than 8-bit premultiplied input. NEON SIMD speed [Hypothesis: ≤ 300 ms for 2 MP output on the low-end device, measured in the spike]. One header added to a C package that already exists (ADR-002); compiles for iOS later.
- Bad: float maths with SIMD paths may give different bytes per ABI [Hypothesis]. That is acceptable while cross-device identity is Should, and `STBIR_NO_SIMD` is a fallback. The header must be pinned at a commit and covered by the CVE watch. Filters on offer: box, triangle, cubic B-spline, Catmull-Rom, Mitchell, point. Lanczos is not available.

### Option B — Own separable fixed-point filter in C (for example Lanczos-3 or Catmull-Rom, integer weights)
- Good: integer maths gives bit-identical output on every ABI, which would allow cross-device Must if the decoder were also bundled (it isn't, see ADR-004). Full control.
- Bad: ~300–500 lines of new C to write, optimise (NEON by hand) and test, including edge handling, weight normalisation and premultiply/unpremultiply rounding. More risk than benefit while decoding is platform-dependent anyway.

### Option C — Pure Dart (`image` package `copyResize`, or own Dart code) in a worker isolate
- Good: no new C; identical bytes everywhere for a given app build.
- Bad: pixels would need to cross into the Dart heap (an extra 96 MB at 24 MP, against ADR-003). Likely 5–20× slower than SIMD C [Hypothesis]. Whether the package's large-ratio downscale is anti-aliased for each interpolation mode needs checking [Hypothesis].

### Option D — Android platform scaling (`Bitmap.createScaledBitmap` / `Canvas` with filtering) via JNIgen
- Good: no new code; hardware-tuned.
- Bad: bilinear filtering without area averaging aliases at large reductions (fails AC-2.3) [Hypothesis]. Output depends on the OS Skia build. Premultiplied 8-bit only. Exact W×H at a sub-pixel source rectangle needs matrix work.

## Decision
Recommend **Option A**, pinned as follows:
- Filter **Catmull-Rom** for both directions (one algorithm, FR-9), edge mode clamp. Catmull-Rom is sharper than Mitchell for signature strokes, at the cost of mild ringing. It is checked on the NFR-3 visual test chart (diagonal lines, zone plate, thin strokes, alpha edge), and if the chart shows ringing problems the fallback is Mitchell (one constant to change; goldens regenerate).
- Data type `STBIR_TYPE_UINT8` (values treated as-is, no sRGB→linear step, per the PO trim). Layout `STBIR_RGBA` for sources with alpha (straight in, straight out, premultiplied internally); `STBIR_4CHANNEL` (no alpha handling) for opaque sources. 3-channel compaction happens after resampling (FEAT-002-TECH section 3).
- A single call from the decoded region (any stride) to the W×H native buffer. Resample first, then the lossless orientation step (ADR-004), so there is still one resample (AC-12.3).
- The library version is part of the app version. A version bump regenerates the resampler goldens (synthetic input, pure function, NFR-9).
- Spike, shared with ADR-004: time 12 MP→2 MP and 25 MP→24 MP on the slowest R1 device. If it fails the ≤ 2 s render budget even with SIMD, revisit (Option B with NEON).
Final once the Product Owner approves.

## Consequences
- Easier: little new code, correct alpha, anti-aliasing for free, no Dart-heap copy.
- Harder: one more vendored file (licence notice, CVE watch). Cross-ABI bytes are not guaranteed; that is accepted under OQ-12 (Should).
- Main alternative: Option B if bit-exact cross-device output becomes Must or stb proves too slow.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-20 | First draft |
| 1.0 | 2026-11-20 | Approved by Product Owner |
