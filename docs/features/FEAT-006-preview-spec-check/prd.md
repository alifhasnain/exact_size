---
id: FEAT-006
title: Preview with "meets spec" check
status: Proposed
version: 0.1
updated: 2026-11-25
links: [ROADMAP, BRIEF, RESEARCH, ADR-001, FEAT-002, FEAT-004, FEAT-005, FEAT-007, FEAT-010, FEAT-011, FEAT-015, FEAT-016, FEAT-018, FEAT-019, FEAT-025, FEAT-027]
---

# FEAT-006 — Preview with "meets spec" check

## 1. Overview
FEAT-006 takes over the success state of the result screen that FEAT-007 shipped. It shows the new image and a three-row check (pixel size, file size, format): the target next to what was **measured in the output file**, never the target echoed back. When every row meets the target it embeds FEAT-007's `ExportPanel` unchanged under the check. Running and failure states of that screen stay as they are. Release: MVP (R1 Phase A), Must in practice, roadmap effort 0.8 pw, RICE 20000, confidence 80% [Fact](docs/roadmap.md, FEAT-006 row). The scope below probably exceeds 0.8 pw (measurement, preview, two bad states, six languages, accessibility tests, FEAT-007 regression): [Assumption] 1.0–1.3 pw; Stage 6 re-estimates.

**Contract**
| Item | Contract |
|---|---|
| Input | `CompressionSuccess` (`tempFilePath`, `sizeBytes`, `format`, `notices`) [Fact](lib/features/compression/domain/compression_result.dart) and the **full** `TargetSpec` the run used: width, height, `minKb` (optional), `maxKb`, `format` [Fact](lib/features/target/domain/target_spec.dart). Today the result screen receives only `Target` (width and height) [Fact](lib/features/export/presentation/result_screen.dart; lib/app_flow.dart, `spec.dimensions`), so the full spec must reach it (section 11). |
| Ownership | The success file is owned by FEAT-006/FEAT-007 and deleted by `leave()` or discard [Fact](docs/features/FEAT-007-export-share/prd.md, section 1). FEAT-006 never edits its bytes. |
| Flow position | pick → target → crop → compress → **preview (FEAT-006)** → export (FEAT-007) [Fact](docs/features/FEAT-007-export-share/prd.md, section 1). |
| Today | A minimal result screen shows progress with Cancel, the FEAT-004 failure message with Back, or "Ready: W × H px, SIZE, FORMAT" plus the panel. The numbers are echoed from the result, no image is shown and no "meets spec" claim is made [Fact](docs/features/FEAT-007-export-share/prd.md, section 5 "Behaviour until FEAT-006 exists"; lib/features/export/presentation/result_screen.dart). |

**Scope boundaries**
| Owned by FEAT-006 | Owned elsewhere (not duplicated here) |
|---|---|
| Measuring the output file; the three-row check and verdict; the image preview; showing FEAT-004's notices before export; the "doesn't match" and "unreadable" states | Size search, KB window, failure reasons and messages, progress: **FEAT-004** (FEAT-006 reuses them and never rewords them) |
| Embedding the panel and calling `leave()` on exit | Save, Share, file name, leave confirm, cleanup: **FEAT-007** |
| Preview privacy (recents, no copies) | Target entry and its validation: **FEAT-005**. Enlargement warning at crop time: **FEAT-002** [Fact](docs/features/FEAT-002-crop-resize/prd.md, FR-11) |
| | DPI row: **FEAT-010** (does not exist). Richer "can't reach" guidance and the one-tap JPEG switch: **FEAT-015** (OQ-6). Privacy copy: **FEAT-016**. Translation: **FEAT-019** |

**Default behaviour without FEAT-010, FEAT-011, FEAT-015.** The check has exactly three rows. DPI is neither checked nor shown. No preset name is shown. Failure states are unchanged.

## 2. Problem statement
Users cannot tell whether the file will pass until the portal accepts or rejects it, and fixing that by trial and error is the pain the product exists to remove [Assumption](BRIEF, Problem). The brief's first-try goal (99%) needs proof the user can see before upload; the roadmap calls this feature "the only user-visible proof" [Fact](docs/roadmap.md, FEAT-006 row). FEAT-004 also handed this feature two duties: tell the user before export that transparency was flattened (FEAT-004 FR-12) and that padding was added (FR-8) [Fact](docs/features/FEAT-004-kb-range-compression/tasks.md, traceability rows FR-8, FR-12). The shipped result screen does not render `success.notices` [Fact](lib/features/export/presentation/result_screen.dart; `OutcomeMessages.notice` exists in lib/features/compression/presentation/outcome_messages.dart but no result-screen code calls it).

