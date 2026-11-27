---
id: FEAT-014-T05-DESIGN
title: Preset source note — lean design (impeccable, gate G1)
status: Proposed
version: 0.1
updated: 2026-11-27
links: [FEAT-014, FEAT-014-TECH, FEAT-014-TASKS, FEAT-011-T09-DESIGN, PRODUCT.md]
---

# Preset source note — lean design

This is the lean impeccable path (CLAUDE.md, Budget): one short pass on Material 3 and the existing Booth theme (`lib/ui/booth.dart`). There are no image comps, no reviewer subagents and only one round. It refines two surfaces FEAT-011 already built, so the FEAT-011 design note (`t09/preset_design.md`) still applies and only the additions are described here.

Claude builds the target-step block in T07 and the card lines in T08. The Product Owner reviews the emulator screenshots at G2 (T09). Builds and screenshots show only the synthetic Test Forms A, B and C.

- **Mode:** Operate. The note is read once, after a form is picked, then the user moves on. It must be easy to see and impossible to mistake for a stamp of approval.
- **Limits from the PRD:**
  - FR-8: plain text, with no link, no selection, no tap and no copy.
  - FR-9: no "verified", "official" or similar words.
  - FR-1: the block comes after the notes (OQ-9).
  - FR-2: the list cards have no prompt.
  - FR-13: this design gate.

## Direction: the label on the booth's size board

The FEAT-011 world is a size board hanging next to an ID photo booth. FEAT-014 adds the small printed label under each size: where the size was copied from, and when someone last compared it with that source. A careful booth would also add a line asking you to check your own form. It is printed in the same plain type as the board. It is not a sticker, not a seal and not a warning sign.

- **Colours:** nothing new. The block uses the existing `BoothNotice` panel (`Booth.notice` fill, `Booth.text`). Flash amber stays reserved for Continue.
- **No alarm when old:** the old-check prompt changes its words only, not its colour or icon. A red or amber "outdated" look would make users distrust a size that is probably still right, while a plain sentence asks for the same check.
- **No authority marks:** there is no tick, shield, seal, badge or logo anywhere. The source is described in words.

## Target step: the source block (T07)

The block is one more `BoothNotice` in the notes column under the applied preset row:

```
┌──────────────────────────────────┐
│ Photo: 3000 × 4000 px  Use this  │
│ ┌──────────────────────────────┐ │
│ │ ▤  Test Form A · Photo     › │ │  applied row (unchanged)
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ ⓘ This form also asks for    │ │  FEAT-011 notes (KB-only line first,
│ │   200 DPI. …                 │ │  then each note; unchanged)
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ ↺ Source: Test notice 1      │ │  source block: icon `history`
│ │   (Test Issuer)              │ │
│ │   Website: notice.example.   │ │
│ │   test                       │ │
│ │   Last checked: 2026-10-01   │ │
│ │   Check these sizes against  │ │  the prompt is the last line
│ │   your form's notice or …    │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ Width × Height, Min, Max …   │ │  plate with the five fields (unchanged)
│ └──────────────────────────────┘ │
│            [ Continue ]          │
└──────────────────────────────────┘
```

- **Widget:** the existing `BoothNotice` with text `PresetStrings.block(form, now)`. The lines are joined by line breaks, so there is one `Text`, one semantics node and no new widget (tech section 10: a new widget only if the prompt must look different).
- **Icon:** `Icons.history`, 20 dp, the same size and colour as the `info_outline` notes.
  - The FEAT-011 notes mean "a rule ExactSize does not cover"; this block means "where these sizes come from and when they were compared". A different icon tells the two apart at a glance.
  - `history` (a clock with a return arrow) reads as "last time", not as approval. Rejected: `verified` and `fact_check` (they look like approval), `link` and `open_in_new` (they promise a tap), `warning` (it alarms).
  - The icon has no semantic label. TalkBack reads the text only.
