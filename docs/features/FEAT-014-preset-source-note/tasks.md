---
id: FEAT-014-TASKS
title: Preset source note and "check your notice" prompt — Implementation Tasks
status: Approved
version: 1.0
updated: 2026-11-27
links: [FEAT-014, FEAT-014-TECH, FEAT-011, ADR-001]
---

# FEAT-014 — Implementation Tasks

Milestone: R1 Phase A (MVP, Must). Ships with FEAT-011: the preset list is not released without it. Work top to bottom, one task at a time.

Sizes: **S** ≈ 0.25 day, **M** ≈ 0.5 day; each task is one PR. Files, contracts and test names are in tech sections 2, 4, 5 and 8; tasks reference them instead of repeating them.

**Already built, reused, not planned again:** `PresetForm.source` / `issuer` / `lastChecked`, `parseLibrary`, `_applied` derivation in `PresetRow` (FEAT-011 FR-13), `BoothNotice`, `_fsi` / `_lri` / `_number` helpers in `PresetStrings`, `libraryProblems`, `preset_copy_test.dart` (banned words, six-locale presence), `tool/presets/freshness.dart` (`maxAgeDays`), FEAT-016 whole-tree scan, `privacy_copy_test.dart`, reviewed package and dependency lists, the CI `build` and API 28 `emulator` jobs, `TargetScreen`'s `SingleChildScrollView`.

**Decisions used:** PRD 1.0 open questions OQ-1 to OQ-11 at their defaults (host only, plain text; `YYYY-MM-DD`; old-check prompt in R1; "notice or instructions"; no prompt on the list; no acknowledgement; no chosen-pixel note; missing line left out; notes first, block after; no not-affiliated line on the target step). Tech 1.0 OQ-T1 to OQ-T4 at defaults (no resume listener; empty issuer leaves the source line out; host as Dart parses it; pick announcement unchanged). No new ADR.

**Test devices and pushes:**
- Local device runs use the emulator **Medium_Phone_API_36.1** (`-memory 2048`). Run `adb devices` first; start it only if none is listed; never kill it (CLAUDE.md, Budget). A real phone is optional.
- **API 28 runs only in CI.** One planned push, **P1**, in T10 after G2. Run `flutter analyze` and `flutter test` locally before it.
- Device runs that need forms use `integration_test/preset_demo.dart` with synthetic Test Forms A/B/C and a clock override; `git diff --exit-code assets/presets/presets.json` must pass before every commit.
- Test data is synthetic only. Test forms keep `example.test` URLs; any credential-like value is `[PLACEHOLDER]`.

## Decision gates
| Gate | Task | Passes when | If it fails / what it blocks |
|---|---|---|---|
| G1 Design and copy (FR-13, PRD OQ-4, OQ-9) | T05 | The Product Owner was told before any visual work; one lean impeccable pass (Material 3, existing Booth theme, no image comps, no reviewer subagents, one round) covers the target-step block (fresh, old-check, KB-only, DPI note, 200%) and the card lines; the five English strings accepted or fixes named; decision recorded | **Blocks T06** (translation needs final wording) **and T07, T08** (all visible UI). T01–T04 do not wait |
| G2 Screens (NFR-2, AC-5.1, AC-5.2) | T09 | Emulator screenshots, one per key state, accepted by the Product Owner or fixes named. One look | **Blocks T10 and P1.** Fixes go into T07/T08 code inside T09; a wording fix re-runs `/l10n-translate` for that key only |
| G-final Build | T10 | Offline emulator run passes; release APK permissions and reviewed lists unchanged; FEAT-016 `claims.md` row updated; P1 CI green; the Product Owner accepts the Open items | A network use, trace, crash or accessibility miss means stop and report. T10 stays unticked until it passes |
| Release (not a build gate) | — | FEAT-011 and FEAT-014 ship together; counsel input on wording and the not-affiliated line (FEAT-011 OQ-5, PRD OQ-10) [PLACEHOLDER: counsel]; `freshness.dart` run at release (tech risk: a release after 2027-02-25 shows the old-check prompt on all 17 forms) | The preset list is not released |