**Evidence gap.** `docs/research/competitors.md` has one relevant finding: a before/after preview exists in an iOS competitor [Fact](docs/research/competitors/compress-photos-resize-image-ios.md). It has no finding on whether any tool measures the output file and shows it against the requested spec, so that is a [Hypothesis] differentiator, not a benchmarked one. A1 is only partly supported: portals also impose content rules such as colour photo or recent date [Fact](docs/research/competitors.md, A1), which a size check cannot see, so the verdict must not promise acceptance (FR-7, FR-9). Content checks (face, background) are a competitor strength (PhotoAiD) and an open Product Owner question in the research [Fact](docs/research/competitors.md, Research gaps); they are out of scope here.

## 3. Goals & success metrics
| Goal | Metric | Target |
|---|---|---|
| Truthful measurement | Cases where a measured value on screen differs from an independent test measurement of the same file (byte length, header size, signature) | 0 over the R1 device matrix and a synthetic set of JPEG and PNG files |
| No false "matches" | Injected out-of-spec files shown as matching (size at window floor minus 1 byte and ceiling plus 1 byte, width or height off by 1, wrong format) | 0 |
| No false "doesn't match" | In-window files from the FEAT-004 test suite shown as failing | 0 |
| Same rule as FEAT-004 | Verdict differs from the FEAT-004 window function on a generated set (incl. narrow and max-only targets) | 0 |
| Fast | Success state to verdict and preview drawn, output up to 2 MP, 2 GB emulator profile | ≤ 500 ms median, ≤ 1.5 s p95 [Assumption]; feeds the under-30 s journey [Fact](docs/product/vision.md, success metrics) |
| No added taps | Taps between success and Save | 0 added |
| FEAT-007 intact | FEAT-007's own test suite and acceptance criteria | 100% pass, unchanged |
| Nothing kept | Decoded preview copies in memory caches after leaving | 0 |
| Private logs | Sizes, dimensions, paths or names in logs and crash reports | 0 |
| Readable | 200% font and 6 languages: clipped or truncated check text | 0 |

First-try success (99%) is measured in pre-release device tests, not production telemetry [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, OQ-11). FEAT-006 adds no counter in R1; its measurement is the oracle those tests use.

**Non-goals:** content checks (face, background, ID-photo rules); looking up a portal's rules; DPI (FEAT-010); editing, cropping or zoom from the preview; before/after comparison with the original; export-anyway for an out-of-spec file [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, OQ-7); showing JPEG quality, metadata or preset names; repeating FEAT-002's enlargement warning (OQ-7); a production counter or telemetry.

## 4. User stories
- **US-1** As an applicant, I want to see what the form asks next to what my file really is, so that I know it fits before I upload.
  - **AC-1.1** Given a successful result for a 300 × 300 px, 20–50 KB, JPEG target, when the screen opens, then I see three rows (Size in pixels, File size, Format), each with the target and the measured value of the file.
  - **AC-1.2** Given a test replaces the output file with a different valid file after compression, when the screen opens, then the rows show the replacement's values, not the target's or the result object's.
  - **AC-1.3** Given a target with no minimum (100 KB max), when I read the File size row, then the target reads "Up to 100 KB".
  - **AC-1.4** Given the check is running, when I look at the screen, then no "matches" text is visible before the measurement is done.
- **US-2** As an applicant, I want one clear verdict, so that I can go to Save or Share with confidence.
  - **AC-2.1** Given all three fields meet the target, when I read the screen, then the headline says "Matches your target", each row shows an icon and the word "Meets", and Save and Share are available below.
  - **AC-2.2** Given test files of exactly the window floor and ceiling in bytes, when checked, then both meet; given floor minus 1 and ceiling plus 1, then File size does not meet.
  - **AC-2.3** Given a 49–50 KB target (narrow, floor = min × 1000), when a file of 49,500 bytes is checked, then it meets and the narrow-range notice is shown.
  - **AC-2.4** Given a non-narrow target and a matching file, when I read the File size row, then "Also fits if your portal counts 1 KB as 1,024 bytes." is shown (Should); in the narrow case it is not.
  - **AC-2.5** Given a matching file, when I read the screen, then one line says only pixels, KB and format are checked and some forms also check the photo (Should); no text says the portal will accept the file.
