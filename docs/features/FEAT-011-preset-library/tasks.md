---
id: FEAT-011-TASKS
title: Built-in preset library — Implementation Tasks
status: Approved
version: 2.0
updated: 2026-11-27
links: [FEAT-011, FEAT-011-TECH, ADR-001, FEAT-005, FEAT-002, FEAT-004, FEAT-014, FEAT-016, FEAT-019]
---

# FEAT-011 — Implementation Tasks

Milestone: R1 Phase A (MVP, Must). Work top to bottom, one task at a time.

Sizes: **S** ≈ 0.25 day, **M** ≈ 0.5 day, **L** ≈ 1 day; each task is one PR.
Module paths follow tech section 3: new `lib/features/presets/{domain,data,presentation}`, `assets/presets/presets.json`, `test/features/presets/`, `test/presets/` (CI rules and fixtures), `integration_test/preset_fixture_run.dart`, `tool/presets/freshness.dart`; changed `lib/features/target/presentation/target_screen.dart`, `pubspec.yaml` (one asset line), `lib/l10n/app_*.arb`, `integration_test/bundle.dart` (one import), `docs/features/FEAT-016-on-device-privacy/claims.md` (sections 5 and 6), `docs/CHANGELOG.md` (one convention note).
**Revision 2.0 (PRD 2.0, tech 2.0: KB-only specs):** T01–T14 stay as built; T15 is rescoped; T16–T21 are new. Files from tech 2.0 "Changes in the built code": `preset_types.dart`, `parse_library.dart`, `preset_row.dart`, `preset_strings.dart`, `lib/l10n/app_*.arb` (two keys), `test/presets/library_rules.dart`, `test/presets/fixtures/test_library.json`, `integration_test/preset_fixture_data.dart`, `integration_test/preset_fixture_run.dart`, `integration_test/preset_demo.dart` (one line), and the count-ripple tests. `TargetSpec`, `TargetInput`, `TargetFormController`, `target_screen.dart`, `PresetListScreen`, search, providers and loader have no diff.

**Already built, reused, not planned again:** `TargetFormController.fill`, `targetFormProvider`, `validateTargetInput`, `cleanNumberText` (FEAT-005); `checkTarget`, `validateTarget`, `CropRenderer`, `SourceProbe`, `CompressionRunner` and the `crop_to_compression.dart` call sequence (FEAT-002, FEAT-004); the `LogSink` typedef and enum-only log pattern; the `_iso` / `_ltr` isolate helpers; `BoothNotice` note style; FEAT-016 whole-tree scan, `privacy_copy_test.dart`, reviewed package and dependency lists, `claims.md`; the CI `build` and API 28 `emulator` jobs running `integration_test/bundle.dart`; gen-l10n with 6 languages.

**Decisions used (PRD 1.0, open questions at defaults; tech 1.0, OQ-T1..T3 at defaults):**
- PRD OQ-1: the form list is **not** a build blocker. Everything is built and tested with synthetic fixtures (`test/presets/fixtures/test_library.json`, "Test Form A/B", country `ZZ`, a second user-assigned code such as `XY` only where a test needs two sections). The shipped asset stays `{"schema": 1, "forms": []}` until T15.
- OQ-T1: the row is hidden when the library has zero forms (FEAT-005 alone); the load-failure message is only for a real load error.
- OQ-T2: fixture images are generated at test time with `dart:ui`; no binary committed.
- OQ-T3: banned words are checked in UI strings and `aliases`, not in published names, issuers or source titles.
- PRD OQ-2 form with 1–2 spec rows; OQ-3 no KB-only presets; OQ-6 search Should (first cut if the budget slips: T07 and the search part of T10, about 0.75 d); OQ-7 label back to "Choose a form" after an edit; OQ-8 pick replaces silently; OQ-9 no FEAT-006 change; OQ-11 applied preset beside `TargetSpec`; OQ-13 URL stored as text, not shown; OQ-14 90 days.
- **2.0:** PRD OQ-3 decided: KB-only specs allowed (FR-3, FR-11, FR-13, FR-26); the "OQ-3 no KB-only presets" default above no longer applies. PRD FR-1: Claude may draft researched candidates (`t15/`), only rows the Product Owner confirmed enter the asset. Tech OQ-T5 default: Width and Height are kept on a KB-only pick. No new ADR.

**Test devices:**
- **Local device runs and screenshots use the connected real phone, Realme 2 Pro, API 36.** Run `adb devices` first. The local emulator (Medium_Phone_API_36.1) is used only if `adb devices` already shows it; never start a second one, never kill it.
- **API 28 runs only in CI.** CI costs about 80 min per push to `main`: commit after each task, push only at milestones. Planned pushes: **P1** after T08 (CI data rules, copy test, first FR-20 fixture run on API 28), **P2** in T14 after T13, before G-final. **P2b** (2.0) in T21 after gate G3: KB-only code, both-or-neither CI rule and the FR-20 run of Test Form C on API 28; the only push for T16–T21. **P3** in T15 when the Product Owner's real forms land (FR-20 on real specs). Run `flutter analyze` and `flutter test` locally before each push.
- Device runs that need forms in the list use a **local, uncommitted** copy of the fixture library over `assets/presets/presets.json`; `git diff --exit-code assets/presets/presets.json` must pass before every commit.
- Files run under `flutter drive` use `testWidgets` only.

## Decision gates
| Gate | Task | Passes when | If it fails / what it blocks |
|---|---|---|---|
| G1 Design (FR-25) | T09 | The Product Owner was told before any visual work; one lean impeccable pass on Material 3 and the existing theme (no image comps, no reviewer subagents, one round) covers the target-step row (choose, applied with notes, load failure, hidden when empty) and the list (search, sections, spec rows, notes, empty state, footer); the T03 English copy accepted or fixes named; reference and date recorded | **Blocks T10, T11, T12** (all list and row UI). T01–T08 (data, loader, strings, CI rules, copy test, freshness, search, fixture run) do not wait on it |
| G2 Accessibility, RTL, 200% | T12 | Guideline, 200% and RTL tests pass in en, ar and hi; the Product Owner has seen one Realme 2 Pro screenshot per key state and accepts them or names fixes. One look | **Blocks T13** (strings final before translation) **and T14**. Fixes go into T10/T11 code inside T12; a scope change means a PRD change |
| G3 KB-only UI (2.0, FR-25, FR-26) | notice before T17; acceptance in T21 | **Before T17 starts** the Product Owner is told that two small visual changes on existing components follow ("Any pixel size" in the list-row summary, the FR-26 line under the target-step row) and that a lean check replaces a new impeccable pass (both reuse the G1 summary line and `BoothNotice`). **In T21:** the 200% and RTL tests pass with Test Form C; the Product Owner has seen one Realme 2 Pro screenshot per KB-only state and accepts them or names fixes. One look | **Blocks the P2b push and T15.** Fixes go into T20 code inside T21; a wording change re-runs `/l10n-translate` for that key. If the Product Owner wants a full impeccable pass instead, it replaces T21's look (about +0.5 d) |
| G-final Build (device and CI) | T14 (+ T21 for 2.0) | Real-phone offline run passes (release build, airplane mode plus Wi-Fi and mobile data off); no preset survives a restart; logcat holds enum lines only; release APK permissions and reviewed lists unchanged; FEAT-016 `claims.md` row recorded; P2 CI green; **2.0: G3 accepted and P2b CI green**; the Product Owner accepts the Open items. The T14 offline evidence stands for 2.0, which adds no network, storage, log, permission or dependency code [Assumption]; the Product Owner may ask for a re-run | A network use, a privacy leak, a crash or an accessibility miss means stop and report. Otherwise the build is done. **G-final does not depend on T15**; T14 stays unticked until it passes |
| Release (not a build gate) | T15 + others | T15 done with 15–20 Product Owner-confirmed forms and P3 green; FEAT-014 display shipped; OQ-5 legal advice taken; the FEAT-016 release checklist preset line passes | The preset list is not released. Whether `/approve FEAT-011 implemented` waits for T15 is the Product Owner's call (Open items 1) |

