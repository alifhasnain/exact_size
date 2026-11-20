---
id: FEAT-004-TASKS
title: Compress to a min–max KB range with JPEG/PNG choice — Implementation Tasks
status: Approved
version: 1.1
updated: 2026-11-20
links: [FEAT-004, FEAT-004-TECH, ADR-001, ADR-002, ADR-003]
---

# FEAT-004 — Implementation Tasks

Milestone: R1 Phase A — core. Work top to bottom, one task at a time.

Sizes: **S** = up to half a day, **M** = up to one day; each task is one PR.
Module paths follow ADR-001: `lib/features/compression/{domain,data,presentation}`, native codec in `packages/es_codec/`, tests mirror them under `test/` and `integration_test/`.
"Emulator profile" means an Android emulator with 2 GB RAM on API 28 (and the latest API where stated). No physical low-end device is used (Product Owner decision 2026-11-20); timings measured on the emulator are informational only. "2 MP synthetic image" means a generated 1600×1250 buffer (gradients, noise, edges), never a real photo.

## Decision gates
| Gate | Task | Passes when | If it fails |
|---|---|---|---|
| G0 | T02 | Flutter 3.50.x allows minSdk 28; FFIgen, JNIgen and `record_use` work as ADR-001 assumes | Stop. Propose an ADR-001 change to the Product Owner before T03 |
| G1 | T04 | libjpeg-turbo builds and runs on the emulator profile → **ADR-002 Option C kept** (approved default; no measured encoder decision without a low-end device, Product Owner 2026-11-20) | Build or run fails: stop all FEAT-004 work and report to the Product Owner (Option B fallback needs a decision) |
| G2 | T23 | Goldens are byte-identical across arm64-v8a, armeabi-v7a, x86_64 (FR-21 met) | Apply ADR-002's rule (SIMD off for the differing step); if too slow, report to the Product Owner that FR-21 drops to "both in window" (AC-6.4) |
| G3 | T25 | NFR-2 and NFR-8 met on the emulator profile; NFR-1 timings recorded for information only | Memory or reliability miss: stop and report; timing misses are reported, not a gate |
| G4 | T26 | Tuning confirms quality floor 40 for photos and signatures | Present the proposed value (or per-type floor) to the Product Owner; change the constant only after the decision (PRD FR-7 / OQ-8 change) |

## Tasks

### - [x] FEAT-004-T01 — Project scaffold (shared, not FEAT-004 effort)
- **Implements:** foundation for NFR-4, NFR-9 · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** M
- **Scope:** Flutter 3.50.x with the exact patch pinned (FVM config or documented version); Android app with `minSdkVersion 28`; `flutter_riverpod` pinned (decide on `riverpod_generator` here and note it in the PR); `get_it`, `injectable`, `injectable_generator` and `build_runner` pinned, with `lib/di/injection.dart` (`configureDependencies()`) called from `main()` (ADR-001 v1.1); `flutter_lints` or stricter analysis options; `gen-l10n` set up with `l10n.yaml` and ARB files for en, es, pt_BR, hi, id, ar; empty module skeleton `lib/features/compression/{domain,data,presentation}`, empty local plugin `packages/es_codec/`.
- **Done when:** `flutter analyze` reports 0 issues; `flutter test` passes one smoke test; `flutter build apk --debug` succeeds with minSdk 28 in the merged manifest; the app starts in `ar` with an RTL layout (widget test); `dart run build_runner build` generates the DI config and CI fails if generated files are stale.

