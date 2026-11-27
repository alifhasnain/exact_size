---
id: FEAT-014
title: Preset source note and "check your notice" prompt
status: Proposed
version: 0.1
updated: 2026-11-27
links: [ROADMAP, BRIEF, RESEARCH, FEAT-005, FEAT-006, FEAT-011, FEAT-013, FEAT-016, FEAT-019, FEAT-025, FEAT-027]
---

# FEAT-014 — Preset source note and "check your notice" prompt

## 1. Overview
When a user picks a built-in form spec (FEAT-011), ExactSize shows where the spec came from (source title and issuer, optionally the website host) and when the Product Owner last checked it, plus a short fixed prompt to check the user's own notice before uploading. The same source and date appear on each form in the preset list. It is display only: no link, no network, no storage, no data schema change. A second prompt wording appears when the check date is more than 90 days old by the device clock. Release: MVP, R1 Phase A, Must, size S, roadmap effort 0.3 pw [Fact](docs/roadmap.md, FEAT-014 row). It ships with FEAT-011: the preset list is not released without it [Fact](docs/features/FEAT-011-preset-library/prd.md, section 11).

**What FEAT-011 already gives (not rebuilt here)**
- Each form has one `source` (title, optional URL as text) and one `lastChecked` date, both exposed on `PresetForm`; FEAT-011 built no UI for them [Fact](docs/features/FEAT-011-preset-library/prd.md, FR-4; lib/features/presets/domain/preset_types.dart).
- The list screen with form cards and spec keys, and the target-step row whose applied state is derived from the five values [Fact](docs/features/FEAT-011-preset-library/t09/preset_design.md; FEAT-011 FR-13).
- 17 real forms ship, each with a source title, URL and `lastChecked` 2026-11-27 [Fact](assets/presets/presets.json; brief from the Product Owner).

**Boundary:** FEAT-011 owns the data, the `notCovered` notes and the "not affiliated" footer. FEAT-014 owns the source note, the date, the prompt and their wording [Fact](docs/features/FEAT-011-preset-library/prd.md, section 1, boundary table).

## 2. Problem statement
**Who:** applicants, students, visa applicants and cyber café operators who copy a form's limits from a preset instead of reading the notice.
**Pain:** a stale or wrong preset makes the portal reject the upload, possibly at a deadline. Accuracy is kept by one person and shipped only with app releases, so every spec ages [Hypothesis](docs/features/FEAT-011-preset-library/prd.md, section 2). A phone that never updates the app keeps old specs for as long as it is installed [Hypothesis, no install-age data].
**Evidence:** every preset observed in competitor tools is sourced from a specific circular and tells users to check their own notice [Fact](docs/research/competitors.md, Market notes). How vendors keep presets current is not stated [Fact](docs/research/competitors.md, Market notes). The Product Owner decided FEAT-014 is required with FEAT-011 to limit stale-spec risk (Option B) [Fact](docs/roadmap.md, FEAT-014 row).
**Why now:** FEAT-011 is Implemented and its list shows spec values with no provenance. Releasing it as is would break the release rule.
**What the data looks like today [Fact](assets/presets/presets.json):** source titles are short page titles, and some are one generic word, so the title alone does not say which notice it is; 3 of 17 URLs use `http://`, not `https://`; there is no free-text note field.

## 3. Goals & success metrics
The app has no analytics and FEAT-016 allows no usage telemetry for this feature, so metrics are CI results, release checks and observation in the closed test [Fact](docs/features/FEAT-011-preset-library/prd.md, section 3). Test environment as FEAT-011 (2 GB emulator, API 28 and latest, en, ar, hi).

| Goal | Metric | Target |
|---|---|---|
| Provenance is always visible | Shipped forms whose target-step block and list card both show a non-empty source line and a date | 100% (17 of 17 today) |
| No extra effort to see it | Extra taps after picking a spec to see source and date | 0 |
| The prompt cannot be missed | Applied-preset states (en, ar, hi; fresh and old; KB-only spec) where the prompt is absent | 0 |
| Old specs are flagged | Table-driven stale cases (section 8) that fail | 0 |
| No link, network or trace | New permissions, dependencies, intents, clipboard use, log lines, counters, stored values caused by this feature | 0 |
| Honest wording | Banned words in the new English strings (FR-9) | 0 |
| Language | New strings in 6 languages; title, issuer, host and date never translated | 100% |
| Accessible | Clipped or overlapping text at 200% font, 360×640 dp, en, ar, hi, longest shipped issuer and title | 0 |
| Understood (closed test, observed by the Product Owner, informational) | Testers who can point to where a spec came from after picking one | at least 4 of 5 [Assumption: small sample] |
| Effect on rejected uploads | Not measurable without telemetry | no target [Hypothesis: the prompt reduces failed uploads] |

