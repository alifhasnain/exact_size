---
id: FEAT-001-T16-DESIGN
title: Pick screen — lean design (impeccable, gate G3)
status: Proposed
version: 0.1
updated: 2026-11-22
links: [FEAT-001, FEAT-001-T16-CHECKLIST, FEAT-002-T22-DESIGN, PRODUCT.md]
---

# Pick screen — lean design

This follows the lean impeccable path (CLAUDE.md Budget): Claude designs on Material 3 and builds in Flutter, and the Product Owner reviews emulator screenshots and approves gate G3.
- **Mode:** Operate.
- **Platform:** Android, Material 3.
- **Flow:** photo first (OQ-4), so this is the app's start screen.

## Direction: the front of the booth
The Product Owner chose this on 2026-11-22. The pick screen is the outside of the ID photo booth whose inside is the crop screen (FEAT-002-T22). It uses the same world and palette, now shared in `lib/ui/booth.dart`:
- the curtain-maroon shell;
- a darker lit cabin window, with the booth light falling from above;
- one flash-amber key and chrome-pale keys;
- the condensed spec cell.

The palette is fixed in both themes, and every text pair meets WCAG AA.

## Layout (portrait phone, scrolls)
1. **Brand cell:** the app name in the Barlow Condensed spec cell, at the top start, marked as a header.
2. **Cabin window,** centred vertically. Its content depends on the state:
   - **Notice:** when there is a refusal, an icon and text in the notice tone, as a polite live region.
   - **Take a photo:** the flash-amber key, 64 dp high, with a camera icon. When no camera app exists it is disabled, with an info icon and the reason as text below it.
   - **Choose from gallery:** a chrome key, 64 dp high, with a gallery icon.
   - **Choose from files** (Should): a text key with a folder icon.
   - **Opening:** after 500 ms, the cabin shows a spinner, "Opening your photo…" and Cancel in place of the keys.
3. **Privacy plaque:** a lock icon and the privacy line, at the bottom.

The TalkBack order follows the reading order: Take a photo, Choose from gallery, Choose from files, privacy line (AC-7.1).

## Behaviour
- **RTL:** the layout and text mirror; the camera and gallery icons do not (they don't follow text direction).
- **200% text:** the whole screen scrolls, nothing is clipped, and the keys grow.
- **Out of the view, done in T17:**
  - focus returns to the button used;
  - routing to the target step;
  - a landscape check.

## Screenshots for review
The screenshots are in `t16/`, side by side in `review_sheet.png`. They come from the API 36.1 emulator, using a profile build of `integration_test/pick_screen_demo.dart`. The screen shows no photos.
- `idle.png`
- `nocamera.png`
- `message.png` (the longest English message)
- `opening.png`
- `arabic.png` (the message state in RTL)
- `font200.png` (the low-space message at 200%)

## Known limits
- At 200% the button icons stay at 24 dp while the text grows. T17 may scale them with the text.
- The spinner in `opening.png` was captured early in its animation, so it looks like a dot.