### - [x] FEAT-004-T02 — CI and ADR-001 interop checks (shared, not FEAT-004 effort) — gate G0
- **Implements:** — (ADR-001 follow-up) · **ADRs:** ADR-001
- **Depends on:** T01
- **Size:** M
- **Scope:** GitHub Actions CI workflow (analyze, test, `build apk` for arm64-v8a, armeabi-v7a, x86_64); throwaway proof in `packages/es_codec/`: one FFIgen-generated binding to a one-line C function, one JNIgen binding to an Android API (for example `android.os.Build.VERSION.SDK_INT`), `record_use` enabled in the release build.
- **Done when:** CI is green on `main`; Flutter 3.50.x's own minimum Android version is confirmed ≤ API 28 (value and source recorded in the PR and `docs/CHANGELOG.md`); the FFIgen and JNIgen calls return correct values in an integration test on an API 28 emulator; the release build succeeds with `record_use` and an unused binding is shown removed using the check in the official docs; the claims are checked against the official Flutter 3.50 release notes. Any claim that fails → gate G0.

### - [x] FEAT-004-T03 — Speed spike, part 1: libjpeg-turbo FFI build
- **Implements:** NFR-1 (evidence) · **ADRs:** ADR-001, ADR-002
- **Depends on:** T02
- **Size:** M
- **Scope:** spike branch; vendor libjpeg-turbo source at a pinned tag into `packages/es_codec/`; CMake build for the emulator ABI (x86_64, plus arm64-v8a if an arm64 emulator is available); FFIgen bindings for `tj3Init/tj3Set/tj3Compress8/tj3Free/tj3Destroy`.
- **Done when:** on the emulator profile, a debug build encodes the 2 MP synthetic image at q 85 and the output decodes (with the `image` package) to 1600×1250. This task can be merged with FEAT-002's device spike if the Product Owner decides so; until then it is planned here.

### - [x] FEAT-004-T04 — Speed spike, part 2: per-pass timing and encoder decision — gate G1
- **Implements:** NFR-1, NFR-3 (decision) · **ADRs:** ADR-002
- **Depends on:** T03
- **Size:** S
- **Scope:** spike branch; profile-mode benchmark on the emulator profile (informational: emulator CPU timing does not represent low-end phones): Option C (libjpeg-turbo) and Option B (pinned `image` package) encoding the 2 MP synthetic image, configs A (4:2:0, optimised Huffman) and C (4:4:4, standard Huffman), q 40, 75, 100; 2 warm-up runs then 20 timed runs each, back to back so thermal throttling is included.
- **Done when:** a table of median and p95 ms per pass per encoder/config is recorded in `docs/CHANGELOG.md` and the PR, and the gate records **ADR-002 Option C kept** (approved default; no measured switch without a real low-end device) → continue with T05. If libjpeg-turbo does not build or run on the emulator → stop all FEAT-004 work and go back to the Product Owner. No later task starts until this gate is passed.

### - [x] FEAT-004-T05 — `es_codec` productionised: 3 ABIs, 16 KB pages, pinned source
- **Implements:** FR-15, FR-21 (prerequisite), NFR-6 · **ADRs:** ADR-001, ADR-002
- **Depends on:** T04 (G1 = Option C kept)
- **Size:** M
- **Scope:** `packages/es_codec/` CMake for arm64-v8a, armeabi-v7a, x86_64 with identical flags; source tarball SHA-256 checked at build time; 16 KB page alignment linker flags; spike code cleaned up or replaced.
- **Done when:** CI builds all 3 ABIs; the build fails if the vendored source checksum differs from the pinned value (test by altering one byte locally); the 16 KB alignment check from the Android page-size guide (`zipalign -c -P 16` and ELF LOAD alignment 2**14) passes for every `.so` in the APK.

