---
id: FEAT-005
title: Manual target entry (W×H, KB min/max, format)
status: Implemented
version: 1.1
updated: 2026-11-24
links: [ROADMAP, BRIEF, RESEARCH, ADR-001, FEAT-001, FEAT-002, FEAT-004, FEAT-006, FEAT-008, FEAT-010, FEAT-011, FEAT-012, FEAT-014, FEAT-015, FEAT-016, FEAT-019, FEAT-027]
---

# FEAT-005 — Manual target entry (W×H, KB min/max, format)

## 1. Overview
The target step of the flow. After a photo is accepted, the user types the form's limits: width and height in pixels, an optional minimum and a required maximum size in KB, and the output format (JPEG or PNG). The step validates them with the rules FEAT-002 and FEAT-004 already enforce, then hands one target value to crop (FEAT-002) and compression (FEAT-004). Everything runs on the device. Release: MVP (R1 Phase A), Must [Fact](docs/roadmap.md, FEAT-005 row).

**Contract (one target model for FEAT-005 and FEAT-011)**

| Item | Contract |
|---|---|
| Input | `PickedImage` from FEAT-001 (this step reads only the source size and EXIF orientation, never pixels), optionally values filled in by FEAT-011. |
| Output | One immutable target value (working name `TargetSpec`): `width`, `height` (int px), `minKb` (int, null = no minimum), `maxKb` (int), `format` (jpeg or png). It maps to FEAT-002 `Target(width, height)` [Fact](lib/features/crop/domain/crop_types.dart) and FEAT-004 `ValidTarget(minKb, maxKb, format)` [Fact](lib/features/compression/domain/target_validator.dart). |
| Sharing with FEAT-011 | One model, one validation path, one screen. FEAT-011 fills the same fields programmatically; every value still goes through section 8 on Continue. The model has no preset-specific field in R1; whether FEAT-011 adds a nullable source reference (for FEAT-014) is decided in its PRD. How the preset entry sits on the screen is a joint design decision (OQ-10). FEAT-005 must work alone first, because it ships before FEAT-011 in Phase A [Fact](docs/roadmap.md, Milestones). |
| Replaces | The dev-only placeholder screen `_NextStepPlaceholder` [Fact](lib/app.dart). |

## 2. Problem statement
Applicants, students, visa applicants and cyber-café operators fill forms that state exact limits, for example photo 20–50 KB and signature 10–20 KB [Fact](docs/research/competitors.md, Gap 1 and A4). The preset library (FEAT-011) will cover only about 15–20 forms [Fact](docs/roadmap.md, FEAT-011 row) while the market is global, so manual entry is the only way to reach the long tail, and the only way at all until presets ship. Most tools reviewed offer max-only or fixed KB targets [Fact](docs/research/competitors.md, feature comparison); a min–max range as input is the product's differentiator.

Pain points this feature must remove:
- Typing errors with no feedback (30 for 300, "7,5" for 7.5, a thousands separator read as a decimal) that surface late, as a wrong crop or a failed export.
- Digits typed on an Arabic or Hindi keyboard that a plain integer parser rejects. [Fact](lib/features/compression/domain/target_validator.dart) uses `int.tryParse`, which accepts Western digits only.
- A form that lists only a KB limit, while FEAT-002 needs a width and height [Fact](docs/features/FEAT-002-crop-resize/prd.md, FR-1).

Honest limit: typing four numbers on a numeric keypad probably takes 10–20 s [Hypothesis], so the vision's "under 30 s from open to export" median [Fact](docs/product/vision.md, success metrics) is realistic through presets, not through manual entry (OQ-14).

## 3. Goals & success metrics
Test environment as FEAT-002 section 7 (emulators, 2 GB RAM profile, API 28 and latest). Timing is best effort.

| Goal | Metric | Target |
|---|---|---|
| Only valid targets go on | Invalid targets reaching FEAT-002 or FEAT-004 in the section 9 table-driven test and a 1,000-input random run | 0 |
| No new limits | Limits typed into FEAT-005 code instead of read from the shared constants (`maxTargetSide`, `maxTargetPixels`, `maxKbLimit`, `minMaxKb`) | 0 |
| Fast entry | Taps other than typing, from screen open to hand-over (max-only target, JPEG) | 1 (Continue) |
| Entry time | Median from screen open to Continue, four values, closed test | ≤ 20 s [Assumption], informational |
| Locale input | Test strings in 4 digit systems read to the right number | 100% |
| Accessible | Clipped or overlapping controls at 200% font in en and ar, 360×640 dp [Assumption], states empty / filled / error | 0 |
| Privacy | Target values on disk, in logs or in crash reports | 0 |

