---
id: FEAT-004
title: Compress to a min–max KB range with JPEG/PNG choice
status: Approved
version: 1.0
updated: 2026-11-19
links: [ROADMAP, FEAT-002, FEAT-005, FEAT-006, FEAT-011, FEAT-015, FEAT-016, FEAT-018, FEAT-010]
---

# FEAT-004 — Compress to a min–max KB range with JPEG/PNG choice

## 1. Overview
FEAT-004 takes an image that is already at the target width×height and produces a file whose size in KB falls inside the requested minimum–maximum range, in the requested format (JPEG or PNG). It runs fully on-device and offline on Android (Flutter). It is the engine behind the main differentiator: a min–max KB range as a first-class input, instead of max-only tools [Fact](docs/research/competitors.md, Gap 1, A4).

**Release:** MVP (R1 Phase A, 2.0 person-weeks, Must; RICE 12000, confidence 80% because on-device KB search is unproven until Stage 6) [ROADMAP].

**Scope boundaries**
| Owned by FEAT-004 | Owned elsewhere (not duplicated here) |
|---|---|
| File size (bytes) and output format of the final file; the size search; the minimum-KB floor; the basic honest "can't reach this size" outcome | Crop and pixel dimensions: **FEAT-002** (FEAT-004 receives pixels already at W×H and never resizes or crops) |
| The KB definition rule (section 6, FR-3) | Target values (min KB, max KB, format): **FEAT-005** (manual entry) and **FEAT-011** (presets) |
| | Preview and "meets spec" display: **FEAT-006** |
| | Richer guidance when a target can't be met (suggestions, polished guard, quality-floor tuning UX): **FEAT-015** |
| | EXIF/GPS stripping: **FEAT-018**. DPI metadata: **FEAT-010**. Interaction: metadata bytes count toward file size (FR-14) |
| | Saving and sharing the file: FEAT-007. On-device/offline guarantee and privacy explainer: **FEAT-016** |