**Non-goals**
- Tappable links, "open source", "copy link", share, or any browser or external app launch (OQ-1, FEAT-011 OQ-13).
- Checking a spec against the web, remote or automatic refresh, or any date from a server (FEAT-013 is parked).
- An in-app "report a wrong spec" action (FEAT-011 OQ-16: the store listing carries the support contact [PLACEHOLDER]).
- An acknowledgement checkbox, a blocking dialog, or a stored "user was warned" flag (OQ-6).
- Source notes for manual entry, for saved presets (FEAT-012) or on the FEAT-006 preview (FEAT-011 OQ-9).
- Changing preset data, the `notCovered` notes or the not-affiliated footer (FEAT-011).
- Legal terms or disclaimers text (Product Owner and counsel, OQ-5).

## 4. User stories
Test data in acceptance criteria is synthetic and is not a claim about any real form. **Test Form A:** issuer "Test Issuer", source title "Test Notice A", URL `https://notice.example.test/page`, `lastChecked` 2026-03-05, photo and signature specs. **Test Form B:** as A, with a DPI note. **Test Form C:** KB-only spec, URL `[PLACEHOLDER]`.

- **US-1** As an applicant who just picked a spec, I want to see where it came from, when it was checked and a reminder to check my own notice, so that I can compare before I upload.
  - **AC-1.1** Given device date 2026-03-20 and Test Form A photo applied, when I look at the target step, then below the preset row and its FEAT-011 notes I see "Source: Test Notice A (Test Issuer)", "Website: notice.example.test", "Last checked: 2026-03-05" and the prompt "Check these sizes against your form's notice or instructions before you upload. They can change.", and Continue works as before.
  - **AC-1.2** Given the form has no URL, or the URL has no usable host (Test Form C), then the Website line is not drawn and the other lines are unchanged.
  - **AC-1.3** Given a spec is applied, when I edit any of the five values, then the block disappears together with the notes, and when I set the values back to the spec's, then it reappears (state derived as in FEAT-011 FR-13).
  - **AC-1.4** Given Test Form C (KB-only) is applied, then the FEAT-011 FR-26 line and the block are both shown, and at 200% font Continue is reachable by scrolling.
  - **AC-1.5** Given Test Form B (DPI note) is applied, then the DPI note comes first and the block after it, and nothing blocks Continue.
  - **AC-1.6** Given I tap or long-press any line of the block, then nothing happens: no browser, no selection handles, no copy menu, no navigation.
  - **AC-1.7** Given the library failed to load, or no spec is applied, then no block is shown and the screen is as FEAT-011 defines.
- **US-2** As an applicant browsing the list, I want each form's source and check date before I pick, so that I can judge it first.
  - **AC-2.1** Given the list is open, then each form card shows the Source line, the Website line when usable, and the Last-checked line once, between the issuer and category line and the first spec key, also for a form with two specs.
  - **AC-2.2** Given I search, then the lines on the remaining cards are unchanged.
  - **AC-2.3** Given TalkBack, then each spec key reads exactly as before (the source lines are not inside it), and the source lines are read after the form name and issuer line.
  - **AC-2.4** Given the list, then the "not affiliated" footer is still the last item, and the list shows no prompt (OQ-5).
- **US-3** As a user whose installed app is old, I want a stronger reminder when the spec has not been checked for a long time.
  - **AC-3.1** Given `lastChecked` 2026-03-05 and device date 2026-06-04 (91 days later), then the block shows the old-check prompt "These sizes were last checked more than 90 days ago. Check your form's notice or instructions before you upload." instead of the normal prompt.
  - **AC-3.2** Given device date 2026-06-03 (exactly 90 days), then the normal prompt shows.
  - **AC-3.3** Given device date 2026-03-01 (before `lastChecked`), then the normal prompt shows and nothing fails.
  - **AC-3.4** Given the old-check prompt, then Continue is not blocked and no value changes.
  - **AC-3.5** Given the device date changes while the app is open, when the block is next built (returning from the list, language change, resume), then the prompt is chosen again; there is no timer.
