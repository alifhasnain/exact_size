---
id: FEAT-007-TASKS
title: Export and share — Implementation Tasks
status: Approved
version: 1.0
updated: 2026-11-24
links: [FEAT-007, FEAT-007-TECH, ADR-007, ADR-006, ADR-001, FEAT-001, FEAT-004, FEAT-006, FEAT-019]
---

# FEAT-007 — Implementation Tasks

Milestone: R1 Phase A — core. Work top to bottom, one task at a time.

Sizes: **S** ≈ 0.25 day, **M** ≈ 0.5 day, **L** ≈ 1 day; each task is one PR.
Module paths follow ADR-001: `lib/features/export/{domain,data,presentation}`, plus `lib/app_flow.dart`, `lib/main.dart`, `android/app/src/main/kotlin/com/exactsize/exact_size/{ExportBridge,MainActivity}.kt`, the manifest, `res/xml/share_paths.xml` and `android/app/build.gradle.kts`. Tests mirror them under `test/`; device tests in `integration_test/`; host drivers in `test_driver/`; fakes in `test_support/`.

**Already built, reused, not planned again:** `CompressionSuccess`, `CompressionController.cancel()` (the only deleter of the temp file), `TempFiles` and its start-up sweep, `OutcomeMessages`, the `_iso` FSI pattern (FEAT-004); `PickController.release()`, `isOwnProvider` in `MainActivity.kt`, `ShareTargetActivity`, the picker bridge and its Kotlin grep tests in `test/features/pick/pick_privacy_test.dart` (FEAT-001, ADR-006); `CropController.end()` (FEAT-002); `checkMergedManifest`; `test/features/compression/no_network_imports_test.dart`; `tool/run_offline_test.sh`; `test_driver/push_fixtures_driver.dart`, `test_driver/share_intent_driver.dart`; `TolerantGoldenComparator`; gen-l10n with 6 languages; the CI API 28 emulator job (`.github/workflows/ci.yml`).

**Test devices:**
- **Local device runs use the connected real phone, Realme 2 Pro, API 36**, not an emulator (the local emulator's data was corrupted during FEAT-005; same substitution as FEAT-005 T15–T18). Check `adb devices` first.
- **API 28 runs only in the CI emulator job.** There is no local API 28 image (see Open items 6).
- New `*_test.dart` files run from `integration_test/bundle.dart`; a test that needs a host driver gets its own `flutter drive` line in the same `script:` block of `ci.yml`.

**Emulator/device test rule:** files run under `flutter drive` use `testWidgets` only. Plain `test()` failures are not reported under `flutter drive`, so a failing check would pass silently.

**Real-phone data rule:** device tests write synthetic files into the Product Owner's `Pictures/ExactSize`. Each run deletes only the files it created (names held in the driver's memory or `build/`, never in the Test record). No low-space test on the real phone (it would fill a personal device). If a cloud gallery backup is on, the synthetic files may be uploaded: the Product Owner pauses backup for the run or accepts it.

**Decisions from FEAT-007-TECH section 12 used here (approved with tech.md v1.0):**
- OQ-T2: "Choose where to save" shows only after a permission refusal on API 28 (T08, T18).
- OQ-T3: Open is also offered after a save-as save, using the document URI (T14, T18).
- OQ-T4: `OPEN_NO_VIEWER` is **not** used in code until the PRD lists it (T02 blocks T14). See Open items 1.
- OQ-T5: kill test uses a large synthetic blob first; a debug-only chunk delay only if R10 happens (T22).
- PRD OQ-2, OQ-4, OQ-5, OQ-6, OQ-7, OQ-8, OQ-9 are not yet ticked in the PRD; tasks use their defaults (`Pictures/ExactSize`, idempotent Save, confirm on back only when nothing was saved or shared, both Shoulds kept, the FR-4 name, share copy deleted at leave, hint shown). G1 asks the Product Owner to confirm the UI ones or say "defaults".

## Decision gates
| Gate | Task | Passes when | If it fails |
|---|---|---|---|
| G0 Platform spike | T01 | Every tech [Hypothesis] listed in T01 is observed on the Realme 2 Pro (API 36) and in one CI API 28 run, and recorded in the Test record | A failed hypothesis stops the plan: propose a tech.md (or PRD) change to the Product Owner before T04 |
| G1 Export design | T17 | A lean impeccable pass is done (Material 3, no image comps, no reviewer subagents, one round). The Product Owner has seen it and answered the G1 questions or said "defaults". The design reference and date are recorded | No visible UI work (T18–T20). Non-visual tasks T01–T16 may run |
| G2 Design check | T20 | The Product Owner has seen one real-phone screenshot each of ready, saved, error, permission-denied layout (forced in a demo build), ar RTL and 200% font, and accepts them or names fixes. One look | Fixes go into T20 before T21. A scope change means a PRD change |
| G3 Device run | T23 | Every checklist row passes on the Realme 2 Pro (API 36), and the CI API 28 job is green for `bundle.dart`, `export_bridge_test.dart`, `export_reliability_test.dart`, `target_flow.dart` and the share drive. Required: no crash, no file name, URI, path or size in logcat, nothing left in app cache after leave, airplane mode works, TalkBack announces the save result once | A privacy, data-loss, crash or accessibility miss means stop and report to the Product Owner. An OEM behaviour miss (R4, H7) is recorded as residual risk, not a stop |

## Tasks

### - [ ] FEAT-007-T01 — Platform spike on the real phone and CI API 28 — gate G0
- **Implements:** verification for FR-5, FR-6, FR-7, FR-13, FR-15, FR-16, FR-17, NFR-7 · **ADRs:** ADR-007
- **Depends on:** —
- **Size:** M
- **Scope:** throwaway branch, not merged: a minimal Kotlin spike class plus `integration_test/export_spike_test.dart` (`testWidgets` only), synthetic bytes only. Observe and record:
  - H1: a MediaStore row with `IS_PENDING=1` under `RELATIVE_PATH=Pictures/ExactSize` is not returned to a second query without the pending flag, and appears after `IS_PENDING=0`.
  - MediaStore behaviour on a duplicate `DISPLAY_NAME` (rename, not overwrite; record the read-back name form).
  - Owner-filtered pending query (API 30+ `QUERY_ARG_MATCH_PENDING`) returns only our rows.
  - H2 on CI API 28: after `pm grant ... WRITE_EXTERNAL_STORAGE`, `checkSelfPermission(READ_EXTERNAL_STORAGE)` result.
  - API 28: `.part` with a leading dot is not indexed by the media scanner; `Files.move` without replace throws on an existing target; `scanFile` callback time.
  - H5: `OpenableColumns.DISPLAY_NAME` of a `.share` FileProvider URI equals the file name.
  - `EXTRA_EXCLUDE_COMPONENTS` on the Realme share sheet (observed by eye; no image of the screen committed).
  - Save-as result after "Don't keep activities": does an empty document stay (R8).