- **US-3** As a user, I want a plain stop if the file does not match, so that I never export a file I was told fits.
  - **AC-3.1** Given a test injects a file with any one field off, when the screen opens, then the headline says the file doesn't match and can't be saved or shared, the failing row shows "Doesn't meet" with the target and measured values, Save and Share are not shown, and the file is deleted.
  - **AC-3.2** Given the file is 20 bytes above the ceiling, when I read File size, then the number shown is above the maximum (never reads as inside the range).
  - **AC-3.3** Given I tap Back, when the screen closes, then I am on the crop step with my photo and target values kept.
  - **AC-3.4** Given the file is missing, empty, unreadable, not decodable, or its length differs from `sizeBytes`, when the screen opens, then I see FEAT-007's "file is no longer available" message, no check and no panel, and leaving runs `leave()` to the pick screen.
  - **AC-3.5** Given any of the above, when I look for a way to export anyway, then there is none.
- **US-4** As a user, I want to see the image I will upload, so that I can spot a wrong crop or a damaged result.
  - **AC-4.1** Given a successful result, when the screen opens, then the whole image is shown from the output file, aspect ratio kept, not cropped or stretched, and a caption says it is scaled to fit the screen.
  - **AC-4.2** Given a test replaces the output file with an image of another colour, when the screen opens, then the preview shows that colour (the preview comes from the file).
  - **AC-4.3** Given a 24 MP output, when the screen opens, then the app does not crash, the rows show the file's real values, and the preview is drawn from a reduced decode.
  - **AC-4.4** Given the preview cannot be drawn for lack of memory, when the screen opens, then I see "Preview isn't available. The check below is still correct.", the rows and the panel stay, and a decode error other than memory follows AC-3.4.
  - **AC-4.5** Given a transparent PNG, when shown, then the image sits over a neutral checkerboard (Should).
  - **AC-4.6** Given TalkBack is on, when focus reaches the preview, then it reads "Preview of your new file, 300 × 300 px, JPEG." and nothing about what the picture shows.
  - **AC-4.7** Given I swipe or pinch on the preview, when I lift my finger, then the page scrolls or nothing happens and no zoom occurs (OQ-2).
- **US-5** As a user, I want to be told what changed in my file before I export it, so that a flattened background or added padding is no surprise.
  - **AC-5.1** Given `success.notices` holds a transparency, padding or narrow-range notice, when the screen opens, then each is shown once above Save and Share with FEAT-004's text, as icon plus text.
  - **AC-5.2** Given no notices, when the screen opens, then no notice area is shown.
- **US-6** As a user with an ID photo or signature, I want nothing left behind, so that my image is not exposed by this screen.
  - **AC-6.1** Given Android 13 or later, when the preview is shown and I open recent apps, then the app's thumbnail does not show the image; screenshots still work [Fact](docs/features/FEAT-002-crop-resize/prd.md, FR-26).
  - **AC-6.2** Given I leave the screen, when the next customer's photo reaches this screen, then nothing from the previous preview is drawn and no decoded copy remains in memory caches.
  - **AC-6.3** Given a full session, when release logs and crash reports are read, then they hold only the enum codes of section 5.
  - **AC-6.4** Given airplane mode, when I use the screen, then everything works and no network call is made.
- **US-7** As a FEAT-007 user, I want Save, Share and leaving to work as they did, so that nothing I rely on breaks.
  - **AC-7.1** Given all rows meet, when I use Save, Share, the messages and the privacy line, then they behave as FEAT-007's AC-1.1 to AC-9.2 and its suite passes unchanged.
  - **AC-7.2** Given nothing was saved or shared, when I tap Done, app-bar back or system back, then FEAT-007's "Leave without saving?" confirm appears; after Leave, `leave()` runs once, the file is deleted and the pick screen opens.
  - **AC-7.3** Given compression is running or failed, when I look at the screen, then it is FEAT-007's progress with Cancel or FEAT-004's failure message with Back, with no preview and no check.
  - **AC-7.4** Given rotation, a font-size change or a language change, when the screen redraws, then verdict, rows, preview and panel state are kept and compression does not run again.
- **US-8** As a TalkBack, large-font, Arabic or Hindi user, I want the check readable in my language, so that I understand the result.
  - **AC-8.1** Given 200% font in the longest language, when I open the screen, then nothing is clipped or truncated, there is no horizontal scroll and Save, Share and Done are reachable by scrolling.
  - **AC-8.2** Given TalkBack, when the verdict appears, then it is announced once; each row reads as one sentence "[LABEL]: target [TARGET], this file [MEASURED], [STATUS]."; status is never shown by colour alone.
  - **AC-8.3** Given any of the 6 languages, when I read the check, then every label is translated; in Arabic the layout is mirrored, numbers, "KB", "px" and format names are left-to-right and unbroken, with digits 0-9.

