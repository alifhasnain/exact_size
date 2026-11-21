---
id: FEAT-002-TASKS
title: Crop and resize to exact target dimensions — Implementation Tasks
status: Approved
version: 1.0
updated: 2026-11-20
links: [FEAT-002, FEAT-002-TECH, ADR-001, ADR-003, ADR-004, ADR-005]
---

# FEAT-002 — Implementation Tasks

Milestone: R1 Phase A — core. Work top to bottom, one task at a time.

Sizes: **S** = up to half a day, **M** = up to one day; each task is one PR.
Module paths follow ADR-001: `lib/features/crop/{domain,data,presentation}`, native code in `packages/es_codec/` (JNIgen bindings under `packages/es_codec/lib/src/android/`, as in FEAT-004-T02). Tests mirror them under `test/` and `integration_test/`; shared fixtures and helpers go in `test_support/`.

**Already built, reused, not planned again:** Flutter 3.50.1 scaffold, Riverpod, get_it + injectable (ADR-001 v1.1), gen-l10n with 6 languages, GitHub Actions CI with the API 28 emulator job, `packages/es_codec/` with Dart build/link hooks (`native_toolchain_c`), vendored libjpeg-turbo with a build-time checksum, FFIgen, JNIgen, `record_use` tree shaking, `tool/check_16kb_alignment.sh`, `test_support/synthetic_image.dart`.

**Overrides of tech.md wording:**
- Native build uses Dart build hooks, never CMake (ADR-001 v1.2). "CMake" or "jnigraphics link" in tech.md means changes to `packages/es_codec/hook/build.dart` and `lib/src/c_library.dart`.
- "Emulator profile" means an Android emulator with 2 GB RAM on API 28 **and** on the latest API (PRD v1.3 test note). This is the only "low-end device". Timings measured there are informational, not gates. The Samsung Galaxy S23 Ultra (arm64, high-end) may be used as an extra arm64 device for ABI and NEON checks, and is never used as the low-end reference.
- Same-device determinism means same device **and** OS build. Cross-device is Should (PRD OQ-12).
- The FEAT-004 spike (FEAT-004-T03/T04) already proved the native build and FFI on the emulator. FEAT-002's spike (T03, T04) covers only what is still unproven.