## Tasks

### - [x] FEAT-011-T01 — Domain types, `parseLibrary`, synthetic fixture library
- **Implements:** FR-2, FR-3, FR-4, FR-12 (types), FR-16 (spec skip), NFR-6, NFR-7 · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** M (0.5 d)
- **Scope:** `lib/features/presets/domain/preset_types.dart` (`PresetForm`, `PresetSpec` with `target` and `input`, `PresetSource`, sealed `NotCovered` → `DpiNote`/`BackgroundNote`/`ContentNote`, `SpecKind`, `FormCategory`, `PresetLibrary`, `AppliedPreset` with redacted `toString`); `parse_library.dart` with the runtime rules of tech section 5; `test/presets/fixtures/test_library.json` (Test Form A: photo 200×230, 20–50 KB, JPEG, notes `dpi` 200 + `background`, signature with `minKb` null; Test Form B: one spec with a `content` note; `source.url` `[PLACEHOLDER]`; all values made up). No `package:flutter`, Riverpod or DI import under `domain/`.
- **Done when:** `flutter test test/features/presets/parse_library_test.dart` passes with table cases: fixture parses to 2 forms; width 0, unknown kind, unknown format, unknown note code and a repeated kind each skip only that spec and count it; a form with no valid spec is dropped; a root without `schema: 1` or `forms` throws `FormatException`; an unknown field is ignored; `minKb: null` gives `input.minKb == ''`; `spec.target` equals the `TargetSpec` from manual entry of the same values; `AppliedPreset.toString()` holds no form id. `FEAT-005` `TargetSpec`/`TargetInput` files have no diff.

### - [x] FEAT-011-T02 — Asset source, empty shipped asset, providers, enum log
- **Implements:** FR-1 (shipped file), FR-12 (state), FR-16 (log, error path), FR-17, FR-18, NFR-5 · **ADRs:** ADR-001
- **Depends on:** T01
- **Size:** M (0.5 d)
- **Scope:** `assets/presets/presets.json` = `{"schema": 1, "forms": []}`; `pubspec.yaml` one asset entry; `lib/features/presets/data/preset_asset_source.dart` (`loadPresets()`, `LogSink` constructor parameter with `debugPrint` default); `lib/features/presets/presentation/preset_providers.dart` (beside the screens, as `targetFormProvider` sits in `target/presentation/`) (`presetLibraryProvider` kept alive, `appliedPresetProvider` not auto-disposed, no restoration). Log lines exactly `exactsize.presets outcome=LOAD_FAILED` and `exactsize.presets outcome=SPEC_SKIPPED`.
- **Done when:** `flutter test test/features/presets/preset_asset_source_test.dart` passes: corrupt JSON gives an `AsyncError` and exactly one `LOAD_FAILED` line; the fixture plus one bad spec gives exactly one `SPEC_SKIPPED` line; no line contains a form id, name, count or exception text; the shipped asset loads with 0 forms; a fresh `ProviderContainer` has `appliedPresetProvider == null` (AC-8.1). `flutter test test/privacy/` passes (whole-tree scan covers the new folder); `git diff --stat tool/privacy/reviewed_packages.txt android/app/reviewed_dependencies.txt` is empty.

### - [x] FEAT-011-T03 — English strings and `preset_strings.dart`
- **Implements:** FR-23 (English), FR-6 (summary), FR-14 (keyed notes), FR-15 (footer), FR-24, NFR-4 · **ADRs:** ADR-001
- **Depends on:** T01
- **Size:** S (0.25 d)
- **Scope:** `lib/l10n/app_en.arb` only: the `preset*` keys of tech section 6 with "FEAT-011 ..." `@` descriptions and placeholders (`presetCountry` with only `other{{code}}` until T15, never a `ZZ` case; `presetCategory` with the four cases). `lib/features/presets/presentation/preset_strings.dart`: code → getter mapping, FSI/PDI around data names, LRI/PDI around numbers with units, digits 0–9. The five other ARBs are untouched until T13 (Open items 5).
- **Done when:** `flutter gen-l10n` passes; `flutter test test/features/presets/preset_strings_test.dart` passes (summary with and without minimum, DPI note with 200, form name wrapped in U+2068/U+2069, "px"/"KB" in an LTR isolate, four category labels, unknown country shows its code); `flutter test test/privacy/privacy_copy_test.dart` still passes (no connectivity word in a new key). Final wording may change at G1.

### - [x] FEAT-011-T04 — CI data rules and self-tests (FR-19)
- **Implements:** FR-19, FR-1 (no test entries shipped), FR-2, FR-3, FR-4, NFR-6, NFR-10 · **ADRs:** —
- **Depends on:** T01, T03
- **Size:** M (0.5 d)
- **Scope:** `test/presets/library_rules.dart` (CI-only rules of tech section 5: unknown fields, slug and duplicate ids, 16 px floor, `dpi` 1–1200, issuer and source title, `lastChecked` `YYYY-MM-DD` not after today, country and category present as `select` cases, no `test-` id or "Test Form" name in the shipped file); `test/presets/library_data_test.dart` runs them on `assets/presets/presets.json`. Messages are the PRD section 8 texts with id and kind filled in. Rule self-tests pass their own key set (so `ZZ` never needs an ARB case).
- **Done when:** `flutter test test/presets/library_data_test.dart` passes on the shipped file; self-tests fail as expected and name form id, kind and rule for: width 0, min 10 with max 5, width 15 px (AC-7.1); missing source title, missing `lastChecked`, a future date (AC-7.2); duplicate id (AC-7.3); unknown field; non-slug id; `dpi` 0 and 1201; repeated note; country without a key; a `test-` id in the shipped file.

### - [x] FEAT-011-T05 — Copy and storage test (banned words, AC-8.2)
- **Implements:** FR-15 (test), FR-17, NFR-5, AC-8.2 · **ADRs:** —
- **Depends on:** T03
- **Size:** M (0.5 d)
- **Scope:** `test/presets/preset_copy_test.dart`: "official", "approved", "guaranteed" (case-insensitive) banned in every `preset*` value in `app_en.arb`, as Latin tokens in all 6 ARBs, and in `aliases` of the shipped file; every `preset*` key has an `@` description starting "FEAT-011"; scan of `lib/features/presets/` for `dart:io`, `path_provider`, `shared_preferences`, `restorationId`, `PageStorageKey`, `Clipboard`. The presence-in-6-locales check is added in T13.
- **Done when:** passes on the tree; a planted "official" in a scratch copy of the English map, a planted alias, a missing description and a scratch file with `PageStorageKey` each fail with a message naming the key or `file:line`.