- **Done when:** each item above has one Test record row (pass/fail per API level, no URIs, paths or file names). Any failed item has a written proposal to the Product Owner. Gate G0 is recorded. Spike code is deleted.

### - [ ] FEAT-007-T02 — Product Owner PRD clarification for `OPEN_NO_VIEWER`
- **Implements:** FR-15, FR-27 (log code list) · **ADRs:** —
- **Depends on:** —
- **Size:** S (Product Owner time; developer side only prepares the change)
- **Scope:** tech.md proposes an `OPEN_NO_VIEWER` outcome code for the FR-15 "No app can open this file" message (tech OQ-T4); PRD sections 5 and 10 do not list it, and FR-27 allows only the listed codes. Prepare a one-line PRD clarification (section 5 info codes and section 10 log list, version 1.1, Change log line) and give it to the Product Owner. Do not edit the Approved PRD status yourself; the Product Owner's flow sets it Under Discussion and `/approve` re-approves it. The Product Owner may fold Open items 2 and 3 into the same edit.
- **Done when:** PRD version 1.1 (minor) listing `OPEN_NO_VIEWER` is Approved by the Product Owner through `/approve`, **or** the Product Owner declines in writing, in which case T14 shows the message and logs nothing for it.

### - [ ] FEAT-007-T03 — Domain: `ExportName`, `ExportOutcome`, `SavedItem`, `BridgeSave`, `ExportInput`
- **Implements:** FR-4, FR-27 (redaction), NFR-5 (secure random) · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** S
- **Scope:** `lib/features/export/domain/` per tech section 4.2:
  - `ExportName.generate(w, h, OutputFormat, Random)` with the section 8 regex and the 40-character cap asserted; `ext` and `mime` per format. Callers pass `Random.secure()`.
  - `ExportOutcome` with the **nine PRD codes only** (`code` getter gives the PRD spelling). `openNoViewer` is added in T14 if T02 approves it.
  - `SavedItem {ref, displayName, viaSaveAs}`, sealed `BridgeSave`, `ExportInput (CompressionSuccess, Target)`; redacted `toString` on all of them.
  - No Flutter, Riverpod, get_it or channel imports.
- **Done when:** unit tests pass: 10,000 generated names all match the regex, are ≤ 40 characters and contain no repeat; 1×1 and 999999×999999 both valid; jpeg → `jpg`/`image/jpeg`, png → `png`/`image/png`; a grep test finds `Random.secure()` at every `ExportName.generate` call site in `lib/` and no `Random(` elsewhere in `lib/features/export/`; `toString` of each type built from `[PLACEHOLDER]`-style synthetic values contains neither the name, the ref nor the size; `ExportOutcome.values.map((o) => o.code)` equals the PRD section 5 list.

### - [ ] FEAT-007-T04 — Manifest, share FileProvider and `checkMergedManifest` rules
- **Implements:** FR-8, FR-18, NFR-5, NFR-8 (permission set) · **ADRs:** ADR-007
- **Depends on:** T01 (G0)
- **Size:** S
- **Scope:** per tech sections 2 and 7:
  - `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>`.
  - Second `FileProvider`, authority `${applicationId}.share`, `exported="false"`, `grantUriPermissions="true"`, `@xml/share_paths`; `share_paths.xml` holds only `<cache-path name="share" path="exactsize_share/"/>`.
  - `checkMergedManifest` rules 1–5: WRITE needs `maxSdkVersion` ≤ 28; `MANAGE_EXTERNAL_STORAGE` banned (existing bans kept); `.share` provider exists, not exported, only `@xml/share_paths` with exactly one path; every FileProvider is one of our two authorities; no exported provider. Fails, never strips.
- **Done when:** `./gradlew :app:assembleRelease` passes with the check on. A negative check (test manifest or Gradle test fixture) fails for each of: WRITE uncapped, WRITE capped at 29, a third FileProvider, `.share` exported, a second path in `share_paths.xml`. The merged-manifest permission list is pasted into the PR (evidence for NFR-8). The camera provider checks are unchanged.

### - [ ] FEAT-007-T05 — `ExportBridge.kt` foundation: channel, `MainActivity` wiring, `share`, `itemExists`, `open`
- **Implements:** FR-15 (native), FR-17, FR-18, FR-20, FR-27 (native side) · **ADRs:** ADR-007, ADR-006
- **Depends on:** T04
- **Size:** M
- **Scope:**
  - New `ExportBridge.kt` on `MethodChannel('exactsize/export')`; one single-thread executor; results posted on the main thread; every entry point catches `Throwable` and returns enum strings or `PlatformException('internalError', null)`; no `android.util.Log`, `println` or `printStackTrace`.
  - `MainActivity.kt`: create in `configureFlutterEngine`, forward `onActivityResult(REQUEST_SAVE_AS)` and `onRequestPermissionsResult`, remove in `cleanUpFlutterEngine` (about 15 lines). Picker code unchanged.
  - `share(path, mime)`: `getUriForFile(.share)` (throws outside the folder = guard), `ACTION_SEND`, `EXTRA_STREAM` + `ClipData`, `FLAG_GRANT_READ_URI_PERMISSION` only, chooser with `EXTRA_EXCLUDE_COMPONENTS = [ShareTargetActivity, MainActivity]`, `startActivity` → `opened`, throw → `failed`.
  - `itemExists(ref)`: content URI query or file exists for an API 28 path; `false` on any error.
  - `open(ref, mime)`: `ACTION_VIEW` with read grant; `ActivityNotFoundException` → `noViewer`; API 28 path ref re-scans once.
  - Stubs for `save`, `saveAs`, `sweepIncomplete` return `failed` / null until T06–T09.
