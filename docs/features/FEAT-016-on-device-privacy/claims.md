---
id: FEAT-016-CLAIMS
title: ExactSize privacy claims register, data inventory and release checklist
status: Proposed
version: 0.2
updated: 2026-11-27
links: [FEAT-016, FEAT-016-TECH, FEAT-016-TASKS, FEAT-007, FEAT-011, FEAT-013, FEAT-025, FEAT-027]
---

# Privacy claims register and release checklist (FEAT-016)

This is the living copy of FEAT-016 PRD section 10 (PRD OQ-8 default). Every user-facing privacy sentence and every store statement maps to a claim ID here (NFR-7). Change it only through the change procedure in section 4. The build gates point here: `checkMergedManifest`, `checkReviewedDependencies` and `test/privacy/*`.

## 1. Claims register

Check types:
- **code test:** fails `flutter test` or the release build.
- **manifest check:** `checkMergedManifest`.
- **manual checklist:** section 6, run per release candidate.
- **disclosure only:** true by nature; nothing to test.

| ID | Plain claim | Check | Ad-free build | Build with ads (FEAT-025) | With preset updates (FEAT-013) | Check type | Explainer / app keys |
|---|---|---|---|---|---|---|---|
| C1 | ExactSize never uploads your photos or signatures | FR-9 scan; FR-8 manifest; FR-19 for later code | True | True for ExactSize code; the SDK is not provable (flag 3) | True if the fetch carries no user data | code test + manifest check | pickPrivacyNote, privacyOnPhone |
| C2 | Every core step works without internet | FR-14 matrix; FR-16 | True | True; ads do not load | True; bundled presets remain | manual checklist (FR-14) + code test (FR-16) | privacyOffline |
| C3 | No account or sign-in | FR-10 dependency list; no sign-in code | True | True | True | code test (FR-10 lists; no sign-in code) | privacyOnPhone |
| C4 | Temporary copies are deleted when you finish, or at the next start | Start-up sweeps in `lib/main.dart` [Fact](lib/main.dart); temp-file tests | True | True | True | code test (temp-file and sweep tests) | privacyKept |
| C5 | Logs hold only short status codes | Enum-only wrappers; per-feature privacy tests; FR-18 | True for ExactSize code | SDK logs excluded; say "ExactSize's logs" | True | code test (enum-only wrappers, FR-18 test) | privacyKept |
| C6 | ExactSize has no permission to use the internet (internal and store-form use only, not in the explainer) | FR-8 | True | False | False | manifest check (FR-8) | (internal and store form only) |
| C7 | ExactSize collects no data (store label only after OQ-7) | Data inventory below | Reading to confirm | False; use SDK disclosure | Reading to confirm | manual checklist (inventory, OQ-7) | (store label only, after OQ-7) |
| C8 | Saved and shared copies leave ExactSize's control | Disclosure only | True | True | True | disclosure only | privacyCopies, exportPrivacy |
| C9 | Gallery, keyboard and receiving apps follow their own rules | Disclosure only | True | True | True | disclosure only | privacyOutside |
| C10 | ExactSize reads only the photo you choose | Manifest bans CAMERA, READ_EXTERNAL_STORAGE, READ_MEDIA_* [Fact](android/app/build.gradle.kts); FEAT-007 FR-8 on API 28 | True | True | True | manifest check + code (FEAT-007 FR-8) | privacyReads |

Every `privacy*` explainer key names its claim IDs in its `@description` in `lib/l10n/app_en.arb`. `test/privacy/privacy_copy_test.dart` checks this.

## 2. Data inventory (Google Play Data safety input)

This is the ad-free build. When FEAT-025 ships, the ads column is filled from the SDK vendor's published disclosure for the pinned version ([PLACEHOLDER]).

