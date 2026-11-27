---
id: FEAT-011-T15-REVIEW
title: Candidate form list for the Product Owner's confirmation
status: Proposed
version: 0.3
updated: 2026-11-27
links: [FEAT-011, FEAT-011-TASKS]
---

# Candidate form list — for the Product Owner to confirm

Draft only. Nothing here is in the app. Every value comes from `draft_forms.md` (round 1) or `draft_forms_round2.md` (round 2) and was re-checked by an independent AI agent (`verification.md`, `verification_round2.md`). AI checks are not a substitute for your confirmation: open each source, compare the numbers, then tick the row or write the fix.

"KB-only" rows are allowed by PRD 2.0 (Approved 2026-11-27) and are built in tasks T16–T21. "Choose px" rows need you to pick one exact pixel size, which the PRD allows (OQ-4).

## Proposed for the list (19 forms)

| # | Form (id) | Country | Photo | Signature | Type | AI check | Your decision needed |
|---|---|---|---|---|---|---|---|
| 1 | bd-bpsc-bcs | BD | 300×300 px, ≤100 KB | 300×80 px, ≤60 KB | Exact px | Confirmed | Format not stated: JPEG? |
| 2 | bd-teletalk-govt-jobs | BD | 300×300 px, ≤100 KB | 300×80 px, ≤60 KB | Exact px | Confirmed | Format: JPEG? Same numbers as 1 and 19; keep separate or merge |
| 19 | bd-ntrca-registration | BD | 300×300 px, ≤100 KB | 300×80 px, ≤60 KB | Exact px | Confirmed (newest circular not reachable) | Same numbers as 1 and 2 |
| 20 | bd-ru-admission | BD | 300×400 px (order not stated), ≤100 KB, JPG | — | Exact px | Confirmed except W/H order | Confirm 300 wide × 400 high |
| 3 | in-ibps-crp-clerk | IN | 200×230 px, 20–50 KB, JPEG | 140×60 px, 10–20 KB, JPEG | Exact px | Confirmed | — |
| 16 | in-sbi-recruitment | IN | 200×230 px, 20–50 KB, JPEG | 140×60 px, 10–20 KB, JPEG | Exact px | Confirmed | Same numbers as 3 |
| 18 | in-keam | IN | "150X100" (no unit, no order) | "150X100" | Choose px | Numbers confirmed, unit and order not on page | Confirm unit and W×H on the live screen |
| 22 | in-kerala-psc | IN | 150×200 px, ≤30 KB, JPG | 150×100 px, ≤30 KB | Exact px | Confirmed (Sept 2026 notice) | — |
| 4 | in-upsc | IN | KB only: 20–200 KB, JPG | 350–500 px (no axis), 20–100 KB, JPG | Photo KB-only; signature choose px | Confirmed | Pick signature W×H, or make it KB-only |
| 5 | in-ssc-cgl | IN | — (webcam) | about 6.0×2.0 cm or 4.0×2.0 cm, 10–20 KB, JPEG | Signature KB-only or choose px | Confirmed (notice contradicts itself) | KB-only, or pick px |
| 6 | in-nta-neet-ug | IN | KB only: 10–200 KB, JPEG | KB only: 10–100 KB, JPEG | KB-only | Confirmed | — |
| 7 | in-nta-jee-main | IN | KB only: 10–200 KB, JPEG | KB only: 10–100 KB, JPEG | KB-only | Confirmed | — |
| 8 | in-evisa | IN | square, 10 KB–1 MB, JPEG | — | KB-only | Confirmed | 1 MB = 1000 or 1024 KB |
| 17 | in-embassy-consular-photo | IN (issuer; applicants in FR) | 630×810 px, "generally" ≤200 KB | no px | Exact px (photo) | Confirmed | Country FR or IN; KB limit is soft |
| 9 | pk-fpsc | PK | KB only: <30 KB, JPG | — | KB-only | Confirmed | — |
| 11 | mx-unam-suayed | MX | KB only: ≤200 KB, JPG | KB only: ≤200 KB, JPG | KB-only | Confirmed | — |
| 12 | us-dv-lottery | US | 600×600 px, ≤240 KB, JPEG | — | Exact px | Source blocked; search results agree | Check the State Department page yourself |
| 13 | us-visa-digital-image | US | 600–1200 px square, ≤240 KB, JPEG | — | Choose px | Source blocked | Pick 600×600? Or merge with 12 |
| 21 | sg-ica-eservices | SG | 400×514 px, ≤8 MB | — | Exact px | Confirmed | 8 MB = 8000 or 8192 KB |

## Proposed defaults for the open choices (2026-11-27)

These are Claude's proposals to save you time. None of them changes a number the notice states, and none of them invents a pixel size. Reply "defaults OK" or change any line.

| Choice | Proposed default | Why |
|---|---|---|
| Format for rows 1, 2, 19 (Bangladesh, format not stated) | JPEG | The app's default and what these portals' upload screens commonly take; you confirm on the live screen |
| Rows 1, 2, 19 share identical numbers | Keep three separate rows | Users search by the name they know; identical specs cost nothing |
| Rows 3 and 16 (IBPS, SBI) share identical numbers | Keep two separate rows | Same reason |
| Row 4 UPSC signature (350–500 px, no axis) | KB-only (20–100 KB, JPEG) | The notice gives no width or height, so a pixel size would be a guess |
| Row 5 SSC CGL signature (two cm sizes in one notice) | KB-only (10–20 KB, JPEG) | The notice contradicts itself; KB and format are clear |
| Row 13 US visa photo (600–1200 px) | Drop it; row 12 (DV lottery, 600×600, ≤240 KB) covers the same photo rule | 600×600 is inside the visa range and is the DV rule; one row avoids picking a size |
| Row 18 KEAM ("150X100", no unit or order) | Leave out until you see the live upload screen | Unit and order are unknown |
| Row 17 Indian Embassy Paris | Country FR; max 200 KB | Applicants are in France; the notice's "generally up to 200 KB" is the only figure |
| MB limits (row 8 e-Visa 1 MB, row 21 ICA 8 MB) | 1 MB = 1000 KB, 8 MB = 8000 KB | The smaller reading is safe whichever way the portal counts |
| Row 12 US DV lottery (source blocked for both AI checks) | Keep, after you open the State Department page once | Search results agree, but no one has read the page |

With these defaults the list has 17 forms: 10 with exact pixel sizes (rows 1, 2, 3, 12, 16, 17, 19, 20, 21, 22) and 7 KB-only (rows 4, 5, 6, 7, 8, 9, 11).

## Not proposed

| # | Form | Why |
|---|---|---|
| 10 | id-cpns-sscasn | No maximum KB found in an official source |
| 14 | ae-icp-personal-photo | No KB limit at all |
| 15 | bh-iga-id-card | Its own numbers disagree; online upload not confirmed |

Coverage gaps: no usable source for Brazil, Indonesia (beyond CPNS) or the Arabic-speaking countries other than the two above.

## Privacy notes from the sources (not shown in the app)
- Rajshahi University also takes a selfie in its own app for face matching.
- The Indian Embassy Paris guide suggests third-party online photo tools. ExactSize does not link to or endorse them.