## 5. User flows
**Main flow**
1. FEAT-004 returns success; the result screen leaves its progress state.
2. The screen measures the file (FR-2) and decodes the preview off the UI thread. Until then it shows progress and no verdict (FR-1).
3. All fields meet (FR-4): the screen shows preview, headline, three rows, notices, the caveat line, the panel and Done, in that reading order (FR-7).
4. The user saves or shares through the panel; FEAT-007 behaves as specified there.
5. Done, back or system back: FEAT-007's leave sequence runs (FR-21).

**Can the "doesn't match" state occur?** Normally no. FEAT-004 returns success only after a check on the final bytes (FR-6), its input is already W × H (FR-1), and its format comes only from the target; a failure carries no file path, so no out-of-range file reaches this screen [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, FR-1, FR-6, FR-11; lib/features/compression/domain/compression_result.dart). It stays possible through a defect in the encoder or padding, a file altered or truncated after FEAT-004, or a wrong spec handed to the screen. The expected rate is 0. The state exists as defence in depth and so the on-screen check is an honest oracle for the 99% tests; it must stop the export, say so plainly and let the user retry.

**Alternate flows**
- **Does not match (FR-10):** verdict "doesn't match", rows with measured values, no panel, file deleted, Back to the crop step.
- **Unreadable (FR-11):** FEAT-007's `FILE_MISSING` message, no panel, leave through `leave()`.
- **Preview unavailable (FR-14):** placeholder; rows and panel stay.
- **Back from background (FR-12):** measured again once; the screen moves to one of the two states above if the file changed.

**Outcome codes (enum only, FR-19):** `SPEC_MEETS`, `SPEC_MISMATCH` (with field codes `DIMENSIONS`, `SIZE`, `FORMAT`), `SPEC_UNREADABLE`, `PREVIEW_UNAVAILABLE`.

