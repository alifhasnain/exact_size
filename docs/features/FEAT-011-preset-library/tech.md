---
id: FEAT-011-TECH
title: Built-in preset library — Technical Plan
status: Approved
version: 2.0
updated: 2026-11-27
links: [FEAT-011, FEAT-005, FEAT-002, FEAT-004, FEAT-014, FEAT-016, FEAT-019, FEAT-013, ADR-001]
---

# FEAT-011 — Technical Plan

## 1. Summary
The library is one JSON asset (`assets/presets/presets.json`) bundled with the app, read once per session through `rootBundle`, parsed by a pure-Dart function into immutable types, and held in a Riverpod `FutureProvider`. Picking a spec calls the existing `TargetFormController.fill(TargetInput)` [Fact](lib/features/target/presentation/target_form_controller.dart, `fill`: "a preset or a saved spec"), so `TargetSpec` and FEAT-005 validation stay untouched. The applied-preset reference (form id, kind) lives in its own session-only provider; the row label is derived from the current field values (`PresetSpec.matches`, revision 2.0; 1.0 compared the validated `TargetSpec`). Search reuses FEAT-005's `cleanNumberText` plus lowercase and a small diacritic fold. CI gets a pure-Dart data test (every PRD section 8 rule, with self-tests), a string test, and one integration test that runs every spec through crop and compression on images generated at test time. No package, Gradle dependency, permission or network call is added.

### Revision 2.0 (PRD 2.0: KB-only specs)
T01–T14 are built against plan 1.0; only T15 (real data) is open. Plan 2.0 adds what a **KB-only spec** (width and height both null, PRD FR-3) needs and nothing else. Detail is in sections 3–9.

**Changes in the built code**
| File | Change |
|---|---|
| `lib/features/presets/domain/preset_types.dart` | `PresetSpec.width` / `height` become `int?` (both or neither, constructor `assert`); `bool get kbOnly => width == null`. The `target` and `input` getters are replaced by `bool matches(TargetInput current)` and `TargetInput applyTo(TargetInput current)` (section 5) |
| `lib/features/presets/domain/parse_library.dart` | Both null → KB-only spec; exactly one null or a non-int → spec skipped and counted; `checkTarget` runs only when both are present |
| `lib/features/presets/presentation/preset_row.dart` | `_applied` uses `spec.matches(state.input)` instead of `result.spec == spec.target`; `_choose` calls `fill(spec.applyTo(current input))`; while a KB-only spec is applied the FR-26 line is the first notice under the key, and the pick announcement adds it |
| `lib/features/presets/presentation/preset_strings.dart` | `summary` passes `presetAnyPixelSize` as `{pixels}` for a KB-only spec |
| `lib/l10n/app_*.arb` | Two new keys (section 6); `@presetSpecRange` / `@presetSpecUpTo` descriptions mention the new `{pixels}` value |
| `test/presets/library_rules.dart` | Both-or-neither rule and message (section 5); self-tests for it and for a passing KB-only spec |
| `test/presets/fixtures/test_library.json`, `integration_test/preset_fixture_data.dart` | New synthetic "Test Form C" with one KB-only photo spec (section 5) |
| `integration_test/preset_fixture_run.dart` | A KB-only spec runs at the fixed synthetic size 600 × 600 px (FR-20, section 8) |
| `integration_test/preset_demo.dart` | `spec.input` → `spec.applyTo(const TargetInput())`; new `kbonly` demo state for the emulator screenshot |
| Tests whose counts move with a third form | `preset_asset_source_test` (forms 2 → 3), `preset_list_screen_test` ("Photo" rows 2 → 3), `freshness_test` (`forms: 3`), fixture run (`hasLength(3)`); `parse_library_test`'s `target` test becomes a `matches` / `applyTo` test |

**Stays as built:** `TargetSpec`, `TargetInput`, `validateTargetInput`, `TargetFormController` including `fill` (no new controller method), `target_screen.dart` (`_copyFromForm` still copies all four controllers; for a KB-only pick it copies width and height back unchanged), `PresetListScreen`, search, providers, `AppliedPreset`, `PresetPick`, loader, enum logs, privacy controls, JSON `schema: 1`, and no new package, permission or network call. `schema` stays 1 because no released build has read a non-empty library (the shipped asset is still `forms: []`), so no reader of schema 1 can meet a null width.

## 2. Architecture impact
New feature module `lib/features/presets/{domain,data,presentation}` (ADR-001 module layout). Changed: `target_screen.dart` (one row slot below the photo line, where the code already reserves it [Fact](target_screen.dart, line 193 comment)), `pubspec.yaml` (one asset entry), `app_*.arb` (new `preset*` keys), CI (`bundle.dart` gains one test), FEAT-016 `claims.md` section 6 (one checklist line).

```mermaid
flowchart LR
  A[assets/presets/presets.json] -->|rootBundle.loadString| S[PresetSource data]
  S -->|parseLibrary pure Dart| L[PresetLibrary]
  L --> P[presetLibraryProvider FutureProvider]
  P --> R[PresetRow on TargetScreen]
  P --> V[PresetListScreen]
  V -->|pop PresetPick| R
  R -->|fill TargetInput| F[targetFormProvider FEAT-005]
  R -->|set| AP[appliedPresetProvider session]
  F --> C[Continue -> validateTargetInput unchanged]
```