### - [x] FEAT-004-T06 — `TurboJpegEncoder` data adapter
- **Implements:** FR-2, FR-14, FR-15, NFR-3 · **ADRs:** ADR-002, ADR-003
- **Depends on:** T05
- **Size:** M
- **Scope:** `packages/es_codec/` FFIgen bindings (final); `lib/features/compression/data/turbo_jpeg_encoder.dart` implementing `encodeJpeg(q, subsampling, optimise, dpi)` from a native pixel pointer (3 channels): baseline only, JFIF APP0 with density from DPI, no EXIF, no ICC; TurboJPEG error codes mapped to a typed error. (The `Encoder` interface itself lands in T08; this adapter implements it.)
- **Done when:** an integration test on an emulator parses the output of a synthetic image and finds: SOI, APP0 JFIF with density = requested DPI, no APP1/APP2 markers, SOF0 (baseline), sampling factors matching 4:2:0 or 4:4:4, EOI as the last two bytes; two encodes of the same input are byte-identical; an invalid parameter returns the typed error, not a crash.

### - [x] FEAT-004-T07 — Licences and dependency pinning
- **Implements:** — (ADR-002 follow-up, supply chain in FEAT-004-TECH section 7) · **ADRs:** ADR-002
- **Depends on:** T05
- **Size:** S
- **Scope:** register libjpeg-turbo licences (IJG, BSD, zlib) with `LicenseRegistry`; pin the `image` package to an exact version and confirm its licence; note the libjpeg-turbo CVE watch in `packages/es_codec/README.md`.
- **Done when:** a widget test finds the libjpeg-turbo licence texts on the licence page; `pubspec.lock` and `pubspec.yaml` show an exact `image` version; the README names the pinned tag and checksum.

### - [x] FEAT-004-T08 — Result model, reasons, `Encoder` interface, fake encoder
- **Implements:** FR-11, FR-13 (relay of `UNSUPPORTED_INPUT`), FR-19, NFR-9 · **ADRs:** ADR-003
- **Depends on:** T04 (G1 passed)
- **Size:** S
- **Scope:** `domain/`: `CompressionRequest`, `CompressionResult` (`Success`, `Failure`), `Reason` (all 12 codes incl. `NO_FIT`, `WRITE_FAILED`), `Notice` (`narrowRange`, `paddingAdded`, `transparencyFlattened`), `Direction`, `Encoder` interface; `test/.../fake_encoder.dart` returning scripted size curves per (config, q).
- **Done when:** `result_model_test.dart` passes and shows `Failure` has no file path field and `Success` carries size, quality, format, subsampling, Huffman flag, padding bytes and notices; `Reason.values` matches the PRD section 5 list exactly; the domain folder has no Flutter or Riverpod imports (test scans imports).

### - [x] FEAT-004-T09 — `TargetValidator` and `ByteWindow`
- **Implements:** FR-3, FR-4, FR-16 · **ADRs:** —
- **Depends on:** T08
- **Size:** S
- **Scope:** `domain/target_validator.dart`, `domain/byte_window.dart`.
- **Done when:** `target_validator_test.dart` covers every PRD section 8 row (max 1, 2, 10,240, 10,241; min ≥ max; negative; zero max; blank/NaN; decimals; format other than JPEG/PNG) with the specific message key, and no encoder call happens on `INVALID_TARGET` (fake encoder call count 0); `byte_window_test.dart` shows 20–50 → [20,480, 50,000], 49–50 → [49,000, 50,000] with `narrow = true`, min unset → lo = 0.

### - [x] FEAT-004-T10 — `SizeSearch` JPEG main path
- **Implements:** FR-5, FR-6, FR-7, NFR-1 (10-pass cap), NFR-9 · **ADRs:** ADR-002
- **Depends on:** T09
- **Size:** M
- **Scope:** `domain/size_search.dart`: A@100, binary search for the largest q in `[qFloor, 99]` with size ≤ hi, neighbour check q+1, q+2, per-(config, q) size cache, `ABOVE_MAX` / `TOO_DEGRADED` via A@1, hard cap of 10 passes; `qFloor = 40` as one constant.
- **Done when:** `size_search_main_test.dart` with the fake encoder passes: monotonic curve → highest fitting q; non-monotonic curve → the fitting neighbour is chosen; fit only below q 40 → `TOO_DEGRADED`; A@1 > hi → `ABOVE_MAX`; min unset → best q under the ceiling (AC-8.2); pass count ≤ 10 for every scripted curve in the test file.