## 6. Functional requirements
| ID | Requirement | Story | Priority (MoSCoW) |
|---|---|---|---|
| FR-1 | When the success state opens, the system shall measure the output file before showing any verdict. Until the measurement finishes it shall show progress and no "matches" text. | US-1 | Must |
| FR-2 | **Measured values.** File size = byte length of the file on disk. Pixel size = the stored width and height read from the file itself. Format = JPEG or PNG read from the file's own content, not its name or extension. No measured value shall come from the target, the form fields, the file name, or the result's `sizeBytes` and `format`. (`sizeBytes` serves only the consistency check in FR-11.) | US-1 | Must |
| FR-3 | **Target values.** The check shall compare against exactly the fields of the `TargetSpec` captured when the run started: width, height, minimum KB (optional), maximum KB, format. It shall use no other field. DPI is not checked or shown; FEAT-010 would add a row through a change to this PRD. | US-1 | Must |
| FR-4 | **Rules.** Pixel size meets only if width and height each equal the target exactly (no tolerance). File size meets only if it lies in the FEAT-004 byte window: `min×1024 ≤ bytes ≤ max×1000`, floor `min×1000` when that window would be empty (narrow range), floor 0 without a minimum. The window shall come from the one definition FEAT-004 uses, never a second copy [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, FR-3, FR-4, FR-19; lib/features/compression/domain/byte_window.dart). Format meets only if it equals the target format. The verdict is "matches" only if all three meet. | US-2 | Must |
| FR-5 | The system shall show three rows in fixed order (Size in pixels, File size, Format). Each row shows its label, the target, the measured value and a status as icon plus word ("Meets" or "Doesn't meet"). A target without a minimum reads "Up to [MAX] KB". | US-1, US-2 | Must |
| FR-6 | KB shall be shown as 1 KB = 1000 bytes with one decimal. A file inside the window rounds to the nearest tenth. A file outside it rounds away from the target, so a failing value never reads as inside the range [Fact](lib/features/compression/presentation/outcome_messages.dart, `achievedKb`; the rule is still marked [Assumption] in code, OQ-5). | US-3 | Must |
| FR-7 | The headline for a matching file shall say it matches the target the user entered and shall not say or imply that a portal will accept, approve or guarantee it. Preview, headline and rows shall come before Save and Share in reading and focus order. | US-2 | Must |
| FR-8 | When the window is not narrow, the File size row should add: "Also fits if your portal counts 1 KB as 1,024 bytes." It shall be hidden in the narrow case. | US-2 | Should |
| FR-9 | The screen should show one line that only pixels, KB and format are checked and that some forms also check the photo itself. | US-2 | Should |
| FR-10 | **Does not match.** If any field fails FR-4, the system shall show the verdict "doesn't match", the rows with measured values and the message in section 8, shall not show Save or Share, shall delete the file, shall offer Back to the crop step with photo and target kept, and shall log `SPEC_MISMATCH` with the failing field codes. It shall offer no export-anyway [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, OQ-7). | US-3 | Must |
| FR-11 | **Unreadable.** If the file is missing, empty, unreadable, cannot be decoded as its format, or its length differs from `sizeBytes`, the system shall show FEAT-007's `FILE_MISSING` message, no check and no panel, shall leave through `leave()` and shall log `SPEC_UNREADABLE`. | US-3 | Must |
| FR-12 | When the app returns to the foreground on the success state, the system should measure again once and move to FR-10 or FR-11 if the file changed. | US-3 | Should |
| FR-13 | **Preview source.** The preview shall be decoded from the output file, not from pre-compression pixels, with no filter, sharpening or overlay on the image. The whole image shall be visible, aspect ratio kept, never cropped or stretched. | US-4 | Must |
| FR-14 | **Size on screen.** The preview shall fit an area of at most [Assumption] 40% of the screen height in portrait, enlarged by at most [Assumption] 4 device pixels per image pixel, with a caption that it is scaled to fit. The decode shall be bounded to the display size so a 24 MP output does not crash, and no measured value shall be read from the preview bitmap. If the preview cannot be drawn for lack of memory, the system shall show a "Preview isn't available" placeholder, keep rows and panel, and log `PREVIEW_UNAVAILABLE`. | US-4 | Must |
| FR-15 | A transparent PNG should be shown over a neutral checkerboard (same as FEAT-002 AC-6.4). | US-4 | Should |
| FR-16 | The preview shall carry a text alternative with width, height and format only, for example "Preview of your new file, 300 × 300 px, JPEG." It shall never describe or identify what the picture shows, and no recognition or captioning shall run. | US-4, US-8 | Must |
| FR-17 | The preview shall take no zoom, pan or tap gesture in R1 and shall not block page scroll (OQ-2). | US-4 | Won't (R1) |
| FR-18 | **Notices.** The system shall show each item of `success.notices` once, before the export actions, as icon plus text, using FEAT-004's existing texts (narrow range, padding added, transparency flattened) [Fact](lib/features/compression/presentation/outcome_messages.dart, `notice`). FEAT-006 shall add no wording of its own for them. | US-5 | Must |
| FR-19 | **Privacy and logs.** The screen shall hide itself from the recent-apps thumbnail on Android 13 and later while the preview is shown, with the same mechanism as the crop screen and without blocking screenshots [Fact](docs/features/FEAT-002-crop-resize/prd.md, FR-26). The preview shall never be written to disk, cache, gallery or clipboard, and its decoded copy shall be released from memory and image caches when the screen closes or the result is discarded. Logging shall use only the enum codes in section 5 through the shared wrapper [Fact](lib/features/compression/data/outcome_log.dart). No size, dimension, path or name shall be logged, put in a crash report or passed to any ad, analytics or crash SDK, and the feature shall use no network API. | US-6 | Must |
| FR-20 | **Extend in place.** FEAT-006 shall replace only the success state of the result screen, including FEAT-007's interim "Ready:" line. The running state (progress, Cancel) and the failure state (FEAT-004 message, Back) stay as shipped. It shall not reword FEAT-004's failure messages or hints, nor repeat FEAT-002's enlargement notice. | US-7 | Must |
| FR-21 | **Panel and leave.** When the verdict is "matches" the screen shall embed `ExportPanel(success:, size:)` unchanged. Every exit from that state (Done, app-bar back, system back) shall follow FEAT-007: the FR-23 confirm when nothing was saved or shared, then `ExportController.leave()` once, then start over. FEAT-006 adds no confirm, button or prompt of its own to that sequence. The FR-10 state follows FR-10 instead. | US-7 | Must |
| FR-22 | Verdict, rows, preview and panel state shall survive rotation, font-size and language changes without running compression again. | US-7 | Must |
| FR-23 | All new strings shall be in `app_en.arb` with ICU placeholders and translated through FEAT-019 (`/l10n-translate`), status "AI-reviewed only". Numbers, units and format names are shown as isolated left-to-right text. | US-8 | Must |