### - [x] FEAT-011-T06 — Freshness tool, FEAT-016 `claims.md` lines, CHANGELOG convention
- **Implements:** FR-21, FR-22 (convention note), FR-1 (count at release), NFR-3 · **ADRs:** —
- **Depends on:** T01
- **Size:** S (0.25 d)
- **Scope:** `tool/presets/freshness.dart` (`--today YYYY-MM-DD` optional, default today; prints `forms: N` and one `<id> <lastChecked>` line per form older than 90 days) with `test/presets/freshness_test.dart`. FEAT-016 `claims.md` (plus one line in its Change log): section 5 offline matrix, new row "Pick a preset" right after "Target entry" (open list, search, pick, Continue; expected: works with no delay or network message; result filled by T14); section 6 release checklist line "Preset library: `dart run tool/presets/freshness.dart`; 15–20 forms; each form older than 90 days accepted or fixed in the release record; no test entries; FEAT-014 display shipped (FEAT-011 FR-1, FR-21, release rule)". `docs/CHANGELOG.md`: one convention note "Preset data changes: one line per form with form id, source title and check date (FEAT-011 FR-22, checked at PR review)".
- **Done when:** `dart run tool/presets/freshness.dart` prints `forms: 0` on the shipped file; the test with the fixture and `--today 2027-03-01` lists Test Form A only; both `claims.md` lines and the CHANGELOG note are in the PR; `flutter test test/privacy/` still passes.

### - [x] FEAT-011-T07 — Search key, filter, grouping and fuzz test
- **Implements:** FR-8, FR-6 (grouping and sort), NFR-1 (search), NFR-7, NFR-8 · **ADRs:** ADR-001
- **Depends on:** T01
- **Size:** M (0.5 d)
- **Scope:** `lib/features/presets/domain/preset_search.dart` (`searchKey`: cut to 100, `cleanNumberText`, lowercase, small diacritic fold for Latin and Arabic harakat; `filterForms`: substring over name, issuer, aliases, localized country and category; sections by localized country name, forms by name).
- **Done when:** `flutter test test/features/presets/preset_search_test.dart` passes: "TEST form a", extra spaces, U+200F marks and Arabic-Indic digits all match Test Form A (AC-2.2); alias, issuer, country name and category label each match (AC-2.1); section and form order stable; empty query returns all; a 101-character query is cut; 1,000 seeded random strings (lone surrogates, controls, mixed scripts) and a 10,000-character paste never throw; filtering the fixture 1,000 times takes under 100 ms per call on the host (informational).

### - [x] FEAT-011-T08 — FR-20 fixture engine run in CI and push P1
- **Implements:** FR-20, NFR-1 (load time), NFR-9 · **ADRs:** ADR-001
- **Depends on:** T02, T04, T05, T06, T07
- **Size:** L (1.0 d)
- **Scope:** `integration_test/preset_fixture_run.dart` (`testWidgets` only), imported by `integration_test/bundle.dart`. Generates one textured photo-like and one stroke-on-white signature-like image with `dart:ui` into the app support dir; for every spec it probes, renders the default crop at W×H and compresses with the KB range and format (same calls as `crop_to_compression.dart`); a size, KB or "can't reach" outcome fails unless `engineReview` is non-empty. It runs the shipped asset via `loadPresets()` and an inline synthetic library with the same values as `test/presets/fixtures/test_library.json` (files under `test/` are not on the device), plus one planted unreachable spec (for example 4000×4000 px, max 2 KB) that must be reported, and must pass once given an `engineReview`. Records library load time (NFR-1, informational).
- **Done when:** the module passes locally on the Realme 2 Pro (build uninstalled after); `flutter analyze` and `flutter test` pass locally; **P1** CI is green with the fixture run in the API 28 emulator job; the extra emulator-job time against the last green run is recorded in the Test record (tech hypothesis 1–3 min).

### - [x] FEAT-011-T09 — impeccable design pass with the Product Owner — gate G1
- **Implements:** FR-25, FR-5, FR-6, FR-14 (design) · **ADRs:** —
- **Depends on:** T03 (English copy to review)
- **Size:** M (0.5 d)
- **Scope:** stop and tell the Product Owner first. One lean impeccable pass on Material 3 and the existing theme, jointly with the FEAT-005 preset slot: target-step row in its states (choose, applied with notes, load failure; hidden when empty), list screen (search, section headings, form with 1–2 spec rows, notes with icon, empty state with "Enter sizes yourself", not-affiliated footer). No image comps, no reviewer subagents, one round. Result in `docs/features/FEAT-011-preset-library/t09/preset_design.md`; accepted copy fixes go into `app_en.arb` in this task.
- **Done when:** the design note exists with date and the Product Owner's acceptance (or named fixes) recorded in the Test record as G1.

### - [x] FEAT-011-T10 — Preset list screen
- **Implements:** FR-6, FR-7, FR-8 (UI), FR-9, FR-10, FR-14 (list rows), FR-15 (footer), FR-16 (skipped spec), NFR-8 · **ADRs:** ADR-001
- **Depends on:** T09 (G1), T07
- **Size:** L (1.0 d)
- **Scope:** `lib/features/presets/presentation/preset_list_screen.dart`: search field (`autocorrect: false`, `enableSuggestions: false`, `enableIMEPersonalizedLearning: false`, no autofill, `LengthLimitingTextInputFormatter(100)`, controller in State, disposed on pop, no `PageStorageKey`); lazy sectioned list; one tappable row per spec popping `PresetPick`; notes as icon plus text; empty state popping `null`; footer. Pushed with `Navigator.push(MaterialPageRoute)`.
- **Done when:** `flutter test test/features/presets/preset_list_screen_test.dart` passes with the fixture: sections with headings and spec rows (AC-1.2); single-spec tap pops its `PresetPick` (AC-1.3); two rows for Test Form A (AC-3.1) and no invented row for Test Form B (AC-3.3); filtering per keystroke (AC-2.1); empty state and "Enter sizes yourself" pops `null` (AC-2.3); the three keyboard flags asserted on the `TextField` (AC-2.4); DPI, background and content notes show with an icon (AC-5.1, AC-5.2); a skipped spec is absent and nothing throws (AC-6.2); a 10,000-character paste is cut to 100 with no exception; footer present. `flutter test test/privacy/` and T05 pass.

### - [x] FEAT-011-T11 — Target-step row and wiring
- **Implements:** FR-5, FR-11, FR-12, FR-13, FR-14 (while applied), FR-16 (message), FR-17, NFR-5 · **ADRs:** ADR-001
- **Depends on:** T10, T02
- **Size:** M (0.5 d)
- **Scope:** `lib/features/presets/presentation/preset_row.dart` and its slot in `target_screen.dart` (the reserved place below the photo line): "Choose a form" / "<form> · <kind>" derived from `state.result is TargetInputValid(:spec) && spec == preset.target`; load-failure message (non-tappable) on `AsyncError`; hidden for zero forms (OQ-T1); notes while applied; on pick: `fill(spec.input)`, copy into the four `TextEditingController`s as `_usePhotoSize` does, set `appliedPresetProvider`, unfocus.
- **Done when:** `flutter test test/features/presets/preset_row_test.dart` passes: row plus five usable fields (AC-1.1); load failure shows the message and manual entry works (AC-6.1); zero forms hides the row; typed Width 300 then pick Test Form A photo shows 200/230/20/50/JPEG with the keyboard closed (AC-4.1); no minimum leaves Minimum empty (AC-4.2); label "Test Form A · Photo" (AC-4.3); edit one value → "Choose a form", set it back (also as Arabic-Indic digits) → label returns (AC-4.4); Continue hands over the same `TargetSpec` as manual entry (AC-4.5); upscale notice as for manual (AC-4.6); notes shown while applied and nothing blocked (AC-5.1–5.3); Back from the list leaves values unchanged (AC-1.4); photo then signature pick switches values (AC-3.2). All existing FEAT-005 target tests pass unchanged; `flutter test test/privacy/` passes.

