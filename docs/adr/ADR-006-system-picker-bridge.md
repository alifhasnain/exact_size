---
id: ADR-006
title: System picker and camera bridge — small Kotlin activity-result bridge in MainActivity over a MethodChannel
status: Proposed
version: 0.1
updated: 2026-11-21
links: [FEAT-001, FEAT-001-TECH, ADR-001, FEAT-002]
---

# ADR-006 — System picker and camera bridge

Format: lightweight [MADR](https://adr.github.io/madr/).

## Context
FEAT-001 (Approved v1.0) must open the system photo picker (document picker as fallback), the document picker ("Choose from files", Should) and the system camera intent writing into an app-private file, then get the result back into Dart. The Product Owner decided OQ-1 and OQ-2: no runtime permission, no in-app gallery or camera [Fact](FEAT-001 prd.md section 12).

Constraints from the PRD:
- **FR-8 / FEAT-002 OQ-3:** hand over the picked `content://` URI, no copy into app storage, no display-name query.
- **FR-4 / AC-6.4:** the camera file lives in `<cache>/camera/`, exposed by a non-exported FileProvider limited to that folder.
- **FR-15 / AC-5.1:** the result is delivered exactly once even if the activity is recreated. Under "Don't keep activities" a plain `FlutterActivity` destroys its Flutter engine with the activity, so the Dart isolate that launched the picker is gone when the result comes back [Hypothesis: default `FlutterActivity` engine ownership; verify in spike FEAT-001-T01].
- **FR-17 (Should):** recover a camera capture after process death; the only state kept is a marker with a random file name.
- **FR-18:** no CAMERA or media permission in the merged manifest.

ADR-001 chose JNIgen for Android API calls and rejected "a Kotlin platform-channel plugin", and FEAT-002-TECH section 11 left out "a custom MainActivity" [Fact](ADR-001 sub-decisions; FEAT-002 tech.md section 11). JNIgen can *start* an activity from Dart, but a result arrives in `Activity.onActivityResult`, which only Java/Kotlin code inside the activity (or a registered plugin listener) receives. After process death or engine recreation that callback runs before any Dart code exists, so it must be buffered on the native side.

## Decision drivers
- No copy (FR-8) and a FileProvider scoped to `camera/` only (AC-6.4).
- Exactly-once delivery across activity recreation and process death (FR-15, FR-17).
- No permission, no new Dart dependency that could add one (FR-18).
- Photo picker on API 28–32 through the AndroidX contract and its Play services backport (FR-2, FR-3, NFR-7).
- Solo developer: smallest amount of native code; keep ADR-001's "JNIgen first" spirit where it works.
- Enum-only logging; platform exception text never reaches logs (FR-19).

## Options considered
### Option A — `package:image_picker` (or `file_picker`)
- Good: ready-made, maintained by the Flutter team; camera and gallery in two calls; has `retrieveLostData()` for process death on Android.
- Bad: [Hypothesis, not re-verified: no web access in this session] `image_picker_android` copies a gallery pick into the app cache and returns a file path (`XFile.path`), which breaks FR-8 and the `content://` hand-off contract with FEAT-002. Its own FileProvider path config is broader than `camera/` [Hypothesis], which breaks AC-6.4. Lost-data recovery stores paths in SharedPreferences [Hypothesis], more than FR-17's single random-name marker. Older plugin versions use `ACTION_GET_CONTENT` instead of the photo picker below API 33 unless a flag is set [Hypothesis]. `file_picker` also caches picked files by default [Hypothesis]. Behaviour can change on any plugin update, outside our control.

### Option B — Small Kotlin bridge in `MainActivity` over one `MethodChannel` (recommended)
`MainActivity` stays a `FlutterActivity` (no base-class change). It builds intents with the AndroidX contracts (`ActivityResultContracts.PickVisualMedia().createIntent(...)` with `ImageOnly`, `PickVisualMedia.isPhotoPickerAvailable(context)`), falls back to `ACTION_OPEN_DOCUMENT`, launches with `startActivityForResult`, and parses results in `onActivityResult`. One pending-result slot is kept natively; Dart pulls it (`takeResult`, which clears it) at start-up and whenever the bridge signals `resultReady`. The camera marker (random file name) and the "launch outstanding" flag live in the activity's saved-instance-state `Bundle`. A share target (FR-20, Should) uses a tiny no-UI trampoline activity that forwards to `MainActivity`.
- Good: hands over the provider's `content://` URI unchanged, no copy, no metadata query. FileProvider is ours and scoped to `camera/`. One delivery path (pull) for warm, recreated and cold cases, so exactly-once is one native slot cleared on read. Uses the platform's own photo-picker availability logic, including the Play services backport [Hypothesis: AndroidX `activity` ≥ 1.7 behaviour; spike]. No new Dart dependency; two AndroidX Gradle artefacts that the Flutter embedding probably already pulls in transitively [Hypothesis]. Kotlin code ~150–200 lines, all strings and enums over the channel, no pixel data (ADR-003 untouched).
- Bad: hand-written Kotlin that ADR-001 tried to avoid; a custom `MainActivity` (FEAT-002-TECH section 11 said none). Channel contract is untyped (maps of strings) and must be guarded by a Dart wrapper and tests. Native code must be tested on emulators, not in `flutter test`.

### Option C — JNIgen only (Dart starts the intent, Dart-implemented Java listener receives the result)
- Good: no Kotlin source; consistent with ADR-001.
- Bad: there is no Dart-reachable registration point for activity results without a Flutter plugin's `ActivityPluginBinding` [Hypothesis: `jni_flutter` 1.1.0 exposes the activity but not result listeners]. After process death or engine recreation the result arrives before Dart runs, so a Dart-implemented listener cannot exist yet: FR-15 under "Don't keep activities" and FR-17 fail. Needs Kotlin anyway for buffering, so it ends up as Option B plus JNIgen complexity.

### Option D — Same as B, packaged as a local Flutter plugin (`packages/es_picker`, `ActivityAware`)
- Good: `MainActivity` stays untouched; plugin listeners exist for activity results, new intents and saved state.
- Bad: an extra Gradle module, plugin pubspec and registration for the same code; ordering of plugin attach versus result delivery after recreation needs extra verification. Worth it only if the code is reused or iOS is added; neither is planned.

## Decision
Recommend **Option B**. It is the only option that meets FR-8 and AC-6.4 without fighting a plugin, and the pull-based slot gives exactly-once delivery for warm, recreated and cold starts with one code path. It is a scoped exception to ADR-001's "no Kotlin plugin": Kotlin is used only for activity-result plumbing that Dart cannot receive; all image work stays in Dart, JNIgen and C. Option D is the fallback if `MainActivity` grows beyond this bridge. Final once the Product Owner approves.

Proposed pins (Gradle, `android/app/build.gradle.kts`), exact versions:
- `androidx.activity:activity:1.10.1` (`PickVisualMedia`, `isPhotoPickerAvailable`)
- `androidx.core:core:1.16.0` (`FileProvider`, `IntentCompat`)

[Hypothesis] Both are stable releases known before this session; Flutter 3.50.1's embedding may already resolve newer versions transitively, in which case Gradle picks the higher one. Spike FEAT-001-T01 runs `gradlew :app:dependencies`, records the resolved versions and updates these pins to match. No Dart dependency is added.

## Consequences
- Easier: full control of the no-copy, FileProvider scope, marker and logging rules; no third-party behaviour drift; result recovery after recreation works by construction.
- Harder: Kotlin source in `android/app/src/main/kotlin/` to maintain and review; emulator-only tests for the bridge; `MainActivity` is no longer a plain `FlutterActivity`.
- ADR-001 says "no hand-written bindings or Kotlin plugin" (Consequences) and FEAT-002-TECH section 11 lists "a custom MainActivity" as left out. If this ADR is approved, the Product Owner decides whether ADR-001 gets a clarification line pointing here (ADR-001 is Approved; editing it sets it to Under Discussion). This ADR does not supersede ADR-001.
- Follow-up: spike FEAT-001-T01 verifies the [Hypothesis] items above (photo picker availability on API 28 with and without Play services and on API 36, result ordering after process death, engine lifetime under "Don't keep activities", URI grant validity, share task behaviour).

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-21 | First draft |