## 3. Components
| Component | Layer | Responsibility | New / changed |
|---|---|---|---|
| `preset_types.dart`: `PresetForm`, `PresetSpec`, `PresetSource`, `NotCovered` (sealed), `SpecKind`, `FormCategory`, `PresetLibrary`, `AppliedPreset` | domain | Immutable data; `PresetSpec.kbOnly`; `PresetSpec.matches(TargetInput)` decides the applied label, `PresetSpec.applyTo(TargetInput)` gives the input to `fill` (2.0: replaces the 1.0 `target` / `input` getters) | New (changed 2.0) |
| `parse_library.dart`: `parseLibrary(Object? json) -> PresetLibrary` | domain | Structural read + runtime validity (via `checkTarget` when width and height are present, `validateTarget`); accepts both-null width/height as KB-only; skips a bad spec (incl. one of width/height null), drops a form with no valid spec; counts skips. Ignores unknown fields (forward-compatible) | New (changed 2.0) |
| `preset_search.dart`: `searchKey(String)`, `filterForms(...)` | domain | Cleaning (FEAT-005 `cleanNumberText` + lowercase + diacritic fold), substring match, section grouping and sort | New |
| `preset_asset_source.dart` | data | `rootBundle.loadString('assets/presets/presets.json')` + `jsonDecode` + `parseLibrary`; writes one enum log line on failure or skip | New |
| `preset_providers.dart`: `presetLibraryProvider` (FutureProvider, kept alive), `appliedPresetProvider` (Notifier<AppliedPreset?>, not auto-disposed, no restoration) | state | Session-only holders | New |
| `preset_strings.dart` | presentation | Maps codes to ARB getters (country/category `select`, note keys, kind labels, spec summary; 2.0: "Any pixel size" summary for KB-only); adds bidi isolates around data names | New (changed 2.0) |
| `PresetRow` | presentation | "Choose a form" / "<form> · <kind>" / load-failure message; notes while applied (2.0: FR-26 line first for a KB-only spec); opens list; on pick: fill + sync text controllers + unfocus | New (UI gated, FR-25; changed 2.0) |
| `PresetListScreen` | presentation | Search field, sectioned lazy list, spec rows, notes, empty state, footer | New (UI gated, FR-25) |
| `TargetScreen` | presentation | Hosts `PresetRow`; exposes a callback that copies provider text into its four `TextEditingController`s (same as `_usePhotoSize` does today [Fact](target_screen.dart, `_usePhotoSize`)) | Changed (1.0); unchanged in 2.0 |
| `test/presets/library_rules.dart` + `library_data_test.dart` | test | FR-19 CI rules (strict, incl. CI-only rules), self-tests for AC-7.1..7.3; 2.0: both-or-neither rule | New (changed 2.0) |
| `test/presets/preset_copy_test.dart` | test | FR-15 banned words, key presence and `select` cases in 6 locales, no-storage code scan (AC-8.2) | New |
| `integration_test/preset_fixture_run.dart` | test | FR-20 engine run on generated synthetic images; 2.0: KB-only spec at `kbOnlyTestSize` 600 × 600 px | New (changed 2.0) |
| `test/presets/fixtures/test_library.json` + `integration_test/preset_fixture_data.dart` | test | Synthetic Test Forms A, B and (2.0) C; kept equal by `fixture_data_test.dart` | New (changed 2.0) |
| `tool/presets/freshness.dart` | tool | FR-21: prints form count and forms checked more than 90 days ago | New |

## 4. API contracts
No network API (FR-18). Internal contracts:

```dart
// domain (pure Dart, no Flutter, Riverpod or DI imports — ADR-001)
PresetLibrary parseLibrary(Object? json);            // never throws on bad content; throws FormatException only if root is not {schema:1, forms:[...]}
List<FormSection> filterForms(List<PresetForm> forms, String query, String Function(PresetForm) localTerms, String Function(String country) countryName);
String searchKey(String raw);                        // cut to 100 chars, cleanNumberText, toLowerCase, fold diacritics
bool PresetSpec.matches(TargetInput current);        // 2.0: applied label (FR-13); KB-only ignores width/height
TargetInput PresetSpec.applyTo(TargetInput current); // 2.0: what fill() gets (FR-11); KB-only keeps current width/height

// data
Future<PresetLibrary> loadPresets();                 // async (rootBundle); errors propagate as AsyncError

// presentation result of the list route
final class PresetPick { final String formId; final SpecKind kind; }
```

Log lines (FR-16, the FEAT-016 FR-18 enum-only pattern [Fact](lib/features/privacy/data/uncaught_error_log.dart)): `exactsize.presets outcome=LOAD_FAILED` and `exactsize.presets outcome=SPEC_SKIPPED`. No form id, count, path, exception text or search text. The source takes the existing `LogSink` typedef as a constructor parameter with a `debugPrint` default, as `outcome_log.dart` and `uncaught_error_log.dart` do [Fact](lib/features/compression/data/outcome_log.dart line 6), so tests inject a fake sink. The whole-tree scan covers the new folder without edits, and its print ban applies only to `lib/features/privacy/` [Fact](test/privacy/whole_tree_scan_test.dart lines 8–9, 49).

