---
id: FEAT-011
title: Built-in preset library
status: Approved
version: 2.0
updated: 2026-11-27
links: [ROADMAP, BRIEF, RESEARCH, FEAT-005, FEAT-006, FEAT-009, FEAT-010, FEAT-012, FEAT-013, FEAT-014, FEAT-016, FEAT-019, FEAT-027]
---

# FEAT-011 — Built-in preset library

## 1. Overview
A small library of about 15–20 common application-form specs that ship inside the app. On the target step (FEAT-005) the user opens a list, picks a form and one of its specs (photo or signature), and the five target fields (width, height, minimum KB, maximum KB, format) are filled. The user can still edit every value. The library works offline and makes no network call. Release: MVP, R1 Phase A, Must [Fact](docs/roadmap.md, FEAT-011 row; Milestones).

**Decided (Product Owner), not reopened here**

| Decision | Source |
|---|---|
| Small library of about 15–20 form specs, in the MVP (Option B) | [Fact](docs/product/decisions.md, 2026-11-18 "ROADMAP MVP Option B chosen"); [Fact](docs/roadmap.md, FEAT-011 row) |
| Specs ship inside app releases; no remote update; FEAT-013 stays parked; no network call | [Fact](docs/product/decisions.md, 2026-11-18 "BRIEF Preset updates via app releases; Firebase may host presets later") |
| The Product Owner keeps specs accurate | [Fact](docs/product/vision.md, open questions; BRIEF 1.3) |
| FEAT-014 (source note, last-checked date, "check your notice" prompt) is a separate feature that ships with FEAT-011 | [Fact](docs/roadmap.md, FEAT-014 row) |
| FEAT-009 (dual photo + signature flow) is out of scope | [Fact](docs/roadmap.md, FEAT-009 row) |
| Languages en, es-419, pt-BR, hi, id, ar; form names stay as published; UI strings via gen-l10n | [Fact](docs/product/vision.md, platforms; CLAUDE.md, Localization) |

**Roadmap wording now stale (not edited here).** The FEAT-011 row says "Depends on: spec sourcing and accuracy owner (open question)" and "Blocked by the open question". That question is resolved by BRIEF 1.3 (Product Owner keeps specs accurate). The row's "First item in M2" is also superseded by the merged release plan: FEAT-011 is in R1 Phase A [Fact](docs/roadmap.md, Milestones). The Product Owner may update the row at the next roadmap change.

**Boundary with FEAT-014**

| Item | FEAT-011 | FEAT-014 |
|---|---|---|
| Spec data (W, H, KB range, format) | Owns | Reads |
| Source (title, issuer, optional URL text) and last-checked date: stored per form | Owns the data, requires it, exposes it | Owns the screens and wording that show it |
| "Check your notice" prompt | Not shown by this feature | Owns |
| "Not covered by ExactSize" notes (DPI, background, content rules) | Owns (an engine limit, not a source fact) | Not involved |
| "Not affiliated" footer line on the list | Owns | Not involved |
| Release | The preset list is not released without FEAT-014's display (release rule, section 11) | Same |

**Contract with FEAT-005.** FEAT-005's `TargetSpec` (width, height, minKb, maxKb, format) is unchanged by this feature. A preset only fills its fields, and every value still goes through FEAT-005 validation on Continue [Fact](docs/features/FEAT-005-manual-target/prd.md, section 1, FR-9). FEAT-005 left open whether `TargetSpec` gets a source reference for FEAT-014. Proposal: no. The applied-preset reference (form id, spec kind) is kept beside the target in session state, because crop and compression never need it (OQ-11).

## 2. Problem statement
Applicants, students, visa applicants and operators fill forms that state exact limits, and reading each circular costs time and invites typing errors [Fact](docs/roadmap.md, FEAT-011 row: "No need to read the circular"). Competitors show presets as per-exam pages or a few fixed sizes, and every preset observed is sourced from a specific circular and tells users to check their own notice [Fact](docs/research/competitors.md, feature comparison; Market notes). The only research-backed official spec found is an Indian recruitment page: photo 20–50 KB, signature 10–20 KB, with no pixel size in our sources [Fact](docs/research/competitors.md, A4).

Why now: the vision's "under 30 s from open to export" is realistic through presets, not manual entry, which probably takes 10–20 s of typing [Hypothesis] [Fact](docs/features/FEAT-005-manual-target/prd.md, section 2, OQ-14).

Risks this feature must handle:
- A stale or wrong spec makes the user's upload fail. Accuracy is owned by one person and updated only with app releases, so staleness is certain over time [Hypothesis]. Mitigation: store source and date (FEAT-014 shows them), CI checks, a freshness list at each release.
- Some forms have rules ExactSize cannot meet (DPI, background colour, face position). The user must not think the file is "form-ready" when only size, KB and format are checked.
- Naming exams and agencies carries trademark and accuracy-claim risk (section 10).
- Research covers South Asian forms; no form evidence was found for Spanish, Portuguese, Indonesian or Arabic markets, although those are launch languages [Hypothesis, gap in docs/research/competitors.md]. Library coverage may not match launch markets (OQ-1).