## Tasks

### - [x] FEAT-014-T01 — `source_note.dart` pure helpers and table tests
- **Implements:** FR-3, FR-4, FR-6 (logic), FR-11 (shared helper), NFR-6, NFR-7 · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** M (0.5 d)
- **Scope:** `lib/features/presets/domain/source_note.dart` (`staleAfterDays`, `sourceHost`, `isoDate`, `isStale`, `hasControlChars`; tech section 4; pure Dart, no imports); `preset_types.dart` comment on `PresetSource.url` (tech section 2); `test/features/presets/source_note_test.dart`; one test in `test/presets/freshness_test.dart`.
- **Done when:** `flutter test test/features/presets/source_note_test.dart test/presets/freshness_test.dart` passes with: host table of tech section 4 (http and https shipped examples, port, IP, upper case pinned, IDN decoded, user info, `ftp`, relative, `[PLACEHOLDER]`, blank, `https:///path`, a host with a control character all → expected value or null; nothing throws); `isoDate` gives `2026-03-05` from `DateTime.utc(2026, 3, 5)` and pads year 1 and month/day 1; the exact PRD section 8 stale table (lastChecked 2026-03-05: 03-01, 03-05, 06-03 normal; 06-04, 2099-01-01 old-check; 1970-01-01 normal) plus `null` → false; `hasControlChars` true for each bidi control and a C0/C1 sample, false for ZWJ and ZWNJ; `staleAfterDays == maxAgeDays`. `flutter analyze` clean.

### - [x] FEAT-014-T02 — CI data rules (FR-11), fixture URLs, copy-test bans (FR-8, FR-9)
- **Implements:** FR-11, FR-9 (banned-word test), FR-8 (token scan), AC-6.2, AC-5.5 · **ADRs:** —
- **Depends on:** T01
- **Size:** M (0.5 d)
- **Scope:** `test/presets/library_rules.dart` and `library_data_test.dart` (tech section 5 rules, messages and self-tests); `test/presets/fixtures/test_library.json` and `integration_test/preset_fixture_data.dart` URLs per tech section 2 (A `https://notice.example.test/page`, B `http://notice.example.test/b`, C `url` removed), plus any test that asserted the old `[PLACEHOLDER]` URL; `test/presets/preset_copy_test.dart`: extra banned words in English `preset*` values with a planted self-test, descriptions may start `FEAT-011` or `FEAT-014`, module scan adds `SelectableText`, `SelectionArea`, `GestureRecognizer`, `launchUrl`.
- **Done when:** `flutter test test/presets/` passes on the shipped file and the fixture (incl. `fixture_data_test.dart`); self-tests fail as expected naming form id and rule for: a title with U+202E, `https://[PLACEHOLDER]@notice.example.test`, `ftp://notice.example.test/x` (AC-6.2), a 101-character title, an issuer with a C1 control; a title with ZWJ and a form without `url` pass; a planted "verified" in a scratch English map and a scratch file with `SelectableText` each fail with key or `file:line`; `git diff --exit-code assets/presets/presets.json` passes.

### - [x] FEAT-014-T03 — Clock seam `presetClockProvider`
- **Implements:** FR-6 (device clock only), FR-7 (no cache), NFR-6 · **ADRs:** ADR-001
- **Depends on:** T01
- **Size:** S (0.25 d)
- **Scope:** `lib/features/presets/presentation/preset_providers.dart`: `presetClockProvider` (tech section 4), not kept alive beyond the default, no timer. A provider test in the existing presets provider test file (or `preset_row_test.dart` setup helper shared by T07).
- **Done when:** a test shows the default returns a time within a second of `DateTime.now()` and `overrideWithValue(() => DateTime(2026, 12, 31))` is returned as given; `grep -r "DateTime.now" lib/features/presets/` finds only this provider; `flutter test test/privacy/` passes.

