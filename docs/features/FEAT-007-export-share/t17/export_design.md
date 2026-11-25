---
id: FEAT-007-T17-DESIGN
title: Result screen and export panel — lean design (impeccable, gate G1)
status: Proposed
version: 0.1
updated: 2026-11-24
links: [FEAT-007, FEAT-007-TECH, FEAT-007-TASKS, FEAT-005-T09-DESIGN, PRODUCT.md]
---

# Result screen and export panel — lean design

Lean impeccable path (CLAUDE.md Budget): one short pass on Material 3, no image comps, no reviewer subagents, one round. Claude builds it in Flutter (T18–T20); the Product Owner reviews the G2 phone screenshots (T20). All content synthetic.
- **Mode:** Operate (two actions, speed first). **Platform:** Android, Material 3, portrait phone; scrolls.
- **Scope limits (PRD):** no image preview and no "meets spec" claim (FEAT-006 owns both, FR-29); no ads, no account, no history.

## Direction: the pickup slot
Same booth world as the pick screen (front of the booth), the order slip (target step) and the cabin (crop), from `lib/ui/booth.dart`. After the cabin, the print drops into the pickup slot: you take it home (Save) or hand it over (Share).
- Curtain-maroon shell; the result and the actions sit on one darker **plate** (`Booth.plate`).
- The ready line uses the condensed spec face (`BarlowCondensed`, tabular figures), so the delivered size reads like the print spec.
- One flash-amber key: **Save**. **Share** is a chrome-pale key. Everything else is a text key.
- Messages use the `BoothNotice` look: icon plus text on the notice tone, never colour alone. Fixed palette in both themes; every text pair already meets WCAG AA.

## Result screen (temporary, replaces the dev stand-in; FEAT-006 takes it over)
Reading order = focus order = TalkBack order.
1. **App bar:** Back, no title. Back runs the same leave flow as Done.
2. **Running:** centred spinner, the existing FEAT-004 progress text (polite live region), one chrome key **Cancel** (existing behaviour: cancels and returns to the crop step).
3. **Failure:** `BoothNotice` with the FEAT-004 outcome message (existing `OutcomeMessages`), one chrome key **Back** to adjust the size (pops to the crop step). No Save or Share (FR-1).
4. **Success:** the **ready line** on the plate, "Ready: 300 × 300 px, 48.2 KB, JPEG" (spec face, isolated numbers), then the export panel.

## Export panel (self-contained; FEAT-006 embeds it later)
Inside the plate, below the ready line:
1. **Save** — full-width flash-amber key, 56 dp, download icon. While a save runs for more than 500 ms it shows a small spinner and the label "Saving…" and is inactive (label change, not colour alone). Taps while busy do nothing (FR-12).
2. **Share** — full-width chrome key, 56 dp, share icon. Under it the **chat hint** (FR-21) in small text with an info icon.
3. **Message** (polite live region, stays until the user leaves; the next action replaces it):
   - saved / already saved: check or info icon, "Saved to Pictures/ExactSize as exactsize-300x300-a1b2c3.jpg." The folder and the file name are each one LTR isolate and never break inside (wrap only at spaces around them).
   - errors (no space, save failed, file missing, share failed): error icon plus the PRD text.
   - permission denied (API 28): error icon plus text, and below it the text key **Choose where to save** (FR-10; shown only after a refusal, OQ-T2).
   - no viewer: info icon plus text.
   - After Share or a closed save-as dialog: no message (FR-19).
4. **Open** — text key with an open-in icon, shown only after a save (FR-15), placed right under the saved message.
5. **Privacy line** (FR-26) — one plain line in small text at the bottom of the plate.
6. **Done** — chrome text key below the plate; leaves the result (same as Back).

Wide or large-font layout: the keys always stay stacked full width (simplest at 200% font); the message and hint wrap.

## Leave dialog (FR-23)
Shown on Back or Done only when nothing was saved and nothing was shared. Material 3 `AlertDialog` on the plate tone: title "Leave without saving?", body "The new file will be deleted. Your gallery photos stay as they are.", actions **Stay** (focused first) and **Leave**. Leave waits for a running save (FR-24), deletes the share copy and the temp file, then returns to the pick screen. After a save or a share, Back and Done leave at once.

## Accessibility and locale
- Each key ≥ 48 dp (Save and Share 56 dp); labels are verbs; icons are decorative.
- One live-region announcement per save result (NFR-2); Save's busy state is announced by its label change.
- 200% font at 360×640: the screen scrolls, nothing clips, the message wraps, Save and Share stay full width.
- RTL (ar): the layout mirrors; the file name and folder stay LTR and unbroken; numbers in the ready line are isolated, Western digits.

## Questions for the Product Owner (G1)
- **PRD OQ-5:** confirm on Back only when nothing was saved or shared. Default: yes.
- **PRD OQ-6:** keep both Shoulds, "Choose where to save" and Open. Default: yes.
- **PRD OQ-9:** show the chat hint now; copy re-checked after the T23 chat-app check. Default: yes.

## Verification screenshots for G2 (T20)
Realme 2 Pro (API 36), profile build, synthetic image only, no real faces or signatures:
1. `ready.png` — success, ready line and panel, nothing saved yet.
2. `saved.png` — after Save: saved message, Open shown.
3. `error.png` — save failed message (forced in a demo build).
4. `permission.png` — permission-denied layout with "Choose where to save" (forced in a demo build on API 36).
5. `arabic.png` — saved state in ar, RTL.
6. `font200.png` — 200% font, 360×640 class layout, saved state.