## 2. Problem statement
Application portals reject uploads outside a strict size window. Official forms set both a floor and a ceiling, for example a photo of 20–50 KB and a signature of 10–20 KB [Fact](https://mstcindia.co.in/MSTC_Careers/ImageDocUploadingSteps.aspx). Reviewed tools mostly offer max-only KB; a visible "cannot reach limit" message is a pattern worth copying [Fact](docs/research/competitors.md, Gap 1 and UX patterns). Whether those tools miss the target is untested (A2 accuracy, Low confidence; A4 weakness unproven), so ExactSize must prove accuracy itself. Applicants today fix this by trial and error [Assumption](BRIEF Problem). The brief's success metric requires at least 99% first-try success; this feature is the part that decides whether the file size is right.

## 3. Goals & success metrics
| Goal | Metric | Target |
|---|---|---|
| Delivered files are always in range | Share of exported files with size inside the requested range (under the FR-3 rule) | **100%** (zero tolerance: a file outside the range is never exported) |
| First-try success on feasible targets | Share of test exports, on feasible targets, ending in "success" on the R1 device matrix (5+ Android devices, low-end included) | **≥ 99%** [Assumption: BRIEF target; corpus of ≥ 500 exports across photo and signature images, feasibility judged by an offline reference search] |
| Honest failure | Share of infeasible targets that end in the "can't reach" outcome instead of an export | 100% |
| Speed | Median and p95 time of the size search on a low-end device (NFR-1) | ≤ 3 s / ≤ 8 s [Assumption] |
| Consistency | Same input, target and app version on the same device → same bytes (Must); across devices → same bytes (Should, depends on the Stage 6 encoder choice) | 100% of the test set |

Note: because failures are never exported, "99% inside range" is only meaningful against feasible targets; the 100% row guards the exported files.

**Non-goals**
- Cropping, resizing, fill/fit, or any pixel-dimension change (FEAT-002, FEAT-008). FEAT-004 never changes W×H to save bytes.
- Showing the preview or the "meets spec" badge (FEAT-006).
- Rich failure guidance, alternative-target suggestions, polished over-compression guard (FEAT-015). FEAT-004 supplies the basic message and a machine-readable reason.
- EXIF/GPS stripping (FEAT-018) and DPI writing (FEAT-010); FEAT-004 only measures their bytes.
- Output formats other than JPEG and PNG (no WebP/HEIC output); PDF output (FEAT-024 rejected).
- Padding by any method other than standard JPEG comment segments (no trailing bytes, noise or pixel changes); no padding for PNG in R1.
- Batch processing (FEAT-022, Later), signature cleanup (FEAT-020).
- Uploading, cloud processing, accounts.

## 4. User stories
- **US-1** As a job applicant, I want the app to compress my photo into the KB range my form demands, so that the portal accepts it on the first upload.
  - **AC-1.1** Given an image at 300×300 px, target 20–50 KB, format JPEG, when I tap Export (or the pipeline runs), then the output is JPEG and its size is ≥ 20×1024 bytes and ≤ 50×1000 bytes.
  - **AC-1.2** Given the same image at a higher-quality starting point, when compression runs, then the result uses the highest JPEG quality that still fits the ceiling (best visual quality inside the range).
  - **AC-1.3** Given a range where the two KB interpretations cannot both be met (for example 49–50 KB, where 49×1024 = 50,176 > 50×1000 = 50,000), when compression runs, then the app uses the fallback rule in FR-4 and shows the "range very narrow" notice.

- **US-2** As a visa applicant whose form has a minimum size, I want a simple image raised to the floor without being damaged, so that the portal does not reject it as too small.
  - **AC-2.1** Given an image that encodes to 8 KB at default quality and a target of 20–50 KB, when compression runs, then quality is raised (up to 100, then the size-raising encoder settings in FR-8) until the file is ≥ 20×1024 bytes; padding is used only if those steps are not enough.
  - **AC-2.2** Given a JPEG target and an image that stays below the minimum even at maximum quality and settings (for example a clean 140×60 signature with a 10–20 KB target), when compression runs, then neutral padding is added in JPEG comment segments until the file is inside the window, the file still opens as a valid JPEG with unchanged pixels, no bytes follow the end-of-image marker, and the user sees a "padding added to reach the minimum size" note.
  - **AC-2.3** Given padding is used, when the file is inspected, then the comment content contains no user data, file names, device data or timestamps, and running the same input twice gives byte-identical output.

- **US-3** As a student, I want to choose PNG when a form asks for PNG, so that I get the right format with an honest result.
  - **AC-3.1** Given a PNG target and an image whose lossless PNG size is inside the range, when compression runs, then a PNG in range is returned and pixels are unchanged from the input.
  - **AC-3.2** Given a PNG target where the best lossless PNG is above the maximum, when compression runs, then the result is "can't reach this size" with reason `PNG_ABOVE_MAX`, no PNG is exported, and the message offers a one-tap switch to JPEG only if a JPEG probe shows JPEG would fit.
  - **AC-3.3** Given a PNG target and an image whose PNG is below the minimum, when compression runs, then the result is `PNG_BELOW_MIN`, no file is exported, and no filler is added.
  - **AC-3.4** Given a JPEG target and an input with transparency, when compression runs, then transparent areas are flattened onto white and the user is told before export that the output has no transparency.

- **US-4** As any user, I want to be told plainly when the size can't be reached, so that I never upload a file the portal will reject.
  - **AC-4.1** Given a target that is impossible (for example 300×300 px, max 3 KB), when compression runs, then no file is handed to export, the message states the closest achievable size in KB and whether it is too big or too small, and the reason code is returned to FEAT-006/FEAT-015.
  - **AC-4.2** Given the JPEG quality needed to fit the ceiling is below the quality floor (FR-7), when compression runs, then the result is `TOO_DEGRADED`, no file is exported, and the case is handed to FEAT-015.
  - **AC-4.3** Given any failure outcome, when I look at the screen, then no "success" or "meets spec" state is shown and the Export action for the out-of-range candidate is not available.

- **US-5** As a user with a modern phone, I want to start from any common photo format, so that I do not convert files first.
  - **AC-5.1** Given a source in JPEG, PNG, HEIC/HEIF or WebP, when the image reaches FEAT-004 as pixels at target W×H, then the target-format output is produced with the same behaviour for all four sources.
  - **AC-5.2** Given a source format the device cannot decode (for example HEIC on an unsupported Android version), when it is selected, then the user gets a clear "this file type isn't supported on this device" message and no crash.
  - **AC-5.3** Given a very large camera image (for example 50 MP), when it is processed, then the app does not crash from memory pressure: it either completes or shows a clear "image too large" error.

- **US-6** As a user, I want the same result every time and no data leaving my phone, so that I can trust the app with my signature.
  - **AC-6.1** Given the same source pixels, target and app version, when I run compression twice on the same device, then the two output files are byte-identical.
  - **AC-6.4** (Should) Given the same inputs on two different devices of the R1 matrix, when compression runs, then the outputs are byte-identical, or at minimum both land inside the window.
  - **AC-6.2** Given airplane mode, when I run compression, then it completes with no network access and no error.
  - **AC-6.3** Given compression finishes, is cancelled, or fails, when I inspect the app's temporary storage, then no intermediate image files remain.

- **US-7** As a Spanish, Portuguese, Hindi, Indonesian or Arabic speaker, or a screen-reader user, I want results and errors in my language and announced accessibly, so that I understand the outcome.
  - **AC-7.1** Given the device language is any of the 6 supported languages, when a success or failure message appears, then it is shown in that language with correct number and unit placement.
  - **AC-7.2** Given Arabic (RTL), when the message shows sizes such as "50 KB", then the layout mirrors and numbers and units stay readable (bidi-isolated).
  - **AC-7.3** Given TalkBack is on, when compression starts, ends or fails, then progress and the outcome are announced without needing to see the screen.

- **US-8** As a user entering a custom target, I want invalid ranges rejected clearly, so that I do not waste time on a target that cannot work.
  - **AC-8.1** Given min ≥ max, a negative or non-numeric value, or a value above the upper limit, when the target reaches FEAT-004, then it is rejected with a specific message and no compression runs.
  - **AC-8.2** Given a target with no minimum (max-only form), when compression runs, then only the ceiling applies.

## 5. User flows
**Main flow (JPEG)**
1. FEAT-002 passes pixels at target W×H. FEAT-005/FEAT-011 supply min KB, max KB and format.
2. FEAT-004 validates the target (section 8) and computes the byte window: floor = min×1024, ceiling = max×1000 (FR-3).
3. It runs the deterministic quality search (FR-5) with the final-file serialisation, including metadata from FEAT-010/FEAT-018 (FR-14).
4. It checks the final bytes against the window. In range: it returns `success` with the temp file, size in bytes, quality used, and format.
5. FEAT-006 shows the preview and "meets spec"; FEAT-007 exports.

**Alternate flows**
- **Floor not met at quality ≤ 100:** apply the size-raising settings (FR-8); if still below, return `BELOW_MIN`.
- **Narrow range** (floor > ceiling under FR-3): fallback rule FR-4, success with the notice, or failure if even the fallback is impossible.
- **PNG:** best lossless compression; success only if in range, otherwise `PNG_ABOVE_MAX` or `PNG_BELOW_MIN`.
- **Cancel / app backgrounded:** the search stops, temp files are deleted.

**Error flows:** `ABOVE_MAX` (too large even at JPEG quality 1), `TOO_DEGRADED` (fits only at a quality below the FR-7 floor), `NO_FIT` (no quality lands inside a narrow window because size jumps over it), `BELOW_MIN`, `PNG_ABOVE_MAX`, `PNG_BELOW_MIN`, `INVALID_TARGET`, `UNSUPPORTED_INPUT`, `IMAGE_TOO_LARGE`, `OUT_OF_MEMORY_HANDLED`, `CANCELLED`. In all of them no out-of-range file is exported.

## 6. Functional requirements
| ID | Requirement | Story | Priority (MoSCoW) |
|---|---|---|---|
| FR-1 | The system shall accept as input decoded pixels already at the target W×H, plus a target of {min KB, max KB, format ∈ {JPEG, PNG}}. It shall not resize, crop or change aspect ratio. | US-1 | Must |
| FR-2 | The system shall produce the output by encoding from pixels (no pass-through of the original file bytes), so that the output contains only metadata that this app writes. | US-1, US-6 | Must |
| FR-3 | **KB rule (safe for both portal conventions).** The system shall treat the accepted window as `min×1024 ≤ size_bytes ≤ max×1000`, so that the file passes whether the portal counts 1 KB as 1000 or 1024 bytes. Size is the byte length of the final file. If min is unset, the floor is 0. | US-1 | Must |
| FR-4 | **Narrow-range fallback.** When `min×1024 > max×1000` (ratio max/min below 1.024, for example 49–50 KB), the system shall target the ceiling `max×1000`, aim for the highest size at or below it, and require at least `min×1000`; it shall return success with a "range very narrow, portals that count KB differently may differ" notice. (min < max is guaranteed by validation, so `min×1000 < max×1000` always holds.) Decided by the Product Owner, 2026-11-19 (OQ-1). | US-1 | Must |
| FR-5 | **JPEG search.** The system shall search integer quality 1–100 with a deterministic search (binary search, then verify the chosen quality and its neighbours, since size is not guaranteed monotonic), and select the highest quality whose final size is ≤ the ceiling and ≥ the floor. | US-1 | Must |
| FR-6 | The system shall never return success, and never hand a file to export, unless the final file's size is inside the window (or FR-4 applies). This check shall run on the final file bytes, not on an estimate. | US-1, US-4 | Must |
| FR-7 | **Quality floor.** The system shall define a minimum acceptable JPEG quality (proposed default 40 [Assumption], tuned on a visual test set in Stage 6). If fitting the ceiling needs quality below it, the system shall return `TOO_DEGRADED` and not export. Handing the case to richer guidance is FEAT-015. | US-4 | Must |
| FR-8 | **Minimum-KB floor.** If the file is below the floor at the best quality found, the system shall raise size in this order, stopping at the first success: (1) higher JPEG quality up to 100; (2) 4:4:4 chroma subsampling; (3) disable optimised Huffman tables and progressive mode; (4) **only if still below the floor**, add padding inside standard JPEG comment (COM) segments, with neutral fixed content (no user data, no timestamps, deterministic), split across segments as needed (≤ 65,533 bytes each), up to the floor plus a small margin and never above the ceiling. The user is told that padding was added. The system shall never append bytes after the end-of-image marker, add noise, or alter pixels to gain size. If padding is not possible (PNG, or a write failure), return `BELOW_MIN`. Decided by the Product Owner, 2026-11-19 (OQ-2). | US-2 | Must |
| FR-9 | **PNG.** The system shall encode PNG losslessly at the highest compression setting, and return success only if the size is in the window. It shall not apply lossy colour reduction in R1 (see OQ-3). | US-3 | Must |
| FR-10 | When a PNG cannot fit, the system shall return `PNG_ABOVE_MAX` or `PNG_BELOW_MIN`. For `PNG_ABOVE_MAX` it shall run one JPEG probe and flag whether JPEG would fit; the basic message may offer a one-tap switch to JPEG only when the flag is true. The switch is a user action; the system shall never change the format on its own. | US-3 | Must |
| FR-11 | **Failure outcome.** On any failure the system shall return a result object with: status, reason code (section 5), closest achievable size in bytes, direction (too big / too small), and no exportable file. It shall produce a plain-language message (NFR-4) stating the target and the closest size. | US-4 | Must |
| FR-12 | The system shall flatten transparency onto white for JPEG output and shall tell the user before export that transparency is lost. | US-3 | Must |
| FR-13 | The system shall accept sources JPEG, PNG, HEIC/HEIF and WebP wherever the device can decode them, and show a clear unsupported-file message otherwise. Output format is chosen only by the target. | US-5 | Must |
| FR-14 | **Metadata interaction.** The size search and final check shall measure the full final file including every metadata byte written by FEAT-018 (stripped) and FEAT-010 (DPI) and any ICC profile or container header. When these steps run before or inside the search, the final size shall still pass FR-6; FEAT-004 owns the final size gate, FEAT-018 and FEAT-010 own the metadata content. FEAT-018 stripping must not remove FEAT-004's padding comment segments, or the size gate re-runs. | US-1 | Must |
| FR-15 | The system shall be deterministic on a device: identical pixels, target and app version shall give byte-identical output. | US-6 | Must |
| FR-21 | The system should give byte-identical output across supported devices. Whether this needs a bundled, pinned encoder is a Stage 6 (ADR) decision. | US-6 | Should |
| FR-16 | The system shall validate the target (section 8) before any encoding and return `INVALID_TARGET` with a specific message. | US-8 | Must |
| FR-17 | The system shall run off the UI thread, report progress, and be cancellable; cancel shall delete temp files. | US-6 | Should |
| FR-18 | The system shall handle out-of-memory and oversized images without crashing, returning `IMAGE_TOO_LARGE` or `OUT_OF_MEMORY_HANDLED`. | US-5 | Must |
| FR-19 | The system shall expose the achieved size, quality used and outcome to FEAT-006 so the preview shows real numbers (it shall not recompute them differently). | US-1 | Must |
| FR-20 | The system shall delete all intermediate and candidate files on success, cancel, failure and at next app start (orphan sweep). | US-6 | Must |

## 7. Non-functional requirements
| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | On a low-end Android device (about 2 GB RAM, entry-level CPU [Assumption]) the search for a target of ≤ 2 megapixels completes in ≤ 3 s median and ≤ 8 s p95 [Assumption]. Search is bounded to ≤ 10 encode passes [Assumption]. |
| NFR-2 | Memory | Peak memory attributable to FEAT-004 ≤ 150 MB for a 2-megapixel target [Assumption]; no crash on larger inputs (FR-18). |
| NFR-3 | Determinism | Same-device byte-identical output (FR-15, Must). Cross-device identity (FR-21, Should) may need a bundled, pinned encoder instead of the OS encoder; Stage 6 decides and records it in an ADR. |
| NFR-4 | Localisation | All FEAT-004 messages exist in English, Spanish, Portuguese (Brazil), Hindi, Indonesian and Arabic. Numbers and units use placeholders so word order can change; Arabic is RTL with bidi-isolated numbers and "KB". No message is built by string concatenation. Native-speaker review is part of the R1 Phase B exit criteria. |
| NFR-5 | Accessibility | Progress, success and every failure are announced by TalkBack (live region); outcomes are never conveyed by colour alone; text scales with the system font size; touch targets ≥ 48 dp; messages state what happened and one next action. |
| NFR-6 | Offline / poor network | Fully offline. The image pipeline makes no network calls (verified, per the Phase A exit criteria). No dependency on a server or downloadable codec. |
| NFR-7 | Privacy | No logging of image content, file names, paths or pixel data; release builds log only enumerated outcome codes with no user data (section 10). |
| NFR-8 | Reliability | The 99% first-try target is measured on the R1 device matrix; the 100% in-range rule for exported files has no tolerance. |
| NFR-9 | Testability | The core search is a pure function over (pixels, target, settings), unit-testable with synthetic images and a golden-file determinism test. |

## 8. Validation rules
| Field / input | Rule | Error message (English; all 6 languages required) |
|---|---|---|
| Max KB | Required; number; ≥ 2 and ≤ 10,240 (10 MB) [Assumption] | "Enter a maximum size between 2 and 10,240 KB." |
| Min KB | Optional; if set, number ≥ 1 and < max | "Minimum must be smaller than maximum." |
| Min/Max precision | Whole numbers in R1 (decimals are an open question, OQ-5) | "Use whole numbers of KB." |
| Min, max | Not negative, not zero for max, not NaN/blank | "Enter a valid size in KB." |
| Format | Must be JPEG or PNG | "Choose JPEG or PNG." |
| Pixels | Must already equal target W×H from FEAT-002; mismatch is a programming error | "Something went wrong preparing your image. Please try again." |
| Narrow range | max/min < 1.024 is allowed but triggers the FR-4 notice | "This range is very narrow. Some portals count KB differently, so the file may still be rejected." |
| Impossible by size | Not a validation error; handled by the outcome (FR-11) | "We can't reach [MIN]–[MAX] KB for this image at this size. Closest: [ACHIEVED] KB." |

## 9. Edge cases & error states
| Case | Expected behaviour |
|---|---|
| Image compresses below min even at quality 100 | FR-8 levers 1–3, then JPEG comment padding (lever 4) with a user note; `BELOW_MIN` only if padding is impossible |
| Ceiling needs quality below the floor | `TOO_DEGRADED`; no export; hand to FEAT-015 |
| Range where KB interpretations conflict (for example 49–50) | FR-4 fallback with notice |
| Very narrow range with no JPEG quality inside (size jumps over it) | Neighbour verification (FR-5); if none lands in the window, `NO_FIT`, reported as failure with the closest size |
| Non-monotonic size vs quality | Verified by neighbour search; the final check is on actual bytes |
| min unset (max-only form) | Floor = 0; best quality under the ceiling |
| Tiny max (for example 2 KB) at normal dimensions | `ABOVE_MAX` if even quality 1 is too large, otherwise `TOO_DEGRADED`; clear message |
| PNG with lots of photographic detail | `PNG_ABOVE_MAX`; JPEG probe decides whether to suggest a switch |
| PNG that is a flat signature and tiny | May be below min: `PNG_BELOW_MIN`; no padding for PNG in R1; the message suggests JPEG if the form allows it |
| Transparent source, JPEG target | Flatten onto white with notice (FR-12) |
| Animated WebP/GIF-like source | First frame used; user told |
| 16-bit, CMYK, wide-gamut or unusual colour source | Converted to 8-bit sRGB before encoding; the ICC profile policy is OQ-6 |
| HEIC not decodable on the device | `UNSUPPORTED_INPUT` message |
| 50 MP camera image | Handled upstream by downsampled decode (FEAT-002); FEAT-004 only sees target-size pixels; the large target W×H is bounded by OQ-4 |
| Target W×H very large (for example 6000×6000) | Allowed up to a bound [Assumption: 24 MP]; beyond it `IMAGE_TOO_LARGE` |
| Low storage / write failure | Failure message; temp files cleaned; no partial file exported |
| App killed during search | Orphan temp files removed at next start |
| User cancels or rotates device during the search | Search continues or cancels cleanly with no duplicate runs and no leaked files |
| Metadata step adds bytes after the search | Final check includes them (FR-14); if the result is now outside the window, the search is re-run with the actual overhead |
| Same input run twice | Byte-identical output on the same device (FR-15); across devices per FR-21 |
| Low-end device slow | Progress shown; cancel available; no ANR |

## 10. Compliance & data privacy
- **Money / payments involved? PCI-DSS scope?** No. FEAT-004 handles image bytes and numbers only. No card data, tokens or merchant credentials exist in this feature, so no PCI-DSS scope. In-app purchases (FEAT-026) are handled by Google Play Billing and are outside this feature.
- **Bangladesh Bank requirements that apply:** None for this feature. It involves no payment instruments, wallets, or money movement, and no financial data. (Consistent with the BRIEF compliance scope [Assumption] and RESEARCH market notes [Hypothesis].) If the product later adds paid features that handle payments directly, revisit.
- **Personal data collected, purpose, retention, consent:**
  - Photos and signatures are personal data; signatures are identity-sensitive. Faces in photos can also be biometric-adjacent. Students include minors (children's-privacy flag, with ad SDK exposure covered by FEAT-025).
  - Processing is **on-device only**; no image, byte count tied to a person, file name or path leaves the device. No network calls in the pipeline (verifiable, see FEAT-016).
  - **No logging** of pixel data, image content, file names, file paths, or EXIF values, including crash reports and debug logs in release builds. Only enumerated outcome codes (for example `BELOW_MIN`) may be logged or counted locally (FEAT-027 is local-only or opt-in).
  - **Temp files** are written only to app-private cache storage (not shared storage, not the gallery), deleted on success, cancel and failure, and swept at app start. Nothing is written to public storage until the user exports (FEAT-007).
  - **Retention:** none by FEAT-004. No recents or history here (FEAT-023 is Later and carries its own privacy flag).
  - **Consent:** no collection, so no consent is needed for this feature. The privacy explainer and store labels (FEAT-016) must stay consistent with the ad SDK's real data collection; FEAT-004 itself does not feed the ad SDK any image data.
  - **Privacy risk to flag:** source images (especially camera and HEIC files) may contain GPS and device metadata. FEAT-004 re-encodes from pixels (FR-2) so original metadata is not carried over, but formal stripping and its guarantee belong to FEAT-018.
  - **Padding content:** JPEG comment padding (FR-8 lever 4) holds only neutral fixed bytes. It must never carry user data, device identifiers, file names or timestamps, so it can't leak information or fingerprint the user.
  - **Test data:** tests and docs use synthetic images and `[PLACEHOLDER]` values, never real people's photos or signatures.

## 11. Dependencies
- **FEAT-002** supplies pixels at target W×H (hard dependency).
- **FEAT-005 / FEAT-011** supply the target; **FEAT-006** consumes the result; **FEAT-015** consumes failure reasons; **FEAT-010 / FEAT-018** add metadata bytes (FR-14); **FEAT-016** verifies no network and the privacy copy; **FEAT-007** exports; **FEAT-019** supplies the 6-language message translations.
- **Stage 6:** on-device KB search validated (roadmap dependency); a hands-on test of whether clean signatures (for example 140×60 px, 10–20 KB) fall below the floor without padding [Hypothesis]; re-estimate effort, since this scope probably exceeds the roadmap's 2.0 pw; encoder library choice and pinning (ADR); minSdk and HEIC decode support; plugin versus native-code split.
- **Content / legal:** native-speaker review of the failure messages (Phase B exit).

## 12. Open questions
- [x] **OQ-1 — decided 2026-11-19: accept FR-3 and FR-4 as written.** (Was blocking.) Is `min×1024 ≤ size ≤ max×1000` (valid under both conventions) the right default? For ranges where it is impossible (max/min < 1.024, such as 49–50 KB), FR-4 proposes aiming at the ceiling `max×1000` with a warning. Alternative: fail with "range too narrow". Trade-off: fallback helps more users, but the file may be rejected by a portal using 1024.
- [x] **OQ-2 — decided 2026-11-19: allow padding only via JPEG comment segments, only when quality levers fail, always disclosed to the user (FR-8 lever 4). PNG: no padding in R1.** Original question: Should the app ever add filler bytes (for example a JPEG comment segment or trailing data) when an image cannot reach the minimum by quality? Pro: meets floor on very simple images, such as clean signatures. Con: it is deceptive filler, some portals or validators may reject trailing or odd data, it changes the file for no visual benefit, and it adds privacy-review burden. Default in this PRD: no padding. A decision is needed because `BELOW_MIN` on clean signatures is plausible (signature floors of 10 KB are in the research [Fact]).
- [ ] **OQ-3: PNG lossy colour reduction.** Allow an opt-in "reduce colours" for PNGs above the maximum? Pro: PNG could fit more targets. Con: no longer lossless, new UI and tuning. Default: not in R1.
- [ ] **OQ-4: Maximum target W×H and output formats.** Confirm the upper pixel bound (24 MP [Assumption]) and that output is JPEG/PNG only.
- [ ] **OQ-5: Decimal KB.** Are targets like 7.5 KB required? Default: whole KB.
- [ ] **OQ-6: ICC profile and colour policy.** Convert to sRGB and drop the profile, or keep it? Bytes count toward size. Who owns it: FEAT-004, FEAT-018 or FEAT-010?
- [ ] **OQ-7: Export-anyway override.** Should the user be able to export an out-of-range or too-degraded candidate after an explicit warning? The roadmap says never silently, so this PRD says no; if yes, it belongs in FEAT-015.
- [ ] **OQ-8: Quality floor value** (40 [Assumption]) and whether signatures use a different floor from photos. Needs a visual test set (Stage 6).
- [ ] **OQ-9: Order of metadata and size search** (inside the loop versus overhead estimate). Architecture decision for Stage 6; the requirement (FR-14) is the same.
- [ ] **OQ-10: Minimum Android version and HEIC support.** Needs the minSdk decision.
- [ ] **OQ-11: Accuracy measurement.** Does the first-try metric count a safe-rule success or the portal's own measurement? The brief measures it via an on-device counter, which conflicts with a no-telemetry stance (FEAT-027).

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-19 | First draft |
| 0.2 | 2026-11-19 | Review fixes: ABOVE_MAX/TOO_DEGRADED split, NO_FIT added, determinism split (FR-15 Must same-device, new FR-21 Should cross-device); OQ-1 accepted; OQ-2 JPEG comment padding allowed; effort re-estimate flagged |
| 1.0 | 2026-11-19 | Approved by Product Owner |