### - [x] FEAT-014-T04 — Five English keys and `PresetStrings` lines
- **Implements:** FR-3, FR-4 (line), FR-5, FR-6 (string choice), FR-9 (English), FR-10, AC-5.1 (isolates), AC-6.1, AC-6.3 · **ADRs:** ADR-001
- **Depends on:** T01, T02
- **Size:** M (0.5 d)
- **Scope:** `lib/l10n/app_en.arb`: the five keys of tech section 6 with "FEAT-014 ..." descriptions and placeholders (the `presetCheckNoticeOld` description says `days` is always 90); `flutter gen-l10n`; `preset_strings.dart`: `sourceLine`, `websiteLine`, `checkedLine`, `prompt`, `cardSource`, `block` (tech section 4); `test/features/presets/preset_strings_test.dart`. The five other ARBs are filled in T06; until then the six-locale presence check in `preset_copy_test.dart` is expected red locally. Do not push between T04 and T06.
- **Done when:** `flutter gen-l10n` passes; `preset_strings_test.dart` passes: Test Form A lines with title and issuer in U+2068…U+2069 and host and date in U+2066…U+2069; Form C has no Website line; prompt switches at 90/91 days via `prompt(form, now)`; empty title, empty issuer and null date each leave out only their line, `block` still ends with the prompt and nothing contains "()" (AC-6.3); FR-10: the shipped asset parses with no form dropped (count equals the raw count) and for each of the 17 forms in each of the 6 locales `sourceLine`, `checkedLine`, `block` and `cardSource` are non-empty and contain the title and date (AC-6.1); English banned-word check from T02 passes on the new keys; FEAT-016 `privacy_copy_test.dart` passes.

### - [x] FEAT-014-T05 — Lean impeccable design pass with the Product Owner — gate G1
- **Implements:** FR-13, FR-1 / FR-2 (design), PRD OQ-4, OQ-9 · **ADRs:** —
- **Depends on:** T04 (English copy to review)
- **Size:** S (0.25 d)
- **Scope:** stop and tell the Product Owner first. One short impeccable pass on Material 3 and the FEAT-011 design note `t09/preset_design.md`: icon, spacing, whether the prompt looks different from the lines (tech section 10: a new widget only if it does), placement under the notes and between the issuer line and first spec key. No image comps, no reviewer subagents, one round. Result in `docs/features/FEAT-014-preset-source-note/t05/source_design.md`; accepted copy fixes go into `app_en.arb` in this task.
- **Done when:** the design note exists with date; the Product Owner's acceptance (or named fixes) is recorded in the Test record as G1; `preset_strings_test.dart` still passes after any copy fix.

### - [x] FEAT-014-T06 — Translate the five strings (es, pt, hi, id, ar) — Product Owner runs `/l10n-translate`
- **Implements:** FR-9, NFR-4, AC-5.4 · **ADRs:** —
- **Depends on:** T05 (G1; wording final)
- **Size:** M (0.5 d; Product Owner run time extra)
- **Scope:** the Product Owner types `/l10n-translate <lang>` for es (es-419), pt (pt-BR), hi, id and ar (MSA, Western digits 0-9), one language at a time, vendored `localize-*` skills only. Reviewer brief: all FR-9 banned words; no network words ("online", "offline", "connect", "internet"); placeholders `title`, `issuer`, `host`, `date`, `days` unchanged and untranslated, no bidi marks added; back-translation checks "notice" (PRD OQ-4) and the plural for the fixed 90. Only app strings go to the model, never user data. Status `AI-reviewed only`. One commit with all six ARBs (closes the red check left by T04).
- **Done when:** the five keys are in all six ARBs; `untranslated_messages.json` has no FEAT-014 key; `docs/l10n/ai-review-log.md` has one entry per language with `AI-reviewed only`; `preset_copy_test.dart` (six-locale presence, banned words), `privacy_copy_test.dart` and `preset_strings_test.dart` (FR-10 in 6 locales) pass. **Gates T07–T09** (their 7-locale tests and ar/hi screenshots need real translations).

