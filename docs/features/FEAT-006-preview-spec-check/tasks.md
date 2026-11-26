---
id: FEAT-006-TASKS
title: Preview with "meets spec" check — Implementation Tasks
status: Approved
version: 1.0
updated: 2026-11-25
links: [FEAT-006, FEAT-006-TECH, ADR-001, ADR-004, ADR-007, FEAT-002, FEAT-004, FEAT-005, FEAT-007, FEAT-019]
---

# FEAT-006 — Implementation Tasks

Milestone: R1 Phase A — core. Work top to bottom, one task at a time.

Sizes: **S** ≈ 0.25 day, **M** ≈ 0.5 day, **L** ≈ 1 day; each task is one PR.
Module paths follow ADR-001: new `lib/features/preview/{domain,data,presentation}`; changed `lib/features/export/presentation/result_screen.dart`, `lib/app_flow.dart`, `integration_test/result_screen_demo.dart`, FEAT-002's `preview_decoder.dart`, `RecentsGuard` and `crop_canvas.dart` (only what tech section 2 names), and `lib/l10n/app_*.arb`. Tests mirror them under `test/`; device tests in `integration_test/`; fakes in `test_support/`.

**Already built, reused, not planned again:** `checkContainer` over `FileByteSource`, `sniffHeader`, `PreviewDecoder` (ADR-004), `RecentsGuard` and `AndroidRecentsBinding`, `_checkerboard` (FEAT-002); `CompressionSuccess`, `CompressionController.cancel()` (the only deleter of the temp file), `ByteWindow.fromKb`, `achievedKb`, `kbAmount`, `kbRange`, `OutcomeMessages.notice`, `TempFiles` and its start-up sweep (FEAT-004); `TargetSpec` (FEAT-005); `ExportPanel`, `ExportController.leave()`, `ExportMessages.message(ExportOutcome.fileMissing)`, the FR-23 leave dialog, `ExportOutcomeLog` as the log shape (FEAT-007, ADR-007); `TolerantGoldenComparator`; gen-l10n with 6 languages; `integration_test/bundle.dart`; the CI API 28 emulator job.

**Test devices:**
- **Local device runs and screenshots use the connected real phone, Realme 2 Pro, API 36** (check `adb devices` first). The local API 36 emulator (Medium_Phone_API_36.1, `-memory 2048`) is used only for the NFR-1 2 GB timing in T01 and T15 if it is available; start it only if `adb devices` shows no emulator and never kill it (Open items 1).
- **API 28 runs only in the CI emulator job.** Push only at milestones (T01 throwaway run, T15, before G-final); run `flutter analyze` and `flutter test` locally before each push. Throwaway CI runs are slim (only the job and test needed), have `timeout-minutes`, and every wait loop is bounded.
- Files run under `flutter drive` use `testWidgets` only (plain `test()` failures are not reported there). New device tests run from `integration_test/bundle.dart`.

**Real-phone data rule:** synthetic images only (generated gradients, flat colours, checker patterns; never real faces, signatures, documents or cards). FEAT-006 writes nothing to the gallery; a synthetic source shared in with `am start` (FEAT-005 T18 style) is deleted after the run, and anything saved through the panel during a check is deleted with its MediaStore row. File names, paths, URIs, sizes and dimensions of real files never go into the Test record, PR text or screenshot captions; use `[PLACEHOLDER]`, for example `exactsize-300x300-[TOKEN].jpg`.

**Decisions from FEAT-006-TECH section 12 used here (approved with tech.md v1.0 at their proposed defaults):**
- OQ-T1: AC-7.1 means every FEAT-007 behaviour assertion passes unchanged; the allowed edit set is listed below (T05, T12, T13).
- OQ-T2: a WebP, GIF, HEIF or unknown signature is FR-11 unreadable (T03).
- OQ-T3: FR-6 wording clarified in PRD 1.1; `achievedKb` is reused (T06).
- OQ-T4: the unreadable exit runs `leave()` with no "Leave without saving?" confirm (T12).
- OQ-T5: `exportReady` is removed from all 6 ARBs (T13).
- OQ-T6: a same-shape `SpecCheckLog` (T03).
- OQ-T7: exiting during `Checking` uses the FR-23 confirm (T12).
- PRD OQ-1 to OQ-10 are at their defaults (PRD 1.0): block export on mismatch, no zoom, no hide toggle, "Matches your target", no JPEG switch, no enlargement reminder, all four Shoulds kept.

**FEAT-007 test edit set (OQ-T1), exactly and only:**
1. Constructor argument `size:` → `spec:` in FEAT-007's result screen tests and `integration_test/result_screen_demo.dart` (T05).
2. A fake `OutputMeasurer` and preview-decoder override, or a valid synthetic 300×300 JPEG fixture, in place of the 48,200-byte `0x01` fixture where the success state is reached (T12).
3. Retire the "Ready:" result screen test (T12) and the two `ExportMessages.ready` cases in `export_messages_test.dart` (T13).
4. Re-record the 7 result goldens (T12).

Panel, controller, data, domain and privacy test files of FEAT-007 are not edited (checked with `git diff` in T12 and T13).

