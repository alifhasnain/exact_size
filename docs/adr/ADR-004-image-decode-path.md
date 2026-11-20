---
id: ADR-004
title: Image decode path — Android platform decoders (BitmapRegionDecoder / BitmapFactory) via JNIgen, own orientation step, same path for preview and render
status: Approved
version: 1.0
updated: 2026-11-20
links: [FEAT-002, FEAT-004, ADR-001, ADR-003, ADR-005]
---

# ADR-004 — Image decode path for FEAT-002

Format: lightweight [MADR](https://adr.github.io/madr/).

## Context
FEAT-002 must decode JPEG, PNG, WebP and HEIC/HEIF (minSdk 28) to 8-bit sRGB using the platform decoder's own colour conversion and no custom colour engine. It must apply EXIF orientation 1–8 identically in preview and render, decode a reduced preview, and for the render decode only the crop region at the largest power-of-two reduction that keeps it ≥ target W×H. It must support sources up to 100 MP and targets up to 24 MP on a ~2 GB device without crashing [Fact](FEAT-002 prd.md FR-3, FR-6, FR-7, FR-10, NFR-2). ADR-001 fixes Flutter 3.50.x, JNIgen for Android APIs (no Kotlin platform-channel plugin) and C via FFI in `packages/es_codec/`. ADR-003 fixes the output: a native `malloc` buffer whose ownership moves to FEAT-004, and large pixels never cross JNI as Java arrays. The PRD asks Stage 6 to choose the decoder (region decode, HEIC/WebP, orientation, ICC) and the Flutter vs native split for large images.

## Decision drivers
- Memory: a full decode is ~400 MB at 100 MP and ~800 MB at 200 MP (the source ceiling, FEAT-002 PRD v1.1) at 4 bytes/px [Fact: arithmetic], which is not viable on 2 GB devices. Region and sampled decode are needed.
- One orientation rule for preview, gesture mapping and render (FR-3, AC-3.2).
- Platform sRGB conversion (FR-10), HEIC on all supported devices (ADR-001).
- Least native code and no extra codec licences or app size.
- Determinism on the same device (FR-12).

## Options considered
### Option A — Platform decoders via JNIgen: `BitmapRegionDecoder` (render and preview), `BitmapFactory` (bounds probe and fallback), `android.media.ExifInterface` (orientation only); orientation applied by our own lossless step
- Good: `decodeRegion(rect, options)` with `inSampleSize` (power of two) matches FR-7 exactly, so only the crop region is decoded [Fact](https://developer.android.com/reference/android/graphics/BitmapRegionDecoder). `inPreferredColorSpace = SRGB` asks the platform for sRGB (API 26+) [Fact](https://developer.android.com/reference/android/graphics/BitmapFactory.Options#inPreferredColorSpace). Neither decoder applies EXIF orientation, so one D4 (rotate/flip) table in our code handles preview display, gesture maths and render, which makes preview/render mismatch impossible by construction. Bitmap pixels live in native memory (Android 8+) [Fact](https://developer.android.com/topic/performance/graphics/manage-memory) and can be read in C through NDK `AndroidBitmap_lockPixels` with no Java array copy. No extra licences or app size.
- Bad: we own the orientation maths, including mirrored values 2/4/5/7. HEIF orientation may come from `irot`/`imir` boxes rather than EXIF, and whether the decoder applies them is unverified [Hypothesis]. Region-decoder support per format and API level (HEIF, animated WebP, GIF) needs a fallback path [Hypothesis]. Progressive JPEG and very large PNGs may still need large internal buffers or decode slowly [Hypothesis]. Output can change after an OS update.

### Option B — `ImageDecoder` (API 28) only, via JNIgen
- Good: one API; it applies orientation itself (including HEIF transforms) [Hypothesis: verify], decodes the first frame of animated images, and offers `setTargetSampleSize`, `setCrop` and `setTargetColorSpace` [Fact](https://developer.android.com/reference/android/graphics/ImageDecoder).
- Bad: `setCrop` is believed to crop after decoding the whole (sampled) image, not to decode only a region [Hypothesis]. A 24 MP target from a 50 MP source would then decode ~200 MB instead of only the crop region. It is opaque about which orientation it applied, so gesture coordinates must trust it blindly, and it gives no direct pixel pointer without the same jnigraphics step.

### Option C — Flutter engine codec (`ui.instantiateImageCodec` / `ImageDescriptor` with target size)
- Good: no JNI at all; pure Flutter; iOS-ready.
- Bad: no region decode, so the full image is decoded at the chosen size. Control over orientation handling and colour-space conversion is unclear and changes with engine versions [Hypothesis]. Getting pixels out for the render (`toByteData`) copies through the GPU/raster thread. Not suitable for a 24 MP render from a 100 MP source.

### Option D — Bundled C decoders in `es_codec` (libjpeg-turbo decode with crop + scale, libpng, libwebp, libheif + libde265)
- Good: cross-device identical pixels (would let OQ-12 become Must); full control of region, scale and orientation; libjpeg-turbo is already vendored (ADR-002).
- Bad: FR-10 requires the platform's sRGB conversion, so this needs our own ICC engine (lcms2), which the PO scope trim removed. HEIC needs libheif/libde265 (LGPL, HEVC patent questions, +several MB). It adds 4 more libraries to the CVE watch. Most effort of all options.

## Decision
Recommend **Option A**, with these rules:
- **Decode path chosen once per source at probe time** and used for both preview and render: `region` (`BitmapRegionDecoder`) by default; `full` (`BitmapFactory.decodeFileDescriptor` with `inSampleSize`, then crop in memory) when the region decoder cannot open the file (for example GIF or some animated WebP) [Hypothesis]. Both paths ignore EXIF, so the single D4 rule applies to both.
- Always request `ARGB_8888`, `inPreferredColorSpace = SRGB`, `inPremultiplied = false`. If the returned bitmap's config or colour space differs, the result is `UNSUPPORTED_INPUT` (FR-10). This is a verifiable check, not our own colour conversion.
- Orientation is read only through `ExifInterface.getAttributeInt(TAG_ORIENTATION, 1)`; values outside 1–8 are treated as 1.
- Pixels are read in `es_codec` through `AndroidBitmap_lockPixels` (jnigraphics) and resampled straight into the ADR-003 native buffer, then the bitmap is recycled.
- `ImageDecoder` (Option B) is used only as a **test oracle** in instrumented tests, to check our orientation result.
- A ≤ 1-day spike (shared with ADR-005) runs on the slowest R1 device and checks: (1) region decode + sample + sRGB for JPEG (baseline and progressive), PNG, WebP and HEIC at 12/50/100/200 MP; (2) whether HEIF `irot` is applied by the decoder (if so, HEIF orientation is forced to 1); (3) JNIgen calls from a worker isolate; (4) jnigraphics access through the JNI env exposed by `package:jni`. If (3) or (4) fails, the fallback is `Bitmap.copyPixelsToBuffer` into a direct `ByteBuffer` over the native buffer, which is still no Java array.
Final once the Product Owner approves.

## Consequences
- Easier: memory stays close to region size plus output; one orientation rule; HEIC with no bundled codec; no new licences.
- Harder: own D4 maths and an 8-orientation × format fixture set; a fallback path for formats the region decoder can't open; same-device determinism holds per OS build, not across OS updates (see FEAT-002-TECH OQ-12).
- Main alternative: Option B if the spike shows the region decoder misbehaves on HEIC or on common OEM builds; the cost is higher peak memory, so `IMAGE_TOO_LARGE` would appear earlier on 2 GB devices.
- Follow-up: synthetic fixtures only (generated test patterns, no real people); add jnigraphics to the `es_codec` CMake link.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-20 | First draft |
| 0.2 | 2026-11-20 | Source ceiling 200 MP reflected in drivers and spike |
| 1.0 | 2026-11-20 | Approved by Product Owner |
