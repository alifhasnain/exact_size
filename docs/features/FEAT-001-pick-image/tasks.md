---
id: FEAT-001-TASKS
title: Pick image from camera or gallery — Implementation Tasks
status: Approved
version: 1.0
updated: 2026-11-21
links: [FEAT-001, FEAT-001-TECH, ADR-001, ADR-006, FEAT-002, FEAT-004]
---

# FEAT-001 — Implementation Tasks

Milestone: R1 Phase A — core. Work top to bottom, one task at a time.

Sizes: **S** = up to half a day, **M** = up to one day; each task is one PR.
Module paths follow ADR-001: `lib/features/pick/{domain,data,presentation}`; native code only in `android/app/src/main/kotlin/com/exactsize/exact_size/` (ADR-006). Tests mirror them under `test/` and `integration_test/`; fakes and fixtures go in `test_support/`.

**Already built, reused, not planned again:** `SourceHandle`, `SourceProbe` (`ProbeOk`/`ProbeErr`, worker isolate), `Reason`, `CropOutcomeLog` pattern, `TempFiles` and its start-up sweep in `lib/main.dart` (FEAT-004), `test_support/crop_fixtures/` with `tool/gen_crop_fixtures.py` and `MANIFEST.md`, `test_driver/push_fixtures_driver.dart`, `integration_test/bundle.dart` (enforced by `test/integration_bundle_test.dart`), `tool/run_offline_test.sh`, the import-ban test `test/features/compression/no_network_imports_test.dart`, gen-l10n with 6 languages, the CI API 28 emulator job (`.github/workflows/ci.yml`).

**Test devices:**
- Local: `Medium_Phone_API_36.1` (2 GB). API 28 needs two local AVDs with a 2 GB profile: AOSP without Play services and a Google Play image [Assumption: allowed to create them; no physical low-end phone, PO decision 2026-11-20].
- CI: the existing API 28 x86_64 job (`reactivecircus/android-emulator-runner`, default target, so AOSP without Play services [Assumption: default target]). New `*_test.dart` files go into `integration_test/bundle.dart`. Tests that need pushed fixtures run as an extra `flutter drive --driver test_driver/push_fixtures_driver.dart --target integration_test/<file>.dart` line in the same `script:` block, like `crop_data_matrix.dart`.
- System pickers and camera UIs cannot be driven by `integration_test` (FEAT-001-TECH section 11). Those paths are covered by the scripted checklist in T19, whose results go into the Test record section below.

**Decisions from FEAT-001-TECH section 12 used here (approved with tech.md v1.0):** OQ-T1 zero-byte file → `CORRUPT_INPUT` (T02, a FEAT-002 code change); OQ-T3 camera low-space threshold 32 MiB; OQ-T4 FR-17 marker in the saved-instance-state `Bundle`; OQ-T5 a gallery result arriving after process death is a new result, not a restored image; OQ-T6 NFR-1 measured up to the `PickedImage` hand-off. OQ-T2 (non-seekable provider streams) is still open and is decided at gate G1 only if the spike finds such a provider. OQ-T7 (ADR-001 pointer to ADR-006) is a doc change for the Product Owner, not a task.

