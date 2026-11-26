---
id: FEAT-006-T10-DESIGN
title: Check screen (result screen success branch) — lean design (impeccable, gate G1)
status: Proposed
version: 0.1
updated: 2026-11-26
links: [FEAT-006, FEAT-006-TECH, FEAT-006-TASKS, FEAT-007-T17-DESIGN, PRODUCT.md]
---

# Check screen — lean design

Lean impeccable path (CLAUDE.md Budget): one short pass on Material 3 and the existing Booth theme (`lib/ui/booth.dart`), no image comps, no reviewer subagents, one round. Claude builds it in Flutter (T11–T12); the Product Owner reviews the G2 phone screenshots (T14). All content synthetic.
- **Mode:** Operate (read a verdict, then act). **Platform:** Android, Material 3, portrait phone; the page scrolls.
- **Scope limits (PRD):** only the success branch of the result screen changes (FR-20). The running and failure branches, `ExportPanel` and the leave dialog stay exactly as FEAT-007 shipped them. No zoom or pan on the preview (FR-17), no new strings beyond T06.

## Direction: inspecting the print at the pickup slot
Same booth world as pick, target, crop and the FEAT-007 pickup slot. Before you take the print home you hold it under the light and check it against the order slip: the print sits on the dark plate, and below it the slip lists what you ordered next to what you got, each line stamped "Meets".
- Curtain-maroon shell, darker `Booth.plate` surfaces, one flash-amber key (Save, inside the unchanged panel).
- Target and measured values use the spec face (`BarlowCondensed` 600, tabular figures), like the ready line and the crop screen's spec cells, so the numbers read as a print spec.
- Status is always icon plus word (NFR-2). Meets: `check_circle` in flash amber plus "Meets". Doesn't meet: `cancel` plus "Doesn't meet" on a `Booth.notice` pill. Fixed palette in both app themes; every text pair is an existing Booth pair that already meets WCAG AA; no text drawn with alpha.

## Matches (`CheckMeets`)
Reading order = focus order = TalkBack order (FR-7). 24 dp page padding, 16 dp between blocks.

```
┌──────────────────────────────────┐
│ ←                                │  app bar, no title (Back = leave flow)
│ ┌──────────────────────────────┐ │
│ │        ┌──────────┐          │ │  1 preview stage (Booth.plate)
│ │        │  image   │          │ │    box at measured aspect, ≤ 40% screen
│ │        └──────────┘          │ │    height, ≤ 4 device px per image px
│ │ Shown scaled to fit your …   │ │    caption, centred
│ └──────────────────────────────┘ │
│ ✔ Matches your target            │  2 headline (live region)
│ ┌──────────────────────────────┐ │
│ │ Size in pixels       ✔ Meets │ │  3 spec slip (Booth.plate), 3 rows
│ │ Target       This file       │ │
│ │ 300 × 300 px 300 × 300 px    │ │
│ │ ──────────────────────────── │ │
│ │ File size            ✔ Meets │ │
│ │ 20.0–50.0 KB 48.2 KB         │ │
│ │ Also fits if your portal …   │ │    1,024 line (not narrow only)
│ │ ──────────────────────────── │ │
│ │ Format               ✔ Meets │ │
│ │ JPEG         JPEG            │ │
│ └──────────────────────────────┘ │
│ ⓘ Padding was added to reach …   │  4 notices (BoothNotice, one per item)
│ We check pixels, KB and format…  │  5 caveat line
│ ┌──────────────────────────────┐ │
│ │ [ Save ]  [ Share ]  …       │ │  6 ExportPanel on its plate, unchanged
│ └──────────────────────────────┘ │
│              Done                │  7 Done (text key)
└──────────────────────────────────┘
```

1. **Preview stage.** Full-width `Booth.plate` container, radius 16, padding 16. The image box is centred; its size comes from the **measured** W×H (not the bitmap): `scale = min(contentWidth / w, 0.4 × screenHeight / h, 4 / devicePixelRatio)`, box = (w × scale, h × scale). Named constants `kPreviewMaxHeightFraction = 0.4`, `kPreviewMaxDevicePxPerPx = 4`. `RawImage` with `BoxFit.contain`, `FilterQuality.medium` for downscale only, no overlay, no filter. A 1 dp hairline in `Booth.text` at 30% sits **outside** the box (frame of the print, not on the image). Transparent PNG: `paintCheckerboard` under the image, clipped to the box (FR-15). Semantics: one image node labelled `previewAlt` ("Preview of your new file, 300 × 300 px, JPEG."). No gesture detector, so a drag on the preview scrolls the page (FR-17). Caption `previewCaption` below, `bodySmall`, centred, excluded from semantics duplication (it is read once, in order).
2. **Headline.** Row: `check_circle` 28 dp flash amber (decorative) + "Matches your target" in `headlineSmall`, `Booth.text`. Wrapped in `Semantics(liveRegion: true)`: the verdict is announced once (NFR-2). Never says "accepted" or "guaranteed" (FR-7).
3. **Spec slip.** `Booth.plate`, radius 16, padding 16; three rows in fixed order (Size in pixels, File size, Format), separated by 1 dp dividers (`Booth.text` 20%). Each row:
   - Line 1: label in `titleSmall` at start; status at end (icon 20 dp + word in `labelLarge`). Built as a `Wrap` so at large font the status drops under the label instead of clipping.
   - Line 2: two cells in a `Wrap` (spacing 24, run spacing 8): small caption "Target" over the target value, small caption "This file" over the measured value. Values in the spec face, 20 sp. At 200% font the cells stack.
   - File size only, line 3: the 1,024 line (`checkAlsoFits1024`) in `bodySmall` when the window is not narrow (FR-8).
   - Semantics: the whole row is one node, `label: rowSentence`, `excludeSemantics: true` (AC-8.2).