## 3. Goals & success metrics
The app sends no data and has no analytics SDK, and FEAT-016 allows no usage telemetry for its own feature [Fact](docs/features/FEAT-016-on-device-privacy/prd.md, section 3). Local-only counters (FEAT-027, Proposed) cannot be read by the Product Owner without the user's help, so none are proposed here. Metrics are therefore CI checks, release checks and observation in the closed test with a handful of real applicants [Fact](docs/roadmap.md, Milestones, Phase A exit: recommended closed test track). Test environment as FEAT-005 (emulators, 2 GB RAM, API 28 and latest; timing best effort).

| Goal | Metric | Target |
|---|---|---|
| Library size as decided | Forms in the data file at release | 15–20 (about, Product Owner) |
| Every spec is valid | Specs failing FEAT-005 validation or FR-19 in CI | 0 |
| Every spec fits the engine | Specs whose fixture run (FR-20) ends outside W×H or the KB range and are not reviewed by the Product Owner | 0 [Assumption: fixtures stand in for real photos] |
| Provenance | Forms without source title, issuer or last-checked date | 0 |
| Freshness | Forms checked more than 90 days before the release candidate, not accepted by the Product Owner in the release record | 0 [Assumption: 90 days] |
| Fast path | Median time from target step open to Continue when the user picks a preset, closed test, observed by the Product Owner | ≤ 10 s [Assumption], informational; compare 20 s for manual entry |
| Few taps | Taps from target step open to Continue, form visible without search (no typing) | ≤ 3 (open list, pick spec, Continue) |
| Coverage | Closed-test testers who found their own form in the list (asked, not logged) | ≥ 50% [Assumption], informational; shows which forms to add next |
| Accuracy in the field | Verified wrong or stale specs reported (store reviews, support mail) and still open after 14 days | 0 [Assumption] |
| No network | New network calls, permissions or dependencies not on the reviewed list | 0 |
| Privacy | Preset selections or search text on disk, in logs, crash reports or the clipboard | 0 |
| Language | New UI strings present in 6 languages; form names unchanged in all | 100% |
| Accessible | Clipped or overlapping controls in list, search and note states at 200% font, en and ar, 360×640 dp | 0 |