- **Done when:** the release build passes. The Kotlin grep test (extended in `test/features/pick/pick_privacy_test.dart` or a new `test/features/export/export_kotlin_grep_test.dart`) passes for `ExportBridge.kt`: no `Log.`, `println`, `printStackTrace`, `READ_EXTERNAL_STORAGE`, and every `catch` returns without reading `.message`. The existing pick bridge drive (`integration_test/pick_bridge_test.dart`) still passes on the Realme 2 Pro.

### - [ ] FEAT-007-T06 — Kotlin `save` on API 29+ (MediaStore, pending, verify, publish)
- **Implements:** FR-2 (native length check), FR-3, FR-5, FR-6, FR-11 (read-back name), FR-13 (system rename), FR-14, NFR-1, NFR-6 · **ADRs:** ADR-007
- **Depends on:** T05
- **Size:** M
- **Scope:** tech section 4.3 "Kotlin save on API 29+" steps 1–6: length check → `fileMissing`; insert with `DISPLAY_NAME`, `MIME_TYPE`, `RELATIVE_PATH=Pictures/ExactSize`, `IS_PENDING=1` (null → `failed`); 64 KiB chunk copy, flush, `fd.sync()`; verify `statSize == bytes` else delete → `failed`; `IS_PENDING=0`; return the queried `DISPLAY_NAME` and URI. On `IOException`/`SecurityException`: delete the row, then `noSpace` if `StatFs` free < bytes + 1 MiB, else `failed`. Never `nameTaken` on 29+.
- **Done when:** on the Realme 2 Pro a temporary drive check in `integration_test/export_bridge_test.dart` (completed in T11) saves a synthetic 300 KB JPEG: SHA-256 and length equal the source, the folder gains exactly one file and no pending row is visible to a non-pending query. A forced failure (source deleted mid-call by a test hook in the driver, or a zero `bytes` mismatch) leaves no row and returns `failed`/`fileMissing`. The grep test still passes.

### - [ ] FEAT-007-T07 — Kotlin `save` on API 28 (permission, `.part`, no-overwrite rename, scan)
- **Implements:** FR-3, FR-7, FR-8 (own folder only), FR-9 (once per call), FR-13, FR-14, NFR-6 · **ADRs:** ADR-007
- **Depends on:** T06
- **Size:** M
- **Scope:** tech section 4.3 "Kotlin save on API 28" steps 1–6: `checkSelfPermission`; if missing, `requestPermissions` once and hold the pending `Result` in the bridge instance; denied (including "don't ask again") → `permissionDenied`; no stored "asked" flag, no rationale. `Pictures/ExactSize/.<name>.part` → copy → sync → verify → `Files.move` without `REPLACE_EXISTING` (`FileAlreadyExistsException` → delete part → `nameTaken`); final or part exists up front → `nameTaken`. `scanFile` with a 2 s wait; `ref` = scanned URI or the path. Errors delete `part`.
- **Done when:** in the CI API 28 job (driver runs `pm grant`), the T11 checks for byte equality, one visible file, no `.part` left and a pre-made colliding final file kept untouched with `nameTaken` returned all pass. With `pm revoke` plus `pm set-permission-flags ... user-fixed` the call returns `permissionDenied` at once with no dialog (AC-2.4) and writes nothing. The Kotlin grep test fails on any `listFiles` call outside the `Pictures/ExactSize` directory.

### - [ ] FEAT-007-T08 — Kotlin `saveAs` (system save-as dialog) — Should
- **Implements:** FR-10, FR-14 · **ADRs:** ADR-007
- **Depends on:** T05
- **Size:** S
- **Scope:** tech section 4.3 "Kotlin saveAs": `ACTION_CREATE_DOCUMENT`, `CATEGORY_OPENABLE`, mime, `EXTRA_TITLE = name`; on `RESULT_OK` chunk copy on the executor, verify `statSize`; failure → `deleteDocument` best effort → `noSpace`/`failed`; cancel → `cancelled`; a result with no pending call deletes the created document and reports nothing (R8). Returns the picked document's `DISPLAY_NAME`.
- **Done when:** manual check on the Realme 2 Pro (recorded in the Test record): save-as to Downloads with a synthetic file gives an identical length; cancel returns `cancelled`; with "Don't keep activities" on, a save-as completed after recreation leaves no empty document. No permission dialog on any path.

