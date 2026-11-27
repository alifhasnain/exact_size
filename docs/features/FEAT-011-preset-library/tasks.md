---
id: FEAT-011-TASKS
title: Built-in preset library — Implementation Tasks
status: Approved
version: 1.0
updated: 2026-11-27
links: [FEAT-011, FEAT-011-TECH, ADR-001, FEAT-005, FEAT-002, FEAT-004, FEAT-014, FEAT-016, FEAT-019]
---

# FEAT-011 — Implementation Tasks

Milestone: R1 Phase A (MVP, Must). Work top to bottom, one task at a time.

Sizes: **S** ≈ 0.25 day, **M** ≈ 0.5 day, **L** ≈ 1 day; each task is one PR.
Module paths follow tech section 3: new `lib/features/presets/{domain,data,presentation}`, `assets/presets/presets.json`, `test/features/presets/`, `test/presets/` (CI rules and fixtures), `integration_test/preset_fixture_run.dart`, `tool/presets/freshness.dart`; changed `lib/features/target/presentation/target_screen.dart`, `pubspec.yaml` (one asset line), `lib/l10n/app_*.arb`, `integration_test/bundle.dart` (one import), `docs/features/FEAT-016-on-device-privacy/claims.md` (sections 5 and 6), `docs/CHANGELOG.md` (one convention note).

**Already built, reused, not planned again:** `TargetFormController.fill`, `targetFormProvider`, `validateTargetInput`, `cleanNumberText` (FEAT-005); `checkTarget`, `validateTarget`, `CropRenderer`, `SourceProbe`, `CompressionRunner` and the `crop_to_compression.dart` call sequence (FEAT-002, FEAT-004); the `LogSink` typedef and enum-only log pattern; the `_iso` / `_ltr` isolate helpers; `BoothNotice` note style; FEAT-016 whole-tree scan, `privacy_copy_test.dart`, reviewed package and dependency lists, `claims.md`; the CI `build` and API 28 `emulator` jobs running `integration_test/bundle.dart`; gen-l10n with 6 languages.

**Decisions used (PRD 1.0, open questions at defaults; tech 1.0, OQ-T1..T3 at defaults):**
- PRD OQ-1: the form list is **not** a build blocker. Everything is built and tested with synthetic fixtures (`test/presets/fixtures/test_library.json`, "Test Form A/B", country `ZZ`, a second user-assigned code such as `XY` only where a test needs two sections). The shipped asset stays `{"schema": 1, "forms": []}` until T15.
- OQ-T1: the row is hidden when the library has zero forms (FEAT-005 alone); the load-failure message is only for a real load error.
- OQ-T2: fixture images are generated at test time with `dart:ui`; no binary committed.
- OQ-T3: banned words are checked in UI strings and `aliases`, not in published names, issuers or source titles.
- PRD OQ-2 form with 1–2 spec rows; OQ-3 no KB-only presets; OQ-6 search Should (first cut if the budget slips: T07 and the search part of T10, about 0.75 d); OQ-7 label back to "Choose a form" after an edit; OQ-8 pick replaces silently; OQ-9 no FEAT-006 change; OQ-11 applied preset beside `TargetSpec`; OQ-13 URL stored as text, not shown; OQ-14 90 days.

**Test devices:**
- **Local device runs and screenshots use the connected real phone, Realme 2 Pro, API 36.** Run `adb devices` first. The local emulator (Medium_Phone_API_36.1) is used only if `adb devices` already shows it; never start a second one, never kill it.
- **API 28 runs only in CI.** CI costs about 80 min per push to `main`: commit after each task, push only at milestones. Planned pushes: **P1** after T08 (CI data rules, copy test, first FR-20 fixture run on API 28), **P2** in T14 after T13, before G-final. **P3** in T15 when the Product Owner's real forms land (FR-20 on real specs). Run `flutter analyze` and `flutter test` locally before each push.
- Device runs that need forms in the list use a **local, uncommitted** copy of the fixture library over `assets/presets/presets.json`; `git diff --exit-code assets/presets/presets.json` must pass before every commit.
- Files run under `flutter drive` use `testWidgets` only.

## Decision gates
| Gate | Task | Passes when | If it fails / what it blocks |
|---|---|---|---|
| G1 Design (FR-25) | T09 | The Product Owner was told before any visual work; one lean impeccable pass on Material 3 and the existing theme (no image comps, no reviewer subagents, one round) covers the target-step row (choose, applied with notes, load failure, hidden when empty) and the list (search, sections, spec rows, notes, empty state, footer); the T03 English copy accepted or fixes named; reference and date recorded | **Blocks T10, T11, T12** (all list and row UI). T01–T08 (data, loader, strings, CI rules, copy test, freshness, search, fixture run) do not wait on it |
| G2 Accessibility, RTL, 200% | T12 | Guideline, 200% and RTL tests pass in en, ar and hi; the Product Owner has seen one Realme 2 Pro screenshot per key state and accepts them or names fixes. One look | **Blocks T13** (strings final before translation) **and T14**. Fixes go into T10/T11 code inside T12; a scope change means a PRD change |
| G-final Build (device and CI) | T14 | Real-phone offline run passes (release build, airplane mode plus Wi-Fi and mobile data off); no preset survives a restart; logcat holds enum lines only; release APK permissions and reviewed lists unchanged; FEAT-016 `claims.md` row recorded; P2 CI green; the Product Owner accepts the Open items | A network use, a privacy leak, a crash or an accessibility miss means stop and report. Otherwise the build is done. **G-final does not depend on T15** |
| Release (not a build gate) | T15 + others | T15 done with 15–20 verified forms and P3 green; FEAT-014 display shipped; OQ-5 legal advice taken; the FEAT-016 release checklist preset line passes | The preset list is not released. Whether `/approve FEAT-011 implemented` waits for T15 is the Product Owner's call (Open items 1) |

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