### - [x] FEAT-011-T12 — Accessibility, 200% font, RTL, screenshots — gate G2
- **Implements:** FR-24, NFR-1 (open time), NFR-2, NFR-7, NFR-8 (configuration changes), FR-14 (a11y) · **ADRs:** —
- **Depends on:** T11
- **Size:** L (1.0 d)
- **Scope:** `test/features/presets/preset_a11y_test.dart`: tap-target, labelled-target and text-contrast guidelines on the row and the list; en, ar and hi at 200% on 360×640 dp: no overflow, no horizontal scroll, every spec row reachable (AC-9.2); ar mirrored, data names isolated, digits 0–9 (AC-9.1); one merged semantics node per spec row holding name, kind, size, KB range, format and note, headings marked as headers (AC-9.3); 48 dp minimum (AC-9.4); locale and font-scale change with the list open keeps search text and scroll (NFR-8). Real phone with the local uncommitted fixture asset, profile build: one screenshot per key state (row choose, list, search, empty, picked with note, ar, 200%); list open time from `dumpsys gfxinfo` (NFR-1, informational).
- **Done when:** the test passes; screenshots taken per the real-phone rules and recorded (no personal data); settings restored, build uninstalled, asset diff clean; the Product Owner accepts the screenshots or names fixes (G2 in the Test record).

### - [x] FEAT-011-T13 — Translate preset strings (es, pt, hi, id, ar) — Product Owner runs `/l10n-translate`
- **Implements:** FR-23, NFR-4, AC-9.5 · **ADRs:** —
- **Depends on:** T12 (G2; strings final)
- **Size:** M (0.5 d)
- **Scope:** the Product Owner types `/l10n-translate <lang>` for es (es-419), pt (pt-BR), hi, id and ar (MSA, Western digits 0-9), one language at a time, vendored `localize-*` skills only. Keys: every `preset*` key. The reviewer brief names the FR-15 banned words ("official", "approved", "guaranteed"), the FEAT-016 rule that no non-allow-listed key mentions the network ("offline", "online", "connect"), and that `select` case keys and placeholders stay identical. Only app strings go to the model, never user data. Status `AI-reviewed only`. Then add the presence-in-6-locales and `select`-cases-per-locale checks to `preset_copy_test.dart`.
- **Done when:** all five ARBs hold every `preset*` key; `untranslated_messages.json` has no FEAT-011 key; `docs/l10n/ai-review-log.md` has one entry per language with `AI-reviewed only`; T05 (with the new checks), FEAT-016 `privacy_copy_test.dart` and the T12 200% and RTL tests pass in every supported locale.

### - [x] FEAT-011-T14 — Real-phone offline check, P2 — gate G-final
- **Implements:** NFR-3, FR-17, FR-18, NFR-5, NFR-9 (evidence) · **ADRs:** —
- **Depends on:** T06, T13
- **Size:** M (0.5 d)
- **Scope:** push **P2** after local `flutter analyze` and `flutter test`. On the Realme 2 Pro, release build with the local uncommitted fixture asset: airplane mode on, Wi-Fi off and mobile data off (state noted; `ping 1.1.1.1` "Network is unreachable" first): open target step, open list, search, pick, Continue through compression (AC-1.5); force-stop and reopen: no preset applied, no recent list (AC-8.1); `adb logcat --pid` holds enum lines only, no form id, name or search text (AC-8.2); `aapt2 dump permissions` on the release APK equals `claims.md` section 3; reviewed lists unchanged. Result written into the `claims.md` "Pick a preset" row.
- **Done when:** every row passes and is recorded with date and device; P2 CI is green; synthetic files deleted with their MediaStore rows; settings restored; build uninstalled; `assets/presets/presets.json` back to `"forms": []` (`git status` clean); G-final recorded with the Product Owner's acceptance of the Open items.

### - [ ] FEAT-011-T15 — Enter the Product Owner's confirmed forms, exact-pixel and KB-only (waits on the Product Owner's confirmation; not done by Claude alone)
- **Implements:** FR-1, FR-3 (KB-only rows in real data), FR-20 (real specs), FR-21, FR-22, NFR-6, NFR-10 · **ADRs:** —
- **Depends on:** the Product Owner's confirmation of rows in `t15/review_list.md` (PRD OQ-1, FR-1 2.0): per row ticked or fixed against its source, with the decisions the list asks for (format where not stated; one exact W×H for "Choose px" rows per OQ-4, or KB-only; 1 MB / 8 MB as 1000 or 1024 KB; country for the embassy row; merge or keep forms with equal numbers); T04, T06, T08, **T17, T18, T19** (KB-only parse, CI rule, FR-20 size), **G3** (T21). May run before or after G-final; not part of it. **Release depends on it.**
- **Size:** not counted (data entry about 0.5 d [Assumption]; Product Owner confirmation time extra)
- **Scope:** start from `t15/review_list.md` (sources and quotes in `draft_forms.md`, `draft_forms_round2.md`, `verification.md`, `verification_round2.md`). Enter only confirmed rows, exactly as confirmed; a KB-only spec as `"width": null, "height": null` (tech section 5). Claude does not change a confirmed value or pick a pixel size, unit or format for the Product Owner; a doubt goes back to the Product Owner. The PR description lists every confirmed form id (FR-1 2.0, checked at review). One `docs/CHANGELOG.md` line per form (id, source title, date). One `presetCountry` `select` case per new country in `app_en.arb` (the review list names BD, IN, PK, MX, US, SG, and FR if chosen), translated by the Product Owner through `/l10n-translate`. Run `library_data_test.dart`, `freshness.dart` and the fixture run; any FR-20 report goes to the Product Owner, who fixes the spec or writes the `engineReview` reason. Push **P3**.
- **Done when:** 15–20 confirmed forms in the shipped file, each id listed as confirmed in the PR; `library_data_test.dart` and T05 pass; `freshness.dart` output recorded; P3 CI green including the fixture run on every real spec (KB-only ones at 600 × 600 px); each CHANGELOG line present; the new `presetCountry` cases in all six ARBs with `ai-review-log.md` entries. Release also needs FEAT-014 and OQ-5 (Open items 2, 3).