### - [x] FEAT-014-T07 — Source block on the target-step row
- **Implements:** FR-1, FR-5, FR-6, FR-7, FR-8, FR-12, NFR-2, NFR-5, NFR-7, AC-1.1–1.7, AC-3.1–3.5, AC-4.3, AC-4.4, AC-5.2, AC-5.3 · **ADRs:** ADR-001
- **Depends on:** T03, T06 (and G1)
- **Size:** M (0.5 d)
- **Scope:** `lib/features/presets/presentation/preset_row.dart` only: while `_applied` gives a spec, show the KB-only line, then notes, then `BoothNotice(icon, s.block(form, ref.watch(presetClockProvider)()))` (tech section 8, FR-1). Tests in `test/features/presets/preset_row_test.dart` and `preset_a11y_test.dart`. The hostile form for NFR-7 is built in the test, never added to the fixture file.
- **Done when:** `flutter test test/features/presets/` passes with (fixture dates, see Open items 2): AC-1.1 lines and prompt shown with clock 2026-10-16 and Continue works; AC-1.2 Test Form C has no Website line; AC-1.3 edit hides and restore shows the block with the notes; AC-1.4 KB-only line plus block, Continue reachable by scrolling at 200%; AC-1.5 DPI note before the block; AC-1.6 tap and long-press on the block push no route and show no selection handles or `AdaptiveTextSelectionToolbar`; AC-1.7 `AsyncError` and no applied spec show no block; AC-3.1/3.2/3.3 old-check at lastChecked+91, normal at +90 and at a date before; AC-3.4 old-check changes no value and Continue works; AC-3.5 changing the clock override then returning from the list switches the prompt; AC-4.3 captured `debugPrint` and loader sink hold no form id, title, host or date; AC-4.4 a fresh `ProviderContainer` shows no block; AC-5.3 the block is one semantics node after the row and notes and the icon has no label; NFR-7 hostile in-test form (empty title, null date, 300-character URL, control character in title) throws nothing and shows no "Source: ()"; 200% on 360×640 dp with the longest shipped title (97 characters) and issuer in all 7 supported locales: no overflow, no horizontal scroll (AC-5.2). Existing FEAT-005 target tests and goldens pass unchanged; `flutter test test/privacy/` passes.

### - [x] FEAT-014-T08 — Source lines on the list's form cards
- **Implements:** FR-2, FR-3, FR-4, FR-8, NFR-1, NFR-2, AC-2.1–2.4, AC-5.2 · **ADRs:** ADR-001
- **Depends on:** T06, T07 (and G1)
- **Size:** M (0.5 d)
- **Scope:** `lib/features/presets/presentation/preset_list_screen.dart`: `_FormCard` one plain `Text(s.cardSource(form))` between the issuer line and the first `_SpecKey`, no prompt, no handler (tech section 8, FR-2). Tests in `preset_list_screen_test.dart` and `preset_a11y_test.dart`; fix FEAT-011 finders that now see the issuer twice (tech risk row 3).
- **Done when:** `flutter test test/features/presets/` passes with: AC-2.1 each card shows the lines once, also Test Form A with two specs, Website line absent for Test Form C; AC-2.2 after search the remaining cards' lines are unchanged; AC-2.3 each spec-key semantics node equals its FEAT-011 value and the source text comes after the name and issuer in traversal order; AC-2.4 footer is the last item and no prompt text appears on the list; tap and long-press on the lines do nothing (FR-8); 200% on 360×640 dp in all 7 locales with the longest shipped title and issuer: no overflow, every spec key reachable and at least 48 dp; no new provider read or async step in the diff (NFR-1, by review). All FEAT-011 list and a11y tests pass after the finder fixes.