### - [x] FEAT-004-T11 — FR-8 levers 1–3 and the narrow-window jump case
- **Implements:** FR-4, FR-8 (levers 1–3) · **ADRs:** ADR-002
- **Depends on:** T10
- **Size:** M
- **Scope:** `domain/size_search.dart`: floor path (tech.md section 3 step 4: B@100, binary search in B, C@100) and jump case (step 3: B and C at the same q, then hand to padding).
- **Done when:** `size_search_floor_test.dart` passes one scripted case per branch of steps 3 and 4 (success at B@100, success in B search, success at C@100, hand-off to padding from C@100, from B@100 and from the B-search file); the order A → B → C is asserted from the fake encoder call log; progressive mode is never requested.

### - [x] FEAT-004-T12 — `JpegPadder` and padding outcome
- **Implements:** FR-8 (lever 4), FR-6, FR-15 · **ADRs:** ADR-002
- **Depends on:** T11
- **Size:** M
- **Scope:** `domain/jpeg_padder.dart`: COM segments spliced after APP0; target `min(lo + min(1024, (hi − lo) div 2), hi)`; segments ≤ 65,537 bytes with no segment < 4 bytes; constant payload byte (0x20); `BELOW_MIN` (or `NO_FIT` in the jump case) when `hi − size < 4`.
- **Done when:** `jpeg_padder_test.dart` passes for pad amounts 4, 5, 65,537, 65,538, 65,540 and 200,000 (segment lengths asserted); the padded file ends with FFD9 and nothing after it; it decodes with the `image` package to pixels identical to the unpadded file; payload bytes are all 0x20 (no user, device or time data, AC-2.3); room of 3 bytes → `BELOW_MIN` and `NO_FIT` in the jump case, room of 4 → success; padding twice gives identical bytes.

### - [x] FEAT-004-T13 — Final size gate, notices and failure details
- **Implements:** FR-6, FR-11, FR-19, FR-4 (notice), FR-8 (disclosure) · **ADRs:** —
- **Depends on:** T12
- **Size:** S
- **Scope:** `domain/size_search.dart` result assembly: `lo ≤ finalBytes.length ≤ hi` on the exact bytes; `narrowRange` and `paddingAdded` notices; `closestBytes` and `direction` on every failure.
- **Done when:** `size_gate_property_test.dart` runs 1,000 seeded random targets and size curves and finds every `Success` inside its window, every `Failure` with `closestBytes` and `direction` set (except `INVALID_TARGET` / `CANCELLED`, where they are null), and every padded success carrying `paddingAdded`.

### - [x] FEAT-004-T14 — `Flattener`
- **Implements:** FR-12 · **ADRs:** ADR-003
- **Depends on:** T08
- **Size:** S
- **Scope:** `domain/flattener.dart`: in-place integer composite onto white, 4 → 3 channels in the same native buffer; sets `transparencyFlattened`.
- **Done when:** `flattener_test.dart` gives the exact expected RGB for alpha 0, 1, 128, 254, 255 (rounding rule written in the test); channels become 3; the debug allocation counter shows no new pixel allocation; opaque 3-channel input is untouched and has no notice.

### - [x] FEAT-004-T15 — PNG path and JPEG probe
- **Implements:** FR-9, FR-10, FR-14 · **ADRs:** ADR-002
- **Depends on:** T13, T14
- **Size:** M
- **Scope:** `data/dart_png_encoder.dart` (level 9, 3 or 4 channels, `pHYs` only when DPI is set, no `iCCP`/`eXIf`/text chunks); PNG branch in `SizeSearch`; one probe A@qFloor on `PNG_ABOVE_MAX` setting `jpegWouldFit`.
- **Done when:** `png_path_test.dart` passes: in range → `Success`, and the decoded PNG equals the input pixels for RGB and RGBA (AC-3.1); above max → `PNG_ABOVE_MAX` with `jpegWouldFit` true in one case and false in another; below min → `PNG_BELOW_MIN` with no padding; `pHYs` adds exactly 21 bytes when DPI is set; the result format is always PNG (no automatic switch).

