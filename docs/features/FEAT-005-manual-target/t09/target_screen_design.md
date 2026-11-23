---
id: FEAT-005-T09-DESIGN
title: Target screen — lean design (impeccable, gate G1)
status: Proposed
version: 0.1
updated: 2026-11-23
links: [FEAT-005, FEAT-005-TECH, FEAT-005-TASKS, FEAT-001-T16-DESIGN, FEAT-002-T22-DESIGN, PRODUCT.md]
---

# Target screen — lean design

Lean impeccable path (CLAUDE.md Budget): one short pass on Material 3, no image comps, no reviewer subagents, one round. Claude builds it in Flutter (T12–T14) and the Product Owner reviews five emulator screenshots at gate G2 (T15).
- **Mode:** Operate (form entry, speed first).
- **Platform:** Android, Material 3, portrait phone; scrolls.
- **Product Owner answers (2026-11-23, all defaults):** OQ-1 session memory only; OQ-3 JPEG preselected; OQ-7 "Use photo size" shown; OQ-10 FEAT-005 screen works alone, with room for a FEAT-011 preset entry above the fields.

## Direction: the order slip at the booth
Same world as the pick screen (front of the booth) and the crop screen (inside the cabin), from `lib/ui/booth.dart`. Between them sits the order slip: you write the size the form asks for, then step inside.
- Curtain-maroon shell; the fields sit on one darker **plate** (`Booth.plate`), like the booth's control plate.
- Numbers typed in the field use the condensed spec face with tabular figures (`BarlowCondensed`), so what you type looks like the print spec you will get.
- One flash-amber key: **Continue**. Everything else is chrome-pale or text keys.
- Notices and errors use `BoothNotice` style: icon plus text on the notice tone, never colour alone.
- Fixed palette in both themes (the booth is the same day or night); every text pair already meets WCAG AA.

## Layout (top to bottom, reading order = focus order = TalkBack order)
1. **App bar:** Back (start-over, releases the photo, T01 guard) and no title text; the screen header below carries the meaning.
2. **Photo line:** "Your photo: 4000×3000 px" (oriented size, isolated digits) in body text, with **Use photo size** as a text key at the end of the same line; it wraps below at large font. Hidden key when the photo is not a valid target (FR-12).
3. **Preset slot (empty in FEAT-005):** no widget now; the column keeps a top slot so FEAT-011 can add a preset row without moving the fields (OQ-10).
4. **Size plate** (`Booth.plate`, 16 dp radius, 16 dp padding):
   - **Width** and **Height** side by side, a "×" between them; each `TextField` with the label, suffix unit "px", number keypad, LTR digits. Below 360 dp width or at font scale ≥ 1.5 the row becomes a column (no "×").
   - **Minimum size** with suffix "KB" and helper text "Optional", then **Maximum size** with suffix "KB" (required; no asterisk). Order W, H, Min, Max as fixed by FR-3 and FR-8. Min and Max sit side by side on wide layouts, stacked otherwise.
   - **Format:** label "Format", then a `SegmentedButton` JPEG | PNG, single select, never empty, chrome-pale selected segment with a check icon.
5. **Hints** (between the plate and Continue, polite live region, non-blocking):
   - enlarge notice (reused `cropNoticeEnlarged`) with an info icon;
   - very-small notice with an info icon.
6. **Continue:** full-width flash-amber key, 56 dp, always enabled (FR-8), at the end of the scroll content (not pinned over the keyboard, so it never hides a field). The scroll view keeps the focused field and Continue reachable (`Scrollable.ensureVisible` on focus, bottom padding = keyboard inset).

## States
- **Empty (fresh):** fields empty, JPEG selected, no errors, photo line shown.
- **Filled / valid:** typed numbers in the spec face; no messages.
- **Error:** each refused field shows the error text under it with an error icon (`InputDecoration.error` with an icon row, not colour alone); all errors at once after Continue; focus moves to the first refused field (W, H, Min, Max) and TalkBack reads its error (T13).
- **Hints shown:** notices between the plate and Continue; they never block Continue.
- **Crop step decode (T10, new states on the crop route):**
  - progress after 500 ms: cabin-dark background, centred spinner and "Opening your photo…" (reuse of the pick string if its wording fits; otherwise T10 notes a new key);
  - decode error: `BoothNotice` with the `CropMessages.reason` text, then one chrome key "Choose another photo" (release, end crop, back to the pick screen).

## Accessibility and locale
- Labels carry the unit and required/optional for TalkBack: "Width, pixels", "Minimum size, kilobytes, optional".
- Touch targets ≥ 48 dp; fields 56 dp high.
- 200% font at 360×640 with the keyboard open: the whole screen scrolls, W/H becomes a column, nothing clips, Continue stays reachable.
- RTL (ar): layout mirrors; field text stays LTR digits 0–9; numbers in messages are in U+2068/U+2069 isolates (T08). The "×" between W and H mirrors with the row.

## Verification screenshots for G2 (T15)
API 36.1 emulator, synthetic image only, no real faces or signatures:
1. `empty.png` — fresh screen, JPEG selected.
2. `valid.png` — 300 × 300 px, Max 100 KB.
3. `error.png` — all fields refused after Continue (longest English messages).
4. `arabic.png` — error state in ar, RTL.
5. `font200.png` — 200% font, 360×640, keyboard open.

## Out of scope here
- Translations (T16, `/l10n-translate`, AI-reviewed only).
- Presets (FEAT-011), saved specs (FEAT-012), DPI (FEAT-010).