- **US-4** As a user whose application choice is private (shared phone, government job, minor), I want the source note to leave no trace and open nothing.
  - **AC-4.1** Given airplane mode and Wi-Fi off, then every state of the block and the list lines works with no delay and no network message.
  - **AC-4.2** Given the release build, then the merged manifest, the reviewed dependency list and the FEAT-016 scans pass with no new permission, package, Gradle dependency, intent or URL launcher.
  - **AC-4.3** Given I applied and viewed Test Form A, then no log line, crash detail, counter, clipboard entry or file contains the form id, source title, host, date or the fact that a prompt was shown (log-wrapper test plus code search, as FEAT-011 AC-8.2).
  - **AC-4.4** Given I close and reopen the app, then nothing about the earlier block remains.
- **US-5** As a user of any launch language, I want the note readable and usable.
  - **AC-5.1** Given Arabic, then the block and card lines are mirrored, title and issuer sit in first-strong isolates, host and date in left-to-right isolates, and digits are 0–9.
  - **AC-5.2** Given font scale 200% at 360×640 dp and the longest shipped issuer and title, then nothing is clipped or overlapped, there is no horizontal scroll, and every line wraps in full.
  - **AC-5.3** Given TalkBack, then the target-step block is one item read right after the row and its notes; icons are not announced; meaning is by text, not colour.
  - **AC-5.4** Given any of the 6 languages, then labels and prompts are translated, and title, issuer, host and date equal the data.
  - **AC-5.5** Given the banned-word test, then no new English string contains a banned word (FR-9).
- **US-6** As the Product Owner, I want checks that stop a broken or misleading source note from shipping, so that provenance is never blank or spoofed.
  - **AC-6.1** Given the 17 shipped forms, when a test builds the target-step text and the card text for each, then each has a non-empty source line and a date line.
  - **AC-6.2** Given three synthetic bad forms (a title with a bidi control character; a URL with user info, `https://[PLACEHOLDER]@notice.example.test`; a URL with the scheme `ftp`), when CI runs, then each fails with the form id and the rule.
  - **AC-6.3** Given a form with an empty source title or a null date that got past CI, when its block is built, then the prompt is shown, the missing line is left out, no text like "Source: ()" appears, and nothing crashes.
  - **AC-6.4** Given I re-check a form's source, then I update `lastChecked` and add a `docs/CHANGELOG.md` line; I do not change the date without a re-check (process, checked at review).

## 5. User flows
**Main flow**
1. The user picks a spec in the list (FEAT-011) and returns to the target step.
2. The row reads "<form> · <kind>". Below it: any `notCovered` notes (FEAT-011), then the source block: source line, website line if usable, last-checked line, the prompt.
3. The user compares with their notice, edits values if needed, taps Continue. Nothing is blocked.

**Alternate flows**
- Browse: in the list each form card shows source and date before any pick.
- Old check date (more than 90 days by the device clock): the prompt text changes (FR-6).
- Edit after pick: row, notes and block go away together (FR-7).
- KB-only spec: the FEAT-011 FR-26 line and the block both show.
- Language, font scale or rotation change: the block is rebuilt in place.

**Error flows**
- URL missing or unusable: the Website line is left out.
- Title empty or date null (corrupt data past CI): the prompt shows alone with the other lines left out.
- Library load failure: no row, no block (FEAT-011 FR-16).