### - [x] FEAT-004-T16 — `CompressionRunner`: isolate, progress, cancel, buffer ownership
- **Implements:** FR-1, FR-17, NFR-2 (single buffer) · **ADRs:** ADR-001, ADR-003
- **Depends on:** T06, T15
- **Size:** M
- **Scope:** `data/compression_runner.dart` and `CompressionService.compress`: worker isolate gets the `PixelBuffer` address; dimension/stride assert at entry (FR-1); progress `(pass, maxPasses)`; cancel flag checked between passes; buffer freed on success, failure and cancel; debug leak counter. Tests use synthetic `PixelBuffer`s that follow the ADR-003 contract (3 and 4 channels, tight stride), since FEAT-002 is not built.
- **Done when:** `compression_runner_test.dart` (integration, emulator) passes: progress events are monotonic and end at the pass count used; cancel during a search returns `CANCELLED` within one pass; leak counter is 0 after 100 mixed runs (success, failure, cancel); a stride or size mismatch is rejected before any encode; the UI isolate frame time stays under 16 ms during a run (no jank test via `IntegrationTestWidgetsFlutterBinding` timeline).

### - [x] FEAT-004-T17 — `TempFiles`, `WRITE_FAILED` and start-up sweep
- **Implements:** FR-20, FR-6, FR-11 (`WRITE_FAILED`) · **ADRs:** ADR-003
- **Depends on:** T16
- **Size:** S
- **Scope:** `data/temp_files.dart`: write only the final file to `<cache>/exactsize_out/<random>.jpg|png`; delete on failure and cancel; sweep at app start (shared with FEAT-002 FR-18).
- **Done when:** `temp_files_test.dart` passes: success leaves exactly one file with a random name containing no user data; failure and cancel leave the folder empty (AC-6.3); a simulated write error (read-only or full directory) returns `WRITE_FAILED` with no file left; the sweep deletes planted leftovers; nothing is written outside app-private cache.

### - [x] FEAT-004-T18 — Memory pre-flight and out-of-memory mapping
- **Implements:** FR-18, NFR-2 · **ADRs:** ADR-003
- **Depends on:** T16
- **Size:** S
- **Scope:** `data/memory_preflight.dart`: read `MemAvailable` from `/proc/meminfo` (injected reader for tests; fall back to allocation failure if unreadable); target above 24 MP → `IMAGE_TOO_LARGE`; encoder working memory × 2 headroom vs `MemAvailable` → `IMAGE_TOO_LARGE`; native allocation failure → `OUT_OF_MEMORY_HANDLED`.
- **Done when:** `memory_preflight_test.dart` passes for: 24,000,000 px allowed, 24,000,001 px → `IMAGE_TOO_LARGE`; low `MemAvailable` text → `IMAGE_TOO_LARGE`; unreadable meminfo → no crash, check skipped; simulated null allocation → `OUT_OF_MEMORY_HANDLED` and the buffer is still freed.

### - [x] FEAT-004-T19 — `OutcomeMessages` and English ARB strings
- **Implements:** FR-11 (message), NFR-4 · **ADRs:** ADR-001
- **Depends on:** T13, T17
- **Size:** M
- **Scope:** `presentation/outcome_messages.dart`; ARB keys with ICU placeholders for every `Reason`, `Notice` and section 8 validation message (English text from the PRD); numbers and "KB" wrapped in U+2068…U+2069; the other 5 locales listed as untranslated for FEAT-019.
- **Done when:** `outcome_messages_test.dart` passes: every `Reason` and `Notice` maps to a key; English output for "can't reach" matches PRD section 8 with formatted [MIN]/[MAX]/[ACHIEVED] values; in `ar` every number and "KB" is inside bidi isolates; no message is built with string concatenation (all go through `AppLocalizations` methods, checked in review and by a test that each message has placeholders where the PRD has values); `gen-l10n` produces the untranslated-keys list handed to FEAT-019.