## 7. Non-functional requirements
| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | Measurement and decode run off the UI thread. Verdict and preview drawn ≤ 500 ms median, ≤ 1.5 s p95 for outputs up to 2 MP on the 2 GB emulator profile [Assumption]. Extra memory for the preview ≤ [Assumption] 24 MB. |
| NFR-2 | Accessibility | Verdict announced once through a live region; each row is one sentence (AC-8.2); touch targets at least 48 dp; text scales with system font size and reflows at 200% with no clipping, truncation or horizontal scroll; text contrast at least 4.5:1 and icons at least 3:1 [Assumption: WCAG 2.x AA values chosen by this PRD]; status never by colour alone. |
| NFR-3 | Offline / poor network | Works in airplane mode; no network call (FR-19). FEAT-016 verifies. |
| NFR-4 | Localisation | English, es-419, pt-BR, hi, id, ar (RTL, Western digits 0-9) [Fact](CLAUDE.md, Localization). Translations "AI-reviewed only", never "native-quality". Messages short and plain. |
| NFR-5 | Truthfulness | The verdict equals the FEAT-004 window function and exact pixel and format comparison on 100% of a generated boundary set (floor and ceiling ±1 byte, width and height ±1, format swap, narrow, max-only). |
| NFR-6 | Testability | Measurement sits behind an interface so tests can supply any file, since FEAT-004 never produces the FR-10 and FR-11 states. |
| NFR-7 | Compatibility | Android 9 (API 28) to latest, tested on the API 28 and latest emulators [Fact](docs/roadmap.md, Phase A exit). Real-device behaviour is [Hypothesis] until tested. |
| NFR-8 | Privacy | See section 10; the screen is treated as showing identity data (FEAT-007 NFR-5). |

## 8. Validation rules
| Field / input | Rule | Message (English draft, all 6 languages) |
|---|---|---|
| Output file | Exists, non-empty, readable, decodes as its format, length equals `sizeBytes` (FR-11) | FEAT-007's text: "The new file is no longer available. Your gallery photos stay as they are. Choose the photo again to make a new one." (`FILE_MISSING`, reused, not copied) |
| Size in pixels | Width and height equal the target exactly (FR-4) | Row status "Doesn't meet" |
| File size | Inside the FEAT-004 byte window (FR-4) | Row status "Doesn't meet" |
| Format | Content signature equals the target format (FR-4) | Row status "Doesn't meet" |
| Verdict, all meet | FR-4 | "Matches your target" |
| Verdict, any fails | FR-10 | "This file doesn't match your target, so it can't be saved or shared. Go back and try again." |
| Labels and status | Fixed | "Size in pixels", "File size", "Format"; columns "Target", "This file"; "Meets", "Doesn't meet"; "Up to [MAX] KB" |
| Window not narrow (Should) | FR-8 | "Also fits if your portal counts 1 KB as 1,024 bytes." |
| Caveat (Should) | FR-9 | "We check pixels, KB and format. Some forms also check the photo itself, such as the face or background." |
| Preview | FR-14, FR-16 | Caption "Shown scaled to fit your screen." Alternative text "Preview of your new file, [W] × [H] px, [FORMAT]." Placeholder "Preview isn't available. The check below is still correct." |
| Notices | FR-18 | FEAT-004's `noticeNarrowRange`, `noticePaddingAdded`, `noticeTransparencyFlattened`, reused |
| Row for TalkBack | AC-8.2 | "[LABEL]: target [TARGET], this file [MEASURED], [STATUS]." |

## 9. Edge cases & error states
| Case | Expected behaviour |
|---|---|
| All three meet | Verdict, rows, preview, notices, panel (AC-2.1). |
| One field off (should not occur) | FR-10: no panel, file deleted, Back to crop, `SPEC_MISMATCH` (AC-3.1 to AC-3.3). |
| File gone, empty, truncated, undecodable, or length differs from `sizeBytes` | FR-11: `FILE_MISSING` message, `leave()` to the pick screen (AC-3.4). |
| Size exactly at the window floor or ceiling | Meets. One byte outside: does not (AC-2.2). |
| Narrow range (for example 49–50 KB) | Floor is min × 1000; the FEAT-004 notice is shown; the 1,024 line is hidden (AC-2.3). |
| Max-only target | Target reads "Up to N KB"; no floor (AC-1.3). |
| Failing size a few bytes outside | Shown number rounds away from the target, never looks in range (AC-3.2). |
| JPEG padded to reach the minimum | Padding notice shown; the picture is unchanged (FEAT-004 FR-8). |
| Transparent source, JPEG target | Flatten notice shown before export (FEAT-004 FR-12). Transparent PNG output shows a checkerboard (Should). |
| Very small output (for example 140 × 60) or very thin output | Fits the preview area, enlargement capped (FR-14); rows state the real size. |
| 24 MP output | Reduced decode, no crash; measured values from the file (AC-4.3). Out of memory: placeholder, check kept (AC-4.4). |
| Output has an orientation tag | Not expected: FEAT-004 encodes from pixels and writes only its own metadata [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, FR-2). Measured size is the stored width and height [Assumption: Stage 6 confirms by test]. |
| App backgrounded, cache cleared, app resumed | Measured again (FR-12, Should); without it FEAT-007 FR-2 still refuses an export of a missing file. |
| Rotation, font or language change | State kept, compression not re-run (AC-7.4). |
| User leaves while measuring | Measurement is dropped, `leave()` runs once, nothing is drawn afterwards. |
| Done tapped twice | `leave()` runs once; FEAT-007 FR-24 still waits for a running save. |
| Screenshot or screen recording | Not blocked, by decision [Fact](docs/features/FEAT-002-crop-resize/prd.md, OQ-8). The shot lands in the gallery, outside ExactSize's control (section 10). |
| Android 12 or older | Recents thumbnail may show the image; no protection there [Fact](docs/features/FEAT-002-crop-resize/prd.md, section 10). |
| Photo of a payment card or another sensitive item | ExactSize cannot know; shown and handled like any image, never read, logged or sent. |
| Upscaled source | FEAT-002 already warned at crop time; this screen repeats nothing (OQ-7). |
| DPI-checking portal | Not checked in R1; no row (FEAT-010). |
| PNG that cannot reach the KB range, or other FEAT-004 failures | No file, so no preview and no check: FEAT-004's failure state, unchanged. |