### - [ ] FEAT-014-T09 — Demo states and emulator screenshots — gate G2
- **Implements:** NFR-2, NFR-4, AC-5.1, AC-5.2, FR-6 (visible) · **ADRs:** —
- **Depends on:** T08
- **Size:** S (0.25 d)
- **Scope:** `integration_test/preset_demo.dart`: clock override plus states `source` (fresh), `stale`, `source-ar`, `source-hi`, `source200` (Test Form C, 200%), `list200` (tech section 2), synthetic forms only. On the emulator (`adb devices` first, never killed), debug demo build: one screenshot per key state: list card (en), block fresh (en), block old-check, ar block, hi block, 200% KB-only block, 200% list. ExactSize in front before each capture; screenshots under `build/feat014_g2/`, not committed. Font scale, locale and rotation noted and restored; build uninstalled.
- **Done when:** seven screenshots taken and listed in the Test record; ar is mirrored with Western digits and title, host and date in reading order (AC-5.1); nothing clipped at 200% (AC-5.2); the Product Owner accepts them or names fixes (G2 in the Test record); `git diff --exit-code assets/presets/presets.json` passes.

### - [ ] FEAT-014-T10 — Offline matrix row, verification, P1 — gate G-final
- **Implements:** NFR-3, NFR-5, NFR-8, NFR-9, FR-12, FR-14 (check), AC-4.1, AC-4.2, AC-4.4 · **ADRs:** —
- **Depends on:** T09 (G2)
- **Size:** S (0.25 d)
- **Scope:** `docs/features/FEAT-016-on-device-privacy/claims.md`: "see source note" in the "Pick a preset" offline row plus a Change log line (NFR-3). Emulator, release build of the demo flow: airplane mode on and Wi-Fi off (state noted; `adb shell ping -c1 1.1.1.1` fails first): open list, pick Test Form A photo, see the block, Continue (AC-4.1); force-stop and reopen: no block (AC-4.4); `adb logcat --pid` holds no form id, title, host or date. `aapt2 dump permissions` on the release APK equals `claims.md` section 3; `git diff --stat main -- pubspec.yaml android/app/src/main/AndroidManifest.xml tool/privacy/reviewed_packages.txt android/app/reviewed_dependencies.txt assets/presets/presets.json` is empty (AC-4.2, NFR-9, FR-14: no `lastChecked` change in this feature). `dart run tool/presets/freshness.dart` output recorded. Local `flutter analyze` and `flutter test`, then push **P1**.
- **Done when:** every check above passes and is recorded with date and device; P1 CI is green (build job and API 28 emulator job incl. `integration_test/bundle.dart`); emulator settings restored, build uninstalled; one `docs/CHANGELOG.md` line per task present; the Product Owner accepts the Open items (G-final in the Test record).

## Effort reconciliation
| Tech Effort line | Tech days | Tasks | Task days |
|---|---|---|---|
| `source_note.dart`, table tests, constant equality | 0.5 | T01 M | 0.5 |
| `PresetStrings`, 5 English keys, copy-test changes, FR-10 | 0.5 | T04 M (copy-test changes moved to T02) | 0.5 |
| CI FR-11 rules, fixture URLs, self-tests | 0.5 | T02 M (with copy-test changes) | 0.5 |
| Lean impeccable pass | 0.25 | T05 S | 0.25 |
| `PresetRow` block, clock provider, widget tests | 0.75 | T03 S, T07 M | 0.75 |
| `_FormCard` lines, list and a11y tests, finder ripples | 0.5 | T08 M | 0.5 |
| `/l10n-translate` for 5 languages | 0.5 | T06 M | 0.5 |
| Demo states, screenshots, offline matrix row, CHANGELOG | 0.5 | T09 S, T10 S | 0.5 |
| **Total** | **4.0 d ≈ 0.8 pw** | 10 tasks | **4.0 d ≈ 0.8 pw** |

