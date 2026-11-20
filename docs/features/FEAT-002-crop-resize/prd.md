---
id: FEAT-002
title: Crop and resize to exact target dimensions
status: Approved
version: 1.3
updated: 2026-11-20
links: [ROADMAP, FEAT-001, FEAT-004, FEAT-005, FEAT-006, FEAT-008, FEAT-011, FEAT-016, FEAT-018]
---

# FEAT-002 — Crop and resize to exact target dimensions

## 1. Overview
FEAT-002 takes the image chosen through FEAT-001 (camera or gallery) and the target width×height from FEAT-005 (manual entry) or FEAT-011 (preset). It shows a crop screen whose frame is locked to the target aspect ratio, lets the user frame the subject (drag, pinch-zoom and proportional corner handles, plus a non-gesture alternative), then renders decoded pixels at **exactly W×H**. It also corrects EXIF orientation, decodes very large photos without running out of memory, and warns when the crop must be enlarged. It runs fully on-device and offline on Android (Flutter). It is crop-to-fill only: the whole W×H area is always covered by image content.

**Release:** MVP (R1 Phase A, roadmap effort 1.3 person-weeks, Must, RICE 23077; this row absorbed the former FEAT-003 resize, PO decision 2026-11-19) [ROADMAP]. The scope below probably exceeds 1.3 pw (see OQ-9).

**Output contract to FEAT-004 (matches FEAT-004 FR-1, FR-2, section 8 "Pixels" rule and section 9 edge cases)**
| Item | Contract |
|---|---|
| Dimensions | Decoded pixel buffer of exactly target W×H (integers). FEAT-002 asserts this before hand-off; on mismatch it hands off nothing and reports an internal error. |
| Colour form | 8 bits per channel, sRGB, row-major. Opaque source: 3 channels (RGB). Source with transparency: 4 channels, straight (non-premultiplied) alpha. |
| Colour conversion owner | **FEAT-002 owns conversion** to 8-bit sRGB at decode, using the platform decoder's own sRGB output (no custom colour engine); sources the platform can't decode to 8-bit sRGB are refused as `UNSUPPORTED_INPUT` (FR-10). This matches FEAT-004 section 9 ("converted to 8-bit sRGB before encoding"). FEAT-004 does not convert. Whether the output file embeds an sRGB ICC profile is not decided here: that is FEAT-004 OQ-6 (see OQ-4 below). |
| Orientation | Already applied to the pixels. No orientation tag is passed on. |
| Hand-off flags | `hasTransparency` (true only if at least one output pixel has alpha < 255), `upscaleFactor`, `cropRect`, `rotationApplied` (manual rotation only: 0, 90, 180 or 270 degrees clockwise; EXIF orientation is never included, OQ-13). No EXIF, GPS, file name or path is passed on. |
| Cleanup | Pixel buffers or temp files follow the FEAT-004 FR-20 cleanup rules. |

**Scope boundaries**
| Owned by FEAT-002 | Owned elsewhere (not duplicated here) |
|---|---|
| EXIF orientation correction (read orientation only) | EXIF/GPS stripping in the output file: **FEAT-018** |
| Downsampled decode of very large sources (FEAT-004 relies on this for 50 MP) | File size (KB), output format, JPEG flattening of transparency: **FEAT-004** |
| Crop screen: aspect locked to target, pinch-zoom, drag, proportional corner handles (Should), non-gesture controls | Target W×H values and validation UI: **FEAT-005** (manual), **FEAT-011** (presets) |
| High-quality resampling to exact W×H; conversion to 8-bit sRGB | Picking the image (camera/gallery, permissions): **FEAT-001** |
| Upscale warning when the source is smaller than the target | Fill vs fit/pad modes: **FEAT-008** (FEAT-002 is fill only) |
| Manual 90° rotate in the crop screen (Should, accepted) | Preview and "meets spec": **FEAT-006**. Signature cleanup and auto-crop: **FEAT-020 / FEAT-021**. On-device/offline guarantee and privacy copy: **FEAT-016** |

## 2. Problem statement
Applicants need photo and signature uploads at exact pixel sizes such as 300×300 px (photo) and 300×80 px (signature), and signature strips can be as extreme as 140×60 [Fact](docs/research/competitors.md, UX patterns; FEAT-004 AC-2.2). A phone photo is almost never at the form's ratio, so the user must choose which part to keep. Reviewed tools offer fill (crop) vs fit modes [Fact](https://imresizer.com/bangladesh-bcs-photo-size), and the tool with task-first defaults shows 300×300 and 300×80 [Fact](https://tool.teamzlab.com/bd/photo-signature-resizer/). Without a locked-ratio crop, users guess and re-upload. Phone photos also arrive sideways when the orientation tag is ignored, and 50 MP photos can crash naive decoders on low-end phones [Hypothesis]. The brief's UVP ("exact pixel size") depends on this feature [BRIEF Pitch]. How often users give up on cropping is unknown [Assumption].

## 3. Goals & success metrics
| Goal | Metric | Target |
|---|---|---|
| Exact dimensions | Share of renders whose hand-off buffer is exactly W×H | **100%** (zero tolerance) |
| No sideways photos | Share of EXIF orientation test files (all 8 values, JPEG and HEIC where decodable) that render upright | 100% |
| Crash-free on large inputs | Crashes or ANRs on the large-image test set (12 MP, 50 MP, 24 MP target) on the R1 low-end device | 0 |
| Speed | Final render from a 12 MP source to a target ≤ 2 MP on low-end (NFR-1) | ≤ 2 s median, ≤ 5 s p95 [Assumption] |
| Determinism | Same source + crop rectangle + target + app version on the same device and OS build → same pixels | 100% of test set |
| Re-crop quality | Re-crop output vs a single direct render from the original | Pixel-identical |
| Task speed | Median time from crop screen open to "Continue" for a first-time user | ≤ 15 s [Assumption] |

