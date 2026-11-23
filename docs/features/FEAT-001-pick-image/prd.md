---
id: FEAT-001
title: Pick image from camera or gallery
status: Implemented
version: 1.1
updated: 2026-11-23
links: [ROADMAP, BRIEF, RESEARCH, ADR-001, FEAT-002, FEAT-004, FEAT-005, FEAT-007, FEAT-011, FEAT-016, FEAT-018, FEAT-019, FEAT-022, FEAT-025]
---

# FEAT-001 — Pick image from camera or gallery

## 1. Overview
FEAT-001 is the entry point of every flow. The user taps **Take a photo** or **Choose from gallery**, the Android system UI does the work, and ExactSize gets one image. It then calls FEAT-002's `SourceProbe` straight away (FEAT-002 OQ-11), so unsupported, corrupt, too-large or unreadable files are refused on the pick screen and never reach the crop screen. Android only (minimum API 28), Flutter, fully on-device.

**Design stance (proposed, see OQ-1 and OQ-2).** ExactSize asks for **no runtime permission** to pick an image. Gallery uses the system photo picker (with the document picker as fallback). Camera uses the system camera app through an intent that writes into an app-private file. There is no in-app gallery and no in-app camera.

**Release:** MVP (R1 Phase A), Must, roadmap effort 0.5 pw, RICE 60000 [Fact](docs/roadmap.md). The scope below probably exceeds 0.5 pw, as happened to FEAT-002 (1.3 to 4.7 pw at Stage 6). [Assumption] about 0.8–1.2 pw for the Musts and +0.3 pw for the Shoulds; Stage 6 re-estimates.

**Hand-off contract to FEAT-002 (matches FEAT-002 FR-1, FR-2, OQ-3, OQ-11, section 8 and edge case "Camera temp file")**
| Item | Contract |
|---|---|
| Handle | `SourceHandle`: a read-only `content://` URI kept in memory. **No copy** into app storage (FEAT-002 OQ-3). `file://` is never accepted. |
| Info | `SourceInfo` returned by `SourceProbe.probe` (rawW, rawH, mime, exifOrientation, isAnimated, hasAlpha, decodePath). FEAT-001 never decodes pixels. |
| Origin | Enum `camera`, `gallery`, `files`, `share`. Used only to decide temp-file lifetime. Never logged or persisted. |
| Failure | `Err(Reason)` with the FEAT-002 codes `UNSUPPORTED_INPUT`, `CORRUPT_INPUT`, `IMAGE_TOO_LARGE`, `SOURCE_UNAVAILABLE`. No handle is handed over. |
| Metadata | No file name, path or EXIF value is read or passed on. |
| Lifetime | The handle stays valid for the flow session. FEAT-001 owns the camera temp file until the session ends (FR-11); FEAT-002 only reads. |

## 2. Problem statement
Applicants on budget phones and cyber-café operators must get a photo or signature into the app fast; the R1 target is a median under 30 s from app open to export [Fact](docs/product/vision.md, success metrics). File hunting and permission screens cost time and trust. Photos and signatures are personal data, signatures are identity-sensitive, and students include minors [Fact](docs/product/vision.md, compliance scope).

Evidence is thin: `docs/research/competitors.md` has no finding on how rival tools pick images, ask for permissions, or handle cloud photos. The claims below about Android behaviour are [Hypothesis] taken from Android developer documentation and **not re-verified in this session**; Stage 6 must confirm each one.
- [Hypothesis] The system photo picker needs no storage permission, hands the app access to only the chosen item, and is available on Android 13+, on Android 11–12 through system updates, and on older versions through Google Play services. Where it is missing, the AndroidX contract falls back to the document picker (ACTION_OPEN_DOCUMENT). (Android docs, "Photo picker".)
- [Hypothesis] `ACTION_IMAGE_CAPTURE` needs no CAMERA permission, but if the merged manifest declares CAMERA the intent fails with a `SecurityException` unless the user granted it. A dependency can add that declaration silently, so the merged manifest must be checked (FR-18). (Android docs, "Camera intents".)
- [Hypothesis] The `image_picker` plugin copies the picked file into the app cache and returns a path. That would break the no-copy decision (OQ-3), so Stage 6 must check it or use a thin native layer.
- [Hypothesis] On 2 GB phones the system may kill a background app while the camera is open, so the result can arrive in a new process.
- [Assumption] Cyber-café operators receive customer photos through WhatsApp, USB drives and file managers, not only the gallery. No research confirms this (BRIEF persona only).