Same as tech. Risk: T02 and T10 are tight at their size (T02 carries CI rules and copy-test changes; T10 carries the offline run and a P1 CI run of about 80 min wall time, not counted as work). FEAT-011 ran over by the offline run (+0.5 d); a similar overrun here would give about 4.5 d. Not counted: the Product Owner's design, review and translation time.

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T07 | |
| FR-2 | T08 | |
| FR-3 | T01, T04, T07, T08 | |
| FR-4 | T01, T04, T08 | Should |
| FR-5 | T04, T07 | |
| FR-6 | T01, T03, T04, T07, T09 | Should |
| FR-7 | T03, T07 | |
| FR-8 | T02, T07, T08 | |
| FR-9 | T02, T04, T06 | |
| FR-10 | T04 | |
| FR-11 | T01, T02 | Should |
| FR-12 | T07, T10 | |
| FR-13 | T05 | Gate G1 |
| FR-14 | T10 | Should; process; T10 only checks this feature changes no `lastChecked` |
| NFR-1 | T08 | By construction; not timed |
| NFR-2 | T07, T08, T09 | |
| NFR-3 | T10 | |
| NFR-4 | T06, T09 | `AI-reviewed only` |
| NFR-5 | T07, T10 | |
| NFR-6 | T01, T03 | |
| NFR-7 | T01, T07 | |
| NFR-8 | T10 | API 28 in CI (P1) |
| NFR-9 | T10 | |

| Acceptance criterion | Task (test) |
|---|---|
| AC-1.1–1.7 | T07 (`preset_row_test.dart`, `preset_a11y_test.dart`) |
| AC-2.1–2.4 | T08 (`preset_list_screen_test.dart`, `preset_a11y_test.dart`) |
| AC-3.1–3.3 | T01 (exact PRD dates, `source_note_test.dart`), T07 (widget, fixture offsets) |
| AC-3.4 | T07 |
| AC-3.5 | T07 (return from the list); "resume" not covered, see Untraced |
| AC-4.1, AC-4.2 | T10 (emulator offline run, `aapt2`, diff of reviewed lists) |
| AC-4.3 | T07 (log capture), T10 (logcat) |
| AC-4.4 | T07 (fresh container), T10 (force-stop) |
| AC-5.1 | T04 (isolate code points), T09 (ar screenshot) |
| AC-5.2 | T07, T08 (200% tests), T09 (screenshots) |
| AC-5.3 | T07 (semantics) |
| AC-5.4 | T04 (data equal in 6 locales), T06 |
| AC-5.5 | T02 (banned-word test), T04 |
| AC-6.1 | T04 (FR-10 test) |
| AC-6.2 | T02 (self-tests) |
| AC-6.3 | T04 (strings), T07 (hostile form widget test) |
| AC-6.4 | T10 (diff check only; process) |

**Untraced (no task covers it fully):**
- AC-3.5 "resume": tech OQ-T1 default adds no lifecycle listener, so an app left open on the target step across the 90-day boundary keeps the old prompt until the next rebuild.
- AC-6.4 / FR-14 as a process: future re-checks are checked at PR review, not by a test.
- PRD section 3 metric "Understood (closed test, at least 4 of 5)": observed by the Product Owner in the closed test; no task.
- PRD section 3 "Effect on rejected uploads": no target, not measurable.
- NFR-1 300 ms list open: not timed; met by construction only.
- TalkBack speech (AC-2.3, AC-5.3): semantics tests only; speech is checked only if the Product Owner enables TalkBack on the emulator.
- Counsel wording and the not-affiliated line (PRD OQ-5, OQ-10): release item [PLACEHOLDER: counsel].
- FEAT-025 and FEAT-027 carried constraints (PRD section 10, flags 6 and 7): belong to those PRDs.