## 6. Functional requirements
| ID | Requirement | Story | Priority (MoSCoW) |
|---|---|---|---|
| FR-1 | While a spec is applied (FEAT-011 FR-13 applied state), the target step shall show below the notes a source block: source line, website line when usable (FR-4), last-checked line, and the prompt (FR-5 or FR-6), as plain text with an icon. | US-1 | Must |
| FR-2 | In the list, each form card shall show the source line, the website line when usable and the last-checked line once per form, above its spec keys and outside them. The list shall show no prompt. | US-2 | Must |
| FR-3 | Source line: "Source: {title} ({issuer})" with title and issuer exactly as in the data, not translated. Last-checked line: "Last checked: {date}" with the date as `YYYY-MM-DD`, digits 0–9 in every language, built from the stored year, month and day with no time-zone conversion. A missing title or date leaves out its line. | US-1, US-2, US-5 | Must |
| FR-4 | Website line: "Website: {host}", the host part of `source.url` only. Shown only if the URL is absolute, `http` or `https`, with a non-empty host. Never the scheme, path, query or user info; never rewritten (no `http` to `https`). Otherwise the line is left out. | US-1, US-2 | Should |
| FR-5 | Prompt: one fixed string asking the user to check the figures against their form's notice or instructions before uploading. It never blocks, never asks for a tick, and changes no value. | US-1 | Must |
| FR-6 | If the number of calendar days from `lastChecked` to the device's local date is more than 90, the prompt shall be the old-check variant with the number 90. If the device date is on or before `lastChecked`, or the days are 90 or fewer, the normal prompt shows. The device clock is the only source; no network time. The 90 is the same constant FEAT-011 FR-21 uses [Assumption: 90 days]. | US-3 | Should |
| FR-7 | The block shall exist only while the preset row is in its applied state and be rebuilt from current data each time it is built (no timer, no cache). | US-1 | Must |
| FR-8 | Block and card lines shall not be interactive: no tap or long-press handler, no link span, no selectable text, no URL launcher, intent or browser call, no clipboard. | US-1, US-4 | Must |
| FR-9 | All new labels and prompts shall be in `app_en.arb` with descriptions and placeholders and translated into es, pt (pt-BR), hi, id and ar through FEAT-019 and `/l10n-translate` (status `AI-reviewed only`). Title, issuer, host and date are data, passed as placeholders, never translated. A string test shall fail if any new English string contains: "official", "approved", "guaranteed" (FEAT-011 FR-15) or "verified", "accurate", "up to date", "latest", "current", "certified", "compliant". | US-5 | Must |
| FR-10 | A test shall build the target-step text and card text for every shipped form and fail if the source line or the date line is empty. | US-6 | Must |
| FR-11 | The FEAT-011 CI data test shall also fail on: a source title or issuer longer than 100 characters [Assumption]; any bidi control character (embedding, override, isolate or direction mark) or C0/C1 control character in title or issuer; a `source.url` that is not absolute `http` or `https` with a host and no user info. Each message names the form id and rule. Joiners used in Indic and Arabic scripts shall not be rejected. | US-6 | Should |
| FR-12 | The feature shall make no network call, add no permission, package or Gradle dependency, write nothing to disk, logs, crash reports, counters (FEAT-027) or clipboard, and log no form id, title, host or date. Showing a block or a prompt shall not be counted. | US-4 | Must |
| FR-13 | The block and card lines shall be designed with impeccable as a short addition to the FEAT-011 screens, after the Product Owner is told first [Fact](CLAUDE.md, Implementation). Pure functions (host, date, age, strings) and tests may proceed before. | US-1, US-2 | Must |
| FR-14 | `lastChecked` shall change only when the Product Owner re-checked the form's source; each change is recorded in `docs/CHANGELOG.md` (FEAT-011 FR-22). | US-6 | Should |

## 7. Non-functional requirements
| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | No extra file read or async step; list open stays within FEAT-011 NFR-1 (300 ms on the 2 GB emulator) [Assumption]. |
| NFR-2 | Accessibility | Block read as one TalkBack item after the row and notes; card lines in reading order; no touch target added; no clipping at 200% font on 360×640 dp; text plus icon, never colour alone; existing Booth colour pairs (WCAG AA) [Fact](docs/features/FEAT-011-preset-library/t09/preset_design.md). |
| NFR-3 | Offline / poor network | Works in airplane mode; the date logic reads only the device clock. Add "see source note" to the preset row of FEAT-016's offline matrix [Fact](docs/features/FEAT-016-on-device-privacy/prd.md, FR-14). |
| NFR-4 | Localisation | 6 languages (en, es-419, pt-BR, hi, id, ar with RTL), Western digits in ar, short plain sentences, no idioms; "AI-reviewed only", never "native-reviewed" [Fact](CLAUDE.md, Localization). The word "notice" may not map to the same document in every market; the back-translation review checks it (OQ-4). Residual translation risk is a [Hypothesis]. |
| NFR-5 | Privacy | Section 10. No telemetry, no trace of the displayed form. |
| NFR-6 | Testability | Host extraction, date formatting, age calculation and string choice are pure Dart with an injectable clock and table-driven tests; one emulator check per key state at en, ar, hi, 200% font. |
| NFR-7 | Robustness | No crash on empty, very long or odd titles, URLs without host, invalid dates, a device clock far in the past or future, or configuration changes with the block visible. |
| NFR-8 | Compatibility | Android 9 (API 28) and later [Fact](docs/product/vision.md, Platforms). |
| NFR-9 | Supply chain | No new package, plugin, WebView or network library (FEAT-016 FR-10, NFR-10). |

