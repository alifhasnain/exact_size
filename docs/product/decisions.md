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
| 2026-11-20 | ADR-001 minSdk | Android 9 (API 28) | 0.2 | HEIC decodes on all supported devices; Android 7.0–8.1 dropped |
| 2026-11-20 | ADR-001 state management | Riverpod | 0.2 | Replaces built-in ChangeNotifier proposal |
| 2026-11-20 | ADR-001 Flutter version | Flutter 3.50.x, pinned | 0.2 | FFIgen/JNIgen for native calls; release-note claims to verify at scaffold |
| 2026-11-20 | ADR-001 | Approved | 1.0 | Flutter 3.50.x + FFIgen/JNIgen, minSdk 28, Riverpod |
| 2026-11-20 | ADR-002 | Approved | 1.0 | Pinned libjpeg-turbo via FFI for JPEG, `image` package for PNG; spike may fall back to Option B |
| 2026-11-20 | ADR-003 | Approved | 1.0 | Native in-memory pixel buffer, ownership moves to FEAT-004; answers FEAT-002 OQ-10 |
| 2026-11-20 | FEAT-004 OQ-12 | Pad in narrow-window jump case | 1.1 | FR-8 applies; `NO_FIT` only with < 4 bytes of room; `WRITE_FAILED` added |
| 2026-11-20 | FEAT-004 OQ-3–11, OQ-13 | Tech-plan proposals accepted unchanged | 1.1 | See FEAT-004-TECH section 12 |
| 2026-11-20 | FEAT-004 | Under Discussion | 1.1 | Clarification after Stage 6; needs re-approval |
| 2026-11-20 | FEAT-004 | Approved | 1.1 | Re-approved after Stage 6 clarification (OQ-12 padding, OQ-3–13 decided); no open questions |
| 2026-11-20 | FEAT-004-TECH | Approved | 1.0 | Effort re-estimate ~3.9 pw (vs 2.0) to go into the roadmap update after FEAT-002 tech plan |
| 2026-11-20 | FEAT-002 FR-6 | Source ceiling 200 MP (was 100 MP) | 1.1 | Best effort; files that need full decode and don't fit in memory get IMAGE_TOO_LARGE; output cap stays 24 MP; ~+0.2 pw |
| 2026-11-20 | FEAT-002 | Under Discussion | 1.1 | Source ceiling change; needs re-approval |
| 2026-11-20 | FEAT-002 | Approved | 1.1 | Re-approved with 200 MP source ceiling; OQ-4, 6, 9, 10, 11, 12 still open (non-blocking, proposals in FEAT-002-TECH) |
| 2026-11-20 | ADR-004 | Approved | 1.0 | Platform region decoder via JNIgen + own EXIF orientation step; spike checks 12–200 MP and HEIC rotation |
| 2026-11-20 | ADR-005 | Approved | 1.0 | Pinned stb_image_resize2 (Catmull-Rom) in es_codec |
| 2026-11-20 | FEAT-002 OQ-12 | Option A: same device = same device and OS build; cross-device stays Should | 1.2 | No bundled decoders |
| 2026-11-20 | FEAT-002 OQ-4, 6, 10, 11, 13, 14 | Tech-plan proposals written into PRD v1.2 | 1.2 | To be confirmed by re-approving FEAT-002 v1.2 |
| 2026-11-20 | FEAT-002 | Under Discussion | 1.2 | Clarification after Stage 6; needs re-approval |
| 2026-11-20 | FEAT-002 | Approved | 1.2 | Re-approved; confirms OQ-4, 6, 10, 11, 12, 13, 14; only OQ-9 (Shoulds in R1) open, for the roadmap update |
| 2026-11-20 | FEAT-002-TECH | Approved | 1.0 | Effort ~4.7 pw (0.7 pw Shoulds); keep-or-defer Shoulds decided in roadmap update |
| 2026-11-20 | ROADMAP | Under Discussion | 1.2 | Stage 6 effort update drafted: R1 20.2 → 25.8 pw; needs Product Owner decision on options and re-approval |
| 2026-11-20 | FEAT-002 OQ-9 | Should items (handles, rotate, nudge buttons, 0.7 pw) stay in R1 | 1.2 | R1 stays 25.8 pw; PRD OQ-9 checkbox to be ticked at the next FEAT-002 PRD change |
| 2026-11-20 | ROADMAP | Approved | 1.2 | Stage 6 effort update: R1 25.8 pw (Phase A 13.8, Phase B 10.5, setup 0.3, store 1.5); FEAT-002 Shoulds kept; spike merge (b) still an option; BRIEF timeline needs update |
| 2026-11-20 | BRIEF | Under Discussion | 1.4 | Timeline aligned with ROADMAP v1.2 (25.8 pw); stack lines point to ADR-001/002; needs re-approval |
| 2026-11-20 | BRIEF | Approved | 1.4 | Timeline about 6.5 months / 25.8 pw; stack per ADR-001/002 |
| 2026-11-20 | FEAT-004-TASKS | CI = GitHub Actions; PNG-to-JPEG switch re-renders via FEAT-002 | 0.2 | No low-end test device on hand; sourcing pending |
| 2026-11-20 | ADR-001 DI | get_it + injectable for dependency injection; Riverpod keeps state | 1.1 | ADR-001 and BRIEF back to Under Discussion; FEAT-004 tasks T01/T20 updated |
| 2026-11-20 | Test environment | Emulators only (2 GB RAM profile, API 28 + latest); no physical low-end device | — | Timing targets best effort; risk of real low-end slowness/kills accepted; FEAT-004 PRD 1.2, FEAT-002 PRD 1.3, ROADMAP 1.3 Under Discussion |
| 2026-11-20 | ADR-001 | Approved | 1.1 | get_it + injectable for DI; Riverpod for state |
| 2026-11-20 | BRIEF | Approved | 1.5 | Technology line: get_it + injectable for DI (ADR-001 v1.1) |
| 2026-11-20 | FEAT-004 | Approved | 1.2 | Re-approved with emulator-only test environment; timing targets best effort |
| 2026-11-20 | FEAT-002 | Approved | 1.3 | Re-approved with emulator-only test environment; OQ-9 ticked; no open questions |
| 2026-11-20 | ROADMAP | Approved | 1.3 | Phase A exit on emulators (2 GB RAM profile); timing targets best effort |
| 2026-11-20 | FEAT-004-TASKS | Approved | 1.0 | 27 tasks; T01-T02 shared scaffold; emulator-only testing; T27 blocked until FEAT-002 |
| 2026-11-20 | FEAT-004 gate G0 | Passed | — | minSdk 28 allowed; FFIgen, JNIgen, record_use work (CI run 44748990934); native build uses Dart hooks instead of CMake (ADR-001 wording clarification proposed) |
| 2026-11-20 | ADR-001 | Under Discussion | 1.2 | Wording: native build via Dart build hooks, not CMake; needs re-approval |
| 2026-11-20 | FEAT-004-TASKS | Under Discussion | 1.1 | Note: CMake mentions mean Dart build hooks (ADR-001 v1.2); needs re-approval |
| 2026-11-20 | ADR-001 | Approved | 1.2 | Native C built with Dart build/link hooks (native_toolchain_c), not CMake |
| 2026-11-20 | FEAT-004-TASKS | Approved | 1.1 | Build-hooks note (ADR-001 v1.2); T01-T02 done |
| 2026-11-20 | FEAT-004 gate G1 | Passed: ADR-002 Option C (libjpeg-turbo) kept | — | Builds and runs on the emulator; informational timings: C 123-334 ms median per 2 MP pass, B (pure Dart) 3.5-6x slower |
| 2026-11-20 | FEAT-002-TASKS | Approved | 1.0 | 29 tasks (~4.7 pw); design gate G3 before visual tasks; T16/T17/T20 wait for FEAT-004-T16/T18/T21 |
| 2026-11-21 | FEAT-004 gate G2 | Passed: FR-21 met on the tested ABIs | — | 30 golden cases identical on the x86_64 emulator (API 28 in CI, API 36 local), an arm64-v8a phone (S23 Ultra) and the Windows and Linux x64 hosts; no arm64 emulator available; armeabi-v7a not tested (no device) |
| 2026-11-21 | FEAT-004 gate G3 | Passed: NFR-2 and NFR-8 met on the emulator profile | — | Peak memory for 2 MP targets at most 49.5 MB (limit 150 MB) on API 28 and 18.9 MB on API 36; corpus 100% in window, 100% feasible success on both APIs; offline run passes; all 139 padded files decode with BitmapFactory; no ANR. Timings informational |
| 2026-11-21 | FEAT-004 gate G4 | Passed: JPEG quality floor 40 confirmed for photos and signatures (Product Owner) | — | T26 contact sheet and SSIM: no knee between q30 and q50; signatures keep 100% ink and no stroke breakup from q40; blocking visible at q30 |
| 2026-11-21 | FEAT-002 gate G1 (HEIC orientation) | Read HEIF orientation in our own code (Product Owner) | — | Decode matrix: BitmapFactory/region decoder ignore irot/imir on API 28 and 36; ExifInterface on HEIC reports irot rotation without mirroring on API 28 and EXIF only on API 36. Rule: irot/imir of the primary item when present, else the EXIF orientation in the file; same on every API level. ADR-004 change to follow |
| 2026-11-21 | FEAT-002 gate G1 (large HEIC fixtures) | Install MSYS2 libheif (heif-enc) as a dev-only tool to make tiled 50/100/200 MP HEIC fixtures (Product Owner) | — | pillow-heif writes one HEVC frame, which neither the emulator nor the S23 Ultra can decode above 12 MP |
| 2026-11-21 | FEAT-002 gate G1 (corrupt files) | Add a file-structure check before decoding; a broken file gets CORRUPT_INPUT (Product Owner) | — | Android decodes truncated JPEG (both APIs) and corrupt PNG (API 36) without an error |
| 2026-11-21 | ADR-004 | Approved | 1.1 | Gate G1 spike results: own HEIF irot/imir + EXIF orientation reader, structure check before decode (CORRUPT_INPUT, early IMAGE_TOO_LARGE), per-format memory factor, GIF on the full path, tiled HEIC confirmed |
| 2026-11-21 | FEAT-002-TECH | Approved | 1.1 | Gate G1 results: ContainerCheck and HeifOrientation components, GIF on the full path, per-format memory factors, R4 updated, R12 (own parsers read untrusted bytes) added |
| 2026-11-21 | FEAT-002-TASKS | Approved | 1.1 | New task T30 (ContainerCheck, HeifOrientation) before T12; T12 and T16 use the G1 results |
| 2026-11-21 | FEAT-002 gate G1 | Passed: ADR-004 v1.1, FEAT-002-TECH v1.1 and FEAT-002-TASKS v1.1 approved (Product Owner) | — | T04 decision record in docs/CHANGELOG.md; T30 and T12 onwards may start |
| 2026-11-21 | FEAT-002 gate G2 | Passed: Catmull-Rom accepted as the resampler (Product Owner) | — | T13 chart docs/features/FEAT-002-crop-resize/t13/resampler_chart.png: both filters anti-alias on reduction; Catmull-Rom slightly crisper on enlargement; no dark fringe on alpha edges |
| 2026-11-21 | ROADMAP | Approved | 1.4 | FEAT-019 and Phase B exit: native-speaker review replaced by the AI-only review workflow (/l10n-translate); no native reviewer available, residual translation risk accepted [Hypothesis]; effort unchanged |
| 2026-11-21 | FEAT-002 gate G4 | Passed: orientation and determinism tests green on API 28 (CI) and API 36 | — | 23 orientation cases upright and not mirrored in preview and render; same-device renders byte-identical; re-crop and four-rotation outputs identical to fresh renders; cross-ABI run not done (phone not connected; Should) |
| 2026-11-21 | FEAT-002 gate G3 | Passed: crop screen design approved (Product Owner) | — | impeccable lean path, direction "ID photo booth" (seed:b60936c27bab1bdd); reference docs/features/FEAT-002-crop-resize/t22/crop_screen_design.md v0.2, review_sheet.png (synthetic images only), contract .impeccable/surfaces/lib-features-crop-presentation-crop-screen-dart.md; finish review and DESIGN.md skipped (lean budget); T23-T28 may start |
| 2026-11-21 | FEAT-002 gate G5 | Passed: NFR-2 memory limits and NFR-8 reliability met on the API 28 (CI) and API 36.1 emulators; airplane-mode run completed | — | Peak memory, as lower bounds from 5 ms sampling: 12 MP to 2 MP at most 11.5 MB (limit 200 MB); 50 MP to a 24 MP target at most 230.9 MB (limit 350 MB). Computed worst case about 19 MB and 274 MB. No crash or ANR on the large and broken set. Timings and frame rate are informational (docs/CHANGELOG.md). All FEAT-002 tasks are ticked |
| 2026-11-21 | FEAT-002 | Implemented | 1.3 | All 30 tasks ticked; gates G1-G5 passed; open follow-ups: PO wording approval for the T10 developer strings and zoom step, cross-ABI determinism on a physical device (Should) |
| 2026-11-21 | FEAT-004 | Approved | 1.3 | AC-5.2 clarification: corrupt files give CORRUPT_INPUT, undecodable formats UNSUPPORTED_INPUT (matches FEAT-002 gate G1, ADR-004 v1.1); FEAT-004-TASKS T27 done-when wording still says UNSUPPORTED_INPUT for corrupt files |
| 2026-11-21 | FEAT-004 | Implemented | 1.3 | All tasks ticked (T27 end-to-end with FEAT-002 green on the API 36.1 emulator); open follow-ups: PO wording approval for T19, T27 done-when wording in FEAT-004-TASKS |
| 2026-11-21 | FEAT-001 | Approved | 1.0 | OQ-1 system photo picker with document-picker fallback and OQ-2 system camera intent, both without runtime permissions; OQ-4 (photo-first vs target-first, start-screen owner) stays open and blocks UI work only |
| 2026-11-21 | ADR-006 | Approved | 1.0 | Kotlin activity-result bridge in MainActivity over one MethodChannel for photo picker, document picker and camera intent; deviation from the Dart-only stance of ADR-001 accepted (ADR-001 clarification line is OQ-T7, not done yet) |
| 2026-11-21 | FEAT-001-TECH | Approved | 1.0 | ADR-006 bridge; effort about 1.6 pw (roadmap row says 0.5, PRD OQ-9 update pending). Proposals OQ-T1 to OQ-T7 stand as written; OQ-T1 (zero-byte file gives CORRUPT_INPUT in FEAT-002 SourceProbe) and OQ-T7 (ADR-001 pointer) need their own doc changes; PRD OQ-4 still blocks the pick-screen UI task |
| 2026-11-21 | FEAT-001-TASKS | Approved | 1.0 | 25 tasks (Musts T01-T19, Shoulds T20-T25), gates G1-G4; PRD OQ-4 blocks T16 onwards |
| 2026-11-21 | FEAT-001 gate G1 | Passed (Product Owner) | — | On the API 36.1 emulator and the S23 Ultra (API 37): picker, camera (full size, survives process death), grants in the probe isolate, share cold and warm all pass; (g) passes with a duplicate-launcher guard (`!isTaskRoot` + MAIN/LAUNCHER finishes), added in T10 as part of ADR-006 Option B; API 28 not run locally, covered by CI API 28 in T15. Record: docs/features/FEAT-001-pick-image/t01/spike_record.md |
| 2026-11-22 | FEAT-001 OQ-4 | Decided (Product Owner): photo first | 1.1 | Pick screen is the start screen (FEAT-001); accepted, shared and recovered images go to the target step (FEAT-005/011), then crop. PRD 1.1 Under Discussion until /approve FEAT-001 |
| 2026-11-22 | FEAT-001 | Approved | 1.1 | OQ-4 photo first recorded; no blocking open questions left (OQ-5 to OQ-10 non-blocking). Unblocks T16 (gate G3) |
| 2026-11-22 | FEAT-001 gate G3 | Passed (Product Owner) | — | Pick screen design "booth front" approved: t16/pick_screen_design.md v0.1 and review_sheet.png (6 states). Unblocks T17, T18 and the UI parts of T22, T23 |
| 2026-11-23 | FEAT-001 gate G4 | Passed with waiver (Product Owner) | — | API 28 AOSP and Google Play manual checklist rows not run (no local images; download declined). Evidence: API 36.1 emulator, S23 Ultra (camera rows), CI automated API 28 jobs. All reliability, privacy and permission rows passed |
| 2026-11-23 | FEAT-001 | Implemented | 1.1 | All 25 tasks ticked; gates G1-G4 passed (G4 with the API 28 manual-row waiver); share target (Should) and Choose from files (Should) built; CI run 45200898069 green. Open follow-ups: OQ-6 and OQ-7 built as proposed (PO confirmation), OQ-9 roadmap effort 0.5 to about 1.7 pw (PO decision), OQ-10 Play policy check before release, OQ-5/8/11 non-blocking, OQ-T7 ADR-001 pointer line, FEAT-007 must call PickController.release() |
