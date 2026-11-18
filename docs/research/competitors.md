---
id: RESEARCH
title: Competitor & Market Research
status: Approved
version: 1.0
updated: 2026-11-18
links: [BRIEF]
---

# Competitor & Market Research

> Filled in Stage 2 (`/research-competitors`). Every claim tagged `[Fact](source)` or `[Hypothesis]`.
> Per-competitor detail lives in `competitors/<slug>.md`.
> Evidence quality: Google Play pages could not be read directly, so Android data comes from third-party trackers (weaker). Web-tool privacy claims are vendor self-claims, not tested. Review evidence is thin.

## Landscape
| Competitor | Type | Platforms | Model | Key strength | Key weakness | Detail |
|---|---|---|---|---|---|---|
| Image Resizer for SSC, Forms | regional (India) | Android | Free, ads only [Fact](https://appgoblin.info/apps/com.forever.optipic) | Exam-named presets, 20/50/100/200 KB targets | Small (16K+ installs); privacy info unknown | [file](competitors/image-resizer-ssc-forms.md) |
| Photo Resizer for Form Fill Up | regional (India) | Android | Ads + IAP [Fact](https://appgoblin.info/apps/com.fairsofttech.photoresizerconverterapp) | About 140K installs; photo + signature + format convert | Installs trend declining (tracker); privacy unknown | [file](competitors/photo-resizer-form-fill-up.md) |
| Compress Photos - Resize Image | direct, generic | iOS | Ads; Pro $2.49/mo or $8.99/yr [Fact](https://apps.apple.com/us/app/-/id6444087511) | On-device, preview, batch | Batch capped at 5 free; ad complaint; no form presets | [file](competitors/compress-photos-resize-image-ios.md) |
| Teamzlab BD Photo and Signature Resizer | regional (Bangladesh) | Web | Free, ads [Fact](https://tool.teamzlab.com/bd/photo-signature-resizer/) | BD defaults, signature clean-up, honest failure message | Web only; max-KB only; no batch | [file](competitors/teamzlab-bd-photo-signature-resizer.md) |
| Imresizer | indirect (web default) | Web | Free, banner ads [Fact](https://imresizer.com/bangladesh-bcs-photo-size) | Country/exam pages, DPI, bulk 12 | Not native/offline; presets unspecified | [file](competitors/imresizer.md) |
| iLoveIMG | indirect (web default) | Web | Free + paid plans [Fact](https://www.iloveimg.com/help/faq) | Brand, 26 languages | No target-KB; uploads files | [file](competitors/iloveimg.md) |
| PhotoAiD | direct (passport/visa) | iOS, Android, web | Pay per photo [Fact](https://www.g2.com/products/photoaid/reviews) | AI compliance checks, 4.5-4.7 ratings | Pricing and privacy complaints; not KB-focused | [file](competitors/photoaid.md) |

Also seen but not profiled: FilePrep (Android; claims target-KB, signature maker, passport maker) [Fact](https://play.google.com/store/apps/details?id=com.oor.fileprep); Exam Photo Resizer & Editor (claims "Exact KB Control", ad-supported) [Fact](https://appgoblin.info/apps/com.apptivize.examphotoresize); "Compress image size in kb" iOS (declares ad tracking; weekly/monthly/yearly subscription, prices inconsistent in listing) [Fact](https://apps.apple.com/us/app/id6742405380).

## Feature comparison
"?" = not stated in sources reviewed.

| Capability | SSC Forms | Form Fill Up | Compress Photos iOS | Teamzlab BD | Imresizer | iLoveIMG | PhotoAiD |
|---|---|---|---|---|---|---|---|
| Hits target KB | Fixed targets listed | Desired KB/MB | Yes (target size) | Max KB, downward only | Max KB | No | ? (not KB-focused) |
| Min-max KB range | ? | ? | ? | No (max only) | Max only | No | ? |
| Processing | ? | ? | On-device (claim) | Browser (claim) | Browser (claim) | Server upload | ? (not stated) |
| Presets | Few (e.g. 300x300) | Templates | No | BD forms | Per-exam pages | No | Visa/ID docs |
| Batch | ? | ? | 5 free, more Pro | No | 12 | Plan-limited | ? |
| Signature tools | Crop | Yes (resize) | No | Yes + clean-up | ? | No | No |
| PDF output | ? | PDF convert listed | ? | No | ? | n/a | ? |
| Languages | ? | ? | EN + ? | EN (Bangla labels) | EN | 26, no Bengali | ? |
Sources: per-competitor files.

## UX patterns worth learning from
- Task-first defaults (photo 300x300 / 100 KB; signature 300x80 / 60 KB) and a visible "cannot reach limit" message instead of an oversize file [Fact](https://tool.teamzlab.com/bd/photo-signature-resizer/).
- Signature clean-up (whiten paper, darken ink) with preview [Fact](https://tool.teamzlab.com/bd/photo-signature-resizer/).
- Free tier capped by batch count with Pro removing ads and cap [Fact](https://apps.apple.com/us/app/-/id6444087511).
- Fill (crop) vs fit modes [Fact](https://imresizer.com/bangladesh-bcs-photo-size).
- Per-form landing pages as the discovery channel (web) [Hypothesis].

## Gaps & opportunities
| # | Gap / opportunity | Evidence | Confidence |
|---|---|---|---|
| 1 | Min-max KB range as a first-class input, with an over-compression guard | Tools reviewed state max-only or fixed targets; official forms set a floor, e.g. photo "between 20kb–50 kb", signature "between 10kb – 20kb" [Fact](https://mstcindia.co.in/MSTC_Careers/ImageDocUploadingSteps.aspx) | Medium |
| 2 | Verifiable on-device privacy plus honest store disclosures | Several apps' privacy info unknown; an ad-supported iOS app claims "no data collected" while another declares tracking; iLoveIMG uploads [Fact](https://apps.apple.com/us/app/id6742405380) | Medium |
| 3 | Signature cleanup + exact size in one native app | Cleanup exists only in the BD web tool among those reviewed [Fact](https://tool.teamzlab.com/bd/photo-signature-resizer/) | Medium |
| 4 | Saved presets + batch for operators | Batch is capped/paywalled where present; no preset-saving seen | Low-Medium |
| 5 | Bangla and other South Asian language UI | iLoveIMG lacks Bengali [Fact](https://www.iloveimg.com/help/faq); others English | Medium |

### Assumption tests
- **A1 (users fail mostly on KB and dimensions, not content): Partly supported.** Guides and tools frame rejection around size, format and dimensions; Imresizer explicitly leaves content rules to the user [Fact](https://imresizer.com/bangladesh-bcs-photo-size). But Bangladeshi circulars also impose content rules (colour photo, taken within three months) [Fact](https://en.prothomalo.com/youth/employment/xjgiumie3g), and PhotoAiD reviews show content/biometric rejections for passports [Fact](https://www.g2.com/products/photoaid/reviews). No quantitative failure data found. Confidence: Low-Medium.
- **A2 (existing tools ad-heavy, inaccurate, or upload): Partly supported.** Ads: SSC Forms is 100% ad-supported per tracker; one iOS review complains of ads; a G2 PicResize reviewer complained of pop-ups [Fact](https://www.g2.com/products/picresize/reviews_and_filters). Upload: iLoveIMG uploads. Counter-evidence: Teamzlab, Imresizer and the iOS app claim local processing (unverified). Accuracy: no evidence found of a tool missing its KB target; claims untested. Confidence: Medium for ads/upload, Low for accuracy.
- **A3 (cyber cafes pay for batch + presets): No direct evidence.** Batch exists (5 free then Pro on iOS; Imresizer 12) but no operator pricing or demand data found. Needs interviews. Confidence: Low.
- **A4 (minimum-KB requirements exist and tools handle them poorly): Requirement supported; tool weakness unproven.** An official recruitment page requires photo 20–50 KB and signature 10–20 KB [Fact](https://mstcindia.co.in/MSTC_Careers/ImageDocUploadingSteps.aspx) (orchestrator-verified; the subagent's original guide source returned HTTP 410 and was replaced). Reviewed tools mostly offer max-only KB. No test of tools on min-KB done (would need hands-on testing). Confidence: Medium for existence, Low for weakness.

## Market notes
- Signature size targets cluster at 10-50 KB; photo at 50-100 KB; dimensions vary per portal [Fact](https://iformat.io/blog/photo-size-guide-10kb-20kb-50kb-100kb) (weaker, blog).
- Pricing norms seen: iOS utilities use subscriptions (monthly/yearly; one lists weekly) [Fact](https://apps.apple.com/us/app/-/id6444087511); a tracker estimates IAP revenue exceeds ads for one India app (estimate, weak) [Fact](https://appgoblin.info/apps/com.fairsofttech.photoresizerconverterapp). No one-time unlock found among those reviewed, so unknown.
- Preset maintenance: all presets observed are sourced from specific circulars and tell users to check their own notice [Fact](https://tool.teamzlab.com/bd/photo-signature-resizer/). How vendors update them is not stated: unknown.
- PDF-under-KB: only one app lists PDF conversion; PDF-under-KB targeting not found. Signature cleanup: seen in one tool only.
- Privacy/compliance: photos and signatures are personal data; ad SDKs add exposure (see BRIEF compliance scope). Do not claim "no data collected" unless the ad SDK is accounted for. Bangladesh Bank rules are not engaged for a size-only app with store billing [Hypothesis].

## Research gaps & open questions
- No hands-on tests: exact-KB accuracy, minimum-KB handling and real ad load of each tool are untested.
- Play Store ratings, reviews and Data Safety were not readable; need manual check (Android is likely the main market).
- No cyber-cafe interviews or pricing evidence (A3).
- No Bangladesh-specific native app found; search was limited, so one may exist.
- Product Owner: one-time vs subscription still open; evidence leans subscription on iOS but is thin.
- Product Owner: is content-compliance (face/background) in scope? PassportPhoto-class tools compete there, at higher cost.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-18 | Skeleton created |
| 0.2 | 2026-11-18 | Stage 2: 7 competitors profiled, matrix, gaps, assumption tests A1-A4 |
| 0.3 | 2026-11-18 | Review: replaced dead min-KB source with an official one; Teamzlab claims spot-checked |
| 1.0 | 2026-11-18 | Approved by Product Owner |