## 5. Data model
**Format and location (OQ-12): JSON asset `assets/presets/presets.json`**, declared in `pubspec.yaml` `flutter: assets:`. Parsed with `dart:convert` (SDK; no package).

```json
{
  "schema": 1,
  "forms": [
    {
      "id": "test-form-a",
      "name": "Test Form A",
      "issuer": "Test Issuer",
      "country": "ZZ",
      "category": "exam_admission",
      "aliases": ["TFA"],
      "source": { "title": "Test notice 1", "url": "[PLACEHOLDER]" },
      "lastChecked": "2026-11-01",
      "specs": [
        { "kind": "photo", "width": 200, "height": 230, "minKb": 20, "maxKb": 50, "format": "jpeg",
          "notCovered": [ { "code": "dpi", "dpi": 200 }, { "code": "background" } ] },
        { "kind": "signature", "width": 140, "height": 60, "minKb": null, "maxKb": 20, "format": "jpeg",
          "engineReview": "[PLACEHOLDER: Product Owner reason, only if FR-20 reports this spec]" }
      ]
    }
  ]
}
```
The example is synthetic (country `ZZ` is an ISO user-assigned code); it is not a real form.

A **KB-only spec** (2.0, PRD FR-3) keeps both keys with `null`, the same way `minKb` writes "none", so the file shows the choice explicitly and a forgotten key still fails CI as "missing field":
```json
{ "kind": "photo", "width": null, "height": null, "minKb": 10, "maxKb": 200, "format": "jpeg" }
```

**Dart types** (all `final class`, `const` constructors, unmodifiable lists, value equality where compared):
- `enum SpecKind { photo, signature }`; `enum FormCategory { job, examAdmission, visaPassport, other }` (JSON `job`, `exam_admission`, `visa_passport`, `other`).
- `sealed class NotCovered` → `DpiNote(int dpi)`, `BackgroundNote()`, `ContentNote()`. A list of objects, not a map, so CI can detect repeats (`jsonDecode` silently keeps the last duplicate key [Fact](dart:convert behaviour)).
- `PresetSpec { kind, int? width, int? height, int? minKb, maxKb, OutputFormat format, List<NotCovered> notCovered, String? engineReview }`, constructor `assert((width == null) == (height == null))`; `bool get kbOnly => width == null`. (1.0 had non-null width/height and `target` / `input` getters; 2.0 replaces both getters, see below.)
- **Typing choice (2.0): nullable width/height on the one `PresetSpec`**, not a separate `KbOnlySpec` type. Every reader except the summary, `matches`, `applyTo` and the FR-20 run treats the two kinds the same (kind, KB range, format, notes, list row, search), and only 3 call sites construct `PresetSpec` (parser, 2 tests). A sealed pair would touch every reader for no extra safety, since the parser and the `assert` already enforce both-or-neither.
- **`applyTo(current)` (FR-11):** a full spec returns a fresh `TargetInput` of all five values (`minKb` null → `''`), so earlier values are gone (AC-4.1) as in 1.0. A KB-only spec returns `current.copyWith(minKb: minKb == null ? '' : '$minKb', maxKb: '$maxKb', format: format)`, so typed or empty width and height stay exactly as they were (AC-4.7). `PresetRow` passes `ref.read(targetFormProvider).input` and calls the unchanged `fill`. Chosen over a new `TargetFormController` method because FEAT-005's controller, its tests and `TargetScreen._copyFromForm` stay untouched; the merge is a pure, unit-testable domain function.
- **`matches(current)` (FR-13):** each field is read with FEAT-005's own `readNumber(cleanNumberText(text))` and compared with the preset: `format` equal, Max reads `Whole(maxKb)`, Min reads `Empty` when `minKb` is null else `Whole(minKb)`, and, for a full spec only, Width and Height read `Whole(width)` / `Whole(height)`. A KB-only spec ignores Width and Height entirely, so the label stays when they are edited (AC-4.8), empty, or invalid (AC-4.9: `TargetFormState.result` is then `TargetInputInvalid` with width/height errors, which the label no longer looks at). For a full spec this is equivalent to 1.0's `TargetInputValid.spec == spec.target`: the parser only admits valid values, so "every field reads as the preset's whole number" holds exactly when validation passes with an equal `TargetSpec`; leading zeros and native digits still match because the same cleaning is used.
- `PresetForm { id, name, issuer, country, category, List<String> aliases, PresetSource source(title, String? url), DateTime lastChecked (date only), List<PresetSpec> specs }`.
- `PresetLibrary { List<PresetForm> forms; int skipped }`.
- `AppliedPreset { formId, kind }`, `toString()` redacted like `TargetSpec` [Fact](target_spec.dart, `toString`), because it reveals the user's application.

`engineReview` is Product Owner-only data for FR-20 and is never rendered (AC-5.5). `source` and `lastChecked` are exposed through `PresetForm` for FEAT-014 (FR-4); no UI here.

