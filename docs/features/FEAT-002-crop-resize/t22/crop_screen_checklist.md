---
id: FEAT-002-T22-CHECKLIST
title: Crop screen — design checklist for the Product Owner (gate G3)
status: Proposed
version: 0.1
updated: 2026-11-21
links: [FEAT-002, FEAT-002-TECH, FEAT-002-TASKS]
---

# Crop screen — what the design must cover (gate G3)

Non-visual input for the Product Owner's design session in impeccable (https://github.com/pbakaus/impeccable). This lists the states, elements, constraints and strings the PRD requires. It contains no layout, colour or mock-up. Use synthetic images only in the design file (no real faces or signatures).

The engine behind the screen is built and tested (T05–T21): crop maths, gestures as pure reducers, preview decode, render, TalkBack actions and announcements, strings.

## 1. Elements
| Element | Requirement | Source |
|---|---|---|
| Preview image | Display-only decode, long side ≤ 2048 px, painted upright (EXIF and manual rotation applied by the app); moves and scales under a fixed frame | FR-4, FR-7, FR-25 |
| Crop frame | Ratio exactly W:H; fully visible; ≥ 48 dp on its short side; ≥ 24 dp side margins; two-tone outline readable on any photo (WCAG AA) | FR-4, NFR-4 |
| Outside the frame | Dimmed | tech.md section 3 |
| Checkerboard | Under transparent areas of PNG/WebP sources | FR-14 |
| Corner handles (Should) | Four, physical corners; touch targets ≥ 48 dp, may extend outside the frame, pushed outward when the frame is < 96 dp so they never overlap | FR-28, AC-13.6 |
| Centre, Reset (Must) | Visible buttons, ≥ 48 dp, labelled | FR-5, AC-9.2 |
| Move ×4, Zoom in/out (Should) | Visible buttons, ≥ 48 dp, labelled; long-press repeats; move step 5% of the crop | FR-27 |
| Rotate clockwise / counter-clockwise (Should) | Visible buttons | FR-21 |
| Upscale notice | Shown when the enlargement is above 1.0; icon plus text (never colour alone); updates live while zooming | FR-11, AC-5.1, AC-5.4 |
| Enlargement confirmation | Dialog at Continue when above 2.0: "Continue anyway" / "Choose another photo" | FR-11, AC-5.3 |
| Animated-image notice | When the source is animated (first frame used) | PRD section 8 |
| Thin-frame hint and touch band | Extreme ratios (beyond about 6.5:1 in portrait, e.g. 1000:10): true-ratio frame at full width with a ≥ 48 dp touch band and the hint pointing to the buttons | FR-4, tech.md OQ-14 |
| Continue | Starts the render | US-2 |
| Progress | Shown only when the render takes over 500 ms; cancellable | FR-18 |
| Error states | One message plus one next action (choose another photo) per reason | PRD section 8 |

## 2. States to design
1. Normal: frame over a photo, no notice.
2. Enlarged (factor 1.0–2.0): notice visible.
3. Strong enlargement (> 2.0): notice visible; confirmation dialog after Continue.
4. Transparent source: checkerboard visible.
5. Animated source: notice visible.
6. Signature strip 300×80 on a portrait photo (wide frame, all four handles reachable).
7. Extreme ratio 1000:10 (thin frame, touch band, hint).
8. Rendering (progress after 500 ms, cancel).
9. Each error: too large, unsupported type, can't read, photo gone, out of memory, something went wrong.
10. Arabic (RTL), 200% font, landscape, split-screen.

## 3. Rules the layout must keep
- **RTL (FR-23, AC-10.2):** control rows, button order, back and Continue mirror; the photo, frame, handles and move directions keep physical directions ("Move left" always moves toward the physical left).
- **Accessibility (NFR-4):** every action has a non-gesture equivalent; targets ≥ 48 dp; text scales to 200%; notices use icon and text; overlays meet WCAG AA contrast on any photo.
- **Rotation and split-screen (FR-20, Should):** the crop is kept; only the view re-fits.
- **One gesture at a time:** drag, pinch or handle; the first to win holds until all fingers lift.
- **Privacy:** the screen is hidden from the recent-apps thumbnail on Android 13+ (built, T19); screenshots stay allowed.

## 4. Strings (English, from `lib/l10n/app_en.arb`)
Messages from the PRD: target out of range, target too large, photo too large, unsupported type, can't read, photo gone, out of memory, something went wrong, enlarged notice, enlargement confirmation, animated notice.

Wording written by the developer, to be approved by the Product Owner:
- "Cancelled. Your photo was not changed."
- "The frame is very thin on screen. Use the move and zoom buttons for fine positioning."
- "The photo no longer needs enlarging." (screen reader)
- "Strong enlargement ([FACTOR]×). You will be asked to confirm before continuing." (screen reader)
- Buttons: Centre, Reset, Move left/right/up/down, Zoom in/out, Rotate clockwise/counter-clockwise, Continue, Continue anyway, Choose another photo.
- Screen reader: "Crop area, zoom [PERCENT], showing the centre / top / … of the photo"; "Reached the left edge."; "Resize crop, top-left corner".

## 5. What the Product Owner returns
The impeccable design reference (file or link, synthetic images only) and the approval date. That records gate G3, after which T23–T28 (the screen itself) start.