- **Order:** KB-only line, then the FEAT-011 notes, then this block, then the plate (FR-1, OQ-9). The existing 12 dp gap above the notes column stays, and `BoothNotice` brings its own 12 dp bottom margin.
- **Prompt look:** same `bodyMedium` as the lines, no bold.
  - Alternative: a bolder prompt would need a rich-text `BoothNotice` variant (a new widget), and it competes with Continue, the one strong element on the screen. Placing the prompt last already gives it the final word.
  - If G2 shows that the prompt is lost, the fix is a blank line before it. That is a code change in T07 with no new string.
- **Old-check:** the same block with `presetCheckNoticeOld` as its last line. Nothing else changes.
- **Missing parts:** a line whose data is missing is left out and the others close the gap (AC-6.3). The prompt is always present, so the block never disappears while a spec is applied.
- **Long text, 200% and RTL:**
  - The text wraps in full and is never cut short with an ellipsis.
  - A long host with no spaces breaks at characters, which Flutter does by default.
  - The target screen already scrolls, so Continue stays reachable (AC-1.4).
  - In `ar`, the panel mirrors (icon on the right). Title, host and date keep their own order inside their isolates.
- **No interaction:** no `InkWell`, no `GestureDetector`, no `SelectableText`. A long press does nothing (FR-8, AC-1.6).

## Form list: source lines on each card (T08)

```
│ ┌──────────────────────────────┐ │
│ │ Test Form A                  │ │  form name (unchanged)
│ │ Test Issuer · Exams and      │ │  issuer · category (unchanged)
│ │ admissions                   │ │
│ │ Source: Test notice 1        │ │  NEW: cardSource, bodySmall,
│ │ (Test Issuer)                │ │  Booth.text at 80%, 4 dp above
│ │ Website: notice.example.test │ │
│ │ Last checked: 2026-10-01     │ │
│ │ ┌──────────────────────────┐ │ │
│ │ │ Photo                    │ │ │  spec keys (unchanged), 12 dp above
│ │ │ 200 × 230 px · 20–50 KB  │ │ │
│ │ └──────────────────────────┘ │ │
```

- **Widget:** one plain `Text(s.cardSource(form))` between the issuer line and the first spec key. It is drawn only when the text is not empty.
- **Type:** `bodySmall` in `Booth.text` at 80% alpha, so the card keeps its order: the name first, then the issuer, then this smaller source detail, then the keys you tap.
  - Contrast on `Booth.plate`: 9.8:1 at 80% (full `Booth.text` is 14.9:1), well above the 4.5:1 minimum for small text.
  - `bodySmall` scales with the system font, so it reaches 24 sp at 200%.
- **Spacing:** 4 dp above the source text. The existing 12 dp gap before each spec key stays.
- **No prompt and no icon on the list (FR-2):**
  - The prompt belongs to the moment after a pick, on the target step.
  - Seventeen repeated prompts would be noise, and an icon per card would add a decorative element to every card.
- **Semantics:** the text is its own node, after the name and issuer in reading order and before the spec keys. The spec-key buttons keep their FEAT-011 labels (AC-2.3).
- **No interaction:** the card is not tappable today and stays so (FR-8).

## Copy

The five English strings from T04 stand as written. No copy fix is proposed:
- **Source line:** "Source: {title} ({issuer})". The issuer in brackets also identifies a page whose own title is generic (for example a page titled "Help").
- **Website line:** "Website: {host}". It shows the host only, never `http://` and never a path.
- **Last-checked line:** "Last checked: {date}". The date is in `YYYY-MM-DD` form, the same in every language, with digits 0–9.
- **Prompt:** "Check these sizes against your form's notice or instructions before you upload. They can change."
- **Old-check prompt:** "These sizes were last checked more than 90 days ago. Check your form's notice or instructions before you upload."

## What G1 decides
1. The `history` icon for the block, or `info_outline` like the notes.
2. The prompt in the same weight as the lines, or set apart.
3. The card lines in `bodySmall` at 80%, or the issuer line's `bodyMedium`.
4. The five English strings as written (they then go to `/l10n-translate`).