## Decision gates
| Gate | Task | Passes when | If it fails |
|---|---|---|---|
| G0 Decode and timing spike | T01 | An app-cache `file://` URI decodes through the ADR-004 `PreviewDecoder` on API 36 (Realme 2 Pro) and CI API 28; measure + decode of a 2 MP output is ≤ 500 ms median and ≤ 1.5 s p95; steady extra memory for the preview at a 24 MP output is ≤ 24 MB; peak memory and the 10 MB `checkContainer` time are recorded. All rows in the Test record | Stop. Propose a tech.md change to the Product Owner before T04 (fallbacks in T01). Domain, measurer, log, strings and wiring (T02, T03, T05, T06) may continue |
| G1 Check screen design | T10 | The Product Owner was told before any visual work; one lean impeccable pass is done (Material 3 + existing Booth theme, no image comps, no reviewer subagents, one round); the Product Owner accepted it or named fixes; reference and date recorded | No visible UI work (T11–T14). Non-visual tasks T01–T09 may run |
| G2 Design check | T14 | The Product Owner has seen one Realme 2 Pro screenshot per state named in T10 (synthetic images) and accepts them or names fixes. One look | Fixes go into T14 before T15. A scope change means a PRD change |
| G-final Device run | T17 | Every runnable checklist row passes on the Realme 2 Pro (API 36), CI API 28 is green for `bundle.dart` and `preview_check_test.dart`, and the Product Owner accepts the recorded gaps. Required: no crash, enum-only logs, nothing left in app cache after leave, airplane mode works, recents thumbnail hidden on API 36 | A privacy, data-loss, crash, false "matches" or accessibility miss means stop and report. Otherwise the Product Owner may type `/approve FEAT-006 implemented` |

## Tasks

### - [x] FEAT-006-T01 — Spike: cache `file://` decode, 24 MP memory, timing — gate G0
- **Implements:** verification for FR-13, FR-14, NFR-1, NFR-7 · **ADRs:** ADR-004, ADR-001
- **Depends on:** —
- **Size:** M
- **Scope:** throwaway branch, not merged: `integration_test/preview_spike_test.dart` (`testWidgets` only) plus a temporary `maxSide` argument on a local copy of the decode call. Synthetic JPEG (baseline) and PNG outputs, written into FEAT-004's cache folder (`exactsize_out`). Observe and record:
  - H1: `PreviewDecoder.decode(SourceHandle(Uri.file(path).toString()), …, decodePath: region)` returns `PreviewOk` for a JPEG and a PNG in app cache, on the Realme 2 Pro (API 36) and in one slim CI API 28 run (`timeout-minutes` set, only this target).
  - H2: memory at a 24 MP (6000×4000) output with `maxSide` = the device's physical short side: `dumpsys meminfo <package>` before, polled during (bounded loop) and after the decode on the Realme 2 Pro. Steady extra (image alive, after the decode) is gated at ≤ 24 MB; the transient peak is reported, not gated (tech section 10). Emulator RSS is not used (ADR-004: unreliable).
  - H3: 20 runs of measure (`File.length` + `checkContainer` in `Isolate.run`) then decode for a 2 MP JPEG and PNG output: median and p95 on CI API 28, the Realme 2 Pro and, if available, the local 2 GB API 36 emulator.
  - H4: `checkContainer` time on a 10,240,000-byte JPEG and PNG (tech [Hypothesis] ≤ 100 ms), reported.
- **Fallbacks to propose if a row fails:** H1 → `ParcelFileDescriptor.open` through a JNIgen binding (still ADR-004, small regeneration); H3 → run the measurer inside the decode isolate (no API change); H2 → a smaller `maxSide` cap. Each is a tech.md change for the Product Owner, not improvised.
- **Done when:** each H row has one Test record line per device or CI run (pass/fail and numbers; no paths or file names). Gate G0 is recorded. Spike code is deleted.

### - [x] FEAT-006-T02 — Domain: `MeasuredOutput`, `MeasureResult`, `OutputMeasurer`, `checkSpec`
- **Implements:** FR-3, FR-4, FR-6 (`sizeDirection`), FR-8 (`window.narrow`), NFR-5, NFR-6 · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** M
- **Scope:** `lib/features/preview/domain/` per tech 4.1 and 4.2: `MeasuredOutput {bytes, width, height, format, hasAlpha}` with redacted `toString`; sealed `MeasureResult` (`Measured`, `Unreadable`); `OutputMeasurer` interface; `SpecCheck {pixels, size, format, window, sizeDirection, meets}` with redacted `toString`; `checkSpec(MeasuredOutput, TargetSpec)` using `ByteWindow.fromKb(minKb:, maxKb:)` and only width, height, minKb, maxKb, format. No Flutter, Riverpod, get_it or `dart:io` imports.
- **Done when:** `test/features/preview/domain/spec_check_test.dart` passes: floor and ceiling meet, floor − 1 and ceiling + 1 fail with `tooSmall` / `tooBig` (AC-2.2); width ± 1 and height ± 1 fail `pixels`; format swap fails `format`; 49–50 KB at 49,500 B meets with `window.narrow` true (AC-2.3); max-only target has floor 0; a generated set of at least 10,000 cases (random targets incl. narrow and max-only, sizes at window edges ± 1) agrees 100% with `ByteWindow.contains` and exact pixel and format equality (NFR-5); `toString` of both types built from synthetic values contains no number from the input. A grep test finds no `1024` or `1000` literal in `lib/features/preview/` (one window definition, FR-4) and no forbidden import in `domain/`.