**Runtime vs CI rules.** One parser, two strictness levels:
- Runtime (`parseLibrary`): skips a spec that is structurally wrong, has an unknown kind/format/note code, a repeated kind, exactly one of width/height null or either one not an `int` (2.0; both null = KB-only, accepted), or, when both are present, fails `checkTarget(Target(w, h))` [Fact](lib/features/crop/domain/target_check.dart) or `validateTarget(maxText, minText, format)` [Fact](lib/features/compression/domain/target_validator.dart); skips a form with no valid spec or a missing id/name; logs `SPEC_SKIPPED` once if anything was skipped. Root not an object with `schema == 1` and a `forms` list → `FormatException` → `LOAD_FAILED`.
- CI only (`test/presets/library_rules.dart`, not shipped): **both or neither (2.0)**: keys `width` and `height` stay required; if exactly one is `null` the rule adds "Form [ID] [KIND]: give both width and height, or neither." (PRD section 8) and skips the size check; if both are `null` there is no size check and the existing `maxKb` / `format` rules still apply; if both are present the 1.0 size rule runs unchanged ("size outside engine limits."). New self-tests: Test Form C passes; photo A with `height: null` gives the both-or-neither message; a KB-only spec with `maxKb: null` gives "KB range invalid.". Other CI rules: unknown fields, duplicate or non-slug ids, 16 px floor, `dpi` 1–1200, issuer/source title present, `lastChecked` `YYYY-MM-DD` and not after today, country/category present as `select` cases in `app_en.arb`, no `test-` id or "Test Form" name in the shipped file. Kept out of `lib/` so no dead code ships.

**Storage:** none. Nothing is persisted, so there is no migration; a corrected spec in a new app version replaces the old one with nothing stale on the device.

**Development data.** Until the Product Owner supplies OQ-1 data, the shipped asset holds `"forms": []` and the row is hidden when the library is empty (FEAT-005 alone). All unit, widget and integration tests use `test/presets/fixtures/test_library.json` with synthetic "Test Form A/B/C" entries in country `ZZ`. A CI rule rejects test entries in the shipped file.

**Fixture change (2.0).** Added to `test_library.json` and, identically, to `integration_test/preset_fixture_data.dart` (`fixture_data_test.dart` keeps them equal), used by AC-4.7 to AC-4.9 and the FR-20 run:
```json
{ "id": "test-form-c", "name": "Test Form C", "issuer": "Test Office", "country": "ZZ", "category": "visa_passport",
  "aliases": [], "source": { "title": "Test notice 3", "url": "[PLACEHOLDER]" }, "lastChecked": "2026-11-20",
  "specs": [ { "kind": "photo", "width": null, "height": null, "minKb": 10, "maxKb": 200, "format": "jpeg" } ] }
```
No notes, so note-count assertions stay; `lastChecked` 2026-11-20 keeps the freshness self-test's stale list unchanged (only the count becomes `forms: 3`). Synthetic values; not a real form.

## 6. Integrations
- **FEAT-005:** `TargetFormController.fill`, `targetFormProvider`, `TargetInput.copyWith`, `cleanNumberText`, `readNumber` (2.0: the label reads `state.input` through `readNumber`, no longer `TargetFormState.result`). No change to `TargetSpec`, `TargetInput`, `TargetFormController` or validation; a KB-only pick with empty width/height is caught by FEAT-005's Continue exactly as manual entry (AC-4.9). "Use photo size" (FEAT-005 FR-12) works unchanged after a KB-only pick and keeps the label.
- **FEAT-002 / FEAT-004:** `checkTarget` (only for specs with a size), `validateTarget` (runtime and CI); `CropRenderer`, `SourceProbe`, `CompressionRunner` (FR-20 test only, same calls as `integration_test/crop_to_compression.dart` [Fact]). A KB-only spec at a user-chosen size that cannot reach its maximum gets FEAT-004's normal "can't reach this size" message; no preset-specific handling (PRD section 9).
- **FEAT-014:** reads `PresetForm.source` and `lastChecked`; owns their display.
- **FEAT-016:** whole-tree scan and privacy copy tests must stay green; release checklist gains the FR-21 line.
- **FEAT-019 / gen-l10n (FR-23):** new keys in `app_en.arb`, each with a "FEAT-011 ..." description in the existing style [Fact](app_en.arb, `target*` keys): `presetChooseForm`, `presetApplied` ({form}, {kind}; form already isolated), `presetKindPhoto`, `presetKindSignature`, `presetSpecRange` / `presetSpecUpTo` (numbers pre-formatted, isolated), `presetListTitle`, `presetSearchHint`, `presetNoMatch`, `presetEnterYourself`, `presetNoteDpi` ({dpi} int), `presetNoteBackground`, `presetNoteContent`, `presetNotAffiliated`, `presetLoadFailed`, `presetCountry` (`{code, select, <ISO code>{<name>} ... other{{code}}}`; cases added with the OQ-1 data, never `ZZ`; rule self-tests pass their own key set), `presetCategory` (`select` over the four values). **2.0 adds two keys, no placeholders:**
  - `presetAnyPixelSize` = "Any pixel size". It is passed as the `{pixels}` argument of the existing `presetSpecRange` / `presetSpecUpTo`, so the KB part still reuses `kbRange` / `kbAmount` in an LRI isolate and the format its isolate, exactly as for a full spec. It is UI-language text, so it gets no isolate. Result: "Any pixel size · 10–200 KB · JPEG" / "Any pixel size · up to 200 KB · JPEG" (PRD section 8). Chosen over two new summary keys (`presetSpecAnyRange`, `presetSpecAnyUpTo`): one short phrase to translate instead of two patterns, and the "·" list pattern needs no grammar around it. The `@presetSpecRange` / `@presetSpecUpTo` descriptions gain "pixels is checkPixels, or presetAnyPixelSize for a form with no pixel size".
  - `presetKbOnlyNote` = "This form sets no pixel size. Enter a width and height, or use your photo's size." (FR-26). Description tells translators to name the button as their `targetUsePhotoSize` translation does.
  - Both go through `/l10n-translate` for the 5 languages ("AI-reviewed only") and must pass the existing banned-word, key-presence and FEAT-016 network-word checks (no "offline", "online", "connect").

  Form names, issuers, aliases and source titles are never ARB values. Every locale must also pass FEAT-016's existing rule that no key outside its allow-list talks about the network, which runs over all keys [Fact](test/privacy/privacy_copy_test.dart lines 20–21, 57–60): "Forms could not be loaded" passes; any wording with "offline", "online", "connect" would fail.