## Decision gates
| Gate | Task | Passes when | If it fails |
|---|---|---|---|
| G1 Decode/resample spike | T04 | ADR-004 and ADR-005 assumptions hold on the emulator profile: region decode with `inSampleSize` and the sRGB/ARGB_8888/unpremultiplied request works for JPEG (baseline and progressive), PNG, WebP and HEIC; JNIgen works from a worker isolate; pixels reach C with no Java array (jnigraphics or the `copyPixelsToBuffer` fallback); 12 MP → 2 MP and a 24 MP target stay inside NFR-2; a 50 MP source decodes. A recorded decision table exists (below) | Stop all FEAT-002 data and native work (T12 onwards) and report to the Product Owner. An ADR-004 change (for example Option B, `ImageDecoder`) or an ADR-005 change needs a Product Owner decision. Domain tasks T05–T11 may continue, because they do not depend on the decoder |
| G2 Resampler chart | T13 | The Product Owner accepts Catmull-Rom on the synthetic visual chart (NFR-3, ADR-005) | Present the Mitchell comparison. Change the filter constant only after a Product Owner decision; goldens then regenerate |
| G3 Crop screen design | T22 | The Product Owner has designed the crop screen with impeccable (https://github.com/pbakaus/impeccable) and the design reference is recorded | No task that builds or styles the visible crop screen (T23–T28) starts. Non-visual work may continue |
| G4 Orientation and determinism | T21 | 100% of the 8 EXIF orientations (JPEG and HEIC) render upright and not mirrored, preview matches render, and same-device and same-OS-build renders are byte-identical | Stop and report: a sideways or mirrored ID photo, or FR-12 failing, is a Must defect. A cross-device difference is recorded only (Should) |
| G5 Emulator run | T29 | NFR-2 and NFR-8 are met on the emulator profile at both API levels; airplane mode works; no crash or ANR. NFR-1 and FR-25 numbers recorded for information only | A memory or reliability miss: stop and report. Timing misses are reported, not a gate |

## Tasks

### - [x] FEAT-002-T01 — Vendor `stb_image_resize2.h` (pinned, checksummed, licensed)
- **Implements:** FR-9 (prerequisite) · **ADRs:** ADR-001, ADR-005
- **Depends on:** — (es_codec from FEAT-004-T05)
- **Size:** S
- **Scope:** `packages/es_codec/third_party/stb/stb_image_resize2.h` at a pinned upstream commit; `third_party/stb/VENDOR.md` (version, commit, source URL, SHA-256, licence, update procedure) following `third_party/libjpeg-turbo/VENDOR.md`; extend `lib/src/vendor_checksum.dart` and the check in `hook/build.dart` to cover the stb file; register the stb licence (MIT option of its dual licence) with `LicenseRegistry`, using the same place as FEAT-004-T07 (or creating it, if T07 has not landed); add stb to the CVE-watch note in `packages/es_codec/README.md`.
- **Done when:** the build fails when one byte of `stb_image_resize2.h` is changed locally and passes again when it is restored; CI builds arm64-v8a, armeabi-v7a and x86_64; `tool/check_16kb_alignment.sh` passes; a widget test finds the stb licence text on the licence page; `VENDOR.md` names the commit and SHA-256.

### - [x] FEAT-002-T02 — Synthetic crop fixture generator
- **Implements:** NFR-8, NFR-9 (test data), AC-3.2 (fixtures) · **ADRs:** ADR-004
- **Depends on:** —
- **Size:** M
- **Scope:** `tool/gen_crop_fixtures.sh` (or `.dart`) running offline on the developer machine with pinned host tools (for example ImageMagick and libheif `heif-enc` [Assumption: allowed as dev-only tools, versions recorded]); `test_support/crop_fixtures/` with `MANIFEST.md` (file, purpose, generator version, SHA-256). Small committed set: an asymmetric arrow/quadrant pattern with EXIF orientation 1–8 in JPEG and HEIC (HEIC via EXIF and via `irot`/`imir`), orientation 0, 9 and missing; PNG with partial alpha, PNG with alpha but fully opaque; 16-bit PNG, grayscale, Display P3 PNG, CMYK JPEG; animated WebP and GIF; HEIC 10-bit; truncated JPEG, corrupt PNG, a text file named `.jpg`; 1×1, 7×7, 200×200, 1000×100; diagonal-line chart, zone plate, thin-stroke signature-like strip; a crafted PNG header claiming 200,000,001 px. Large set, generated on demand and pushed with `adb`, not committed: 12, 50, 100 and 200 MP as baseline JPEG, progressive JPEG, PNG, WebP (where the format allows the size) and HEIC.
- **Done when:** running the script twice gives files whose SHA-256 match `MANIFEST.md` (or the manifest records which tool output is not byte-stable); every fixture is generated from patterns (no real faces, signatures or photos; names use neutral words, any sensitive value is `[PLACEHOLDER]`); the large set generates on a clean machine from documented commands with no network access during generation.

### - [x] FEAT-002-T03 — Spike part 1: JNI from a worker isolate, pixel access in C, stb timing
- **Implements:** NFR-1 (evidence), FR-18 (evidence) · **ADRs:** ADR-004 (spike items 3, 4), ADR-005
- **Depends on:** T01
- **Size:** M
- **Scope:** spike branch; JNIgen bindings for `Bitmap` and `BitmapFactory` (temporary); `Isolate.run` that calls `BitmapFactory` via JNIgen; C function that reads a synthetic `Bitmap` through `AndroidBitmap_lockPixels` using the JNI env exposed by `package:jni` (jnigraphics linked in the build hook); fallback measurement with `Bitmap.copyPixelsToBuffer` into a direct `ByteBuffer` over `malloc` memory; profile-mode stb Catmull-Rom timing for 12 MP → 2 MP and 25 MP → 24 MP on synthetic buffers (2 warm-up runs, then 20 timed runs).
- **Done when:** on the emulator profile at API 28 and the latest API, an integration test shows (a) a JNIgen call inside a worker isolate returning the expected bitmap size, (b) C reading the expected pixel values of a synthetic bitmap with no Java array (jnigraphics, or the fallback if jnigraphics fails); a timing table (median, p95) is recorded in the PR and `docs/CHANGELOG.md`, marked informational, with an optional S23 Ultra arm64 row labelled "high-end, NEON, not the low-end reference".

### - [ ] FEAT-002-T04 — Spike part 2: decode matrix, HEIC orientation, large sources — gate G1
- **Implements:** FR-3, FR-6, FR-7, FR-10, FR-15, NFR-2, NFR-10 (evidence) · **ADRs:** ADR-004, ADR-005
- **Depends on:** T02, T03
- **Size:** M
- **Scope:** spike branch; on the emulator profile at API 28 and the latest API, for the T02 large set and variants: `BitmapRegionDecoder.newInstance` and `decodeRegion` with `inSampleSize`, `ARGB_8888`, `inPreferredColorSpace = SRGB`, `inPremultiplied = false`; record whether the region decoder opens the file, the returned config and colour space, peak memory (`dumpsys meminfo` before/after), success or OOM. HEIC: compare our EXIF-based orientation with the `ImageDecoder` oracle for EXIF and `irot`/`imir` fixtures. Animated WebP and GIF: does the region decoder open them, is the first frame returned. 10-bit HEIC, CMYK JPEG, 16-bit and P3 PNG: what config/colour space comes back.
- **Done when:** a decision record is in the PR and `docs/CHANGELOG.md` with: (1) decode path per format (`region` or `full`); (2) the HEIF orientation rule (force 1 if the decoder applies `irot`, else EXIF), identical on both API levels or per API level; (3) a per-format memory pre-flight factor; (4) the 100 MP and 200 MP outcome per format (decodes, or the pixel threshold above which the probe returns `IMAGE_TOO_LARGE` early, allowed by FR-6 best effort); (5) jnigraphics or `copyPixelsToBuffer`; (6) first-frame behaviour for animated files; (7) which variants map to `UNSUPPORTED_INPUT`. Gate G1 is recorded as passed, or work stops and the failing assumption goes to the Product Owner. No task from T12 onwards starts before G1 passes.

### - [x] FEAT-002-T05 — Domain types, `Reason` and `TargetCheck`
- **Implements:** FR-1, FR-19 (types), NFR-9 · **ADRs:** ADR-003
- **Depends on:** —
- **Size:** S
- **Scope:** `lib/features/crop/domain/`: `Target`, `CropRect`, `SourceInfo`, `Reason` (`INVALID_TARGET_DIMENSIONS`, `UNSUPPORTED_INPUT`, `CORRUPT_INPUT`, `SOURCE_UNAVAILABLE`, `IMAGE_TOO_LARGE`, `OUT_OF_MEMORY_HANDLED`, `CANCELLED`, `INTERNAL_ERROR`), `RenderResult`, `target_check.dart`.
- **Done when:** `target_check_test.dart` passes for W or H = 0, 1, 10,000, 10,001, negative, and W×H = 24,000,000 (allowed) and 24,000,001 (refused), each refusal giving `INVALID_TARGET_DIMENSIONS` with the right message key (per-side vs too-large); `Reason.values` equals the list above; an import-scan test shows `lib/features/crop/domain/` has no Flutter, Riverpod, get_it or JNI imports.

### - [ ] FEAT-002-T06 — `Orientation` (D4) table
- **Implements:** FR-3, FR-21 (composition), AC-3.2, AC-3.3, AC-12.2 · **ADRs:** ADR-004
- **Depends on:** T05
- **Size:** S
- **Scope:** `domain/orientation.dart`: EXIF 1–8 and quarter-turns to one of 8 transforms; compose; point and rect mapping raw ↔ oriented; display matrix values; invalid → 1.
- **Done when:** `orientation_test.dart` passes: for every EXIF value 1–8 a 3×2 asymmetric grid maps to a hand-written expected grid (mirrored 2, 4, 5, 7 included); 0, 9, −1 and missing map to 1; four clockwise quarter-turns compose to identity for every EXIF value; raw → oriented → raw is identity for 1,000 seeded rects per transform.

### - [ ] FEAT-002-T07 — `CropMath`: cover, minimum, clamp, rounding, upscale, sample size
- **Implements:** FR-4, FR-7 (sample size), FR-8, FR-11 (factor), FR-12 (gesture determinism), AC-1.1, AC-1.3–1.6, AC-5.5 · **ADRs:** ADR-004
- **Depends on:** T06
- **Size:** M
- **Scope:** `domain/crop_math.dart`: `CropState {cx, cy, cw, quarterTurns}`, initial state, cover width, minimum crop (`max(coverCw/8, width where the shorter side is 32 px)`, capped at cover), `toCropRect` (tech.md FR-8 rule), `upscaleFactor`, `sampleSize` (largest power of two with `cropW/s ≥ W` and `cropH/s ≥ H`, else 1).
- **Done when:** `crop_math_test.dart` passes: 4000×3000 → 300×300 gives cropRect (500, 0, 3000, 3000); 3000×4000 → 300×80 gives the centred full-width strip 3000×800; 140×60 ratio holds; square/square and equal-ratio sources give the whole image; 1×1 and 7×7 sources give a valid rect with w, h ≥ 1; 200×200 → 300×300 factor 1.5; 1000×100 → 300×300 uses the limiting axis; `sampleSize(3000×3000 → 300×300) = 8`, and 1 when the crop is smaller than the target; a 10,000-case seeded property test finds every cropRect inside the image, the ratio error under 1 source pixel per side, and identical output for identical input.

### - [ ] FEAT-002-T08 — Must reducers: drag, pinch, move, zoom, centre, reset
- **Implements:** FR-4, FR-5 (logic), FR-27 (logic: same move/zoom reducers), AC-1.2, AC-9.3 · **ADRs:** —
- **Depends on:** T07
- **Size:** M
- **Scope:** `domain/crop_reducers.dart`: pure functions on `CropState`; move step 5% of the visible crop region; result carries an `edgeReached` value (left, right, top, bottom, none) for announcements; physical directions only (no RTL input).
- **Done when:** `crop_reducers_test.dart` passes: drag and pinch never leave the image or go below minimum / above cover; a move that hits an edge stops there and reports that edge; zoom in/out actions equal pinch with the focal point at the frame centre; centre and reset give the initial state; a seeded property test of 10,000 random reducer sequences keeps every invariant (inside the image, ratio exact, `min ≤ cw ≤ cover`).

### - [ ] FEAT-002-T09 — Should reducers: corner handle and 90° rotate
- **Implements:** FR-21, FR-28 (logic), AC-12.1, AC-12.2, AC-13.1–13.4, AC-13.7 · **ADRs:** ADR-004
- **Depends on:** T08
- **Size:** S
- **Scope:** `domain/crop_reducers.dart`: handle reducer anchored at the opposite corner with the same clamps; rotate clockwise / counter-clockwise around the frame centre with re-fit.
- **Done when:** tests pass: a handle drag keeps the opposite corner fixed and the ratio exact, stops at the image edge and at the minimum; handle release leaves `CropState` unchanged (only the view re-fits later); a zoom-in action and a handle shrink to the same width give the same cropRect (AC-13.7); four rotations in one direction return the original state; after any rotation no empty area is inside the frame.

### - [ ] FEAT-002-T10 — Crop strings (ARB) and `CropMessages`
- **Implements:** FR-22, NFR-6, AC-10.1, AC-10.3 · **ADRs:** ADR-001
- **Depends on:** T05
- **Size:** M
- **Scope:** English ARB keys with ICU placeholders for every PRD section 8 message, the enlarge notice and confirm dialog, animated-image notice, "limited on-screen precision" hint, button labels (Centre, Reset, nudge, zoom, rotate, Continue, Continue anyway, Choose another photo), TalkBack labels and announcements (crop area state, edge reached, handle names, upscale change); `presentation/crop_messages.dart` mapping `Reason` and notices to keys; numbers, "W×H" and units wrapped in U+2068…U+2069; untranslated list for FEAT-019.
- **Done when:** `crop_messages_test.dart` passes: every `Reason` and notice has a key; English text matches PRD section 8 with formatted [W], [H], [FACTOR]; in `ar` every number and "300×80" is inside bidi isolates and not reversed; every message with a PRD value uses a placeholder (no concatenation); `gen-l10n` lists the 5 untranslated locales for FEAT-019.

### - [ ] FEAT-002-T11 — `cropControllerProvider`, TalkBack action handlers and announcements
- **Implements:** FR-5, FR-11 (live updates), FR-13 (state restore), FR-20 (state kept), AC-5.4, AC-8.4, AC-9.1, AC-9.3, AC-9.4 · **ADRs:** ADR-001
- **Depends on:** T08, T10
- **Size:** M
- **Scope:** `presentation/crop_controller.dart`: Riverpod notifier holding `CropState`, kept alive for the flow session and disposed at flow end (nothing persisted); action handler table (move ×4, zoom ±, centre, reset; handle/rotate actions added when T09 exists) calling the same reducers; announcement composer producing polite messages on actions, button presses, edge reached and upscale threshold crossings (1.0 and 2.0), never per drag update. No widgets.
- **Done when:** `crop_controller_test.dart` passes: each action handler gives the same cropRect as the matching reducer; a drag of 60 updates produces 0 announcements and a threshold crossing produces exactly 1; an edge-reached move produces the edge message; leaving and re-entering the screen in the same session restores cropRect, zoom and rotation; ending the flow disposes the state; announcement text contains no file name, path or EXIF value.

### - [ ] FEAT-002-T12 — JNIgen bindings, `SourceHandle` and `SourceProbe`
- **Implements:** FR-2, FR-3 (read), FR-6 (ceiling), FR-15 (flag), FR-17, FR-24, NFR-10, AC-3.3, AC-7.1, AC-7.2, AC-7.4 · **ADRs:** ADR-001, ADR-004
- **Depends on:** T04 (G1), T05, T06
- **Size:** M
- **Scope:** final JNIgen config and bindings in `packages/es_codec/lib/src/android/` for `BitmapRegionDecoder`, `BitmapFactory(.Options)`, `Bitmap`, `ExifInterface` (orientation only), `ContentResolver`/`ParcelFileDescriptor`, `Activity.setRecentsScreenshotEnabled`; `data/source_handle.dart` (redacted `toString`); `data/source_probe.dart`: open read-only (`"r"`), bounds-only decode, header sniff for animation (WebP `VP8X`/`ANIM`, PNG `acTL`, GIF), orientation with the T04 HEIF rule, decode path from the T04 table, 200 MP ceiling and any T04 per-format threshold → `IMAGE_TOO_LARGE`; platform exception text never logged, mapped to `Reason`.
- **Done when:** `source_probe_test.dart` (integration, emulator profile, both API levels) gives the expected `SourceInfo` or `Reason` for every T02 small fixture, including orientation 1–8, invalid values as 1, the `.jpg` text file → `CORRUPT_INPUT` or `UNSUPPORTED_INPUT`, the 200,000,001 px header → `IMAGE_TOO_LARGE` with no pixel decode; `SourceHandle.toString()` contains no URI text; each fixture's bytes and mtime are unchanged after probing; JPEG, PNG, WebP and HEIC go through the same code path.

### - [ ] FEAT-002-T13 — `es_resample` (stb Catmull-Rom), goldens and visual chart — gate G2
- **Implements:** FR-8 (separate x/y scales), FR-9, FR-14 (alpha), AC-2.3, AC-5.6, AC-6.3, NFR-3, NFR-9 · **ADRs:** ADR-005
- **Depends on:** T01, T04 (G1)
- **Size:** M
- **Scope:** `packages/es_codec/src/crop.c` (and header): `es_resample` from a source pointer with any stride to a tight W×H buffer, `STBIR_TYPE_UINT8`, Catmull-Rom, edge clamp, `STBIR_RGBA` for alpha sources and `STBIR_4CHANNEL` for opaque ones; sources added in `lib/src/c_library.dart`; FFIgen bindings; host and emulator tests on synthetic buffers; contact sheet tool producing the chart at Catmull-Rom and Mitchell.
- **Done when:** `es_resample_test.dart` passes on the host and the emulator: output is exactly W×H for 3000×3000 → 300×300, 3000×800 → 300×80, 2333×1000 → 140×60, 1×1 → 300×300; a same-size resample equals the input (or the maximum deviation is recorded and reported as "identity within the pinned algorithm", PRD section 9); a red opaque shape on transparent pixels shows no dark fringe (RGB of every pixel with alpha > 0 within ±2 of red); SHA-256 goldens for about 10 cases are stable over two runs; the chart (diagonal lines, zone plate, thin strokes, alpha edge) is attached to the PR and shown to the Product Owner, and gate G2 is recorded.

### - [ ] FEAT-002-T14 — `es_orient`, `es_finish` and bitmap pixel access
- **Implements:** FR-3, FR-14, FR-21, AC-3.5, AC-6.1, AC-6.2, AC-12.3 · **ADRs:** ADR-004, ADR-005, ADR-003
- **Depends on:** T06, T13
- **Size:** M
- **Scope:** `packages/es_codec/src/crop.c`: `es_orient` (lossless D4, 8 transforms in the same order as `domain/orientation.dart`); `es_finish` (alpha scan, in-place compaction 4 → 3 channels when opaque); `es_bitmap_lock`/`unlock` via jnigraphics, or the `copyPixelsToBuffer` fallback chosen in T04; `hook/build.dart` links `jnigraphics` for Android targets only; FFIgen bindings.
- **Done when:** tests pass on the host (orient, finish) and the emulator (lock): for all 8 transforms `es_orient` gives the same grid as the Dart D4 mapping; one pixel with alpha 254 → `hasTransparency` true and 4 channels; all alpha 255 → false and 3 channels with RGB unchanged; a synthetic bitmap's pixels read in C match the Java values; CI builds 3 ABIs and `tool/check_16kb_alignment.sh` passes; release build tree-shaking check still passes.

### - [ ] FEAT-002-T15 — `PreviewDecoder`
- **Implements:** FR-7 (preview display only), FR-10, FR-18 (off UI thread), FR-25 (preview ≤ 2048), AC-4.1 · **ADRs:** ADR-004
- **Depends on:** T12, T14
- **Size:** S
- **Scope:** `data/preview_decoder.dart`: worker isolate; sample size so the long side is ≤ 2048; region or full path per `SourceInfo`; config/colour-space check → `UNSUPPORTED_INPUT`; Java OOM → `OUT_OF_MEMORY_HANDLED`; pixels → `ui.ImageDescriptor.raw` → `ui.Image`; bitmap recycled on every path. The preview type is not accepted by the renderer API.
- **Done when:** `preview_decoder_test.dart` (integration, emulator profile, both API levels) passes: 12 MP and 50 MP fixtures give a preview with long side ≤ 2048 and no crash; T04's unsupported variants give `UNSUPPORTED_INPUT`; animated fixtures give the first frame and set the animation flag; a forced OOM (test hook) gives `OUT_OF_MEMORY_HANDLED`.

### - [ ] FEAT-002-T16 — Crop `MemoryPreflight`
- **Implements:** FR-6, NFR-2 · **ADRs:** ADR-003, ADR-004
- **Depends on:** T04 (G1), T05; FEAT-004-T18 (`/proc/meminfo` reader)
- **Size:** S
- **Scope:** `data/crop_memory_preflight.dart` reusing FEAT-004's reader: (decoded region × T04 per-format factor + output + transform buffer) × 2 against `MemAvailable` → `IMAGE_TOO_LARGE`; unreadable meminfo → check skipped.
- **Done when:** `crop_memory_preflight_test.dart` passes with an injected reader: a 12 MP → 2 MP request with ample memory passes; a 24 MP target with low `MemAvailable` → `IMAGE_TOO_LARGE`; unreadable meminfo → no crash and no refusal.

### - [ ] FEAT-002-T17 — `CropRenderer` pipeline producing the ADR-003 `PixelBuffer`
- **Implements:** FR-1 (re-check), FR-7, FR-8, FR-9, FR-10, FR-13, FR-14, FR-16, FR-17, FR-19, FR-21, NFR-2 (single buffer) · **ADRs:** ADR-003, ADR-004, ADR-005
- **Depends on:** T07, T12, T14, T16; FEAT-004-T16 (`PixelBuffer` type and isolate-runner pattern)
- **Size:** M
- **Scope:** `data/crop_renderer.dart`: tech.md section 3 steps 1–9 in a worker isolate; re-open the URI read-only each render; bounds differ from probe → `SOURCE_UNAVAILABLE`; region decode at `sampleSize`; `es_resample` into a native W×H buffer; `es_orient` only if the transform is not identity (free the first buffer); `es_finish`; assert width, height, channels ∈ {3, 4}, stride → `INTERNAL_ERROR` and free on mismatch; `PixelBuffer` with `hasTransparency`, `upscaleFactor`, `cropRect`, `rotationApplied` (manual only), no orientation, path or EXIF field.
- **Done when:** `crop_renderer_test.dart` (integration, emulator profile) passes: outputs are exactly 300×300, 300×80, 140×60 and 1×1 → 300×300 from the fixtures; a partly transparent PNG gives 4 channels and `hasTransparency` true, an opaque-alpha PNG gives false; orientation-6 source with 0 manual turns gives `rotationApplied` 0; one manual clockwise turn gives 90; a test-hook dimension mismatch returns `INTERNAL_ERROR` and nothing is handed off; the preview `ui.Image` is never an input (type check in the test).

### - [ ] FEAT-002-T18 — Renderer errors, cancel, progress events and handover contract (unblocks FEAT-004-T27)
- **Implements:** FR-6, FR-16, FR-18, FR-19, AC-4.3, AC-4.4, AC-7.5 · **ADRs:** ADR-003
- **Depends on:** T17
- **Size:** M
- **Scope:** `data/crop_renderer.dart`: Java `OutOfMemoryError` and native allocation failure → `OUT_OF_MEMORY_HANDLED`; revoked or deleted source → `SOURCE_UNAVAILABLE`; cancel flag between steps → `CANCELLED`; `RenderStep` progress events; try/finally frees the bitmap and buffers on every path; debug leak counter; producer-side contract test that hands the `PixelBuffer` to a fake consumer which frees it (ownership transfer).
- **Done when:** tests pass on the emulator profile: deleting the fixture after probing gives `SOURCE_UNAVAILABLE`; cancel during decode or resample gives `CANCELLED` within one step; a forced OOM gives `OUT_OF_MEMORY_HANDLED` with no crash; the leak counter is 0 after 100 mixed runs (success, failure, cancel); the contract test asserts width, height, channels, tight stride and that the producer no longer frees the buffer after handover. FEAT-004-T27 can start once this task is done (note it in `docs/CHANGELOG.md`).

### - [ ] FEAT-002-T19 — `RecentsGuard`
- **Implements:** FR-26 · **ADRs:** ADR-001
- **Depends on:** T12
- **Size:** S
- **Scope:** `presentation/recents_guard.dart` (route observer or widget): `Activity.setRecentsScreenshotEnabled(false)` on push and `true` on pop, only on API 33+, via the T12 binding; no `FLAG_SECURE`.
- **Done when:** a unit test with a fake binding shows false on push and true on pop, and no call below API 33; an integration test on API 28 shows no crash; on the latest-API emulator the recents thumbnail of a test screen showing a synthetic image is blank while `adb exec-out screencap` still captures it (screenshots attached to the PR); a test finds no `FLAG_SECURE` in the app code.

### - [ ] FEAT-002-T20 — Privacy guards for the crop module
- **Implements:** FR-17, FR-24, NFR-5, NFR-7, AC-11.1, AC-11.3, AC-11.4 · **ADRs:** ADR-003
- **Depends on:** T17; FEAT-004-T21 (import-ban test and enum-only logger)
- **Size:** S
- **Scope:** extend the FEAT-004 import-ban test to `lib/features/crop/`; route crop outcomes through the enum-only logger; a test that bans write APIs in the crop module (`openOutputStream`, mode `"w"`/`"rw"`, `File.write*`, `delete`); app-cache listing before/after renders.
- **Done when:** the import-ban test fails on a planted network import in `lib/features/crop/` and passes on the real code; the write-API ban test fails on a planted write call; after success, cancel and failure renders the app cache holds no new files (FEAT-002 writes none) and each source fixture is byte-identical with an unchanged mtime; captured logs of a full session contain only enum names (a test rejects path separators, file extensions, URI schemes, numbers tied to crop coordinates and EXIF tag names).

### - [ ] FEAT-002-T21 — Orientation, determinism and re-crop instrumented tests — gate G4
- **Implements:** FR-3, FR-12, FR-13, FR-21, AC-3.1–3.5, AC-8.1–8.3, AC-12.2, AC-12.3, AC-13.5, NFR-3, NFR-9, NFR-10 · **ADRs:** ADR-004, ADR-005
- **Depends on:** T02, T15, T18
- **Size:** M
- **Scope:** `integration_test/crop_orientation_test.dart`, `integration_test/crop_determinism_test.dart`: for the 8 orientations in JPEG and HEIC, compare our render and our preview with the `ImageDecoder` oracle by sampling the coloured quadrants of the arrow pattern; render twice and compare SHA-256; N re-crops ending in the same cropRect vs a fresh render; four rotations vs unrotated; mixed drag/pinch/handle sequences ending in the same cropRect vs a fresh render (pure part via reducers). Optional cross-ABI run: x86_64 emulator vs the S23 Ultra (arm64), recorded only.
- **Done when:** on the emulator profile at both API levels all 16 orientation cases are upright and not mirrored in preview and render, matching the oracle; same-device, same-OS-build renders are byte-identical; re-crop and four-rotation outputs are pixel-identical to fresh renders; the cross-ABI result (identical or not) is recorded in the PR as Should evidence. Gate G4 is recorded.

### - [ ] FEAT-002-T22 — Crop screen design review with the Product Owner (impeccable) — gate G3
- **Implements:** prerequisite for FR-4, FR-5, FR-11, FR-14, FR-20, FR-23, FR-27, FR-28, NFR-4 (visual) · **ADRs:** —
- **Depends on:** T11
- **Size:** S (developer preparation; the Product Owner's design time is not counted)
- **Scope:** stop work and hand the Product Owner a non-visual checklist only (no layouts, colours or mock-ups from the developer): screen states and elements the PRD requires (frame with two-tone outline, dimmed outside, checkerboard, corner handles with ≥ 48 dp outward hit areas, Centre/Reset, nudge/zoom, rotate, upscale notice and confirm dialog, animated-image notice, extreme-ratio hint and touch band, progress after 500 ms, error states, Continue), constraints (≥ 24 dp edge margins, ≥ 48 dp frame short side and targets, 300×80 and 1000:10 layouts, 200% font, RTL mirroring rules, contrast on any photo), and the T10 strings. The Product Owner designs the screen with impeccable (https://github.com/pbakaus/impeccable).
- **Done when:** the Product Owner's impeccable design reference (file or link, no real photos in it) and approval date are recorded in the PR and `docs/CHANGELOG.md`; gate G3 is recorded. T23–T28 do not start before this.

### - [ ] FEAT-002-T23 — Crop canvas: preview, frame, overlay, checkerboard, drag and pinch
- **Implements:** FR-4, FR-14 (checkerboard), FR-25, NFR-4 (contrast), AC-1.1–1.3, AC-6.4 · **ADRs:** ADR-004
- **Depends on:** T22 (G3), T11, T15
- **Size:** M
- **Scope:** `presentation/crop_canvas.dart` built to the G3 design: preview `ui.Image` painted under one matrix (orientation × zoom/pan) inside a `RepaintBoundary`; dimmed outside; two-tone frame; checkerboard under alpha; frame layout with ≥ 24 dp margins and ≥ 48 dp short side, and the extreme-ratio touch band plus hint beyond about 6.5:1 (FR-4, OQ-14); drag and pinch through the T08 reducers, one gesture mode until all pointers lift; physical coordinates (no RTL mirroring of the canvas).
- **Done when:** widget tests pass: 4000×3000 → 300×300 shows a square frame over the centred area; 3000×4000 → 300×80 shows a fully visible strip ≥ 48 dp high on a 360 dp-wide screen; 1000:10 shows the full-width band with the hint; a drag beyond the edge stops at the edge; the checkerboard shows under a transparent fixture; golden screenshots match the G3 design on synthetic images only.

### - [ ] FEAT-002-T24 — Crop area semantics, Centre/Reset and upscale notice/dialog
- **Implements:** FR-5, FR-11, NFR-4, AC-5.1–5.4, AC-9.1, AC-9.2, AC-9.4 · **ADRs:** —
- **Depends on:** T23, T10
- **Size:** M
- **Scope:** `Semantics` on the crop area with label, value and custom actions wired to the T11 handlers; Centre and Reset buttons (≥ 48 dp, labelled); upscale notice with icon and text in a polite live region; confirm dialog above 2.0 at Continue ("Continue anyway" / "Choose another photo").
- **Done when:** widget tests pass: the semantics tree exposes move ×4, zoom ±, centre and reset, and each gives the same cropRect as the gesture; Centre and Reset are ≥ 48 dp with labels; a 200×200 source at 300×300 shows the notice with icon and text and Continue enabled; a factor above 2.0 opens the dialog and both choices work; zooming across 1.0 or 2.0 updates the notice and emits one live-region announcement.

### - [ ] FEAT-002-T25 — Continue flow: render, progress, cancel, errors, notices, recents guard
- **Implements:** FR-1, FR-2 (messages), FR-15, FR-16 (message), FR-18, FR-19, FR-26 (hook-up), AC-2.1, AC-2.2, AC-4.3, AC-7.1–7.5 · **ADRs:** ADR-003
- **Depends on:** T24, T18, T19
- **Size:** M
- **Scope:** `presentation/crop_screen.dart`: Continue (debounced, one render at a time) → `CropRenderer`; progress shown after 500 ms with cancel; every `Reason` mapped to its T10 message with one next action; animated-image notice; `RecentsGuard` applied to the route; `PixelBuffer` passed to a hand-off callback (FEAT-004 wiring is FEAT-004-T27); a changed target re-initialises the frame (AC-2.2). Tests use fixture URIs and fixed targets, since FEAT-001/005/011 are not built.
- **Done when:** widget and integration tests pass: a double tap on Continue starts one render; a render over 500 ms (test delay) shows progress and cancel returns to the screen with nothing handed off; each `Reason` shows its message and next action; an animated fixture shows the notice; a new target changes the frame ratio and output size; the callback receives a W×H buffer.

### - [ ] FEAT-002-T26 — RTL, 200% font, device rotation and split-screen
- **Implements:** FR-20, FR-23, NFR-4, NFR-6, AC-9.5, AC-10.2 · **ADRs:** —
- **Depends on:** T25
- **Size:** S
- **Scope:** `presentation/`: control rows under `Directionality`, canvas and nudge directions physical; scrollable controls at 200% font with the frame kept visible; geometry recomputed on layout from `CropState`.
- **Done when:** widget tests pass: in `ar` the control rows, back and Continue mirror while the frame, handles and nudge arrows do not; at text scale 2.0 every control is reachable by scrolling and the frame stays fully visible; a simulated rotation and a split-screen size change keep the same cropRect.

### - [ ] FEAT-002-T27 — Corner handles UI (Should)
- **Implements:** FR-28, AC-13.1–13.8 · **ADRs:** —
- **Depends on:** T23, T09
- **Size:** M
- **Scope:** `presentation/crop_canvas.dart`: four handles per the G3 design; 48 dp hit areas pushed outward when the frame is under 96 dp in either dimension; handle gesture as one gesture mode; re-centre and re-fit on release without changing cropRect; `Semantics` labels per handle; physical positions in RTL.
- **Done when:** widget tests pass: on a 300×80 frame the four hit areas are ≥ 48 dp and do not overlap; dragging out past the image edge stops at the edge with the opposite corner fixed; shrinking stops at the minimum and updates the notice; release re-fits the view and leaves cropRect unchanged; pinch during a handle drag is ignored; TalkBack labels read "Resize crop, top-left corner" etc.; in `ar` handles stay at the physical corners.

### - [ ] FEAT-002-T28 — Rotate and nudge/zoom buttons (Should)
- **Implements:** FR-21, FR-27, AC-9.2, AC-12.1 · **ADRs:** ADR-004
- **Depends on:** T24, T09
- **Size:** S
- **Scope:** `presentation/`: rotate clockwise / counter-clockwise buttons; nudge up/down/left/right (long-press repeats) and zoom in/out buttons, each ≥ 48 dp and labelled, calling the T08/T09 reducers.
- **Done when:** widget tests pass: each button gives the same cropRect as its reducer; long-press repeats a nudge until released and stops at the edge with the edge announcement; rotate keeps the frame ratio and shows no empty area; all buttons are ≥ 48 dp with labels.

### - [ ] FEAT-002-T29 — Emulator run: memory, reliability, offline; timings and frame rate informational — gate G5
- **Implements:** NFR-1, NFR-2, NFR-5, NFR-8, FR-6, FR-25, AC-4.1–4.4, AC-11.2 · **ADRs:** ADR-003, ADR-004, ADR-005
- **Depends on:** T20, T21, T26 (and T27, T28 if the Shoulds ship)
- **Size:** M
- **Scope:** on the emulator profile at API 28 and the latest API, with the T02 large set: crop screen time to first frame after probe (12 MP); render times 12 MP → 2 MP and 50 MP sources (20 runs, median and p95); peak memory via `dumpsys meminfo` for 12 MP → 2 MP and a 24 MP target; 100 MP, 200 MP, corrupt, 1×1 and extreme-ratio runs; profile-mode frame timings during scripted drag and pinch; airplane-mode run. Optional S23 Ultra rows labelled "high-end, not the low-end reference".
- **Done when:** peak memory attributable to FEAT-002 is ≤ 200 MB (12 MP → 2 MP) and ≤ 350 MB (24 MP target) or the run returns `IMAGE_TOO_LARGE`/`OUT_OF_MEMORY_HANDLED`; no crash or ANR on the whole set; the airplane-mode run completes; timings and frame rate are recorded in the PR and `docs/CHANGELOG.md` as informational. Any memory or reliability miss → gate G5.

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T05, T17, T25 | Entry validation UI is FEAT-005 / FEAT-011 |
| FR-2 | T12, T25 | FEAT-001 calls `SourceProbe` right after picking (OQ-11); that call is FEAT-001 work |
| FR-3 | T04, T06, T12, T14, T21 | |
| FR-4 | T07, T08, T23 | |
| FR-5 | T08, T11, T24 | |
| FR-6 | T04, T12, T16, T18, T29 | Low-memory-killer process kills cannot be caught (tech.md gap 2) |
| FR-7 | T04, T07, T15, T17 | |
| FR-8 | T07, T13, T17 | |
| FR-9 | T01, T13, T17 | Gate G2 |
| FR-10 | T04, T15, T17 | |
| FR-11 | T07, T11, T24 | |
| FR-12 | T07, T13, T21 | Same device and OS build; cross-device is Should, recorded in T21 |
| FR-13 | T11, T17, T21 | |
| FR-14 | T13, T14, T17, T23 | Flattening is FEAT-004 FR-12 |
| FR-15 | T04, T12, T15, T25 | |
| FR-16 | T17, T18, T25 | |
| FR-17 | T12, T17, T20 | |
| FR-18 | T03, T15, T18, T25 | No temp files (ADR-003); start-up orphan sweep is FEAT-004-T17 |
| FR-19 | T05, T17, T18, T25 | Consumers: FEAT-004-T27, FEAT-006 |
| FR-20 | T11, T26 | Should |
| FR-21 | T06, T09, T14, T21, T28 | Should |
| FR-22 | T10 | Translations FEAT-019 |
| FR-23 | T26 | |
| FR-24 | T12, T20 | |
| FR-25 | T15, T23, T29 | Should; frame rate informational |
| FR-26 | T12, T19, T25 | FEAT-006 should reuse `RecentsGuard` |
| FR-27 | T08, T28 | Should |
| FR-28 | T09, T27 | Should |
| NFR-1 | T03, T29 | Informational only (PRD v1.3) |
| NFR-2 | T04, T16, T17, T29 | Gates G1, G5 |
| NFR-3 | T13, T21 | Gates G2, G4 |
| NFR-4 | T11, T23, T24, T26 | |
| NFR-5 | T20, T29 | Store/privacy copy FEAT-016 |
| NFR-6 | T10, T26 | Native-speaker review: FEAT-019, Phase B exit |
| NFR-7 | T20 | |
| NFR-8 | T02, T29 | Gate G5 |
| NFR-9 | T02, T05, T13, T21 | Purity starts after decode (tech.md gap 4) |
| NFR-10 | T04, T12, T21 | |

**Not covered by a task:** the PRD section 3 metric "Task speed: median ≤ 15 s from crop screen open to Continue for a first-time user" needs a usability check with people; no task can verify it (see Open questions).

## Open questions
- **`PixelBuffer` home and order:** T17 assumes FEAT-004-T16 has landed and defines `PixelBuffer` and the isolate-runner pattern; T16 and T20 also need FEAT-004-T18 and FEAT-004-T21. If the Product Owner schedules FEAT-002 before those FEAT-004 tasks, the shared pieces move into T16, T17 and T20 (about +0.5 pw here, the same amount less in FEAT-004).
- **Host fixture tools:** T02 assumes ImageMagick and libheif may be used as dev-only tools on the developer machine (never shipped). Large fixtures (up to 200 MP) are generated on demand, not committed.
- **Task-speed metric (≤ 15 s):** no usability test is planned. Options: a short informal test with 3–5 people using synthetic images after T26, or treating the metric as post-release. Product Owner decision.
- **Upstream features not built:** tests use fixture file URIs and fixed targets. Wiring to FEAT-001 (source handle, probe call) and FEAT-005/011 (target) is owned by those features.

## Instructions for Claude Code
- Read `prd.md`, `tech.md` and the linked ADRs before starting a task.
- Native build: where tech.md or an ADR says "CMake" or "jnigraphics link", change `packages/es_codec/hook/build.dart` and `lib/src/c_library.dart` (Dart build hooks with `native_toolchain_c`, ADR-001 v1.2). Vendored code follows the libjpeg-turbo pattern: pinned version, SHA-256, build-time checksum, `VENDOR.md`, licence entry.
- Implement only the current task; tick its checkbox and add a line to `docs/CHANGELOG.md` when done.
- Gates: no task from T12 onwards before G1 passes (T05–T11 may run while G1 waits on the Product Owner); no visible crop screen work (T23–T28) before G3; stop at every failing gate and report to the Product Owner.
- UI rule: before designing or building any real UI screen, stop and tell the Product Owner (impeccable, decision 2026-11-20). T22 is that stop.
- If a requirement is unclear or wrong, stop and propose a PRD change.
- Privacy: synthetic test images only, never real faces or signatures; any sensitive value is `[PLACEHOLDER]`; no network calls; never log pixel data, file names, paths, URIs, EXIF values, crop coordinates or platform exception text; the original is opened read-only.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-20 | First draft |
| 1.0 | 2026-11-20 | Approved by Product Owner |