### - [x] FEAT-006-T03 — `FileOutputMeasurer`, `SpecCheckLog`, DI
- **Implements:** FR-2, FR-11 (measure side), FR-19 (enum-only log), NFR-1 (off the UI thread), NFR-6 · **ADRs:** ADR-004, ADR-001
- **Depends on:** T02
- **Size:** M
- **Scope:** `lib/features/preview/data/file_output_measurer.dart` per tech section 3: `Isolate.run`; missing, empty, unopenable or length ≠ `expectedBytes` → `Unreadable`; `checkContainer(FileByteSource)` `ContainerOk` JPEG/PNG → `Measured` (alpha from `sniffHeader`), anything else, including WebP, GIF, HEIF and unknown signatures → `Unreadable` (OQ-T2); catches everything and keeps no exception text; `@LazySingleton(as: OutputMeasurer)`, `build_runner` output committed. `spec_check_log.dart` in the `ExportOutcomeLog` shape, taking enums only (no `String` or `int` parameter). Synthetic fixtures generated in the test with `package:image` (tests only).
- **Done when:** `test/features/preview/data/file_output_measurer_test.dart` passes: JPEG and PNG fixtures give byte length, width, height and format equal to the `package:image` oracle and `File.length` (FR-2); a file swapped after the result was built gives the swapped file's values (AC-1.2); a `.jpg` name holding PNG bytes gives PNG; missing, empty, truncated (JPEG without EOI, PNG without IEND, bad CRC), length ± 1 and WebP/GIF signatures give `Unreadable` (AC-3.4); the real FEAT-004 encoders' outputs over the FEAT-004 golden and runner cases, plus JPEGs padded with COM segments of 4 B and 65,537 B, give 0 `Unreadable` (tech risk 2, "no false doesn't match"); those outputs contain no APP1 segment and no eXIf chunk (PRD section 9 assumption). `spec_check_log_test`: every line matches `^exactsize\.preview outcome=(SPEC_MEETS|SPEC_MISMATCH fields=(DIMENSIONS|SIZE|FORMAT)(,(DIMENSIONS|SIZE|FORMAT))*|SPEC_UNREADABLE|PREVIEW_UNAVAILABLE)$`.

