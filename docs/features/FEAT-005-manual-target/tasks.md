---
id: FEAT-005-TASKS
title: Manual target entry (W×H, KB min/max, format) — Implementation Tasks
status: Approved
version: 1.0
updated: 2026-11-23
links: [FEAT-005, FEAT-005-TECH, ADR-001, ADR-003, FEAT-001, FEAT-002, FEAT-004, FEAT-006, FEAT-011, FEAT-019]
---

# FEAT-005 — Implementation Tasks

Milestone: R1 Phase A — core. Work top to bottom, one task at a time.

Sizes: **S** ≈ 0.25 day, **M** ≈ 0.5 day, **L** ≈ 1 day; each task is one PR.
Module paths follow ADR-001: `lib/features/target/{domain,presentation}` (no data layer: no I/O), plus `lib/app_flow.dart`. Tests mirror them under `test/`; emulator tests in `integration_test/`; fakes in `test_support/`.

**Already built, reused, not planned again:** `checkTarget`, `Target`, `TargetDimensionsMessage`, `maxTargetSide`, `maxTargetPixels`, `Orientation.fromExif`, `CropMath.coverWidth`, `CropScreen`, `CropController`, `PreviewDecoder`, `CropMessages` (FEAT-002); `validateTarget`, `TargetMessage`, `maxKbLimit`, `minMaxKb`, `OutcomeMessages`, `compressionControllerProvider`, `CompressionRequest`, `PixelBuffer` (FEAT-004, ADR-003); `PickController`, `PickedImage`, `PickScreen` (its `popUntil(isFirst)` + `CropController.end()` on a new image), `FakeSystemPicker` (FEAT-001); the privacy tests `test/features/compression/no_network_imports_test.dart`, `test/features/crop/crop_privacy_test.dart`, `test/features/pick/pick_privacy_test.dart`; `TolerantGoldenComparator`; `test_driver/push_fixtures_driver.dart`, `test_driver/share_intent_driver.dart` + `integration_test/pick_share_test.dart`; synthetic fixtures in `test_support/crop_fixtures/`; gen-l10n with 6 languages; the CI API 28 emulator job (`.github/workflows/ci.yml`).

**Test devices:** local `Medium_Phone_API_36.1` (2 GB, keep it running between tasks; start it only if `adb devices` shows none). API 28 runs only in the CI emulator job; no local API 28 image (as FEAT-001 T19). New `*_test.dart` files run from `integration_test/bundle.dart`; a test that needs pushed fixtures or a driver gets its own `flutter drive` line in the same `script:` block of `ci.yml`.

**Emulator test rule:** files run under `flutter drive` use `testWidgets` only. Plain `test()` failures are not reported under `flutter drive`, so a failing check would pass silently.

**Decisions from FEAT-005-TECH section 12 used here (approved with tech.md v1.0):**
- OQ-T1: FEAT-005 owns the flow wiring (`app_flow.dart`), with a dev-only stand-in after crop until FEAT-006 (T01, T10, T11).
- OQ-T2: the field shows the FR-4 (a)–(c) result as typed (leading zeros kept, a long digit string not rewritten, only read as 999,999,999); a long paste is refused by the length cap (T03, T12).
- OQ-T3: the upscale notice reuses `cropNoticeEnlarged`; no `targetHintEnlarged` key (T08, T14).
- OQ-T4: the field's system Copy/Cut menu stays (T12).
- OQ-T5: the guarded release replaces the placeholder's release-on-any-pop (T01).
- OQ-T6: FEAT-004's validator is left unchanged (no task).

PRD OQ-1, OQ-3, OQ-7 and OQ-10 are answered by the Product Owner at gate G1. If there is no answer, the PRD defaults apply: session memory, JPEG preselected, "Use photo size" shown, FEAT-005 works alone.

## Decision gates
| Gate | Task | Passes when | If it fails |
|---|---|---|---|
| G1 Target screen design | T09 | A lean impeccable pass is done (Material 3, no image comps, no reviewer subagents, one round). The Product Owner has seen it and answered PRD OQ-1, OQ-3, OQ-7 and OQ-10, or said "defaults". The design reference and its date are recorded | No visible UI work starts (T10–T15). Non-visual tasks T01–T08 may run |
| G2 Design check | T15 | The Product Owner has seen one emulator screenshot each of empty, valid, error, ar RTL and 200% font, and accepts them or names fixes. One look, no multi-round critique | Fixes go into T15 before T17 starts. A change of scope means a PRD change, not a fix |
| G3 Emulator run | T18 | Every checklist row passes on API 36.1, and the CI API 28 job is green for `target_flow.dart`, the share drive and `bundle.dart`. Required: no crash, no value or path in logcat, no new file in app storage, airplane mode works, TalkBack reads every field and error, no clipping at 200% in en/ar/hi, empty start after `am kill` | A privacy, crash or accessibility miss means stop and report to the Product Owner. A Gboard flag miss is recorded as residual risk R1 for FEAT-016 copy, not a stop |

