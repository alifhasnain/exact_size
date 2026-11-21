---
id: FEAT-001-T01-RECORD
title: FEAT-001-T01 spike — gate G1 decision record (partial)
status: Proposed
version: 0.1
updated: 2026-11-21
links: [FEAT-001-TASKS, FEAT-001-TECH, ADR-006]
---

# Gate G1 — partial record

The spike code is kept on the local branch `spike/feat-001-t01` (throwaway). It contains a minimal Kotlin bridge in `MainActivity`, a FileProvider for `cache/camera/`, a share trampoline activity and a debug page (`integration_test/pick_spike_demo.dart`). Tests used one synthetic image, the arrow pattern from `test_support/crop_fixtures`. No URIs, paths or file names are recorded here.

| Item | API 36.1 emulator (Google Play image, 2 GB) | API 28 AOSP | API 28 Google Play |
|---|---|---|---|
| (a) Gallery opens the photo picker, images only, one selection, no permission prompt | **Pass.** `isPhotoPickerAvailable` is true and the intent action is `PICK_IMAGES`; no prompt. The picker shows its own "only the photos you select" banner, and a selection needs a tap on **Done** | Not run: system image not installed | Not run: system image not installed |
| (b) `onActivityResult` before `onResume`; under "Don't keep activities"; slot survives engine recreation | **Pass on normal return**: `onActivityResult` ran about 130–330 ms before `onResume`. Under "Don't keep activities" the activity was not destroyed, because the picker is a translucent bottom sheet, so recreation was not exercised. After a forced process kill during the picker the emulator stopped responding, so the result is inconclusive | — | — |
| (c) Grant opens in `SourceProbe`'s worker isolate, also after recreation | **Pass** without recreation (probe OK, 80×120 JPEG). After recreation: not exercised (see b) | — | — |
| (d) Camera writes a full-size file through the FileProvider `EXTRA_OUTPUT` URI | **Not verifiable here**: opening the camera app froze the emulator twice (virtual-scene camera and emulated camera, software GL, 2 GB). This is an environment limit, not a result | — | — |
| (e) Resolved AndroidX versions | `androidx.activity:activity` **1.10.1**, `androidx.core:core` **1.16.0** (`releaseRuntimeClasspath`; no other module raises them) | same build | same build |
| (f) Descriptor type (`statSize`) per provider | MediaStore item through the photo picker: a real file descriptor; `statSize` equals the file length | — | — |
| (g) Launcher icon during the camera keeps the camera on top (`singleTop`) | Not verifiable (camera freezes the emulator, see d) | — | — |
| (h) Share trampoline lands in the existing task with a usable grant | Not run (emulator hung before this step) | — | — |

**Debug-build note:** the debug manifest requests `INTERNET`, which is added by Flutter for debugging. The FR-18 no-permission check (T09) runs on the release merged manifest.

**Status:** G1 is not passed. (a), (c) for a normal return, (e) and (f) pass on API 36.1. (b) and (c) after recreation, (d), (g) and (h) need a device that can run the camera app and survive a process kill. All three items on both API 28 images also still need running.