### - [ ] FEAT-011-T14 — Real-phone offline check, P2 — gate G-final
- **Implements:** NFR-3, FR-17, FR-18, NFR-5, NFR-9 (evidence) · **ADRs:** —
- **Depends on:** T06, T13
- **Size:** M (0.5 d)
- **Scope:** push **P2** after local `flutter analyze` and `flutter test`. On the Realme 2 Pro, release build with the local uncommitted fixture asset: airplane mode on, Wi-Fi off and mobile data off (state noted; `ping 1.1.1.1` "Network is unreachable" first): open target step, open list, search, pick, Continue through compression (AC-1.5); force-stop and reopen: no preset applied, no recent list (AC-8.1); `adb logcat --pid` holds enum lines only, no form id, name or search text (AC-8.2); `aapt2 dump permissions` on the release APK equals `claims.md` section 3; reviewed lists unchanged. Result written into the `claims.md` "Pick a preset" row.
- **Done when:** every row passes and is recorded with date and device; P2 CI is green; synthetic files deleted with their MediaStore rows; settings restored; build uninstalled; `assets/presets/presets.json` back to `"forms": []` (`git status` clean); G-final recorded with the Product Owner's acceptance of the Open items.

### - [ ] FEAT-011-T15 — Enter the Product Owner's verified forms (waits on PRD OQ-1 data; not done by Claude alone)
- **Implements:** FR-1, FR-20 (real specs), FR-21, FR-22, NFR-6, NFR-10 · **ADRs:** —
- **Depends on:** the Product Owner's verified list (PRD OQ-1): per form the name and issuer as published, country, category, source title, check date and each spec value; T04, T06, T08. May run before or after T14; not part of G-final. **Release depends on it.**
- **Size:** not counted (data entry about 0.5 d [Assumption]; Product Owner sourcing time extra)
- **Scope:** enter values exactly as given; Claude never looks up, guesses or "corrects" a value (a doubt goes back to the Product Owner). One `docs/CHANGELOG.md` line per form (id, source title, date). One `presetCountry` `select` case per new country in `app_en.arb`, translated by the Product Owner through `/l10n-translate`. Run `library_data_test.dart`, `freshness.dart` and the fixture run; any FR-20 report goes to the Product Owner, who fixes the spec or writes the `engineReview` reason. Push **P3**.
- **Done when:** 15–20 forms in the shipped file; `library_data_test.dart` and T05 pass; `freshness.dart` output recorded; P3 CI green including the fixture run on every real spec; each CHANGELOG line present. Release also needs FEAT-014 and OQ-5 (Open items 2, 3).

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

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T02, T04, T06, T15 | Shipped empty until T15; count checked by the release checklist, not CI |
| FR-2 | T01, T04 | |
| FR-3 | T01, T04 | KB-only forms excluded (OQ-3) |
| FR-4 | T01, T04 | Data exposed for FEAT-014; no UI here |
| FR-5 | T09, T11 | |
| FR-6 | T03, T07, T09, T10 | |
| FR-7 | T10 | |
| FR-8 | T07, T10 | Should |
| FR-9 | T10 | Keyboard honouring the flag is a [Hypothesis] (Open items 6) |
| FR-10 | T10 | Should |
| FR-11 | T11 | |
| FR-12 | T01, T02, T11 | `TargetSpec` unchanged |
| FR-13 | T11 | |
| FR-14 | T03, T09, T10, T11, T12 | |
| FR-15 | T03, T05, T10 | Should |
| FR-16 | T01, T02, T10, T11 | |
| FR-17 | T02, T05, T11, T14 | |
| FR-18 | T02, T14 | |
| FR-19 | T04 | |
| FR-20 | T08, T15 | Should |
| FR-21 | T06, T15 | Should |
| FR-22 | T06, T15 | Should; process item, checked at PR review (convention note in T06) |
| FR-23 | T03, T13 | |
| FR-24 | T03, T12 | |
| FR-25 | T09 | Gate G1 |
| NFR-1 | T07, T08, T12 | Informational timings |
| NFR-2 | T12 | TalkBack speech: Open items 4 |
| NFR-3 | T06, T14 | |
| NFR-4 | T03, T13 | `AI-reviewed only` |
| NFR-5 | T02, T05, T11, T14 | |
| NFR-6 | T01, T04, T15 | |
| NFR-7 | T01, T07, T12 | |
| NFR-8 | T07, T10, T12 | |
| NFR-9 | T08, T14 | API 28 in CI, API 36 phone |
| NFR-10 | T04, T15 | |