## Tasks

### - [ ] FEAT-005-T01 — Flow fix: guarded release on the target route (R2, OQ-T5)
- **Implements:** FR-1 (one target step per accepted image), NFR-8 · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** M
- **Scope:** new `lib/app_flow.dart` with `openTargetStep(BuildContext, PickedImage)`. It pushes the target route wrapped in `PopScope`. `onPopInvokedWithResult(didPop)` calls `pickController.release()` and `cropController.end()` **only if `identical(ref.read(pickControllerProvider).current, image)`**. Until T12 the route body stays the dev-only placeholder text (moved from `lib/app.dart`). `lib/app.dart`: `onPicked: openTargetStep`; delete `_NextStepPlaceholder` and `_openNextStep`. Widget test `test/app_flow_test.dart` uses `FakeSystemPicker`, a fake probe and the camera `TempFiles` fake, as in `pick_screen_test.dart`:
  - (a) camera image A accepted, then target step open, then image B accepted (new pick, and a share-origin pick): the `popUntil` pop does not release B, B stays `current`, B's camera file still exists, A's file is deleted (by `PickController`), and exactly one target route is on top.
  - (b) Back on the target step with A releases A and empties the camera folder (start-over, FEAT-001 FR-11).
  - Run test (a) once against the old placeholder to show it fails there, and note the result in the PR.
- **Done when:**
  - `flutter test test/app_flow_test.dart` passes. The PR shows test (a) failing on the pre-fix tree.
  - The existing `pick_screen_test.dart` and `pick_controller_test.dart` pass unchanged.
  - FEAT-001-T25's share drive (`flutter drive --driver test_driver/share_intent_driver.dart --target integration_test/pick_share_test.dart`) passes on API 36.1 and in the CI API 28 job. The result is recorded in the Test record.

### - [ ] FEAT-005-T02 — Domain types: `TargetSpec`, `TargetInput`, `TargetField`, `TargetError`, results
- **Implements:** FR-2 (format default `jpeg`), FR-9, FR-14 (redaction) · **ADRs:** ADR-001, ADR-003
- **Depends on:** —
- **Size:** S
- **Scope:** `lib/features/target/domain/target_spec.dart` and `target_input.dart` per tech section 4:
  - `TargetSpec` with `dimensions` → `Target` and `request(PixelBuffer)` → `CompressionRequest`. The buffer moves in (ADR-003).
  - `==`/`hashCode`.
  - `TargetInput` with `copyWith`, `format` defaulting to `jpeg`.
  - Sealed `TargetError` (`PixelRangeError`, `PixelsNotWhole`, `KbError`) and `TargetInputResult` (`TargetInputValid`, `TargetInputInvalid` with `firstField` in the order W, H, Min, Max).
  - Redacted `toString` on `TargetSpec` and `TargetInput`.
  - Imports only crop and compression domain types; no Flutter or Riverpod.
- **Done when:** unit tests pass. `dimensions` and `request` map every field. `firstField` follows W, H, Min, Max for every subset of fields. `toString` of a spec and an input built from synthetic test numbers (for example 4321 and 987) contains neither number.

### - [ ] FEAT-005-T03 — `cleanNumberText` and `readNumber`
- **Implements:** FR-4, NFR-4 (native digits), NFR-7, NFR-8 · **ADRs:** —
- **Depends on:** T02
- **Size:** S
- **Scope:** `lib/features/target/domain/number_text.dart`:
  - FR-4 (a): remove `\s` and the bidi controls listed in the PRD.
  - FR-4 (b): map Arabic-Indic, Extended Arabic-Indic, Devanagari and Bengali digits to 0–9.
  - FR-4 (c): map `,` `٫` `٬` to `.`.
  - `readNumber` returns `Empty`, `Whole(int)`, `NotWhole` or `NotNumber`. `Whole` matches `^[0-9]+$`; leading zeros are stripped before the 9-digit cap, and more than 9 significant digits gives 999,999,999. `NotWhole` is digits plus at least one `.`. Anything else is `NotNumber`.
