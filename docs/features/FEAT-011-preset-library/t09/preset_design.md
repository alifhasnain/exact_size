---
id: FEAT-011-T09-DESIGN
title: Preset row and form list — lean design (impeccable, gate G1)
status: Proposed
version: 0.2
updated: 2026-11-27
links: [FEAT-011, FEAT-011-TECH, FEAT-011-TASKS, FEAT-005, FEAT-016-T13-DESIGN, PRODUCT.md]
---

# Preset row and form list — lean design

This is the lean impeccable path (CLAUDE.md Budget):
- One short pass on Material 3 and the existing Booth theme (`lib/ui/booth.dart`).
- No image comps, no reviewer subagents, one round.

Claude builds it in Flutter (T10 list screen, T11 target-step row), and the Product Owner reviews the G2 phone screenshots (T12). All forms shown in builds and screenshots are the synthetic "Test Form A/B" (country `ZZ`).

- **Mode:** Operate: the user picks a form and gets back to the size fields fast. **Platform:** Android, Material 3, portrait phone.
- **Scope limits (PRD):**
  - **FR-5:** the manual fields stay visible and usable at all times.
  - **FR-13:** the row label is derived from the five values.
  - **FR-14:** notes appear in the list and while a spec is applied.
  - **FR-15:** no logos, no official styling, a not-affiliated footer.
  - **FR-9:** the search field has no autocorrect, suggestions or keyboard learning.
  - **OQ-T1:** the row is hidden when the library has zero forms.
- **Copy:** the T03 English strings with two fixes folded in from the Product Owner's copy review (section "Copy" below).

## Direction: the booth's price board

This is the same booth world as the pick, target, crop and result screens. Next to an ID photo booth hangs a board listing the common sizes: "Passport", "Exam form", each with its measurements. You find yours, point at it, and the booth is set. The board is a convenience printed by the booth, not a stamp from the agency.
- **Colours:** curtain-maroon background, `Booth.plate` cards (the same plate as the target fields), `Booth.text` for all text. No flash amber in the list: amber is the one action key on a screen (Continue on the target step), and the list has many equal choices.
- **Not a certificate:** no logo, crest, seal, tick-badge or "verified" icon anywhere (FR-15). Form names are plain text, exactly as published.
- **Numbers:** the spec summary uses tabular figures so sizes line up from row to row, like the booth's price display (`BoothSpecCell`).

## Target step: the preset row (T11)

The row goes in the slot FEAT-005 reserved: directly below the photo line, above the plate with the five fields.

```
┌──────────────────────────────────┐
│ ←                                │
│ Photo: 3000 × 4000 px  Use this  │  photo line (unchanged)
│ ┌──────────────────────────────┐ │
│ │ ▤  Choose a form           › │ │  preset row: outlined key, ≥ 56 dp
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ Width × Height, Min, Max,    │ │  plate with the five fields (unchanged)
│ │ JPEG | PNG                   │ │
│ └──────────────────────────────┘ │
│            [ Continue ]          │  amber key (unchanged)
└──────────────────────────────────┘
```

- **Widget:** a full-width outlined key: `Material` + `InkWell`, radius 12, border `Booth.text` at 60% alpha, 1.5 dp (the `BoothSpecCell` outline), transparent fill, minimum height 56 dp, 16 dp horizontal padding.
  - Leading icon `Icons.list_alt` (a plain list, not a document with a seal), 20 dp.
  - Label `titleMedium`, `Booth.text`, wraps to as many lines as it needs (no ellipsis: a form name must be read in full).
  - Trailing `chevron_right`, mirrors in RTL, excluded from semantics.