4. **Notices.** One `BoothNotice` per `success.notices` item, FEAT-004 text via `OutcomeMessages.notice`, `info_outline` icon (narrow range: `warning_amber`). None → no widget (FR-18).
5. **Caveat.** `checkCaveat` in `bodySmall`, `Booth.text`, no icon (the panel already uses the info icon for its hint).
6. **Export panel.** The existing plate with `ExportPanel(success:, size: spec.dimensions)` exactly as now; the FEAT-007 "Ready:" line above it is removed (FR-20, T13).
7. **Done.** Existing text key; same leave flow as Back (FR-21).

### Preview unavailable (`CheckMeets`, image null)
Same stage, min height 120 dp: `image_not_supported_outlined` icon 32 dp plus `previewUnavailable` text, centred, no caption. Headline, slip, notices, caveat, panel unchanged (FR-14, AC-4.4).

## Checking (`Checking`)
Centred `CircularProgressIndicator` in the space where the preview stage will be; nothing else, no "matches" text (FR-1). It lasts ≤ 500 ms median (G0: under 100 ms on the Realme 2 Pro). Back runs the FEAT-007 leave flow. No new string (see question 2).

## Does not match (`CheckMismatch`, forced only)
1. **Headline:** `BoothNotice` with `error_outline` and `checkMismatch` ("This file doesn't match your target, so it can't be saved or shared. Go back and try again."), in the live region.
2. **Spec slip:** the same three rows with measured values; failing rows show the "Doesn't meet" pill. The 1,024 line is hidden here (question 3).
3. **Back:** one full-width chrome key (`FilledButton.tonal`, Material "Back" label, same as the FEAT-004 failure branch), pops to the crop step with photo and target kept (FR-10).
No preview, no caveat, no panel, no export-anyway control.

## Unreadable (`CheckUnreadable`, forced only)
`BoothNotice` with `error_outline` and FEAT-007's `exportFileMissing` text (live region), then one full-width chrome key that runs `leave()` with no confirm and opens the pick screen (FR-11). Label: reuse `cropButtonChooseAnother` "Choose another photo" (question 1). No check, no panel.

## Accessibility and locale
- Keys ≥ 48 dp (Back and Choose another photo 56 dp, like FEAT-007). Icons decorative; status words carry the meaning.
- One live region for the verdict besides the panel's own (AC-8.2).
- 200% font at 360×640: page scrolls; row status and value cells wrap; no clipping or horizontal scroll; Save, Share and Done reachable by scrolling (AC-8.1).
- RTL (ar): layout mirrors (label start, status end); numbers, `px`, `KB` and format names stay inside the LTR isolates `CheckMessages` already adds; Western digits 0-9 (AC-8.3).
- Recents protection: the whole route inside `RecentsGuard` (FR-19, T12).

## Questions for the Product Owner (G1)
1. **Unreadable key label:** reuse "Choose another photo" (goes to the pick screen, matches the message "Choose the photo again"). Alternative: "Done". Default: "Choose another photo".
2. **Checking state:** spinner only, no text (no new string; it lasts under 0.1 s on the Realme). Alternative: add a "Checking your file…" string (new key, translated in T16). Default: spinner only.
3. **1,024 line on a mismatch:** hide it there, because "Also fits…" next to a failing size reads like a contradiction. FR-8 does not name the state; this narrows a Should. Default: hide on mismatch, show on matches.

## Verification screenshots for G2 (T14)
Realme 2 Pro (API 36), from `integration_test/result_screen_demo.dart`, synthetic images only (no faces, no signatures), the fake measurer forcing the bad states:
1. `matches_padding.png` — JPEG 300×300, padding notice.
2. `matches_png.png` — transparent PNG over the checkerboard.
3. `preview_unavailable.png` — forced out of memory.
4. `mismatch.png` — forced size mismatch.
5. `unreadable.png` — forced missing file.
6. `arabic.png` — matches in ar, RTL.
7. `font200.png` — matches at 200% font.