**Non-goals (out of scope in R1)**
- Preset list, preset source note, saved presets: FEAT-011, FEAT-014, FEAT-012.
- Print size, mm / cm / inch input, DPI conversion: DPI metadata is FEAT-010 (Could); unit conversion is not in the backlog (OQ-2).
- MB input or a KB/MB switch; decimal KB (FEAT-004 OQ-5: whole KB only) [Fact](docs/features/FEAT-004-kb-range-compression/prd.md).
- Output formats other than JPEG and PNG; PDF [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, non-goals).
- Fit/pad or other resize modes (FEAT-008); content rules such as face position.
- Predicting whether a KB range is reachable (FEAT-004 outcome, FEAT-015 guidance).
- Pasting "300x300" into one field to fill two; a photo thumbnail on this screen; persistence across launches (OQ-1).

## 4. User stories
- **US-1** As an applicant whose form says "300×300 px, max 100 KB", I want to type those numbers and continue, so that every later step uses my form's limits.
  - **AC-1.1** Given the target step opened after an accepted photo, when I look at it, then I see Width, Height, Minimum size (optional), Maximum size and Format with JPEG selected, and no field is pre-filled on the first photo of a fresh app start.
  - **AC-1.2** Given I type 300 in Width, 300 in Height and 100 in Maximum and leave Minimum empty, when I tap Continue, then the target (300, 300, no minimum, 100 KB, JPEG) is handed on and the crop step opens.
  - **AC-1.3** Given the keypad is open on Width, when I press the keyboard's Next action, then focus moves Width, Height, Minimum, Maximum in reading order (right to left in Arabic), and Done on Maximum closes the keyboard.
- **US-2** As an applicant whose form has a floor and a ceiling (photo 20–50 KB), I want to enter both, so that the file is never too small.
  - **AC-2.1** Given Minimum 20 and Maximum 50, when I tap Continue, then minKb 20 and maxKb 50 are handed on.
  - **AC-2.2** Given Minimum 50 and Maximum 20, when I tap Continue, then "Minimum must be smaller than maximum." appears next to Minimum and nothing is handed on.
  - **AC-2.3** Given Minimum 50 and Maximum 50, when I tap Continue, then the same message appears (FEAT-004 requires min < max; OQ-6).
  - **AC-2.4** Given Minimum 49 and Maximum 50, when I tap Continue, then the target is accepted; the narrow-range notice is shown later by FEAT-004 [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, section 8).
- **US-3** As a user who mistypes, I want a short, plain message beside the field, so that I fix it in one step.
  - **AC-3.1** Given Width is empty or 0, when I tap Continue, then "Enter a width and height between 1 and 10,000 pixels." appears under the size row, focus moves to the first invalid field, TalkBack announces the message, and nothing is handed on.
  - **AC-3.2** Given Width 6001 and Height 4000, when I tap Continue, then "That size is too large for this app. Choose a smaller size." appears and nothing is handed on.
  - **AC-3.3** Given Maximum "7.5" or "7,5", when I tap Continue, then "Use whole numbers of KB." appears next to Maximum.
  - **AC-3.4** Given an error is showing on a field, when my edit makes the value valid, then the error disappears at once, before I tap Continue.
  - **AC-3.5** Given several fields are invalid, when I tap Continue, then each shows its own message, not only the first.
- **US-4** As a student whose form requires PNG, I want to switch format with one tap.
  - **AC-4.1** Given the screen is open, when I tap PNG, then only PNG is selected and Continue hands on `png`.
  - **AC-4.2** Given any state, then exactly one format is selected and the selection cannot be cleared.
  - **AC-4.3** Given TalkBack is on, then each option is announced with its name and selected state.
- **US-5** As a user whose keyboard types Arabic-Indic or Devanagari digits, I want my numbers understood.
  - **AC-5.1** Given "٣٠٠" in Width, when I leave the field or tap Continue, then the value is read as 300 and the field shows 300.
  - **AC-5.2** Given "۳۰۰" or "३००", then the value is read as 300.
  - **AC-5.3** Given "1,000", "1.000" or "٧٫٥", then the entry is treated as not whole and the whole-number message appears; the app never guesses what a separator means.
  - **AC-5.4** Given the app language is Arabic, then the layout is mirrored, and digits and the units "KB" and "px" show inside left-to-right isolates, without jumbled order.