## 10. Compliance & data privacy
- **Money / payments involved? PCI-DSS scope?** N/A for this feature. FEAT-006 shows an image and three numbers; it handles no card number, token, merchant credential, wallet or money. A user could pick a photo that shows a payment card; the preview draws it on screen like any image and ExactSize does not read, detect, store, log or send it, so it does not process cardholder data on its own account [Assumption: legal reading to be confirmed with FEAT-007 OQ-10]. In-app purchases are Google Play Billing (FEAT-026), out of scope here.
- **Bangladesh Bank requirements that apply:** N/A for this feature, reason: no payment instrument, wallet, payment service or money movement and no financial data, so no Bangladesh Bank payment or PSP/PSO rule is engaged [Assumption](docs/product/vision.md, Compliance scope) [Hypothesis](docs/research/competitors.md, Market notes). Revisit if the product ever takes payments itself or sends images to a server.
- **Personal data, purpose, retention, consent:**
  - The preview puts a photo or signature on screen. These are personal data; signatures are identity-sensitive, faces can be biometric-adjacent and students include minors [Fact](docs/features/FEAT-007-export-share/prd.md, section 10). Purpose: let the user confirm the result by eye.
  - Processing is on-device only. FEAT-006 stores nothing: no thumbnail, history or recents, no copy on disk, no clipboard. The only copy is the decoded image in memory, released when the screen closes (FR-19). The file itself belongs to FEAT-004/FEAT-007 and is deleted by `leave()`.
  - Consent: none is collected, so none is needed. The privacy explainer and store labels stay with FEAT-016 and must not say "no data collected" unless the ad SDK is accounted for [Fact](docs/roadmap.md, FEAT-016 row).
  - **Privacy flags raised proactively.** (1) **ID photo on screen in public:** a cyber café or a queue lets others see the image; the preview is shown by default because the user must check it (OQ-3 proposes an optional hide control). (2) **Recents thumbnail:** hidden on Android 13+ only; Android 9–12 get none [Fact](docs/features/FEAT-002-crop-resize/prd.md, OQ-8). (3) **Screenshots and recordings** are not blocked, so an image can reach the gallery and its cloud backup; this is the user's action and the same decision as the crop screen. (4) **Operator devices:** the next customer must never see the previous preview (AC-6.2). (5) **Measured values are image-derived** (sizes, pixel counts), so they are kept out of logs, crash reports and every SDK (FR-19). (6) **Text alternative** states only technical values, so TalkBack or other assistive services never receive a description of the person (FR-16). (7) **Ads:** the ad SDK (FEAT-025) must receive no image, measured value or screen content from this feature; ad placement on this screen is decided there. (8) **Children's privacy:** FEAT-006 collects nothing from under-13 users.
  - **What is logged:** only the enum codes in section 5. Never a file name, path, size, dimension, MIME or platform exception text, in debug or release builds and crash reports.
  - **Play Data safety [Hypothesis, verify before release]:** FEAT-006 sends nothing off the device and adds no "data collected" entry.
  - **Markets:** launch is global [Fact](docs/product/vision.md). On-device processing with no transmission probably means low exposure under local data-protection law [Hypothesis]; no market-specific law was checked for this draft (OQ-9).
  - Examples and tests use synthetic images and `[PLACEHOLDER]` values such as `exactsize-300x300-[TOKEN].jpg`; never real people's photos, signatures or cards.