**Not covered by a task:** real-world accuracy of specs (BRIEF 1.3, Product Owner); OQ-5 legal advice; FEAT-014 screens; the stale FEAT-011 roadmap row wording (Product Owner's edit, PRD section 1).

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
   d. Device checks need forms in the list; they use an uncommitted local fixture asset, never committed (T12, T14).

## Test record
_Filled in by T08, T09, T12, T13, T14 and T15 (one row per check and device: date, device or CI run, result). Synthetic images and synthetic forms only. No file names, URIs, paths of real files, image content or anything personal seen on the phone; use `[PLACEHOLDER]` for anything sensitive._

| Date | Task | Check | Device / run | Result |
|---|---|---|---|---|
| 2026-11-27 | T13 | Translations es, pt, hi, id, ar | host | Every preset key in all six ARBs, untranslated_messages.json empty, one ai-review-log entry per language with AI-reviewed only (open lists empty; the es open item was settled by rewording presetLoadFailed in English). preset_copy_test.dart gained the six-locale presence-and-translated check; preset_a11y_test.dart 200% test now runs in all 7 supported locales; privacy_copy_test.dart passes. |
| 2026-11-27 | T12 | preset_a11y_test.dart | host | Pass: tap-target, labelled-target and contrast guidelines on the row and the list; en, ar and hi at 200% on 360×640 with no overflow, every spec row reachable and at least 48 dp; ar mirrored, names in FSI/PDI, digits 0-9; one merged button node per spec row with form name, kind, size, KB range, format and notes; country and form headings are header nodes; locale and font-scale change keep search text and scroll. |
| 2026-11-27 | T12 | G2 screenshots: choose, applied with notes, load failure, list, no match with footer, ar list, 200% list | Realme 2 Pro, API 36, debug demo build (integration_test/preset_demo.dart, synthetic Test Form A/B served in place of the asset; shipped asset unchanged) | Taken, ExactSize in front before each capture, under build/preset_g2 (not committed). Rotation locked to portrait for the shots and restored (accelerometer_rotation 1, user_rotation 0); build uninstalled. Seen: ar shows the English fallback until T13, so sentence periods sit at the line start; the demo opens the list as the first route, so no back arrow shows (the real flow pushes it). List open time (NFR-1, informational) not measured: the debug demo build is not representative. Gate G2 passed: the Product Owner accepted the seven screenshots on 2026-11-27. |
| 2026-11-27 | T09 | Gate G1 | design note t09/preset_design.md 0.1 | Passed: the Product Owner accepted the design and its three defaults (full-screen list, nothing drawn while loading, no summary on the applied row) and the English copy with two fixes (presetNoteContent "rules for this image", presetLoadFailed "enter sizes yourself"). |
| 2026-11-27 | T08 | FR-20 fixture run, local | Realme 2 Pro, API 36, debug | Pass: shipped library 0 forms (loaded in 24 ms); Test Form A photo and signature and Test Form B photo READY; planted 4000×4000 px, max 2 KB spec reported (ABOVE_MAX) and passes with an engineReview. Synthetic images in the app support dir, deleted in tearDownAll; build uninstalled. |
| 2026-11-27 | T08 | P1 CI | run 45946777092 | Green: all three jobs; same FR-20 lines on API 28 (load 2 ms). Emulator job 11 min 38 s against 20 min 59 s on the last green run (45886183791), so the added time is below run-to-run noise and could not be measured (tech hypothesis 1–3 min). |
| 2026-11-27 | T06 | Freshness test date | host | The fixture dates are 2026-10-01 (Form A) and 2026-11-20 (Form B), so the CI rule "lastChecked not after today" passes on the fixture. With --today 2027-03-01 both forms would be over 90 days, so the test uses --today 2027-02-01 (A 123 days, listed; B 73 days, not listed). Same check, different date. |

## Instructions for Claude Code
- Read `prd.md`, `tech.md` and ADR-001 before starting a task.
- Implement only the current task, in order; tick its checkbox, commit, and add a line to `docs/CHANGELOG.md` when done. Push only at P1 (T08), P2 (T14) and P3 (T15); run `flutter analyze` and `flutter test` locally first.
- Gates: no list or row UI (T10, T11, T12) before G1; T13 and T14 only after G2; stop at every failing gate and report to the Product Owner.
- UI rule: before designing or building any real UI screen, stop and tell the Product Owner (impeccable, decision 2026-11-20). T09 is that stop. impeccable runs lean: no image comps, no reviewer subagents, one round, one screenshot per key state.
- Data rule: never enter a real form, value, name, issuer or source title unless the Product Owner supplied it for T15; never look one up on the web. Tests use only synthetic "Test Form" entries in country `ZZ`. Never commit fixture data into `assets/presets/presets.json`.
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