- **US-6** As a user with large text or a screen reader, I want the screen to stay usable.
  - **AC-6.1** Given font scale 200% on a 360×640 dp screen with the keyboard open, then no label, field or message is clipped or overlapped, there is no horizontal scroll, and I can scroll to Continue.
  - **AC-6.2** Given TalkBack is on, then each field is announced with label, unit, required or optional, value and error.
  - **AC-6.3** Given any control, then its touch target is at least 48 dp.
- **US-7** As a user with a small photo, or a form that lists only a KB limit, I want to know early and be helped.
  - **AC-7.1** Given the photo is 200×200 px and the target 300×300, then a non-blocking notice "Your photo is smaller than this size. It will be enlarged and may look soft." shows and Continue works.
  - **AC-7.2** Given Width 10 and Height 10, then a non-blocking notice "Very small image. Check the size on your form." shows.
  - **AC-7.3** Given the photo is 4000×3000 px, when I tap "Use photo size", then Width 4000 and Height 3000 are filled; given a photo that breaks the section 8 size rules (for example 12,000 px wide), then the action is not shown.
  - **AC-7.4** Given a phone photo with EXIF rotation, then the "Your photo" line shows the size as the user sees it (3000×4000, not 4000×3000).
- **US-8** As a user who goes back from crop, I want my values kept, so that I do not retype.
  - **AC-8.1** Given I continued to crop and press Back, then the target step shows the same values.
  - **AC-8.2** Given I rotate the device, change font size or change language, then the values stay and messages re-render in the new language.
  - **AC-8.3** Given I close the app, then nothing was written to storage and the next launch starts empty (OQ-1 default).
