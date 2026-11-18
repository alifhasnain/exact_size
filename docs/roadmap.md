---
id: ROADMAP
title: Roadmap & Prioritized Backlog
status: Proposed
version: 0.3
updated: 2026-11-18
links: [BRIEF, RESEARCH]
---

# Roadmap & Prioritized Backlog

> Backlog filled in Stage 3 (`/discover-features`), scored in Stage 4 (`/prioritize`).
> Rejected features stay in the table with status `Rejected`; IDs are never reused.

## Scoring
- **RICE** = Reach × Impact × Confidence ÷ Effort
  - Reach: users affected per quarter
  - Impact: 3 massive · 2 high · 1 medium · 0.5 low · 0.25 minimal
  - Confidence: 100% / 80% / 50%
  - Effort: person-weeks
- **MoSCoW** (MVP only): Must · Should · Could · Won't (this release)
- **Release**: MVP · Next · Later

## Backlog
| ID | Feature | Value statement | User value | Business value | Complexity | Depends on | Source | R | I | C | E | RICE | MoSCoW | Release | Status | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| FEAT-001 | [Core] Pick image from camera or gallery | Start from any photo in two taps | No file hunting; works with a fresh selfie or saved image | Entry point of every flow; needed for the under 30 s metric | S | Camera/photo permission strings and store disclosures | BRIEF Pitch; Success metrics | | | | | | | | Proposed | |
| FEAT-002 | [Core] Crop to target aspect and dimensions | Frame the subject at the form's exact ratio | Correct framing without guesswork | Required step for exact output | M | FEAT-001 | BRIEF Pitch | | | | | | | | Proposed | |
| FEAT-003 | [Core] Resize to exact pixel dimensions | Output is exactly W×H px | Portal accepts dimensions first time | Core promise (UVP) | S | FEAT-002 | BRIEF UVP | | | | | | | | Proposed | |
| FEAT-004 | [Core] Compress to a min–max KB range with JPEG/PNG choice | Land inside the KB range and format in one step | No trial and error; meets floor and ceiling | Main differentiator vs max-only tools | L | FEAT-003; on-device KB search validated in Stage 6 | BRIEF UVP; RESEARCH gap 1, A4 | | | | | | | | Proposed | |
| FEAT-005 | [Core] Manual target entry (W×H, KB min/max, format) | Handle any form, not only listed ones | Works for forms not in the library | Covers long tail without maintaining presets | S | none | BRIEF Target input | | | | | | | | Proposed | |
| FEAT-006 | [Core] Preview with "meets spec" check | Show real dimensions, KB and format against the spec before export | Confidence before upload | Drives first-try success metric (99%) | M | FEAT-004 | BRIEF Success metrics; RESEARCH UX patterns | | | | | | | | Proposed | |
| FEAT-007 | [Core] Export and share | Save to gallery or share to any app | Get the file into the portal's upload picker | Completes the job; no upload by us | S | FEAT-006; storage permission disclosures | BRIEF Pitch | | | | | | | | Proposed | |
| FEAT-008 | [Core] Fill vs fit modes | Choose crop-to-fill or pad-to-fit | Avoids stretched or cropped faces | Matches pattern seen on Imresizer | S | FEAT-002 | RESEARCH UX patterns | | | | | | | | Proposed | |
| FEAT-009 | [Core] Quick dual flow: photo then signature | One guided run for both uploads of a form | Finish a whole form's images in one session | Cuts time to export; fits applicant job-to-be-done | M | FEAT-004; FEAT-011 | BRIEF Target users; RESEARCH gap 3 | | | | | | | | Proposed | |
| FEAT-010 | [Core] DPI metadata setting | Write required DPI (e.g. 200/300) into the file | Passes portals that check DPI | Parity with Imresizer; small cost | S | FEAT-004 | RESEARCH Landscape (Imresizer) | | | | | | | | Proposed | |
| FEAT-011 | [Presets] Built-in preset library | Pick a popular form and get its spec | No need to read the circular | Retention and store-search relevance | M | Spec sourcing and accuracy owner (open question); FEAT-005 | BRIEF Target input | | | | | | | | Proposed | |
| FEAT-012 | [Presets] Saved custom presets | Reuse own specs in one tap | No re-typing for repeat forms | Needed by operators; upgrade hook | S | FEAT-005; local storage only | BRIEF Target input; RESEARCH gap 4 | | | | | | | | Proposed | |
| FEAT-013 | [Presets] Preset update mechanism without backend | Refresh presets without an app release | Library stays current as circulars change | Lowers maintenance for solo dev | M | Static signed file host (a CDN or repo); network call must send no user data; store disclosures | BRIEF Open questions; RESEARCH Market notes | | | | | | | | Proposed | |
| FEAT-014 | [Presets] Preset source note and "check your notice" prompt | Show where each spec came from and its last-checked date | Users verify against their own notice | Limits liability for stale specs | S | FEAT-011 | RESEARCH Market notes | | | | | | | | Proposed | |
| FEAT-015 | [Trust] Over-compression guard and honest "can't reach this size" message | Never silently output a bad file; explain and suggest a fix | Avoids failed uploads and blurry results | Trust; differentiator | M | FEAT-004 | RESEARCH gap 1; UX patterns | | | | | | | | Proposed | |
| FEAT-016 | [Trust] On-device-only processing with in-app privacy explainer | Make "photos never leave your phone" true and visible | Safe for identity-sensitive signatures | Core UVP; basis for honest store labels | S | Ad SDK data accounted for (no "no data collected" claim); store privacy disclosures | BRIEF UVP, Compliance; RESEARCH gap 2 | | | | | | | | Proposed | |
| FEAT-017 | [Trust] Offline-first operation | All core flows work with no network | Usable on poor connections | Strong in emerging markets | S | FEAT-016; ads degrade gracefully offline | BRIEF UVP | | | | | | | | Proposed | |
| FEAT-018 | [Trust] Strip location/EXIF metadata on export | Remove GPS and device data from output | Prevents leaking location in uploads | Privacy proof point; low cost | S | FEAT-010 (metadata handling) | RESEARCH gap 2 [Assumption] | | | | | | | | Proposed | |
| FEAT-019 | [Core] Localisation: English + 3–5 languages with RTL | Use the app in the user's language | Lower friction for non-English users | Gap in competitors (e.g. no Bengali) | M | Languages decided 2026-11-18: English, Spanish, Portuguese (BR), Hindi, Indonesian, Arabic; RTL layout for Arabic | BRIEF Platforms; RESEARCH gap 5 | | | | | | | | Proposed | |
| FEAT-020 | [Signature] Signature cleanup (whiten paper, darken ink) | Turn a phone photo of a signature into a clean upload | Signature accepted and legible | Only seen in one web tool; native gap | M | FEAT-004; signature treated as identity-sensitive, no logging | RESEARCH gap 3; UX patterns | | | | | | | | Proposed | |
| FEAT-021 | [Signature] Signature auto-crop to ink bounds | Trim whitespace to target ratio | Faster, tidier signature | Supports dual flow | S | FEAT-020 | BRIEF Open questions | | | | | | | | Proposed | |
| FEAT-022 | [Operator] Batch processing | Process many images with one preset | Operators finish queues fast | Core paid-upgrade candidate | L | FEAT-012; memory handling for large sets | BRIEF Business model; RESEARCH gap 4 (A3 unproven) | | | | | | | | Proposed | |
| FEAT-023 | [Operator] Customer-named output files and recents | Name files per customer and reopen recent jobs | Avoids mixing up customers' files | Operator stickiness | S | FEAT-022; recents stored locally with clear-all control (privacy) | RESEARCH gap 4 [Assumption] | | | | | | | | Proposed | |
| FEAT-024 | [Core] PDF output under a KB limit | Export a document image as PDF within the KB range | Meets forms that ask for scanned PDFs | Rare among tools; extra-tier option | L | FEAT-004; Product Owner scope decision | BRIEF Open questions; RESEARCH Market notes | | | | | | | | Rejected | |
| FEAT-025 | [Monetisation] Ads with consent flow | Fund the free tier with ads shown only after valid consent | Free core app | Main free-tier revenue | M | CMP for GDPR/UK; Apple ATT; Play Data Safety and App Store labels; COPPA/under-13 handling | BRIEF Business model, Compliance | | | | | | | | Proposed | |
| FEAT-026 | [Monetisation] Paid ad-free upgrade (store IAP) | Remove ads and unlock extras | Clean, faster experience | Revenue; target 1–2% conversion | M | FEAT-025; yearly subscription (decided 2026-11-18), regional price points open; store IAP only (no payment data handled) | BRIEF Business model; RESEARCH Market notes | | | | | | | | Proposed | |
| FEAT-027 | [Trust] Anonymous on-device success and timing counters | Measure first-try success and time to export | Indirect: better product | Tracks the success metrics | S | FEAT-025 consent state; disclose in store labels; no images or identifiers | BRIEF Success metrics | | | | | | | | Proposed | |
| FEAT-028 | [Later] AI background removal/replacement | Fix photo backgrounds to a required colour | Meets content rules (e.g. white background) | Premium upsell | L | New privacy review and explicit consent if not on-device; Later release | BRIEF Out of scope; RESEARCH A1 | | | | | | | | Proposed | |
| FEAT-029 | [Later] Content compliance checks (face position, background) | Warn before upload on non-size rules (photo age dropped: not detectable from the image) | Fewer rejections beyond size | Competes with PhotoAiD-class tools; Later release | L | Product Owner scope decision; on-device model | RESEARCH A1, open questions | | | | | | | | Proposed | |

## Milestones
| Milestone | Goal | Features | Exit criteria |
|---|---|---|---|

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-18 | Skeleton created |
| 0.2 | 2026-11-18 | Stage 3: 29 candidate features FEAT-001 to FEAT-029 added (unscored, Proposed) |
| 0.3 | 2026-11-18 | FEAT-024 rejected; photo age removed from FEAT-029; FEAT-026 yearly subscription; FEAT-019 languages decided |