- **States:**
  1. **Choose:** label `presetChooseForm`.
  2. **Applied** (the five values equal the picked spec): label `presetApplied` ("Test Form A · Photo"). Under the row, one `BoothNotice` per note of that spec, in data order, icon `info_outline`. The spec summary is not repeated: the fields above and below already show the values. Tapping the row opens the list again.
  3. **Edited after a pick** (any value differs): back to state 1, notes gone (FR-13, OQ-7). Setting the values back brings state 2 back.
  4. **Load failure:** the row is replaced by one `BoothNotice` with `info_outline` and `presetLoadFailed`. It is not tappable. The fields work as FEAT-005 alone.
  5. **Empty library** (today's shipped file) or **still loading:** nothing is drawn, and the screen is exactly FEAT-005. The bundled file loads in milliseconds (T08: 2–24 ms), so a loading indicator would only flash.
- **After a pick:** the five fields and their text controllers are filled, focus is cleared (no keyboard pops up), and the applied label is announced once to TalkBack (`SemanticsService.sendAnnouncement`), because the change happens on a screen the user just returned to.
- **Semantics:** one button node; its label is the row text. Notes follow the row in reading order.
- **Format:** picking a PNG spec switches the JPEG | PNG control through the same `fill` call; nothing new on the plate.

## Form list screen (T10)

A full-screen route pushed from the row. It returns a `PresetPick(formId, kind)`, or nothing on Back or "Enter sizes yourself".

```
┌──────────────────────────────────┐
│ ←  Forms                         │  app bar: Back + presetListTitle
│ ┌──────────────────────────────┐ │
│ │ 🔍 Search forms           ✕ │ │  search: pinned, filled TextField
│ └──────────────────────────────┘ │
│ ZZ                               │  country heading (presetCountry), header
│ ┌──────────────────────────────┐ │
│ │ Test Form A                  │ │  form name: titleMedium w600, header
│ │ Test Issuer · Exams and      │ │  issuer · category: bodyMedium
│ │ admissions                   │ │
│ │ ┌──────────────────────────┐ │ │
│ │ │ Photo                    │ │ │  spec key: kind (titleSmall)
│ │ │ 200 × 230 px · 20–50 KB  │ │ │  summary: bodyMedium, tabular figures
│ │ │ · JPEG                   │ │ │
│ │ │ ⓘ This form also asks    │ │ │  notes: info_outline 18 dp + bodyMedium
│ │ │   for 200 DPI. …         │ │ │
│ │ └──────────────────────────┘ │ │
│ │ ┌──────────────────────────┐ │ │
│ │ │ Signature                │ │ │  second spec key (if any)
│ │ │ 140 × 60 px · up to 20 KB│ │ │
│ │ └──────────────────────────┘ │ │
│ └──────────────────────────────┘ │
│ …                                │
│ ExactSize is not affiliated with │  footer: bodyMedium, last item
│ the organisations listed.        │
└──────────────────────────────────┘
```

- **Shell:** `Scaffold` with the Booth theme, `SafeArea`, content capped at 560 dp wide (tablets, landscape), 16 dp side padding.
- **App bar:** Back plus the title `presetListTitle` ("Forms"). One short word fits at 200% in every language we ship; if a translation ever clips, it moves into the body as on the FEAT-016 explainer.
- **Search field (FR-8, FR-9):**
  - Pinned under the app bar (it does not scroll away), filled `TextField`, leading `search` icon, hint `presetSearchHint`.
  - A clear button (`close` icon, 48 dp) appears when the field has text. Its tooltip and label is Material's own `clearButtonTooltip`, so no new string is needed.
  - `autocorrect: false`, `enableSuggestions: false`, `enableIMEPersonalizedLearning: false`, `autofillHints: null`, `keyboardType: text` (Devanagari and Arabic typing work), `textInputAction: search`.
  - No autofocus: the list is visible first, because café operators often scroll to a known form. The list filters on every keystroke (T07: about 18 µs per call).
  - The controller lives in the screen's `State` and is disposed on pop. There is no `PageStorageKey` and no restoration (AC-8.2).
- **List:** one `CustomScrollView` built lazily, `keyboardDismissBehavior: onDrag`.
  - **Country heading:** `presetCountry` name, `titleSmall` weight 600, 24 dp above, 8 dp below, `Semantics(header: true)`. Sections are sorted by the localized country name (T07).
  - **Form card:** `Booth.plate`, radius 16, 16 dp padding, 12 dp between cards. The card itself is not tappable, because a form with two specs needs a choice.
    - Form name: `titleMedium` weight 600, `Semantics(header: true)`, so TalkBack heading navigation steps form by form.
    - Issuer and category on one wrapping line: `bodyMedium`.
  - **Spec key** (the tappable part, one per spec): outlined like the target row (radius 12, `Booth.text` at 60%, 1.5 dp), minimum 56 dp, 12 dp padding, 8 dp between keys.
    - Kind label (`presetKindPhoto` / `presetKindSignature`), `titleSmall`.
    - Summary (`PresetStrings.summary`), `bodyMedium` with tabular figures, so W × H and the KB range line up across rows.
    - Notes: an 18 dp `info_outline` icon plus `bodyMedium` text per note. They are inside the key, so TalkBack reads them with the spec before the user picks it (AC-5.1).
    - The whole key is one `MergeSemantics` button: "Photo, 200 × 230 px · 20–50 KB · JPEG, This form also asks for 200 DPI. …".
    - No chevron: a tap picks and returns, it does not open another page.
  - **Footer:** `presetNotAffiliated`, `bodyMedium`, 24 dp above, 32 dp bottom padding. Always the last item, also under the empty state, so it is never scrolled out of existence (FR-15).
- **Empty state (no match):** in place of the sections: `presetNoMatch` (`bodyLarge`), 12 dp gap, then an `OutlinedButton` "Enter sizes yourself" (`presetEnterYourself`, Booth text and outline, 48 dp) that closes the list with no pick. It is not amber, because it is a way out, not the main action.
- **Long names and 200% font at 360×640:** everything wraps, no fixed heights, no ellipsis. The search field stays pinned, and the list scrolls under it.
- **RTL (ar):** start-aligned text, the back arrow and the target row's chevron mirror. Form names sit in first-strong isolates and numbers with units in left-to-right isolates (`PresetStrings`), so "200 × 230 px" keeps its order.
- **Glyphs:** a form name in a script the device font lacks may show boxes (PRD section 9). T12 checks each script present in the data.

## Accessibility and contrast

- `Booth.text` on `Booth.curtain`, `Booth.plate` and `Booth.notice` are the existing pairs and meet WCAG AA. No text is drawn with alpha; only the outline uses 60% alpha (about 5:1 on curtain, more on the darker plate; non-text contrast needs 3:1).
- Every tappable element is at least 48 dp tall (the row and spec keys are 56 dp), has a text label and is at least 8 dp from the next.
- Headings: country names and form names are header nodes. Notes are never conveyed by the icon alone.
- No colour carries meaning: an applied preset is shown by its label, not a colour change.

## Copy (G1 review of the T03 English)

Folded in with the Product Owner's agreement (2026-11-27):

| Key | Before | After | Why |
|---|---|---|---|
| `presetNoteContent` | "This form also has other photo rules. ExactSize does not check them." | "This form also has other rules for this image. ExactSize does not check them." | The note can sit on a signature spec, where "photo rules" reads wrong |
| `presetLoadFailed` | "Forms could not be loaded. You can enter the sizes yourself." | "Forms could not be loaded. You can enter sizes yourself." | Matches the empty-state button "Enter sizes yourself" |
| `presetLoadFailed` (after G2, 2026-11-27) | "Forms could not be loaded. You can enter sizes yourself." | "The form list could not be opened. You can enter sizes yourself." | The Spanish review read "loaded" as a possible download and "forms" as the user's own forms. The list is bundled and nothing is downloaded (FEAT-016 offline claim). The Product Owner left the choice to Claude |

Kept as drafted (the Product Owner reviewed them): `presetListTitle` "Forms"; the category labels "Jobs", "Exams and admissions", "Visa and passport", "Other"; every other T03 string.

## G1 decisions (each with a default)

1. **List as a full-screen route, not a bottom sheet.** Default: full screen. A sheet with about 40 forms, a search field and the keyboard is cramped on a budget phone and at 200% font, and system Back behaves the same either way.
2. **Nothing drawn while the library loads.** Default: hidden (state 5). The file is bundled and loads in milliseconds, so a spinner or placeholder would only flash.
3. **No spec summary on the applied row.** Default: the row shows "form · kind" and the notes only. The five fields already show the values, and repeating them would make the row tall at 200%.

## G2 screenshots (T12, one per state, Realme 2 Pro)

The device build uses a local, uncommitted copy of the synthetic fixture over `assets/presets/presets.json` (restored before every commit).

1. Target step, "Choose a form" row (en).
2. Target step, preset applied with its notes (en).
3. Target step, load failure (a local, uncommitted broken asset) (en).
4. Form list, top (en).
5. Form list, search with no match: empty state and footer (en).
6. Form list in Arabic (RTL).
7. Form list at 200% font (en).

Before each screenshot, the foreground app is checked. Only ExactSize's own screens are captured, and nothing personal is on them.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-27 | Lean design pass (FEAT-011-T09) |
| 0.2 | 2026-11-27 | presetLoadFailed reworded after the es review (T13) |