- **Done when:** a table unit test passes for `٣٠٠`, `۳۰۰`, `३००`, `৩০০` → 300; `0300` and `0000000000300` → 300; bidi-wrapped and NBSP/U+202F-padded `300` → 300; `7.5`, `7,5`, `1,000`, `1.000`, `1.000.000`, `٧٫٥`, `١٬٠٠٠` → `NotWhole`; `-5`, `+5`, `0x10`, `1e3`, `300x300`, `३०० px`, `KB` → `NotNumber`; 10, 20 and 40 digits → `Whole(999999999)`; `''` and whitespace-only → `Empty`. The cleaned text keeps leading zeros (OQ-T2).

### - [ ] FEAT-005-T04 — `validateTargetInput`: per-field composition, section 9 table, fuzz, benchmark
- **Implements:** FR-5, FR-6, FR-8 (result and first field), FR-9, NFR-1, NFR-5, NFR-7, NFR-8 · **ADRs:** —
- **Depends on:** T03
- **Size:** M
- **Scope:** `lib/features/target/domain/validate_target_input.dart`, implementing the tech section 3 algorithm:
  - W/H go through `checkTarget(Target(n, 1))` per side, then `checkTarget(Target(w, h))` → `tooManyPixels` on Width.
  - Max goes through `validateTarget(maxText: …)`.
  - Min goes through `validateTarget` with Max (or `maxKbLimit` when Max is invalid). `minNotBelowMax` is dropped when Max is invalid.
  - Format is passed as `OutputFormat.name`.
  - All errors are returned together.
  - One-line comment at the Min call site about relying on `validateTarget` checking Max first (R3).
  - No limit literals.
- **Done when:** `test/features/target/domain/validate_target_input_test.dart` passes:
  - every PRD section 9 row without UI, each message pinned to its field (tech section 8 testing table);
  - 6000×4000 accepted; 6001×4000 and 10,000×2,401 refused;
  - Max 1, 2, 10,240 and 10,241;
  - Min only; Min 0; Min = Max; 49/50;
  - all fields empty → W/H and Max errors, `firstField` = width.
  - A seeded 1,000-string fuzz never throws, and every `TargetInputValid` passes `checkTarget` and `validateTarget`.
  - 10,000 validations finish in under 50 s total, i.e. ≤ 5 ms each (NFR-1, informational on CI hardware).
  - A test asserts that the messages carry `maxTargetSide`, `maxTargetPixels` and `maxKbLimit` values read from the shared constants (NFR-5). A grep test finds no `10000`, `24000000` or `10240` literal in `lib/features/target/`.

### - [ ] FEAT-005-T05 — `targetHints` (photo line, "Use photo size", upscale, very small)
- **Implements:** FR-11, FR-12, FR-13 (logic) · **ADRs:** —
- **Depends on:** T04
- **Size:** S
- **Scope:** `lib/features/target/domain/target_hints.dart`:
  - `smallTargetHintPx = 16` (hint threshold, not a limit).
  - Oriented photo size via `Orientation.fromExif(...).orientedSize`.
  - `canUsePhotoSize = checkTarget(Target(photo)) == null`.
  - `enlarges` via `CropMath.coverWidth` (> 1.0).
  - `verySmall` when W < 16 or H < 16.
  - Hints are computed only from valid W/H.
- **Done when:** unit tests pass for:
  - an EXIF-6 4000×3000 source → photo 3000×4000;
  - a 200×200 source with a 300×300 target → `enlarges`; 300×300 → not `enlarges`;
  - a 12,000-wide source → `canUsePhotoSize` false; a 4000×3000 source → true;
  - 15 px → `verySmall`, 16 px → not;
  - invalid W/H → no `enlarges` and no `verySmall`.

### - [ ] FEAT-005-T06 — `targetFormProvider` / `TargetFormController`
- **Implements:** FR-2 (default), FR-7 (reveal rules), FR-9 (`fill`), FR-10, FR-12 (`usePhotoSize`) · **ADRs:** ADR-001
- **Depends on:** T04, T05
- **Size:** S
- **Scope:** `lib/features/target/presentation/target_form_controller.dart`:
  - Riverpod 3 `NotifierProvider`, not auto-disposed. State is `TargetFormState { TargetInput input; Set<TargetField> revealed; }`.
  - Methods: `setText`, `setFormat`, `reveal`, `revealAll`, `fill`, `usePhotoSize(SourceInfo)`, `startForPhoto()` (keeps values, clears `revealed`).
  - A getter for the visible errors: `validateTargetInput(input)` filtered by `revealed`.
  - No persistence, no `restorationId`.
- **Done when:** unit tests with a `ProviderContainer` pass:
  - a fresh container is empty with JPEG;
  - `startForPhoto` keeps the texts and clears `revealed`;
  - an error is hidden until `reveal` or `revealAll`, then follows every `setText` and disappears when the value is fixed;
  - `fill` replaces all fields;
  - `usePhotoSize` writes the oriented size, and does nothing when `canUsePhotoSize` is false;
  - a new container (process death) starts empty.

