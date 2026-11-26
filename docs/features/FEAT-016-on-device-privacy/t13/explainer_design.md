---
id: FEAT-016-T13-DESIGN
title: Privacy explainer and pick-screen entry — lean design (impeccable, gate G1)
status: Proposed
version: 0.1
updated: 2026-11-27
links: [FEAT-016, FEAT-016-TECH, FEAT-016-TASKS, FEAT-001, FEAT-006-T10-DESIGN, PRODUCT.md]
---

# Privacy explainer and pick-screen entry — lean design

This is the lean impeccable path (CLAUDE.md Budget):
- One short pass on Material 3 and the existing Booth theme (`lib/ui/booth.dart`).
- No image comps, no reviewer subagents, one round.

Claude builds it in Flutter (T14), and the Product Owner reviews the G2 phone screenshots (T15). All content is synthetic.

- **Mode:** Read: the visitor understands something, then goes back. **Platform:** Android, Material 3, portrait phone. The explainer page scrolls.
- **Scope limits (PRD):**
  - **FR-4:** static local text only, with no link, image, WebView, permission or counter.
  - **FR-3:** six parts, (a) to (f).
  - **OQ-3 default:** a labelled control beside the pick-screen privacy line; the line itself stays as it is.
  - **Copy:** the strings are the T07 English copy and are not changed here. G1 reviews the copy together with the placement.

## Direction: the notice on the booth wall

This is the same booth world as the pick, target, crop and result screens. A photo booth has a small printed notice on the wall: what happens to your pictures and who keeps them. You read it once, standing up, then you step in.
- **Colours:** curtain-maroon background, `Booth.text` for everything, and no flash amber. Amber is reserved for the one action key on a screen, and the explainer has no action.
- **Not a certificate:** no shield, lock, tick-badge or "verified" icon anywhere. A badge would claim more than the text does (FR-5, banned "secure", "certified"). The trust comes from plain, specific sentences.
- **Reading comfort:** body text at `bodyLarge`, line length capped at 560 dp on tablets and in landscape, and 24 dp between parts so each part reads as one idea.

## Pick screen: the entry control

The plaque at the bottom of the pick screen keeps its text (`pickPrivacyNote`) and style. Directly under it sits one control:

```
┌──────────────────────────────────┐
│ ExactSize                        │
│                                  │
│  ┌────────────────────────────┐  │  cabin with the three keys (unchanged)
│  │ …                          │  │
│  └────────────────────────────┘  │
│                                  │
│ Your photos are resized on your  │  plaque (unchanged widget, new T07 copy)
│ phone. ExactSize never uploads   │
│ them.                            │
│  How your photos are handled  ›  │  entry: TextButton, Booth.text, ≥ 48 dp tall
└──────────────────────────────────┘
```

- **Widget:** `TextButton` with the label `privacyEntry` and a trailing `chevron_right` (Material Symbols), 18 dp.
  - The label is underlined so it reads as "go somewhere", while the plaque stays plain text.
  - The chevron is a `Directionality`-aware icon, so it mirrors in Arabic.
  - The button is centred under the plaque, minimum height 48 dp, and the label wraps on two lines at 200% instead of clipping.
- **Focus and TalkBack order:** after the plaque, so the order is the three keys, the privacy line, then the entry. The button label is the semantics label, and the chevron is excluded from semantics.
- **Why not make the plaque itself tappable?** A tappable sentence has no visible affordance, and on the pick screen a stray tap near the bottom keys would open a page the user did not ask for. A separate labelled control is clearer (OQ-3 default).
- **States:**
  - While the picker is opening (`_Opening`), the entry is disabled with the same treatment as the keys, so the explainer can't open over a pick in progress.
  - Otherwise it is always enabled.

## Explainer screen (`PrivacyScreen`)

```
┌──────────────────────────────────┐
│ ←                                │  app bar: back only, no title (see G1 decision 1)
│                                  │
│ Your photos and privacy          │  privacyTitle — headlineSmall, Semantics(header)
│                                  │
│ On your phone                    │  privacyOnPhoneTitle — titleMedium w600, header
│ ExactSize resizes your photo on  │  privacyOnPhone — bodyLarge
│ your phone. ExactSize never      │
│ uploads your photos. You do not  │
│ need an account.                 │
│                                  │  24 dp
│ Works offline                    │  (b) privacyOffline…
│ …                                │
│ What ExactSize keeps             │  (c) privacyKept…
│ When you save or share           │  (d) privacyCopies…
│ Other apps on your phone         │  (e) privacyOutside…
│ What ExactSize reads             │  (f) privacyReads…
│                                  │  32 dp bottom padding
└──────────────────────────────────┘
```

- **Shell:** `Scaffold` with the Booth theme, `SafeArea`, and a `SingleChildScrollView` with 24 dp side padding and the content column capped at 560 dp.
- **App bar:** back arrow only. System Back and the arrow both pop to the pick screen, unchanged.
- **Title:** `privacyTitle` as the first item in the scroll body, `headlineSmall`, wrapped in `Semantics(header: true)`. It is 24 dp above the first part.
- **Each part:** a heading (`titleMedium`, weight 600, `Semantics(header: true)`), 8 dp gap, then the body (`bodyLarge`, height 1.4), 24 dp between parts. The parts appear in the FR-3 order (a) to (f), so TalkBack's heading navigation steps through them.
- **Nothing else on the page:**
  - no button, link, icon or image;
  - no `InkWell`;
  - no dividers (spacing alone separates the parts, which keeps the notice calm);
  - no Done key, because Back is the only way out, as on any read-only page.
- **Selection:** text is not selectable, so no clipboard path is added (FR-9 bans `Clipboard` in app code, and there is nothing to copy).
- **No state:** the page holds no image and no provider. A photo shared in while the page is open goes through the existing `popUntil(route.isFirst)` (tech section 2).
- **RTL:** layout mirrors (start-aligned text, the back arrow flips). No values or isolates are needed, because the copy has no numbers or placeholders.
- **200% font at 360×640:** everything wraps and the page scrolls, with no fixed heights. Because the title is in the body and not the app bar, it can wrap to two or three lines instead of being clipped.

## Accessibility and contrast

- `Booth.text` on `Booth.curtain` is the existing pair used on every booth screen and meets WCAG AA. No text is drawn with alpha.
- Headings are real header nodes, and the body follows its heading in reading order (AC-2.5).
- The entry control is at least 48 dp tall and has a text label (NFR-2).

## G1 decision (one item, with a default)

1. **Title placement.** The tech plan names an AppBar title. A one-line AppBar title clips "Your photos and privacy" at 200% on a 360 dp phone (and longer languages clip sooner). **Default: the title goes in the scroll body as the first header, and the app bar keeps only Back** (same pattern as the FEAT-006 check screen). The alternative is an AppBar title with two-line wrap, which a Material app bar handles poorly.

## G2 screenshots (T15, one per state, Realme 2 Pro)

1. Pick screen with the entry control (en).
2. Explainer top (en).
3. Explainer bottom, scrolled (en).
4. Explainer in Arabic (RTL).
5. Explainer at 200% font (en).

Before each screenshot, the foreground app is checked. Only ExactSize's own screens are captured.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-27 | Lean design pass (FEAT-016-T13) |