- **US-9** As an applicant who picked a preset (FEAT-011), I want to adjust any prefilled value, so that I can fix a form that changed.
  - **AC-9.1** Given FEAT-011 filled the fields, when I edit one, then it behaves as manual entry and is validated the same way.
  - **AC-9.2** Given preset values, when I tap Continue, then the hand-over and validation are identical to manual entry.
  - **AC-9.3** Given every preset in the library, then its values pass section 8 (a test owned by FEAT-011, calling FEAT-005's validation function).

## 5. User flows
**Main flow**
1. FEAT-001 hands over an accepted `PickedImage` (photo first, FEAT-001 OQ-4) [Fact](docs/features/FEAT-001-pick-image/prd.md, section 5 step 6).
2. The target step opens: a line "Your photo: W × H px" (Should), then the five inputs. Values come from the session if any (OQ-1), else empty with JPEG selected.
3. The user types; Next moves between fields; a field shows its error when focus leaves it.
4. The user taps Continue. The app cleans and normalises the text (FR-4), validates (section 8), and on success hands `TargetSpec` and the photo to crop (FEAT-002). Then FEAT-004, FEAT-006, FEAT-007.

**Alternate flows**
- Preset: FEAT-011 fills the fields; the user may edit; Continue as above.
- "Use photo size" fills Width and Height from the photo (FR-12).
- Back from this step is start-over: the photo is released by the app flow [Fact](docs/features/FEAT-001-pick-image/prd.md, FR-11; lib/app.dart). Typed values stay in the session.
- Back from crop returns here with values intact. If the user changes the size, crop restarts with the new ratio (behaviour owned by FEAT-002, to confirm in Stage 6).

**Error flows**
- Invalid input: per-field messages, focus on the first invalid field, nothing handed on.
- A photo that can no longer be read is reported by FEAT-002 at render time; this step never opens the photo.

## 6. Functional requirements
| ID | Requirement | Story | Priority |
|---|---|---|---|
| FR-1 | The system shall show a target step after each accepted photo, with Width (px), Height (px), Minimum size (KB, labelled optional), Maximum size (KB) and Format (JPEG, PNG), replacing the dev-only placeholder. | US-1 | Must |
| FR-2 | Format shall default to JPEG [Assumption, OQ-3], exactly one format shall always be selected, and the choice shall be a single-select control. | US-4 | Must |
| FR-3 | The four number fields shall use a digit keypad, with autocorrect, suggestions and keyboard personalised learning off, a Next action in reading order, and Done on the last field closing the keyboard. | US-1 | Must |
| FR-4 | Before validation the system shall (a) remove whitespace and bidi control characters (U+200E, U+200F, U+061C, U+202A–U+202E, U+2066–U+2069); (b) convert digits of these systems to 0–9: Arabic-Indic U+0660–0669, Extended Arabic-Indic U+06F0–06F9, Devanagari U+0966–096F (Bengali U+09E6–09EF, Could, OQ-11); (c) convert the separators `,` `٫` `٬` to `.` so that they fail as non-whole; (d) treat a digit string longer than 9 digits as 999999999 (no overflow). Leading zeros are allowed. The field shall then show the cleaned value. | US-5 | Must |
| FR-5 | Width and Height shall be validated as whole numbers 1 to 10,000 each and W×H at most 24,000,000, using the shared constants and messages of FEAT-002 section 8 (`checkTarget`). A non-whole entry shall give the new message in section 8. | US-3 | Must |
| FR-6 | Min KB and Max KB shall be validated with the FEAT-004 rules and messages (`validateTarget`): max required, 2–10,240; min optional, at least 1 and below max; whole numbers only. No other limit shall be added. | US-2, US-3 | Must |
| FR-7 | Errors shall not show while the user first types in a field; they shall show when focus leaves the field or on Continue; once shown they shall update on every change and disappear when fixed. Each message shall sit next to the field it concerns (the size row for W/H messages), shall be short, and shall not rely on colour alone. | US-3 | Must |
| FR-8 | Continue shall always be enabled. On invalid input it shall show all current errors, move focus to the first invalid field, announce it to TalkBack, and hand nothing on. On valid input it shall hand on one `TargetSpec` and the photo. | US-1, US-3 | Must |
| FR-9 | `TargetSpec` shall be the only thing FEAT-005 and FEAT-011 hand to FEAT-002 and FEAT-004. Fields shall be settable by code (FEAT-011) and validation shall be callable without the screen (tests, FEAT-011 data checks). | US-9 | Must |
| FR-10 | While the app process lives, entered values shall be kept: through Back from crop, device rotation, font scale and language changes, and for the next photo in the same session [Assumption, OQ-1]. | US-8 | Must |
| FR-11 | The system shall show a non-blocking notice when the best-case upscale `max(W/sourceW, H/sourceH)` exceeds 1.0, using the oriented source size. FEAT-002 FR-11 stays the authority at crop time [Fact](docs/features/FEAT-002-crop-resize/prd.md). | US-7 | Should |
| FR-12 | The system shall show "Your photo: W × H px" (oriented size) and a "Use photo size" action that fills Width and Height, shown only when that size passes FR-5 [Assumption, OQ-7]. | US-7 | Should |
| FR-13 | The system shall show a non-blocking notice when Width or Height is below 16 px [Assumption, FEAT-002 OQ-6, OQ-12]. | US-7 | Should |
| FR-14 | The system shall write target values nowhere: not to disk, logs, crash reports, analytics or clipboard. | US-8 | Must |
| FR-15 | Every user-facing string shall be in `app_en.arb` with a description and placeholders, and in the 5 other languages through FEAT-019. Existing keys shall be reused for existing messages: `targetMaxOutOfRange`, `targetMinNotBelowMax`, `targetWholeNumbersOnly`, `targetInvalidNumber`, `targetChooseJpegOrPng`, `cropTargetSideOutOfRange`, `cropTargetTooLarge` [Fact](lib/l10n/app_en.arb). | US-5 | Must |
| FR-16 | The screen shall be designed with impeccable before it is built (Product Owner decision, 2026-11-20) [Fact](CLAUDE.md, Implementation). | US-6 | Must |

## 7. Non-functional requirements
| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | Validation of all fields is pure integer work, at most 5 ms [Assumption]; no dropped frames while typing. |
| NFR-2 | Accessibility | TalkBack labels with unit and required/optional; errors announced and focus moved (FR-8); touch targets at least 48 dp; layout reflows at 200% font with no clipping, truncation or horizontal scroll; Continue reachable with the keyboard open; Material 3 contrast. |
| NFR-3 | Offline / poor network | No network use at all; works in airplane mode. FEAT-016 verifies. |
| NFR-4 | Localisation | 6 languages (en, es-419, pt-BR, hi, id, ar), translations "AI-reviewed only" [Fact](CLAUDE.md, Localization). Digits shown are 0–9 in every language (ar decided 2026-11-21; hi, id, es, pt [Assumption]). Arabic: layout mirrored, field order follows reading order, digits and units in LTR isolates added in code. Numbers in messages formatted by the locale. |
| NFR-5 | Consistency | Limits and messages come from FEAT-002 and FEAT-004 code; a changed limit changes this screen without edits. |
| NFR-6 | Privacy | See section 10. Keyboard learning off; no values in logs. |
| NFR-7 | Testability | Cleaning, normalising and validation are pure Dart, unit-tested with the section 9 table; one emulator drive at en, ar and hi at 200% font for states empty, valid, error. |
| NFR-8 | Robustness | No crash on any input, including 1,000 random strings, paste of very long text, and configuration changes. |
| NFR-9 | Compatibility | Android 9 (API 28) and later [Fact](docs/product/vision.md, platforms). |

## 8. Validation rules
Existing messages are reused unchanged. One new string is proposed (marked NEW); hint texts are proposals.

| Field / input | Rule | Message |
|---|---|---|
| Width, Height | Whole number, 1–10,000 each; empty, 0 and negative fail | "Enter a width and height between 1 and 10,000 pixels." [Fact](docs/features/FEAT-002-crop-resize/prd.md, section 8) |
| Width, Height | Not whole (any separator) | NEW: "Use whole numbers of pixels." |
| W×H | At most 24,000,000 px | "That size is too large for this app. Choose a smaller size." |
| Maximum | Required; whole; 2–10,240 | "Enter a maximum size between 2 and 10,240 KB." [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, section 8) |
| Minimum | Optional; if set, whole, at least 1, below Maximum | "Minimum must be smaller than maximum." |
| Min, Max | Not whole (any separator) | "Use whole numbers of KB." |
| Min, Max | Not a number, 0 or negative (Maximum also when empty) | "Enter a valid size in KB." |
| Format | JPEG or PNG | "Choose JPEG or PNG." (defensive; the control always has a value) |
| Hint, non-blocking | Photo smaller than target (FR-11) | "Your photo is smaller than this size. It will be enlarged and may look soft." |
| Hint, non-blocking | Width or Height below 16 px (FR-13) | "Very small image. Check the size on your form." |

## 9. Edge cases & error states
| Case | Expected behaviour |
|---|---|
| All fields empty, Continue | Size message under the size row; "Enter a valid size in KB." at Maximum; focus on Width; nothing handed on |
| Width 0, 0 px, negative, or Maximum 0 | Range message for pixels; "Enter a valid size in KB." for Maximum |
| Width "300.5", Maximum "7.5", "7,5", "1,000", "1.000" | Whole-number message (pixels or KB) next to the field; never guessed. Rationale: a decimal comma (es, pt, id) and a grouping comma (en) look alike, and a wrong guess is a 1000× error |
| Width 10,001; Height 10,000 | Pixel range message |
| 6000×4000 (24.0 MP exactly) | Accepted |
| 6001×4000, or 10,000×2,401 | "That size is too large for this app. Choose a smaller size." |
| Maximum 1; Maximum 10,241 | "Enter a maximum size between 2 and 10,240 KB." |
| Maximum 2; Maximum 10,240 | Accepted (FEAT-004 may later report "can't reach this size") |
| Minimum only, Maximum empty | Maximum error; Minimum is not an error by itself |
| Minimum 0 | "Enter a valid size in KB."; the Minimum label says optional, so empty means none |
| Minimum above or equal to Maximum | "Minimum must be smaller than maximum." (OQ-6 for equal) |
| Minimum 49, Maximum 50 | Accepted; FEAT-004 shows the narrow-range notice |
| Decimal KB "7.5" | Whole-number message; decimals are FEAT-004 OQ-5 (not in R1) |
| Very small target (1×1 up to 15 px a side) | Accepted with the very-small notice; FEAT-002 allows 1 px |
| Target larger than the photo | Accepted; upscale notice (FR-11); FEAT-002 asks to confirm above 2.0 [Fact](docs/features/FEAT-002-crop-resize/prd.md, FR-11) |
| Target aspect very different from the photo (300×80 from a square photo) | Accepted, no notice in R1; the crop frame shows what is kept; FEAT-008 adds fit/pad later |
| Arabic-Indic "٣٠٠", Extended "۳۰۰", Devanagari "३००" | Read as 300; field shows 300 |
| Arabic decimal "٧٫٥", grouping "١٬٠٠٠" | Treated as separators: whole-number message |
| Hindi or Arabic text with letters ("३०० px", "KB") | Not a number: range message (pixels) or "Enter a valid size in KB." |
| Pasted "300x300", or a number with surrounding spaces or bidi marks | Surrounding spaces and bidi marks removed; "300x300" is not a number and gets the field's message |
| Leading zeros "0300" | Read as 300 |
| Digit string over 9 digits (paste) | Out-of-range message, no overflow. FEAT-004's validator alone would answer "Use whole numbers of KB." for 20 or more digits, because `int.tryParse` fails and `double.tryParse` succeeds (finding, OQ-8) |
| Photo larger than 24 MP or 10,000 px | "Use photo size" hidden; fields stay manual |
| Source with EXIF rotation | Photo line and upscale notice use the oriented size |
| Photo smaller than 1 MP or tiny (for example 50×50) | Same rules; upscale notice |
| Language or font scale changes while an error shows | Message re-renders in the new language; focus and text kept |
| App killed in the background on the target step (2 GB phones) | App restarts on the pick screen; the photo handle and values are gone in R1 [Assumption, OQ-1] |
| Back from crop and the size is changed | Crop restarts for the new ratio (FEAT-002) |
| Keyboard open on a small screen at 200% font | Screen scrolls; Continue and the focused field stay reachable |

## 10. Compliance & data privacy
- **Money / payments / PCI-DSS:** None touched. The step has no card number, token, wallet, merchant credential or amount field; it accepts only pixel and KB numbers and a format choice. PCI-DSS scope: not engaged by this feature [Assumption](docs/product/vision.md, compliance scope: payments go only through the stores).
- **Bangladesh Bank:** Payment-system rules are not engaged, because nothing here moves or records money [Hypothesis](docs/research/competitors.md, market notes). Ads and subscription belong to FEAT-025 and FEAT-026 and carry their own review. No sensitive value appears in this document; any future example of a credential or card value must use `[PLACEHOLDER]`.
- **Personal data collected:** None by this feature. Target values are not personal data on their own, but they can show which application a person is filling in [Assumption], so they are treated as private: memory only for the session (FR-10), never on disk, in logs, crash reports, analytics or the clipboard (FR-14). Local counters (FEAT-027) must not include target values.
- **Photo:** the step reads only the size and EXIF orientation from the handle, never pixels; nothing is copied; release on start-over is FEAT-001 FR-11. Signatures are identity-sensitive and students include minors [Fact](docs/product/vision.md, compliance scope); this step collects nothing from them.
- **Keyboard privacy risk (flag):** keyboards can learn typed text. Fields turn off personalised learning, suggestions and autocorrect (FR-3); Stage 6 verifies the Flutter options exist on the pinned version [Hypothesis].
- **Consent / retention:** No consent needed, as nothing is collected. Retention is until the app process ends. If OQ-1 is answered with persistence, it must be local only with a clear control and a store privacy label check, and it overlaps FEAT-012.
- **Bangladesh data-protection law:** not checked; nothing leaves the device, so no transfer or collection to assess [Hypothesis].

## 11. Dependencies
- **FEAT-001 (hard):** `PickedImage` with source size and EXIF orientation; start-over release.
- **FEAT-002 (hard):** consumes `Target`; owns `checkTarget`, the shared constants and the pixel messages; the orientation helper for the oriented source size [Fact](lib/features/crop/domain/target_check.dart).
- **FEAT-004 (hard):** owns `validateTarget`, `maxKbLimit`, `minMaxKb`, the KB messages and the KB rule (min×1024 to max×1000, safe under both conventions), so this screen only labels the unit "KB" and needs no explainer [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, FR-3).
- **FEAT-011 (shares the model):** fills the same fields; **FEAT-014** source note lives with presets; **FEAT-012** saves a `TargetSpec` and depends on this feature [Fact](docs/roadmap.md).
- **FEAT-019:** translations of all new strings. **FEAT-016:** no-network and privacy copy check. **FEAT-006:** shows the target in the meets-spec check. **FEAT-027:** must not carry target values.
- **Design gate:** impeccable pass before building (FR-16), jointly with FEAT-011's entry (OQ-10).
- **Stage 6 inputs:** how field-level errors are produced (OQ-8); state holder (Riverpod, ADR-001).

## 12. Open questions
No question blocks approval. OQ-1, OQ-3, OQ-7, OQ-10 should be answered before the design pass; the stated default applies if the Product Owner does not answer.
- [x] **OQ-1 (non-blocking, before design) Remember the last target?** A: nothing kept. B (default here): kept in memory for the session. C: saved on the device across launches. Trade-off: C saves repeat users and operators from retyping, but a stale prefilled target can be exported by mistake, adds storage, and overlaps FEAT-012 (saved presets, local only). Process death is lost under A and B. **Decided 2026-11-24 at gate G1 (Product Owner): B, session memory only (default).**
- [ ] **OQ-2 (non-blocking) Print size or mm/cm and DPI input?** Out of R1. Visa and passport forms often give mm at a DPI [Hypothesis]; it needs its own backlog row (no row added here). FEAT-010 only writes DPI metadata.
- [x] **OQ-3 (non-blocking, before design) Default format.** Proposed: JPEG preselected, since most photo and signature forms ask for it [Hypothesis; no research source]. Alternative: no preselection, forcing a choice and one more tap. **Decided 2026-11-24 at gate G1 (Product Owner): JPEG preselected (default).**
- [ ] **OQ-4 (non-blocking) Unit label.** Proposed: "KB", as forms write it [Fact](docs/research/competitors.md, Gap 1: "20kb–50 kb"). Not "kB" or "KiB". Forms that state MB must be typed in KB (for example 2 MB as 2000 is the safe value under the FEAT-004 rule); an MB entry is not in R1.
- [ ] **OQ-5 (non-blocking) Which numerals to display.** Western 0–9 in all 6 languages (ar decided; hi, id, es, pt assumed).
- [ ] **OQ-6 (non-blocking) Allow minimum = maximum?** Default: rejected, as FEAT-004 requires min < max. Allowing it needs a FEAT-004 change request.
- [x] **OQ-7 (non-blocking, before design) KB-only forms.** FEAT-002 needs a width and height, with no keep-original-size mode. Proposed: "Use photo size" button (Should). Alternative: the user types a size. **Decided 2026-11-24 at gate G1 (Product Owner): "Use photo size" shown (default).**
- [ ] **OQ-8 (non-blocking, Stage 6) Field-level errors.** `validateTarget` returns the first problem without saying which field; options: validate fields separately in FEAT-005, or a FEAT-004 change request adding the field. Also the 20-digit finding in section 9 (FR-4(d) avoids it).
- [ ] **OQ-9 (non-blocking) Effort.** The roadmap gives 0.5 pw. I think it is low: FEAT-002 and FEAT-004 were each 2 to 3 times over their first estimates [Fact](docs/roadmap.md, Stage 6 re-estimate). Rough breakdown in days [Assumption]: model, cleaning and validation 1.0; screen with errors, hints, RTL, 200% font 1.5; impeccable pass 0.5; flow wiring and session state 0.5; en strings and tests 1.5; slack 0.5. About 1.0 pw (range 0.8–1.3), existing validators already saved. Effect if accepted: R1 25.8 to 26.3 pw; RICE 40,000 to 20,000. Roadmap not edited; Product Owner decides.
- [x] **OQ-10 (non-blocking, before design) Screen shape with FEAT-011.** Preset list on this screen, or a preset screen before it. Decide in one design pass for both; FEAT-005 ships first and must work alone. **Decided 2026-11-24 at gate G1 (Product Owner): FEAT-005 screen works alone, with room for a FEAT-011 preset row (default).**
- [ ] **OQ-11 (non-blocking) Bengali digits (U+09E6–09EF)?** Cheap to accept; the market is global and the brief names no Bengali UI. Proposed: yes (Could).
- [ ] **OQ-12 (non-blocking) Small-target threshold.** 16 px is [Assumption]; also whether an extreme-aspect notice is wanted.
- [ ] **OQ-13 (non-blocking) Re-pick with a stale target.** In a dual flow (photo, then signature) a prefilled photo target could be reused for the signature. Mitigation under OQ-1 B: values are visible and editable; a "clear all" action is a possible addition.
- [ ] **OQ-14 (non-blocking) 30 s goal.** Confirm that the "under 30 s median" metric is measured on the preset path, not manual entry.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-23 | First draft |
| 1.0 | 2026-11-23 | Approved by Product Owner |
| 1.1 | 2026-11-24 | Gate G1 answers recorded for OQ-1, OQ-3, OQ-7 and OQ-10 (all defaults; clarification, scope unchanged). Implemented (Product Owner /approve) |