### - [ ] FEAT-005-T07 — Target privacy static tests
- **Implements:** FR-14, NFR-3, NFR-6 · **ADRs:** ADR-001
- **Depends on:** T01, T02
- **Size:** S
- **Scope:** new `test/features/target/target_privacy_test.dart`. It scans `lib/features/target/` and `lib/app_flow.dart` with the same pattern as the existing privacy tests:
  - The no-network import ban and the FEAT-002 write-API ban.
  - Also banned: `shared_preferences`, `dart:io`, `print(`, `debugPrint(`, `log(`, the outcome-log classes, `restorationId`, `RestorationScope` and `Clipboard.setData`.
  - `lib/features/target/domain/` imports no `package:material_ui`, `package:flutter*` or `package:flutter_riverpod`.
- **Done when:** the test passes on the current tree. The PR shows it failing when a forbidden token is added to a scratch file in each scanned location.

### - [ ] FEAT-005-T08 — English strings and `TargetMessages`
- **Implements:** FR-5 (new pixel message), FR-15, NFR-4 (isolates, locale numbers), NFR-5 · **ADRs:** ADR-001
- **Depends on:** T02, T05
- **Size:** S
- **Scope:**
  - `lib/l10n/app_en.arb`: add `targetPixelsNotWhole`, `targetLabelWidth`, `targetLabelHeight`, `targetLabelMin`, `targetLabelMax`, `targetOptional`, `targetUnitPx`, `targetUnitKb`, `targetFormatLabel`, `targetPhotoSize` ({size}), `targetUsePhotoSize` and `targetHintVerySmall`, each with an `@` description and ICU placeholders, no concatenation.
  - Reuse `cropNoticeEnlarged` (OQ-T3), `pixelSize`, `cropButtonContinue` and the FR-15 list. G1 may still ask for a separate Continue key; T12 adds it then.
  - `lib/features/target/presentation/target_messages.dart` maps `TargetError` through `CropMessages.target` and `OutcomeMessages.target`. Numbers and units go in U+2068/U+2069 isolates (as `CropMessages._iso`), formatted with `NumberFormat(localeName)`.
- **Done when:** `flutter gen-l10n` passes. A unit test checks that every `TargetError` and hint has a non-empty English string. The existing "no literal numbers in ARB" tests pass with the new keys added to their scope. The PR lists the new keys.

