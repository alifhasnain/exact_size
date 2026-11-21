# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Two primary audiences, weighted equally (Product Owner, 2026-11-21):

- **Applicants:** job seekers (government and private), students (admissions, board and entrance exams, scholarships) and visa or passport applicants. They have one photo and one signature to get accepted by an online form, often on a budget Android phone, often close to a deadline.
- **Cyber café operators:** they fill forms for many customers every day and need speed, reliability and repeatable specs.

Shared job: get an image that the portal accepts on the first upload.

## Product Purpose

ExactSize resizes and compresses a photo or signature on the phone to the exact pixel dimensions, KB range and format an application form demands, in one step with no trial and error. Success means:

- at least 99% of exports land inside the requested dimensions and KB range on the first try;
- the median time from opening the app to an exported file is under 30 s.

Source: `docs/product/vision.md` (BRIEF v1.5); the targets are marked [Assumption] there.

## Positioning

It hits the exact target (W×H px, a min–max KB range and the format) in one step, and the photo never leaves the phone: everything works offline and nothing is uploaded. The KB search runs on the device and respects both the floor and the ceiling of the range. Many tools only honour a maximum, or upload the image to a server (`docs/research/competitors.md`, gaps 1 and 2).

## Operating Context

- **Typical sequence:** read the form's notice, pick the image (camera or gallery), enter the target or pick a preset, crop to the locked ratio, compress, check the result against the spec, then export or share into the portal's upload picker.
- **Images:** photos and signatures, often taken on the phone. Signatures are identity-sensitive.
- **Connectivity:** often poor, so every core flow works offline.
- **Specs:** they come from form notices and change over time, so presets show their source and when they were last checked, and they tell the user to check their own notice (FEAT-014).

## Capabilities and Constraints

- Android first, minimum Android 9 (API 28), built with Flutter 3.50.x, Riverpod and get_it + injectable. Image codecs are native C through Dart FFI (ADR-001, ADR-002). iOS is later, possibly much later: keep the code iOS-ready but plan no iOS work.
- On-device only: no backend, no accounts, no network in the image pipeline. The original image is opened read-only. Image content, paths and EXIF values are never logged.
- The first release ships in 6 languages: English, Spanish (es-419), Portuguese (pt-BR), Hindi, Indonesian, and Arabic in Modern Standard Arabic with RTL and Western digits. Translations are AI-reviewed only.
- Business model: a free core with ads shown after valid consent, and a yearly subscription that removes ads and unlocks extras. Payment goes only through Play in-app purchase, so the app handles no payment data. Prices per region are undecided.
- Built-in preset library (about 15–20 forms), saved custom presets, JPEG and PNG output.
- Out of scope: cloud processing, accounts, sync, AI editing, submitting forms for the user, general photo editing, PDF output.
- **Terms:**
  - *target*: W×H, a KB min–max and a format;
  - *preset*: a stored target;
  - *crop*: framing at the locked W:H ratio;
  - *enlargement / upscale*: output larger than the cropped source pixels.
- **Undecided:** the final product name, and prices per region.

## Brand Commitments

- **Name:** "ExactSize" is a working name and may change. There is no logo, icon or colour yet; none should be invented as binding.
- **Voice:** plain and calm. Short, plain words with no jargon, reassuring when something fails. Each error gives one message and one next action. Plain wording also keeps the AI-only translations safer.
- Never claim "native-quality" translations or "no data collected" while ads ship.

## Evidence on Hand

- Product and feature docs: `docs/product/vision.md`, `docs/roadmap.md`, `docs/research/competitors.md`, `docs/features/*/prd.md`.
- English UI strings: `lib/l10n/app_en.arb`.
- Crop screen design checklist (gate G3): `docs/features/FEAT-002-crop-resize/t22/crop_screen_checklist.md`.
- There are no testimonials, ratings, user counts, press or benchmarks. Never fabricate them. Design files use synthetic images only, never real faces or signatures.

## Product Principles

1. **Exact or honest:** never export a file outside the spec in silence. If the target can't be reached, say so and offer a next step.
2. **The photo stays on the phone:** privacy is the product, not a setting.
3. **Done in seconds:** every screen serves the under-30-second path. Extras stay out of the way.
4. **Works for everyone in the room:** the applicant on a cheap phone and the operator doing their fiftieth job of the day both finish without help.
5. **Plain words in six languages:** if a phrase is hard to translate, rewrite it.

## Accessibility & Inclusion

- WCAG AA contrast, including overlays drawn on any photo. Nothing is shown by colour alone: notices carry an icon and text.
- Every gesture has a non-gesture equivalent. TalkBack has custom actions and announces state changes through a polite live region.
- Touch targets are at least 48 dp. Text scales to 200%.
- Full RTL for Arabic. Photo content and physical directions stay unmirrored; for example, "Move left" always moves left.
- Low-end devices with 2 GB of RAM are a target (tested on the API 28 emulator).