### - [x] FEAT-006-T04 — FEAT-002 small changes: `maxSide`, `paintCheckerboard`, ref-counted `RecentsGuard`
- **Implements:** FR-13, FR-14 (bounded decode), FR-15, FR-19 (recents) · **ADRs:** ADR-004
- **Depends on:** T01 (G0)
- **Size:** S
- **Scope:** per tech section 2: `PreviewDecoder.decode(src, info, {int maxSide = maxSide})` and `previewSampleSize(w, h, [maxSide])`, default 2048 unchanged; `resultPreviewDecoderProvider` seam (FEAT-002's `previewDecoderProvider` stays where it is); `_checkerboard` → public `paintCheckerboard`; `RecentsGuard` with a static depth counter (disable on 0→1, enable on 1→0). Any T01 fallback the Product Owner approved goes here.
- **Done when:** new `previewSampleSize` cases with `maxSide` 1080 for 6000×4000 and 2000×1000 give the expected sample sizes written from the function's rule; every existing FEAT-002 decoder, crop canvas and golden test passes unchanged; `recents_guard_test` nested case passes: outer mount disables once, inner mount makes no call, inner unmount keeps protection off, outer unmount enables once.

### - [x] FEAT-006-T05 — `TargetSpec` wiring: `ResultScreen(spec:)`
- **Implements:** FR-3 · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** S
- **Scope:** `ResultScreen({required TargetSpec spec, required VoidCallback onStartOver})`, `size` becomes `spec.dimensions` everywhere inside; `lib/app_flow.dart` passes `widget.spec`; `integration_test/result_screen_demo.dart` same one-line change. FEAT-007 test edit 1 only (constructor argument). Behaviour unchanged, so the 7 result goldens stay.
- **Done when:** a new `test/app_flow_test.dart` case shows the pushed `ResultScreen.spec` equals the spec entered (width, height, minKb, maxKb, format) for a min+max and a max-only target; the whole FEAT-007 suite passes with a diff limited to `size:` → `spec:`; goldens unchanged.

### - [x] FEAT-006-T06 — English strings and `CheckMessages`
- **Implements:** FR-5, FR-6, FR-7 (wording), FR-16, FR-23, NFR-4 · **ADRs:** ADR-001
- **Depends on:** T02
- **Size:** M
- **Scope:** the 17 keys of tech 4.5 in `lib/l10n/app_en.arb` with `@` descriptions and ICU placeholders, English text from PRD section 8, no concatenation. `lib/features/preview/presentation/check_messages.dart`: row labels, target texts (`kbRange`, `checkUpToKb`), measured KB through `achievedKb(bytes, sizeDirection)` (reused, not copied), `checkPixels`, `previewAlt`, `checkRowSentence`; numbers, `px`, `KB` and format names wrapped in the existing LRI/FSI isolates in code (never in the ARB), Western digits.
- **Done when:** `flutter gen-l10n` passes. `test/features/preview/presentation/check_messages_test.dart` passes: 50 KB max with 50,001 B reads "50.1 KB" and with 50,020 B reads above 50.0 (AC-3.2); 20 KB min with 20,000 B reads "19.5 KB" (FR-6); max-only 100 KB target reads "Up to 100 KB" (AC-1.3); `previewAlt(300, 300, JPEG)` renders "Preview of your new file, 300 × 300 px, JPEG." with the numbers isolated (AC-4.6); the row sentence matches "[LABEL]: target [TARGET], this file [MEASURED], [STATUS]." (AC-8.2); no English value of a new key contains "accept", "approve" or "guarantee" (FR-7). The existing "no literal numbers in ARB" test passes with the new keys. The PR lists the keys.

### - [x] FEAT-006-T07 — `SpecCheckController`: sequence and states
- **Implements:** FR-1, FR-10 (delete and log), FR-11, FR-14 (OOM → placeholder, log), NFR-6 · **ADRs:** ADR-001, ADR-004
- **Depends on:** T03, T04
- **Size:** M
- **Scope:** `lib/features/preview/presentation/spec_check_controller.dart`: `NotifierProvider.autoDispose.family<…, SpecCheckState, TargetSpec>`; sealed `SpecCheckState` (`CheckIdle`, `Checking`, `CheckMeets(success, measured, check, ui.Image?)`, `CheckMismatch`, `CheckUnreadable`); steps 1–5 of tech 4.3, including `CompressionController.cancel()` on mismatch and `maxSide: min(physicalShortestSide, 2048)`. `test_support/fake_output_measurer.dart` and a fake preview decoder for the seam.
- **Done when:** controller tests pass with the fakes and a fake compression state: `CheckIdle` until `CompressionDone(success)`; then `Checking`, then `CheckMeets(image)` in one transition with `SPEC_MEETS` logged once; `measure` receives `expectedBytes == success.sizeBytes`; width + 1 → `CheckMismatch`, `cancel()` called once, temp file gone, no decode call, `SPEC_MISMATCH fields=DIMENSIONS` (and `SIZE`, `FORMAT` cases); `Unreadable` → `CheckUnreadable` + `SPEC_UNREADABLE`; `PreviewErr(outOfMemoryHandled)` → `CheckMeets(null)` + `SPEC_MEETS` + `PREVIEW_UNAVAILABLE`; any other `PreviewErr` → `CheckUnreadable`; the `Idle` that follows `cancel()` or `leave()` does not reset the state.

### - [x] FEAT-006-T08 — `SpecCheckController`: resume, leave while measuring, image disposal
- **Implements:** FR-12, FR-19 (decoded copy released), AC-6.2 · **ADRs:** ADR-001
- **Depends on:** T07
- **Size:** M
- **Scope:** tech 4.3 steps 6 and 7: one `AppLifecycleListener(onResume:)` re-measures once while in `CheckMeets`; `ref.mounted` after every await; the `ui.Image` is disposed on every transition, on a late arrival and on dispose.
- **Done when:** controller tests pass: resume after deleting the file → `CheckUnreadable` and the image disposed; resume after replacing it with an off-by-one file → `CheckMismatch`; resume with the file unchanged → `measure` called once more and the state instance unchanged (no redraw); resume in `Checking`, `CheckMismatch` or `CheckUnreadable` does nothing; disposing the container while the fake measurer or decoder is pending → no state set and the late fake image records `dispose()`; disposing in `CheckMeets` → image disposed.

### - [x] FEAT-006-T09 — Preview privacy static test and log audit
- **Implements:** FR-19, NFR-3, NFR-8 · **ADRs:** —
- **Depends on:** T08
- **Size:** S
- **Scope:** new `test/features/preview/preview_privacy_test.dart` in the `export_privacy_test.dart` pattern, scanning `lib/features/preview/`: bans `print(`, `debugPrint(` and `log(` outside `SpecCheckLog`, `HttpClient`, `Socket`, network imports (extend `no_network_imports_test.dart` scope), `Image.file`, `FileImage`, `MemoryImage`, `Image.memory`, `shared_preferences`, `restorationId`, `Clipboard`, any ad, analytics or crash SDK import. Log audit: run the T07–T08 suites with a capturing log sink.
- **Done when:** the test passes on the current tree and the PR shows it failing once per rule when a forbidden token is added to a scratch file. Every captured preview line matches the T03 regex; no line contains a digit, `exactsize-`, `/data/`, `/storage/`, `content://` or a `[PLACEHOLDER]` test value (AC-6.3). Because it scans the whole folder, it also guards the UI tasks.

### - [x] FEAT-006-T10 — Check screen design pass with the Product Owner (impeccable, lean) — gate G1
- **Implements:** prerequisite for FR-5, FR-7–FR-9, FR-13–FR-18, NFR-2, NFR-4 (visual) · **ADRs:** —
- **Depends on:** T06, T08
- **Size:** M (developer side; the Product Owner's time is not counted)
- **Scope:** **Stop and tell the Product Owner before any visual work.**
  - One short impeccable pass on Material 3 and the existing Booth theme. No image comps, no reviewer subagents, no multi-round critique.
  - Inputs: states `Checking`, matches (JPEG with and without notices, transparent PNG, preview unavailable), mismatch, unreadable; the T06 strings; the embedded `ExportPanel` unchanged.
  - Constraints: reading and focus order preview → headline → rows → notices → caveat → panel → Done (FR-7); preview box ≤ 40% of screen height and ≤ 4 device pixels per image pixel (named constants, may be tuned within FR-14); no gesture on the preview; status as icon plus word; one live region for the headline; ≥ 48 dp; 200% font at 360×640 with no horizontal scroll; RTL mirrored with numbers, units and format names LTR and unbroken.
  - Define the G2 screenshots: matches with padding notice, matches transparent PNG, preview unavailable (forced), mismatch (forced), unreadable (forced), ar RTL, 200% font.
- **Done when:** the design reference (file, synthetic content only) and its date are in the PR and `docs/CHANGELOG.md`; the Product Owner's acceptance or fixes are recorded; gate G1 is recorded in the Test record.

### - [x] FEAT-006-T11 — `SpecCheckView`
- **Implements:** FR-5, FR-7, FR-8, FR-9, FR-13, FR-14 (box and placeholder), FR-15, FR-16, FR-17, FR-18, NFR-2 · **ADRs:** ADR-001
- **Depends on:** T10 (G1)
- **Size:** M
- **Scope:** `lib/features/preview/presentation/spec_check_view.dart`, built to the G1 design: `RawImage` in a sized box computed from the **measured** W×H, `BoxFit.contain`, `paintCheckerboard` under alpha, no filter or overlay, no gesture detector; caption; headline in `Semantics(liveRegion: true)`; three rows each `Semantics(label: rowSentence, excludeSemantics: true)`; one `BoothNotice` per `success.notices` item via `OutcomeMessages.notice`; the 1,024 line when `!window.narrow`; the caveat line; the "Preview isn't available" placeholder when the image is null.
- **Done when:** widget tests pass: three rows in fixed order with target and measured texts (AC-1.1, AC-1.3); all meet → "Matches your target", each row icon plus "Meets" (AC-2.1); 1,024 line shown for a non-narrow and hidden for a narrow window (AC-2.4); caveat present (AC-2.5); narrow, padding and transparency notices shown once each, none → no notice widget (AC-5.1, AC-5.2); box aspect equals the measured aspect within 1 px, height ≤ 0.4 × screen height and scale ≤ 4 for 300×300, 140×60 and 6000×4000 (AC-4.1, FR-14); preview semantics label equals `previewAlt` (AC-4.6); a drag starting on the preview scrolls the page and no `GestureDetector`/`InteractiveViewer` wraps it (AC-4.7); null image → placeholder text, rows still shown (AC-4.4); `find.byType(Image)` finds nothing and `imageCache.currentSize == 0`.

### - [ ] FEAT-006-T12 — `ResultScreen` success branch, leave rules, FEAT-007 test edits 2–4
- **Implements:** FR-1, FR-7 (order), FR-10, FR-11, FR-19 (recents, cache), FR-20, FR-21, FR-22, NFR-8 · **ADRs:** ADR-001, ADR-007
- **Depends on:** T05, T11
- **Size:** L
- **Scope:** per tech 4.4: success branch switches on `SpecCheckState`; running and failure branches byte-for-byte unchanged; `PopScope` per state (`Checking` and matches → FEAT-007 `_leave`; mismatch → pop to crop; unreadable → `leave()` with no confirm, then `onStartOver`); whole route wrapped in `RecentsGuard`; `ExportPanel(success:, size: spec.dimensions)` embedded unchanged. FEAT-007 edits 2 (fake measurer/decoder or valid synthetic 300×300 JPEG), 3a (retire the "Ready:" test) and 4 (re-record the 7 result goldens).
- **Done when:** new `test/features/export/result_screen_check_test.dart` and `test/app_flow_test.dart` cases pass: no "Matches your target" text before the fake measurer completes (AC-1.4); matches → semantics traversal order preview, headline, rows, notices, caveat, panel, Done (FR-7); mismatch → section 8 headline, no `ExportPanel`, no Save/Share, file gone, Back lands on the crop step with photo and spec kept, no export-anyway control (AC-3.1, AC-3.3, AC-3.5); unreadable and non-OOM `PreviewErr` → `FILE_MISSING` text, no check, no panel, one button runs `leave()` once with no dialog and opens the pick screen (AC-3.4); OOM → placeholder with rows and panel (AC-4.4); back during `Checking` and in matches shows the FR-23 dialog when nothing was saved, Leave runs `leave()` once, file deleted, pick screen on top; Done tapped twice → `leave()` once (AC-7.2); FEAT-007 running and failure tests pass unchanged (AC-7.3); rotation (size change), locale change and text scale 2.0 keep the same state with compression `start` and `measure` each called once (AC-7.4); after leave `imageCache.currentSize == 0`, the image is disposed, and a second run shows nothing from the first (AC-6.2); after FR-10 Back the crop screen's recents protection is still on (nested guard). `git diff --quiet` on `export_panel.dart`, `export_controller.dart` and FEAT-007's panel, controller, data, domain and privacy test files.

### - [ ] FEAT-006-T13 — Remove `exportReady` and `ExportMessages.ready`
- **Implements:** FR-20, FR-23 · **ADRs:** —
- **Depends on:** T12
- **Size:** S
- **Scope:** delete `exportReady` from all 6 ARBs (OQ-T5), `ExportMessages.ready`, and FEAT-007 edit 3b (the two `ready` cases in `export_messages_test.dart`); move the all-locales "`{width}` before `{height}`" order test to `check_messages_test.dart` for `checkPixels` and `previewAlt`.
- **Done when:** `flutter gen-l10n` passes; `grep -rn "exportReady\|ExportMessages.ready" lib test integration_test` finds nothing; the moved order test passes in all 6 locales; the rest of `export_messages_test.dart` is unchanged.

### - [ ] FEAT-006-T14 — Accessibility, 200% font, RTL, goldens — gate G2
- **Implements:** NFR-2, NFR-4, FR-15 (golden), FR-16, FR-23 (isolates) · **ADRs:** —
- **Depends on:** T13
- **Size:** M
- **Scope:** new `test/features/export/result_screen_check_a11y_test.dart`; host goldens with `TolerantGoldenComparator`: en and ar × matches (padding notice), matches transparent PNG (checkerboard), preview unavailable, mismatch, unreadable at 360×640, plus en and hi at 200%. G2 screenshots on the Realme 2 Pro from `integration_test/result_screen_demo.dart` with the fake measurer forcing the bad states, synthetic images only.
- **Done when:** `androidTapTargetGuideline`, `labeledTapTargetGuideline` and `textContrastGuideline` pass for matches, mismatch and unreadable; text scale 2.0 at 360×640 in en, ar and hi gives no overflow, no horizontal scroll, and Save, Share and Done reachable by scrolling (AC-8.1); exactly one live-region node for the verdict besides the panel's own, and each row node's label equals its row sentence (AC-8.2); ar has `TextDirection.rtl`, mirrored rows, numbers/`px`/`KB`/format names inside LTR isolates, digits 0-9 only (AC-8.3); goldens pass. The screenshots are in the PR (not committed unless the Product Owner asks). Gate G2 is recorded.

### - [ ] FEAT-006-T15 — Device test on API 36 (Realme 2 Pro) and CI API 28
- **Implements:** FR-2, FR-10, FR-12, FR-13, FR-14, NFR-1, NFR-7 · **ADRs:** ADR-004
- **Depends on:** T14
- **Size:** M
- **Scope:** new `integration_test/preview_check_test.dart` (**`testWidgets` only**), run from `integration_test/bundle.dart`, with the real `FileOutputMeasurer` and `PreviewDecoder`, synthetic images, compression overridden only where a test file must be injected:
  - real flow, 300×300, 20–50 KB, JPEG target → matches, rows equal an independent `File.length` and header read (metric "Truthful measurement");
  - a solid-colour output replaced by another colour → the controller's image centre pixel is the replacement colour (AC-4.2);
  - 24 MP output → no crash, rows show the file's values, decoded image long side ≤ `maxSide` (AC-4.3); `debugForceOutOfMemory` → placeholder with rows and panel (AC-4.4);
  - real FEAT-004 outputs for a narrow, a max-only, a PNG and a padded-JPEG target → matches (no false "doesn't match");
  - floor − 1, ceiling + 1, width + 1 and format-swap files injected → mismatch (no false "matches");
  - FR-12: background, delete the file, resume → `FILE_MISSING` message;
  - timing: median and p95 of 20 success-to-verdict runs at 2 MP, reported per device.
  - CI: covered by the existing `bundle.dart` line; push once for this milestone.
- **Done when:** the target passes on the Realme 2 Pro and in the CI API 28 job; timings and pass/fail per check are in the Test record (no paths or file names); nothing is left in `cache/exactsize_out` after the run.

### - [ ] FEAT-006-T16 — Translate FEAT-006 strings (es, pt, hi, id, ar) — Product Owner runs `/l10n-translate`
- **Implements:** FR-23, NFR-4 · **ADRs:** —
- **Depends on:** T14 (strings final after G1/G2)
- **Size:** M (not counted: FEAT-019 work)
- **Scope:** the Product Owner types `/l10n-translate <lang>` for es, pt, hi, id and ar, one language at a time. Only the vendored `localize-*` skills and the CLAUDE.md variants (pt-BR, es-419, MSA with Western digits 0-9). Only app strings go to the model, never user data, file names or paths. Keys, ICU syntax and placeholder names identical to `app_en.arb`; no bidi marks in placeholders. Status `AI-reviewed only`; never "native-quality" or "native-reviewed". Headline, mismatch, unavailable and caveat lines short and plain.
- **Done when:** all five `app_*.arb` files contain the 17 FEAT-006 keys and no `exportReady`; mechanical checks pass; `docs/l10n/ai-review-log.md` has one entry per language with status `AI-reviewed only`; `flutter gen-l10n` reports no untranslated FEAT-006 keys; a widget test renders matches and mismatch in all 6 locales with no English fallback; the T13 order test and the T14 200% test pass in every locale; ar goldens re-recorded.

### - [ ] FEAT-006-T17 — Real-phone checklist (Realme 2 Pro, API 36) — gate G-final
- **Implements:** FR-10, FR-12, FR-15, FR-18, FR-19, FR-21, FR-22, NFR-1, NFR-2, NFR-3, NFR-7, NFR-8 (evidence) · **ADRs:** —
- **Depends on:** T15, T16
- **Size:** M
- **Scope:** rows kept in the Test record, profile build, synthetic image shared in with `am start`. Each row: adb command, expected result, pass/fail.
  - AC-1.1, AC-2.1: real flow shows preview, "Matches your target", three rows, panel; Save works as in FEAT-007.
  - AC-5.1: a padded-JPEG target shows the padding notice; a transparent PNG source with a JPEG target shows the flatten notice; a PNG target shows the checkerboard (AC-4.5).
  - AC-3.1, AC-3.3: mismatch forced through the demo target → no panel, Back to crop with photo and values kept, `run-as ls cache/exactsize_out` = 0.
  - FR-12: on matches, Home, `run-as rm` the output, resume → `FILE_MISSING` message, leave → pick screen.
  - AC-6.1: open recents on the result screen → thumbnail hidden (by eye, no image committed); `adb shell screencap` still works (file deleted at once).
  - AC-6.2: Done, then a second synthetic photo of another colour → nothing of the first drawn.
  - AC-6.3: `adb logcat --pid` for every app process → app lines are enum codes only; no `exactsize-`, `/storage/`, `content://`, no size or dimension.
  - AC-6.4, NFR-3: airplane mode → check and Save work.
  - AC-7.2: back with nothing saved asks; Leave → cache empty (`run-as ls cache/exactsize_out cache/exactsize_share` = 0, 0).
  - AC-7.4: rotate, change font size and language on matches → same verdict and preview; logcat shows one compression `SUCCESS` and one `SPEC_MEETS`.
  - AC-8.2: `uiautomator events` → one announcement for the verdict; TalkBack speech if installed (Open items 3).
  - ar RTL and hi at 200% by eye.
  - NFR-1: success-to-verdict time on the phone, informational.
  - Cleanup: delete the run's files (source and anything saved) with their MediaStore rows; restore font scale, rotation, language, airplane mode and developer options as found.
- **Done when:** every runnable row passes and is recorded with date and device; CI API 28 is green for `bundle.dart` and `preview_check_test.dart`; gate G-final is recorded, including the Product Owner's acceptance of the gaps in Open items. The feature may then go to Implemented through the Product Owner's `/approve`.

## Effort reconciliation
| Tech section 10 line | Tech days | Tasks | Task days |
|---|---|---|---|
| Spike | 0.5 | T01 M | 0.5 |
| Domain and boundary tests | 0.5 | T02 M | 0.5 |
| Measurer and fixtures | 0.5 | T03 M | 0.5 |
| Controller | 1.0 | T07 M, T08 M | 1.0 |
| `RecentsGuard`, `maxSide`, checkerboard | 0.25 | T04 S | 0.25 |
| Screen with impeccable, a11y, goldens | 1.5 | T10 M, T11 M, T12 L, T14 M | 2.5 |
| FEAT-007 test migration | 0.5 | T05 S, T13 S (rest inside T12) | 0.5 |
| Strings (translations not counted) | 0.75 | T06 M | 0.5 |
| Emulator integration | 0.5 | T15 M | 0.5 |
| Not in tech | — | T09 S, T17 M | 0.75 |
| **Total** | **6.0 d ≈ 1.2 pw** | 16 counted tasks | **7.5 d ≈ 1.5 pw** |

The task total is 1.5 d above tech and 0.2 pw above its 1.1–1.3 pw range: the design gate and the result-screen work are split into separate PRs, plus the privacy test and the real-phone checklist. Not counted: T16 (FEAT-019 work) and the Product Owner's design time. Cut order if effort grows (PRD OQ-10): FR-8, FR-9, FR-12, FR-15 (saves about 0.1 pw; tech does not recommend cutting).

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T07, T12 | AC-1.4 in T12 |
| FR-2 | T03, T15 | `package:image` oracle; device run |
| FR-3 | T02, T05 | |
| FR-4 | T02 | One window definition (grep) |
| FR-5 | T06, T11 | |
| FR-6 | T02, T06 | `achievedKb` reused |
| FR-7 | T06, T11, T12 | Wording test; focus order |
| FR-8 | T02, T11 | Should |
| FR-9 | T11 | Should |
| FR-10 | T07, T12, T15, T17 | |
| FR-11 | T03, T07, T12 | |
| FR-12 | T08, T15, T17 | Should |
| FR-13 | T01, T04, T11, T15 | |
| FR-14 | T01, T04, T07, T11, T15 | 40% / 4× constants |
| FR-15 | T04, T11, T14, T17 | Should |
| FR-16 | T06, T11, T14 | |
| FR-17 | T11 | Won't (R1): asserted absent |
| FR-18 | T11, T17 | |
| FR-19 | T03, T04, T08, T09, T12, T17 | |
| FR-20 | T12, T13 | |
| FR-21 | T12, T17 | Panel and controller unchanged (`git diff`) |
| FR-22 | T12, T17 | |
| FR-23 | T06, T13, T14, T16 | `AI-reviewed only` |
| NFR-1 | T01, T03, T15, T17 | Gate in T01 |
| NFR-2 | T11, T14, T17 | |
| NFR-3 | T09, T17 | |
| NFR-4 | T06, T14, T16 | |
| NFR-5 | T02 | Generated set, 100% |
| NFR-6 | T02, T07 | Fake measurer |
| NFR-7 | T01, T15, T17 | Real phone for latest API |
| NFR-8 | T09, T12, T17 | |

**Not covered by a task:** PRD OQ-9 compliance review (Data safety reading, PCI "opaque image" reading, local data-protection law) is release work for the Product Owner, as in FEAT-007.

## Open items
1. **2 GB emulator profile.** NFR-1 names it. FEAT-007 recorded the local emulator's data as corrupted; CLAUDE.md says keep it running. T01 and T15 use it if available, otherwise the Realme 2 Pro and CI API 28 numbers stand in; the Product Owner accepts that at G0. Accepted 2026-11-26 (Test record).
2. **AC-7.1 wording.** "FEAT-007 suite passes unchanged" is met in the OQ-T1 sense (behaviour assertions unchanged, fixed edit set), not word for word.
3. **TalkBack** is not installed on the Realme 2 Pro (FEAT-007 T23). AC-4.6 and AC-8.2 are covered by semantics tests and `uiautomator events`; speech is checked only if the Product Owner installs TalkBack.
4. **Recents on Android 9–12** has no protection (PRD privacy flag 2); AC-6.1 is checked on API 36 only, by eye.
5. **Effort** 1.5 pw against tech 1.2 pw and roadmap 0.8 pw; the Product Owner decides whether the roadmap row changes.

## Test record
_Filled in by T01, T10, T12, T14, T15, T16 and T17 (one row per check and device: date, device or CI run, result). Synthetic images only. No file names, URIs, paths, sizes of real files or image content in rows or screenshot captions; use `[PLACEHOLDER]` for anything sensitive._

| Date | Task | Check | Device / run | Result |
|---|---|---|---|---|
| 2026-11-25 | T01 | H1: `PreviewDecoder.decode` of a `file://` URI in app cache (`exactsize_out`), region path, synthetic 2 MP JPEG and PNG: `PreviewOk` 20/20 each; 24 MP JPEG and PNG also `PreviewOk` | Realme 2 Pro, API 36, profile build | Pass |
| 2026-11-25 | T01 | H3: 20 x (measure in `Isolate.run` + decode), 2 MP, cap = physical short side (1080): JPEG median 48.5 ms, p95 90 ms (max 159); PNG median 90.5 ms, p95 142 ms (max 147). Measure alone: JPEG median 4 ms, PNG median 7 ms (gate 500 ms / 1.5 s) | Realme 2 Pro, API 36, profile build | Pass |
| 2026-11-25 | T01 | H2: 24 MP (6000x4000) JPEG, cap 2048 (sample 4, 1500x1000): TOTAL PSS 103.6 MB before, 114.4-114.5 MB while the image is held = steady extra 10.8 MB. Cap 1080 (sample 8, 750x500, a quarter of those pixels): +0.1 MB at the first held sample, then a GC of leftover fixture-generation garbage pulled PSS below the baseline, so the cap-2048 figure is the upper bound. PNG 24 MP, cap 1080: decoded (sample 8), same GC effect. Gate 24 MB | Realme 2 Pro, API 36, profile build | Pass |
| 2026-11-25 | T01 | H2 peak: not measurable on this phone. `dumpsys meminfo` takes about 1 s per sample and the 24 MP decodes took 125-242 ms, so no sample fell inside a decode. A second run read `VmHWM` in the app process, but the kernel refused the high-water reset (`clear_refs`), so the mark (338 MB) comes from generating the 24 MP fixtures in the test, not from the decode. Upper estimate [Hypothesis] from the buffers that exist at once (native bitmap, malloc copy, transferred bytes, Dart copy, engine buffer, `ui.Image`): about 6 x the preview bytes, so about 36 MB at cap 2048 and about 9 MB at cap 1080. Memory was not handed back within 4 s of `dispose` (PSS level until a later GC). Reported only, not gated (tech section 10) | Realme 2 Pro, API 36, profile build | Recorded (estimate) |
| 2026-11-25 | T01 | H4: `checkContainer` on 10,240,000-byte files (noisy pixels, padded to the exact length), 5 runs inside an isolate: JPEG median 47 ms; PNG median 296 ms (max 302). PNG is over the tech [Hypothesis] of 100 ms because every chunk CRC is checked (files up to 64 MB). Reported only | Realme 2 Pro, API 36, profile build | Recorded (PNG over hypothesis) |
| 2026-11-25 | T01 | Second run (same build, same day): H1 20/20 both formats; H3 JPEG median 50.5 ms, p95 58 ms; PNG median 92.5 ms, p95 105 ms; H4 JPEG median 66.5 ms, PNG median 410 ms | Realme 2 Pro, API 36, profile build | Pass (H3); PNG H4 over hypothesis again |
| 2026-11-25 | T01 | H1: `file://` URI in app cache, region path, synthetic 2 MP JPEG and PNG: `PreviewOk` 20/20 each | CI API 28 emulator, profile build, run 45652574957 (slim spike workflow, H2 skipped) | Pass |
| 2026-11-25 | T01 | H3: 20 x (measure + decode), 2 MP: JPEG median 8.5 ms, p95 28 ms; PNG median 20 ms, p95 31 ms. The emulator screen's short side is 320 px, so the cap there is 320 (a smaller preview than any phone): CI numbers show the path works on API 28; the Realme numbers are the timing evidence | CI API 28 emulator, run 45652574957 | Pass |
| 2026-11-25 | T01 | H4: `checkContainer` on 10,240,000-byte files: JPEG median 11 ms; PNG median 107.5 ms | CI API 28 emulator, run 45652574957 | Recorded |
| 2026-11-25 | T01 | Local 2 GB API 36 emulator H3 row: not run, the emulator is not running and its data was recorded as corrupted (Open items 1); the Realme and CI API 28 numbers stand in | Realme 2 Pro, API 36, profile build | Gap, see Open items 1 |
| 2026-11-25 | T01 | Cleanup: spike fixtures deleted by the test teardown; test build uninstalled (package absent afterwards) | Realme 2 Pro, API 36, profile build | Done |
| 2026-11-25 | T01 | Gate G0: passed. `file://` decode works on API 36 and API 28; 2 MP measure + decode at most 92.5 ms median and 142 ms p95 (Realme, gate 500 ms / 1.5 s); steady extra at a 24 MP output 10.8 MB at cap 2048, so at most that at cap = short side (gate 24 MB). Recorded, not gated: peak (estimate only, see above) and the 10 MB PNG `checkContainer` time of 0.3-0.4 s on the Realme (tech [Hypothesis] was 100 ms; it adds to the time to verdict for large PNG outputs only, still far inside NFR-1). No fallback needed. Spike branch deleted, never merged | Realme 2 Pro and CI API 28 | Pass |
| 2026-11-26 | T01 | Gate G0 gaps accepted by the Product Owner: the Realme 2 Pro and CI API 28 numbers stand in for the 2 GB emulator (Open items 1), and the peak memory figure is an estimate | Product Owner | Accepted |
| 2026-11-26 | T10 | Gate G1: lean impeccable design (t10/check_design.md, 2026-11-26) accepted by the Product Owner with the three defaults (unreadable key "Choose another photo"; Checking = spinner only; 1,024 line hidden on a mismatch) | Product Owner | Accepted |

## Instructions for Claude Code
- Read `prd.md`, `tech.md`, ADR-004, ADR-007 and ADR-001 before starting a task.
- Implement only the current task, in order; tick its checkbox, commit, and add a line to `docs/CHANGELOG.md` when done. Push only at milestones.
- Gates: no decoder change (T04) before G0; no visible UI work (T11–T14) before G1; T15 after G2; T16 only after G2; stop at every failing gate and report to the Product Owner.
- UI rule: before designing or building any real UI screen, stop and tell the Product Owner (impeccable, decision 2026-11-20). T10 is that stop. impeccable runs lean: no image comps, no reviewer subagents, one round, one screenshot per key state.
- Do not change FEAT-002, FEAT-004, FEAT-005 or FEAT-007 code beyond what a task names. `ExportPanel`, `ExportController`, `ByteWindow`, `achievedKb` and `OutcomeMessages.notice` stay untouched. If a task seems to need more, stop and propose a change request.
- FEAT-007 tests: only the edit set above.
- Device tests under `flutter drive` use `testWidgets` only. Local runs use the Realme 2 Pro; API 28 runs in CI.
- Translations only through `/l10n-translate <lang>` typed by the Product Owner, status `AI-reviewed only`.
- If a requirement is unclear or wrong, stop and propose a PRD change.
- Privacy: synthetic test images only. Never log or put in crash reports, test records or PR text any image content, file name, URI, path, size, dimension or platform exception text. No persistence, `restorationId`, clipboard writes or network calls. Any sensitive value is `[PLACEHOLDER]`.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-25 | First draft |
| 1.0 | 2026-11-25 | Approved by Product Owner |