### - [x] FEAT-004-T20 — Riverpod providers and accessibility hooks for FEAT-006
- **Implements:** FR-17, FR-19, NFR-5 (FEAT-004 part) · **ADRs:** ADR-001
- **Depends on:** T16, T19
- **Size:** S
- **Scope:** `presentation/compression_providers.dart`: provider that reads `CompressionService` from the get_it container (registered with injectable), run state (progress, result) exposed for FEAT-006; one announcement string per state for `SemanticsService.announce` / live region.
- **Done when:** `compression_providers_test.dart` with a fake `CompressionService` registered in get_it passes: progress, success and every failure produce a non-empty localised announcement; rebuilding the listening widget tree (simulated rotation) does not start a second run; cancel through the provider deletes the temp file.

### - [x] FEAT-004-T21 — No-network guard and enum-only logging
- **Implements:** NFR-6, NFR-7 · **ADRs:** ADR-001
- **Depends on:** T16
- **Size:** S
- **Scope:** `test/.../no_network_imports_test.dart` scanning `lib/features/compression/` and `packages/es_codec/`; `data/outcome_log.dart` whose only input type is `Reason`/outcome enum.
- **Done when:** the import-ban test fails on a planted `package:http`, `HttpClient`, `Socket` or `WebSocket` import and passes on the real code; a full logged run (success, failure, cancel) produces log lines containing only enum names, checked by a test that rejects any path separator, file extension or byte value in the captured output.

### - [x] FEAT-004-T22 — Synthetic image generator and same-device golden tests
- **Implements:** FR-15, NFR-3, NFR-9, FR-8 (AC-2.3) · **ADRs:** ADR-002
- **Depends on:** T17, T21
- **Size:** M
- **Scope:** `test/support/synthetic_images.dart`: seeded photo-like images (gradients, noise, shapes, up to 2 MP) and signature-like images (thin strokes on white, for example 140×60), RGB and RGBA; golden SHA-256 hashes of outputs for about 30 fixed (image, target) cases incl. a padded case. No real photos or signatures; any sample asset name is `[PLACEHOLDER]`.
- **Done when:** `golden_determinism_test.dart` passes twice in a row on the x86_64 emulator in CI and on an arm64 emulator if available (AC-6.1); changing the pinned encoder flags makes it fail.

### - [x] FEAT-004-T23 — Cross-ABI golden comparison — gate G2
- **Implements:** FR-21, NFR-3 · **ADRs:** ADR-002
- **Depends on:** T22
- **Size:** S
- **Scope:** run the T22 cases on the emulator ABIs available (x86_64, and arm64-v8a if an arm64 emulator is available) and compare hashes; armeabi-v7a is not tested (no device).
- **Done when:** a comparison table is in the PR: all identical → FR-21 met; any difference → ADR-002 rule applied (SIMD off for the differing step, re-measured against the T04 timing) or the case is reported to the Product Owner as "both in window" (AC-6.4), with every differing output still inside its window.

### - [ ] FEAT-004-T24 — 500-export corpus harness
- **Implements:** FR-6, FR-8, NFR-8, NFR-1 (pass cap) · **ADRs:** ADR-002
- **Depends on:** T22
- **Size:** M
- **Scope:** `integration_test/corpus/`: ≥ 500 synthetic exports (photo and signature, JPEG and PNG, normal, narrow such as 49–50, max-only, tiny max, transparent); offline reference search (all q 1–100 × configs A/B/C + padding) to label each target feasible or infeasible.
- **Done when:** the harness runs in CI and asserts: 100% of exported files inside their window; ≥ 99% success on feasible targets; 100% of infeasible targets end in a failure, not an export; it reports how often the 10-pass cap binds and the share of 140×60 signature targets of 10–20 KB that needed padding (answers the PRD section 11 hypothesis). A threshold miss stops work and goes to the Product Owner.

