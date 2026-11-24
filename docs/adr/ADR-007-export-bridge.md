---
id: ADR-007
title: Export bridge — small Kotlin class on its own MethodChannel for MediaStore, API 28 permission, save-as and share
status: Approved
version: 1.0
updated: 2026-11-24
links: [FEAT-007, FEAT-007-TECH, ADR-001, ADR-006, FEAT-001]
---

# ADR-007 — Export bridge

Format: lightweight [MADR](https://adr.github.io/madr/).

## Context
FEAT-007 (Approved v1.0) must take FEAT-004's app-private temp file out of the app in two ways [Fact](docs/features/FEAT-007-export-share/prd.md):
- **Save:** on API 29+, through MediaStore into `Pictures/ExactSize`, with the item kept pending until the bytes are verified (FR-6). On API 28, by writing a hidden `.part` file, renaming it without overwriting and requesting a media scan (FR-7). On API 28 this needs `WRITE_EXTERNAL_STORAGE` capped at 28, requested only when the user taps Save (PRD OQ-1 = A, decided 2026-11-24). The system save-as dialog is the fallback (FR-10).
- **Share:** the system chooser with one read-only file whose display name is the FR-4 name. The FileProvider must not be exported, must be scoped to one folder and must be separate from the camera provider. ExactSize must be excluded from the chooser (FR-17, FR-18).
- **Start-up sweep:** remove only the app's own incomplete items (FR-16). Logs hold enum codes only (FR-27). There is no network (FR-28). The merged-manifest check must keep its guarantees (FR-8).

ADR-001 names JNIgen for "MediaStore" calls and rejects a Kotlin plugin [Fact](ADR-001, Option A and sub-decisions). ADR-006 made a scoped exception: Kotlin in `MainActivity` for activity results, because Dart cannot receive `onActivityResult` [Fact](ADR-006, Decision). FEAT-007 has the same problem twice: the API 28 permission result arrives in `onRequestPermissionsResult`, and the save-as result in `onActivityResult`. The release build already fails on banned permissions or a widened camera provider [Fact](android/app/build.gradle.kts, `CheckMergedManifest`), and any plugin that adds manifest entries would trip or have to extend it.

## Decision drivers
- No overwrite, no visible partial file, and a sweep of only our own pending or `.part` items (FR-6, FR-7, FR-13, FR-16, NFR-6).
- The API 28 permission is requested inside the Save tap, once per tap, with no loop on "don't ask again" (FR-7, FR-9).
- A separate, non-exported share FileProvider scoped to one folder, and the FR-4 display name (FR-5, FR-18).
- No new permission, provider or exported component from a dependency (FR-8; `checkMergedManifest`).
- Enum-only results; platform exception text never crosses into Dart or logs (FR-27).
- Solo developer: the least native code, reusing the ADR-006 pattern the project already tests.
- Testable with fakes behind one Dart interface (NFR-9).

## Options considered
### Option A — Extend the ADR-006 approach: `ExportBridge.kt` on channel `exactsize/export`, set up by `MainActivity` (recommended)
A plain Kotlin class (about 250–300 lines [Assumption]) created in `MainActivity.configureFlutterEngine`. `MainActivity` passes it `onActivityResult(REQUEST_SAVE_AS)` and `onRequestPermissionsResult`. It handles `save`, `saveAs`, `itemExists`, `open`, `share` and `sweepIncomplete`. All I/O runs on one single-thread executor and results are posted back on the main thread. A new FileProvider authority `.share` is scoped to `cache/exactsize_share/`.
- Good: full control over the pending flag, the `.part` and no-overwrite rename, the owner-filtered sweep, the share folder scope and the chooser's exclusion list. It adds no Gradle or Dart dependency (`androidx.core` FileProvider is already pinned by ADR-006). The permission and save-as callbacks arrive where the code is. It uses the same enum-only, catch-all, no-`Log` rules and grep tests as the picker bridge. Keeping it in its own class and channel stops `MainActivity` from growing (ADR-006 named that as the trigger for its Option D).
- Bad: more hand-written Kotlin against ADR-001's "JNIgen first". Its behaviour per API level is only testable on emulators and devices. The channel contract is untyped maps and needs a Dart wrapper and tests.

### Option B — JNIgen from Dart (MediaStore, `ContentResolver`, chooser), with Kotlin only for the callbacks
- Good: closest to ADR-001; FEAT-002 already has JNIgen `ContentResolver` bindings [Fact](docs/features/FEAT-001-pick-image/tech.md, Integrations: `SourceProbe` via JNIgen `ContentResolver`).
- Bad: the permission result and the save-as result still need Kotlin in the activity (the same reason ADR-006 rejected its Option C), so this ends up as two mechanisms for one feature. A chunked copy over JNI crosses the boundary once per chunk, or needs a Java helper anyway. More generated bindings (`MediaStore`, `ContentValues`, `MediaScannerConnection`, `Files`) to regenerate and tree-shake. Error handling has to filter Java exception text on the Dart side.

### Option C — Pub plugins: `share_plus` + a gallery saver (`gal` or similar) + `permission_handler` (+ `file_picker` for save-as)
- Good: little code to write; maintained packages.
- Bad: [Hypothesis, not re-verified in this session] `share_plus` adds its own FileProvider and path config and copies files into its own cache folder, which is a third provider that `checkMergedManifest` must allow and that FR-18 does not describe. Gallery savers declare their own storage permissions, possibly with different `maxSdkVersion` caps, and their pending or temp naming is not ours, so the FR-16 sweep cannot target only our items. The display name and the conflict behaviour are the plugin's choice. Plugin exceptions can carry paths into logs. Three or four dependencies can change on any update, and the merged-manifest check would fail or have to be loosened.

### Option D — Same code as A, packaged as a local Flutter plugin (`packages/es_export`, `ActivityAware`)
- Good: `MainActivity` stays untouched; plugin bindings give activity-result and permission listeners.
- Bad: an extra Gradle module, pubspec and registration for the same code; the ADR-006 picker bridge would stay in `MainActivity`, so the project would have two styles. Worth it only if iOS or reuse comes; neither is planned.

## Decision
Recommend **Option A**. It is the only option that meets FR-6, FR-7, FR-13, FR-16 and FR-18 exactly without fighting a dependency's manifest entries or naming. It keeps the merged-manifest check strict, and it reuses a pattern the project already builds, tests and reviews. It is a second scoped exception to ADR-001: Kotlin only for shared-storage writes, the API 28 permission and the system intents. The FR-4 name, the checks, the retries, the idempotent Save and the flow end stay in pure Dart. Option D is the fallback if the bridges grow further. Final once the Product Owner approves.

## Consequences
- Easier: precise control of no-overwrite, pending and sweep rules; no third-party drift; the build check can now also require that every FileProvider in the merged manifest is one of our two authorities.
- Harder: about 300 more lines of Kotlin to maintain, with emulator-only tests (API 28 in CI, API 36 locally) and a scripted manual checklist for system dialogs.
- ADR-001 (Approved) still says MediaStore through JNIgen and "no Kotlin plugin". If this ADR is approved, the Product Owner decides whether ADR-001 gets one clarification line pointing to ADR-006 and ADR-007 (editing it sets it to Under Discussion until re-approved). This ADR does not supersede ADR-001 or ADR-006.
- Follow-up: spike FEAT-007-T01 verifies the [Hypothesis] items in FEAT-007-TECH (pending visibility, conflict rename, owner-filtered pending query, implicit READ on API 28, FileProvider display name, chooser exclusion, scan timing, the save-as orphan document).

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-24 | First draft |
| 1.0 | 2026-11-24 | Approved by Product Owner |
