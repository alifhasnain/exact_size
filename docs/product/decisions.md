# Decision Log

Append-only. Written by `/approve`; one row per Product Owner decision.

| Date | ID | Decision | Version | Note |
|---|---|---|---|---|
| 2026-11-18 | BRIEF | Approved | 1.0 | 6 non-blocking open questions carried into Stage 2 |
| 2026-11-18 | RESEARCH | Approved | 1.0 | Low–Medium confidence; A2 accuracy, A3, A4 tool weakness untested — hands-on tests and operator interviews recommended |
| 2026-11-18 | FEAT-024 | Rejected | — | PDF output under a KB limit: large effort, weak demand evidence |
| 2026-11-18 | FEAT-029 | Scope change | — | "Photo age" check removed (not detectable from the image); feature stays Proposed |
| 2026-11-18 | BRIEF | Paid tier = yearly subscription | 1.1 | Price points per region still open; BRIEF back to Under Discussion until re-approved |
| 2026-11-18 | BRIEF | Launch languages = English, Spanish, Portuguese (BR), Hindi, Indonesian, Arabic | 1.1 | Bangla considered as swap for Arabic; not chosen |
| 2026-11-18 | BRIEF | Approved | 1.1 | Re-approved with yearly subscription and launch languages; 4 non-blocking open questions remain |
| 2026-11-18 | ROADMAP | MVP Option B chosen | 0.5 | Presets (FEAT-011, 014) into MVP; languages (FEAT-019) to start of M2; MVP 9.7 pw; no ads in MVP. BRIEF to 1.2 (Under Discussion) |
| 2026-11-18 | ROADMAP | Development scope = M1 + M2 | 0.5 | ~20.2 pw (~5 months solo); M3 parked, no PRDs for M3 features unless re-prioritised |
| 2026-11-18 | ROADMAP | M1 + M2 merged into first public release R1 | 0.6 | Supersedes "scope = M1 + M2" row: 23 features, 20.2 pw (~5 months solo), built in Phase A then Phase B; Later parked. BRIEF 1.2 timeline updated |
| 2026-11-18 | BRIEF | Approved | 1.2 | First release = M1 + M2 (~5 months); 6 languages, ads and subscription at launch; open: preset accuracy owner, regional prices |
| 2026-11-18 | BRIEF | Android first; iOS later (possibly far future) | 1.3 | R1 ships on Google Play only; Flutter keeps iOS possible |
| 2026-11-18 | BRIEF | Preset updates via app releases; Firebase may host presets later | 1.3 | Product Owner keeps specs accurate; FEAT-013 stays parked |
| 2026-11-18 | BRIEF | Regional subscription pricing deferred | 1.3 | Decide before FEAT-026 PRD |
| 2026-11-18 | BRIEF | Approved | 1.3 | Android-first, presets via app releases, regional pricing deferred; no open questions left in list |
| 2026-11-18 | ROADMAP | Approved | 1.0 | R1 = 23 features, 20.2 pw (~5 months solo), Android first; Phase A then Phase B; Later parked |
| 2026-11-19 | FEAT-003 | Merged into FEAT-002 (Rejected) | — | Crop and resize are one user step; FEAT-002 E = 1.3 |
| 2026-11-19 | FEAT-017 | Merged into FEAT-016 (Rejected) | — | Offline follows from on-device; FEAT-016 E = 0.5 |
| 2026-11-19 | ROADMAP | Under Discussion | 1.1 | Merges applied; R1 = 21 features, 20.2 pw unchanged; needs re-approval |
| 2026-11-19 | ROADMAP | Approved | 1.1 | Merges FEAT-003→002 and FEAT-017→016 accepted; R1 = 21 features, 20.2 pw |
| 2026-11-19 | FEAT-004 OQ-1 | KB rule accepted | 0.2 | min×1024 ≤ size ≤ max×1000; narrow ranges aim at max×1000 with a notice |
| 2026-11-19 | FEAT-004 OQ-2 | JPEG comment padding allowed | 0.2 | Only after quality levers fail; neutral content, disclosed to user; no trailing bytes; no PNG padding in R1 |
| 2026-11-19 | FEAT-004 | Approved | 1.0 | PRD: min–max KB compression; 9 non-blocking open questions left for Stage 6 |
| 2026-11-19 | FEAT-002 | Scope trims | 0.2 | Platform decoder gives 8-bit sRGB (no custom colour engine); no linear-light/PSNR targets; visible nudge/zoom buttons Should (TalkBack actions + Centre/Reset stay Must) |
| 2026-11-19 | FEAT-002 OQs | Decided | 0.2 | Rotate 90° = Should; upscale notice >1×, confirm >2×; keep read URI (no copy); no crop handles in R1; brightness/contrast never in R1; hide from recents on Android 13+ |
| 2026-11-19 | FEAT-002 OQ-5 | Revised: corner crop handles in R1 (Should) | 0.3 | Supersedes earlier "no handles in R1"; proportional, ratio locked to W:H; about +0.4 pw [Assumption], to be confirmed in the Stage 6 re-estimate |
| 2026-11-19 | ROADMAP effort | Deferred to Stage 6 | 1.1 | FEAT-002 (+0.4 pw handles, likely ~3 pw total) and FEAT-004 re-estimates update the roadmap together after /tech-plan |
| 2026-11-19 | FEAT-002 | Approved | 1.0 | PRD: crop and resize with corner handles (Should) and rotate (Should); 6 non-blocking open questions for Stage 6 |