## 11. Dependencies
- **FEAT-004 (Implemented):** `CompressionSuccess`, notices and their texts, the byte window and the display rounding rule. The window must be reused, not copied (FR-4).
- **FEAT-005 (Implemented):** `TargetSpec`. The full spec, not only `spec.dimensions`, must reach the result screen, and the spec captured at run start is the one checked (FR-3). This is a change to the flow wiring, not to FEAT-005's rules.
- **FEAT-007 (Implemented):** embeds `ExportPanel(success:, size:)` unchanged and calls `ExportController.leave()` on every exit (FR-21); reuses the `FILE_MISSING` message and the enum-only log wrapper. FEAT-007's section 5 already says FEAT-006 takes over the screen and embeds the panel, so its PRD needs no change; its tests are the regression gate. The interim "Ready:" string and its translations become unused (Stage 6 removes or reuses them).
- **FEAT-002 (Implemented):** recents-hiding mechanism (FR-26 there); the enlargement notice stays at crop time.
- **FEAT-010 (Proposed):** a later DPI row. **FEAT-011:** a preset name may later head the check. **FEAT-015:** richer failure guidance and the JPEG switch (OQ-6). **FEAT-016:** privacy copy and no-network check. **FEAT-018:** metadata guarantee. **FEAT-019:** six-language strings. **FEAT-025:** receives nothing from this feature. **FEAT-027:** only enum codes, not in R1.
- **ADR-001:** Flutter stack; Stage 6 decides how the header, signature and bounded decode are read (no new dependency is assumed).
- **UI design:** this is a real screen, so the Product Owner is told before design and it is designed with impeccable [Fact](CLAUDE.md, Implementation; decision 2026-11-20).
- **Stage 6 checks:** each [Assumption] number in sections 3 and 7; decode time and memory on a 2 GB device for 24 MP; effort re-estimate.

## 12. Open questions
- [ ] **OQ-1 (non-blocking) Mismatch state.** Proposed default: block Save and Share, delete the file, Back to the crop step (FR-10). Alternative: warn and allow export anyway. Trade-off: the alternative lets a defect reach a portal; FEAT-004 OQ-7 already refused export-anyway for out-of-range files.
- [ ] **OQ-2 (non-blocking) Zoom.** Proposed default: none in R1 (FR-17). Alternative: tap opens a full-screen view with pinch-zoom to 1:1 (Could, about 0.2–0.3 pw [Assumption]). Trade-off: zoom helps judge a signature or face at real size; the crop screen already offers framing, and a preview-only gesture adds scope and a second place an ID image fills the screen.
- [ ] **OQ-3 (non-blocking) Hide control.** Proposed default: preview always shown, only the recents rule applies. Security-first alternative: an eye toggle that hides the image for public places (about 0.1 pw [Assumption], flagged in section 10, flag 1). The Product Owner decides.
- [ ] **OQ-4 (non-blocking) Wording.** Proposed default: "Matches your target" in plain words; the roadmap title keeps "meets spec". Reason: "spec" is jargon for non-native readers, and a claim of acceptance would overpromise (FR-7).
- [ ] **OQ-5 (non-blocking) KB display rule.** The 1000-byte KB, one decimal, round-away-from-target rule exists only in code and is marked [Assumption] there. Proposed default: confirm it and adopt it as FR-6.
- [ ] **OQ-6 (non-blocking) JPEG switch.** FEAT-004 FR-10 allows a one-tap switch to JPEG on `PNG_ABOVE_MAX`, and its task list assigns that UI to "FEAT-006 / FEAT-015" [Fact](docs/features/FEAT-004-kb-range-compression/tasks.md, FR-10 row). Proposed default: not in FEAT-006; leave it to FEAT-015, since it changes the user's target and re-runs compression, and the roadmap row does not name it.
- [ ] **OQ-7 (non-blocking) Enlargement reminder.** Proposed default: none; FEAT-002 warned at crop time and the preview shows softness directly. Alternative: a quiet line when `upscaleFactor` is above 1.0.
- [ ] **OQ-8 (non-blocking) Numbers.** Preview area (40% of height), enlargement cap (4×) and time and memory targets are [Assumption]. Proposed default: tune in the design pass and the Stage 6 spike.
- [ ] **OQ-9 (non-blocking, before release) Compliance review.** Same review as FEAT-007 OQ-10 (Data safety reading, "opaque image" reading for PCI, local data-protection law). Proposed default: treat as open until reviewed.
- [ ] **OQ-10 (non-blocking) Cut order if effort grows.** FR-8, FR-9, FR-12, FR-15. Proposed default: keep all four as Should until the Stage 6 estimate.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-25 | First draft |