**Non-goals**
- Fit/pad, letterbox, background fill, or any mode that leaves unfilled areas (FEAT-008). FEAT-002 never stretches (no non-uniform scaling beyond rounding, FR-8).
- File size, JPEG/PNG encoding, flattening transparency for JPEG (FEAT-004).
- Preview with the real compressed file and "meets spec" badge (FEAT-006).
- Stripping or writing metadata (FEAT-018, FEAT-010). FEAT-002 only reads the orientation value.
- Signature cleanup, whitening, auto-crop, face detection or auto-framing on content (FEAT-020, FEAT-021).
- Brightness, contrast or any colour adjustment (OQ-7, not proposed for R1).
- Free-form (unlocked ratio) cropping, filters, collages (BRIEF out of scope).
- Batch cropping (FEAT-022, Later).
- Cloud processing, uploads, accounts.

## 4. User stories
- **US-1** As a job applicant, I want a crop frame locked to my form's ratio, so that I choose the framing once and the portal accepts the dimensions.
  - **AC-1.1** Given a 4000×3000 photo and target 300×300, when the crop screen opens, then the frame is square, covers the largest possible centred area, and no empty area shows inside it.
  - **AC-1.2** Given the crop screen is open, when I drag or pinch-zoom, then the image moves or scales under the frame, the frame ratio stays exactly W:H, and the image can never move or zoom out so that the frame shows empty space.
  - **AC-1.3** Given a signature target 300×80 (3.75:1) and a 3000×4000 portrait photo, when the screen opens, then the frame is a wide strip at 3.75:1, fully visible on screen with a minimum height of 48 dp, and the initial crop is the centred full-width strip.
  - **AC-1.4** Given a target 140×60 (about 2.33:1), when I continue, then the output buffer is exactly 140×60.
  - **AC-1.5** Given a square source and a square target, when the screen opens, then the initial crop is the whole image and Continue renders without enlarging or reducing beyond a 1:1 scale.
  - **AC-1.6** Given a source whose ratio already equals the target ratio, when the screen opens, then the initial crop is the whole image.

- **US-2** As a user, I want the output to be exactly the size my form wants, so that I never get "dimensions wrong" at upload.
  - **AC-2.1** Given any valid source, crop rectangle and target W×H (within section 8 limits), when I tap Continue, then the pixel buffer handed to FEAT-004 is exactly W×H, in 8-bit sRGB, and its aspect ratio is not distorted beyond the rounding rule in FR-8.
  - **AC-2.2** Given a target W×H that differs from the previous run, when I change the target and return to the crop screen, then the frame ratio and output use the new W×H.
  - **AC-2.3** Given a downscale (crop region larger than target), when the result is inspected, then it is anti-aliased (no visible stair-stepping or moiré on a diagonal-line test chart, FR-9).

- **US-3** As a user taking a photo with the camera, I want it to appear upright, so that I do not have to fix it.
  - **AC-3.1** Given a camera JPEG with EXIF orientation 6 (needs 90° clockwise), when it opens in the crop screen, then it appears upright.
  - **AC-3.2** Given orientation values 1 to 8 (including mirrored 2, 4, 5, 7), when each test image is opened, then each appears upright and not mirrored versus the reference.
  - **AC-3.3** Given a missing, zero, or out-of-range orientation value, when the image opens, then it is treated as orientation 1 and no error appears.
  - **AC-3.4** Given a HEIC photo with an orientation transform, when the device can decode it, then it appears upright (same as JPEG).
  - **AC-3.5** Given the output buffer, when FEAT-004 or FEAT-006 receives it, then no orientation value accompanies it (the rotation is already in the pixels, so rotation is not applied twice downstream).

- **US-4** As a user with a high-resolution camera, I want large photos to work on my phone, so that the app does not crash or freeze.
  - **AC-4.1** Given a 50 MP source on the R1 low-end device, when I open it, then the crop screen appears using a reduced-size preview and the app does not crash.
  - **AC-4.2** Given the same 50 MP source, when I continue, then the render completes from a decode that is never smaller than the target in either axis (FR-7) and the output is exactly W×H.
  - **AC-4.3** Given a source above the supported pixel ceiling (FR-6) or memory runs out, when decoding, then the user sees an "image too large" message with one next action (choose another photo) and the app does not crash.
  - **AC-4.4** Given a target of 24 MP (the bound in FEAT-004 OQ-4 [Assumption]), when I continue on a device without enough memory, then the result is `IMAGE_TOO_LARGE` or `OUT_OF_MEMORY_HANDLED`, not a crash; a target above 24 MP is refused up front (section 8).

- **US-5** As a user whose photo is smaller than the target, I want to be told, so that I can choose a better photo or accept a softer result.
  - **AC-5.1** Given a 200×200 source and target 300×300 (upscaleFactor 1.5), when the crop screen opens, then a visible, non-colour-only notice says the image will be enlarged and may look soft, and Continue is still available.
  - **AC-5.2** Given upscaleFactor above 1.0 up to 2.0, when I continue, then the notice appears (information level) and no extra confirmation is needed.
  - **AC-5.3** Given upscaleFactor above 2.0 [Assumption], when I tap Continue, then a warning dialog explains the likely poor quality and requires "Continue anyway" or "Choose another photo".
  - **AC-5.4** Given I zoom in so that the crop region shrinks, when upscaleFactor crosses a threshold, then the notice updates live (and is announced to TalkBack, AC-9.4).
  - **AC-5.5** Given the source is smaller than target in only one axis (for example 1000×100 for target 300×300), when the screen opens, then the factor is computed on the limiting axis (`max(W/cropW, H/cropH)`) and the warning appears accordingly.
  - **AC-5.6** Given an upscale, when the result is inspected, then the pixels are resampled once from the original-resolution data with the pinned algorithm (no repeated enlargement) and the output is exactly W×H.

- **US-6** As a user with a transparent PNG (for example a signature on a clear background), I want transparency kept until the output step, so that the next step can decide what to do with it.
  - **AC-6.1** Given a PNG with an alpha channel, when I crop and continue, then the output buffer has 4 channels with straight alpha and `hasTransparency` is true if at least one pixel has alpha < 255.
  - **AC-6.2** Given a PNG with an alpha channel in which every pixel is opaque, when I continue, then the buffer may be 3 or 4 channels, but `hasTransparency` is false.
  - **AC-6.3** Given a transparent source and resampling, when edges are inspected, then there are no dark or light fringes at alpha edges (resampling is done in premultiplied form and converted back).
  - **AC-6.4** Given a transparent source, when the crop screen shows it, then a neutral checkerboard shows under transparent areas, so that transparent areas are not mistaken for white or black; flattening and its warning belong to FEAT-004 (FEAT-004 FR-12).