## 8. Validation rules
There is no user input. Rules apply to data and build inputs; CI messages are for the developer.

| Field / input | Rule | Message or behaviour |
|---|---|---|
| `source.title` (CI) | Non-empty (FEAT-011); at most 100 characters; no bidi or C0/C1 control characters | "Form [ID]: source title is empty, too long or has control characters." |
| `issuer` (CI) | Same length and character rules | "Form [ID]: issuer is too long or has control characters." |
| `source.url` (CI, optional) | Absolute `http` or `https`, host present, no user info | "Form [ID]: source URL must be http or https with a host and no user info." |
| `lastChecked` (CI) | Present, valid, not in the future (FEAT-011 FR-19) | existing FEAT-011 message |
| Title empty at runtime | Source line left out; prompt still shown | no message |
| Date null at runtime | Last-checked line left out; normal prompt shown | no message |
| URL unusable at runtime | Website line left out | no message |
| Device date vs `lastChecked` | Calendar days; more than 90 gives the old-check prompt; on or before `lastChecked` gives the normal prompt | see table below |

**Stale cases for the table-driven test (`lastChecked` 2026-03-05)**

| Device date | Days | Prompt |
|---|---|---|
| 2026-03-01 | before | normal |
| 2026-03-05 | 0 | normal |
| 2026-06-03 | 90 | normal |
| 2026-06-04 | 91 | old-check |
| 2099-01-01 | very large | old-check |
| 1970-01-01 | before | normal |

**New user-facing strings (English proposals; keys and final wording after the design pass and copy review; translated by `/l10n-translate`)**

| Use | Proposed text |
|---|---|
| Source line | "Source: {title} ({issuer})" |
| Website line | "Website: {host}" |
| Last-checked line | "Last checked: {date}" |
| Prompt | "Check these sizes against your form's notice or instructions before you upload. They can change." |
| Prompt, old check | "These sizes were last checked more than {days} days ago. Check your form's notice or instructions before you upload." |

## 9. Edge cases & error states
| Case | Expected behaviour |
|---|---|
| Source title is one generic word | Shown as published, with the issuer in brackets and the host line when present, so the note still identifies the page. The Product Owner may reword a title in the data if it misleads. |
| Long issuer or title | Wraps in full; no ellipsis; no fixed height. |
| URL stored as `http://` | Only the host is shown; scheme never shown; never upgraded or rewritten. |
| URL with port, IP address, upper case, non-Latin host | Host shown as parsed, no conversion; left-to-right isolate. |
| URL missing, empty, relative or `[PLACEHOLDER]` | Website line left out. |
| Same host on many forms | Shown on each; no merging. |
| Date null or unparsable at runtime | Last-checked line left out; CI makes this unreachable in a release [Hypothesis]. |
| Time zone far from UTC | Date shown from its stored y/m/d; no off-by-one. |
| Device clock wrong or set to the past | Normal prompt; date line still shows, so the user can judge. |
| Device clock set far ahead | Old-check prompt; harmless and not blocking. |
| App never updated | The old-check prompt is the only in-app signal; presets change only with app releases [Fact](docs/product/vision.md, open questions) [Hypothesis: many users update late]. |
| Edit one value after picking | Block and notes go away (FEAT-011 FR-13); the prompt is not kept for hand-edited values. |
| KB-only spec applied | FEAT-011 FR-26 line plus the block; several lines at 200% font, so the screen scrolls and Continue stays reachable. |
| Spec with DPI, background or content note | Note first, block after. |
| Two specs of one form | Source shown once per card in the list; the same source on the target step for either spec. |
| Library empty or load failure | Nothing shown. |
| Language or font change with block visible | Rebuilt in place; data text unchanged. |
| Source title in another script than the UI | Shown as is; glyph boxes possible on some fonts (FEAT-011 edge case; checked per script on the emulator). |
| Prompt always visible, so users stop reading it | [Hypothesis] The old-check variant is the only difference in R1; no metric can test it. |
| Screenshot of the target step | Shows the form name and source; on the user's own device, not blocked, no claim made (as FEAT-011). |
| Ads later (FEAT-025) | Ads must not receive or use the form, category, source or date (section 10). |

