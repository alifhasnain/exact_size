---
id: FEAT-002-T22-DESIGN
title: Crop screen — lean design (impeccable, gate G3)
status: Proposed
version: 0.1
updated: 2026-11-21
links: [FEAT-002, FEAT-002-T22-CHECKLIST, PRODUCT.md]
---

# Crop screen — lean design

The Product Owner chose the lean impeccable path on 2026-11-21 (see the CLAUDE.md Budget section). Claude designs on Material 3 and builds in Flutter. The Product Owner reviews emulator screenshots of the states below and approves gate G3. Mode: Operate (finish a task). Platform: Android, Material 3.

## Direction
- **The photo is the content; the chrome is quiet.** The canvas has a fixed near-black background in both themes, so photos and the frame keep contrast whatever the theme. Controls sit on the normal Material surface below the canvas; in landscape they sit to the side.
- **One primary action:** Continue, a filled button at the bottom end. Everything else is tonal or text.
- **The colour seed is a placeholder** (teal), because PRODUCT.md has no brand colours. Every colour comes from a Material colour role, so a later brand only changes the seed.

## Layout (portrait phone, 360 dp wide)
1. **Top app bar:** Back, and the target size as the title (for example "300 × 80 px", inside isolates).
2. **Canvas** (fills the rest):
   - the preview is painted upright under one matrix;
   - the frame is fixed and centred, at the W:H ratio, with at least 24 dp side margins;
   - outside the frame is dimmed to 60% black;
   - the frame outline has two tones: 1 dp black outside and 2 dp white inside;
   - white L-shaped corner brackets with a dark outline show where the handles are;
   - a checkerboard shows under transparent sources.
3. **Notice line,** only when needed: tonal container, icon plus text, polite live region. Kinds: enlarged (info icon), strong enlargement (warning icon), animated source, thin-frame hint.
4. **Tool rows:**
   - rotate counter-clockwise and clockwise;
   - zoom out and in;
   - move left, up, down and right (always in physical order, never mirrored; long-press repeats).
   These are 48 dp tonal icon buttons with tooltips and accessibility labels. They wrap to two rows on narrow screens.
5. **Bottom row:**
   - start side: Centre and Reset (text buttons);
   - end side: Continue (filled).

## Behaviour
- **Gestures:** one finger drags the photo; two fingers pinch about the focal point. The first gesture wins until every finger lifts.
- **Extreme ratios (frame shorter than 48 dp):** the frame is full width at its true ratio and the thin-frame hint shows.
- **RTL:** the app bar, the button rows and Continue mirror. The canvas, the handles and the move buttons keep physical directions.
- **200% text:** the controls area scrolls, takes at most half the height, and the frame stays visible.
- **Landscape and split-screen:** the canvas sits on the start side and the controls in a 320 dp side panel. The crop state is unchanged; only the view re-fits.
- **Progress, dialog and errors** (T24, T25): a Material dialog for strong enlargement; progress after 500 ms with Cancel; each error gets one message and one action.

## Screenshots for review
In `t22/` (synthetic images only), all side by side in `review_sheet.png`. Emulator API 36.1, debug build, from `integration_test/crop_screen_demo.dart`:
- `normal.png`
- `signature.png` (transparent PNG, 300×80)
- `enlarged.png`
- `strong.png` (strong enlargement plus the animated notice)
- `extreme.png` (1000×10)
- `arabic.png` (English text in RTL until FEAT-019)
- `font200.png`

Landscape and split-screen are not captured yet; T26 covers them with widget tests.