## Open items
1. **T04 to T06 local red.** The six-locale presence check fails between T04 and T06 because English keys land first. Not a loosened gate; no push until T10.
2. **Test data differs from the PRD.** PRD AC data uses "Test Notice A" and `lastChecked` 2026-03-05; the fixture has "Test notice 1" and 2026-10-01 (B and C 2026-11-20), and tech changes only URLs. Widget tests use fixture values with the same day offsets (2026-12-30 = 90 days, 2026-12-31 = 91, 2026-09-27 = before); the exact PRD dates run in the T01 table test.
3. **Test Form C URL.** The PRD gives `[PLACEHOLDER]`; tech removes `url`. Both are "unusable": C covers a missing URL (T07, T08), `[PLACEHOLDER]` is in the T01 host table.
4. **Old-check prompt on every form after 2027-02-25** if a release slips past 90 days from 2026-11-27. True and non-blocking; `freshness.dart` at release.
5. **Device.** Local runs use the 2 GB emulator, per CLAUDE.md; FEAT-011 used the Realme 2 Pro. A real phone is optional.

## Test record
_Filled in by T05, T06, T09 and T10 (date, device or CI run, result). Synthetic forms only; no personal data; `[PLACEHOLDER]` for anything sensitive._

| Date | Task | Check | Device / run | Result |
|---|---|---|---|---|
| 2026-11-27 | T05 | G1 design and copy: `t05/source_design.md` 0.1 accepted as proposed (Product Owner delegated: "do what you think is right"): `history` icon on the block, prompt in the same weight as the lines, card lines `bodySmall` at 80% (9.8:1 on the plate), the five English strings unchanged | — | Passed |
| 2026-11-28 | T06 | /l10n-translate es, pt, hi, id, ar (Product Owner run): 5 keys each, one blind Sonnet review per language, 13 fixes, open list empty, AI-reviewed only | local | Passed: gen-l10n no untranslated keys; preset, copy and privacy tests 220/220 |
| 2026-11-28 | T09 | Demo states (`integration_test/preset_demo.dart`, synthetic Test Forms, fixed clock): list, source, stale, source-ar, source-hi, source200 (scrolled to the block), list200; ExactSize checked in front before each capture; status bar cropped; screenshots in `build/feat014_g2/` (not committed). Checked: stale shows the old-check prompt; ar mirrored with title, host and date in reading order, digits 0-9 (AC-5.1); nothing clipped at 200% (AC-5.2). Rotation and screen timeout noted, locked for the run and restored; build uninstalled. G2 decision pending | Realme 2 Pro (API 36), debug demo build; emulator not running | Screens OK; G2 pending |

## Instructions for Claude Code
- Read `prd.md`, `tech.md` and ADR-001 before starting a task.
- Implement only the current task, in order; tick its checkbox, commit, and add a line to `docs/CHANGELOG.md` when done. Push only at P1 (T10); run `flutter analyze` and `flutter test` locally first.
- Gates: no visible UI (T07, T08) and no translation (T06) before G1; T10 only after G2; stop at every failing gate and report to the Product Owner.
- UI rule: T05 is the stop before UI work (impeccable, decision 2026-11-20). impeccable runs lean: no image comps, no reviewer subagents, one round, one emulator screenshot per key state.
- Translations only through `/l10n-translate <lang>` typed by the Product Owner, status `AI-reviewed only`.
- Never change `assets/presets/presets.json` or a `lastChecked` date in this feature; never loosen a CI rule, banned-word list or scan without an approved PRD change.
- No link, selection, clipboard, network, log of form data, or persistence. `[PLACEHOLDER]` for every credential or sensitive value.
- Never set a PRD, tech or tasks status to Approved, Rejected or Implemented.
- If a requirement is unclear or wrong, stop and propose a PRD change.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-27 | First draft |
| 1.0 | 2026-11-27 | Approved by the Product Owner (/approve FEAT-014-TASKS); open items stand as written |
