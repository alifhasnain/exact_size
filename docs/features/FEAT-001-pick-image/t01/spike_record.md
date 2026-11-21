---
id: FEAT-001-T01-RECORD
title: FEAT-001-T01 spike — gate G1 decision record
status: Proposed
version: 0.2
updated: 2026-11-21
links: [FEAT-001-TASKS, FEAT-001-TECH, ADR-006]
---

# Gate G1 — decision record

The spike code is kept on the local branch `spike/feat-001-t01` (throwaway). It contains:
- a minimal Kotlin bridge in `MainActivity`;
- a FileProvider for `cache/camera/`;
- a share trampoline activity;
- a duplicate-launcher guard;
- a debug page (`integration_test/pick_spike_demo.dart`).

The gallery and share checks used one synthetic image, the arrow pattern. The camera check took one real photo, which was stored in the app's private cache and deleted when the app was uninstalled. No URIs, paths or file names are recorded here.

After the run the spike app and the test image were removed from the phone. The picker screenshot, which showed the owner's own gallery, was deleted at once, and no picker screenshot was kept.

Devices:
- **Emulator:** Medium_Phone_API_36.1, Google Play image, 2 GB.
- **Phone:** Samsung S23 Ultra, Android API 37 (Samsung camera app, Lawnchair launcher).

| Item | API 36.1 emulator | Phone (API 37) | API 28 (AOSP and Google Play) |
|---|---|---|---|
| (a) Gallery: photo picker, images only, one selection, no permission prompt | **Pass.** `PICK_IMAGES`, no prompt; a selection needs a tap on **Done** | **Pass.** Same; the picker is the Google Photos-branded system picker | Not run: no system image installed |
| (b) `onActivityResult` before `onResume`; result survives recreation and process death | **Pass** on a normal return. The picker is a translucent sheet, so "Don't keep activities" did not destroy the activity | **Pass.** The app process was killed while the camera was in front. On return: `onCreate` with the restored marker, then `configureFlutterEngine`, then `onActivityResult`, then `onResume`; Dart read the slot after the restart. A forced kill while the gallery sheet is open closes the sheet too: not a real low-memory case, because the app stays visible behind the sheet | — |
| (c) Grant opens in `SourceProbe`'s worker isolate, also after recreation | **Pass** (probe OK, 80×120 JPEG) | **Pass**, including the camera result after the process restart (probe OK, 4000×3000 JPEG) | — |
| (d) Camera writes a full-size file through the FileProvider `EXTRA_OUTPUT` URI | **Not verifiable**: opening the camera app froze the emulator twice (software GL) | **Pass.** 4000×3000 JPEG of about 1.1 MB, not a thumbnail | — |
| (e) Resolved AndroidX versions | `androidx.activity:activity` **1.10.1**, `androidx.core:core` **1.16.0** | same build | — |
| (f) Descriptor type per provider | MediaStore item through the photo picker: a real file descriptor; `statSize` equals the length | Same for the photo picker and for the My Files share | — |
| (g) Launcher icon during the camera keeps the camera on top | Not verifiable (camera freezes the emulator) | **Fails without a guard:** a second `MainActivity`, with its own Flutter engine, opens on top of the camera; Back returns to the camera and the result still arrives. **Passes with a guard**: `!isTaskRoot` plus a MAIN/LAUNCHER intent finishes the new instance in `onCreate`, and the camera stays on top | — |
| (h) Share trampoline lands in the app's own task with a usable grant | Not run | **Pass**, cold and warm. A share from My Files went through the trampoline (the task root) into `MainActivity` in its own task, using the forwarded read grant, and the probe was OK. The warm share reused the same instance (`onNewIntent` path, no duplicate) | — |

## Findings for the build tasks
1. **Duplicate-launcher guard (g):** T10 adds it to `MainActivity`. It keeps ADR-006 Option B and only adds to `onCreate`. It needs the Product Owner's confirmation, because the gate treats a (g) failure as a stop.
2. **Shell share testing:** `adb shell am start … --grant-read-uri-permission` cannot grant a MediaStore URI, because the shell lacks the permission (SecurityException). T25 needs another source for automated share tests, for example a small test-only sender app, a FileProvider URI from the test itself, or a manual check. In the spike, forwarding a URI the app had no grant for crashed the trampoline. Production code must catch that and refuse it as `SOURCE_UNAVAILABLE`.
3. **Done tap:** the system picker needs a tap on Done even for a single selection. That is the system's UI and nothing to fix, but it costs one extra tap against the PRD's "one tap" wording.
4. **Process death with the gallery sheet open** is not a realistic low-memory case (the app stays visible). FR-17 is mainly about the camera, which passes.
5. **Camera on the emulator:** the camera app freezes the local 2 GB emulator. Camera integration checks (T15, T19) need the phone or CI.

**Status:** G1 passes on the API 36.1 emulator and the API 37 phone, with the guard in finding 1. The API 28 column is not run (no system image installed locally).