## 10. Compliance & data privacy
- **Money / payments / PCI-DSS:** N/A. The feature shows public text (source title, issuer, website host) and a date about a form's size rules. No card number, token, wallet, merchant credential or amount exists in the data or UI, and the screen takes no payment [Assumption](docs/product/vision.md, Compliance scope: payments only through the stores). App text must never say "PCI-DSS compliant" or borrow any certification of the publisher's organisation (the banned-word test, FR-9; FEAT-016 FR-5). No real card data appears in this document; any future example uses `[PLACEHOLDER]`.
- **Bangladesh Bank:** N/A for this feature. Nothing moves, stores or authorises money, and ExactSize is not a payment instrument or service, so no payment-system rule is engaged [Hypothesis](docs/research/competitors.md, Market notes). No circular was checked. Several shipped forms come from Bangladesh issuers, which does not change this reading. Revisit if the product takes payments itself.
- **Personal data collected, purpose, retention, consent:** none collected, none stored. The block shows public facts and is built in memory from the bundled data and the device date. The device date is read locally for the age check, never stored or sent. No consent is needed because nothing is collected [Assumption: legal reading, FEAT-011 OQ-5 and FEAT-016 OQ-7]. Retention: until the screen closes.
- **Privacy risks flagged proactively**
  1. **The chosen form reveals the application** (job, exam, admission, visa); sensitive for government jobs and minors [Assumption]. The note adds the form's source and host to that screen, so it gets the same rules as the pick itself: nothing on disk, in logs, crash reports, counters or the clipboard (FR-12), no "recent" list.
  2. **Why there is no link.** Opening a browser tells the website, the network and the browser history which notice the user opened, and a cyber café phone is shared, so the next user can read that history [Hypothesis]. 3 of the 17 shipped URLs are `http://`, which travel unencrypted [Fact](assets/presets/presets.json). So the host is shown as text only; the user may type it themselves, on their own initiative. This follows FEAT-011 OQ-13 and FEAT-016 FR-4 [Fact](docs/features/FEAT-016-on-device-privacy/prd.md, FR-4).
  3. **Selectable text and clipboard:** not used (FR-8), so no copy of the host or form name reaches the clipboard, which other apps can read [Hypothesis].
  4. **No rewriting of sources:** the app never changes a URL to `https`, because that would claim a source says something it does not.
  5. **Spoofed or hidden text in data:** the data is bundled and CI-checked, but a bidi control character could reorder displayed text (FR-11).
  6. **Ads (FEAT-025):** the ad SDK must not receive or target on the chosen form, category, source or date. Proposed carried requirement for the FEAT-025 PRD, beside FEAT-016 FR-19(a).
  7. **Counters (FEAT-027):** must not count block views, old-check prompts or form ids (FEAT-016 NFR-6 pattern).
  8. **Local data-protection law** in the launch markets, including Bangladesh, was not checked; nothing leaves the device, so there is no collection or transfer to assess [Hypothesis].
- **Claims register (FEAT-016):** no new claim, no change to C1–C10. The words "last checked" must not be read as "verified", "accurate" or "official", so those words are banned (FR-9).
- **Liability and wording (flag, not legal advice):** the prompt and the date reduce the chance that a user relies on a stale spec; they are not a legal shield [Hypothesis]. Final wording of any disclaimer, and whether the target step also needs the "not affiliated" line (today only on the list), belong to the Product Owner and counsel [PLACEHOLDER: counsel; terms and privacy policy URL]. Naming issuers and showing a website host is nominative use; no logos or official styling (FEAT-011 FR-15). Covered by the FEAT-011 OQ-5 legal check.
- **Test data:** synthetic forms only. Device screenshots for this feature use a local, uncommitted synthetic fixture over `assets/presets/presets.json`, as FEAT-011 did.
- Sensitive values in examples use `[PLACEHOLDER]`.