## 3. Goals & success metrics
> **Test environment:** as in FEAT-002 section 7 (Product Owner decision 2026-11-20): Android emulators with a 2 GB RAM profile on API 28 and on the latest API; no physical low-end phone. Timing targets are best effort and informational.

| Goal | Metric | Target |
|---|---|---|
| Fast start | Taps owned by FEAT-001 from pick screen to next step (excluding system picker or camera app) | 1 tap before the system UI, 0 after |
| Fast hand-off | Time from system UI returning to next screen, local 12 MP JPEG | ≤ 1 s median [Assumption] |
| No permission friction | Runtime permission prompts in all primary flows | 0 |
| Early refusal | Share of unsupported, corrupt, too-large and unreadable test files refused on the pick screen (never on the crop screen) | 100% |
| Reliability | Crashes or ANRs on the pick test set (section 9) | 0 |
| Privacy: no copy | Copies of gallery or files images in app storage after a pick | 0 |
| Privacy: camera file | Camera temp files in app storage after the session ends | 0; at most 1 at rest while a session is active (2 only briefly during a re-capture) |
| Privacy: logs | Content URIs, file names, paths or EXIF values in release logs and crash reports | 0 |
| Least privilege | Photo, camera or storage permissions contributed by this feature to the merged manifest | 0 |

