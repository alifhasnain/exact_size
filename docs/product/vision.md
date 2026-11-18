---
id: BRIEF
title: ExactSize — Product Vision & Brief
status: Approved
version: 1.0
updated: 2026-11-18
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
- Platforms: Android + iOS from one **Flutter** codebase; platform-specific code only where needed. (Product Owner's choice — to be recorded as an ADR in Stage 6.) Store launch order: open.
- Languages: English + 3–5 more at launch. Which ones: open. [Assumption] Candidates: Bangla, Hindi, Urdu, Arabic, Spanish — RTL layout needed if Arabic/Urdu are included.
- Target input: manual entry (W×H, KB range, format) + **built-in preset library** for popular forms worldwide + **saved custom presets**.

## Business model
Free core with ads; paid upgrade removes ads and unlocks extras (e.g. batch processing, future AI features). Price point and one-time vs subscription: open.

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
- **Team / timeline:** solo developer with Claude Code; MVP in ~2–3 months.
- **Technology:** Flutter; on-device processing only; no backend for MVP. [Assumption]
- **Budget:** minimal — store developer fees, no paid servers. [Assumption]
- **Regulation:** ad consent (GDPR/UK, ATT), store privacy disclosures, children's privacy (see Compliance scope).

## Compliance scope
- **Processing:** on-device only for now. Photos and signatures (personal data; signatures are identity-sensitive) never leave the device. Future AI features may change this and will need a fresh privacy review and explicit consent.
- **Payments:** only App Store / Google Play in-app purchase — the stores handle payment data, so no PCI-DSS scope and no Bangladesh Bank payment rules apply to the app itself. [Assumption]
- **Ads SDK is the main privacy exposure:** it collects device identifiers → needs GDPR/UK consent (CMP) for EU/UK users, Apple App Tracking Transparency, Google Play Data Safety and App Store privacy labels, and care with under-13 users (COPPA) since students are a target segment.
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
- [ ] Store launch order: Android and iOS together, or Android first?
- [ ] Which 3–5 languages besides English?
- [ ] Paid tier: one-time unlock or subscription? Price point?
- [ ] Preset library: who keeps the specs accurate, and how are updates shipped without a backend (app releases vs a static file)?
- [ ] Is signature cleanup (white background, darker ink, cropping) in the MVP or a later release?
- [ ] Does the MVP include PDF output? Some forms ask for scanned documents in PDF under a KB limit.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-18 | Skeleton created |
| 0.2 | 2026-11-18 | Stage 1 rounds 1–2: concept, users, market, model, privacy, constraints |
| 1.0 | 2026-11-18 | Approved by Product Owner |