## 11. Dependencies
- **FEAT-011 (Implemented):** data model, list screen, target-step row, applied-state derivation, the 90-day constant (FR-21), the CI data test and banned-word string test to extend. No FEAT-011 PRD change is needed, because OQ-13 hands URL display to this feature. If OQ-1 stays at its default, one code comment must change: `PresetSource.url` says "never opened or shown" [Fact](lib/features/presets/domain/preset_types.dart).
- **FEAT-005:** the target step and its layout.
- **FEAT-016:** no network, permission or dependency; offline matrix row; banned-claim check; claims register unchanged. FEAT-016 gates already scan new files under `lib/`.
- **FEAT-019:** five new strings, five languages.
- **FEAT-006:** no change here; the "meets spec" wording question stays FEAT-011 OQ-9.
- **FEAT-025 and FEAT-027:** carried constraints (section 10, flags 6 and 7).
- **FEAT-013 (parked):** if remote presets ever ship, "last checked" becomes per file or per download and this PRD changes.
- **Design gate:** impeccable lean pass before building the visible parts (FR-13).
- **Content and legal:** counsel input on wording and the not-affiliated line [PLACEHOLDER] (FEAT-011 OQ-5), blocking for release, not for approval.
- **Release rule:** ships with FEAT-011; the preset list is not released without it. Release checklist item, no feature flag.

## 12. Open questions
Each has a recommended default; the default applies if the Product Owner does not answer.
- [ ] **OQ-1 Show the URL?** Default: show the host only, as plain text, not tappable (FR-4). It makes generic source titles identifiable, costs about 10 lines, and shows no `http://`. Alternatives: show nothing (smallest, FR-4 dropped); show the full URL (long, wraps badly at 200% font, links rot, shows `http://`). Not proposed: any tappable or copyable link (section 10, flags 2 and 3).
- [ ] **OQ-2 Date format.** Default: `YYYY-MM-DD` (unambiguous, no month names to translate, no digit exception in Arabic). Alternative: a localised medium date such as "5 Mar 2026" with digits forced to 0–9; needs month names in 6 languages and a check of Arabic digits.
- [ ] **OQ-3 Old-check prompt in R1.** Default: include it (FR-6, Should): it is the only in-app control for an install that never updates. Alternative: one prompt only, the first cut if the budget slips. The device clock may be wrong (section 9).
- [ ] **OQ-4 Wording and the word "notice".** Default: "notice or instructions" (a passport or exam rules page is not always a "notice"); final text after the design pass and the copy review, then a check in back-translation for each language.
- [ ] **OQ-5 Prompt on the list too.** Default: no. The list shows source and date per form; the prompt appears where values are applied. Alternative: one line under the search field.
- [ ] **OQ-6 Acknowledgement before Continue.** Default: none. A tick adds friction, proves nothing, and storing it would be user data. Counsel may advise otherwise [PLACEHOLDER: counsel].
- [ ] **OQ-7 Recording a chosen pixel value (gap in FEAT-011).** FEAT-011 says that when a form states a range or cm and mm, the Product Owner picks one pixel value and the source note records the choice (section 9 and OQ-4 there). The data has no free-text field and FEAT-011 AC-5.5 forbids free text in notes, so FEAT-014 cannot show it. Default: not shown in-app in R1; the choice is recorded in the form's verification record and `docs/CHANGELOG.md`, and the generic prompt covers it. Alternative: a fixed note code (a FEAT-011 data and string change, major version bump). Whether any of the 17 shipped forms needed such a choice is not known to me; the Product Owner knows.
- [ ] **OQ-8 Runtime behaviour when title or date is missing.** Default: show the prompt, leave out the missing line, never crash (FR-3, AC-6.3). Alternative: skip the whole form at load, like an invalid spec (FEAT-011 AC-6.2). CI already blocks this data, so the choice matters only if CI is bypassed.
- [ ] **OQ-9 Placement.** Default: on the target step, notes first and the block after; in the list card, between the issuer line and the spec keys. Decided in the impeccable pass.
- [ ] **OQ-10 Not-affiliated line on the target step.** Default: no (the block is a source citation, and FEAT-011 puts the footer on the list). Counsel to confirm with FEAT-011 OQ-5 [PLACEHOLDER: counsel].
- [ ] **OQ-11 Effort.** The roadmap says 0.3 pw. Rough days [Assumption]: pure functions and tests 0.5; target-step block and wiring 0.75; list card lines 0.5; strings in 6 languages through `/l10n-translate` 0.5; lean design pass 0.25; CI data rules 0.25; emulator checks at en, ar, hi 0.25 = 3 days, about 0.6 pw. Earlier features ran 2–3 times over their first estimates [Fact](docs/roadmap.md, Stage 6 re-estimate), so I show 0.4–0.9 pw. At 0.6 pw the RICE score would be about 5,300 instead of 10,667 (same Reach, Impact and Confidence); I did not compare it with the rest of the backlog. No roadmap change proposed.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-27 | First draft |