### - [ ] FEAT-007-T09 — Kotlin `sweepIncomplete` and Dart start-up sweeps
- **Implements:** FR-8, FR-16 · **ADRs:** ADR-007
- **Depends on:** T07
- **Size:** S
- **Scope:** tech section 4.4 on the same executor as `save`: API 30+ `MATCH_ONLY` pending query with `RELATIVE_PATH`, `OWNER_PACKAGE_NAME`, `DISPLAY_NAME LIKE 'exactsize-%'`; API 29 `setIncludePending`; API 28 only if WRITE is already granted, delete only `^\.exactsize-.+\.(jpg|png)\.part$` in `Pictures/ExactSize`. Never requests a permission, never touches a completed file. **Logs nothing** (the tech's `sweep=done/skipped` lines are not in the PRD log list; Open items 2). `lib/main.dart` wiring is added in T10.
- **Done when:** the T11 drive check plants a pending row (API 36) and a `.part` file (API 28), calls `sweepIncomplete`, and finds both gone while a completed file next to them keeps its SHA-256. With WRITE revoked on API 28 the planted `.part` stays and no dialog appears. The Kotlin grep test fails on a MediaStore query in `ExportBridge.kt` without `RELATIVE_PATH` and `OWNER_PACKAGE_NAME` in its selection.

### - [ ] FEAT-007-T10 — Dart data layer: `AndroidExportBridge`, `ShareCopies`, `ExportOutcomeLog`, DI, `main.dart` sweeps
- **Implements:** FR-3 (share copy length check), FR-5, FR-16 (wiring), FR-27, FR-28, NFR-9 · **ADRs:** ADR-007, ADR-001
- **Depends on:** T03, T09
- **Size:** M
- **Scope:**
  - `lib/features/export/data/export_bridge.dart` (interface, tech 4.2) and `android_export_bridge.dart`: map channel results to `BridgeSave` / bool; unknown or malformed payloads → `saveFailed`/`false`; any `PlatformException` → `saveFailed`, message dropped; never logs payloads.
  - `share_copies.dart` on a new `@Named('share')` `TempFiles` (`exactsize_share`): `copy(src, name)` (`File.copy` + length check), `delete`, `sweep`.
  - `export_outcome_log.dart`: same shape as `PickOutcomeLog`, writes only `exactsize.export outcome=<CODE>`.
  - injectable registrations (`ExportBridge` as `@lazySingleton`); `build_runner` output committed as the project does.
  - `lib/main.dart`: `unawaited` share-folder sweep and `unawaited(sweepIncomplete())`, next to the existing sweeps.
  - `test_support/fake_export_bridge.dart` for T12–T14.
- **Done when:** unit tests pass with a mocked channel (`TestDefaultBinaryMessenger`): every tech 4.1 outcome maps correctly; `{outcome: 'garbage'}`, a missing key, `null` and a `PlatformException` with a `[PLACEHOLDER]` message all map to failure and the message text appears nowhere in captured logs; `ShareCopies` on a temp dir copies with equal length, refuses a length mismatch, deletes and sweeps; `ExportOutcomeLog` output matches `^exactsize\.export outcome=[A-Z_]+$`. App start on the Realme 2 Pro shows no exception from the new sweeps.

### - [ ] FEAT-007-T11 — Bridge drive target, offline run and CI line (integration/CI task)
- **Implements:** FR-3, FR-4, FR-5, FR-6, FR-7, FR-12 (`itemExists`), FR-13, FR-16, FR-18, FR-28, NFR-3, NFR-7 · **ADRs:** ADR-007
- **Depends on:** T10
- **Size:** M
- **Scope:** new `integration_test/export_bridge_test.dart` (**`testWidgets` only**) with host driver `test_driver/export_driver.dart` (runs `pm grant`/`revoke`/`set-permission-flags` on API 28 and `adb shell ls`/`rm` in `Pictures/ExactSize`), through the real `AndroidExportBridge`, synthetic bytes only. Checks from tech section 8 testing:
  - AC-1.2 SHA-256 and length equal; AC-1.4 exactly one new file, no `.part` or `.pending-*`.
  - AC-6.1 100 saves → 100 distinct files, all FR-4 names; AC-6.3 API 28 collision kept untouched.
  - AC-5.3 `itemExists` true, then false after `adb shell rm`.
  - `getUriForFile` refuses a file in `exactsize_out/`; the `.share` URI's `DISPLAY_NAME` is the FR-4 name (H5).
  - A `.share` URI sent to `ShareTargetActivity` → `itemNotOpenable` (FR-18, FEAT-001 FR-20).
  - T09 sweep checks.
  - Driver deletes every file the run created.
  - Extend `tool/run_offline_test.sh` to run this target in airplane mode (NFR-3).
  - CI: add `DEVICE=emulator-5554 timeout 900 flutter drive --driver test_driver/export_driver.dart --target integration_test/export_bridge_test.dart -d emulator-5554` to the `script:` block of `.github/workflows/ci.yml`.
- **Done when:** the target passes on the Realme 2 Pro and in the CI API 28 job, and the offline run passes on the Realme 2 Pro. Results (pass/fail per check, no URIs, paths or file names) are in the Test record. `Pictures/ExactSize` on the phone holds no file from the run afterwards.

### - [ ] FEAT-007-T12 — `ExportController`: Save path (FR-2 check, busy guard, retries, idempotent Save, progress)
- **Implements:** FR-2, FR-9, FR-11 (state), FR-12, FR-13, FR-14, FR-24 (progress), NFR-1 (timer), NFR-9 · **ADRs:** ADR-001
- **Depends on:** T10
- **Size:** M
- **Scope:** `lib/features/export/presentation/export_controller.dart`: `NotifierProvider.autoDispose.family<ExportController, ExportState, ExportInput>` (tech 4.2). `save()` per tech 4.3 "Save (any API level)": busy → return; `saved != null` → `itemExists` → `ALREADY_SAVED` or save again; FR-2 check → `FILE_MISSING`; up to 5 names on `BridgeNameTaken`, then `SAVE_FAILED`; `SAVED` with read-back name; errors keep the temp file; `showProgress` after 500 ms; log the code. No persistence.
- **Done when:** unit tests with `FakeExportBridge` and `TempFiles` on a temp dir pass: missing file and wrong length → `FILE_MISSING` and no bridge call; success → `SAVED`, `saved.displayName` = read-back name; `nameTaken` ×1 then success (2 calls, 2 different names); ×5 → `SAVE_FAILED`; each of `noSpace`, `saveFailed`, `permissionDenied` keeps the temp file and leaves Save retryable; two `save()` calls during one slow fake save → one bridge call; repeat Save with `itemExists` true → `ALREADY_SAVED`, no bridge save; false → a second save; `showProgress` false at 499 ms, true at 500 ms (fake async); a new `ProviderContainer` starts with empty state.

### - [ ] FEAT-007-T13 — `ExportController`: Share, Save as, leave, `needsLeaveConfirm`
- **Implements:** FR-2, FR-10, FR-17 (Dart side), FR-19, FR-20, FR-22, FR-23, FR-24, FR-25 · **ADRs:** ADR-001
- **Depends on:** T12
- **Size:** M
- **Scope:** tech 4.3 "Share" and "Leave":
  - `share()`: FR-2 check; first Share makes one `ShareCopies` copy with a new FR-4 name, later Shares reuse it; bridge `false` or copy failure → `SHARE_FAILED`; success sets only `sharedOnce`, logs `SHARE_OPENED`, sets no message.
  - `saveAs()`: same busy guard; `cancelled` → `SAVE_CANCELLED`, no message; success sets `saved` with `viaSaveAs: true`.
  - `needsLeaveConfirm` = `saved == null && !sharedOnce`.
  - `leave()`: await an in-flight save; delete the share copy; `CompressionController.cancel()`. The caller then runs `release()`, `end()`, `popUntil(isFirst)` (T19).
- **Done when:** unit tests pass: two Shares → one copy, two bridge calls, no shared-storage save; share failure → `SHARE_FAILED`, temp kept; after a successful Share `message` is null; save-as cancel → no message, nothing saved; save-as success counts as saved for `needsLeaveConfirm`; `leave()` during a slow fake save waits for it, then the share copy and the temp file are gone and `cancel()` was called once; `needsLeaveConfirm` true only when nothing was saved or shared.

### - [ ] FEAT-007-T14 — `ExportController.open` and the no-viewer outcome — Should
- **Implements:** FR-15, FR-27 · **ADRs:** ADR-007
- **Depends on:** T02, T13
- **Size:** S
- **Scope:** `open()` calls `bridge.open(saved.ref, mime)` (also after save-as, OQ-T3); `false` → the no-viewer message. If T02 approved PRD 1.1: add `ExportOutcome.openNoViewer` (`OPEN_NO_VIEWER`) and log it. If the Product Owner declined: show the message from a non-logged UI state and log nothing.
- **Done when:** unit tests pass: no `saved` → `open()` does nothing; viewer present → no message; no viewer → the no-viewer message, Save and Share still work; the log line is `OPEN_NO_VIEWER` (approved case) or absent (declined case); the T03 code-list test matches the PRD version in force.

### - [ ] FEAT-007-T15 — Export privacy static tests and log audit
- **Implements:** FR-3 (no codec), FR-8, FR-27, FR-28, NFR-3, NFR-5 · **ADRs:** ADR-007
- **Depends on:** T14
- **Size:** S
- **Scope:** new `test/features/export/export_privacy_test.dart`, same pattern as `target_privacy_test.dart`, scanning `lib/features/export/`:
  - Network import ban (extend `no_network_imports_test.dart` scope), codec imports (`dart:ui` image codecs, `package:image`, the FFI codec), `shared_preferences`, `restorationId`, `RestorationScope`, `print(`, `debugPrint(`, `log(` outside `ExportOutcomeLog`, any ad/analytics/crash SDK import.
  - `lib/features/export/domain/` imports no Flutter, Riverpod, get_it or channel code.
  - Log audit: run the T12–T14 suites with a capturing log sink; every export line matches `^exactsize\.export outcome=[A-Z_]+$` and no line contains `exactsize-`, `content://`, `/data/`, `/storage/`, `Pictures` or a `[PLACEHOLDER]` test value.
  - Kotlin grep rules from T05, T07, T09 collected in one place.
- **Done when:** the test passes on the current tree. The PR shows it failing once per rule when a forbidden token is added to a scratch file in each scanned location.

### - [ ] FEAT-007-T16 — English strings and `ExportMessages`
- **Implements:** FR-11, FR-21, FR-26, FR-30, NFR-4 · **ADRs:** ADR-001
- **Depends on:** T03
- **Size:** S
- **Scope:** `lib/l10n/app_en.arb`, each key with an `@` description and ICU placeholders, no concatenation: Save, Share, Choose where to save, Open, Done, the ready line (`{width}`, `{height}`, `{size}`, `{format}`), every PRD section 8 message (`SAVED` with `{folder}`/`{fileName}`, save-as name-only variant, `ALREADY_SAVED`, `NO_SPACE`, `SAVE_FAILED`, `PERMISSION_DENIED`, `FILE_MISSING`, `SHARE_FAILED`, no-viewer), the FR-26 privacy line, the FR-21 hint, the leave dialog (title, Stay, Leave), the progress label. `lib/features/export/presentation/export_messages.dart` maps outcomes to strings; folder and file name wrapped in U+2066/U+2069 LTR isolates in code (never in the ARB), numbers through `NumberFormat(localeName)` with the existing `_iso` pattern.
- **Done when:** `flutter gen-l10n` passes. A unit test checks every `ExportOutcome` that shows a message has a non-empty English string, and that the rendered `SAVED` text wraps `exactsize-300x300-[TOKEN].jpg` in an LTR isolate. The existing "no literal numbers in ARB" test passes with the new keys in scope. The PR lists the new keys.

### - [ ] FEAT-007-T17 — Export panel and result screen design pass with the Product Owner (impeccable, lean) — gate G1
- **Implements:** prerequisite for FR-1, FR-9–FR-12, FR-15, FR-19–FR-21, FR-23, FR-26, FR-29, NFR-2, NFR-4 (visual) · **ADRs:** —
- **Depends on:** T13, T14, T16
- **Size:** M (developer side; the Product Owner's time is not counted)
- **Scope:** **Stop and tell the Product Owner before any visible work.**
  - One short impeccable pass on Material 3. No image comps, no reviewer subagents, no multi-round critique.
  - Inputs: `ResultScreen` states (running with Cancel, failure with Back, success with the ready line); `ExportPanel` elements (Save, Share, "Choose where to save" after an API 28 refusal, Open after a save, live-region message, privacy line, chat hint, Done, saving progress); the leave dialog; the T16 strings.
  - Constraints: no image preview and no "meets spec" claim (FEAT-006); message in a live region that stays until leave; ≥ 48 dp; no status by colour alone; 200% font at 360×640; RTL mirroring with file name and folder LTR and unbroken; Save visibly inactive while busy.
  - Questions for the Product Owner: PRD OQ-5 (confirm on back, default yes), OQ-6 (keep both Shoulds, default yes), OQ-9 (show the chat hint now, default yes; copy confirmed after the T23 chat-app check). Say "defaults" to accept all.
  - Define the G2 screenshots: ready, saved, error, permission-denied layout (forced in a demo build on API 36), ar RTL, 200% font.
- **Done when:** the design reference (file or link, synthetic content only) and its date are in the PR and `docs/CHANGELOG.md`. The Product Owner's answers (or "defaults") are recorded through the Product Owner's flow. Gate G1 is recorded.

### - [ ] FEAT-007-T18 — `ExportPanel`
- **Implements:** FR-1 (panel content), FR-9, FR-10, FR-11, FR-12 (busy look), FR-15, FR-19, FR-20, FR-21, FR-26, NFR-2 · **ADRs:** ADR-001
- **Depends on:** T17 (G1)
- **Size:** M
- **Scope:** `lib/features/export/presentation/export_panel.dart`, built to the G1 design: `ExportPanel(success:, size:)` watches `exportControllerProvider(ExportInput(...))`. Save, Share, "Choose where to save" (only after `PERMISSION_DENIED`, OQ-T2), Open (after a save), the message in a `Semantics(liveRegion: true)` region announced once, the privacy line, the hint near Share, progress after 500 ms. Self-contained so FEAT-006 can embed it unchanged.
- **Done when:** widget tests with `FakeExportBridge` pass: Save → saved message with folder and name, announced once; `PERMISSION_DENIED` → message plus Share and "Choose where to save" enabled; a successful Share shows no message (AC-3.5); share failure → `SHARE_FAILED` text; Save tapped twice while busy → one bridge call, Save shown inactive (with text or icon, not colour alone); Open hidden before a save; the privacy line and hint present; no image widget in the tree.

### - [ ] FEAT-007-T19 — `ResultScreen`, `app_flow.dart` swap, leave handling, stand-in removed
- **Implements:** FR-1, FR-22, FR-23, FR-24, FR-25, FR-29 · **ADRs:** ADR-001
- **Depends on:** T18
- **Size:** M
- **Scope:** `lib/features/export/presentation/result_screen.dart` per tech 4.5 and the G1 design. `_CropStep.onContinue` pushes `ResultScreen(spec:)`; delete `_AfterCropStandIn` and its `shortcut:` comment. Running: progress + Cancel → `cancel()` and pop to crop. Failure: `OutcomeMessages.failure(...)` + Back. Success: ready line from `spec.dimensions`, `s.sizeBytes`, `s.format` (not recomputed) + `ExportPanel` + Done. `PopScope(canPop: false)` on success: back or Done → FR-23 dialog if `needsLeaveConfirm` → `leave()` → `release()`, `end()`, `popUntil(isFirst)`. **Update callers of the stand-in:** the T11 test in `test/app_flow_test.dart` and `integration_test/target_flow.dart` (expects READY on the stand-in and its pop) now target `ResultScreen`.
- **Done when:** widget tests pass: no Save/Share while running or after a failure (FR-1); back with nothing saved shows the dialog, Stay keeps the screen, Leave runs leave once; back after a save leaves without a dialog; leave during a slow fake save waits, then the temp file is gone, `release()` and `end()` ran once and the pick screen is on top; `test/app_flow_test.dart` passes; `target_flow.dart` passes on the Realme 2 Pro; `grep -r _AfterCropStandIn lib test integration_test` finds nothing.

### - [ ] FEAT-007-T20 — Accessibility, 200% font, RTL, goldens — gate G2
- **Implements:** NFR-2, NFR-4, FR-1, FR-30 (isolates) · **ADRs:** —
- **Depends on:** T19
- **Size:** M
- **Scope:** ≥ 48 dp targets; text scaling; buttons wrap into a column at large scale; Material 3 roles only; Arabic mirrored with file name and folder LTR and unbroken, digits 0-9. Host goldens with `TolerantGoldenComparator`: en and ar × ready, saved, error at 360×640, plus 200%. One real-phone screenshot (Realme 2 Pro, synthetic image) per G2 state, shown to the Product Owner.
- **Done when:** widget tests pass for AC-9.1 (ar mirrored, the saved name is one LTR isolate), AC-9.2 (one live-region announcement per save result, every control ≥ 48 dp, status has text), text scale 2.0 at 360×640 with no overflow. Goldens pass. The screenshots are in the PR (not committed unless the Product Owner asks). Gate G2 is recorded.

### - [ ] FEAT-007-T21 — Translate FEAT-007 strings (es, pt, hi, id, ar) — Product Owner runs `/l10n-translate`
- **Implements:** FR-30, NFR-4 · **ADRs:** —
- **Depends on:** T16, T20 (strings final after G1/G2)
- **Size:** M (not counted in the tech estimate: FEAT-019 work)
- **Scope:** the Product Owner types `/l10n-translate <lang>` for es, pt, hi, id and ar, one language at a time. Only the vendored `localize-*` skills and the CLAUDE.md variants (pt-BR, es-419, MSA with Western digits). Only app strings go to the model, never user data, file names or paths. Keys, ICU syntax and placeholder names stay identical to `app_en.arb`; no bidi marks in placeholders. Status is `AI-reviewed only`; never write "native-quality" or "native-reviewed". Keep the permission, failure and privacy messages short and plain.
- **Done when:** all five `app_*.arb` files contain every FEAT-007 key; the mechanical checks pass; `docs/l10n/ai-review-log.md` has one entry per language with status `AI-reviewed only`; `flutter gen-l10n` reports no untranslated FEAT-007 keys; a widget test renders the result screen and panel in all 6 locales without a missing-key fallback.

### - [ ] FEAT-007-T22 — Reliability drive: kill test, low space, timing, CI line
- **Implements:** FR-14, FR-16, NFR-1, NFR-6, NFR-7 · **ADRs:** ADR-007
- **Depends on:** T11
- **Size:** M
- **Scope:** new `integration_test/export_reliability_test.dart` (**`testWidgets` only**), driven by `test_driver/export_driver.dart`:
  - **Kill test (NFR-6):** a synthetic ~50 MB blob (test only) saved through the bridge; the driver kills the process after a random delay (`run-as <package> kill -9` on the Realme debug build; `adb root` on the CI image), relaunches, waits for the sweep, asserts no `.part` or `.pending-*` entry and that every visible file matches its hash. 20 kills per API level (Realme API 36, CI API 28). If kills never land inside the copy (R10), stop and ask the Product Owner about the OQ-T5 debug-only delay.
  - **Low space (AC-4.1, AC-4.2):** **CI API 28 emulator only** (never on the real phone): fill the data partition with `fallocate`/`dd`, expect `NO_SPACE` and no partial file, free space, save succeeds without re-running compression.
  - **Timing (NFR-1):** median of 20 saves of a 1 MB synthetic file, reported per device (informational: the PRD target is the 2 GB emulator profile, Open items 5).
  - CI: one more `flutter drive` line in `ci.yml` for this target; low-space runs only when the driver detects the emulator.
  - Driver deletes every file the run created.
- **Done when:** 20/20 kills per API level leave no visible partial file and every visible file matches its hash; the low-space check passes in CI; the timing median per device is in the Test record; the CI API 28 job is green.

### - [ ] FEAT-007-T23 — Real-phone run and scripted checklist (Realme 2 Pro, API 36) — gate G3
- **Implements:** FR-9, FR-10, FR-15, FR-17, FR-21, FR-22, FR-25, FR-27, NFR-2, NFR-3, NFR-7, NFR-8 (evidence) · **ADRs:** —
- **Depends on:** T21, T22
- **Size:** M
- **Scope:** rows kept in the Test record below, run on the Realme 2 Pro (profile build), synthetic image shared in with `am start` as in FEAT-005 T18. Each row gets the adb command, the expected result and pass/fail:
  - AC-1.1 and AC-2.5: Save with no permission prompt; message names folder and file.
  - AC-1.3: the system file picker lists the file under Images and in the ExactSize folder.
  - H7: the stock gallery shows the folder (record what is seen; residual if not).
  - AC-3.1 and R4: the share sheet lists apps and not ExactSize; AC-3.4 dismiss gives no message.
  - AC-7.2: Open shows the file in the stock viewer.
  - H6 / PRD OQ-9 (optional, Product Owner performs it): one chat app, synthetic image sent to themselves; record whether the KB changed.
  - Save as to Downloads and cancel (FR-10 shown here via a demo-build switch, since the action normally appears only after an API 28 refusal).
  - AC-8.1: after Done, `adb shell run-as <package> ls cache/exactsize_out cache/exactsize_share cache/camera` is empty.
  - AC-8.2: back with nothing saved asks; Stay keeps the screen.
  - AC-8.3: `am kill` on the export screen, relaunch → pick screen, cache empty after the sweep.
  - AC-8.5 / FR-27: `adb logcat -d` for the app process grepped for `exactsize-`, `content://`, `/storage/`, `/data/`, `Pictures` → zero app-written lines.
  - AC-9.2 / NFR-2: `uiautomator events` shows one announcement per save result; TalkBack speech if available.
  - NFR-3: airplane mode, Save and Share both work.
  - R8: "Don't keep activities" with save-as open → no stuck busy state, no empty document.
  - API 28 permission dialog rows (AC-2.1–2.3): **not runnable here** (phone is API 36; CI cannot tap system dialogs). CI covers granted and user-fixed denied (T07). Recorded as a gap; see Open items 6.
  - NFR-8 evidence: the merged-manifest permission list from T04 attached; PRD OQ-10 stays open for release.
  - Cleanup: delete only the run's files in `Pictures/ExactSize`, restore font scale, rotation, airplane mode, accessibility and developer options as found; uninstall the test build if the Product Owner asks.
- **Done when:** every runnable row passes and is recorded below with date and device. CI API 28 is green for `bundle.dart`, `export_bridge_test.dart`, `export_reliability_test.dart`, `target_flow.dart` and the share drive. Gate G3 is recorded, including the Product Owner's acceptance of the real phone in place of the latest-API emulator and of the API 28 dialog gap.

## Effort reconciliation
| Tech section 12 line | Tech pw | Tasks | Task days |
|---|---|---|---|
| Spike | 0.15 | T01 M | 0.5 |
| `ExportBridge.kt`, `MainActivity`, manifest | 0.3 | T05 M, T06 M, T07 M, T09 S | 1.75 |
| `checkMergedManifest` | 0.05 | T04 S | 0.25 |
| Domain, data, DI, sweeps, static tests | 0.15 | T03 S, T10 M, T15 S | 1.0 |
| `ExportController` + unit tests | 0.2 | T12 M, T13 M | 1.0 |
| Impeccable pass, panel, result screen, widget tests | 0.25 | T17 M, T18 M, T19 M, T20 M | 2.0 |
| Drive targets, CI, checklist, real device | 0.3 | T11 M, T22 M, T23 M | 1.5 |
| English ARB | 0.05 | T16 S | 0.25 |
| Shoulds (save-as, Open, confirm, hint) | 0.2 | T08 S, T14 S (confirm and hint inside T13/T18) | 0.5 |
| **Total** | **1.65 pw ≈ 8.25 d** | 21 counted tasks | **8.75 d ≈ 1.75 pw** |

The task total is 0.5 d above tech, inside tech's 1.4–2.0 pw range, from rounding to S/M/L and the separate spike and privacy tasks. Not counted: T02 (Product Owner time), T21 translations (FEAT-019), store disclosure and Data safety work (PRD OQ-10), FEAT-006, and the Product Owner's design time. Cut order if effort grows (PRD OQ-6): FR-21, FR-23, FR-15 (T14), FR-10 (T08).

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T18, T19, T20 | |
| FR-2 | T06, T07, T12, T13 | Dart check plus Kotlin length re-check |
| FR-3 | T06, T07, T08, T10, T11, T15 | SHA-256 in T11; codec ban in T15 |
| FR-4 | T03, T11 | |
| FR-5 | T01, T06, T07, T10, T11 | H5 checked in T01 and T11 |
| FR-6 | T01, T06, T11 | H1 in T01 |
| FR-7 | T01, T07, T11 | |
| FR-8 | T04, T07, T09, T15 | Implicit READ on API 28 is residual R2 |
| FR-9 | T07, T12, T18, T23 | Live dialog rows: Open items 6 |
| FR-10 | T08, T13, T18, T23 | Should; after API 28 refusal only (OQ-T2) |
| FR-11 | T06, T07, T12, T16, T18 | |
| FR-12 | T11, T12, T18 | |
| FR-13 | T01, T06, T07, T11, T12 | API 29+ system rename: Open items 3 |
| FR-14 | T06, T07, T08, T12, T22 | Low space in CI only |
| FR-15 | T02, T05, T14, T18, T23 | Should; code gated by T02 |
| FR-16 | T01, T09, T10, T11, T22 | |
| FR-17 | T05, T13, T23 | OEM exclusion is R4 |
| FR-18 | T04, T05, T11 | |
| FR-19 | T13, T18 | |
| FR-20 | T05, T13, T18 | |
| FR-21 | T16, T18, T23 | Should |
| FR-22 | T13, T19, T23 | |
| FR-23 | T13, T19 | Should |
| FR-24 | T12, T13, T19 | |
| FR-25 | T12, T13, T19, T23 | |
| FR-26 | T16, T18 | Final copy belongs to FEAT-016 |
| FR-27 | T02, T03, T05, T10, T14, T15, T23 | |
| FR-28 | T10, T11, T15 | |
| FR-29 | T19 | Stand-in deleted |
| FR-30 | T16, T20, T21 | `AI-reviewed only` |
| NFR-1 | T06, T12, T22 | Measured on CI API 28 and the real phone |
| NFR-2 | T18, T20, T23 | |
| NFR-3 | T11, T15, T23 | |
| NFR-4 | T16, T20, T21 | |
| NFR-5 | T03, T04, T15 | |
| NFR-6 | T06, T07, T22 | |
| NFR-7 | T01, T11, T22, T23 | Real phone replaces the latest-API emulator |
| NFR-8 | T04, T23 | Evidence only; PRD OQ-10 review is outside code |
| NFR-9 | T10, T12, T13 | |

**Not covered by a task:**
- PRD OQ-10 compliance review, Play permission disclosure and Data safety answers (NFR-8) are release work for the Product Owner and whoever handles store compliance.
- API 28 live permission dialog (AC-2.1, AC-2.2 auto-continue after Allow, AC-2.3 deny tap): no device in this plan (Open items 6).
- Receiving-app behaviour after the user leaves (H4, PRD OQ-8) is accepted residual risk, not tested.

## Open items
1. **`OPEN_NO_VIEWER`** (tech OQ-T4) is not in the PRD code list; T02 asks the Product Owner for PRD 1.1. T14 depends on it.
2. **Sweep log lines:** tech 4.4 logs `sweep=done` / `sweep=skipped`; PRD FR-27 allows only the section 5 outcome codes. T09 follows the PRD and logs nothing. The Product Owner may add the codes in the T02 edit.
3. **FR-4/FR-5/FR-13 versus the API 29+ conflict rename:** tech relies on MediaStore renaming a taken name (for example `exactsize-300x300-[TOKEN] (1).jpg`) instead of drawing a new TOKEN, so the stored name would not match the FR-4 regex. PRD section 9 allows a read-back system rename; FR-5 and FR-13 read stricter. Odds are 1 in 36^6 per name (tech R11). Not resolved here.
4. **PRD OQ-2, OQ-4–OQ-9 are not ticked** in the Approved PRD; tasks use their defaults, as tech did. G1 (T17) asks for the UI ones.
5. **NFR-1 and the PRD "Fast" metric** name the 2 GB emulator profile; this plan measures on CI API 28 and the Realme 2 Pro (T22), informational.
6. **Devices:** NFR-7 and the Phase A exit name "API 28 and latest emulators", and tech section 8 plans a manual checklist on an API 28 Google Play image. This plan uses the Realme 2 Pro (API 36) for latest, as FEAT-005 G3 did, and has no device for the API 28 permission dialog rows. The Product Owner decides at G3: create a local API 28 AVD for one manual pass, or accept the gap.
7. **Real-phone privacy:** test files land in the Product Owner's gallery and may be picked up by cloud backup (Real-phone data rule above). The optional chat-app check in T23 sends a synthetic image through the Product Owner's own account.
8. **Product Owner follow-ups, not tasks:** ADR-001 clarification line pointing to ADR-006/ADR-007 (tech OQ-T1); roadmap effort 0.5 pw → about 1.75 pw and the soft FEAT-006 dependency (OQ-T6); FEAT-006's PRD dependency line saying it embeds `ExportPanel(success:, size:)` and calls `ExportController.leave()` (tech 4.5).

## Test record
_Filled in by T01, T06–T08, T11, T19, T20, T22 and T23 (one row per check and device: date, device or CI run, result). Synthetic images only. No file names, URIs, paths, sizes or EXIF values in rows or screenshot captions; use `[PLACEHOLDER]` for anything sensitive._

| Date | Task | Check | Device / run | Result |
|---|---|---|---|---|

## Instructions for Claude Code
- Read `prd.md`, `tech.md`, ADR-007, ADR-006 and ADR-001 before starting a task.
- Implement only the current task, in order; tick its checkbox and add a line to `docs/CHANGELOG.md` when done.
- Gates: no manifest or Kotlin work (T04–T09) before G0; no visible UI work (T18–T20) before G1; T21 only after G2; T14 only after T02; stop at every failing gate and report to the Product Owner.
- UI rule: before designing or building any real UI screen, stop and tell the Product Owner (impeccable, decision 2026-11-20). T17 is that stop. impeccable runs lean: no image comps, no reviewer subagents, one round, one screenshot per key state.
- Do not change FEAT-001, FEAT-002 or FEAT-004 code beyond what a task names (`MainActivity.kt` wiring, `app_flow.dart`, `main.dart`, `target_flow.dart`, the T11 test in `app_flow_test.dart`). If a task seems to need more, stop and propose a change request.
- Device tests under `flutter drive` use `testWidgets` only; every new drive target gets a line in `.github/workflows/ci.yml`. Local runs use the Realme 2 Pro; API 28 runs in CI.
- Translations only through `/l10n-translate <lang>` typed by the Product Owner, status `AI-reviewed only`.
- If a requirement is unclear or wrong, stop and propose a PRD change.
- Privacy: synthetic test images only, never real faces, signatures or documents. Never log or put in crash reports, test records or PR text any image content, file name, URI, path, size, EXIF value or platform exception text. No persistence, `restorationId` or clipboard writes. No network calls. Any sensitive value is `[PLACEHOLDER]`.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-24 | First draft |
| 1.0 | 2026-11-24 | Approved by Product Owner |