## Decision gates
| Gate | Task | Passes when | If it fails |
|---|---|---|---|
| G1 Bridge spike | T01 | On API 36.1, API 28 AOSP and API 28 Google Play: (a) gallery opens the photo picker or the document picker, images only, one selection, no permission prompt; (b) `onActivityResult` runs before `onResume` on return, also under "Don't keep activities", and a slot result survives engine recreation; (c) the returned grant opens in `SourceProbe`'s worker isolate, also after recreation; (d) the camera app writes a full-size file through the FileProvider `EXTRA_OUTPUT` URI; (e) resolved AndroidX `activity` and `core` versions recorded; (f) descriptor type (`statSize`) recorded per provider; (g) launcher icon during the camera keeps the camera on top with `singleTop`; (h) share trampoline lands in the existing task with a usable grant. Decision record in the PR and `docs/CHANGELOG.md` | (a)–(d) or (g) fail: stop all native and data work (T08 onwards) and report; an ADR-006 change (for example Option D or `registerForActivityResult`) needs a Product Owner decision. T02–T07 may continue. (e): update the pins in T08, no stop. (f) pipe descriptors found: Product Owner decides OQ-T2 (proposal: accept `SOURCE_UNAVAILABLE`, note the limit in PRD AC-4.3). (h) fails: T24–T25 do not start; the Product Owner decides whether FR-20 moves to Next (PRD OQ-3, tech R6). Musts continue |
| G2 Early refusal and no copy | T15 | 100% of the AC-3.5 set is refused on the pick path with the expected code; the refused camera file is gone; after `release()` the camera folder is empty; no new file exists anywhere in app storage except the one camera file of an accepted capture | Stop and report. A wrong code from `SourceProbe` is a FEAT-002 issue (propose a change there); a file left behind is a Must privacy defect |
| G3 Pick screen design | T16 | PRD OQ-4 (photo first or target first, start-screen owner) is decided by the Product Owner, the Product Owner has designed the pick screen with impeccable (https://github.com/pbakaus/impeccable), and the design reference is recorded | No task that builds or styles the visible pick screen (T17, T18, the UI parts of T22, T23) starts. All non-visual work (T01–T15) may continue |
| G4 Emulator run | T19 | Every checklist row passes on the three emulator images: no crash or ANR (NFR-2), zero permission prompts, zero forbidden permissions, no copies (AC-6.1), original byte-identical (AC-6.6), logcat clean (AC-6.3), airplane mode works (AC-6.5). NFR-1 numbers recorded for information only | A reliability, privacy or permission miss: stop and report. Timing misses are reported, not a gate |

## Tasks

### - [x] FEAT-001-T01 — Spike: picker availability, result ordering, grants, camera output, AndroidX versions, share task — gate G1
- **Implements:** FR-2, FR-3, FR-4, FR-15, FR-17, FR-20, NFR-7 (evidence) · **ADRs:** ADR-006
- **Depends on:** —
- **Size:** M
- **Scope:** spike branch, thrown away after the record. Minimal Kotlin in `MainActivity.kt` (ADR-006 Option B shape: `startActivityForResult` with `PickVisualMedia().createIntent(ImageOnly)`, `isPhotoPickerAvailable`, `ACTION_OPEN_DOCUMENT` fallback, `ACTION_IMAGE_CAPTURE` with a FileProvider URI into `<cache>/camera/`, a temporary no-UI share trampoline) and a debug-only Dart button page. On the three images: check items (a)–(h) of G1 with "Don't keep activities" (`adb shell settings put global always_finish_activities 1`) and `adb shell am kill <package>` after pressing home; open each returned URI with `SourceProbe` and record `statSize`; run `android/gradlew :app:dependencies --configuration releaseRuntimeClasspath` and record resolved `androidx.activity` and `androidx.core`; send a share with `adb shell am start -a android.intent.action.SEND -t image/* --eu android.intent.extra.STREAM <MediaStore URI of a pushed synthetic image> --grant-read-uri-permission` [Hypothesis: shell can grant a MediaStore URI; record the result] cold and warm. Synthetic images only; no URIs, paths or file names in the PR text (use `[PLACEHOLDER]`).
- **Done when:** a decision record with one row per G1 item and per image (pass, fail, or observed value) is in the PR and `docs/CHANGELOG.md`; gate G1 is recorded as passed, or work stops and the failing item goes to the Product Owner. No task from T08 onwards starts before G1 passes.

### - [x] FEAT-001-T02 — FEAT-002 change: zero-byte source → `CORRUPT_INPUT` (OQ-T1)
- **Implements:** FR-7, AC-3.5 (zero-byte row), NFR-2 · **ADRs:** ADR-004
- **Depends on:** —
- **Size:** S
- **Scope:** **touches FEAT-002 code.** `lib/features/crop/data/source_probe.dart` line 63: `size == 0` → `ProbeErr(Reason.corruptInput)`, `size < 0` stays `Reason.sourceUnavailable`. Add an empty `zero_bytes.jpg` to `tool/gen_crop_fixtures.py` and `test_support/crop_fixtures/MANIFEST.md`; add the case to `integration_test/crop_data_matrix.dart` (already a CI `flutter drive` target with `push_fixtures_driver.dart`). The `docs/CHANGELOG.md` line names both FEAT-001 and FEAT-002. FEAT-002 docs have no zero-byte rule (checked), so no FEAT-002 doc change is needed.
- **Done when:** `crop_data_matrix.dart` passes on API 36.1 and in the CI API 28 job with `zero_bytes.jpg` → `CORRUPT_INPUT`; the existing FEAT-002 matrix and unit tests still pass unchanged.

### - [x] FEAT-001-T03 — Pick domain types and `PickRules`
- **Implements:** FR-6, FR-8, FR-10, FR-11, FR-14 (mapping), FR-19 (redaction), NFR-9 · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** S
- **Scope:** `lib/features/pick/domain/pick_types.dart` (`PickSource`, `PickOrigin`, `LaunchOutcome`, `PickMessage`, `PickedImage`, sealed `SystemPickResult` per tech section 4, all with redacted `toString`); `pick_rules.dart` (scheme `content` only, refuse `share && fromOwnApp`, `Reason` → `PickMessage` with the pick-time `sourceUnavailable`, camera-file delete decision per outcome). No Flutter, Riverpod or channel imports.
- **Done when:** unit tests pass for: `content` accepted, `file`, `http`, empty and malformed refused; own-app share refused; every `Reason` maps to its message; delete decision for cancel, refusal, accept-with-previous and accept-without-previous; `toString` of every type contains no URI or file name (checked with a `[PLACEHOLDER]` URI string).

### - [x] FEAT-001-T04 — `TempFiles` folder parameter and `sweep(keep:)`
- **Implements:** FR-11 · **ADRs:** ADR-003 (unchanged contract)
- **Depends on:** —
- **Size:** S
- **Scope:** `lib/features/compression/data/temp_files.dart`: optional folder name (default `exactsize_out`, so FEAT-004 callers are unchanged) and `sweep({String? keep})` that skips the one named entry; register a second instance `@Named('camera')` on `<cache>/camera/` in the get_it module. Extend `integration_test/temp_files_test.dart` (already in `bundle.dart`).
- **Done when:** existing FEAT-004 temp-file tests pass unchanged; new tests show `sweep(keep: name)` leaves only that file, `sweep()` empties the camera folder, and the two instances never touch each other's folder.

### - [x] FEAT-001-T05 — `PickOutcomeLog` and pick privacy static tests
- **Implements:** FR-8, FR-19, NFR-3, NFR-6, NFR-8 · **ADRs:** ADR-001, ADR-006
- **Depends on:** T03
- **Size:** S
- **Scope:** `lib/features/pick/data/pick_outcome_log.dart` (same shape as `CropOutcomeLog`, line `exactsize.pick outcome=<CODE>`, no origin, URI, name or size). `test/features/pick/pick_privacy_test.dart`: extend the import-ban to `lib/features/pick/`; grep `lib/features/pick/` for `OpenableColumns`, `DISPLAY_NAME`, `BitmapFactory`, `dart:ui` image types and pixel buffers; grep `MainActivity.kt` and (when it exists) `ShareTargetActivity.kt` for `Log.`, `println`, `printStackTrace`.
- **Done when:** the tests pass on the current tree and fail when a forbidden token is added to a scratch file in each scanned location (shown in the PR).

### - [x] FEAT-001-T06 — English strings and `PickMessages`
- **Implements:** FR-1, FR-5, FR-13, FR-14, NFR-4 (text), NFR-5 · **ADRs:** —
- **Depends on:** T03
- **Size:** S
- **Scope:** `lib/l10n/app_en.arb`: every PRD section 8 string with `@` descriptions (buttons, disabled-camera reason, all messages, "Opening your photo…", "Cancel"), including the Should strings ("Choose from files", privacy line marked "copy owned by FEAT-016", capture lost) so translation runs once; ICU placeholders only, no concatenation. `lib/features/pick/presentation/pick_messages.dart` maps `PickMessage` → string.
- **Done when:** `flutter gen-l10n` passes; a unit test checks every `PickMessage` has a non-empty English string; the PR lists the new keys. If a Should is later cut, its keys are removed in that decision's PR.

### - [x] FEAT-001-T07 — Translate pick strings (es, pt, hi, id, ar)
- **Implements:** NFR-5, AC-7.3 · **ADRs:** —
- **Depends on:** T06
- **Size:** M
- **Scope:** run `/l10n-translate <lang>` one language at a time for the T06 keys, using only the vendored `localize-*` skills and the variants fixed in CLAUDE.md (pt-BR, es-419, MSA with Western digits). Send only app strings, never user data. Keys, ICU syntax and placeholder names identical to `app_en.arb`.
- **Done when:** all five `app_*.arb` files contain every T06 key; the mechanical checks pass; one entry per language is in `docs/l10n/ai-review-log.md` with status `AI-reviewed only`; `flutter gen-l10n` reports no untranslated FEAT-001 keys.

### - [x] FEAT-001-T08 — Manifest, FileProvider, `queries`, Play services entry, AndroidX pins
- **Implements:** FR-4, FR-5, FR-18, NFR-6, NFR-7 · **ADRs:** ADR-006
- **Depends on:** T01 (G1)
- **Size:** S
- **Scope:** `android/app/src/main/AndroidManifest.xml`: non-exported `androidx.core.content.FileProvider`, authority `${applicationId}.camera`, `grantUriPermissions`; `queries` entry for `android.media.action.IMAGE_CAPTURE` next to `PROCESS_TEXT`; `uses-feature android.hardware.camera required=false`; Play services photo-picker `ModuleDependencies` service entry; `launchMode` stays `singleTop`; no `uses-permission`. `res/xml/camera_paths.xml` with only `<cache-path name="camera" path="camera/"/>`. `android/app/build.gradle.kts`: pin `androidx.activity` and `androidx.core` to the versions recorded in T01 (ADR-006 proposed 1.10.1 and 1.16.0).
- **Done when:** debug and release builds pass; `aapt2 dump xmltree` (or the merged manifest file) shows the provider with `exported=false`, the `queries` entry and `required=false`; no new permission appears in the merged manifest; the pins match the T01 record.

### - [x] FEAT-001-T09 — `checkMergedManifest` Gradle task
- **Implements:** FR-18, AC-6.4, NFR-6, NFR-10 · **ADRs:** ADR-006
- **Depends on:** T08
- **Size:** S
- **Scope:** Gradle task in `android/app/build.gradle.kts` wired after `processReleaseMainManifest`: fail on `CAMERA`, `READ_EXTERNAL_STORAGE`, `READ_MEDIA_*`, `ACCESS_MEDIA_LOCATION`; on any FileProvider with our authority that is exported or whose paths file holds anything other than `camera/`; on a missing `IMAGE_CAPTURE` `queries` entry. Fails loudly, never strips with `tools:node="remove"`. CI runs it through its release build step [Assumption: the CI build job builds release; if not, add `gradlew :app:checkMergedManifest`].
- **Done when:** the release build passes on the current tree; in the PR, three throwaway changes each fail it with a clear message (a dependency manifest line adding `CAMERA`, `exported="true"` on the provider, a second path in `camera_paths.xml`); CI runs it.

### - [x] FEAT-001-T10 — Kotlin bridge part 1: channel, gallery, pending slot, busy guard
- **Implements:** FR-2, FR-3, FR-15, FR-19, NFR-6, NFR-7 · **ADRs:** ADR-006
- **Depends on:** T01 (G1), T08
- **Size:** M
- **Scope:** `MainActivity.kt` (stays a `FlutterActivity` subclass): `MethodChannel('exactsize/system_picker')`; `launch(gallery)` with `isPhotoPickerAvailable` → `PickVisualMedia` `ImageOnly`, else or on `ActivityNotFoundException` → `ACTION_OPEN_DOCUMENT` `CATEGORY_OPENABLE` `image/*`, both fail → `unavailable`; `onActivityResult` → one pending slot (`Picked`/`Cancelled`), result extras never read; `takeResult` returns and clears the slot; `resultReady` sent when an engine is attached; `launchOutstanding` kept in the saved-state `Bundle` → `busy`. Every entry point catches `Throwable` and returns an enum code with a null message; no `android.util.Log`.
- **Done when:** debug build runs on API 36.1; a debug-only manual check (picker opens, pick, cancel, double tap → one picker) passes; T05 Kotlin grep test passes; code review confirms no exception text crosses the channel.

### - [x] FEAT-001-T11 — Kotlin bridge part 2: camera, low space, marker
- **Implements:** FR-4, FR-5, FR-6, FR-11, FR-15, FR-19 · **ADRs:** ADR-006
- **Depends on:** T10
- **Size:** M
- **Scope:** `MainActivity.kt`: `cameraAvailable()` (`resolveActivity(IMAGE_CAPTURE)`); `launch(camera)`: `StatFs(cacheDir).availableBytes < MIN_FREE_BYTES` (32 MiB, OQ-T3) → `lowSpace`; create `<cache>/camera/<32 hex from SecureRandom>.jpg`, `IOException` → `lowSpace`; `FileProvider.getUriForFile` + `EXTRA_OUTPUT` + read/write grant flags; `ActivityNotFoundException` → delete file, `unavailable`; marker `es.pendingCapture = <name>` in the `Bundle`; `RESULT_OK` → `Captured(uri, name)`, anything else → `Cancelled(name)`; marker cleared on result; `pendingCaptureName()`. The marker is needed by the Must sweep (FR-11) so a recreated engine does not delete the file under "Don't keep activities".
- **Done when:** on API 36.1 with the emulator camera, a debug-only manual check shows: capture → one file in `<cache>/camera/` with size > 0 (listed with `adb shell run-as <package> ls cache/camera`, names not copied into the PR); cancel → slot `Cancelled` with the name; `pendingCaptureName()` returns the name while the camera is open and null after.

### - [x] FEAT-001-T12 — `AndroidSystemPicker`, fake, start-up sweep wiring
- **Implements:** FR-11, FR-15, FR-19, NFR-9 · **ADRs:** ADR-006
- **Depends on:** T03, T04, T11
- **Size:** S
- **Scope:** `lib/features/pick/data/system_picker.dart` (interface), `android_system_picker.dart` (channel wrapper: maps to `SystemPickResult`, unknown or malformed payloads → `NotOpenable`, `PlatformException` → code only, message dropped, never logs payloads); `test_support/fake_system_picker.dart`; `lib/main.dart`: `pendingCaptureName()` then camera `sweep(keep: name)` next to the FEAT-004 sweep. `integration_test/pick_bridge_test.dart` (added to `bundle.dart`, runs in the CI API 28 job): `cameraAvailable()` returns a bool, `takeResult()` and `pendingCaptureName()` are null at rest.
- **Done when:** unit tests with a mocked channel pass for every payload shape, malformed maps and a `PlatformException` carrying a `[PLACEHOLDER]` message that never reaches the log sink; `pick_bridge_test.dart` passes on API 36.1 and in CI.

### - [x] FEAT-001-T13 — `PickController`: launch, result handling, one image, `release()`
- **Implements:** FR-1, FR-3, FR-5, FR-6, FR-7, FR-8, FR-9, FR-10, FR-11, FR-15, FR-16, NFR-9 · **ADRs:** ADR-001, ADR-006
- **Depends on:** T03, T05, T12
- **Size:** M
- **Scope:** `lib/features/pick/presentation/pick_controller.dart` (Riverpod `Notifier<PickState>`, keep-alive): `launch` ignored unless idle; `LaunchOutcome` → state/message; `cameraAvailable` at build and on app resume; `takeResult()` once in `build()` and on every `resultReady`; result steps 1–7 of tech section 4 for all `SystemPickResult` cases (including `CaptureLost` → delete, `captureLost`, so the switch is exhaustive); generation token; previous camera file deleted only on a new `ProbeOk`; `release()`. `SourceProbe` and camera `TempFiles` injected via get_it, faked in tests.
- **Done when:** unit tests pass for: each result type; `resultReady` twice → one probe; double `launch` → one `SystemPicker.launch` (AC-5.4); refusal keeps `current` and its file (AC-3.3); acceptance deletes the previous file; refused camera file deleted (AC-3.2); camera missing or zero-byte → `cameraNoPhoto`; `file://` and own-app share → `itemNotOpenable`; `pickerUnavailable` keeps `cameraAvailable`; `release()` empties state and folder; a fresh controller has no `current` (FR-16).

### - [x] FEAT-001-T14 — `PickController`: 500 ms progress, Cancel, late results, log audit
- **Implements:** FR-13, FR-14, FR-19, NFR-1 (timer), AC-4.2, AC-6.3 · **ADRs:** —
- **Depends on:** T13
- **Size:** S
- **Scope:** `pick_controller.dart`: 500 ms timer → `showProgress`; `cancelOpening()` bumps the generation, deletes the attempt's camera file, idle, no message; late `ProbeOk`/`ProbeErr` discarded; `SOURCE_UNAVAILABLE` → pick-time message. Log audit with a capturing sink.
- **Done when:** fake-async unit tests pass: no progress at 499 ms, progress at 500 ms; Cancel then late Ok → no `current`, no file; Cancel then late Err → no message; every captured log line matches `^exactsize\.pick outcome=[A-Z_]+$` across the whole T13/T14 suite.

### - [x] FEAT-001-T15 — Pick data matrix on the emulator — gate G2
- **Implements:** FR-4, FR-6, FR-7, FR-8, FR-10, FR-11, FR-14, NFR-1, NFR-2, NFR-6, NFR-8, AC-3.1, AC-3.2, AC-3.5, AC-6.1, AC-6.2 · **ADRs:** ADR-004, ADR-006
- **Depends on:** T02, T14
- **Size:** M
- **Scope:** `integration_test/pick_data_matrix.dart`, run with the existing `push_fixtures_driver.dart`: the real `PickController`, real `SourceProbe` and real camera `TempFiles`, with `FakeSystemPicker` emitting `Captured` for fixtures copied into `<cache>/camera/` (the real FileProvider URI). Cases: valid JPEG, PNG, WebP; `truncated.jpg`, `zero_bytes.jpg`, `not_an_image.jpg`; new synthetic fixtures added to `tool/gen_crop_fixtures.py` and `MANIFEST.md`: a minimal MP4 (`ftyp` box only) and a crafted PNG header claiming 250 MP; an undecodable HEIC variant if one exists on that API (else recorded N/A); a FileProvider path-traversal URI (`camera/../exactsize_out/…`) and an ungranted `content://media/…` URI → `sourceUnavailable`; storage listing of `cache/` and `files/` (except `files/fixtures/`) after each case; `release()` → empty camera folder; 12 MP JPEG from `LARGE_DIR` timed from `Captured` to `PickedImage` (20 runs, median, OQ-T6, informational). CI: add `DEVICE=emulator-5554 LARGE_DIR=/tmp/large timeout 900 flutter drive --driver test_driver/push_fixtures_driver.dart --target integration_test/pick_data_matrix.dart -d emulator-5554` to `ci.yml`.
- **Done when:** passes on API 36.1 and in the CI API 28 job; every refusal has the expected code and message and leaves no camera file; only the accepted capture's file exists before `release()`; the 12 MP median is recorded in the PR and `docs/CHANGELOG.md` as informational. Gate G2 is recorded.

### - [x] FEAT-001-T16 — Pick screen design review with the Product Owner (impeccable) and OQ-4 — gate G3
- **Implements:** prerequisite for FR-1, FR-5, FR-13, FR-16, FR-21, FR-22, NFR-4, NFR-5 (visual) · **ADRs:** —
- **Depends on:** T06, T14
- **Size:** S (developer preparation; the Product Owner's design time is not counted)
- **Scope:** stop work and hand the Product Owner a non-visual checklist only (no layouts, colours or mock-ups from the developer): elements (Take a photo, Choose from gallery, Choose from files (Should), privacy line (Should), disabled-camera reason, message area with icon and text, "Opening your photo…" with Cancel), states from `PickState`, constraints (TalkBack order AC-7.1, ≥ 48 dp, 200% font with scroll, RTL mirroring with unmirrored camera and gallery icons, no colour-only information, focus back on the used button), the T06 strings, and PRD OQ-4 (photo first or target first, start-screen owner, where a pending start-up result is routed). The Product Owner decides OQ-4 and designs the screen with impeccable.
- **Done when:** the OQ-4 decision is recorded in the PRD by the Product Owner (via `/approve` flow) and the impeccable design reference (file or link, no real photos) and its date are in the PR and `docs/CHANGELOG.md`; gate G3 is recorded. T17, T18 and the UI parts of T22 and T23 do not start before this.

### - [x] FEAT-001-T17 — Pick screen and flow hand-off
- **Implements:** FR-1, FR-5, FR-9, FR-11 (start-over caller), FR-13, FR-16, NFR-4, AC-1.1–1.3, AC-2.5, AC-3.4, AC-4.2 · **ADRs:** ADR-001
- **Depends on:** T16 (G3), T13, T14
- **Size:** M
- **Scope:** `lib/features/pick/presentation/pick_screen.dart` built to the G3 design: buttons call `PickController.launch`, camera disabled (not hidden) with the reason text, messages in a polite live region with icon and text, progress and Cancel after 500 ms; routing per OQ-4: when `current` changes, navigate to the next step (popping the crop screen and calling `CropController.end()` if one is open); start-over calls `release()`; app start lands on the screen OQ-4 names with nothing restored.
- **Done when:** widget tests with `FakeSystemPicker` and a fake probe pass: one tap → one `launch`; disabled camera shows the reason and `Semantics` reports it unavailable; a refusal shows the message and both buttons stay enabled; progress appears at 500 ms and Cancel returns to idle; an accepted pick navigates once; golden screenshots match the G3 design (no photos on this screen).

### - [x] FEAT-001-T18 — Pick screen accessibility, 200% font and RTL
- **Implements:** NFR-4, NFR-5, AC-7.1, AC-7.2, AC-7.4, AC-3.4 · **ADRs:** —
- **Depends on:** T17, T07
- **Size:** S
- **Scope:** semantics order and labels, focus restore to `lastSource` after returning from a system UI, text scale 2.0 with scrolling, `Directionality.rtl` with unmirrored icons; fixes found by the tests.
- **Done when:** widget tests pass: semantics order Take a photo → Choose from gallery → (files) → (privacy line); focus returns to the used button; at text scale 2.0 no overflow and every button ≥ 48 dp; in Arabic the order mirrors and the icons are not mirrored; each of the 6 locales renders every pick string without a missing-key fallback.

### - [x] FEAT-001-T19 — Emulator run and scripted checklist on three images — gate G4
- **Implements:** FR-2, FR-3, FR-4, FR-5, FR-9, FR-13, FR-14, FR-15, FR-16, FR-18, FR-19, NFR-1, NFR-2, NFR-3, NFR-7, NFR-10, AC-1.4, AC-1.5, AC-2.1–2.6, AC-4.1, AC-5.1, AC-5.3, AC-5.4, AC-6.1, AC-6.3–6.6 · **ADRs:** ADR-006
- **Depends on:** T09, T15, T18
- **Size:** M
- **Scope:** `docs/features/FEAT-001-pick-image/checklist.md`-style steps kept in the Test record section below (adb commands, expected result, pass/fail per image) on API 36.1, API 28 AOSP and API 28 Google Play, 2 GB: gallery pick and cancel (photo picker or document picker), camera OK and cancel, no camera app (`adb shell pm disable-user` on the emulator camera [Assumption: allowed on emulator]) → disabled with reason, low space (fill the cache volume to below 32 MiB [Assumption: `fallocate` or `dd` available on the image]), "Don't keep activities" during picker and camera, `am kill` while idle → starts clean, double tap, the AC-3.5 set picked through the document picker after `adb push`, airplane mode (and a cloud-only item only if the image has a provider for it), storage listing after each pick (AC-6.1), original file `sha256sum` and `stat` before and after (AC-6.6), `adb logcat -d` grep for `content://`, `/data/`, `/storage/`, `.jpg`, `.png` and fixture names → zero (AC-6.3), merged manifest permissions (AC-6.4), 12 MP pick timing from return to hand-off (informational).
- **Done when:** every row passes on the three images and is recorded below with date and image; timings recorded as informational. Any reliability, privacy or permission miss → gate G4.

### - [x] FEAT-001-T20 — Capture recovery after process death (Should)
- **Implements:** FR-17, AC-5.2 · **ADRs:** ADR-006
- **Depends on:** T11, T13, T19
- **Size:** S
- **Scope:** `MainActivity.kt`: `onResume` with the marker still set and no result delivered in this resume → `CaptureLost(name)` (tech section 3; ordering from G1 item b). Dart handling already exists from T13. Checklist rows added to the Test record: `am kill` after pressing home with the camera open, then capture → recovered and probed; same with the file deleted before return → capture-lost message and no file.
- **Done when:** both rows pass on API 36.1 and API 28; a unit test covers `CaptureLost` with and without a file name; the camera folder is empty after the lost case.

### - [x] FEAT-001-T21 — Best-effort camera file delete on finish (Should)
- **Implements:** FR-12 · **ADRs:** ADR-006
- **Depends on:** T11
- **Size:** S
- **Scope:** `MainActivity.onDestroy` with `isFinishing` → delete everything in `<cache>/camera/`, `Throwable` caught, nothing logged.
- **Done when:** checklist row: capture, then finish the activity (back on API 28; `adb shell am force-stop` is not a finish and is listed as covered by the sweep) → camera folder empty; the Android 12+ behaviour (back does not finish the root activity [Hypothesis]) is recorded on API 36.1 as observed.

### - [x] FEAT-001-T22 — "Choose from files" (Should)
- **Implements:** FR-21, AC-9.1 · **ADRs:** ADR-006
- **Depends on:** T10, T13, T17 (G3 for the button)
- **Size:** S
- **Scope:** bridge `launch(files)` → `ACTION_OPEN_DOCUMENT` `image/*`, single, failure → `unavailable`; `PickSource.files` through the controller (origin `files`); button on the pick screen per the G3 design.
- **Done when:** unit test: `files` result handled like gallery; widget test: button present, ≥ 48 dp, in TalkBack order; checklist row on API 36.1 and API 28: document picker opens filtered to images, one selection.

### - [x] FEAT-001-T23 — Privacy line (Should)
- **Implements:** FR-22 · **ADRs:** —
- **Depends on:** T17 (G3)
- **Size:** S
- **Scope:** the T06 privacy string on the pick screen per the G3 design; FEAT-016 owns the final copy (only the ARB value changes later).
- **Done when:** widget test finds the line last in semantics order, unclipped at text scale 2.0 and in all 6 locales.

### - [ ] FEAT-001-T24 — Share target hand-in (Should)
- **Implements:** FR-20, AC-8.2, AC-8.3, AC-8.5, NFR-6 · **ADRs:** ADR-006
- **Depends on:** T01 (G1 item h passed), T10, T13
- **Size:** M
- **Scope:** `ShareTargetActivity.kt` (exported, `Theme.NoDisplay`, filter `SEND` + `DEFAULT` + `image/*`, no `SEND_MULTIPLE`) forwarding the stream URI with its grant to `MainActivity` (`NEW_TASK | SINGLE_TOP`); `MainActivity.onCreate`/`onNewIntent`: ignore `FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY` and `es.shareConsumed`; `Picked(uri, share, fromOwnApp)` via `resolveContentProvider`; missing stream → `NotOpenable(share)`; the intent MIME type is never trusted; manifest entry; T09 check extended to allow only this one exported activity filter.
- **Done when:** unit tests: share `file://`, own authority and missing stream → `itemNotOpenable`; T05 grep test covers `ShareTargetActivity.kt`; T09 still passes.

### - [ ] FEAT-001-T25 — Share target tests: cold, warm, refused, mid-flow (Should)
- **Implements:** FR-20, AC-8.1–8.5 · **ADRs:** ADR-006
- **Depends on:** T24, T17
- **Size:** M
- **Scope:** `test_driver/share_intent_driver.dart` (pushes a synthetic image, finds its MediaStore URI with `adb shell content query`, fires `am start -n <package>/.ShareTargetActivity -a android.intent.action.SEND -t image/* --eu android.intent.extra.STREAM <uri> --grant-read-uri-permission` while the test waits; also a `file://` share) with target `integration_test/pick_share_test.dart`; cold start (app stopped first) and warm start; `adb shell cmd package query-activities -a android.intent.action.SEND_MULTIPLE -t image/*` does not list the app (AC-8.3) [Assumption: command available on API 28, else checked in the merged manifest]. CI: add a `flutter drive --driver test_driver/share_intent_driver.dart --target integration_test/pick_share_test.dart -d emulator-5554` line to `ci.yml`. Mid-flow replacement (AC-8.4: crop screen open, render cancelled, old camera file deleted) as a checklist row.
- **Done when:** the drive test passes on API 36.1 and in the CI API 28 job (cold and warm accepted, `file://` refused with "We can't open that item"); the mid-flow row passes and is recorded below.

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T06, T13, T16, T17 | |
| FR-2 | T01, T10, T19 | Gate G1 |
| FR-3 | T01, T10, T13, T19 | Document picker expected on API 28 AOSP |
| FR-4 | T01, T08, T11, T15, T19 | |
| FR-5 | T06, T08, T11, T13, T17, T19 | Threshold 32 MiB (OQ-T3) |
| FR-6 | T03, T11, T13, T15 | |
| FR-7 | T02, T13, T15 | T02 changes FEAT-002 code (OQ-T1) |
| FR-8 | T03, T05, T13, T15 | |
| FR-9 | T13, T17, T19 | |
| FR-10 | T03, T13, T15 | |
| FR-11 | T03, T04, T11, T12, T13, T15, T17 | FEAT-007 must call `release()` at flow end (FEAT-007 work) |
| FR-12 | T21 | Should; the sweep is the real guarantee |
| FR-13 | T06, T14, T17, T19 | |
| FR-14 | T03, T06, T14, T15, T19 | OQ-T2 decided at G1 if needed |
| FR-15 | T01, T10, T11, T12, T13, T19 | Gate G1 item b |
| FR-16 | T13, T17, T19 | Start screen per OQ-4 |
| FR-17 | T01, T11 (marker), T20 | Should; Bundle marker (OQ-T4) |
| FR-18 | T08, T09, T19 | |
| FR-19 | T03, T05, T10, T11, T12, T14, T19 | |
| FR-20 | T01, T24, T25 | Should; G1 item h decides whether it starts |
| FR-21 | T22 | Should |
| FR-22 | T06, T23 | Should; copy owned by FEAT-016 |
| NFR-1 | T14, T15, T19 | Informational; measured to `PickedImage` (OQ-T6) |
| NFR-2 | T02, T15, T19 | Gates G2, G4 |
| NFR-3 | T05, T19 | |
| NFR-4 | T06, T16, T17, T18 | |
| NFR-5 | T06, T07, T18 | `AI-reviewed only` |
| NFR-6 | T05, T08, T09, T10, T15, T24 | |
| NFR-7 | T01, T08, T10, T19 | Three emulator images |
| NFR-8 | T05, T15 | |
| NFR-9 | T03, T12, T13 | |
| NFR-10 | T09, T19 | Play policy reading still PRD OQ-10, before release |

**Not covered by a task:** the PRD section 3 metrics "Taps … 1 before the system UI" and the R1 "< 30 s app open to export" need a usability check and the full flow (OQ-4, FEAT-005/007); T17 tests only the tap count. AC-4.3 (online-only photo while online) and AC-4.1 depend on a cloud provider on the emulator image; T19 records N/A if none exists. Real OEM camera behaviour (tech R4) is not tested (emulator-only test environment).

## Open questions
- **PRD OQ-4** blocks T16 and everything visual after it. Non-visual tasks T01–T15 do not depend on it.
- **OQ-T2** (non-seekable provider streams) is still open; it comes to the Product Owner only if T01 finds such a provider.
- **OQ-T7** (ADR-001 clarification line pointing to ADR-006) is a Product Owner doc change, not a task here.
- **API 28 AVDs:** T01 and T19 assume two local API 28 images (AOSP and Google Play) may be created; the CI job covers only AOSP.
- **FEAT-007 dependency:** FEAT-007's flow-end event must call `PickController.release()`; that wiring belongs to FEAT-007.

## Test record
_Filled in by T01, T19, T20, T21, T25 (one row per check and image: date, image, result). No URIs, paths or file names; use `[PLACEHOLDER]`._

### T19 — 2026-11-22
Images used:
- **API 36.1:** the `Medium_Phone_API_36.1` emulator, 2 GB, Google Play image, profile build x86_64; one row on the release build.
- **S23 Ultra (API 37):** used for the camera rows on Product Owner instruction, because the emulator's virtual-scene camera hangs the emulator. App uninstalled afterwards.
- **API 28 AOSP and API 28 Google Play:** not run yet; no local image (see Open questions).

Test images are synthetic only, pushed to the emulator's shared Pictures folder: the T02 arrow pattern 120×80, the 12 MP chart and the AC-3.5 set.

| # | Check | Image | Result |
|---|---|---|---|
| 1 | Gallery pick: the photo picker opens with images only, allows one selection (a second tap swaps it), and shows no permission prompt; the photo is handed on | API 36.1 | Pass: hand-off at 120×80; app log `ACCEPTED` only |
| 2 | Gallery cancel (Back) | API 36.1 | Pass: pick screen, no message, log `CANCELLED` |
| 3 | Double tap on Choose from gallery | API 36.1 | Pass: one picker in the task, one result |
| 4 | AC-3.5 set through the photo picker | API 36.1 | Pass: truncated JPEG and text-as-JPEG show the corrupt-file message, 250 MP header shows the too-large message. The undecodable HEIC opens on this API (N/A here; refused in CI API 28 by T15). The zero-byte file and the video are not offered by the image-only picker (N/A here; covered by T15). No file in app storage after any refusal |
| 5 | No camera app (camera app disabled for user 0) | API 36.1 | Pass: Take a photo is disabled with the visible reason; a tap does nothing. After the camera app is re-enabled and the app resumes, the button is enabled again |
| 6 | Low space (storage filled to 16 MiB free) | API 36.1 | Pass: low-space message, camera not launched, no camera file; space restored afterwards |
| 7 | Don't keep activities during the gallery picker | API 36.1 | Pass: result delivered once (one `ACCEPTED`), hand-off shown |
| 8 | `am kill` while idle, then relaunch | API 36.1 | Pass: starts on the pick screen, nothing restored, camera folder empty |
| 9 | Airplane mode, local pick | API 36.1 | Pass: hand-off shown |
| 10 | Back from the next step (start over) | API 36.1 | Pass: pick screen; camera folder empty |
| 11 | No copies (AC-6.1): app storage listed after every row | API 36.1, S23 | Pass: no file except the one accepted capture before start-over |
| 12 | Originals byte-identical (AC-6.6): SHA-256 and size after the run | API 36.1 | Pass: all 8 files match their pushed hashes; modification times unchanged |
| 13 | Logcat clean (AC-6.3): app-process lines matching content URIs, shared-storage or app-data paths, `.jpg`, `.png` or the test file names | API 36.1, S23, release build | Pass: 0 lines from the app. The only app lines are enum outcomes. System loader lines under the app's process name only the installed APK path |
| 14 | Merged manifest permissions (AC-6.4), release APK | build | Pass: no INTERNET, camera, storage or media permission; only the AndroidX dynamic-receiver permission (allowed in T09). Debug and profile builds add INTERNET for Flutter tooling only |
| 15 | Release build starts from a launcher intent and picks | API 36.1 | Pass. Flutter logs an "intent verification" warning for external intents; a launcher start still works. To recheck for the share target (T24) |
| 16 | Camera cancel | S23 | Pass: pick screen, no message, the empty camera file deleted, log `CANCELLED` |
| 17 | Camera capture | S23 | Pass: hand-off at 4000×3000; exactly one file in the private camera folder; nothing new in DCIM or Pictures; start-over deletes it |
| 18 | Don't keep activities during the camera | — | Not re-run: the developer setting would have to be changed on the Product Owner's phone. Covered by gate G1 item (b) on the S23 |
| 19 | Timing, return from the system UI to hand-off (informational, NFR-1) | API 36.1, S23 | Small JPEG: median 320 ms (5 runs). 12 MP JPEG: median 458 ms (5 runs). Camera 12 MP on the S23: 436 ms (1 run) |

**Gate G4:** passed on 2026-11-23 with a Product Owner waiver. The API 28 AOSP and API 28 Google Play manual rows were not run.
- **Evidence accepted instead:** this record (API 36.1 and the S23) plus CI's automated API 28 jobs (bundle, pick bridge, T15 pick data matrix, crop and decode matrices).
- **Results:** no crash or ANR; zero permission prompts; zero forbidden permissions; no copies; originals byte-identical; logcat clean; airplane mode works.

### T20 — 2026-11-23 (S23 Ultra, API 37, profile build; app uninstalled afterwards)
| # | Check | Image | Result |
|---|---|---|---|
| 1 | Camera open, Home, `am kill`, back in through the launcher, capture | S23 | Pass after the fixes below: the capture is recovered and probed, hand-off 4000×3000, one file. First runs failed: the capture was swept, and in one run "camera returned no photo" |
| 2 | The same, with a write failure (empty capture file made unwritable) | S23 | The camera app reports a cancel: pick screen, no message, file deleted (cancel path, correct). The "lost" path (OK with an empty file after recreation, or no result by `onResume`) could not be produced on the device; it is covered by unit tests and code review |
| 3 | The same, waiting 30 s before shooting (Samsung freezes, then unfreezes, the app process) | S23 | Pass: recovered and probed |
| 4 | Launcher icon while the camera is open, process alive | S23 | Pass: the capture file is kept; a later cancel deletes it |
| — | API 36.1 emulator and API 28 | — | Not run: the emulator's camera hangs it (the Product Owner directed camera rows to the S23), and there are no API 28 images (download declined at T19) |

Defects found and fixed in T20:
- **Duplicate launcher instance:** it finished at once (G1 finding g) but still ran Dart `main()` without the marker, and its start-up sweep deleted the capture in progress. It now answers every bridge call with an error, so the sweep skips.
- **Sweep race after recreation:** `onActivityResult` cleared the marker before Dart asked for it, so the sweep deleted the just-captured file. `pendingCaptureName` now also returns the file of a camera result that hasn't been taken yet.
- **Exists-then-length gap (T13 code):** the file could vanish between the two calls, giving an unhandled `PathNotFoundException` that printed an app-data path to logcat and stalled the controller's result queue. A single `stat()` call replaces them. Unexpected errors are now caught without printing, the attempt's file is deleted, and the screen shows "can't open this item".

### T21 — 2026-11-23 (API 36.1 emulator, profile build)
| # | Check | Image | Result |
|---|---|---|---|
| 1 | A camera file present, Back on the pick screen | API 36.1 | Pass: the activity finishes and the camera folder is empty (process still alive, so `onDestroy` ran). Observed: on Android 12+ Back does finish the root here, because Flutter handles Back itself and finishes the activity; the "back does not finish the root" hypothesis does not hold for this app |
| 2 | Launcher icon while the gallery picker is open (duplicate instance finishes) | API 36.1 | Pass: the camera file is kept and the picker stays on top |
| — | `am force-stop` or process kill | — | Not a finish; covered by the start-up sweep (T12) |
| — | API 28 | — | Not run (no image; download declined at T19) |

### T22 — 2026-11-23 (API 36.1 emulator, profile build)
| # | Check | Image | Result |
|---|---|---|---|
| 1 | Choose from files opens the document picker | API 36.1 | Pass: it opens on "Recent images", lists the image files only (the MP4 is not listed), and one tap returns one file |
| 2 | Zero-byte file through the document picker (AC-3.5) | API 36.1 | Pass: corrupt-file message, log `CORRUPT_INPUT` and `CORRUPT` |
| 3 | Valid image through the document picker | API 36.1 | Pass: hand-off at 120×80, log `ACCEPTED`, no copy in app storage (the only new files are Android's own compiled-code and profile files) |
| — | API 28 | — | Not run (no image; download declined at T19) |

## Instructions for Claude Code
- Read `prd.md`, `tech.md` and ADR-006 before starting a task.
- Implement only the current task, in order; tick its checkbox and add a line to `docs/CHANGELOG.md` when done.
- Gates: no task from T08 onwards before G1 passes (T02–T07 may run while G1 waits on the Product Owner); no visible pick-screen work (T17, T18, UI parts of T22, T23) before G3; T24–T25 only if G1 item h passed; stop at every failing gate and report to the Product Owner.
- UI rule: before designing or building any real UI screen, stop and tell the Product Owner (impeccable, decision 2026-11-20). T16 is that stop.
- T02 changes FEAT-002 code (`source_probe.dart`); keep it to the approved one-line rule and its test.
- If a requirement is unclear or wrong, stop and propose a PRD change.
- Privacy: synthetic test images only, never real faces or signatures; any sensitive value is `[PLACEHOLDER]`; no network calls; never log or put in crash reports URIs, paths, file names, EXIF values, sizes or platform exception text; originals are opened read-only; no copies of picked images.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-21 | First draft |
| 1.0 | 2026-11-21 | Approved by Product Owner |