- **US-7** As a user with an unusual file, I want a clear message if it can't be opened, so that I know what to do next.
  - **AC-7.1** Given a HEIC/HEIF or WebP file the device cannot decode, when I choose it, then I see "this file type isn't supported on this device" with a next action (pick a JPEG or PNG, or convert the photo) and no crash. Reason code `UNSUPPORTED_INPUT`.
  - **AC-7.2** Given a corrupted or truncated file, when decoding fails, then the message says the file can't be read (`CORRUPT_INPUT`) and I return to selection with no partial image.
  - **AC-7.3** Given an animated WebP, when decoded, then the first frame is used and the user is told (consistent with FEAT-004 section 9).
  - **AC-7.4** Given a file with an image extension but non-image content, when I choose it, then the result is `CORRUPT_INPUT` or `UNSUPPORTED_INPUT`, with no crash.
  - **AC-7.5** Given the source cannot be re-read later (file moved or permission revoked), when I re-crop or continue, then the result is `SOURCE_UNAVAILABLE` with a message to pick the photo again.

- **US-8** As a user who is not happy with the framing, I want to re-crop without losing quality, so that the second try is as sharp as the first.
  - **AC-8.1** Given I rendered once, when I go back, change the crop and render again, then the second output is computed from the original source, never from the previous output or the preview bitmap.
  - **AC-8.2** Given any sequence of N re-crops ending in the same crop rectangle as a fresh single render, when outputs are compared, then they are pixel-identical.
  - **AC-8.3** Given the same source, same integer crop rectangle, same target and same app version on the same device and OS build, when rendered twice, then the pixel buffers are identical (FR-12).
  - **AC-8.4** Given I go back to the crop screen after a render, when it opens, then my previous crop (rectangle, zoom and rotation) is restored.

- **US-9** As a TalkBack or switch user, I want to frame the image without gestures, so that I can complete the step.
  - **AC-9.1** Given TalkBack is on, when I focus the crop area, then it is announced with its purpose and current state (for example "Crop area, zoom [PERCENT], showing the centre of the photo"), and it exposes standard accessibility actions for move left, right, up, down, zoom in, zoom out and reset.
  - **AC-9.2** Given any accessibility setting, when I look at the controls, then visible "Centre" (auto-centre the crop) and "Reset" buttons exist, each ≥ 48 dp with a label (Must); nudge and zoom buttons are also visible if FR-27 ships (Should).
  - **AC-9.3** Given I press a nudge button, when the move would leave the image area, then the crop stops at the image edge and the edge is announced ("reached the left edge").
  - **AC-9.4** Given TalkBack is on, when zoom, position or the upscale notice changes via buttons, then the change is announced politely (live region), without announcing every frame of a drag.
  - **AC-9.5** Given the system font size is 200%, when the crop screen shows, then all controls stay usable (scroll if needed) and the crop frame stays visible.

- **US-10** As an Arabic, Hindi, Spanish, Portuguese or Indonesian speaker, I want the crop screen in my language, so that I understand every message.
  - **AC-10.1** Given the device language is any of the 6 languages, when a crop-screen label, notice or error appears, then it is in that language, built from placeholders (no string concatenation), with numbers and units bidi-isolated.
  - **AC-10.2** Given Arabic (RTL), when the crop screen opens, then control rows, button order, back and Continue positions mirror, while the photo, crop frame and nudge arrows keep physical directions (the "left" nudge always moves toward the physical left; its label says "left" physically).
  - **AC-10.3** Given Arabic, when the target is shown as "300×80", then the dimensions are rendered readable and not reversed.

- **US-11** As a privacy-conscious user, I want my photo and signature to stay on my phone and my original untouched, so that I can trust the app.
  - **AC-11.1** Given any outcome (success, cancel, failure), when I compare the original file before and after, then it is byte-identical and its modification time is unchanged.
  - **AC-11.2** Given airplane mode, when I crop and render, then everything works with no network access.
  - **AC-11.3** Given the step finishes, is cancelled or fails, when temp storage is inspected, then no intermediate image remains (preview bitmaps, region decodes, temp files).
  - **AC-11.4** Given release logs and crash reports, when inspected after a session, then they contain no pixel data, paths, file names, EXIF values (including GPS) or crop coordinates tied to content, only enumerated outcome codes.

- **US-12 (Should; accepted by the Product Owner 2026-11-19, OQ-1)** As a user whose photo is sideways even after automatic correction, I want to rotate it by 90° in the crop screen, so that I don't need another app.
  - **AC-12.1** Given the crop screen, when I tap rotate clockwise or counter-clockwise, then the image rotates 90° around the frame centre, the crop is re-fitted so no empty area shows, and the frame ratio does not change.
  - **AC-12.2** Given I rotated four times in one direction, when the render runs, then the result equals an unrotated render with the same crop (pixel-identical).
  - **AC-12.3** Given rotation, when rendered, then rotation is applied to pixels once, together with the EXIF correction (a single resample, not chained), and `rotationApplied` records the manual rotation only, never the EXIF correction (OQ-13).