| Data type (Play category) | Touched | Leaves the device through ExactSize | Note |
|---|---|---|---|
| Photos and videos | Yes, the chosen photo or signature | No | In memory plus app cache; Save and Share are user actions. How Play treats a user-initiated share through the system chooser is unconfirmed (OQ-7) |
| Files and docs | Yes, via the document picker | No | Same |
| Location | No | No | EXIF GPS is not read; the re-encode carries no source metadata [Fact](docs/features/FEAT-007-export-share/prd.md, section 9, FEAT-004 FR-2). No "location removed" claim until FEAT-018 is verified |
| Personal info, financial info | No | No | Purchases are handled by Google Play (FEAT-026) |
| App activity, app info and performance | No SDK; nothing sent by the app | No | Platform crash data: OQ-7 |
| Device or other IDs | None | No | With ads: advertising ID [PLACEHOLDER per SDK] |
| Permissions declared | `WRITE_EXTERNAL_STORAGE`, API 28 only | n/a | Disclosure text is FEAT-007's input [Fact](docs/roadmap.md, FEAT-007 row) |
| Account, deletion request | No accounts | n/a | Nothing off-device to delete |

## 3. Permissions (release APK)

This table mirrors the reviewed allow-list in `android/app/build.gradle.kts` (`checkMergedManifest`). It was checked with `aapt2 dump permissions` on the release APK on 2026-11-26 (FEAT-016-T01 H3).