### - [ ] FEAT-005-T09 — Target screen design pass with the Product Owner (impeccable, lean) — gate G1
- **Implements:** FR-16; prerequisite for FR-1–FR-3, FR-7, FR-8, FR-11–FR-13, NFR-2, NFR-4 (visual) · **ADRs:** —
- **Depends on:** T06, T08
- **Size:** M (developer side; the Product Owner's time is not counted)
- **Scope:** **Stop and tell the Product Owner before any visible work.**
  - One short impeccable pass on Material 3. Rules: no image comps, no reviewer subagents, no multi-round critique.
  - Inputs:
    - Elements: photo line, W/H row, Min (optional), Max, format segmented control, "Use photo size", hints, Continue.
    - The crop step's decode-progress and decode-error states (new visible states in T10).
    - States: empty, filled/valid, error (all fields), hints shown.
    - Constraints: TalkBack labels with unit and optional/required; errors with icon and text, not colour alone; ≥ 48 dp; 200% font at 360×640 with the keyboard open, scroll, and the W/H row turning into a column; RTL mirroring with LTR digits.
    - The T08 strings.
  - Questions for the Product Owner:
    - PRD OQ-1: remember the last target? (A none, B session (default), C persisted).
    - OQ-3: default format (JPEG default, or none).
    - OQ-7: "Use photo size" (default yes).
    - OQ-10: screen shape with FEAT-011 (default: FEAT-005 alone, room left for a preset entry).
  - Define the five verification screenshots for G2: empty, valid, error, ar RTL, 200% font.
  - Effects of non-default answers:
    - OQ-1 = A: `startForPhoto` clears the values, a one-line change in T12.
    - OQ-1 = C: needs a PRD change and overlaps FEAT-012, so stop.
    - OQ-3 = none: `format` becomes nullable and `chooseJpegOrPng` becomes reachable; T02/T06 follow-up inside T12.
    - OQ-7 = no: the "Use photo size" part of T14 is dropped and its key removed.
- **Done when:** the design reference (file or link, synthetic content only) and its date are in the PR and `docs/CHANGELOG.md`. The Product Owner's answers (or "defaults") to OQ-1, OQ-3, OQ-7 and OQ-10 are recorded in the PRD through the Product Owner's flow. Gate G1 is recorded.

### - [ ] FEAT-005-T10 — Crop step: preview decode, `CropScreen`, "Choose another photo"
- **Implements:** FR-1 (hand-over to crop), FR-9, FR-10 (Back from crop) · **ADRs:** ADR-001
- **Depends on:** T09 (G1), T01, T02
- **Size:** M
- **Scope:** `lib/app_flow.dart` `_CropStep(image, spec)`:
  - Decode with `PreviewDecoder`, showing progress after 500 ms.
  - `PreviewErr` shows `CropMessages.reason` with "Choose another photo", laid out per the G1 design. That action calls `release()` and `cropController.end()` first, then `popUntil(isFirst)`.
  - On success, show `CropScreen(src: image.handle, info: image.info, preview, target: spec.dimensions, …)`.
  - Dispose the `ui.Image` when the route goes.
  - Re-entry with the same spec keeps the crop; a changed spec re-initialises it (FEAT-002 behaviour).
- **Done when:** widget tests in `test/app_flow_test.dart` pass with a fake decoder:
  - no progress at 499 ms, progress at 500 ms;
  - a decode error shows the reason, and "Choose another photo" releases exactly once (no second release from the T01 guard);
  - the preview is disposed on pop;
  - a changed spec re-inits the crop, the same spec keeps it.

### - [ ] FEAT-005-T11 — Crop → compression hand-off and dev-only stand-in
- **Implements:** FR-9 (`TargetSpec.request`) · **ADRs:** ADR-003
- **Depends on:** T10
- **Size:** S
- **Scope:** `CropScreen.onContinue(pixels)` → `compressionController.start(spec.request(pixels))`. Ownership of the buffer moves (ADR-003). Then push `_AfterCropStandIn`: dev-only, not shipped, `shortcut:` comment naming FEAT-006. It shows the run state via `announcementFor`. Popping it calls `compressionController.cancel()`.
- **Done when:** widget test with a fake compression controller: `start` is called once with a request carrying the spec's `minKb`, `maxKb` and `format` and the same buffer; pop calls `cancel()` once; the buffer is not freed by the flow (FEAT-004 owns it).

### - [ ] FEAT-005-T12 — `TargetScreen`: fields, keyboard, focus order, format, hand-over
- **Implements:** FR-1, FR-2, FR-3, FR-4 (clean on blur), FR-8 (valid path), FR-9, FR-10, FR-14 (no restoration), NFR-6, NFR-8 (length cap) · **ADRs:** ADR-001
- **Depends on:** T09 (G1), T06, T08, T10
- **Size:** L
- **Scope:** `lib/features/target/presentation/target_screen.dart`, built to the G1 design:
  - Four `TextField`s with `keyboardType: TextInputType.number`, `autocorrect: false`, `enableSuggestions: false`, `enableIMEPersonalizedLearning: false`, `autofillHints: null`, no spell check, no `restorationId`, and only `LengthLimitingTextInputFormatter(32)` as formatter.
  - Field text direction is `TextDirection.ltr`.
  - `textInputAction` is next, next, next, done. `onSubmitted` focuses the next node in W, H, Min, Max; done unfocuses.
  - On blur, write `cleanNumberText` into the controller and call `reveal(field)`.
  - `SegmentedButton<OutputFormat>`, single select, empty selection not allowed.
  - Continue is always enabled. On valid input it calls `onContinue(spec)` → `_CropStep`.
  - Controllers are seeded from the provider, and `startForPhoto()` runs on open.
  - `openTargetStep` now pushes `TargetScreen` instead of the placeholder text.
  - Copy/Cut menu kept (OQ-T4).
- **Done when:** `test/features/target/presentation/target_screen_test.dart` passes:
  - AC-1.1: empty with JPEG on a fresh container.
  - AC-1.2: 300/300/–/100 → one `TargetSpec(300, 300, null, 100, jpeg)`, with exactly 1 non-typing tap (Continue).
  - AC-1.3: Next/Done order in en.
  - AC-2.1: 20/50 handed on.
  - AC-4.1 and AC-4.2: PNG selected; the selection cannot be cleared.
  - AC-5.1: `٣٠٠` shows `300` after blur.
  - AC-8.1: Back from a fake crop route keeps the values.
  - AC-8.2: values kept across a locale switch.
  - A 10,000-character paste is truncated to 32 without an error.
  - `tester.testTextInput` setup shows learning, suggestions and autocorrect off. [Hypothesis: exact JSON keys; record them in the PR.]
  - `test/app_flow_test.dart` (T01) still passes.

### - [ ] FEAT-005-T13 — Errors: reveal rules, all errors, focus and TalkBack announcement
- **Implements:** FR-7, FR-8 (invalid path), NFR-2 (announcement) · **ADRs:** —
- **Depends on:** T12
- **Size:** S
- **Scope:** `target_screen.dart`:
  - Per-field error text with an error icon (not colour alone). W/H messages sit under the size row.
  - Errors are hidden while the user first types, shown on blur or Continue, and live after that.
  - Continue on invalid input: `revealAll()`, focus `firstField`, and announce only the first message with `SemanticsService.sendAnnouncement` (crop's pattern, R7).
- **Done when:** widget tests pass:
  - AC-2.2 and AC-2.3 (Min ≥ Max message at Min);
  - AC-3.1 (focus on Width, the announcement captured once with the size message, nothing handed on);
  - AC-3.2, AC-3.3, AC-3.4 (error clears on the fixing keystroke);
  - AC-3.5 (all messages at once);
  - no error while typing in a fresh field.

### - [ ] FEAT-005-T14 — Photo line, "Use photo size" and non-blocking hints
- **Implements:** FR-11, FR-12, FR-13 (UI) · **ADRs:** —
- **Depends on:** T13
- **Size:** S
- **Scope:**
  - "Your photo: W × H px" via `targetPhotoSize`/`pixelSize` in isolates.
  - A "Use photo size" button, shown only if `canUsePhotoSize` (and if G1 kept OQ-7).
  - `cropNoticeEnlarged` and `targetHintVerySmall` in a polite live region. They never block Continue.
- **Done when:** widget tests pass:
  - AC-7.1: a 200×200 source with a 300×300 target shows the notice and Continue hands on.
  - AC-7.2: 10×10 shows the very-small notice.
  - AC-7.3: 4000×3000 fill; a 12,000-wide source hides the button.
  - AC-7.4: EXIF 6 shows 3000×4000.

### - [ ] FEAT-005-T15 — Accessibility, 200% font, RTL, goldens — gate G2
- **Implements:** FR-16 (verification), NFR-2, NFR-4 · **ADRs:** —
- **Depends on:** T14
- **Size:** M
- **Scope:**
  - Labels with unit and optional/required in `InputDecoration`.
  - Touch targets of at least 48 dp.
  - `SingleChildScrollView` with `resizeToAvoidBottomInset`.
  - The W/H row turns into a column at large text scale or narrow width.
  - Material 3 roles only.
  - Arabic: mirrored layout, LTR digits and units in isolates.
  - Host goldens with `TolerantGoldenComparator`: en and ar × empty, filled and error at 360×640, plus 200%.
  - Take one emulator screenshot (API 36.1, synthetic fixture photo) each of empty, valid, error, ar RTL and 200% font, and show them to the Product Owner.
- **Done when:**
  - Widget tests pass for: AC-1.3 in ar (reading order); AC-4.3 (segments expose `selected` and `inMutuallyExclusiveGroup`); AC-5.4 (mirrored, digits LTR); AC-6.1 (text scale 2.0 at 360×640 with a 300 dp bottom inset: no overflow, Continue reachable by scroll); AC-6.2 (semantics label carries label, unit, optional/required, value and error); AC-6.3 (every control ≥ 48 dp).
  - Goldens pass.
  - The five screenshots are in the PR (not committed unless the Product Owner asks).
  - Gate G2 is recorded.

### - [ ] FEAT-005-T16 — Translate FEAT-005 strings (es, pt, hi, id, ar)
- **Implements:** FR-15, NFR-4 · **ADRs:** —
- **Depends on:** T08, T15 (strings final after G1/G2)
- **Size:** M (not counted in the tech estimate: FEAT-019 work)
- **Scope:**
  - Run `/l10n-translate <lang>` one language at a time for the T08 keys (and any key T12 added). Use only the vendored `localize-*` skills and the CLAUDE.md variants: pt-BR, es-419, and MSA with Western digits.
  - Send only app strings to the model, never user data or target values.
  - Keys, ICU syntax and placeholder names stay identical to `app_en.arb`. No bidi marks in placeholders.
  - Status is `AI-reviewed only`. Never write "native-quality" or "native-reviewed".
- **Done when:**
  - All five `app_*.arb` files contain every FEAT-005 key.
  - The mechanical checks pass.
  - One entry per language is in `docs/l10n/ai-review-log.md` with status `AI-reviewed only`.
  - `flutter gen-l10n` reports no untranslated FEAT-005 keys.
  - A widget test renders the target screen in all 6 locales without a missing-key fallback.

### - [ ] FEAT-005-T17 — Emulator drive `target_flow.dart` and CI line
- **Implements:** FR-1, FR-10, FR-14, NFR-2, NFR-4, NFR-7, NFR-9 · **ADRs:** ADR-001, ADR-003
- **Depends on:** T11, T15, T16
- **Size:** M
- **Scope:**
  - New `integration_test/target_flow.dart` (**`testWidgets` only**), run with `test_driver/push_fixtures_driver.dart`. It uses a synthetic fixture photo through `FakeSystemPicker` and the real `SourceProbe`.
  - Flow steps: target, then crop. Back keeps the values; a changed size re-inits the crop; Continue reaches compression READY on the stand-in. A new photo keeps the values with errors hidden.
  - en, ar and hi at text scale 2.0 (set in-test), with one screenshot per state (empty, valid, error). The driver needs an `onScreenshot` handler if it lacks one [Assumption]. Screenshots are saved under `build/`, not committed.
  - App-storage listing before and after shows no new file except FEAT-004's temp output, which is deleted on stand-in pop.
  - CI: add to the `script:` block of `.github/workflows/ci.yml`: `DEVICE=emulator-5554 timeout 900 flutter drive --driver test_driver/push_fixtures_driver.dart --target integration_test/target_flow.dart -d emulator-5554`.
  - Re-run FEAT-001-T25's share drive (`share_intent_driver.dart` + `pick_share_test.dart`), now with `TargetScreen` as the next step.
- **Done when:** `target_flow.dart` passes on API 36.1 and in the CI API 28 job. The share drive passes on both. The results (pass/fail per check, no URIs, paths or file names) are in the Test record.

### - [ ] FEAT-005-T18 — Emulator run and scripted checklist — gate G3
- **Implements:** FR-3, FR-10, FR-14, NFR-2, NFR-3, NFR-6, NFR-8, NFR-9 · **ADRs:** —
- **Depends on:** T17
- **Size:** S
- **Scope:** steps kept in the Test record below, run on API 36.1 (profile build) with a synthetic photo. Each row gets an adb command, the expected result and pass/fail.
  - TalkBack: every field is read with label, unit, optional/required and value; on Continue with errors, focus moves and the first error is read once (R7).
  - Font scale 200% (`adb shell settings put system font_scale 2.0`) in en, ar and hi: no clipping, Continue reachable with the keyboard open.
  - Gboard on the number fields: no suggestion strip and no learning indicator. [Hypothesis that Gboard shows it; record what is observed.]
  - Native-digit input from the Arabic and Hindi Gboard layouts, if offered in number mode (R1).
  - Home on the target step, then `adb shell am kill <package>`, then relaunch: the pick screen starts empty and the next target step is empty (AC-8.3).
  - Airplane mode: full flow to the stand-in (NFR-3).
  - Rotation with values and an error showing: kept (AC-8.2).
  - A 10,000-character paste: no crash (NFR-8).
  - `adb logcat -d` for the app process, grepped for the typed test values, `content://`, `/data/` and `/storage/` → zero lines (FR-14).
  - Storage listing of `files/` and `cache/` → no file holding target values, no preferences file.
  - API 28: covered by the CI job only (T17); no local image.
- **Done when:** every row passes on API 36.1 and is recorded below with date and image. CI API 28 is green for `target_flow.dart`, the share drive and `bundle.dart`. Gate G3 is recorded.

## Effort reconciliation
| Tech section 12 line | Tech days | Tasks | Task days |
|---|---|---|---|
| Domain incl. fuzz and static tests | 1.0 | T02 S, T03 S, T04 M, T05 S, T07 S | 1.5 |
| State | 0.25 | T06 S | 0.25 |
| Impeccable pass | 0.5 | T09 M | 0.5 |
| `TargetScreen` incl. widget tests, goldens | 1.75 | T12 L, T13 S, T14 S, T15 M | 2.0 |
| Flow wiring | 1.0 | T01 M, T10 M, T11 S | 1.25 |
| English ARB | 0.25 | T08 S | 0.25 |
| Emulator drive, T25 re-run, manual checks | 0.75 | T17 M, T18 S | 0.75 |
| Slack | 0.5 | — | 0 |
| **Total** | **6.0 d ≈ 1.2 pw** | 17 counted tasks | **6.5 d ≈ 1.3 pw** |

The task total is 0.5 d above tech's 6.0 d, inside tech's 1.0–1.5 pw range. This comes from rounding up to S/M/L buckets and splitting the privacy test and the stand-in into their own tasks; tech's 0.5 d slack is used up by it. No slack is left, so any further overrun goes to the Product Owner (tech R8). Shoulds (FR-11–FR-13) are separable in T05 and T14. Not counted, as in tech: T16 translations (FEAT-019, M), FEAT-011's preset entry, FEAT-006's result screen, and the Product Owner's design time.

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T01, T10, T12, T17 | Placeholder removed in T01; screen in T12 |
| FR-2 | T02, T06, T12 | Default per PRD OQ-3 at G1 |
| FR-3 | T12, T15, T18 | IME compliance [Hypothesis], R1 |
| FR-4 | T03, T12 | Bengali included (Could); display per OQ-T2 |
| FR-5 | T04, T08 | |
| FR-6 | T04 | FEAT-004 code unchanged (OQ-T6) |
| FR-7 | T06, T13 | |
| FR-8 | T04, T12, T13 | |
| FR-9 | T02, T04, T06, T10, T11, T12 | AC-9.3 data test is owned by FEAT-011 |
| FR-10 | T06, T10, T12, T17, T18 | Default per PRD OQ-1 at G1 |
| FR-11 | T05, T14 | Should; reuses `cropNoticeEnlarged` (OQ-T3) |
| FR-12 | T05, T06, T14 | Should; dropped if OQ-7 = no |
| FR-13 | T05, T14 | Should; threshold 16 [Assumption] |
| FR-14 | T02, T07, T12, T17, T18 | Copy/Cut menu kept (OQ-T4) |
| FR-15 | T08, T16 | Translations `AI-reviewed only` |
| FR-16 | T09, T15 | Gates G1, G2 |
| NFR-1 | T04 | Informational benchmark |
| NFR-2 | T13, T15, T17, T18 | |
| NFR-3 | T07, T18 | FEAT-016 verifies copy |
| NFR-4 | T03, T08, T15, T16, T17 | |
| NFR-5 | T04, T08 | |
| NFR-6 | T07, T12, T18 | |
| NFR-7 | T03, T04, T17 | |
| NFR-8 | T03, T04, T12, T18 | |
| NFR-9 | T17, T18 | API 28 via CI only |

**Not covered by a task:**
- PRD section 3 "Entry time ≤ 20 s median" needs a closed test with users (informational). PRD OQ-14 (30 s goal on the preset path) is a Product Owner question.
- AC-9.1–9.3 with real presets belong to FEAT-011; FEAT-005 provides `fill` and `validateTargetInput` only.
- Real-device IME behaviour beyond the emulator's Gboard (R1) is not tested.
- R5 (preview re-decode wait) is observed in T17, not optimised.

## Open questions
- PRD OQ-1, OQ-3, OQ-7 and OQ-10 are answered at G1 (T09); the defaults apply otherwise. OQ-1 = C (persistence) would need a PRD change and is not planned here.
- `tester.testTextInput` JSON keys for the keyboard flags are a [Hypothesis] (T12); if they are not observable, the check moves to the T18 Gboard row only.
- Whether `push_fixtures_driver.dart` already handles screenshots is an [Assumption] (T17).

## Test record
_Filled in by T01, T15, T17 and T18 (one row per check and image: date, image, result). Synthetic images only. No target values, URIs, paths or file names in rows or screenshots' captions; use `[PLACEHOLDER]` for anything sensitive._

## Instructions for Claude Code
- Read `prd.md`, `tech.md`, ADR-001 and ADR-003 before starting a task.
- Implement only the current task, in order; tick its checkbox and add a line to `docs/CHANGELOG.md` when done.
- Gates: no visible UI work (T10–T15) before G1; T17 only after G2; stop at every failing gate and report to the Product Owner.
- UI rule: before designing or building any real UI screen, stop and tell the Product Owner (impeccable, decision 2026-11-20). T09 is that stop. impeccable runs lean: no image comps, no reviewer subagents, one round, one emulator screenshot per key state.
- Do not change FEAT-001, FEAT-002 or FEAT-004 code. If a task seems to need it, stop and propose a change request.
- Emulator tests under `flutter drive` use `testWidgets` only; every new drive target gets a line in `.github/workflows/ci.yml`.
- Keep the emulator running between tasks; start it only if `adb devices` shows none.
- Translations only through `/l10n-translate <lang>`, status `AI-reviewed only`.
- If a requirement is unclear or wrong, stop and propose a PRD change.
- Privacy: synthetic test images only, never real faces or signatures. Never log or put in crash reports, test records or PR text any target value, URI, path, file name or EXIF value. No persistence, `restorationId` or clipboard writes. No network calls. Any sensitive value is `[PLACEHOLDER]`.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-23 | First draft |
| 1.0 | 2026-11-23 | Approved by Product Owner |