### - [ ] FEAT-004-T25 — Emulator run: memory, offline, speed (informational) — gate G3
- **Implements:** NFR-1, NFR-2, NFR-6, NFR-8, FR-17 · **ADRs:** ADR-001, ADR-002
- **Depends on:** T18, T20, T24
- **Size:** M
- **Scope:** run the corpus on the emulator profile at API 28 and the latest API; profile memory there; airplane-mode integration test; decode padded outputs with Android `BitmapFactory` on the emulator (risk R6).
- **Done when:** search time for ≤ 2 MP targets is recorded (informational, not a gate); peak memory attributable to FEAT-004 at 2 MP is ≤ 150 MB (measured with `dumpsys meminfo` before/after); the airplane-mode test completes with no network error (AC-6.2); no ANR during runs; all padded files decode on both API levels; numbers recorded in the PR and `docs/CHANGELOG.md`. Any miss → gate G3.

### - [ ] FEAT-004-T26 — Quality-floor tuning on a synthetic visual set — gate G4
- **Implements:** FR-7 · **ADRs:** —
- **Depends on:** T22
- **Size:** M
- **Scope:** encode the synthetic photo and signature set at q 30, 35, 40, 45, 50; produce a side-by-side contact sheet and SSIM per image class [Assumption: SSIM is an adequate proxy, final call is visual]; thin-stroke signatures checked for stroke breakup.
- **Done when:** the contact sheet and SSIM table are attached to the PR and shown to the Product Owner; result is either "40 confirmed for both classes" or a proposed value / per-type floor that waits for a Product Owner decision before the constant changes.

### - [ ] FEAT-004-T27 — Integration with FEAT-002 pixel producer (BLOCKED until FEAT-002's PixelBuffer handover is implemented)
- **Implements:** FR-1, FR-13, FR-18, FR-12, US-5 (AC-5.1–5.3) · **ADRs:** ADR-003
- **Depends on:** T25; FEAT-002 tasks that produce a `PixelBuffer` (not planned yet)
- **Size:** M
- **Scope:** replace synthetic buffers with FEAT-002's real producer in an end-to-end integration test; check ownership transfer, `hasTransparency` flag, `UNSUPPORTED_INPUT` relay, memory pre-check on both sides.
- **Done when:** on the emulator profile, synthetic source files in JPEG, PNG, HEIC and WebP at the same W×H give the same FEAT-004 behaviour and outcome (AC-5.1); a corrupt file shows `UNSUPPORTED_INPUT` without a crash (AC-5.2); a synthetic 50 MP source completes or returns `IMAGE_TOO_LARGE` without a crash (AC-5.3); leak counter is 0 after the run.

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T16, T27 | |
| FR-2 | T06 | |
| FR-3 | T09 | |
| FR-4 | T09, T11, T13 | |
| FR-5 | T10 | |
| FR-6 | T10, T12, T13, T17, T24 | Export-side enforcement (only `Success` files exported) is FEAT-007 |
| FR-7 | T10, T26 | |
| FR-8 | T11, T12, T13, T24 | Showing the padding note is FEAT-006 |
| FR-9 | T15 | |
| FR-10 | T15 | One-tap switch UI is FEAT-006 / FEAT-015 |
| FR-11 | T08, T13, T17, T19 | Display is FEAT-006; richer guidance FEAT-015 |
| FR-12 | T14, T27 | Telling the user before export is FEAT-006 |
| FR-13 | T08, T27 | Decoding is owned by FEAT-002; FEAT-004 only relays `UNSUPPORTED_INPUT` |
| FR-14 | T06, T15 | DPI value from FEAT-010; "no EXIF/ICC" policy from FEAT-018 (their PRDs must state OQ-13) |
| FR-15 | T05, T06, T12, T22 | |
| FR-16 | T09 | |
| FR-17 | T16, T20, T25 | Progress display is FEAT-006 |
| FR-18 | T18, T27 | Low-memory-killer process kill cannot be caught (tech.md R2) |
| FR-19 | T08, T13, T20 | |
| FR-20 | T17 | Sweep shared with FEAT-002 FR-18 |
| FR-21 | T05, T23 | Should; gate G2 |
| NFR-1 | T03, T04, T10, T24, T25 | Gates G1, G3 |
| NFR-2 | T16, T18, T25 | |
| NFR-3 | T04, T06, T22, T23 | |
| NFR-4 | T01, T19 | Translations FEAT-019; native-speaker review is R1 Phase B exit |
| NFR-5 | T20 | Live region, 48 dp targets, font scaling, no colour-only outcome are FEAT-006 (host screen) |
| NFR-6 | T05, T21, T25 | Store/privacy copy FEAT-016 |
| NFR-7 | T21 | |
| NFR-8 | T24, T25 | |
| NFR-9 | T01, T08, T10, T22 | |