- **US-13 (Should; Product Owner decision 2026-11-19, OQ-5)** As a user, I want to drag a corner of the crop frame to make it bigger or smaller, so that I can frame my photo the way most photo apps do.
  - **AC-13.1** Given the crop screen, when I drag any of the four corner handles, then the frame resizes proportionally, anchored at the opposite corner, and its ratio stays exactly W:H.
  - **AC-13.2** Given I drag a handle outward past the image edge, when the frame reaches the edge, then it stops there and no empty area shows inside it.
  - **AC-13.3** Given I drag a handle inward, when the crop region reaches the minimum (FR-4), then the frame stops shrinking, and the upscale notice updates live if the factor crosses a threshold (FR-11).
  - **AC-13.4** Given I release a handle, when the frame settles, then it re-centres and grows to fill the crop area on screen (the image zooms to match), and the selected part of the image (`cropRect`) does not change.
  - **AC-13.5** Given I have used handles, drag and pinch-zoom in any order, when I tap Continue, then the output is exactly W×H and equals a fresh render of the same final `cropRect` (pixel-identical, FR-12).
  - **AC-13.6** Given a signature strip such as 300×80, when the screen opens, then all four handles are reachable with ≥ 48 dp touch targets that don't overlap.
  - **AC-13.7** Given TalkBack is on, when I explore the crop area, then the handles are announced (for example "Resize crop, top-left corner"), and the zoom in/out accessibility actions (FR-5) give the same result as resizing with a handle.
  - **AC-13.8** Given Arabic (RTL), when the crop screen opens, then handles stay at the physical corners of the frame (not mirrored).

## 5. User flows
**Main flow**
1. FEAT-001 delivers a source handle (camera or gallery). FEAT-005 or FEAT-011 provides target W×H.
2. FEAT-002 validates W×H (section 8) and reads the image header (dimensions, format, orientation) without decoding the full image.
3. It decodes a reduced preview (long side ≤ 2048 px [Assumption]), applies orientation and 8-bit sRGB conversion, and shows the crop screen with the frame at ratio W:H and the initial centred crop (largest area).
4. User drags, zooms, resizes the frame with a corner handle, (optionally) rotates 90°, or uses nudge/zoom/centre buttons. All of these edit the same `cropRect`. The upscale notice updates live.
5. User taps Continue. FEAT-002 converts the on-screen state into an integer `cropRect` in oriented-source pixels, decodes the needed region of the original (FR-7), resamples once to W×H (FR-9), asserts the dimensions, and hands the buffer plus flags to FEAT-004.
6. FEAT-006 shows the preview and "meets spec" later in the pipeline. If the user goes back, the crop state is restored (AC-8.4).

**Alternate flows**
- Source smaller than target: notice (AC-5.1), or a warning with confirm (AC-5.3).
- Source ratio equals target ratio: initial crop is the whole image.
- Transparent source: checkerboard shown; transparency flag passed to FEAT-004.
- Device rotated or app backgrounded during cropping: crop state is kept (relative to the image) and the screen redraws.
- Cancel/Back: render stops, temp files deleted, the original untouched; return to the previous screen.

**Error flows:** `UNSUPPORTED_INPUT`, `CORRUPT_INPUT`, `SOURCE_UNAVAILABLE`, `IMAGE_TOO_LARGE`, `OUT_OF_MEMORY_HANDLED`, `INVALID_TARGET_DIMENSIONS`, `CANCELLED`. No pixel buffer is handed to FEAT-004 in any of them.

