---
id: BRIEF
title: ExactSize — Product Vision & Brief
status: Approved
version: 1.5
updated: 2026-11-20
links: []
---

# Product Vision & Brief

> Filled in Stage 1 (`/product-brief`). Tag guesses `[Assumption]`.

## One-line pitch
**ExactSize** — resize a photo or signature to the exact pixel size and file size (KB) an application form demands, in seconds, on your phone.

## Problem
Online application forms (jobs, admissions, exams, government services) reject uploads unless the photo/signature matches strict limits on dimensions and file size (e.g. "300×300 px, max 100 KB"). [Assumption] Applicants today fix this by trial and error in generic editors, by using ad-heavy web tools, or by paying a computer shop — slow, confusing, and the upload still often fails.

## Target users
| Segment | Description | Primary job-to-be-done |
|---|---|---|
| Job applicants | Government and private job seekers filling online applications | Get photo + signature accepted by the portal on the first upload |
| Students | Admissions, board/entrance exams, scholarships | Meet the form's exact photo/signature spec before the deadline |
| Cyber café operators | Shops filling forms for many customers daily | Process many customers' images fast and reliably (speed, batch, repeatable presets) |
| Visa/passport applicants | Passport, visa, lottery-style photo rules | Produce a photo that meets an official size/KB spec |

## Unique value proposition
Hits the **exact** target (pixel dimensions + KB range + format) in one step — no trial and error — and photos never leave the phone: works offline, nothing uploaded. [Assumption] Competitors miss on at least one of: exact-KB accuracy, privacy, or ad overload — to verify in Stage 2.

## Platforms & markets
- Market: **Global** from launch (no single-country focus).
- Platforms: **Android first** (Product Owner decision 2026-11-18), built in **Flutter** with platform-specific code only where needed (ADR-001: Flutter 3.50.x, minimum Android 9 / API 28). iOS is later, possibly far future; keep the code iOS-ready but plan no iOS work.
- Languages: **English, Spanish, Portuguese (Brazil), Hindi, Indonesian, Arabic** (Product Owner decision, 2026-11-18). Arabic needs RTL layout. All 6 ship in the first public release (M1 and M2 merged, 2026-11-18).
- Target input: manual entry (W×H, KB range, format) + **built-in preset library** for popular forms worldwide + **saved custom presets**.

## Business model
Free core with ads; paid upgrade removes ads and unlocks extras (e.g. batch processing, future AI features). Paid tier is a **yearly subscription** (Product Owner decision, 2026-11-18). Ads and subscription both ship in the first public release. Price point: deferred, to be decided later — set per store region (purchasing power differs widely across target markets).

## Success metrics
All targets below are [Assumption] starting points for the Product Owner to adjust.

| Metric | Target | How measured |
|---|---|---|
| First-try success: output inside the requested KB range and dimensions | ≥ 99% of exports | On-device check at export (anonymous counter) |
| Time from opening the app to an exported file | < 30 s median | Anonymous in-app timing |
| Day-30 retention | ≥ 15% | Store / analytics console |
| Store rating | ≥ 4.5 | Play Store / App Store |
| Paid conversion (ad-free) | ≥ 1–2% of monthly active users | Store revenue reports |

## Constraints
- **Team / timeline:** solo developer with Claude Code. First public release is about 6.5 months (25.8 person-weeks, ROADMAP v1.2): core and Phase B shipped together (Product Owner decision 2026-11-18, replacing the original 2–3 month MVP target; re-estimated 2026-11-20 after the Stage 6 tech plans for FEAT-002 and FEAT-004).
- **Technology:** Flutter 3.50.x with Riverpod (state) and get_it + injectable (dependency injection); native C via Dart FFI for image codecs (ADR-001, ADR-002); on-device processing only; no backend for R1.
- **Budget:** minimal — store developer fees, no paid servers. [Assumption]
- **Regulation:** ad consent (GDPR/UK, ATT), store privacy disclosures, children's privacy (see Compliance scope).

## Compliance scope
- **Processing:** on-device only for now. Photos and signatures (personal data; signatures are identity-sensitive) never leave the device. Future AI features may change this and will need a fresh privacy review and explicit consent.
- **Payments:** only App Store / Google Play in-app purchase — the stores handle payment data, so no PCI-DSS scope and no Bangladesh Bank payment rules apply to the app itself. [Assumption]
- **Ads SDK is the main privacy exposure:** it collects device identifiers → needs GDPR/UK consent (CMP) for EU/UK users, Google Play Data Safety (plus Apple ATT and App Store labels only when iOS ships), and care with under-13 users (COPPA) since students are a target segment.
- No accounts and no server storage planned. [Assumption]

## Out of scope (MVP) — proposed
- Cloud processing, user accounts, cloud sync/backup.
- AI features (background removal/replacement, enhancement) — candidates for a later release.
- Submitting forms or uploading to portals on the user's behalf.
- Desktop/web versions.
- General photo editing beyond what form compliance needs (filters, collages, etc.).

## Assumptions
- Users mostly fail on file size (KB) and dimensions, not on content rules (face position, background colour). To verify in Stage 2.
- Existing tools are ad-heavy, inaccurate on exact KB, or upload images to servers. To verify in Stage 2.
- Cyber café operators will pay for batch processing and saved presets.
- Ad revenue alone is small in the main emerging markets; the ad-free upgrade matters.
- Exact-KB output is technically reliable on-device (adjust compression quality and dimensions until the file falls inside the KB range). To confirm in Stage 6.

## Open questions
- [x] Store launch order: Android first; iOS later, possibly far future (decided 2026-11-18).
- [x] Languages: Spanish, Portuguese (BR), Hindi, Indonesian, Arabic + English (decided 2026-11-18).
- [x] Paid tier model: yearly subscription (decided 2026-11-18). Price point per region still open.
- [x] Preset updates: specs are kept accurate by the Product Owner and shipped through app releases. Firebase may host presets later (FEAT-013, parked) (decided 2026-11-18).
- [x] Signature cleanup and auto-crop: in the first release (FEAT-020 Should, FEAT-021 Could; ROADMAP 0.6).
- [x] PDF output: not planned (FEAT-024 rejected 2026-11-18).

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-18 | Skeleton created |
| 0.2 | 2026-11-18 | Stage 1 rounds 1–2: concept, users, market, model, privacy, constraints |
| 1.0 | 2026-11-18 | Approved by Product Owner |
| 1.1 | 2026-11-18 | Paid tier set to yearly subscription; launch languages chosen (Product Owner decisions) |
| 1.2 | 2026-11-18 | First release = M1 + M2 merged: all 6 languages, ads and subscription at launch; timeline ~5 months |
| 1.3 | 2026-11-18 | Android first, iOS later; presets updated via app releases (Firebase later); regional pricing deferred |
| 1.4 | 2026-11-20 | Timeline updated to about 6.5 months / 25.8 pw (ROADMAP v1.2); stack details point to ADR-001 and ADR-002 (Flutter 3.50.x, Riverpod, minimum Android 9). Under Discussion until re-approved |
| 1.4 | 2026-11-20 | Approved by Product Owner |
| 1.5 | 2026-11-20 | Technology line: get_it + injectable for dependency injection (ADR-001 v1.1). Under Discussion until re-approved |
| 1.5 | 2026-11-20 | Approved by Product Owner |