- **Third-party SDKs/services:** none. No data leaves the device.

## 7. Security & privacy
- **PCI-DSS / Bangladesh Bank:** N/A. No money, card data, token or credential in data, code or UI. Any future example uses `[PLACEHOLDER]`.
- **Personal data:** the applied preset and the search text are sensitive [Assumption, PRD section 10]. They live only in memory: `appliedPresetProvider` (no persistence, no `restorationId`, like `targetFormProvider` [Fact](target_form_controller.dart, comment on `targetFormProvider`)) and the list screen's `TextEditingController`, disposed on pop. No `PageStorageKey` for search text; scroll position survives configuration changes because the State survives them [Assumption: Flutter's default Android `configChanges` keep the activity].
- **Logs:** two enum lines only (section 4). No form id even though form ids are public data, because a log written after a pick could reveal the choice.
- **Keyboard (FR-9):** `autocorrect: false`, `enableSuggestions: false`, `enableIMEPersonalizedLearning: false`, `autofillHints: null`. These compile on the pinned Flutter 3.50.1: the FEAT-005 fields use exactly these [Fact](target_screen.dart lines 137–140; pubspec `flutter: 3.50.1`). Whether a given keyboard app honours the no-learning flag is up to the keyboard [Hypothesis: Gboard honours `IME_FLAG_NO_PERSONALIZED_LEARNING`; others may not]. `keyboardType` stays `text` so Devanagari and Arabic input work.
- **Clipboard:** the app never writes to it. The search field keeps the system copy/paste menu because paste is a user action (NFR-8 tests a long paste); no `Clipboard` call is added, and the FEAT-016 whole-tree scan already bans one [Fact](test/privacy/whole_tree_scan_test.dart, `_dartRules`).
- **No storage code (AC-8.2):** `preset_copy_test.dart` scans `lib/features/presets/` for `dart:io`, `path_provider`, `shared_preferences`, `restorationId`, `PageStorageKey`, `Clipboard` and fails on any hit.
- **Data file integrity:** bundled, so it is as trusted as the code. No signing now; FEAT-013 adds signing if it is ever unparked (claims.md section 7 (b) [Fact]).
- **No network, permission or dependency (FR-18):** `rootBundle` and `dart:convert` are already in use; `tool/privacy/reviewed_packages.txt` and `android/app/reviewed_dependencies.txt` stay unchanged.