**Non-goals (Won't in R1)**
- In-app camera or in-app gallery, and any CAMERA or READ_MEDIA permission (OQ-1, OQ-2).
- Multiple selection and batch (FEAT-022, Later).
- "Open with" (`ACTION_VIEW`) integration, recent or last-photo thumbnails, persisted URI permissions, drag and drop, clipboard paste.
- Decoding, previewing, cropping, resizing or compressing (FEAT-002, FEAT-004), stripping metadata (FEAT-018), saving or sharing output (FEAT-007).
- Saving the camera original to the gallery (OQ-5).
- Choosing the target W×H (FEAT-005, FEAT-011).

## 4. User stories
- **US-1** As an applicant, I want to choose a saved photo from my gallery in one tap, so that I can start without hunting for files.
  - **AC-1.1** Given the pick screen, when I tap "Choose from gallery", then the system photo chooser opens, shows images only (no videos), allows exactly one selection, and no permission prompt appears.
  - **AC-1.2** Given the chooser is open, when I select one photo, then it closes and the app moves on after the probe, with no extra preview or confirmation screen from FEAT-001.
  - **AC-1.3** Given the chooser is open, when I press back or close it, then I return to the pick screen with no message and nothing changed.
  - **AC-1.4** Given a device without the photo picker (for example API 28 without Google Play services), when I tap "Choose from gallery", then the document chooser opens filtered to images with single selection, and AC-1.2 and AC-1.3 still hold.
  - **AC-1.5** Given neither chooser can start (activity not found or disabled), when I tap "Choose from gallery", then I see "We couldn't open the photo chooser…" (section 8) and the camera button still works.

- **US-2** As an applicant with no saved photo, I want to take one with my camera, so that I can use a fresh selfie.
  - **AC-2.1** Given the pick screen and a camera app, when I tap "Take a photo", then the system camera opens in one tap and ExactSize shows no permission prompt.
  - **AC-2.2** Given I take and confirm a photo, when I return, then the result is the full-size file written by the camera app, never the small preview image returned in the result extras, stored only in ExactSize's private camera folder and not added to the gallery.
  - **AC-2.3** Given I cancel in the camera, when I return, then there is no message, no camera file remains and the state is unchanged.
  - **AC-2.4** Given the camera app reports success but the file is missing or empty, or returns only a preview image, when I return, then I see "The camera didn't return a photo. Please try again." and nothing is handed off.
  - **AC-2.5** Given no camera app can handle the request, when the pick screen shows, then "Take a photo" is disabled (not hidden) with a visible reason, "Choose from gallery" works, and TalkBack announces the button as unavailable with that reason.
  - **AC-2.6** Given free storage is too low to create the camera file, when I tap "Take a photo", then the camera does not open and I see the low-space message (section 8).

- **US-3** As a user with an unusable file, I want to be told at once and pick another, so that I never reach a crop screen that cannot work.
  - **AC-3.1** Given I picked a file, when `SourceProbe` returns `UNSUPPORTED_INPUT`, `CORRUPT_INPUT`, `IMAGE_TOO_LARGE` or `SOURCE_UNAVAILABLE`, then I stay on the pick screen, see the matching message (section 8), the crop screen is never shown, and nothing is handed off.
  - **AC-3.2** Given the refused file came from the camera, when the message shows, then its temp file has been deleted.
  - **AC-3.3** Given I already have a valid image in this session, when a new pick is refused or cancelled, then the earlier image stays valid and its camera file (if any) is kept.
  - **AC-3.4** Given a message is shown, when TalkBack is on, then it is announced without moving focus away from the buttons, carries an icon and text, and both entry buttons stay visible and usable.
  - **AC-3.5** Given the test set (HEIC the device cannot decode, truncated JPEG, zero-byte file, text file named `[PLACEHOLDER].jpg`, a video, a 250 MP image), when each is picked, then each is refused with the expected code and nothing crashes.

- **US-4** As a user whose photo is stored online (for example Google Photos), I want a clear result, so that I know what to do offline or on a slow connection.
  - **AC-4.1** Given a photo that is not stored on the phone and airplane mode, when I choose it, then I see the "couldn't open this photo" message with the online hint (section 8), and ExactSize itself made no network call.
  - **AC-4.2** Given opening takes longer than 500 ms, when the wait continues, then "Opening your photo…" with a Cancel button shows; Cancel returns me to the pick screen and a late result is discarded (no hand-off, no temp file).
  - **AC-4.3** Given I am online and choose an online-only photo, when the gallery app downloads it, then ExactSize behaves as for a local photo; the download is done by the gallery or cloud provider, not by ExactSize (privacy copy: section 10, FEAT-016).

- **US-5** As a user on a budget phone, I want my photo not to be lost when Android restarts the app, so that I don't redo the capture.
  - **AC-5.1** Given the activity is recreated while a system UI is open (rotation, or "Don't keep activities" on), when I return, then the result is delivered exactly once and the flow continues.
  - **AC-5.2 (Should)** Given Android killed the app while the camera was open, when I finish the capture, then the app restarts, recovers the capture and runs the probe; if it cannot recover it, I see "The photo was lost while the camera was open. Please take it again." and no camera file remains.
  - **AC-5.3** Given the process was killed at any other time, when the app starts, then it opens on the pick screen with no restored image or handle, and the camera folder has been swept.
  - **AC-5.4** Given I tap "Take a photo" or "Choose from gallery" twice quickly, when the system screen opens, then only one opens and one result is handled.

- **US-6** As a privacy-conscious user, I want ExactSize to touch only the photo I chose, so that nothing else on my phone is exposed.
  - **AC-6.1** Given any pick from gallery, files or share, when app-private storage and cache are listed afterwards, then no copy of the image exists.
  - **AC-6.2** Given an accepted camera capture, when the camera folder is listed, then it holds exactly one file; after the session ends, a cancel, a refusal or a new accepted pick, it holds zero (or the new file only).
  - **AC-6.3** Given a full session, when release logs and crash reports are read, then they contain no `content://` URI, file name, path, EXIF value or size tied to content, only enumerated outcome codes.
  - **AC-6.4** Given the merged release manifest, when it is inspected, then it contains no CAMERA, READ_EXTERNAL_STORAGE, READ_MEDIA_* or ACCESS_MEDIA_LOCATION permission contributed by this feature; the FileProvider is not exported and is limited to the camera folder.
  - **AC-6.5** Given airplane mode, when I pick a photo stored on the phone, then everything works.
  - **AC-6.6** Given any outcome, when the original gallery file is compared before and after, then it is byte-identical with the same modification time.

- **US-7** As a TalkBack user, or a speaker of Arabic, Hindi, Spanish, Portuguese or Indonesian, I want the pick screen to be usable and in my language, so that I can start on my own.
  - **AC-7.1** Given TalkBack is on, when I explore the pick screen, then the order is: Take a photo, Choose from gallery, (Choose from files), privacy line; each has a label and role; after I return from a system UI without picking, focus is back on the button I used.
  - **AC-7.2** Given the system font size is 200%, when the pick screen shows, then no label is clipped, buttons stay ≥ 48 dp high, and the screen scrolls if needed.
  - **AC-7.3** Given any of the 6 languages, when a label or message appears, then it comes from ARB strings with placeholders (no concatenation).
  - **AC-7.4** Given Arabic (RTL), when the pick screen opens, then the button order and text mirror, while the camera and gallery icons are not mirrored.

- **US-8 (Should)** As an operator, I want to share a photo from WhatsApp or a file manager straight into ExactSize, so that I skip the gallery.
  - **AC-8.1** Given a single image in another app, when I tap Share and choose ExactSize, then the app opens (cold or warm start) and proceeds exactly like a gallery pick, including the probe and messages.
  - **AC-8.2** Given the shared item is a `file://` URI, or a URI of ExactSize's own FileProvider, when it arrives, then it is refused with "We can't open that item. Choose a photo instead."
  - **AC-8.3** Given several images are shared at once, when the share sheet lists targets, then ExactSize is not offered (only single-image send is registered).
  - **AC-8.4** Given I am mid-flow (for example on the crop screen), when a share arrives, then the session is replaced per OQ-7, a running render is cancelled and the old camera file is deleted.
  - **AC-8.5** Given the sender's read grant has expired or is denied, when the probe runs, then I see the "couldn't open this photo" message.

- **US-9 (Should)** As an operator with photos on a USB drive, Downloads or cloud storage, I want to browse files, so that I can open images outside the gallery.
  - **AC-9.1** Given the pick screen, when I tap "Choose from files", then the document chooser opens filtered to images with single selection, and the result is handled exactly like a gallery pick.

## 5. User flows
**Main flow**
1. The pick screen shows the entry buttons. FEAT-001 checks that a camera app exists (FR-5).
2. User taps one entry. FEAT-001 opens the system UI (photo picker, or camera with a freshly created private file).
3. The user picks or captures; the system UI returns a `content://` URI (camera: the private file's URI).
4. FEAT-001 validates the scheme and, for the camera, that the file exists and is not empty (section 8).
5. FEAT-001 calls `SourceProbe.probe`. After 500 ms of waiting it shows progress with Cancel (FR-13).
6. On Ok it hands `PickedImage` (section 1) to the flow, which goes to the next step. The flow is photo first (OQ-4, decided 2026-11-22): the next step is the target step (FEAT-005 manual entry or FEAT-011 preset), then crop. The previous session image (and its camera file) is released only now.
7. On Err it shows the message on the pick screen, deletes any new camera file, keeps the previous image, and waits for another tap.

**Alternate flows**
- Cancel at the system UI: back to the pick screen, no message (FR-9).
- Photo picker missing: document picker opens instead; same result type (FR-3).
- Share target (Should): app opens with a URI; steps 4 to 7 follow.
- Process killed during camera: app restarts; recover if possible (Should) or show the lost-photo message; sweep.

**Error flows:** `UNSUPPORTED_INPUT`, `CORRUPT_INPUT`, `IMAGE_TOO_LARGE`, `SOURCE_UNAVAILABLE` (from the probe), plus FEAT-001-only states: picker unavailable, camera unavailable, camera returned nothing, low storage, capture lost, item not openable. No handle is handed over in any of them.

## 6. Functional requirements
| ID | Requirement | Story | Priority (MoSCoW) |
|---|---|---|---|
| FR-1 | The pick screen shall offer "Take a photo" and "Choose from gallery". Each opens its system UI in one tap, with no intermediate dialog or permission rationale. | US-1, US-2 | Must |
| FR-2 | Gallery shall use the Android system photo picker, images only, exactly one selection, with no storage permission requested. | US-1 | Must |
| FR-3 | If the photo picker is unavailable, gallery shall fall back to the document picker (`ACTION_OPEN_DOCUMENT`, `image/*`, single selection). If neither can start, the app shall show the picker-unavailable message and keep the camera usable. | US-1 | Must |
| FR-4 | Camera shall use the system camera intent with the output written to a new randomly named file in an app-private `camera` cache folder, exposed through a non-exported FileProvider limited to that folder. Only that full-size file is used. The preview image in the result extras is never used. Nothing is written to shared storage or the gallery. | US-2 | Must |
| FR-5 | Before showing the pick screen the app shall check that a camera app can handle the request; if not, "Take a photo" is disabled with a visible reason. Before launching the camera it shall create the file and, if that fails (for example no space), show the low-space message and not launch. | US-2 | Must |
| FR-6 | On camera success the app shall accept the result only if the file exists and is larger than 0 bytes. On cancel, or any other result, it shall delete the file. | US-2 | Must |
| FR-7 | Right after a pick or capture, the app shall call FEAT-002 `SourceProbe`. On Ok it shall hand `PickedImage` (section 1) to the flow. On Err it shall show the section 8 message on the pick screen and hand nothing over. | US-3 | Must |
| FR-8 | The app shall hand over a read-only `content://` URI and make no copy, re-encode or resize. It shall refuse any other scheme. It shall not query the file name or any metadata (no display-name query). | US-6 | Must |
| FR-9 | Cancelling a system UI (back, close, camera cancel) shall return to the pick screen with no message and no state change. | US-1, US-2 | Must |
| FR-10 | The flow shall hold one image at a time. The previous image and its camera file are released only after the new pick passes the probe; a refused or cancelled pick leaves the previous image valid. | US-3 | Must |
| FR-11 | Camera file lifetime (FEAT-001 owns it): deleted on probe refusal, cancel, replacement by a newly accepted pick, and when the flow controller ends the session (start-over or flow end). At most one camera file exists at rest. At every cold start the app shall sweep the camera folder (except a pending capture under FR-17). | US-6 | Must |
| FR-12 | When the app is closed by the user (activity finishing), the app shall make a best-effort delete of the camera file. | US-6 | Should |
| FR-13 | While opening or probing takes more than 500 ms, the app shall show "Opening your photo…" with a Cancel button. After Cancel, a late result is discarded: nothing handed off, no temp file. | US-4 | Must |
| FR-14 | The app shall map every read failure at pick time (`SecurityException`, I/O error, provider gone, offline cloud item) to `SOURCE_UNAVAILABLE` with the "couldn't open this photo" message. ExactSize shall make no network call itself. | US-4 | Must |
| FR-15 | The app shall deliver a pick or capture result exactly once even if the activity is recreated, and shall ignore a second launch while one system UI is open. | US-5 | Must |
| FR-16 | After process death, the app shall start on the pick screen with no restored image, handle or crop state. | US-5 | Must |
| FR-17 | The app shall recover a pending camera capture after process death. The only state kept is a marker holding a random file name. The marker is deleted on completion; if recovery fails, show the capture-lost message and delete the file. | US-5 | Should |
| FR-18 | This feature shall declare no CAMERA, READ_EXTERNAL_STORAGE, READ_MEDIA_* or ACCESS_MEDIA_LOCATION permission. It shall declare a `queries` entry for the camera intent and `uses-feature camera required=false`. A build check shall fail if the merged release manifest contains any of those permissions from any dependency. | US-6 | Must |
| FR-19 | Logging shall use only the shared enum-only wrapper. `SourceHandle.toString()` is redacted. Exception text from the platform is never logged or put in crash reports. | US-6 | Must |
| FR-20 | The app shall register as a share target for a single image (`ACTION_SEND`, `image/*` only). It shall accept only `content://` URIs that are not ExactSize's own FileProvider and shall then follow FR-7. It shall handle cold and warm start. | US-8 | Should |
| FR-21 | The pick screen shall offer "Choose from files", opening the document picker (images, single selection). | US-9 | Should |
| FR-22 | The pick screen shall show one short privacy line ("Your photos stay on your phone and are never uploaded."). The final copy and the explainer belong to FEAT-016. | US-6 | Should |

## 7. Non-functional requirements
> The Priority is the first word of each row (Must / Should).

| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | Must: from the system UI returning to the next screen ≤ 1 s median for a local 12 MP JPEG, and the progress indicator appears after 500 ms. Both [Assumption], best effort on the emulator. |
| NFR-2 | Reliability | Must: no crash or ANR across the section 9 test set, including cancel at each system UI, activity recreation, process kill, no camera app, corrupt, zero-byte, 250 MP, HEIC, video and RAW files, revoked grants and double taps. |
| NFR-3 | Offline / poor network | Must: every source stored on the phone works in airplane mode. FEAT-001 makes no network calls. Exception: online-only photos are fetched by the gallery or cloud provider, outside ExactSize's control. |
| NFR-4 | Accessibility | Must: TalkBack labels and order (AC-7.1), targets ≥ 48 dp, text to 200% without clipping, messages with icon and text and a polite announcement, disabled camera button explained in text, no information by colour alone. System picker and camera UIs follow Android's own accessibility. |
| NFR-5 | Localisation | Must: English, Spanish, Portuguese (Brazil), Hindi, Indonesian, Arabic, all via ARB; Arabic RTL (mirrored layout, unmirrored icons). Translations follow the AI-only review workflow (FEAT-019). Picker and camera UIs use the system language and are not ours to translate. |
| NFR-6 | Privacy & security | Must: no copy of picked images, FileProvider not exported and scoped to the camera folder, no permissions (FR-18), enum-only logs, sources treated as untrusted input (scheme and own-authority checks, no trust in the intent's MIME type). See section 10. |
| NFR-7 | Compatibility | Must: Android 9 (API 28) to latest [Fact](docs/product/vision.md, ADR-001). Behaviour is identical across picker paths apart from the system UI. Test on API 28 without Google Play services, API 28 with it, and the latest API (emulators). [Hypothesis] the backported picker may or may not appear on the API 28 Google image; Stage 6 verifies. |
| NFR-8 | Memory | Must: FEAT-001 allocates no bitmap or pixel buffer. The probe reads headers only (FEAT-002). |
| NFR-9 | Testability | Should: picker and camera sit behind one interface so flow tests use fakes; tests use synthetic images and `[PLACEHOLDER]` names only. |
| NFR-10 | Store compliance | Must: no photo, video or camera permission declaration is needed [Hypothesis, Google Play photo and video permissions policy; verify before release]. Data Safety answers for this feature: no data collected or shared (the ad SDK is separate, FEAT-025). |

## 8. Validation rules
| Field / input | Rule | Error message (English; all 6 languages required) |
|---|---|---|
| URI scheme | `content://` only; `file://` and ExactSize's own FileProvider (for share, FR-20) refused | "We can't open that item. Choose a photo instead." |
| Selection count | Exactly one. If a provider returns more, the first item is used. | (no message) |
| Camera result | Success and file exists and size > 0 | "The camera didn't return a photo. Please try again." |
| Camera file creation | Free space sufficient to create the file | "There isn't enough free space on this phone to take a photo. Free some space or choose a photo from the gallery." |
| Camera availability | A camera app can handle the request | "No camera app was found on this phone. Choose a photo from the gallery instead." |
| Picker availability | Photo picker or document picker can start | "We couldn't open the photo chooser. Try again or take a photo." |
| Source readable at pick time | Opens read-only | "We couldn't open this photo. If it is stored online, connect to the internet or choose a photo saved on this phone." (`SOURCE_UNAVAILABLE`, pick-time variant; FEAT-002's render-time message is unchanged) |
| Source format | Decided by `SourceProbe` (FEAT-002 section 8) | "This file type isn't supported on this device. Choose a JPEG or PNG photo." |
| Source integrity | Decided by `SourceProbe` | "We can't read this file. Choose another photo." |
| Source pixel count | Decided by `SourceProbe` (200 MP ceiling, FEAT-002 FR-6) | "This photo is too large to open on this device. Choose another photo." |
| Animated source | Accepted; first-frame notice is shown by FEAT-002 | (none in FEAT-001) |
| Pending capture marker | Holds only a random file name; deleted on completion | (none) |
| Capture lost (Should) | Recovery failed (FR-17) | "The photo was lost while the camera was open. Please take it again." |
| Progress | Shown after 500 ms | "Opening your photo…" and "Cancel" |
| Pick screen buttons and note | Fixed labels | "Take a photo", "Choose from gallery", "Choose from files" (Should), "Your photos stay on your phone and are never uploaded." (Should, FEAT-016 owns the final copy) |

## 9. Edge cases & error states
| Case | Expected behaviour |
|---|---|
| Cancel in photo picker, document picker or camera | Back to pick screen, no message, no state change; camera file (if created) deleted |
| Camera app returns success but no file, empty file, or only a preview image | Capture-failed message; nothing handed off; file deleted |
| Camera app returns cancel but wrote a file | File deleted |
| No camera app (tablet, locked-down or work profile) | Camera button disabled with reason; gallery works |
| Free space too low to create the camera file | Low-space message; camera not launched |
| Both pickers disabled or missing | Picker-unavailable message; camera still works |
| Device rotation or "Don't keep activities" while a system UI is open | Result delivered once; no duplicate launch |
| App process killed while camera is open (2 GB phone) | On restart: recover the capture (Should) or show the capture-lost message; no orphan file; sweep at start |
| App process killed at any other time | Starts on pick screen; nothing restored; sweep |
| Double tap on Camera or Gallery | One system screen only |
| Online-only photo, offline | "Couldn't open this photo" message with online hint; no network call by ExactSize |
| Online-only photo, online but slow | Progress and Cancel after 500 ms; late result discarded after Cancel |
| Photo larger than 200 MP, or memory pre-flight fails | `IMAGE_TOO_LARGE` on pick screen |
| HEIC the device can't decode | `UNSUPPORTED_INPUT` on pick screen. A HEIC the device can decode is accepted. |
| WebP, GIF, animated WebP or GIF | Accepted (first frame); FEAT-002 shows the animation notice |
| Video, RAW, TIFF, BMP, SVG or PDF reaching the app (document picker or share) | `UNSUPPORTED_INPUT` or `CORRUPT_INPUT` from the probe; no crash |
| Zero-byte file, or text file with an image extension | `CORRUPT_INPUT` |
| File deleted or moved between pick and probe | `SOURCE_UNAVAILABLE` pick-time message |
| Read grant lost (reboot, process death, grant expired) | `SOURCE_UNAVAILABLE`; user picks again. FEAT-002 uses its render-time message if this happens later. |
| New pick refused while an earlier valid image exists | Earlier image kept; camera file of the earlier image kept |
| New camera capture while an old camera file exists | New random name; old file deleted only after the new capture passes the probe; at most 2 files exist briefly |
| Share while mid-flow (Should) | Session replaced (OQ-7); render cancelled; old camera file deleted |
| Share of `file://` or own-provider URI (Should) | Refused with "We can't open that item" |
| Camera or gallery photo with GPS in its EXIF | FEAT-001 never reads EXIF. The probe reads orientation only. Output stripping is FEAT-018. [Hypothesis] Android may redact location in gallery URIs (the app never requests ACCESS_MEDIA_LOCATION); camera files can carry GPS if the camera app has location on. |
| Photos on USB drive or file manager | Reachable through the document picker or "Choose from files" (Should); [Hypothesis] the photo picker does not list them |
| Work profile or restricted device with picker app disabled | Picker-unavailable message |
| Picked photo of a child or an ID | Same handling as every photo: on-device only, no copy, no log |
| User leaves the app and returns during a session | Session kept in memory; nothing re-read until the next step needs it |
| User closes the app from recents | Best-effort delete (FR-12); otherwise the camera file waits for the next-start sweep. Residual risk below. |

## 10. Compliance & data privacy
- **Money / payments involved? PCI-DSS scope?** No. FEAT-001 handles an image reference only. No card data, tokens or merchant credentials exist here, so there is no PCI-DSS scope. In-app purchase is handled by the stores (FEAT-026).
- **Bangladesh Bank requirements that apply:** None. No payment instrument, wallet, money movement or financial data is involved. Consistent with the BRIEF compliance scope [Assumption]. Revisit if payments are ever added.
- **Personal data touched:** photos (faces, sometimes minors), signatures (identity-sensitive), file names (may contain a person's name; deliberately never read), URIs and paths (may reveal folders), EXIF (GPS, device, time; never read here). **Purpose:** the user's own on-device resize. **Retention:** none, except one camera file in app-private cache during a session (FR-11, FR-12). Gallery and files images are never copied. **Consent:** none is needed because nothing is collected or sent [Assumption]; legal review of this reading is an open item (OQ-10). Test data uses synthetic images and `[PLACEHOLDER]` values only.
- **Least privilege:** no runtime permission, no broad storage or media access, FileProvider not exported and limited to the camera folder (FR-4, FR-18). The system picker shows the user's library; ExactSize receives only the chosen item [Hypothesis].
- **Play Data Safety and permissions:** this feature collects and shares nothing and declares no sensitive permission. The store label must still match the ad SDK's real collection (FEAT-025, FEAT-016) and must not claim "no data collected" unless the ad SDK is accounted for [Fact](docs/research/competitors.md, market notes).
- **No logging** of image content, URIs, paths, file names, EXIF or sizes, including release crash reports. Platform exception messages can contain the URI, so they are mapped to enum codes and dropped (FR-19).
- **Cloud-only photos (privacy flag):** if the user picks an online-only photo, the gallery or cloud app may download it. That is the provider's network use and its own account relationship, not ExactSize's. FEAT-016's claim "every core flow works without a network" has this exception and must be worded carefully (for example "ExactSize itself never uploads your photos"). ExactSize cannot detect or block it.
- **Share target (Should):** any app can send this app a URI. It is treated as untrusted: only `content://`, never `file://` or the app's own provider (blocks reading the app's private files), and the MIME type in the intent is not trusted (the probe decides).
- **Camera files:** stored in app-private cache only, never in the gallery, which keeps a fresh ID photo out of the user's photo library and cloud backup. Cleanup on refusal, cancel, replacement, session end, app close (best effort) and cold-start sweep. **Residual risk:** if the user never reopens the app after the process is killed, one camera file remains until reopening, clearing the cache or uninstalling [Hypothesis].
- **Children:** students include minors (BRIEF). FEAT-001 collects nothing; photos of minors stay on the device. No image data, URI or origin may reach the ad SDK or analytics (FEAT-025, FEAT-027).
- **Screens:** the pick screen shows no photo, so it needs no recents-thumbnail protection. The crop screen has it (FEAT-002 FR-26).

## 11. Dependencies
- **FEAT-002** (hard, built): `SourceHandle`, `SourceProbe`, reason codes and messages (FEAT-002 section 8, tech sections 3 and 4).
- **FEAT-004:** AC-5.2 ("when it is selected") is met by FR-7.
- **FEAT-005 / FEAT-011:** supply the target in the step after pick (photo first, OQ-4). **FEAT-007:** its flow-end event must call FEAT-001's release (FR-11).
- **FEAT-016:** privacy line, explainer and the cloud-only wording. **FEAT-018:** metadata stripping in the output. **FEAT-019:** 6-language strings. **FEAT-025:** ad SDK exposure, no data from this feature.
- **ROADMAP row FEAT-001:** the dependency "Camera/photo permission strings" no longer applies under this design (no permission strings). Store disclosures remain. See OQ-9.
- **ADR-001:** minimum Android 9, Flutter, JNIgen, enum-only log wrapper.
- **UI:** the pick screen is a real UI screen, so it is designed with impeccable before building (CLAUDE.md, Product Owner decision 2026-11-20). The Product Owner must be told before design starts.
- **For the tech plan (architect, not Product Owner):** plugin versus thin native layer (the `image_picker` copy behaviour, [Hypothesis]); picker contract and fallback detection; FileProvider and `queries` details; result recovery after recreation and process death; who calls release and when; merged-manifest build check.

## 12. Open questions
- [x] **OQ-1 — decided 2026-11-21 (Product Owner): system photo picker with document-picker fallback, no storage permission.** (Was blocking.) Gallery strategy. Proposed: system photo picker with document-picker fallback, no storage permission. Alternative: request READ_MEDIA_IMAGES and build an in-app gallery (more control, a permission prompt, Play policy exposure, much more work). Recommend the proposal.
- [x] **OQ-2 — decided 2026-11-21 (Product Owner): system camera intent into a private file, no CAMERA permission.** (Was blocking.) Camera strategy. Proposed: system camera intent into a private file, no CAMERA permission. Alternative: in-app camera (CameraX): a runtime permission, store disclosure, device bugs and a larger UI. Recommend the proposal. Trade-off: the camera UI and steps belong to the OEM app.
- [ ] **OQ-3 (non-blocking).** Keep "Choose from files" (FR-21) and share target (FR-20, US-8) in R1 as Should, or move them to Next? Value rests on [Assumption] operator behaviour; effort about +0.3 pw [Assumption]. Under the current cut order Should items go after Could items.
- [x] **OQ-4 (blocking UI work, not the tech plan).** Screen order and ownership: photo first or target first, and who owns the start screen. **Decided by the Product Owner 2026-11-22: photo first.** The pick screen is the app's start screen and FEAT-001 owns it; an accepted image goes to the target step (FEAT-005 / FEAT-011), then crop; a result pending at start-up (FR-15, FR-17) and a share (FR-20) go the same way. Reason: one route for picked, shared and recovered photos, and the source size is known when the target is chosen. User preference between the orders is a [Hypothesis] (OQ-8 research gap). The pick UI still needs the impeccable design pass (gate G3, T16).
- [ ] **OQ-5 (non-blocking).** The camera original is discarded when the session ends (privacy default). Alternative: offer "Save original to gallery". Recommend discard. Users may be surprised that a fresh photo is not in their gallery.
- [ ] **OQ-6 (non-blocking).** Is process-death recovery of a camera capture (FR-17) Must or Should? Test with "Don't keep activities" and a forced kill on the 2 GB emulator; real frequency on phones is unknown [Hypothesis].
- [ ] **OQ-7 (non-blocking).** A share arriving mid-flow: replace silently (proposed: fast, nothing is exported yet) or ask first.
- [ ] **OQ-8 (non-blocking).** Research gap: no finding on competitors' pick flows or permission prompts. Worth a short follow-up by the researcher, or accept the risk?
- [ ] **OQ-9 (non-blocking).** Update the ROADMAP row for FEAT-001 (dependency text and the 0.5 pw effort), and the R1 totals if the Product Owner agrees with the re-estimate. Only the Product Owner decides.
- [ ] **OQ-10 (non-blocking, before release).** Confirm the Play photo and video permissions policy reading (NFR-10) and have the "no consent needed" reading checked by whoever handles legal and store compliance.
- [ ] **OQ-11 (non-blocking).** Cloud-only photos cannot be detected or blocked. Accept the dependence on the provider and the privacy wording in section 10?

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-21 | First draft |
| 0.2 | 2026-11-21 | OQ-1 and OQ-2 decided by the Product Owner (picker and camera strategies as proposed) |
| 1.0 | 2026-11-21 | Approved by Product Owner |
| 1.1 | 2026-11-22 | OQ-4 decided by the Product Owner: photo first, pick screen is the start screen (owned by FEAT-001), next step is the target step; section 5 step 6 and section 11 updated (clarification, scope unchanged) |