## Open questions
- **R1 device matrix:** resolved 2026-11-20: no physical devices; emulators with a 2 GB RAM profile on API 28 and the latest API (Product Owner). Timing targets are best effort.
- **JPEG probe on transparent PNG input (FR-10) and the one-tap switch:** the probe needs flattened pixels; the plan assumes the probe flattens in place after the PNG has already failed, and a switch to JPEG re-requests pixels from FEAT-002 because FEAT-004 frees the buffer on failure (ADR-003). Confirm, or keep the buffer alive until FEAT-006 dismisses the outcome (more memory). Accepted by the Product Owner 2026-11-20: the switch re-runs FEAT-002's render (about 1–2 s extra), no requirement change.
- **Spike merge with FEAT-002's device spike:** not decided by the Product Owner; T03/T04 are planned as FEAT-004 tasks.
- **CI provider:** decided 2026-11-20 by the Product Owner: GitHub Actions (T02).

## Instructions for Claude Code
- Native build: where a task, tech plan or ADR says "CMake", use Dart build/link hooks with `native_toolchain_c` in `packages/es_codec/` instead (ADR-001 v1.2, gate G0 finding 2026-11-20).
- Read `prd.md`, `tech.md` and the linked ADRs before starting a task.
- Implement only the current task; tick its checkbox and add a line to `docs/CHANGELOG.md` when done.
- Do not start any task after T04 until gate G1 is passed and recorded; stop at every gate that fails and report to the Product Owner.
- If a requirement is unclear or wrong, stop and propose a PRD change.
- Tests and fixtures use synthetic images only, never real faces or signatures; any sensitive value is `[PLACEHOLDER]`. No network calls in the pipeline; no logging of image content, file names, paths or pixel data.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-20 | First draft |
| 0.2 | 2026-11-20 | CI = GitHub Actions; PNG-to-JPEG switch re-renders via FEAT-002 (accepted); low-end test device still open |
| 0.3 | 2026-11-20 | DI with get_it + injectable (ADR-001 v1.1): T01 scaffold and T20 updated |
| 0.4 | 2026-11-20 | Emulator-only testing (Product Owner): T03/T04/T22/T23/T25/T27 moved to the 2 GB emulator profile; G1 keeps Option C by default; G3 covers memory and reliability, timings informational; T04 M→S |
| 1.0 | 2026-11-20 | Approved by Product Owner |
| 1.1 | 2026-11-20 | Clarification: native build uses Dart build hooks, not CMake (ADR-001 v1.2). Under Discussion until re-approved |
| 1.1 | 2026-11-20 | Re-approved by Product Owner |