**Non-goals (out of scope in R1)**
- Remote or automatic update of specs (FEAT-013); any network call.
- Showing the source note, last-checked date and "check your notice" prompt (FEAT-014 screens).
- Quick dual flow, linking a form's photo and signature in one run (FEAT-009).
- Saved custom presets (FEAT-012); recents, favourites or "last used" lists (they would write the user's application choices to disk, section 10).
- DPI writing (FEAT-010), print-size or cm/mm input (FEAT-005 OQ-2), background change or content checks (FEAT-028, FEAT-029).
- Other image kinds such as thumb impression, ID scan or certificates; only photo and signature.
- Detecting the user's country by location; user-submitted or shared presets; links that open a website; automatic verification of specs against the web.
- Form-specific branding, logos or any official-looking styling.

## 4. User stories
Test data in acceptance criteria uses synthetic forms ("Test Form A") with made-up values. They are not claims about any real form.

- **US-1** As an applicant who knows my form's name, I want to pick its spec from a list, so that I do not type the numbers.
  - **AC-1.1** Given the target step is open, when I look at it, then a row labelled "Choose a form" is shown with the five manual fields still present and usable, and when the library fails to load the row is replaced by the load-failure message (AC-6.1) and the screen works as FEAT-005 alone.
  - **AC-1.2** Given I tap the row, when the list opens, then forms are in sections by country, each section has a heading, and each form shows its name and one tappable row per spec with kind, size, KB range and format.
  - **AC-1.3** Given a form has one spec only, when I tap its row, then that spec is picked at once and I return to the target step.
  - **AC-1.4** Given the list is open, when I press Back without picking, then the target step shows exactly the values it had before.
  - **AC-1.5** Given no network (airplane mode on and Wi-Fi off, checked as in FEAT-016 tasks open item 6), when I open the list and pick a spec, then it works with no delay or message about the network.
- **US-2** As an applicant who does not want to scroll, I want to search, so that I find my form by name, agency or short name.
  - **AC-2.1** Given the list is open, when I type part of a form name, issuer, alias, localized country name or category label, then only matching forms stay, in the same section order, updating on each keystroke.
  - **AC-2.2** Given I type "TEST form a" or the same text with extra spaces, bidi marks or Arabic-Indic digits in place of 0–9, when the list filters, then "Test Form A" still matches (same cleaning as FEAT-005 FR-4).
  - **AC-2.3** Given nothing matches, when the list shows the empty state, then it says no form matches and offers "Enter sizes yourself", which returns to the target step with values unchanged.
  - **AC-2.4** Given the search field, then autocorrect, suggestions and personalised keyboard learning are off, and the text is not stored after I leave the list.
- **US-3** As an applicant whose form asks for both a photo and a signature, I want them as separate specs, so that I choose the one for the image I am processing.
  - **AC-3.1** Given Test Form A has a photo spec and a signature spec, when I open the list, then both rows appear under the form name and each can be picked on its own.
  - **AC-3.2** Given I picked Test Form A photo, when I later start over with a signature image and open the list, then I pick the signature row and the fields change to its values.
  - **AC-3.3** Given a form has no signature spec in the library, then no signature row is shown for it (nothing is invented).
- **US-4** As an applicant, I want the picked values in the target fields and to be free to change them, so that I can fix a form that changed.
  - **AC-4.1** Given I typed Width 300 and then pick Test Form A photo (200×230 px, 20–50 KB, JPEG), when I return, then Width 200, Height 230, Minimum 20, Maximum 50 and JPEG are shown, the previous values are gone, and the keyboard is closed.
  - **AC-4.2** Given a spec has no minimum, when I pick it, then Minimum is empty.
  - **AC-4.3** Given a spec was picked, when I return, then the preset row reads "Test Form A · Photo" (form name as published plus kind).
  - **AC-4.4** Given a spec was picked, when I edit any of the five values, then the row goes back to "Choose a form", and when I set the values back to the preset's, then the row shows the form again (state derived from the five values).
  - **AC-4.5** Given picked values, when I tap Continue, then validation and hand-over are identical to manual entry (FEAT-005 AC-9.2).
  - **AC-4.6** Given a picked spec is larger than my photo, then the FEAT-005 upscale notice appears as for manual entry.
  - **AC-4.7** Given I typed Width 300 and Height 400 and then pick Test Form C photo (KB-only: 10–200 KB, JPEG), when I return, then Width 300 and Height 400 stay, Minimum 10, Maximum 200 and JPEG are shown, the row reads "Test Form C · Photo", and the line from FR-26 is shown.
  - **AC-4.8** Given a KB-only spec was picked, when I change Width or Height, then the row still reads "Test Form C · Photo"; when I change Minimum, Maximum or the format, then the row goes back to "Choose a form".
  - **AC-4.9** Given a KB-only spec was picked with Width and Height empty, when I tap Continue, then FEAT-005 shows its width and height errors exactly as for manual entry and nothing is filled in for me.
- **US-5** As an applicant whose form has rules ExactSize cannot meet, I want to be told plainly, so that I do not assume the file is form-ready.
  - **AC-5.1** Given a spec lists DPI 200 as not covered, when its row shows in the list and again while it is applied on the target step, then a short line says the form also asks for 200 DPI and ExactSize does not set it.
  - **AC-5.2** Given a spec lists a background rule or a content rule, then a short fixed line says ExactSize does not change or check it.
  - **AC-5.3** Given any note is shown, when I tap Continue, then nothing is blocked and no value changes.
  - **AC-5.4** Given a note, then it uses text plus an icon (not colour alone) and is read by TalkBack with the spec row.
  - **AC-5.5** Given the data file, then note text comes only from fixed strings chosen by code, never from free text in the data file.
- **US-6** As a user whose form is not in the library, I want the manual route to stay obvious.
  - **AC-6.1** Given the library data fails to load, when I open the target step, then FEAT-005 works unchanged and a short message says forms could not be loaded and sizes can be entered by hand.
  - **AC-6.2** Given one spec fails runtime validation (corrupt data), when the list opens, then that spec is skipped, others show, and nothing crashes.
- **US-7** As the Product Owner who keeps specs accurate, I want the data in one place with source and date and checked by CI, so that a typo cannot ship.
  - **AC-7.1** Given three test specs (width 0; minimum 10 with maximum 5; width 15 px), when CI runs, then each fails with a message naming the form id, spec kind and rule.
  - **AC-7.2** Given a form without source title or last-checked date, or with a date in the future, when CI runs, then it fails.
  - **AC-7.3** Given two forms with the same id, when CI runs, then it fails.
  - **AC-7.4** Given the release checklist runs, when a form was last checked more than 90 days earlier, then it is listed with its date for the Product Owner to accept or fix.
  - **AC-7.5** Given I change a spec, then the change is recorded in `docs/CHANGELOG.md` with the form id, the source and the date (process, checked at review).
- **US-8** As a user whose application choice is private, I want picking a form to leave no trace.
  - **AC-8.1** Given I picked a form and closed the app, when I reopen it, then no preset is applied and no "recent" list exists.
  - **AC-8.2** Given a picked form and a search, then neither appears in logs, crash reports, analytics, counters or the clipboard (checked by a test over the log wrapper and a code search for storage calls).
- **US-9** As a user of any launch language, I want the list readable and usable.
  - **AC-9.1** Given Arabic, then the layout is mirrored, form names as published sit in correct directional isolates, and digits show as 0–9 with units "px" and "KB" in left-to-right isolates.
  - **AC-9.2** Given font scale 200% at 360×640 dp, then no row, heading, note or search field is clipped or overlapped, there is no horizontal scroll, and every spec row is reachable.
  - **AC-9.3** Given TalkBack, then a spec row is announced as one item: form name, kind, size, KB range, format and any note; section headings are announced as headings.
  - **AC-9.4** Given any control, then its touch target is at least 48 dp.
  - **AC-9.5** Given any of the 6 languages, then form names, issuers and source titles are identical to the data file, while labels, country and category names, notes and messages are translated.

## 5. User flows
**Main flow**
1. The user has an accepted photo and the target step is open (FEAT-005).
2. The user taps "Choose a form". The list opens: sections by country, forms with their spec rows, search field on top.
3. The user taps a spec row (or searches first). The list closes.
4. The target step shows the five values filled, the row reads "<form name> · <kind>", and any not-covered note is shown beside it. FEAT-014 shows its source note here and in the list.
5. The user edits a value if needed, then taps Continue. FEAT-005 validates and hands on (FEAT-002, FEAT-004, FEAT-006, FEAT-007).

**Alternate flows**
- Search: type, list filters, pick. Clear the field to see all forms.
- Photo, then signature (FEAT-009 not built): the user finishes the first image, starts over with the second, and picks the other spec of the same form. Session values from the first target stay (FEAT-005 OQ-1 B), so the row shows which preset is applied, which guards against reusing the photo target for a signature (FEAT-005 OQ-13).
- Edit after pick: row returns to "Choose a form" while values differ from the preset.
- No match: "Enter sizes yourself" returns to the target step.

**Error flows**
- Library load failure: row replaced by a short message, manual entry as in FEAT-005.
- Invalid spec at runtime: skipped, the rest shown.
- Any validation error after a pick appears through FEAT-005's messages on Continue.

## 6. Functional requirements
| ID | Requirement | Story | Priority |
|---|---|---|---|
| FR-1 | The system shall ship a library of about 15–20 forms bundled with the app. The list of forms and every value are supplied and verified by the Product Owner; the developer enters them only as given. Claude may draft a researched candidate list (each value quoted from a cited notice, marked unverified); only rows the Product Owner has confirmed against their source enter the shipped data (decision 2026-11-27). | US-1, US-7 | Must |
| FR-2 | Each form shall have: `id` (lowercase slug, unique, never reused), `name` and `issuer` (as published, not translated), `country` (ISO 3166-1 alpha-2), `category` (job, exam_admission, visa_passport, other [Assumption: from vision segments]), optional `aliases` (search terms), `source` (title as published, optional URL as text), `lastChecked` (date YYYY-MM-DD), and 1–2 specs. | US-1, US-7 | Must |
| FR-3 | Each spec shall have: `kind` (photo or signature, at most one of each per form), `width`, `height`, `minKb` (null = none), `maxKb`, `format` (jpeg or png), and optional `notCovered` entries from a fixed set: `dpi` (with a whole number), `background`, `content`. `width` and `height` shall be both present or both null. A spec with both null is a **KB-only spec**: it is for a form that states a KB limit and format but no pixel size, and it still needs `maxKb` and `format` (OQ-3, decided 2026-11-27). | US-1, US-5 | Must |
| FR-4 | A form shall have exactly one source and one last-checked date, each required. FEAT-011 shall expose both to FEAT-014 through the data model; FEAT-011 shall not build the source-note UI, the date display or the "check your notice" prompt. | US-7 | Must |
| FR-5 | The target step shall show a "Choose a form" row that opens the list (FEAT-005 OQ-10: the FEAT-005 screen works alone with room for a preset row) [Fact](docs/features/FEAT-005-manual-target/prd.md, OQ-10). Manual fields shall stay visible and usable at all times. | US-1 | Must |
| FR-6 | The list shall group forms into sections by country, with a heading per section, sorted alphabetically by localized country name; within a section, forms sorted by name. Each form shall show its name and one tappable row per spec: kind, "W × H px" (or "Any pixel size" for a KB-only spec), KB range or "up to N KB", and format. | US-1, US-3 | Must |
| FR-7 | A form with one spec shall be picked with one tap on that row. A form with two specs shall show both rows without an extra step. | US-1, US-3 | Must |
| FR-8 | The list shall have a search field that matches name, issuer, aliases, localized country name and localized category label, ignoring case, diacritics, whitespace, bidi marks and Arabic-Indic, Extended Arabic-Indic and Devanagari digits (reusing the FEAT-005 FR-4 cleaning). No network. | US-2 | Should |
| FR-9 | The search field shall turn autocorrect, suggestions and personalised keyboard learning off, and its text shall not be stored beyond the open list. | US-2, US-8 | Must |
| FR-10 | When nothing matches, the system shall show an empty state with an action that returns to the target step with values unchanged. | US-2, US-6 | Should |
| FR-11 | Picking a spec shall set width, height, minKb (empty when null), maxKb and format on the FEAT-005 fields, replacing every current value without a confirmation step (OQ-8); picking a KB-only spec shall set minKb, maxKb and format only and leave width and height exactly as they were (typed values or empty); close the keyboard, and return to the target step. | US-4 | Must |
| FR-12 | All picked values shall remain editable and go through FEAT-005 validation on Continue unchanged. `TargetSpec` shall not gain preset-specific fields; the applied-preset reference shall be kept beside it in session state (OQ-11). | US-4 | Must |
| FR-13 | The preset row shall show "<form name> · <kind>" only while the five values equal the picked spec (for a KB-only spec: while minKb, maxKb and format equal it, whatever width and height hold), and "Choose a form" otherwise (derived from current values). | US-4 | Must |
| FR-14 | Specs with `notCovered` entries shall show one fixed line per entry on their list row and on the target step while applied, as plain text with an icon, non-blocking, with no automatic fix. Strings are keyed by code (`dpi` takes a number placeholder); data never carries free-form note text. | US-5 | Must |
| FR-15 | The list shall end with one fixed line stating that ExactSize is not affiliated with the organisations listed. The list shall not use logos, official-looking styling or the words "official", "approved" or "guaranteed" in any preset string. A string test shall enforce the banned words (added to the FEAT-016 banned-claim check or run on its own, Stage 6). | US-5 | Should |
| FR-16 | If the library fails to load, the system shall replace the row with a short non-tappable message (section 8, "Load failure"), keep FEAT-005 fully working, never crash, never retry over a network, and log one enum code only. A spec that fails runtime validation shall be skipped. | US-6 | Must |
| FR-17 | The system shall write preset selections and search text nowhere: not to disk, logs, crash reports, analytics, counters (FEAT-027) or clipboard; and shall keep no recents, favourites or last-used list. | US-8 | Must |
| FR-18 | The feature shall make no network call, add no permission, and add no package or Gradle dependency that is not on the reviewed list [Fact](docs/features/FEAT-016-on-device-privacy/prd.md, FR-10, FR-12). Adding any of these follows the FEAT-016 change procedure. | US-8 | Must |
| FR-19 | A CI test (pure Dart) shall load the shipped data and fail on: unknown or missing fields; duplicate form ids; more than one spec of a kind per form; a spec failing FEAT-005 `checkTarget` or `validateTarget`; only one of width and height present; width or height below 16 px (a likely unit typo; the Product Owner may lower it with a change-log line); `dpi` outside 1–1200 [Assumption]; missing source title, issuer or `lastChecked`; `lastChecked` malformed or in the future; a country, category or note code with no string key in `app_en.arb`. This is the check FEAT-005 AC-9.3 assigns to this feature. | US-7 | Must |
| FR-20 | A CI integration test shall run every spec through the FEAT-002 and FEAT-004 pipeline on synthetic fixture images (no real person's photo) and report any spec that ends outside W×H or the KB range or returns "can't reach this size". A KB-only spec runs at a fixed synthetic test size chosen in the tech plan and recorded in the test. A report fails CI until the Product Owner marks the spec as reviewed in the data (reason field). It reuses the existing integration job pattern [Fact](docs/features/FEAT-016-on-device-privacy/prd.md, FR-16). | US-7 | Should |
| FR-21 | The release checklist shall print the form count and every form whose `lastChecked` is older than 90 days [Assumption], for the Product Owner to accept or fix, as an item inside FEAT-016's release checklist [Fact](docs/features/FEAT-016-on-device-privacy/prd.md, FR-13). | US-7 | Should |
| FR-22 | Every library change shall be recorded in `docs/CHANGELOG.md` with form id, source and date. | US-7 | Should |
| FR-23 | All UI strings (row label, list title, search hint, empty state, kind labels, summary patterns, notes, footer, load-failure message, country and category names) shall be in `app_en.arb` with descriptions and placeholders, and in the 5 other languages through FEAT-019 and `/l10n-translate`. Form names, issuers and source titles are data, shown as published. | US-9 | Must |
| FR-24 | Form names and issuers shall render with automatic text direction isolation so a Latin or Devanagari name inside an Arabic layout (and the reverse) does not reorder; digits shall be 0–9. | US-9 | Must |
| FR-25 | The list and the target-step row shall be designed with impeccable before building, jointly with the FEAT-005 preset row (Product Owner decision 2026-11-20): the Product Owner is told first [Fact](CLAUDE.md, Implementation). Data, loader and tests may proceed before that. | US-1 | Must |
| FR-26 | While a KB-only spec is applied, the target step shall show one fixed, non-blocking line under the row saying the form sets no pixel size and asking the user to enter a width and height or use the photo's size (FEAT-005 FR-12). Width and height then go through FEAT-005 validation as for manual entry; the app shall not propose, guess or "correct" a pixel size. | US-4, US-5 | Must |

## 7. Non-functional requirements
| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | The library loads and the list opens within 300 ms on the 2 GB emulator profile; search updates within 100 ms per keystroke; bundled data under 100 KB [Assumption for all three]. |
| NFR-2 | Accessibility | TalkBack reads a spec row as one item (AC-9.3); headings announced; touch targets at least 48 dp; no clipping at 200% font on 360×640 dp; notes not by colour alone; Material 3 contrast. |
| NFR-3 | Offline / poor network | Works in airplane mode with no network use. "Pick a preset" is added to the target-entry row of FEAT-016's offline matrix [Fact](docs/features/FEAT-016-on-device-privacy/prd.md, FR-14). |
| NFR-4 | Localisation | 6 languages (en, es-419, pt-BR, hi, id, ar with RTL); translations "AI-reviewed only", never "native-reviewed" [Fact](CLAUDE.md, Localization); short plain sentences; no idioms; placeholders and keys identical to `app_en.arb`. Residual translation risk is a [Hypothesis]. |
| NFR-5 | Privacy | Section 10. Keyboard learning off in search. No telemetry. |
| NFR-6 | Maintainability | Adding or changing a form is a data edit plus, for a new country or category, one string key; no code change otherwise. The data lives in one reviewable place (format is a Stage 6 choice, OQ-12). |
| NFR-7 | Testability | Cleaning, matching and validation are pure Dart with table-driven tests; one emulator drive at en, ar and hi at 200% font for states list, search, empty, picked, note. |
| NFR-8 | Robustness | No crash on 1,000 random search strings, a very long paste, or configuration changes (rotation, font scale, language) with the list open; search text and scroll position survive them. |
| NFR-9 | Compatibility | Android 9 (API 28) and later [Fact](docs/product/vision.md, platforms). |
| NFR-10 | Traceability | Every spec can be traced to a source title and a check date in the data. Real-world accuracy cannot be verified by software and is a Product Owner task (BRIEF 1.3). |

## 8. Validation rules
**Library data (checked by CI, FR-19)**

| Field | Rule | Failure message (CI) |
|---|---|---|
| form `id` | Lowercase slug, unique, not reused | "Form id [ID] is duplicated or not a valid slug." |
| `name`, `issuer` | Non-empty, as published | "Form [ID]: name and issuer are required." |
| `country` | ISO alpha-2 code with a name string | "Form [ID]: country [CODE] has no string key." |
| `category` | One of the fixed values, with a label string | "Form [ID]: unknown category." |
| `source.title`, `lastChecked` | Title non-empty; date valid, not in the future | "Form [ID]: source title and a valid last-checked date are required." |
| specs per form | 1–2, one per kind | "Form [ID]: 1–2 specs, one per kind." |
| width, height | Both present (whole numbers 16–10,000 each, W×H at most 24,000,000) or both null (KB-only spec) | "Form [ID] [KIND]: size outside engine limits." or "Form [ID] [KIND]: give both width and height, or neither." |
| `maxKb` / `minKb` | max 2–10,240; min null or 1 up to max minus 1 | "Form [ID] [KIND]: KB range invalid." |
| `format` | jpeg or png | "Form [ID] [KIND]: format must be jpeg or png." |
| `notCovered` | Known code, no repeats; `dpi` whole 1–1200 | "Form [ID] [KIND]: unknown or repeated note." |

**Search input**

| Input | Rule | Behaviour |
|---|---|---|
| Search text | Cleaned (case, diacritics, spaces, bidi marks, digit systems); no length limit beyond 100 characters [Assumption] | Text beyond 100 characters is cut; no error message; no match shows the empty state |

**New user-facing strings (English proposals; final wording after the design pass; translated by `/l10n-translate`)**

| Use | Proposed text |
|---|---|
| Row (none applied) | "Choose a form" |
| Row (applied) | "{form} · {kind}" |
| Kind labels | "Photo", "Signature" |
| Spec summary | "{width} × {height} px · {min}–{max} KB · {format}"; without minimum: "{width} × {height} px · up to {max} KB · {format}" |
| Spec summary, KB-only spec | "Any pixel size · {min}–{max} KB · {format}"; without minimum: "Any pixel size · up to {max} KB · {format}" |
| Note while a KB-only spec is applied | "This form sets no pixel size. Enter a width and height, or use your photo's size." |
| Search hint | "Search forms" |
| Empty state and action | "No form matches." and "Enter sizes yourself" |
| Note `dpi` | "This form also asks for {dpi} DPI. ExactSize does not set DPI." |
| Note `background` | "This form also has a background rule. ExactSize does not change backgrounds." |
| Note `content` | "This form also has other rules for this image. ExactSize does not check them." (wording after the G1 copy review) |
| Footer | "ExactSize is not affiliated with the organisations listed." |
| Load failure | "The form list could not be opened. You can enter sizes yourself." (wording after the es review, 2026-11-27) |

## 9. Edge cases & error states
| Case | Expected behaviour |
|---|---|
| Spec has a DPI rule | Picks normally; DPI note shown (FR-14). DPI is not part of the target and not written. If FEAT-010 ships, its PRD must say how a spec's DPI feeds it and change this note; until then the note stays. Portals may rarely read DPI metadata [Hypothesis, no research source]. |
| Spec has a background-colour rule | Picks normally; note says ExactSize does not change backgrounds. No colour is named in app text (colour comes from the user's notice). Background change is FEAT-028 (Later). |
| Spec has face-position or photo-age rules | Same fixed `content` note. FEAT-029 is Later. |
| FEAT-006 shows "meets spec" for a preset with a note | It means size, KB and format only. Wording risk on the preview is flagged in OQ-9; this PRD does not change FEAT-006. |
| Form states pixel size as a range, or in cm or mm at a DPI | The Product Owner picks one exact pixel value, and the source note (FEAT-014) records the choice. The engine outputs exact pixels only. |
| Form states only a KB limit | A KB-only spec (FR-3, OQ-3 decided). Picking it fills Minimum, Maximum and format; Width and Height keep what the user typed, and the FR-26 line asks for them. "Use photo size" (FEAT-005 FR-12) still works. |
| KB-only spec picked, then "Use photo size" on a large photo | Width and Height become the photo's size; if that size cannot reach the maximum KB, FEAT-004 shows its normal "can't reach this size" message. No preset-specific handling. |
| Form accepts JPEG or PNG | Preset uses one format: JPEG unless the form requires PNG (OQ-10). The user can switch format after picking. |
| Pick while manual values were typed | Values replaced (FR-11, OQ-8). |
| Pick, then edit one value | Row returns to "Choose a form" (FR-13). |
| Picked a photo preset, then a signature image is processed | Row still shows the photo preset until the user changes it, so the mismatch is visible (FEAT-005 OQ-13). |
| Search matches only an alias or country name | Form shown with its section heading. |
| Search with letters of another script than the UI | Plain substring match on cleaned text. Names with glyphs a device font lacks may show boxes; checked on the emulator for each script present [Assumption: system fonts]. |
| Name much longer than the row | Wraps; no truncation that hides the kind or size at 200% font. |
| Language or font scale changes with the list open | List stays open; localized parts re-render; form names unchanged; search text and scroll kept. |
| Back from list without picking | No change to the target step. |
| Data file corrupt, empty or missing | FR-16: row replaced by a short message; manual entry works. CI makes this unreachable in a release [Hypothesis]. |
| One country has many forms, others one | No cap; list uses a lazy list. |
| Two forms with equal numbers | Both stay; no merging. |
| Preset corrected in a new app version | Nothing persisted, so nothing on the device goes stale. A FEAT-012 saved copy would keep the old values (FEAT-012 concern). |
| User on a very old Android 9 phone, 2 GB RAM | Data is tiny (NFR-1); list uses lazy building. |
| Source URL present in data | Stored as text. Whether it is shown or tappable is FEAT-014's decision (OQ-13). |

## 10. Compliance & data privacy
- **Money / payments / PCI-DSS:** N/A. Presets hold pixel sizes, KB limits and formats. No card number, token, wallet, merchant credential or amount exists in the data or UI. PCI-DSS scope is not engaged [Assumption](docs/product/vision.md, compliance scope: payments only through the stores). No real card data appears in this document; any future example must use `[PLACEHOLDER]`.
- **Bangladesh Bank:** N/A for this feature. Nothing here moves, stores or authorises money, so payment-system rules do not apply [Hypothesis](docs/research/competitors.md, market notes). Ads and subscription (FEAT-025, FEAT-026) carry their own review.
- **Personal data stored:** None. The library is public facts about forms, bundled in the app. The user's choice of preset and search text live in memory only for the session (FR-17) and are never written, logged, counted or copied.
- **Privacy risk flagged:** the chosen form can reveal which job, exam, admission or visa a person is applying for, and for government jobs or minors that is sensitive [Assumption]. For that reason: no recents, favourites or last-used list; no log or crash detail with form ids or search text; FEAT-027 counters must not include preset ids; no remote fetch of presets in R1 (FEAT-013 would add a network call and needs the FEAT-016 change procedure).
- **Keyboard privacy risk (flag):** a keyboard can learn typed search text such as an exam name. The search field turns off suggestions, autocorrect and personalised learning (FR-9); Stage 6 verifies the options on the pinned Flutter version [Hypothesis].
- **Test data:** CI fixtures (FR-20) are synthetic images. No real person's photo or signature is committed to the repository.
- **Consent and retention:** No consent needed, as nothing is collected. Retention: until the app process ends. Play Data Safety and store label answers do not change because of this feature; FEAT-016's register is updated only if the answer to a FR-18 gate changes.
- **Bangladesh data-protection law:** not checked; nothing leaves the device, so there is no collection or transfer to assess [Hypothesis].
- **Copyright and trademark (flag, not legal advice):**
  - Names of exams, agencies and forms are used only to identify the form, as published. Proposed: no logos, no official styling, a "not affiliated" line (FR-15), no claim of being official or approved. App name, icon and store text must not imply endorsement; Google Play impersonation rules are the reviewer's lens [Assumption]. The Product Owner should seek legal advice before release (OQ-5).
  - Quoting circulars: only numeric facts (pixels, KB, format) and a short title as the source are stored. No circular text is copied. Dimensions and limits are facts, but copyright and database terms differ by country and by agency [Hypothesis]; check each source's terms before copying a title or adding a URL.
  - A wrong spec can cause a failed upload and a missed deadline. Accuracy claims are avoided; FEAT-014's source, date and prompt, plus the freshness list (FR-21), are the controls. Liability wording belongs to the Product Owner and counsel [PLACEHOLDER: terms and privacy policy URL].
- **Sensitive values in examples use `[PLACEHOLDER]`.** Test forms in this PRD are synthetic.

## 11. Dependencies
- **FEAT-005 (hard, implemented):** target model, validation (`checkTarget`, `validateTarget`), preset row space (OQ-10), digit cleaning (FR-4) [Fact](docs/features/FEAT-005-manual-target/prd.md).
- **FEAT-014 (release rule):** ships together. If it slips, the preset list is not released, because the preset values would show without source and date [Fact](docs/roadmap.md, FEAT-014 row; Phase A exit "every preset shows its source and last-checked date"). Release checklist item, no feature flag proposed.
- **FEAT-002 and FEAT-004:** engine limits and the CI fixture run (FR-20).
- **FEAT-006:** wording of "meets spec" for presets with notes (OQ-9).
- **FEAT-010:** DPI writing, if it ships, changes the DPI note (section 9).
- **FEAT-012:** saved copies of specs; must copy values, not reference built-in ids. **FEAT-009:** will need form-with-two-specs data, which FR-2 already provides; no UI here.
- **FEAT-013:** parked; the data model and file stay compatible with a later signed update file, but nothing is built for it.
- **FEAT-016:** no network, no permission, no new dependency, release checklist, offline matrix, banned-claim check [Fact](docs/features/FEAT-016-on-device-privacy/prd.md).
- **FEAT-019:** translations of new strings and of country and category names.
- **FEAT-027:** must not count preset ids.
- **Content input (blocking for release, not for approval):** the Product Owner's verified list of forms, with source title, issuer, check date and each value (OQ-1).
- **Design gate:** impeccable pass before building the screens (FR-25).
- **Stage 6 inputs:** data format, applied-preset state holder, string-test location, fixture images.

## 12. Open questions
Each has a recommended default; the default applies if the Product Owner does not answer.
- [ ] **OQ-1 (blocking for release, not for PRD approval) The list of 15–20 forms.** The Product Owner supplies forms, pixel and KB values, source titles, issuers and check dates. Research names candidate families only: Indian recruitment portals such as the MSTC careers page (photo 20–50 KB, signature 10–20 KB, no pixel size in our sources), Bangladesh and Indian exam presets seen on competitor pages, and visa/passport photos [Fact](docs/research/competitors.md); these are [Assumption] candidates, with no values copied here. Default: choose forms by (a) a citable public notice, (b) expected applicant volume, and (c) at least one or two per launch-language market where a notice exists, because research found no evidence for es, pt, id or ar markets [Hypothesis]. Update 2026-11-27: Claude drafts the candidates with cited sources and an independent AI check (`t15/draft_forms.md`, `t15/verification.md`); the Product Owner confirms each row.
- [ ] **OQ-2 (before design) One form with two specs, or flat presets.** Default: one form with 1–2 specs shown as separate tappable rows, so FEAT-009 later needs no data change. Alternative: a flat list of "Form photo" and "Form signature" rows, which doubles the rows (up to about 40).
- [x] **OQ-3 Forms with a KB limit but no pixel size.** Decided by the Product Owner on 2026-11-27: allowed as KB-only specs (FR-3, FR-11, FR-13, FR-26). Research found that many high-volume forms state only a KB limit and format (round 1 draft, `t15/draft_forms.md`), so excluding them would leave the list well short of 15–20.
- [ ] **OQ-4 Pixel ranges, cm or mm forms.** Default: the Product Owner picks one pixel value and records the choice in the source note (FEAT-014).
- [ ] **OQ-5 (before release) Legal check of naming and of source titles.** Default: nominative use only, no logos, not-affiliated line, no "official" wording; legal advice [PLACEHOLDER: counsel] before the store release.
- [ ] **OQ-6 Search in R1.** Default: Should; first cut if the budget slips, since about 40 rows can be scrolled. Not proposed: device-region-first ordering (the language region is unreliable, for example en-US in India [Hypothesis]); revisit if the closed test shows scrolling pain.
- [ ] **OQ-7 Row label after an edit.** Default: back to "Choose a form" (derived, no extra string). Alternative: "<form> (edited)".
- [ ] **OQ-8 Pick replaces typed values silently.** Default: yes, no confirmation (five numbers are quick to retype; FEAT-005 keeps no undo).
- [ ] **OQ-9 (before design) "Meets spec" wording in FEAT-006 for presets with notes.** The preview could read as "form-ready". Default: no FEAT-006 change in R1; the note stays on the list row and the target step. Alternative: a FEAT-006 change request to say "meets size, KB and format". Product Owner decides.
- [ ] **OQ-10 JPEG-or-PNG forms.** Default: JPEG unless the form requires PNG.
- [ ] **OQ-11 (Stage 6) Where the applied-preset reference lives.** Default: beside `TargetSpec` in session state; `TargetSpec` stays unchanged (FEAT-005 FR-9).
- [ ] **OQ-12 (Stage 6) Data format and fixture images.** JSON asset or Dart constants; synthetic fixtures. Default: whichever the architect finds easier to test and review.
- [ ] **OQ-13 Source URL.** Default: stored as text; FEAT-014 decides display. Opening a browser leaves the app and tells a website about the user's interest, and FEAT-016 allows no external link in the ad-free explainer [Fact](docs/features/FEAT-016-on-device-privacy/prd.md, FR-4), so no tappable link is proposed.
- [ ] **OQ-14 Freshness threshold.** Default 90 days [Assumption].
- [ ] **OQ-15 "Common sizes" group** (for example 300×300 px, max 100 KB, a default seen in another tool [Fact](docs/research/competitors.md, UX patterns)). Default: not included, since an entry without a notice has no source to show. Manual entry covers it.
- [ ] **OQ-16 Reporting a wrong spec.** Default: no in-app report (it needs a mail intent or a network call); the store listing carries a support contact [PLACEHOLDER]; the Product Owner triages reviews and mail.
- [ ] **OQ-17 Effort.** The roadmap gives 1.5 pw, including sourcing. Rough days [Assumption]: data model, loader, CI checks 2.0; list, search, notes, RTL and 200% font 2.0; impeccable pass 0.5; target-step wiring 0.5; strings in 6 languages 0.5; fixture CI run 0.5 = 6 days, about 1.2 pw of development plus the Product Owner's sourcing time (15–20 forms at roughly 20–30 minutes each, about 5–10 hours [Assumption]). Earlier features ran 2–3 times over their first estimates [Fact](docs/roadmap.md, Stage 6 re-estimate), so I show a range of 1.2–1.8 pw. No roadmap change proposed.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-27 | First draft; review fixes: one load-failure behaviour (message replaces the row), offline AC states Wi-Fi off |
| 1.0 | 2026-11-27 | Approved by the Product Owner (/approve FEAT-011); open-question defaults stand |
| 2.0 | 2026-11-27 | Scope change: KB-only specs allowed (OQ-3 decided; FR-3, FR-6, FR-11, FR-13, FR-19, FR-20 changed; FR-26, AC-4.7 to AC-4.9, two strings, two edge cases added); FR-1 and OQ-1 record the draft-then-confirm sourcing decision; section 8 strings updated to the wording now in the app |
| 2.0 | 2026-11-27 | Approved by the Product Owner (/approve FEAT-011) |