### - [x] FEAT-011-T16 — Two new strings in English and five languages — Product Owner runs `/l10n-translate`
- **Implements:** FR-6 (summary string), FR-26 (string), FR-23, NFR-4, AC-9.5 · **ADRs:** ADR-001
- **Depends on:** T13 (six-locale check in place)
- **Size:** S (0.25 d; Product Owner translation runs extra)
- **Scope:** `lib/l10n/app_en.arb`: `presetAnyPixelSize` "Any pixel size" and `presetKbOnlyNote` "This form sets no pixel size. Enter a width and height, or use your photo's size." (PRD section 8 text), no placeholders, "FEAT-011 ..." descriptions (the note's tells translators to name the button as their `targetUsePhotoSize` does); `@presetSpecRange` / `@presetSpecUpTo` descriptions gain "pixels is checkPixels, or presetAnyPixelSize for a form with no pixel size". Then the Product Owner types `/l10n-translate <lang>` for es (es-419), pt (pt-BR), hi, id and ar (MSA, digits 0-9), one at a time; reviewer brief as in T13 plus "Any pixel size must not read as 'any size is accepted'" (tech risk). One commit with all six ARBs, because T13's six-locale check fails on English-only keys. No Dart change.
- **Done when:** `flutter gen-l10n` passes; both keys in all six ARBs; `untranslated_messages.json` has no FEAT-011 key; one `ai-review-log.md` entry per language with `AI-reviewed only`; `preset_copy_test.dart` (banned words, six-locale presence) and FEAT-016 `privacy_copy_test.dart` pass.

### - [x] FEAT-011-T17 — KB-only `PresetSpec`, `matches`, `applyTo`, parser, summary; callers migrated
- **Implements:** FR-3, FR-11 (`applyTo`), FR-12, FR-13 (`matches`), FR-6 (summary), FR-16 (skip), FR-24, AC-4.8 (logic), NFR-7 · **ADRs:** ADR-001
- **Depends on:** T16 (`presetAnyPixelSize` getter); G3 notice given to the Product Owner first
- **Size:** M (0.5 d)
- **Scope:** `lib/features/presets/domain/preset_types.dart`: `int? width/height` with the both-or-neither `assert`, `kbOnly`, `matches(TargetInput)` and `applyTo(TargetInput)` per tech section 5; the 1.0 `target` / `input` getters removed. `parse_library.dart`: both null → KB-only; one null or a non-int → spec skipped and counted; `checkTarget` only when both are present. `preset_strings.dart`: KB-only summary passes `presetAnyPixelSize` as `{pixels}`. Call sites moved with no behaviour change for full specs: `preset_row.dart` `_applied` → `spec.matches(state.input)`, `_choose` → `fill(spec.applyTo(current input))` (no FR-26 line yet); `integration_test/preset_demo.dart` → `spec.applyTo(const TargetInput())`; `integration_test/preset_fixture_run.dart` size from `kbOnlyTestSize = Target(600, 600)` (named constant, FR-20 comment) for a KB-only spec. `parse_library_test`'s `target` test becomes a `matches` / `applyTo` table test.
- **Done when:** `flutter analyze` is clean; `flutter test test/features/presets/` passes with new cases: both null parses as KB-only, one null and a string width each skip and count; `applyTo` keeps typed and empty Width/Height for KB-only and replaces all five for a full spec (`minKb` null → `''`); `matches` table: leading zeros, Arabic-Indic digits, empty Min, each field changed and changed back, for both kinds, and KB-only true with Width/Height edited, empty or invalid; for every fixture full spec `matches` agrees with `validateTargetInput(...) == TargetSpec` (1.0 equivalence); summary "Any pixel size · 10–200 KB · JPEG" and "Any pixel size · up to 200 KB · JPEG" with the KB part in an LRI isolate. All 1.0 row tests (AC-4.1–4.6) and list, a11y tests pass unchanged. `TargetSpec`, `TargetInput`, `TargetFormController`, `target_screen.dart` have no diff.

### - [x] FEAT-011-T18 — CI both-or-neither rule and self-tests (FR-19 2.0)
- **Implements:** FR-19, FR-3, NFR-6 · **ADRs:** —
- **Depends on:** T17
- **Size:** S (0.25 d)
- **Scope:** `test/presets/library_rules.dart`: `width` and `height` keys stay required; exactly one `null` gives "Form [ID] [KIND]: give both width and height, or neither." and skips the size check; both `null` skips the size check only (`maxKb`, `format`, notes rules still run); both present keeps the 1.0 size rule. Self-tests in `library_data_test.dart`.
- **Done when:** `flutter test test/presets/library_data_test.dart` passes on the shipped file; self-tests: a Test Form C-like spec passes; photo A with `height: null` fails with the both-or-neither message naming id and kind; a KB-only spec with `maxKb: null` fails "KB range invalid."; a spec with the `width` key missing still fails as a missing field; all 1.0 self-tests (AC-7.1–7.3) unchanged.

### - [x] FEAT-011-T19 — Test Form C fixture, count ripples, FR-20 KB-only run on the phone
- **Implements:** FR-20, FR-6 (list row), FR-3, NFR-9 · **ADRs:** ADR-001
- **Depends on:** T17, T18
- **Size:** S (0.25 d)
- **Scope:** Test Form C (tech section 5, synthetic, country `ZZ`, `source.url` `[PLACEHOLDER]`) added identically to `test/presets/fixtures/test_library.json` and `integration_test/preset_fixture_data.dart`. Counts updated: `preset_asset_source_test` (forms 3), `preset_list_screen_test` ("Photo" rows 3, plus Test Form C's row reads "Any pixel size · 10–200 KB · JPEG" with no note), `freshness_test` (`forms: 3`, stale list unchanged), fixture run (`hasLength(3)`).
- **Done when:** `flutter test` passes (incl. `fixture_data_test.dart`); `preset_fixture_run.dart` passes on the Realme 2 Pro (`adb devices` first; debug build, uninstalled after) with Test Form C photo READY at 600 × 600 px inside 10–200 KB, recorded in the Test record; `git diff --exit-code assets/presets/presets.json` passes.

### - [x] FEAT-011-T20 — FR-26 line and announcement on the target-step row
- **Implements:** FR-26, FR-11, FR-13, FR-14 (note order), AC-4.7, AC-4.8, AC-4.9, NFR-2 · **ADRs:** ADR-001
- **Depends on:** T19; G3 notice given
- **Size:** M (0.5 d)
- **Scope:** `lib/features/presets/presentation/preset_row.dart` only: while the applied spec is KB-only and `matches`, `presetKbOnlyNote` is the first `BoothNotice` under the row (before any `notCovered` note), icon plus text, non-blocking, whatever Width and Height hold; the pick announcement for a KB-only spec is the applied label followed by the note. No code proposes or changes a pixel size. Widget tests in `test/features/presets/preset_row_test.dart`.
- **Done when:** `flutter test test/features/presets/preset_row_test.dart` passes with: AC-4.7 (Width 300, Height 400 typed, pick Test Form C photo → 300/400/10/200/JPEG, row "Test Form C · Photo", FR-26 line shown, keyboard closed); AC-4.8 (edit Width then Height → label and line stay; edit Min, Max, format, each restored in between → "Choose a form" and no line); AC-4.9 (Width and Height empty, pick, Continue → FEAT-005 width and height errors as for manual entry, fields stay empty, `onContinue` not called); "Use photo size" after a KB-only pick fills the photo's size and keeps the label; FR-26 line absent for Test Form A; announcement text checked. All 1.0 row tests and FEAT-005 target tests pass unchanged; `flutter test test/privacy/` passes.

### - [x] FEAT-011-T21 — Lean check of the KB-only states, P2b — gate G3
- **Implements:** FR-25 (2.0 changes), FR-26, FR-6, FR-24, NFR-2, AC-9.1, AC-9.2, AC-9.3 · **ADRs:** —
- **Depends on:** T20
- **Size:** S (0.25 d)
- **Scope:** `test/features/presets/preset_a11y_test.dart` extended: Test Form C's list row and the applied row with the FR-26 line at 200% on 360×640 dp in all 7 supported locales (no overflow, row reachable, 48 dp); ar mirrored with the KB part in an LRI isolate and digits 0–9; the merged semantics node of Test Form C's row holds "Any pixel size". Real phone, profile build with the **local uncommitted** fixture asset (A/B/C), real flow, no impeccable pass: one screenshot each of the list row with "Any pixel size", applied with Width/Height typed (FR-26 line), applied with Width/Height empty, then ar and 200% of the applied state. Locale and font scale noted and restored; build uninstalled; asset diff clean. After the Product Owner accepts: local `flutter analyze` and `flutter test`, then push **P2b**.
- **Done when:** the a11y test passes; screenshots recorded under the real-phone rules (no personal data); the Product Owner accepts them or names fixes (G3 in the Test record); P2b CI green with the Test Form C line in the API 28 fixture run.

## Effort reconciliation
| Tech Effort line | Tech days | Tasks | Task days |
|---|---|---|---|
| Types, `parseLibrary`, loader, providers, enum log, unit tests | 1.0 | T01 M, T02 M | 1.0 |
| CI data rules + self-tests, copy/storage test, freshness tool, checklist line | 1.0 | T04 M, T05 M, T06 S | 1.25 |
| Search key, filter, fuzz test | 0.5 | T07 M | 0.5 |
| ARB keys (en) + `/l10n-translate` | 0.75 | T03 S, T13 M | 0.75 |
| Target-step wiring | 0.5 | T11 M | 0.5 |
| impeccable pass | 0.5 | T09 M | 0.5 |
| List screen + row UI, RTL, 200%, TalkBack, emulator states | 2.0 | T10 L, T12 L | 2.0 |
| FR-20 fixture test and CI wiring | 1.0 | T08 L | 1.0 |
| Not in tech: real-phone offline check and G-final | — | T14 M | 0.5 |
| **Total** | **7.25 d ≈ 1.45 pw** | 14 counted tasks | **8.0 d ≈ 1.6 pw** |

The task total is 0.75 d above tech: the separate `claims.md`/CHANGELOG/freshness PR (+0.25) and the release-build offline run on the real phone (+0.5). It stays inside PRD OQ-17's 1.2–1.8 pw. Not counted: T15 (needs OQ-1 data) and the Product Owner's design, review and sourcing time. Cut candidate (PRD OQ-6, a Product Owner decision): drop search (T07 and the search part of T10), saving about 0.75 d.

**2.0 delta (KB-only specs)**
| Tech 2.0 delta line | Tech days | Tasks | Task days |
|---|---|---|---|
| `PresetSpec` nullable size, `kbOnly`, `applyTo`, `matches`, parser, unit and table tests | 0.5 | T17 M (with the summary and the call-site moves) | 0.5 |
| CI both-or-neither rule + self-tests | 0.25 | T18 S | 0.25 |
| `PresetStrings` summary, `PresetRow` FR-26 line and announcement, widget tests AC-4.7..4.9 | 0.5 | T20 M (summary moved to T17, because the nullable size does not compile without it) | 0.5 |
| 2 ARB keys (en) + `/l10n-translate` | 0.25 | T16 S | 0.25 |
| Test Form C, count ripples, FR-20 KB-only size, `preset_demo` | 0.25 | T19 S (size constant and demo line in T17) | 0.25 |
| Emulator check of the KB-only state (en, ar, 200%) | 0.25 | T21 S (Realme 2 Pro, plus P2b) | 0.25 |
| **Delta** | **2.0 d ≈ 0.4 pw** | 6 counted tasks | **2.0 d ≈ 0.4 pw** |

New task total 10.0 d ≈ 2.0 pw (tech 9.25 d ≈ 1.85 pw), above PRD OQ-17's 1.2–1.8 pw; the 0.75 d gap is the 1.0 one above. Not in tech, not counted: the `kbonly` demo state (left out, Open items 11). A full impeccable pass instead of T21's look would add about 0.5 d (G3).

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T02, T04, T06, T15 | Shipped empty until T15; count checked by the release checklist, not CI. 2.0: only Product Owner-confirmed rows from `t15/review_list.md`; confirmed ids listed in the T15 PR (process, not testable) |
| FR-2 | T01, T04 | |
| FR-3 | T01, T04, T17, T18, T19, T15 | 2.0: KB-only spec (both null) in types, parser, CI rule, fixture, real data |
| FR-4 | T01, T04 | Data exposed for FEAT-014; no UI here |
| FR-5 | T09, T11 | |
| FR-6 | T03, T07, T09, T10, T16, T17, T19, T21 | 2.0: "Any pixel size" string (T16), summary (T17), list-row test (T19), screenshot (T21) |
| FR-7 | T10 | |
| FR-8 | T07, T10 | Should |
| FR-9 | T10 | Keyboard honouring the flag is a [Hypothesis] (Open items 6) |
| FR-10 | T10 | Should |
| FR-11 | T11, T17, T20 | 2.0: `applyTo` unit tests (T17), AC-4.7 widget test (T20) |
| FR-12 | T01, T02, T11, T17 | `TargetSpec` unchanged (T17 checks no diff) |
| FR-13 | T11, T17, T20 | 2.0: `matches` table test (T17), AC-4.8 widget test (T20) |
| FR-14 | T03, T09, T10, T11, T12, T20 | 2.0: FR-26 line first, then notes |
| FR-15 | T03, T05, T10 | Should |
| FR-16 | T01, T02, T10, T11 | |
| FR-17 | T02, T05, T11, T14 | |
| FR-18 | T02, T14 | |
| FR-19 | T04, T18 | 2.0: both-or-neither rule (T18) |
| FR-20 | T08, T17, T19, T21, T15 | Should. 2.0: KB-only at `kbOnlyTestSize` 600 × 600 px (T17), Test Form C on the phone (T19) and API 28 (P2b, T21) |
| FR-21 | T06, T15 | Should |
| FR-22 | T06, T15 | Should; process item, checked at PR review (convention note in T06) |
| FR-23 | T03, T13, T16 | |
| FR-24 | T03, T12, T17, T21 | |
| FR-25 | T09, T21 | Gate G1; 2.0 changes: lean check, gate G3 (no new impeccable pass unless the Product Owner asks) |
| FR-26 | T16, T20, T21 | String (T16), line and announcement (T20), screenshots and 200%/RTL (T21) |
| AC-4.7 | T20 | Widget test |
| AC-4.8 | T17, T20 | `matches` table (T17), widget test (T20) |
| AC-4.9 | T20 | Widget test; FEAT-005 validation unchanged |
| NFR-1 | T07, T08, T12 | Informational timings |
| NFR-2 | T12, T20, T21 | TalkBack speech: Open items 4 |
| NFR-3 | T06, T14 | |
| NFR-4 | T03, T13, T16 | `AI-reviewed only` |
| NFR-5 | T02, T05, T11, T14 | |
| NFR-6 | T01, T04, T15, T18 | |
| NFR-7 | T01, T07, T12, T17 | |
| NFR-8 | T07, T10, T12 | |
| NFR-9 | T08, T14, T19, T21 | API 28 in CI, API 36 phone |
| NFR-10 | T04, T15 | |

**Not covered by a task:** real-world accuracy of specs (BRIEF 1.3, Product Owner); OQ-5 legal advice; FEAT-014 screens; the stale FEAT-011 roadmap row wording (Product Owner's edit, PRD section 1). 2.0: the Product Owner's confirmation of each `review_list.md` row (FR-1, process); a KB-only pick at a size whose maximum cannot be reached gets FEAT-004's normal message (PRD section 9, no preset code, no task); no offline re-run for the 2.0 code (G-final, [Assumption]).

## Open items
1. **OQ-1 data and "Implemented".** The build can pass G-final with an empty shipped library. The Product Owner decides whether `/approve FEAT-011 implemented` waits for T15. The release waits for T15 in any case.
2. **FEAT-014 release rule.** The preset list is not released without FEAT-014's source and date display (PRD section 11).
3. **OQ-5 legal check** of naming and source titles before the store release [PLACEHOLDER: counsel].
4. **TalkBack** is not installed on the Realme 2 Pro; AC-9.3 is covered by semantics tests (T12); speech is checked only if the Product Owner installs it.
5. **English-only in five locales between T03 and T13.** gen-l10n falls back to English; do not release in between.
6. **Keyboard learning flag** is honoured by Gboard [Hypothesis]; the phone's keyboard app is not checked by any task.
7. **Inconsistencies found:**
   a. AC-1.1 says the row is always shown; tech OQ-T1 hides it for an empty library (development only; release requires 15–20 forms).
   b. NFR-1 names the 2 GB emulator profile; local runs use the Realme 2 Pro and timings are informational; API 28 timing only in CI (T08).
   c. FR-20 on the device cannot read `test/presets/fixtures/`; T08 uses an inline synthetic library with the same values.
   d. Device checks need forms in the list; they use an uncommitted local fixture asset, never committed (T12, T14, T21).
   e. (2.0) Tech section 9's risk row "Row label flicker ... compare validated `TargetSpec`" still names the 1.0 mitigation; 2.0 uses `matches` with the same cleaning (tech section 5). Tasks follow section 5.
   f. (2.0) `t15/review_list.md` says KB-only rows need PRD 2.0 "(Under Discussion)"; PRD 2.0 is now Approved. Its header is stale, its rows are not affected.
8. **(2.0) Translation before the look.** T16 translates the two new strings before G3, unlike 1.0 (T13 after G2), because T13's six-locale check fails on English-only keys and the wording is the approved PRD section 8 text. A wording fix at G3 re-runs `/l10n-translate` for that key only.
9. **(2.0) G-final scope.** G-final now also waits for G3 and P2b. The T14 offline run is not repeated for 2.0 [Assumption: 2.0 adds no network, storage, log or permission code]; the Product Owner may ask for one (about 0.25 d).
10. **(2.0) OQ-T5 residual risk.** A KB-only pick keeps Width and Height left over from earlier, and the row then reads "<form> · Photo" at a size the form never stated. Mitigated only by the FR-26 line (T20) and the closed test.
11. **(2.0) Left out:** the `kbonly` state in `integration_test/preset_demo.dart` (tech 2.0). T21 uses the real flow with the local fixture asset instead; add the demo state only if the real flow cannot reach a state.

## Test record
_Filled in by T08, T09, T12, T13, T14, T15, T16, T19 and T21 (one row per check and device: date, device or CI run, result). Synthetic images and synthetic forms only. No file names, URIs, paths of real files, image content or anything personal seen on the phone; use `[PLACEHOLDER]` for anything sensitive._

| Date | Task | Check | Device / run | Result |
|---|---|---|---|---|
| 2026-11-27 | T15 | FR-20 report resolved; country names translated | host | pk-fpsc photo given an engineReview reason (the Product Owner left the choice to Claude). presetCountry cases in es, pt, hi, id, ar (AI-reviewed only; one hi fix). A repeat phone run could not start because the phone was asleep and locked (not unlocked by Claude); the earlier phone run covered the same specs, and P3 CI runs all of them on API 28. Full suite 745 pass; freshness forms: 17. |
| 2026-11-27 | T15 | Confirmed forms entered | host + Realme 2 Pro, API 36, debug | The Product Owner replied "confirm all" to the 17-row checklist (t15/confirm_checklist.md, defaults as listed). Shipped file: 17 forms, 27 specs (10 exact-pixel forms, 7 KB-only), lastChecked 2026-11-27; presetCountry gains BD, FR, IN, MX, PK, SG, US in English. library_data_test passes; freshness: forms: 17, none older than 90 days; target-screen goldens re-recorded (the row now shows). FR-20 on the phone: 26 of 27 specs READY; pk-fpsc photo (KB-only, max 30 KB) TOO_DEGRADED at the 600 × 600 test size, reported to the Product Owner. Not pushed until resolved. |
| 2026-11-27 | T14 | Gate G-final | P2 (45959410818), G3, P2b (45992551444) | Passed: the Product Owner accepted the Open items (release waits for T15 and FEAT-014; OQ-5 legal check before release; TalkBack speech covered by tests only; keyboard learning flag depends on the keyboard app; documented inconsistencies). Build done; T15 (confirmed forms) remains. |
| 2026-11-27 | T21 | P2b CI | run 45992551444 | Green on the first attempt: all three jobs; the API 28 fixture run reports Test Form C photo READY with the other specs, and the planted unreachable spec still reported. |
| 2026-11-27 | T21 | a11y test for KB-only | host | Pass: Test Form C row reachable and at least 48 dp at 200% in all 7 locales; the applied row with the FR-26 line fits at 200% in all 7; ar summary keeps "10–200 KB" in an LRI isolate with digits 0-9; Test Form C row is one button node holding name, kind, "Pixel size not stated", KB range and format. |
| 2026-11-27 | T21 | G3 screenshots: list row, applied with 300×400 typed, applied with Width/Height empty, ar applied, 200% applied | Realme 2 Pro, API 36, profile build with the fixture (A/B/C) copied over the asset locally; real flow (synthetic photo chosen from files by its name only) | Taken, ExactSize in front before each capture, under build/preset_g3 (not committed). Settings noted and restored: rotation (1, 0) locked to portrait for the shots, font_scale 0.85 → 2.0 → 0.85, app locale set to ar then cleared. Synthetic file and its MediaStore row deleted; build uninstalled; asset back to `"forms": []`. Gate G3 passed: the Product Owner accepted the five screenshots on 2026-11-27. |
| 2026-11-27 | T20 | FR-26 line and announcement | host | Done: PresetRow shows presetKbOnlyNote as the first notice while a KB-only spec is applied and matches; the pick announcement is the label, a line break, then the note. Tests: AC-4.7 (300/400 kept, 10/200/JPEG, label, note first, keyboard closed), AC-4.8 (Width/Height edits keep it; Min, Max, format drop and restore it), AC-4.9 (empty Width/Height: Continue shows FEAT-005 errors, nothing filled), "Use photo size" keeps the label and hands over 4000×3000 10–200 KB, no line for a full spec, announcement text. Full suite 743 pass; FEAT-005 files unchanged. |
| 2026-11-27 | T19 | Test Form C and FR-20 phone run | Realme 2 Pro, API 36, debug | Pass: Test Form C photo (KB-only) READY at 600 × 600 px inside 10–200 KB; A photo, A signature and B photo READY; planted unreachable spec still reported (ABOVE_MAX). Build uninstalled by the test run; shipped asset unchanged. Counts updated in parse, asset-source, list, search and freshness tests; list test checks Test Form C reads "Pixel size not stated · 10–200 KB · JPEG". |
| 2026-11-27 | T17 | KB-only spec type and callers | host | Done: `PresetSpec` width/height nullable (both or neither, assert), `kbOnly`, `applyTo` and `matches` replace `input`/`target`; parser accepts both null, skips one null or a non-int; summary shows "Pixel size not stated" (the English changed from "Any pixel size" after T16); `PresetRow`, `preset_demo.dart` and `preset_fixture_run.dart` (KB-only at `kbOnlyTestSize` 600×600) moved; new parse, applyTo, matches (native digits, leading zeros, each field changed and restored, KB-only ignores width/height even empty or invalid), 1.0 equivalence and summary tests. Full suite 733 pass; TargetSpec, TargetInput, TargetFormController and target_screen.dart unchanged. The G3 notice was given before T17 (2026-11-27). |
| 2026-11-27 | T16 | Strings presetAnyPixelSize, presetKbOnlyNote in six languages | host | Done: blind Sonnet review per language; hi and id fixed and ar pre-fixed so the summary says "pixel size not stated" (their first drafts could read as "no limit"); open lists none; untranslated_messages.json empty; preset copy, privacy copy and preset tests pass. For G3: the English "Any pixel size" can itself read as "any size is accepted"; proposal "Pixel size not stated", which is what all five translations say. Applied 2026-11-27 (the Product Owner left the choice to Claude); translations unchanged. |
| 2026-11-27 | T14 | P2 CI | run 45959410818 | Green on attempt 2. Attempt 1: build and tree-shaking jobs green and the FR-20 fixture run passed on API 28, but the FEAT-007 export_bridge_test step timed out ("driver did not answer" from the export driver; no export, driver or Android file changed since FEAT-011 began). Re-running the failed job passed. |
| 2026-11-27 | T14 | Real-phone offline run (airplane mode on, Wi-Fi off, mobile data off; `ping 1.1.1.1` "Network is unreachable" before and after) | Realme 2 Pro, API 36, release build (debug-signed) with the fixture copied over the asset locally | Pass (AC-1.5): synthetic photo chosen from files by its name only; target step showed "Choose a form"; list opened at once; search "tfa" left Test Form A only; picking its photo spec filled 200/230/20/50 JPEG with the keyboard closed and both notes shown; crop and compression reached "Matches your target" (22.1 KB). A shell share-in (`am start` SEND with a MediaStore URI) could not be read by the app (no URI grant from the shell), so files was used. |
| 2026-11-27 | T14 | Restart, logs, permissions | same | Pass: after force-stop and reopen the row read "Choose a form", the fields were empty and the list search was empty (AC-8.1). `adb logcat --pid` held only enum lines (pick, crop, compression, preview outcomes) and no form id, name or search text (AC-8.2). `aapt2 dump permissions` equals claims.md section 3; reviewed package and dependency lists unchanged. claims.md "Pick a preset" row filled. Synthetic file and its MediaStore row deleted; airplane mode, Wi-Fi, mobile data and rotation restored as noted (0, 1, 0, 1); build uninstalled; `assets/presets/presets.json` back to `"forms": []`. |
| 2026-11-27 | T13 | Translations es, pt, hi, id, ar | host | Every preset key in all six ARBs, untranslated_messages.json empty, one ai-review-log entry per language with AI-reviewed only (open lists empty; the es open item was settled by rewording presetLoadFailed in English). preset_copy_test.dart gained the six-locale presence-and-translated check; preset_a11y_test.dart 200% test now runs in all 7 supported locales; privacy_copy_test.dart passes. |
| 2026-11-27 | T12 | preset_a11y_test.dart | host | Pass: tap-target, labelled-target and contrast guidelines on the row and the list; en, ar and hi at 200% on 360×640 with no overflow, every spec row reachable and at least 48 dp; ar mirrored, names in FSI/PDI, digits 0-9; one merged button node per spec row with form name, kind, size, KB range, format and notes; country and form headings are header nodes; locale and font-scale change keep search text and scroll. |
| 2026-11-27 | T12 | G2 screenshots: choose, applied with notes, load failure, list, no match with footer, ar list, 200% list | Realme 2 Pro, API 36, debug demo build (integration_test/preset_demo.dart, synthetic Test Form A/B served in place of the asset; shipped asset unchanged) | Taken, ExactSize in front before each capture, under build/preset_g2 (not committed). Rotation locked to portrait for the shots and restored (accelerometer_rotation 1, user_rotation 0); build uninstalled. Seen: ar shows the English fallback until T13, so sentence periods sit at the line start; the demo opens the list as the first route, so no back arrow shows (the real flow pushes it). List open time (NFR-1, informational) not measured: the debug demo build is not representative. Gate G2 passed: the Product Owner accepted the seven screenshots on 2026-11-27. |
| 2026-11-27 | T09 | Gate G1 | design note t09/preset_design.md 0.1 | Passed: the Product Owner accepted the design and its three defaults (full-screen list, nothing drawn while loading, no summary on the applied row) and the English copy with two fixes (presetNoteContent "rules for this image", presetLoadFailed "enter sizes yourself"). |
| 2026-11-27 | T08 | FR-20 fixture run, local | Realme 2 Pro, API 36, debug | Pass: shipped library 0 forms (loaded in 24 ms); Test Form A photo and signature and Test Form B photo READY; planted 4000×4000 px, max 2 KB spec reported (ABOVE_MAX) and passes with an engineReview. Synthetic images in the app support dir, deleted in tearDownAll; build uninstalled. |
| 2026-11-27 | T08 | P1 CI | run 45946777092 | Green: all three jobs; same FR-20 lines on API 28 (load 2 ms). Emulator job 11 min 38 s against 20 min 59 s on the last green run (45886183791), so the added time is below run-to-run noise and could not be measured (tech hypothesis 1–3 min). |
| 2026-11-27 | T06 | Freshness test date | host | The fixture dates are 2026-10-01 (Form A) and 2026-11-20 (Form B), so the CI rule "lastChecked not after today" passes on the fixture. With --today 2027-03-01 both forms would be over 90 days, so the test uses --today 2027-02-01 (A 123 days, listed; B 73 days, not listed). Same check, different date. |

## Instructions for Claude Code
- Read `prd.md`, `tech.md` and ADR-001 before starting a task.
- Implement only the current task, in order; tick its checkbox, commit, and add a line to `docs/CHANGELOG.md` when done. Push only at P1 (T08), P2 (T14), P2b (T21) and P3 (T15); run `flutter analyze` and `flutter test` locally first.
- Order for 2.0: T16 → T17 → T18 → T19 → T20 → T21, then T15 when the Product Owner has confirmed rows. T15 never starts before T17–T19 and G3.
- Gates: no list or row UI (T10, T11, T12) before G1; T13 and T14 only after G2; tell the Product Owner before T17 (G3 notice); P2b only after G3; stop at every failing gate and report to the Product Owner.
- UI rule: before designing or building any real UI screen, stop and tell the Product Owner (impeccable, decision 2026-11-20). T09 is that stop. impeccable runs lean: no image comps, no reviewer subagents, one round, one screenshot per key state.
- Data rule: never enter a real form, value, name, issuer or source title into the asset unless the Product Owner confirmed that row for T15 (PRD FR-1 2.0; researched drafts stay in `t15/`); in T15 never look one up again or change a confirmed value. Tests use only synthetic "Test Form" entries in country `ZZ`. Never commit fixture data into `assets/presets/presets.json`.
- Never loosen a gate (CI data rules, 16 px floor, banned words, storage scan, reviewed lists, whole-tree scan) without a PRD change approved by the Product Owner.
- Never set a PRD, tech or tasks status to Approved, Rejected or Implemented.
- Translations only through `/l10n-translate <lang>` typed by the Product Owner, status `AI-reviewed only`.
- **Real phone (Realme 2 Pro):** `adb devices` first; synthetic images only (generated gradients, flat colours, checker patterns), pushed to `Download` and deleted with their MediaStore rows after the run, never a real face, signature, document or card; check the foreground app (`adb shell dumpsys window | grep mCurrentFocus`) before every screenshot and capture only ExactSize's own screens, never the system picker, file chooser, camera, gallery or share sheet; offline means airplane mode **plus** Wi-Fi off and mobile data off, checked with `ping` first (Wi-Fi stays on in airplane mode on this phone); note every setting before changing it (airplane mode, Wi-Fi, mobile data, font scale, locale, rotation) and restore it after; uninstall the test build after each run; never record personal data seen on the phone.
- Privacy: no network call, clipboard use, persistence, recents, or form id or search text in any log. `[PLACEHOLDER]` for every credential, key, URL or sensitive value.
- If a requirement is unclear or wrong, stop and propose a PRD change.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-27 | First draft |
| 1.0 | 2026-11-27 | Approved by the Product Owner (/approve FEAT-011-TASKS) |
| 2.0 | 2026-11-27 | Scope change for PRD 2.0 / tech 2.0 (KB-only specs): new T16–T21 (strings and translation, domain and parser, CI rule, Test Form C and FR-20 run, FR-26 line, lean check with gate G3 and push P2b); T15 rescoped to confirmed rows from `t15/review_list.md` incl. KB-only, now after T17–T19 and G3; G-final also waits for G3 and P2b; traceability for FR-1, FR-3, FR-6, FR-11, FR-13, FR-19, FR-20, FR-26, AC-4.7–4.9; 2.0 effort delta; Open items 7e–11. Status Under Discussion |
| 2.0 | 2026-11-27 | Approved by the Product Owner (/approve FEAT-011-TASKS) |