## 6. Functional requirements
| ID | Requirement | Story | Priority |
|---|---|---|---|
| FR-1 | The system shall accept a source handle from FEAT-001 and target W×H from FEAT-005 or FEAT-011, validate W×H (section 8) and return `INVALID_TARGET_DIMENSIONS` on failure. | US-2 | Must |
| FR-2 | The system shall read the image header (width, height, format, orientation) without a full decode, and refuse unsupported or corrupt files with `UNSUPPORTED_INPUT` or `CORRUPT_INPUT` before showing the crop screen. | US-7 | Must |
| FR-3 | The system shall apply EXIF orientation values 1 to 8 (including mirrored), treat missing or invalid values as 1, apply it identically in the preview and in the final render, and pass no orientation value downstream. It reads only the orientation, no other EXIF field is read or stored. | US-3 | Must |
| FR-4 | The system shall show a crop frame whose ratio is exactly W:H, with image drag and pinch-zoom under a frame whose ratio is fixed at W:H (its on-screen size can also change through corner handles, FR-28). The initial crop is the largest centred area at ratio W:H. Minimum zoom is the "cover" scale (no empty area inside the frame); maximum zoom is the point where the crop region's shorter side is 32 source pixels or 8× the cover scale, whichever comes first [Assumption]. The frame shall be fully visible and at least 48 dp in its shorter dimension, even at ratios of 3.75:1 or more. Where the screen cannot show an exact-ratio frame that is fully visible and at least 48 dp (beyond about 6.5:1 in portrait), the frame is drawn at the true ratio at full width with a touch band of at least 48 dp and the "limited on-screen precision" hint pointing to the buttons; the output stays exactly W×H (OQ-14, 2026-11-20). | US-1 | Must |
| FR-5 | The system shall provide TalkBack custom accessibility actions on the crop area (move up/down/left/right, zoom in/out, centre, reset) and visible "Centre" and "Reset" buttons (≥ 48 dp, labelled). Results are identical to gesture results (same `cropRect` rules). | US-9 | Must |
| FR-6 | The system shall support sources up to a ceiling of 200 MP (Product Owner decision 2026-11-20; best effort: a file that must be decoded in full and does not fit in memory gets the too-large message); above it, or if memory runs out at any step, it shall return `IMAGE_TOO_LARGE` or `OUT_OF_MEMORY_HANDLED` and never crash. Target pixels (W×H) shall be at most 24 MP [Assumption, FEAT-004 OQ-4]. | US-4 | Must |
| FR-7 | **Downsampled decode, single resample.** The preview shall be a reduced decode used only for display. The final render shall decode only what is needed from the original file (region decode where the codec supports it, otherwise a full decode at a reduced sample size) at the largest power-of-two reduction such that the decoded crop region is still at least target W×H in both axes. The decode shall never reduce the crop region below the target size; if the crop region is smaller than the target, no reduction is applied. The preview bitmap shall never be used as a render input. | US-4, US-8 | Must |
| FR-8 | The system shall define the crop as an integer rectangle `cropRect` (x, y, w, h) in oriented-source pixels with `abs(w/h − W/H)` as small as possible given integers (the rounding error is under 1 source pixel on each side). The resample maps cropRect onto W×H with separate x and y scale factors only to absorb that rounding. | US-2 | Must |
| FR-9 | The system shall resample once from the decoded region to exactly W×H using one pinned, anti-aliased algorithm chosen in Stage 6 and recorded in an ADR, with alpha handled in premultiplied form. (Linear-light and PSNR targets removed, Product Owner decision 2026-11-19.) | US-2 | Must |
| FR-10 | The system shall obtain 8-bit sRGB pixels by asking the platform decoder for 8-bit sRGB output (which covers grayscale, 16-bit and ICC-tagged/wide-gamut sources where the platform supports them). It shall not implement its own colour conversion. Sources the platform can't decode to 8-bit sRGB (for example CMYK JPEGs on devices that don't support them) shall return `UNSUPPORTED_INPUT` with the normal message. Scope trimmed by Product Owner decision 2026-11-19. | US-2 | Must |
| FR-11 | **Upscale warning.** upscaleFactor = `max(W/cropW, H/cropH)` computed on the current cropRect. At > 1.0 up to 2.0 the system shall show a visible information notice; above 2.0 [Assumption] it shall require explicit confirmation ("Continue anyway") before rendering. Upscaling is never blocked. The notice shall not rely on colour alone and updates live while zooming. | US-5 | Must |
| FR-12 | The system shall be deterministic: the same source bytes, `cropRect`, target, rotation and app version on the same device and the same OS build shall give byte-identical pixel buffers (an OS update may change the platform decoder's output). The gesture-to-cropRect conversion shall also be deterministic (same final gesture state, same cropRect). Cross-device identity is Should (depends on the platform decoder; OS decoders may differ); kept as Should by the Product Owner, 2026-11-20 (OQ-12). | US-8 | Must |
| FR-13 | Every render shall start from the original source (re-read and re-decoded), never from a prior output, preview or intermediate resize. The crop state (cropRect, zoom, rotation) shall be restored when the user returns to the screen in the same session. | US-8 | Must |
| FR-14 | The system shall keep alpha through crop and resample (straight alpha, 4 channels) when the source has transparency, set `hasTransparency` accurately, and show a checkerboard under transparent areas. It shall not flatten transparency; this is FEAT-004 FR-12. | US-6 | Must |
| FR-15 | The system shall use the first frame of animated sources and tell the user. | US-7 | Must |
| FR-16 | The system shall assert before hand-off that the buffer is exactly W×H with 8-bit sRGB channels; on failure it shall hand off nothing and report an internal error ("Something went wrong preparing your image. Please try again."). | US-2 | Must |
| FR-17 | The system shall never modify, move, rename or delete the original file, and shall only read it. | US-11 | Must |
| FR-18 | The system shall run decode and render off the UI thread, show progress for operations over 500 ms [Assumption], be cancellable, and delete all temp files on success, cancel, failure and at app start (orphan sweep, shared with FEAT-004 FR-20). | US-11 | Must |
| FR-19 | The system shall expose outcome codes, `upscaleFactor`, `cropRect` and `rotationApplied` to FEAT-004 and FEAT-006, and no other data derived from the source. | US-2 | Must |
| FR-20 | The system shall keep the crop UI usable on device rotation, split-screen and font scaling to 200%, preserving the crop state. | US-9 | Should |
| FR-21 | The system should offer a 90° rotate (clockwise and counter-clockwise) in the crop screen; rotation shall combine with EXIF correction into one transform in the single resample. Accepted (Product Owner decision 2026-11-19, OQ-1). | US-12 | Should |
| FR-22 | The system shall show the checkerboard and "enlarged" notices, errors and labels from localisable resources in all 6 languages, with no string concatenation. | US-10 | Must |
| FR-23 | Crop screen controls shall mirror in RTL, while the image, crop frame and nudge arrow directions keep their physical orientation. | US-10 | Must |
| FR-24 | The system shall not write logs, analytics fields or crash reports containing pixel data, file names, paths, EXIF values or crop coordinates; only enumerated outcome codes. | US-11 | Must |
| FR-25 | The system shall, where a decoded source is wider than the screen preview, keep drag/zoom at ≥ 30 fps on the R1 low-end device [Assumption] by using the preview bitmap for display only. | US-1 | Should |
| FR-26 | On Android 13 and later, the system shall hide the crop screen from the recent-apps thumbnail without blocking screenshots (no FLAG_SECURE). FEAT-006 should apply the same rule to its preview. Product Owner decision 2026-11-19 (OQ-8). | US-11 | Must |
| FR-27 | The system should also show visible nudge buttons (up/down/left/right, step 5% of the visible crop region [Assumption], long-press repeats) and zoom in/out buttons, each ≥ 48 dp with a label. Split from FR-5, Product Owner decision 2026-11-19. | US-9 | Should |
| FR-28 | The system should show four corner handles on the crop frame. Dragging a handle resizes the frame proportionally, anchored at the opposite corner, with the ratio locked to W:H. Handles, drag and pinch-zoom all edit the same `cropRect` and obey the same limits: clamped to the image (no empty area) and to the FR-4 minimum crop. One gesture runs at a time. On release the frame re-centres and re-fits on screen without changing `cropRect`. Touch targets are ≥ 48 dp and may extend outside the frame. Handles keep physical positions in RTL and have TalkBack labels; zoom actions (FR-5) are the non-gesture equivalent. Product Owner decision 2026-11-19 (OQ-5). | US-13 | Should |

## 7. Non-functional requirements

> **Test environment (Product Owner decision 2026-11-20):** no physical low-end phone is used before release. Wherever this PRD says "low-end device", "R1 low-end device" or "R1 device matrix", read: Android emulators with a 2 GB RAM profile on API 28 and on the latest API. Memory and reliability targets are checked there. Timing targets (the speed rows in section 3 and the timing parts of the NFRs and FR-25 frame rate) are best effort: measured on the emulator for information only and not verified on real low-end hardware. Risk accepted: slowness or low-memory kills on real low-end phones may first appear after release.
| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | On the R1 low-end device (about 2 GB RAM, entry-level CPU [Assumption]): crop screen visible ≤ 1.5 s median after selecting a 12 MP photo; final render ≤ 2 s median and ≤ 5 s p95 for a 12 MP source and a target ≤ 2 MP; a 50 MP source renders in ≤ 8 s p95; crop-screen interaction ≥ 30 fps. All [Assumption], to be measured in Stage 6. |
| NFR-2 | Memory | Peak memory attributable to FEAT-002 ≤ 200 MB for a 12 MP source with a target ≤ 2 MP; ≤ 350 MB with a 24 MP target (4-channel buffer is about 96 MB at 24 MP) [Assumption]. Above the device's limit: `IMAGE_TOO_LARGE`/`OUT_OF_MEMORY_HANDLED`, never a crash. Only one full-size working buffer at a time. |
| NFR-3 | Accuracy / determinism | Exact W×H 100% of renders; same-device determinism 100% (FR-12); resampler quality accepted on the Stage 6 visual test chart. |
| NFR-4 | Accessibility | All crop actions have non-gesture equivalents (FR-5); controls ≥ 48 dp; TalkBack announces state changes through a polite live region; text scales to 200%; no information by colour alone (notices carry an icon and text); contrast at WCAG AA for overlays on any photo (frame outline uses a two-tone border). |
| NFR-5 | Offline / poor network | Fully offline; the image pipeline makes no network calls and needs no downloadable codec or server. |
| NFR-6 | Localisation | English, Spanish, Portuguese (Brazil), Hindi, Indonesian, Arabic. Placeholders for numbers and dimensions; Arabic is RTL, with bidi-isolated numbers and units; native-speaker review is part of the R1 Phase B exit criteria (FEAT-019). |
| NFR-7 | Privacy | See section 10: on-device only, no content logging, original never modified, temp files cleaned. |
| NFR-8 | Reliability | No crash or ANR on the test set: 8 EXIF orientations, HEIC/WebP (supported and unsupported), 100 MP, 200 MP and corrupt files, 1×1 sources, extreme ratios. |
| NFR-9 | Testability | The render pipeline is a pure function over (source bytes, cropRect, rotation, target), unit-testable with synthetic images and a golden-pixel determinism test; orientation and colour tests use synthetic images only. |
| NFR-10 | Compatibility | Min Android version and HEIC support follow the minSdk decision (FEAT-004 OQ-10); behaviour is identical for JPEG, PNG, WebP and HEIC wherever decodable. |

## 8. Validation rules
| Field / input | Rule | Error message (English; all 6 languages required) |
|---|---|---|
| Target W and H | Integers, each ≥ 1 and ≤ 10,000 [Assumption]; UI entry validation belongs to FEAT-005, FEAT-002 re-checks defensively | "Enter a width and height between 1 and 10,000 pixels." |
| Target pixel count | W×H ≤ 24 MP [Assumption, FEAT-004 OQ-4] | "That size is too large for this app. Choose a smaller size." |
| Source pixel count | ≤ 200 MP (Product Owner, 2026-11-20) | "This photo is too large to open on this device. Choose another photo." |
| Source format | Decodable JPEG, PNG, WebP; HEIC/HEIF where the device supports it | "This file type isn't supported on this device. Choose a JPEG or PNG photo." |
| Source integrity | Must decode (header and data) | "We can't read this file. Choose another photo." |
| Source availability | Source must still be readable at render time | "We can't find this photo anymore. Please choose it again." |
| Source smaller than target | Allowed; information up to factor 2.0, confirmation above 2.0 [Assumption] | "This photo is smaller than [W]×[H] px, so it will be enlarged and may look soft." / "This photo is much smaller than needed ([FACTOR]× enlargement) and may look blurry. Continue anyway?" |
| cropRect | Within source bounds, ratio per FR-8, zoom limits per FR-4 | (not shown to the user; clamps silently) |
| Animated source | First frame used | "This image is animated. Only the first frame is used." |
| Orientation value | 1 to 8, else treated as 1 | (no message) |
| Out of memory during render | Handled, not a crash | "This photo is too large for this device. Try a smaller photo." |
| Internal dimension mismatch | Programming error; nothing handed off (FR-16) | "Something went wrong preparing your image. Please try again." |

## 9. Edge cases & error states
| Case | Expected behaviour |
|---|---|
| Signature strip 300×80 (3.75:1) | Frame is a wide strip, visible and ≥ 48 dp high; initial crop is the centred full-width strip of the source; drag is mostly vertical on a landscape photo; output exactly 300×80 |
| Signature strip 140×60 | Same; output exactly 140×60; a tiny result is still handed to FEAT-004 (padding is FEAT-004's job) |
| Extreme ratio such as 1000:10 | Frame still ≥ 48 dp thick (the frame is scaled to fit the screen width, and a min thickness warns of limited on-screen precision); output exactly W×H; non-gesture controls cover fine positioning |
| Square photo, square target | Initial crop is the whole image |
| Portrait source, landscape target (or reverse) | Initial crop is the largest centred area at ratio W:H; the user can move it along the free axis |
| Source smaller than target in both axes | Crop = whole image at cover scale; upscale factor shown (AC-5.1); allowed with warning (FR-11) |
| Source smaller than target in one axis only | Factor on the limiting axis (AC-5.5) |
| Tiny source, such as 1×1 or under 8×8 | Allowed; factor is huge, so confirmation required (> 2.0); output exactly W×H (blurry); no crash |
| Source exactly the target size | Crop = whole image, factor 1.0, no resampling distortion (identity within the pinned algorithm); no notice |
| Transparent PNG | Alpha kept; checkerboard in the crop screen; `hasTransparency` true only if a pixel is not opaque; flattening is FEAT-004's job (FR-12 there) |
| Transparent PNG that is fully opaque | `hasTransparency` false |
| HEIC not decodable | `UNSUPPORTED_INPUT` message, back to selection |
| WebP not decodable or corrupt | `UNSUPPORTED_INPUT` or `CORRUPT_INPUT`, no crash |
| Animated WebP | First frame; user told |
| Camera photo with orientation 6 or 8 | Upright in the preview and in the output; no orientation tag passed on |
| Camera photo already upright but with a bad tag | Treated by the tag (standard behaviour); the user fixes it with manual rotate (FR-21) |
| Photo is sideways even after EXIF (no tag) | Manual rotate (FR-21) fixes it |
| 16-bit, CMYK, grayscale, Display P3 source | Converted to 8-bit sRGB by the platform decoder where supported; otherwise `UNSUPPORTED_INPUT` (FR-10) |
| 50 MP source | Reduced preview; region/sample decode; never below target size (FR-7); no crash |
| Source above 200 MP, or out of memory (for example a 200 MP file that cannot be decoded in parts) | `IMAGE_TOO_LARGE`/`OUT_OF_MEMORY_HANDLED`, with a message |
| Target 24 MP on a low-end device | Either completes or `OUT_OF_MEMORY_HANDLED`, never a crash |
| Target above 24 MP | Refused up front (section 8) |
| Re-crop after a render | New render from the original; pixel-identical to a fresh render (AC-8.2) |
| Same source, cropRect, target, run twice | Identical pixels on the same device (FR-12) |
| Crop frame near system gesture zones | Frame has a ≥ 24 dp [Assumption] margin from screen edges to avoid triggering system back-gesture |
| Source file moved/deleted/permission revoked after selection | `SOURCE_UNAVAILABLE` at render; message to pick again |
| Device rotated or split-screen during crop | State preserved relative to the image (no jump) |
| App backgrounded or killed during crop | Temp files removed on next start; no crop state or source is persisted (privacy); the user starts again |
| Camera temp file | FEAT-001 owns its lifetime; FEAT-002 deletes none of the user's gallery files and only reads |
| User cancels during render | Render stops; temp files deleted; no buffer handed off |
| Rapid double-tap on Continue | Only one render runs (debounced) |
| Very low storage (temp write fails) | Failure message; no partial buffer handed off |
| Source has dimensions that don't match its header (corrupt) | `CORRUPT_INPUT` |
| Corner handle dragged past the image edge | Frame stops at the edge (clamped); no empty area; the opposite corner stays fixed |
| Corner handle shrinks the frame below the minimum crop (FR-4 zoom limit) | Frame stops at the minimum; the upscale notice updates live |
| Handle drag and pinch at the same time | One gesture at a time: the first one to start wins until all fingers lift |
| Very thin strip (for example 300×80 or 1000:10) | Handle touch targets (≥ 48 dp) extend outside the frame so they stay usable and don't overlap; the drag area inside the frame stays usable |
| Extreme zoom-in on a blank area | Allowed until max zoom (FR-4); upscale warning applies |
| Crop frame on a tiny screen (small phone, large font) | Frame stays fully visible; other controls scroll |

## 10. Compliance & data privacy
- **Money / payments involved? PCI-DSS scope?** No. FEAT-002 handles image pixels and integer dimensions only. No card data, tokens or merchant credentials exist in this feature, so there is no PCI-DSS scope. In-app purchases (FEAT-026) are handled by Google Play Billing and are outside this feature.
- **Bangladesh Bank requirements that apply:** None for this feature. It involves no payment instruments, wallets, money movement or financial data. Consistent with the BRIEF compliance scope [Assumption]. Revisit if payment handling is ever added.
- **Personal data collected, purpose, retention, consent:**
  - Photos and signatures are personal data; signatures are identity-sensitive, faces can be biometric-adjacent, and students include minors (children's-privacy flag; the ad SDK exposure is covered by FEAT-025).
  - **On-device only.** No image, crop coordinates, file name or path leaves the device. No network calls in the pipeline (verifiable, FEAT-016).
  - **Original never modified.** FEAT-002 only reads it (FR-17); the crop result is a separate in-app buffer or temp file.
  - **No logging** of pixel data, image content, file names, paths, EXIF values (especially GPS) or crop coordinates, including crash reports and debug output in release builds. Only enumerated outcome codes (FR-24).
  - **EXIF handling:** FEAT-002 reads the orientation value only and holds no other EXIF field in memory or storage. The output buffer carries no metadata, so no source EXIF or GPS can reach the output through this step; stripping guarantees for the final file belong to FEAT-018 (flag: camera photos contain GPS and device data).
  - **Temp files** (preview bitmaps, region decodes, intermediate buffers) are written only to app-private cache, never to shared storage or the gallery, deleted on success, cancel and failure, and swept at app start.
  - **Retention:** none. No recents, thumbnails history or persisted crop state. Crop state lives in memory for the session only. (If FEAT-023 recents is built later, it needs its own privacy review.)
  - **Consent:** no collection, so no consent is needed for this feature. The privacy explainer and store labels (FEAT-016) must stay consistent with the ad SDK's real data collection; FEAT-002 passes no image data to the ad SDK or to analytics.
  - **Screenshots and recents:** the crop screen shows an identity photo, so it is hidden from the Android recent-apps thumbnail on Android 13+ (FR-26). Screenshots are not blocked (no FLAG_SECURE), so users and testers can still capture the screen; older Android versions get no protection here (decided 2026-11-19, OQ-8).
  - **Test data:** tests and docs use synthetic images and `[PLACEHOLDER]` values, never real people's photos or signatures.

## 11. Dependencies
- **FEAT-001** (hard): source handle with read access, plus lifetime of any camera temp file.
- **FEAT-005 / FEAT-011** (hard): target W×H.
- **FEAT-004** (downstream, approved contract): consumes the pixel buffer and flags; see section 1. Follow-up: FEAT-004 FR-13 / AC-5.2 (unsupported source formats) really describe decoding, which FEAT-002 owns. Clarify in a FEAT-004 v1.1 when convenient; no behaviour changes.
- **FEAT-006:** consumes `cropRect`, `upscaleFactor` and outcome for preview. **FEAT-008:** later adds fit/pad on top of FEAT-002's fill. **FEAT-016:** verifies no network and the privacy copy. **FEAT-018:** owns metadata stripping in the output. **FEAT-019:** supplies the 6-language translations. **FEAT-020/021:** later features may reuse the crop screen.
- **Stage 6:** resampling algorithm and colour-space ADR; decode library choice (region decode, HEIC/WebP support, ICC handling); Flutter plugin versus native split for large images; re-estimate effort (OQ-9); minSdk (FEAT-004 OQ-10).
- **Content:** native-speaker review of the crop-screen messages (Phase B exit).

## 12. Open questions
- [x] **OQ-1 — decided 2026-11-19: accepted as Should (FR-21).** Manual 90° rotate in the crop screen (Should, FR-21, US-12).** Camera photos are often sideways even after EXIF correction. Pro: avoids leaving the app; small UI cost. Con: more UI and test surface; adds effort. This PRD proposes Should; not decided.
- [x] **OQ-2 — decided 2026-11-19: keep notice above 1.0 and confirmation above 2.0.** Upscale thresholds. Information notice above 1.0 and confirmation above 2.0 [Assumption]. Should the threshold be different (for example warning only above 1.5, hard limit above 4)? Needs a visual test on real small sources.
- [x] **OQ-3 — decided 2026-11-19: keep the read URI, no copy.** Source-handle lifetime (FEAT-001). Does FEAT-001 copy the picked image into app-private cache (stable re-crop, but an extra personal-data copy to clean up) or keep a read URI (no copy, but `SOURCE_UNAVAILABLE` risk)? Proposed default: keep the read URI, no copy.
- [x] **OQ-4 — closed 2026-11-20: no ICC profile, decided in FEAT-004 (OQ-6).** ICC profile in the output file. FEAT-002 converts to sRGB (this PRD). Does the output embed an sRGB ICC profile or no profile? Bytes count toward KB (FEAT-004 FR-14), so FEAT-004/FEAT-018 must decide; FEAT-002 proposes no profile (untagged sRGB is the web default) [Assumption].
- [x] **OQ-5 — decided 2026-11-19 (revised the same day): proportional corner handles ARE in R1 as a Should (FR-28, US-13); the ratio stays locked to W:H. An earlier same-day decision of "no handles in R1" is superseded.** Crop handles. BRIEF/UX favours image-moves-under-fixed-frame. Should R1 also have corner handles that resize the frame proportionally? Proposed default: no handles in R1 (the frame is fixed; zoom is the control); if added, it is a Could.
- [x] **OQ-6 — decided 2026-11-20: no extra lower bound in FEAT-002 (1–10,000 px per side, ≤ 24 MP); FEAT-005 may show a soft hint.** Maximum target bound. 24 MP [Assumption] follows FEAT-004 OQ-4. Is a lower bound (for example W,H ≥ 16 px) needed, and who owns it (FEAT-005)?
- [x] **OQ-7 — decided 2026-11-19: never in R1.** Brightness/contrast adjustment. Not in scope or proposed (BRIEF excludes general editing). Listed only so the Product Owner can confirm "never in R1" or ask for a later feature.
- [x] **OQ-8 — decided 2026-11-19: hide from recents on Android 13+ without blocking screenshots (FR-26).** Hide the crop screen from the Android recent-apps thumbnail (FLAG_SECURE-style).** Privacy gain for identity photos versus tester inconvenience (blocks screenshots). Decide with FEAT-016.
- [x] **OQ-9 — decided 2026-11-20: Should items stay in R1 (ROADMAP v1.2).** Effort. Stage 6 re-estimate 2026-11-20: about 4.7 pw (range 4.0–5.5), of which about 0.7 pw is Should items (handles, rotate, nudge buttons). Whether to keep the Shoulds in R1 is decided in the roadmap update. Roadmap gives 1.3 pw. This scope (EXIF, region decode of large images, colour conversion, accessible crop UI, 6 languages, rotate, corner handles about +0.4 pw [Assumption]) probably exceeds it. Re-estimate in Stage 6; impact on the 20.2 pw plan to be shown to the Product Owner.
- [x] **OQ-10 — closed 2026-11-20: native in-memory buffer, ADR-003.** Pixel handover format to FEAT-004. In-memory buffer versus app-private raw temp file at 24 MP (about 96 MB at 4 channels). Architecture decision; the contract in section 1 does not change.
- [x] **OQ-11 — decided 2026-11-20: FEAT-002's source probe is the single implementation; FEAT-001 calls it right after picking.** Who probes the source first. Does FEAT-001 do the header/decodability probe on selection, or FEAT-002 (this PRD)? FEAT-004 AC-5.2 says the message shows "when it is selected".
- [x] **OQ-12 — decided 2026-11-20 (Product Owner, option A): same-device determinism (Must) means same device and OS build; cross-device stays Should; no bundled decoders.** Cross-device determinism. FR-12 makes this Should, because OS decoders differ; a bundled decoder would make it Must but adds app size.
- [x] **OQ-13 — decided 2026-11-20: `rotationApplied` means manual rotation only.** EXIF orientation is applied inside FEAT-002 and never passed on (FR-3, FR-19); `cropRect` is in the space after EXIF and manual rotation.
- [x] **OQ-14 — decided 2026-11-20: extreme ratios use a full-width true-ratio frame with a ≥ 48 dp touch band (FR-4).** Output stays exact.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-19 | First draft |
| 0.2 | 2026-11-19 | Scope trims (platform sRGB decode, no linear-light/PSNR, nudge buttons Should via FR-27); OQ-1/2/3/5/7/8 decided; FR-26 recents protection; FEAT-004 clarification follow-up noted |
| 0.3 | 2026-11-19 | OQ-5 revised: proportional corner handles added as Should (US-13, FR-28, edge cases); effort about +0.4 pw [Assumption] |
| 1.0 | 2026-11-19 | Approved by Product Owner |
| 1.1 | 2026-11-20 | Source ceiling raised from 100 MP to 200 MP, best effort (FR-6, NFR-8, section 8, edge cases). Under Discussion until re-approved |
| 1.1 | 2026-11-20 | Re-approved by Product Owner |
| 1.2 | 2026-11-20 | Clarification after Stage 6: FR-12 same device means same OS build (OQ-12); `rotationApplied` manual only (OQ-13); FR-4 extreme ratios (OQ-14); OQ-4, 6, 10, 11 closed per FEAT-002-TECH; OQ-9 effort noted. Under Discussion until re-approved |
| 1.2 | 2026-11-20 | Re-approved by Product Owner |
| 1.3 | 2026-11-20 | Test environment note: emulators only (2 GB RAM profile), timing targets best effort, no physical low-end device (Product Owner). OQ-9 ticked: Shoulds stay in R1 (decided 2026-11-20). Under Discussion until re-approved |
| 1.3 | 2026-11-20 | Re-approved by Product Owner |