| Permission | Why | Since |
|---|---|---|
| `android.permission.WRITE_EXTERNAL_STORAGE` (`maxSdkVersion` 28) | Save to the gallery on Android 9 only (FEAT-007 FR-8) | FEAT-007 |
| `com.exactsize.exact_size.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | Declared by `androidx.core` for the app's own non-exported receivers; no user-visible effect | FEAT-007 |

The release APK has no INTERNET, network-state, Wi-Fi-state or advertising-ID permission.

**Backup:** `allowBackup="false"`, and `dataExtractionRules` excludes all app data from cloud backup and device transfer (FR-17).

**Reviewed dependency lists:**
- `android/app/reviewed_dependencies.txt`: Gradle modules, checked by the release build.
- `tool/privacy/reviewed_packages.txt`: Dart packages, checked by `flutter test`.

## 4. Change procedure (FR-12)

A change that adds any of the following must complete the steps below in the same change:
- the INTERNET permission;
- a third-party SDK;
- an app-initiated network call;
- new data collection;
- a new way a photo leaves the phone.

Steps:
- [ ] Update the claims register (section 1) and the data inventory (section 2). Update the permission table (section 3) if a permission changes.
- [ ] Update the explainer parts and their translations through `/l10n-translate` (status `AI-reviewed only`), or block the release until they are done.
- [ ] Change the FEAT-016 PRD through its change log, with the Product Owner's approval.
- [ ] Record the decision in `docs/product/decisions.md`.
- [ ] Only then widen a gate. A gate is widened by:
  - an entry on the permission allow-list;
  - a reviewed-list entry with its note;
  - an exempt path in the source scan. The exempt list is empty in R1, and each entry also goes into the PRD change log.

Source (PRD FR-12): Change procedure: a change that adds INTERNET, a third-party SDK, an app-initiated network call, new data collection or a new way a photo leaves the phone shall, in the same change: update the claims register and data inventory; update the explainer parts and their translations (or block the release); change this PRD through its change log with Product Owner approval; and record the decision. Gate failure messages shall point here.

## 5. Offline matrix (FR-14)

Run once per release candidate, on a real phone, with a release build.

Offline means **airplane mode on, Wi-Fi off and mobile data off**. Check it first with `adb shell ping -c 1 -W 2 1.1.1.1`, which must answer "Network is unreachable". On the Realme 2 Pro, Wi-Fi stays connected in airplane mode (FEAT-016-T10 Test record), so airplane mode alone is not offline there.

| Row | Expected | Date | Device / build | Result |
|---|---|---|---|---|
| Cold start | Pick screen, no network wait | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass |
| Pick: system photo picker, local photo | Target screen | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Picker opened offline and returned (CANCELLED). Not selected: the newest picker item was not the synthetic photo, so nothing of the owner's was opened; the same accept path is covered by the files and share-in rows |
| Pick: camera | Target screen | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Camera app opened offline, cancelled with Back, no capture (a capture would show the room); returns to the pick screen |
| Pick: Choose from files | Target screen | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass (synthetic file chosen by its name only) |
| Pick: share-in | Target screen | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass |
| Target entry | Values accepted | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass |
| Pick a preset | Open the form list, search, pick a spec, Continue: works with no delay and no network message (FEAT-011) | | | Filled by FEAT-011-T14 |
| Crop | Continue works | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass |
| Compress | Result reached | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass |
| Check | Verdict shown | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass (Matches your target) |
| Save | Saved message | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass |
| Share | System chooser opens (what the receiving app does is its own business) | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass (chooser opened, cancelled, no screenshot) |
| Explainer | Opens at once, no spinner, no error | 2026-11-27 | Realme 2 Pro, API 36, release (debug-signed) | Pass |

## 6. Release checklist (FR-13)

Before each store submission:

- [ ] `aapt2 dump permissions` on the release APK matches section 3.
- [ ] Both gate markers exist after the release build (`build/app/outputs/privacy/*.ok`). CI asserts them.
- [ ] The offline matrix (section 5) passes on a real phone.
- [ ] The register (section 1) agrees with the explainer, the store listing text in six languages and the Data safety answers. Nothing in the listing claims more than the register.
- [ ] The privacy policy URL is set in the store listing: [PLACEHOLDER].
- [ ] All six languages are `AI-reviewed only` in `docs/l10n/ai-review-log.md`, and none is described as native-reviewed.
- [ ] The combined compliance review (PRD OQ-7) is done, or the Product Owner's waiver is recorded. Until then, there is no "no data collected" claim.
- [ ] A release signing key is configured. Today `android/app/build.gradle.kts` signs release builds with the debug key.
- [ ] Preset library: `dart run tool/presets/freshness.dart`; 15–20 forms; each form older than 90 days accepted or fixed in the release record; no test entries; FEAT-014 display shipped (FEAT-011 FR-1, FR-21, release rule).

## 7. Carried requirements (FR-19)

These are copied verbatim from the FEAT-016 PRD. Each owner copies its part into its own PRD at `/draft-prd`, and the product-analyst brief for those PRDs reads this section (tech OQ-T3).

| Owner | Requirement | Status |
|---|---|---|
| FEAT-025 (ads) | **(a) FEAT-025 ads:** ad code lives in one allow-listed folder (FR-9); no ad request before valid consent; the ad slot collapses when offline and no core step waits on the ad or consent network; no ad view on a screen that shows photo pixels (crop, check, result) [Assumption: placement is FEAT-025's decision]; the SDK receives no image, URI, path, name or measured value; the register, inventory and explainer ads part change in the same change (placeholder text: "This app shows ads from [AD_NETWORK_PLACEHOLDER]. Ads may use your device's advertising ID [PLACEHOLDER per SDK disclosure]. ExactSize never gives ads your photos."); Data safety follows the pinned SDK vendor's disclosure. | To copy into owning PRD at /draft-prd |
| FEAT-013 (preset updates) | **(b) FEAT-013 presets:** the fetch sends no user data, device identifier or query parameter; the file is signed and verified; failure offline is silent and bundled presets stay usable; one allow-listed folder; the explainer states what is fetched and from where; the label is updated [Fact](docs/roadmap.md, FEAT-013 row). | To copy into owning PRD at /draft-prd |
| FEAT-027 (counters) | **(c) FEAT-027 counters:** local-only or opt-in, listed in the explainer, never counting explainer opens. | To copy into owning PRD at /draft-prd |

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-27 | First version, from PRD 1.0 section 10 (FEAT-016-T11) |
| 0.2 | 2026-11-27 | Offline row "Pick a preset" and the preset library release check (FEAT-011-T06) |