## 8. Requirement coverage
| Requirement | How it is met |
|---|---|
| FR-1 | One asset file; release checklist checks count 15–20. 2.0: a row enters `presets.json` only after the Product Owner has confirmed it against its source; Claude's researched drafts (`t15/draft_forms.md`, `t15/verification.md`) stay in docs and never enter the asset unconfirmed. Software cannot check confirmation; the T15 PR description lists each confirmed form id and the PR review checks it (process) |
| FR-2 | `PresetForm` fields; JSON schema in section 5; CI rules for id, country, category |
| FR-3 | `PresetSpec` with `int? width/height` (both or neither, `kbOnly`), `NotCovered` sealed set; both-null in JSON = KB-only spec, still with `maxKb` and `format` (section 5) |
| FR-4 | `PresetForm.source`, `lastChecked` public fields; no UI here |
| FR-5 | `PresetRow` in the reserved slot of `TargetScreen`; manual fields untouched |
| FR-6 | `filterForms` groups by country, sorts sections by localized name and forms by name; spec summary string; KB-only: `presetAnyPixelSize` in place of `checkPixels` (section 6); widget test on Test Form C's row |
| FR-7 | One tappable row per spec; tap pops `PresetPick` |
| FR-8 | `searchKey` (reuses `cleanNumberText`) over name, issuer, aliases, localized country and category |
| FR-9 | TextField flags (section 7); text in widget State only |
| FR-10 | Empty state with "Enter sizes yourself" = pop with no result |
| FR-11 | `fill(spec.applyTo(current))`: a full spec replaces all five values, a KB-only spec sets Min, Max and format and keeps Width and Height as they were; `_copyFromForm` copies text into the four controllers (unchanged); unfocus. Unit tests on `applyTo` (typed, empty, minKb null) |
| FR-12 | `TargetSpec` unchanged; `appliedPresetProvider` beside `targetFormProvider` |
| FR-13 | Row label derived: `picked` matches form id and kind and `spec.matches(state.input)` (section 5): KB-only compares Min, Max and format only, whatever Width and Height hold, even when the result is invalid; full specs compare all five, equivalent to 1.0. Table test: leading zeros, native digits, empty Min, each field changed and changed back |
| FR-14 | Note strings by code (`presetNoteDpi` with `{dpi}`, `presetNoteBackground`, `presetNoteContent`), icon + text, reuse `BoothNotice` style on the target step |
| FR-15 | Footer key; `preset_copy_test.dart` bans "official", "approved", "guaranteed" in `preset*` strings (en, plus Latin tokens in all locales) and in `aliases` |
| FR-16 | `AsyncError` → row replaced by message; enum log; spec-level skip in `parseLibrary`; no retry |
| FR-17 | Memory-only holders; storage scan; enum-only logs; no recents |
| FR-18 | No new package, permission or network; FEAT-016 gates unchanged |
| FR-19 | `library_data_test.dart` loads the shipped JSON with `dart:io` and applies every section 8 rule; self-tests plant the AC-7.1..7.3 cases; 2.0: both-or-neither rule and message, KB-only spec passes (section 5) |
| FR-20 | `preset_fixture_run.dart` imported as a module by `integration_test/bundle.dart`, like the other tests there [Fact](integration_test/bundle.dart imports), so it runs in the existing API 28 emulator job (`ci.yml`, `flutter test integration_test/bundle.dart`, 2 GB) with no new driver. It probes, renders the default crop at W×H, compresses with the spec's KB range and format (same calls as `crop_to_compression.dart`), and fails on a size, KB or `can't reach` outcome unless `engineReview` is non-empty. Fixtures are generated with `dart:ui` into the app support dir: no real person. 2.0: a KB-only spec renders at the fixed `kbOnlyTestSize = Target(600, 600)`, a named constant with an FR-20 comment in `preset_fixture_run.dart`, and is checked against that size and its KB range. 600 × 600 is the size `crop_to_compression.dart` already proves on this job [Fact](integration_test/crop_to_compression.dart line 70) and sits between small portal sizes and full photo sizes [Assumption]. It proves the KB range and format are reachable at one plausible size, not at every size a user may type; that case falls to FEAT-004's normal message |
| FR-26 | `PresetRow` shows `presetKbOnlyNote` as the first `BoothNotice` under the key (before any `notCovered` notes) whenever the applied spec is KB-only and `matches`, whatever Width and Height hold; icon + text, non-blocking, not on the list row (the list row's "Any pixel size" says it there). The pick announcement for a KB-only spec is the applied label followed by the note. No code proposes or changes a pixel size; Width and Height go through FEAT-005 validation on Continue |
| AC-4.7 | Widget test: Width 300, Height 400 typed, pick Test Form C photo → 300 / 400 / 10 / 200 / JPEG in the fields, row "Test Form C · Photo", FR-26 line shown |
| AC-4.8 | Widget test: after the pick, edit Width, then Height → label stays; edit Min, Max, then format (each restored in between) → "Choose a form" each time |
| AC-4.9 | Widget test: Width and Height empty, pick Test Form C, Continue → FEAT-005 width and height errors as for manual entry, fields stay empty, `onContinue` not called |
| FR-21 | `dart run tool/presets/freshness.dart` + one line in FEAT-016 `claims.md` section 6 |
| FR-22 | Process: PR review checks `docs/CHANGELOG.md` line when the asset changes |
| FR-23 | New `preset*` ARB keys with descriptions; translated via `/l10n-translate`; data names never pass through gen-l10n |
| FR-24 | Data names wrapped in FSI/PDI (U+2068/U+2069) and numbers with units in LRI/PDI, the `_iso` / `_ltr` helpers used by the other message classes [Fact](lib/features/preview/presentation/check_messages.dart lines 51–52); digits formatted 0–9 |
| FR-25 | UI tasks blocked on the impeccable pass; data, loader, search, strings, CI tasks are not. 2.0: the FR-26 line and the "Any pixel size" summary reuse the G1 `BoothNotice` and summary line, so no new design pass is proposed [Assumption]; the Product Owner is still told before that UI task (CLAUDE.md), and one emulator screenshot of the `kbonly` state (en, ar, 200%) checks it |
| NFR-1 | Load starts when the target step opens (row watches the provider); < 100 KB JSON; 20 forms filter in microseconds; timed in the fixture test [Hypothesis: well under 300 ms] |
| NFR-2 | `MergeSemantics` per spec row, `Semantics(header: true)` on headings, 48 dp minimum, icon + text notes, emulator check at 200% |
| NFR-3 | No network code; add "Pick a preset" to FEAT-016 offline matrix (claims.md section 5) |
| NFR-4 | Strings through FEAT-019, `AI-reviewed only`; `select` cases checked in 6 locales |
| NFR-5 | Section 7 |
| NFR-6 | Adding a form = JSON edit; a new country or category = one `select` case in `app_en.arb` (+ translations); no Dart change |
| NFR-7 | Pure-Dart table tests for `searchKey`, `filterForms`, `parseLibrary`, rules; one emulator drive en/ar/hi at 200% |
| NFR-8 | Fuzz test: 1,000 random strings incl. surrogates and controls through `searchKey`/`filterForms`; `LengthLimitingTextInputFormatter(100)`; widget test for a long paste and font-scale/locale change with the list open |
| NFR-9 | No API-level-specific code |
| NFR-10 | Source and date required by CI per form |

## 9. Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| OQ-1 data arrives late; feature built and released empty, or with synthetic forms left in | High | High | Shipped file `forms: []` until data arrives; CI rejects `test-` ids and "Test Form" names in the shipped file; release checklist requires 15–20 forms; tests use only `test/presets/fixtures/` |
| A real spec fails the engine (e.g. tiny max KB at a large size) and the user gets "can't reach this size" | Medium | High | FR-20 run per spec; failure blocks CI until the Product Owner records `engineReview` |
| Generated fixtures are not representative of real photos (noise compresses worse, flat images better) | Medium | Medium | One textured photo-like and one stroke-on-white signature-like image per kind [Hypothesis: brackets real content]; closed test is the real check |
| Stale or wrong spec over time | Certain over time | High | Freshness tool at each release, FEAT-014 display, changelog per change |
| Translators break ICU `select` cases for country/category names | Medium | Medium | `preset_copy_test.dart` checks every `select` case exists in every locale; fallback `other{...}` shows the code, never crashes |
| Keyboard app ignores the no-learning flag | Medium | Medium (privacy) | Flags set; residual risk stated in privacy explainer review [Hypothesis]; no further control exists in app code |
| Row label flicker or wrong label after edits with leading zeros or native digits | Low | Low | Compare validated `TargetSpec`, not raw text; `validateTargetInput` already cleans each field with `cleanNumberText` [Fact](lib/features/target/domain/validate_target_input.dart lines 16, 39) |
| Fixture run lengthens the CI emulator job | Medium | Low | One fixture per spec kind; about 40 runs [Hypothesis: 1–3 min]; inside the existing `bundle.dart` timeout |
| Banned word inside a form name as published | Low | Medium | Open question OQ-T3; names are not scanned by default |
| (2.0) A KB-only pick keeps Width and Height left from an earlier preset or photo, and the user exports at a size the form never asked for while the row reads "<form> · Photo" | Medium | Medium | Decided behaviour (PRD FR-11, FR-13); FR-26 line shown for as long as the spec is applied, not only while Width/Height are empty; OQ-T5 |
| (2.0) A KB-only form's maximum cannot be reached at the size the user chooses (e.g. "Use photo size" on a 12 MP photo) | Medium | Medium | FEAT-004's normal "can't reach this size" message (PRD section 9); FR-20 proves only the 600 × 600 case; closed test |
| (2.0) Applied label logic changes from validated `TargetSpec` to per-field reads and regresses AC-4.4 for full specs | Low | Medium | Equivalence argued in section 5; the 1.0 row tests stay and must pass unchanged; new table test covers both kinds |
| (2.0) FR-26 text names "use your photo's size" while the "Use photo size" button is hidden (photo size not a valid target) | Low | Low | Text still true as advice; FEAT-005 shows why the button is absent; wording owned by the PRD |
| (2.0) Translations of "Any pixel size" read as "any size is accepted" (KB limit ignored) | Low | Medium | The KB range follows on the same line; `/l10n-translate` back-translation review checks the meaning |

## 10. Decisions
- Relies on **ADR-001** (Flutter 3.50.1, Riverpod, get_it/injectable, gen-l10n, module layout).
- **No new ADR.** The bundled data format is cheap to reverse: one file of about 20 records, read only by this app version, nothing persisted on the device, no outside consumer; converting JSON to Dart constants or back is a script of under a day [Hypothesis]. The costly-to-reverse decision is the FEAT-013 remote file schema and signing, which ships to older app versions; that ADR belongs to FEAT-013's tech plan if it is unparked. The `schema: 1` field keeps that door open at no cost.
- **Chosen: JSON asset** over Dart constants. Dart constants would give compile-time field checks and no load path (FR-16 nearly unreachable), but the Product Owner edits Dart syntax, FEAT-013 would need a JSON parser anyway, and FR-19's "unknown or missing fields" and AC-6.2's runtime skip would test a path that cannot happen. YAML was rejected: it needs a package (FR-18) and has implicit typing traps (`NO` → false).
- **Still no new ADR in 2.0.** Nullable width/height in one bundled file of about 20 records, nothing persisted, no outside reader, `schema` unchanged: moving to a separate type or back is under a day [Hypothesis]. Chosen in 2.0 (section 5): nullable fields on `PresetSpec` over a sealed `KbOnlySpec`; a pure `applyTo` merge over a new `TargetFormController` method; per-field `matches` over validated `TargetSpec` equality (the latter cannot see Min/Max/format when Width/Height are invalid, which AC-4.9 needs); one `presetAnyPixelSize` phrase over two new summary patterns.
- **Country and category names as ICU `select` messages** (`presetCountry`, `presetCategory`) instead of one key per country, so NFR-6 holds (no Dart change for a new country).

## 11. Deliberately left out
- Locale-aware collation for section sorting: Dart has no Collator; sort by code units of the localized name [Fact](dart:core `String.compareTo`). Upgrade if testers find the order odd.
- Full Unicode normalisation: a small fold table for Latin precomposed letters (es, pt, id) and Arabic harakat; no NFD [Hypothesis: enough for 15–20 names].
- Signing, remote update, schema migration (FEAT-013).
- Source-note UI, date display, "check your notice" (FEAT-014).
- Recents, favourites, device-region ordering, "Common sizes" (PRD OQ-6, OQ-15).
- A CI check that `docs/CHANGELOG.md` changes with the asset (review is enough at this size).
- (2.0) Any suggested, default or "typical" pixel size for a KB-only spec (PRD FR-26 forbids it); a separate KB-only type; a kind-specific or multi-size FR-20 run for KB-only specs (one fixed 600 × 600 size); the FR-26 line on the list row; a `schema` bump.
- `tasks.md` (Stage 7, `/handoff`).

## 12. Open questions
- **OQ-T1 Empty library behaviour during development.** Default: hide the row when there are zero forms (not the load-failure message, which would be untrue). Product Owner may prefer the release to be blocked instead; the checklist already blocks it.
- **OQ-T2 Fixture images.** Default: generated at test time with `dart:ui` (no binary committed, no real person). Alternative: commit two small synthetic files under the existing fixture push.
- **OQ-T3 Banned words in published names.** Default: scan UI strings and `aliases` only; names, issuers and source titles stay as published. If the Product Owner wants names scanned, a real name containing "Official" would need an exception list.
- **OQ-T4 Where the "meets spec" wording risk lands** stays PRD OQ-9 (no FEAT-006 change).
- **OQ-T5 (2.0) Width/Height left over before a KB-only pick.** Default: as the PRD decided (keep them, FR-26 line always shown while applied). Alternative for the Product Owner, a PRD change: clear Width and Height on a KB-only pick so the user must enter them (FEAT-005 then asks on Continue); safer against a stale size, but drops AC-4.7's "Width 300 and Height 400 stay".

## Effort
| Work | Days [Assumption] |
|---|---|
| Types, `parseLibrary`, loader, providers, enum log, unit tests | 1.0 |
| CI data rules + self-tests, copy/storage test, freshness tool, checklist line | 1.0 |
| Search key, filter, fuzz test | 0.5 |
| ARB keys (en) + `/l10n-translate` for 5 languages | 0.75 |
| Target-step wiring (fill, controller sync, derived row, notes) | 0.5 |
| impeccable pass (lean) | 0.5 |
| List screen + row UI, RTL, 200%, TalkBack, emulator states | 2.0 |
| FR-20 fixture integration test and CI wiring | 1.0 |
| **Total (1.0, built)** | **7.25 days ≈ 1.45 pw**, inside PRD OQ-17's 1.2–1.8 pw; Product Owner sourcing time is extra |

**2.0 delta (KB-only specs), on top of the built 1.0 work**
| Work | Days [Assumption] |
|---|---|
| `PresetSpec` nullable size, `kbOnly`, `applyTo`, `matches`, parser both-or-neither, unit and table tests | 0.5 |
| CI both-or-neither rule + self-tests | 0.25 |
| `PresetStrings` summary, `PresetRow` FR-26 line and announcement, widget tests AC-4.7..4.9 | 0.5 |
| 2 ARB keys (en) + `/l10n-translate` for 5 languages | 0.25 |
| Test Form C in both fixtures, count ripples, FR-20 KB-only size, `preset_demo` state | 0.25 |
| Emulator check of the `kbonly` state (en, ar, 200%) | 0.25 |
| **Delta** | **2.0 days ≈ 0.4 pw**; new total 9.25 days ≈ 1.85 pw, just above PRD OQ-17's 1.2–1.8 pw range. T15 data entry is unchanged and still Product Owner-paced |

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-27 | First draft |
| 1.0 | 2026-11-27 | Approved by the Product Owner (/approve FEAT-011-TECH); OQ-T1..T3 defaults stand |
| 2.0 | 2026-11-27 | Scope change for PRD 2.0 (KB-only specs): Revision 2.0 note; nullable width/height, `applyTo` / `matches` replace `input` / `target`; parser and CI both-or-neither; `presetAnyPixelSize`, `presetKbOnlyNote`; FR-26 line in `PresetRow`; Test Form C fixture; FR-20 KB-only size 600 × 600; coverage for FR-1, FR-3, FR-6, FR-11, FR-13, FR-19, FR-20, FR-26, AC-4.7..4.9; risks, OQ-T5, effort delta; no ADR. Status Under Discussion |
| 2.0 | 2026-11-27 | Approved by the Product Owner (/approve FEAT-011-TECH); OQ-T5 default stands (keep Width and Height) |
