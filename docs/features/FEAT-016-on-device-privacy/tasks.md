---
id: FEAT-016-TASKS
title: On-device-only, offline-capable processing with in-app privacy explainer — Implementation Tasks
status: Approved
version: 1.0
updated: 2026-11-26
links: [FEAT-016, FEAT-016-TECH, ADR-001, ADR-006, ADR-007, FEAT-001, FEAT-007, FEAT-019, FEAT-025, FEAT-013, FEAT-027, FEAT-012]
---

# FEAT-016 — Implementation Tasks

Milestone: R1 Phase A (MVP, Must). Work top to bottom, one task at a time.

Sizes: **S** ≈ 0.25 day, **M** ≈ 0.5 day, **L** ≈ 1 day; each task is one PR.
Module paths follow tech section 2: new `lib/features/privacy/{presentation,data}`, `test/privacy/`, `test/features/privacy/`, `tool/privacy/reviewed_packages.txt`, `android/app/reviewed_dependencies.txt`, `android/app/src/main/res/xml/data_extraction_rules.xml`, `docs/features/FEAT-016-on-device-privacy/claims.md`; changed `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `lib/main.dart`, `lib/features/pick/presentation/{pick_view,pick_screen}.dart`, `integration_test/offline_test.dart`, `.github/workflows/ci.yml` (one assertion line), `lib/l10n/app_*.arb`.

**Already built, reused, not planned again:** `checkMergedManifest` and its self-test pattern, the FileProvider `@xml/...` check (FEAT-007); `networkUses` in `no_network_imports_test.dart`; the per-feature `*_privacy_test.dart` files (kept as they are, FR-9); `OutcomeLog` and the `LogSink` typedef pattern; `TempFiles` and the start-up sweeps (C4); `tool/run_offline_test.sh` and its "networking is off" first check; the CI `build` and API 28 `emulator` jobs; `Navigator.push(MaterialPageRoute)` (`lib/app_flow.dart`); `popUntil(route.isFirst)` on share-in (`pick_screen.dart`); gen-l10n with 6 languages; the synthetic fixture generator.

**Decisions used (tech.md v1.0, OQ-T1 to OQ-T4 at defaults; PRD 1.0, open questions at defaults):**
- OQ-T1: the Gradle half of FR-10 fails in the release build, not in `flutter test`; AC-4.3 is clarified in a PRD minor version (T12).
- OQ-T2: one heading key and one body key per part (14 new keys); headings do not count toward the 150 words.
- OQ-T3: FR-19 is recorded in `claims.md` only; no edit to the roadmap or other PRDs.
- OQ-T4 / PRD OQ-10: effort is re-estimated below; the Product Owner updates the roadmap row (Open items 2).
- PRD OQ-1 app-scoped wording (FR-1); OQ-3 labelled control beside the plaque (final placement in T13); OQ-4 no in-app policy link; OQ-5 backup off; OQ-6 all three gates; OQ-8 `claims.md` is the living register; OQ-11 C6 stays out of user-facing text; OQ-12 FR-18 built.

**Test devices:**
- **Local device runs and screenshots use the connected real phone, Realme 2 Pro, API 36.** Run `adb devices` first. The local emulator (Medium_Phone_API_36.1) is used only if `adb devices` already shows it; never start a second one, never kill it.
- **API 28 runs only in CI.** CI costs about 80 min per push to `main`: commit after each task, push only at milestones. Planned pushes: **P1** after T10 (gate markers, offline cases, API 28 backup check), **P2** after T16 before G-final. Run `flutter analyze` and `flutter test` locally before each push. Throwaway CI runs are slim (one job, one step), have `timeout-minutes`, and every wait loop is bounded.
- Files run under `flutter drive` use `testWidgets` only.

**Real-phone rules:**
- Synthetic images only (generated gradients, flat colours, checker patterns), pushed to `Download` and deleted with their MediaStore rows after the run. Never a real face, signature, document or card.
- Before every screenshot, check the foreground app (`adb shell dumpsys window | grep mCurrentFocus`) and capture only ExactSize's own screens. Never screenshot the system photo picker, file chooser, camera, gallery or share sheet: they show the owner's photos, files and contacts.
- Never record personal data seen on the phone (names, contacts, photo content, file names, paths, URIs, account names) in the Test record, PR text, captions or logs; use `[PLACEHOLDER]`.
- Note every setting before changing it (airplane mode, Wi-Fi, mobile data, font scale, locale, rotation, backup) and restore it after. Uninstall the test build after each run.
- Credentials, keys and URLs in docs and code: `[PLACEHOLDER]` only.

## Decision gates
| Gate | Task | Passes when | If it fails |
|---|---|---|---|
| G0 Hypothesis check | T01 | `dart pub deps --json` shape on Windows is known (or the fallback is chosen); a local `flutter build apk --release` is shown to execute `checkMergedManifest` (task graph); the release APK permission set is printed; file-count floors are measured. All in the Test record | Stop. Propose a tech.md change before T02 (manifest) or T05 (Dart deps). T06–T09 may continue |
| G1 Explainer design | T13 | The Product Owner was told before any visual work; one lean impeccable pass on Material 3 and the existing theme (no image comps, no reviewer subagents, one round); entry placement (OQ-3) and the English copy (T07) accepted or fixes named; reference and date recorded | No visible UI work (T14, T15). Non-visual tasks T01–T12 may run |
| G2 Screenshot review | T15 | The Product Owner has seen one Realme 2 Pro screenshot per key state named in T13 and accepts them or names fixes. One look | Fixes go into T15 before T16. A scope change means a PRD change |
| G-final Device and CI | T17 | Every FR-14 offline row passes on the Realme 2 Pro (release build, airplane mode); release APK permissions equal `claims.md`; register and explainer agree; CI is green at P2 (gate markers and API 28 offline cases); PRD 1.1 re-approved by the Product Owner (or the deviation accepted); the Product Owner accepts the recorded gaps | A false claim, a network use, a privacy leak, a crash or an accessibility miss means stop and report. Otherwise the Product Owner may type `/approve FEAT-016 implemented` |

## Tasks

### - [x] FEAT-016-T01 — Verify tech hypotheses (pub deps, release gate, permissions) — gate G0
- **Implements:** verification for FR-8, FR-10, FR-11, NFR-5 · **ADRs:** ADR-001
- **Depends on:** —
- **Size:** S
- **Scope:** local only, no code merged. Observe and record:
  - H1: `dart pub deps --json` (with `runInShell: true` on Windows, as the test will call it): field names `packages[].dependencies`, root `directDependencies` / `devDependencies`. If they differ, use the fallback `dart pub deps --no-dev --style=list` and note it for T05.
  - H2: `flutter build apk --release -v` runs `checkMergedManifest` before `assembleRelease` (look for the task in the Gradle task list of the verbose log). This also shows whether non-verbose output hides it (tech risk 2, the reason for marker files).
  - H3: merged release permissions with `aapt2 dump permissions` on the release APK. This settles the FEAT-007 T23 "profile build" ambiguity and fixes the T02 allow-list.
  - H4: counts of `.dart` files under `lib/` and `.kt`/`.java` files under `android/app/src/main` for the NFR-5 floors (real count minus a margin).
- **Done when:** one Test record row per H item (result, no paths beyond repo-relative ones); G0 recorded; if any H fails, a tech.md change is proposed to the Product Owner and T02/T05 wait.

### - [x] FEAT-016-T02 — Manifest permission allow-list and gate marker
- **Implements:** FR-8, FR-11, FR-12 (message), NFR-5 · **ADRs:** ADR-007
- **Depends on:** T01 (G0)
- **Size:** M
- **Scope:** `android/app/build.gradle.kts` `CheckMergedManifest`: every `uses-permission` and `uses-permission-sdk-23` checked against the allow-list constant (tech section 5, from T01 H3); named messages for INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE and `com.google.android.gms.permission.AD_ID`; existing banned messages and the no-`tools:node="remove"` rule kept; new self-test mutations: INTERNET added, ACCESS_NETWORK_STATE as `uses-permission-sdk-23`, AD_ID, an unknown permission. Writes `build/app/outputs/privacy/checkMergedManifest.ok` on success. Every message ends with "Follow FEAT-016 FR-12 (docs/features/FEAT-016-on-device-privacy/claims.md)." A comment notes that a flavor change must rename the task per variant.
- **Done when:** a local release build passes and writes the marker; each mutation makes the self-test fail with the permission name and the FR-12 pointer, and passes once removed (AC-4.1, AC-4.4, AC-4.5); the existing mutations still pass.

### - [x] FEAT-016-T03 — Backup off: manifest, extraction rules, gate
- **Implements:** FR-17, NFR-5, NFR-9 · **ADRs:** ADR-007
- **Depends on:** T02
- **Size:** M
- **Scope:** `<application android:allowBackup="false" android:dataExtractionRules="@xml/data_extraction_rules">`; new `res/xml/data_extraction_rules.xml` excluding `root`, `file`, `database`, `sharedpref` and `external` in both `<cloud-backup>` and `<device-transfer>`; no `fullBackupContent` (tech section 11). `CheckMergedManifest` requires both attributes and all five excludes in both sections; mutations: allowBackup removed, allowBackup true, dataExtractionRules missing, `device-transfer` loses one exclude. Message per PRD section 8.
- **Done when:** Android lint reports no error on the rules file; the four mutations fail and pass when removed; real-phone check on the Realme 2 Pro (API 36): note the backup state, `adb shell bmgr backupnow <applicationId>` reports the package as not eligible or not allowed, state restored, build uninstalled (rows in the Test record). The API 28 `bmgr` check runs in the P1 slim throwaway step (T10). Device-to-device transfer has no adb test: recorded as covered by lint and the gate only [Hypothesis stays].

### - [x] FEAT-016-T04 — Gradle reviewed-dependencies task and list
- **Implements:** FR-10 (Gradle half), FR-11, FR-12 (message), NFR-5, NFR-10 · **ADRs:** ADR-001
- **Depends on:** T02
- **Size:** M
- **Scope:** inline task `CheckReviewedDependencies` per tech 8.2: `releaseRuntimeClasspath` resolved artifacts mapped to `group:module` of `ModuleComponentIdentifier` (provider inputs, configuration-cache safe), plugin subprojects skipped; runs before `assembleRelease` and `bundleRelease`; writes `checkReviewedDependencies.ok`. Bootstrap `android/app/reviewed_dependencies.txt` from the task's first output, one note per entry (`# network: …; data: …; permissions: …`). `.github/workflows/ci.yml` `build` job: one line after the release build asserting both marker files.
- **Done when:** a local release build passes and writes the marker; the self-test with `[PLACEHOLDER_GROUP]:planted` fails naming it, with the FR-12 pointer; an entry with an empty note fails; a version bump of a listed module passes; the CI line is in place (verified at P1).

### - [x] FEAT-016-T05 — Dart reviewed-packages test and list
- **Implements:** FR-10 (Dart half), FR-11, FR-12 (message), NFR-5, NFR-10 · **ADRs:** ADR-001
- **Depends on:** T01 (G0)
- **Size:** M
- **Scope:** `test/privacy/reviewed_packages_test.dart` with `runtimePackages(pubDepsJson)` (tech section 4; or the T01 fallback); `tool/privacy/reviewed_packages.txt` with a note per package; build-hook packages noted "build-time hook, not in APK".
- **Done when:** `flutter test test/privacy/reviewed_packages_test.dart` passes on the tree; a fixture graph with one unlisted runtime name fails with "New dependency [NAME]. Review network, data and permissions, then add it with a note." and the FR-12 pointer; a missing note fails; a dev-only transitive package (for example `http` via `build_runner`) does not appear in the closure; a version bump passes.

### - [x] FEAT-016-T06 — Whole-tree deny-by-default source scan
- **Implements:** FR-9, FR-4 (WebView, `url_launcher` ban), FR-15 (connectivity tokens), FR-12 (message), NFR-5, NFR-6 · **ADRs:** ADR-006, ADR-007
- **Depends on:** T01 (floors)
- **Size:** M
- **Scope:** `test/privacy/whole_tree_scan_test.dart` per tech 8.1: roots `lib/`, `packages/es_codec/{lib,hook}`, `android/app/src/main/kotlin` and `java` if present; generated files scanned; `exempt` map empty, entries must exist; file-count floors from T01; Dart tokens (`networkUses` imported, plus `webview_flutter`, `url_launcher`, `connectivity_plus`, `ConnectivityResult`, `WebView`, the analytics/ads/crash import list, `\bClipboard\b`); Kotlin/Java tokens (tech 8.1, `android.net.Uri` allowed); `//` and KDoc `*` lines skipped; `print`/`debugPrint` banned under `lib/features/privacy/` except `uncaught_error_log.dart`. Existing per-feature privacy tests untouched.
- **Done when:** passes on the current tree; the temp-dir self-test (`features/new_feature/x.dart` with `HttpClient()`, `kotlin/X.kt` with `java.net.URL(...)`) gives exactly one hit each as `file:line: text` and none once removed (AC-4.2, AC-4.4); a root below its floor fails; a stale exempt path fails; nothing is written into `lib/`.

### - [x] FEAT-016-T07 — English privacy strings (15 keys)
- **Implements:** FR-1, FR-3, FR-6 (English), FR-7, NFR-4, NFR-7 · **ADRs:** —
- **Depends on:** —
- **Size:** S
- **Scope:** `lib/l10n/app_en.arb` only: `pickPrivacyNote` = "Your photos are resized on your phone. ExactSize never uploads them."; new `privacyEntry` (proposed "How your photos are handled"), `privacyTitle`, and `privacy{OnPhone,Offline,Kept,Copies,Outside,Reads}` plus each `…Title`. Parts (a)–(f) per FR-3 and AC-2.3; part (b) names the online-album exception; part (d) agrees with the unchanged `exportPrivacy`; part (e) names gallery, keyboard and receiving apps; no internal-gate fact (C6, C7); `@` descriptions name register IDs (`Register: C1, C3`); no placeholders; short plain sentences, no idioms. The five other ARBs are not touched (T16); until then they still carry the old `pickPrivacyNote` (not shippable, closed by T16).
- **Done when:** `flutter gen-l10n` passes; body text ≤ 150 English words and no sentence > 20 words (checked by T08); the PR lists each key with its C-IDs. The Product Owner reviews the copy at G1.

### - [x] FEAT-016-T08 — Privacy copy tests (banned claims, key rules, connectivity words)
- **Implements:** FR-5, FR-6, FR-7, FR-15, FR-3 (length), NFR-7 · **ADRs:** —
- **Depends on:** T07
- **Size:** M
- **Scope:** `test/privacy/privacy_copy_test.dart` per tech section 8: FR-5 banned list, case-insensitive, over `privacy*`, `pickPrivacyNote`, `exportPrivacy` in `app_en.arb`, PRD section 8 message; Latin tokens (`100%`, `GPS`, `GDPR`, `PCI`) in all 6 ARBs; every `privacy*` key except `privacyEntry`/`privacyTitle` has an `@` description matching `C\d+` and no `{placeholder}`; English values matching `internet|connect|network|offline|online` fail outside `pickSourceUnavailable`, `privacyOffline`, `privacyOfflineTitle`; word and sentence counts for FR-3. The presence-in-6-locales check is added in T16 (it cannot pass before translation).
- **Done when:** passes on the tree; a planted "never leaves" in a scratch copy of the English map fails with the PRD message; a missing C-ID and a placeholder each fail; a "no internet" phrase in a non-allow-listed key fails. If an existing non-privacy key trips the connectivity rule, stop and report; do not widen the allow-list silently.

### - [x] FEAT-016-T09 — Global uncaught-error log (enum only)
- **Implements:** FR-18, NFR-6, NFR-8 · **ADRs:** ADR-001
- **Depends on:** T06
- **Size:** M
- **Scope:** `lib/features/privacy/data/uncaught_error_log.dart` with `installUncaughtErrorLog({LogSink sink, bool debug})` per tech 8.3; one call in `lib/main.dart` after `ensureInitialized()`. Line: `exactsize.app outcome=UNCAUGHT source=FRAMEWORK|PLATFORM`; handlers never read the error object; debug keeps the previous handler and returns `false`.
- **Done when:** `test/features/privacy/uncaught_error_log_test.dart` passes: an error whose message holds `[PLACEHOLDER_PATH]`, thrown through both handlers with `debug: false`, gives exactly one matching line each and the line lacks the message; with `debug: true` the previous handler is called once and the platform handler returns `false`. Release logcat check on the Realme 2 Pro: a throwaway branch (never merged) throws an error holding `[PLACEHOLDER_PATH]` once after start; `adb logcat --pid` shows the text before the handler and only the enum line after; build uninstalled; result recorded (PRD gap 7 becomes a [Fact]).

### - [x] FEAT-016-T10 — Offline integration cases and CI push P1
- **Implements:** FR-16, FR-11 (CI), FR-17 (API 28), NFR-1 (CI time), NFR-3, NFR-8, NFR-9 · **ADRs:** ADR-006, ADR-007
- **Depends on:** T03, T04, T05, T09
- **Size:** M
- **Scope:** `integration_test/offline_test.dart` (`testWidgets` only): crop-to-compression and preview-check cases with one synthetic fixture each, behind the existing networking-off first check; `tool/run_offline_test.sh` unchanged. Local run on the Realme 2 Pro with Wi-Fi and mobile data off (state noted and restored, build uninstalled). Push **P1** after `flutter analyze` and `flutter test` pass locally. One slim throwaway CI run (emulator job only, `timeout-minutes`, bounded waits, not merged into `ci.yml`) installs the release build on API 28 and runs `bmgr backupnow <applicationId>`.
- **Done when:** the new cases pass on the Realme 2 Pro offline; P1 CI is green with both marker assertions true and the offline step passing on API 28; the API 28 `bmgr` result is recorded; the extra CI time of the `build` and `emulator` jobs against the last green run is recorded (NFR-1 target ≤ 1 min; see Open items 4d).

### - [x] FEAT-016-T11 — `claims.md`: register, inventory, procedure, checklist, carried items
- **Implements:** FR-12, FR-13, FR-14 (matrix table), FR-19 (record), FR-3 (register map), NFR-7 · **ADRs:** —
- **Depends on:** T02, T03, T07
- **Size:** S
- **Scope:** new `docs/features/FEAT-016-on-device-privacy/claims.md` (frontmatter, status `Proposed`): claims register C1–C10 from PRD section 10 with check type; data inventory; permission list mirroring the T02 allow-list; "Change procedure" copying FR-12 as a checklist; "Release checklist" (FR-13 plus tech rows: `aapt2 dump permissions` compare, offline matrix, register vs explainer vs listing vs Data safety, privacy policy URL `[PLACEHOLDER]`, 6 languages `AI-reviewed only`, OQ-7 review result or waiver, release signing key in place of the debug key); FR-14 matrix table (empty result columns); "Carried requirements" FR-19 (a)–(c) verbatim with owner and status "to copy into owning PRD at /draft-prd".
- **Done when:** every explainer key's C-IDs from T07 exist in the register; every C-ID has a check type; the path in the gate messages resolves; no real credential, URL or personal data (`[PLACEHOLDER]` only).

### - [x] FEAT-016-T12 — PRD 1.1 minor clarification (AC-4.3, FR-11) for re-approval
- **Implements:** FR-10, FR-11 (wording) · **ADRs:** —
- **Depends on:** T04, T10
- **Size:** S
- **Scope:** `prd.md` only: version 1.1, status `Under Discussion` (CLAUDE.md rule for changing an Approved doc), Change log line. AC-4.3: the Dart package list fails in `flutter test`; the Gradle coordinate list fails in the release build (OQ-T1). FR-11: "its log line appears in CI" becomes "a marker file it writes is asserted in CI" (tech FR-11). No scope change. Tell the Product Owner; only the Product Owner's `/approve` sets it back to Approved.
- **Done when:** the PRD diff touches only AC-4.3, FR-11, the version, status and Change log; the Product Owner has been told; the re-approval (or the decision to keep 1.0 and accept the deviation) is recorded before G-final.

### - [x] FEAT-016-T13 — Explainer design pass with the Product Owner (impeccable, lean) — gate G1
- **Implements:** prerequisite for FR-2, FR-3, FR-4, NFR-2, NFR-4 (visual) · **ADRs:** —
- **Depends on:** T07, T08
- **Size:** S (developer side; the Product Owner's time is not counted)
- **Scope:** **Stop and tell the Product Owner before any visual work.** One short impeccable pass on Material 3 and the existing theme; no image comps, no reviewer subagents, no multi-round critique. Inputs: the T07 English copy, the pick screen plaque, OQ-3 default (labelled control beside or under the plaque, ≥ 48 dp, plaque unchanged). Constraints: AppBar title, scrollable column, 6 parts as heading (`Semantics(header: true)`) then body, no link, no image, no icon that suggests a certification; 200% font at 360×640 with no clipping; RTL mirrored. Define the G2 screenshots: pick screen with entry control (en), explainer top and bottom (en), ar RTL, 200% font.
- **Done when:** the design reference (synthetic content only) and its date are in the PR and `docs/CHANGELOG.md`; the Product Owner's acceptance of the placement and the English copy, or named fixes, is recorded; G1 recorded in the Test record.

### - [x] FEAT-016-T14 — `PrivacyScreen` and pick-screen entry control
- **Implements:** FR-2, FR-3, FR-4, NFR-2, NFR-6, NFR-10 · **ADRs:** ADR-001
- **Depends on:** T13 (G1)
- **Size:** M
- **Scope:** `lib/features/privacy/presentation/privacy_screen.dart` (stateless, ARB text only, no provider, no log); `PickView` gets `onPrivacy` and the entry control per G1; `PickScreen` pushes `PrivacyScreen` with `MaterialPageRoute<void>`. No `PopScope`. No `pubspec.yaml` or Gradle change.
- **Done when:** `test/features/privacy/privacy_screen_test.dart` passes: tap the entry control on a pumped `PickScreen` → title shown (1 tap, AC-2.1); Back → pick screen with the same `PickController` state; the 6 headings are header semantics in order (a)–(f) followed by their bodies; no `InkWell`, `GestureDetector` on text, link semantics, `Image` or progress indicator in the tree (FR-4, AC-2.2); a share-in while open returns to the first route (`popUntil`); the entry control is ≥ 48 dp. T06 scan still green (NFR-6); `git diff --quiet pubspec.yaml pubspec.lock android/app/build.gradle.kts` apart from T02–T04 (NFR-10).

### - [x] FEAT-016-T15 — Accessibility, 200% font, RTL, screenshots — gate G2
- **Implements:** NFR-2, NFR-4, FR-1 (on screen), FR-2, NFR-1 (informational) · **ADRs:** —
- **Depends on:** T14
- **Size:** M
- **Scope:** widget tests: `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` on the pick screen and explainer; text scale 2.0 at 360×640 in en and ar with no overflow and all parts reachable by scrolling; ar `TextDirection.rtl`, digits 0-9 only. Screenshots on the Realme 2 Pro (profile build), foreground app checked before each, only ExactSize screens, states from T13. Explainer open time read from a profile trace on the Realme (and on the emulator only if already running), informational.
- **Done when:** tests pass; the screenshots are in the PR (not committed unless the Product Owner asks); phone settings restored (font scale, locale) and build uninstalled; the Product Owner accepted them or named fixes, which are done here; G2 recorded. Until T16 the ar shot shows English privacy text; that is expected.

### - [x] FEAT-016-T16 — Translate privacy strings (es, pt, hi, id, ar) — Product Owner runs `/l10n-translate`
- **Implements:** FR-1, FR-5 (reviewer brief), FR-6, NFR-4 · **ADRs:** —
- **Depends on:** T15 (G2; strings final)
- **Size:** M (not counted: FEAT-019 work)
- **Scope:** the Product Owner types `/l10n-translate <lang>` for es (es-419), pt (pt-BR), hi, id and ar (MSA, Western digits 0-9), one language at a time, vendored `localize-*` skills only. Keys: `pickPrivacyNote` and the 14 `privacy*` keys. **The reviewer brief names the FR-5 banned list** ("never leaves", "no data collected", "100%", "secure", "encrypted", "anonymous", "GPS", "location removed", "compliant", "certified", "GDPR", "PCI", "Bangladesh Bank") **and the rule "claims stay scoped to ExactSize"**; a back-translation that turns a scoped claim into an absolute one holds the string back. Only app strings go to the model, never user data. Keys and descriptions identical to `app_en.arb`; no placeholders; short plain sentences. Status `AI-reviewed only`; never "native-quality" or "native-reviewed". Then add the FR-6 presence-in-6-locales check to `privacy_copy_test.dart`.
- **Done when:** all five ARBs contain the 15 keys; `flutter gen-l10n` reports no untranslated FEAT-016 key; `docs/l10n/ai-review-log.md` has one entry per language with status `AI-reviewed only` and the banned-list check noted; T08 tests (including Latin tokens and the new presence check) pass in all locales; the T15 200% and RTL tests pass in every locale.

### - [x] FEAT-016-T17 — Real-phone offline matrix, release checklist dry run, P2 — gate G-final
- **Implements:** FR-13, FR-14, FR-2, FR-8 (release APK), NFR-2, NFR-3, NFR-8, NFR-9 (evidence) · **ADRs:** —
- **Depends on:** T11, T12, T16
- **Size:** M
- **Scope:** push **P2** after local `flutter analyze` and `flutter test`. On the Realme 2 Pro, release build (debug-signed; Open items 3), airplane mode on with Wi-Fi and mobile data off (state noted, restored after). FR-14 rows in `claims.md`, each with command, expected result, pass/fail: cold start; system picker with a synthetic photo in Download; camera (lens covered, black frame only, the capture deleted at once, never screenshotted); Choose from files; share-in with `am start`; target entry; crop; compress; check; Save; Share (chooser opens, then cancel; no screenshot of the sheet); open explainer (no spinner, no error, AC-2.2). Plus: `aapt2 dump permissions` on the release APK equals the `claims.md` list (FR-8, FR-13); `adb logcat --pid` during the run has only enum lines (no path, URI, name or size; nothing personal copied into the record); register vs explainer (en) compared line by line; AC-3.2 noted as covered by FEAT-001's existing message (no online-only photo is created on the owner's account). TalkBack speech only if the Product Owner installs it (Open items 1).
- **Done when:** every runnable row passes and is recorded with date and device; P2 CI is green (markers, API 28 offline step); synthetic files and any saved outputs deleted with their MediaStore rows; settings restored; test build uninstalled; T12 re-approval (or accepted deviation) recorded; G-final recorded with the Product Owner's acceptance of the Open items. The feature may then go to Implemented through the Product Owner's `/approve`.

## Effort reconciliation
| Tech section 12 line | Tech days | Tasks | Task days |
|---|---|---|---|
| Manifest allow-list, backup, mutations, CI marker | 0.75 | T02 M, T03 M | 1.0 |
| Gradle dependency task and list bootstrap | 0.5 | T04 M | 0.5 |
| Dart package test and list | 0.4 | T05 M | 0.5 |
| Whole-tree scan and self-test | 0.5 | T06 M | 0.5 |
| Copy tests (FR-5, FR-6, FR-15) | 0.3 | T08 M | 0.5 |
| FR-18 handler, test, logcat check | 0.5 | T09 M | 0.5 |
| English copy (15 strings) | 0.3 | T07 S | 0.25 |
| Explainer screen and entry (impeccable, widget tests, screenshots) | 1.0 | T13 S, T14 M, T15 M | 1.25 |
| FR-16 offline cases (one CI run) | 0.5 | T10 M | 0.5 |
| `claims.md`, checklist, FR-19 record | 0.3 | T11 S | 0.25 |
| Real-phone offline matrix | 0.3 | T17 M | 0.5 |
| Not in tech | — | T01 S, T12 S | 0.5 |
| **Total** | **5.4 d ≈ 1.1 pw** | 16 counted tasks | **6.75 d ≈ 1.35 pw** |

The task total is 1.35 d above tech (range 1.0–1.3 pw) and 0.85 pw above the roadmap's 0.5 pw: G0, the PRD clarification, separate backup and manifest PRs, the design gate split and the release-build matrix. Not counted: T16 (FEAT-019) and the Product Owner's design and review time. Cut candidate (PRD OQ-6 alternative, a PRD change for the Product Owner): drop FR-10 (T04, T05), saving about 1.0 d.

## Traceability
| Requirement | Tasks | Notes |
|---|---|---|
| FR-1 | T07, T15, T16 | Scoped wording; five retranslations |
| FR-2 | T13, T14, T15, T17 | 1 tap; Back unchanged |
| FR-3 | T07, T08, T11, T14 | Word and sentence counts; C-ID map |
| FR-4 | T06, T14 | WebView/`url_launcher` banned; no link widget |
| FR-5 | T08, T16 | English test; reviewer brief carries the list |
| FR-6 | T07, T08, T16 | Presence in 6 locales added in T16 |
| FR-7 | T07, T08 | `exportPrivacy` unchanged, now checked |
| FR-8 | T01, T02, T17 | Release APK permissions |
| FR-9 | T06 | Deny by default, empty exempt map |
| FR-10 | T04, T05, T12 | Should; Gradle half in release build (OQ-T1) |
| FR-11 | T01, T02, T04, T05, T06, T10, T12 | Marker files asserted in CI |
| FR-12 | T02, T04, T05, T06, T11 | Messages point to `claims.md` |
| FR-13 | T11, T17 | Includes debug-signing row |
| FR-14 | T11, T17 | Manual, real phone, release build |
| FR-15 | T06, T08 | Tokens and copy words |
| FR-16 | T10 | Should |
| FR-17 | T03, T10 | Should; API 36 phone and API 28 CI |
| FR-18 | T09 | Should; gap confirmed in tech 8.3 |
| FR-19 | T11 | Recorded only; built by FEAT-025, 013, 027 |
| NFR-1 | T10, T15 | CI time and open time, informational |
| NFR-2 | T13, T14, T15, T17 | TalkBack speech: Open items 1 |
| NFR-3 | T10, T17 | |
| NFR-4 | T07, T15, T16 | `AI-reviewed only` |
| NFR-5 | T02, T03, T04, T05, T06 | Self-tests, floors, no skip flag |
| NFR-6 | T06, T09, T14 | No log or counter for opens |
| NFR-7 | T07, T08, T11 | C-IDs in `@` descriptions |
| NFR-8 | T09, T10, T17 | Synthetic fixtures, `[PLACEHOLDER]` |
| NFR-9 | T03, T10, T17 | API 28 in CI, API 36 phone |
| NFR-10 | T04, T05, T14 | No new dependency |

**Not covered by a task:** PRD OQ-7 combined compliance review (Data safety reading, PCI "opaque image" reading, local data-protection law, platform crash data) is release work for the Product Owner; filling the store listing and Data safety form, and the privacy policy text and URL `[PLACEHOLDER]` (OQ-4), are store-release work using `claims.md`; copying FR-19 into FEAT-025, FEAT-013 and FEAT-027 PRDs happens at their `/draft-prd`; the stale "no-ads MVP" roadmap text (PRD OQ-2) is the Product Owner's edit.

## Open items
1. **TalkBack** is not installed on the Realme 2 Pro. AC-2.5 reading order is covered by semantics tests (T14, T15); speech is checked only if the Product Owner installs TalkBack.
2. **Roadmap effort row.** 1.35 pw here against tech 1.1 pw and roadmap 0.5 pw; the Product Owner decides whether the row changes (PRD OQ-10, OQ-T4).
3. **Debug-signed release.** The release build uses the debug key (tech section 7). T17 tests that build; fixing signing is a `claims.md` release-checklist row only, not a task here.
4. **Inconsistencies found:**
   a. AC-4.3 says the dependency check fails in `flutter test`; the Gradle half fails in the release build (OQ-T1). T12.
   b. FR-11 asks for a CI log line; tech uses marker files because non-verbose builds hide it. T12.
   c. Tech risk table plans the `bmgr` check on "the local API 36 emulator"; this plan uses the Realme 2 Pro (device rule) and API 28 in CI.
   d. PRD goal "0 extra CI minutes" and NFR-1 "≤ 1 min added" versus tech FR-16 "about 1 min extra" plus the new tests and Gradle tasks: the sum may pass 1 min. T10 measures it; if over, the Product Owner accepts or clarifies NFR-1.
   e. FR-6 "present in all six locales" cannot hold between T07 and T16; the check lands in T16, and the five locales keep the old absolute `pickPrivacyNote` until then (do not release in between).
   f. FR-14 camera, picker and share rows on a real phone touch the owner's data; T17 uses a covered lens and no screenshots of system UI.
   g. NFR-1 names the 2 GB emulator profile; local runs use the Realme 2 Pro, the emulator only if already running.
5. **Backup device-to-device transfer** (API 31+) has no adb check; it rests on lint and the gate [Hypothesis].
6. **Airplane mode is not offline on the Realme 2 Pro.** Wi-Fi stays connected in airplane mode (T10 Test record). Every offline row uses airplane mode plus Wi-Fi off and mobile data off, checked with `ping` first (`claims.md` section 5). The FEAT-006 T17 airplane row did not prove offline; whether to correct the FEAT-006 record (an Implemented doc) is the Product Owner's call.

## Test record
_Filled in by T01, T03, T09, T10, T13, T15, T16 and T17 (one row per check and device: date, device or CI run, result). Synthetic images only. No file names, URIs, paths of real files, image content or anything personal seen on the phone; use `[PLACEHOLDER]` for anything sensitive._

| Date | Task | Check | Device / run | Result |
|---|---|---|---|---|
| 2026-11-26 | T01 | H1: `dart pub deps --json` (Dart 3.50.1 SDK, Windows): top-level `root`, `packages`, `sdks`, `executables`; each package has `name`, `version`, `kind` (`root`, `direct`, `dev`, `transitive`), `source`, `dependencies`, `directDependencies`, `devDependencies`, `dependencyConstraints`. The root's `directDependencies` (14) and `devDependencies` (7) separate runtime from dev. Runtime closure from `directDependencies` through `dependencies`: 67 packages; no `http`. It contains test packages (`flutter_test`, `leak_tracker*`, `vm_service`, `test_api`) because `flutter_riverpod` 3.5 depends on `flutter_test`, and build-hook packages (`hooks`, `native_toolchain_c`, `code_assets`, `record_use`, `process` …) through `es_codec`; T05 lists them with notes ("test-only API, not used by app code", "build-time hook, not in APK"). No fallback needed | Host (Windows), Flutter 3.50.1 | Pass |
| 2026-11-26 | T01 | H2: `flutter build apk --release -v`: the task graph contains `:app:checkMergedManifest` after `processReleaseMainManifest` and before `assembleRelease`; it logs "checkMergedManifest: OK (5 self-test mutations refused)". A non-verbose `flutter build apk --release` prints no line from the task (0 matches), so the tech plan's marker files (FR-11, risk 2) are needed | Host (Windows), release build | Pass |
| 2026-11-26 | T01 | H3: `aapt2 dump permissions` (build-tools 36.1.0) on the release APK: `uses-permission` `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion` 28; `permission` and `uses-permission` `com.exactsize.exact_size.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; no INTERNET, no network-state or AD_ID permission. The FEAT-007 T23 "profile build" ambiguity is settled for the release APK. The release manifest has no `allowBackup`, `dataExtractionRules` or `fullBackupContent` attribute (PRD gap 8 confirmed). T02 allow-list = these two names | Host (Windows), release APK | Pass |
| 2026-11-26 | T01 | H4: 98 `.dart` files under `lib/` (8 generated and tracked: 7 `app_localizations*.dart`, `injection.config.dart`); 4 `.kt` files under `android/app/src/main/kotlin`; 1 `.java` (`GeneratedPluginRegistrant.java`), git-ignored and regenerated by the Flutter tool, so it is scanned when present but not counted in the floor. NFR-5 floors for T06: Dart under `lib/` at least 85, Kotlin at least 4 | Host (Windows) | Recorded |
| 2026-11-26 | T01 | Gate G0: passed. All four hypotheses hold; no tech.md change needed. T02 and T05 may start | — | Pass |
| 2026-11-27 | T03 | Release build: `checkMergedManifest: OK (13 self-test mutations refused)` with the four backup mutations (allowBackup removed, allowBackup true, dataExtractionRules missing, device-transfer loses one exclude); marker written | Host (Windows), release build | Pass |
| 2026-11-27 | T03 | `gradlew :app:lintRelease`: no finding on `data_extraction_rules.xml`. One warning (DataExtractionRules) asks for `fullBackupContent` for API 28-30; left out on purpose (tech section 11: `allowBackup="false"` already covers those levels). The 2 lint errors are in the untracked, machine-local `android/local.properties` (path escaping), unrelated and pre-existing | Host (Windows) | Pass |
| 2026-11-27 | T03 | Real phone: Backup Manager found disabled (`bmgr enabled`), not changed. Release build installed: package flags without `ALLOW_BACKUP`; `bmgr backupnow com.exactsize.exact_size` gives "Backup is not allowed". Build uninstalled; Backup Manager still disabled. Device-to-device transfer has no adb test: covered by lint and the gate only [Hypothesis stays]. API 28 `bmgr` check runs at P1 (T10) | Realme 2 Pro, API 36, release build (debug-signed) | Pass |
| 2026-11-27 | T09 | Release logcat, throwaway probe entry point (not committed) that reports one framework error and throws one async error, each message holding `[PLACEHOLDER_PATH]`. Without the handler: `I flutter : Exception: framework [PLACEHOLDER_PATH]` and `E flutter : … Unhandled Exception: Exception: async [PLACEHOLDER_PATH]`, so release builds do print exception text (PRD gap 7 is now a [Fact]). With `installUncaughtErrorLog()`: only `exactsize.app outcome=UNCAUGHT source=FRAMEWORK` and `… source=PLATFORM`. Probe deleted, build uninstalled, no screenshot | Realme 2 Pro, API 36, release build | Pass |
| 2026-11-27 | T10 | `integration_test/offline_test.dart` with `--dart-define=OFFLINE=true`: compression, crop to compression (synthetic 800x600 JPEG probed, default crop to 300x300, compressed) and preview check (output measured as 320x240 with its byte length, decoded `PreviewOk`) pass, 3/3. Airplane mode alone was **not** offline on this phone: Wi-Fi stayed connected (`wifi_on` 2, `ping 1.1.1.1` answered, DNS probe resolved, so the first run failed its offline check). The passing run had airplane mode on **and** `svc wifi disable` (`ping`: "Network is unreachable"); state restored to airplane 0, Wi-Fi 1, mobile data 0; build removed | Realme 2 Pro, API 36, debug build | Pass |
| 2026-11-27 | T10 | P1 (commit 64a2740): all 3 jobs green. "Privacy gates ran" step passes (both marker files present after the release build); the offline step on API 28 passes the 3 offline cases. Job times against the last green run (45863467485): build 9 min 8 s vs 8 min 9 s (+59 s), emulator 20 min 13 s vs 19 min 36 s (+37 s); NFR-1 target is 1 minute or less | CI API 28, run 45875422502 | Pass |
| 2026-11-27 | T10 | API 28 backup, slim throwaway run (branch never merged, deleted after): release APK installed, `getprop ro.build.version.sdk` = 28, package flags `[ HAS_CODE ALLOW_CLEAR_USER_DATA ]` (no ALLOW_BACKUP), `bmgr backupnow` gives "Package com.exactsize.exact_size with result: Backup is not allowed". Backup Manager was disabled, enabled for the check, disabled again. First attempt (45875475653) did not boot the emulator (runner disk full); rerun with the usual disk cleanup | CI API 28 emulator, run 45877836926 | Pass |
| 2026-11-27 | T10 | Finding for earlier records: because Wi-Fi stays on in airplane mode on this phone, the FEAT-006 T17 row "AC-6.4, NFR-3: airplane mode on (Wi-Fi off)" did not prove offline (the run noted `wifi_on` 2, the same state as today). Its result (check and Save work) is not in doubt, and FEAT-016 T10 now proves the pipeline offline on the phone and on API 28; T17 re-runs Save and Share offline with Wi-Fi off (Open items 6). FEAT-006 docs are Implemented and are not edited here | Realme 2 Pro, API 36 | Recorded |
| 2026-11-27 | T12 | PRD 1.1 (AC-4.3, FR-11 wording, no scope change) re-approved by the Product Owner (`/approve FEAT-016`) | Product Owner | Approved |
| 2026-11-27 | T13 | Gate G1: lean impeccable design (t13/explainer_design.md, 2026-11-27) and the T07 English copy accepted by the Product Owner with the default title placement (title in the scroll body, app bar with Back only) | Product Owner | Accepted |
| 2026-11-27 | T15 | `privacy_a11y_test.dart`: tap-target, labelled-target and text-contrast guidelines pass on the pick screen with the entry and on the explainer; en and ar at 200% on 360x640 have no overflow, every part is reachable by scrolling and the entry stays at least 48 dp; ar is right to left with the title at the right edge and no Eastern digits | Host (Windows), flutter test | Pass |
| 2026-11-27 | T15 | G2 screenshots (profile build, foreground app checked before each, only ExactSize screens, status bar cropped): pick screen with the entry (en), explainer top and bottom (en), explainer in ar (English text until T16), explainer at 200% font. Explainer push, informational: 2 frames rendered, 0 janky, 50th and 90th percentile 10 ms (`dumpsys gfxinfo`). Settings: rotation locked to portrait for the run, then auto-rotate restored to on (found on); font scale 2.0 then back to 0.85; app language ar then cleared by uninstall; build uninstalled | Realme 2 Pro, API 36, profile build | Pass |
| 2026-11-27 | T15 | Gate G2: the Product Owner accepted the five screenshots with no fixes. Known until T16: the ar shot shows the English privacy text | Product Owner | Accepted |
| 2026-11-27 | T16 | `/l10n-translate` es, pt, hi, id, ar (run by the Product Owner): 15 keys each (pickPrivacyNote and the 14 privacy* keys), drafted by Claude Opus 5.5, blind review by Claude Sonnet and second blind review of all keys by Claude Haiku with the FR-5 banned list; 29 fixes (es 5, pt 3, hi 7, id 8, ar 6), open list none, status AI-reviewed only. `untranslated_messages.json` is `{}`; the new presence check (every locale has every privacy key, not English) and the 200% test in all 7 supported locales pass; 611 tests pass, analyze clean | Host (Windows) | Pass |
| 2026-11-27 | T17 | Release APK (`aapt2 dump permissions`, build-tools 36.1.0): WRITE_EXTERNAL_STORAGE max API 28 and the app's DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, equal to `claims.md` section 3 (FR-8, FR-13) | Host (Windows), release APK | Pass |
| 2026-11-27 | T17 | FR-14 offline matrix (airplane mode on, Wi-Fi off, mobile data off; `ping 1.1.1.1` "Network is unreachable" first): cold start, Choose from files (synthetic file picked by its name only), share-in, target, crop, compress, check (Matches), Save (saved message), Share (chooser opens, cancelled, no screenshot), explainer (opens at once, no progress indicator) pass. System photo picker and camera opened offline and were cancelled without a selection or capture: the picker's newest item was not the synthetic photo (MediaStore check), and a camera capture would show the room; their accept path is the one the files and share-in rows used. Results in `claims.md` section 5 | Realme 2 Pro, API 36, release build (debug-signed) | Pass (picker and camera rows open and return only) |
| 2026-11-27 | T17 | `adb logcat --pid` of the release app during the run: app lines are outcome codes only (pick ACCEPTED x2, CANCELLED x2, crop and compression SUCCESS, preview SPEC_MEETS, export SAVED and SHARE_OPENED); no `exactsize-` name, `/storage/`, `content://`, file name, size or dimension | Realme 2 Pro, API 36, release build | Pass |
| 2026-11-27 | T17 | Register vs English explainer: each part's sentences map to its claim IDs (C1, C3 / C2 / C4, C5 / C8 / C9 / C10; checked by `privacy_copy_test.dart`), no sentence claims C6 or C7, and the pick line maps to C1. AC-3.2 (online-only photo offline) is covered by FEAT-001's existing `pickSourceUnavailable` message; no online-only photo was created on the owner's account | Host | Pass |
| 2026-11-27 | T17 | Cleanup: the synthetic source in Download and the saved output in Pictures/ExactSize deleted with their MediaStore rows (none left from the run); `/sdcard/ui.xml` removed; build uninstalled. Settings as found: airplane 0, Wi-Fi 1, mobile data 0, font 0.85, auto-rotate 1 (locked to portrait for the run; it switched itself back on once mid-run, as in earlier runs), user rotation 0 | Realme 2 Pro, API 36 | Done |
| 2026-11-27 | T17 | P2 (commit 7a9973f): all 3 jobs green; the "Privacy gates ran" marker step passes and the 3 offline cases pass on API 28 | CI API 28, run 45886183791 | Pass |
| 2026-11-27 | T17 | Gate G-final: the Product Owner accepted the run and the gaps: TalkBack speech not checked (Open items 1); effort 1.35 pw vs roadmap 0.5 pw, roadmap row unchanged (2); debug-signed release, checklist row only (3); CI time +59 s build and +37 s emulator job (4d); photo picker and camera rows checked as open-and-return only (4f); device-to-device backup rests on lint and the gate (5); the FEAT-006 T17 airplane row stays as recorded (6) | Product Owner | Passed |

## Instructions for Claude Code
- Read `prd.md`, `tech.md`, ADR-001, ADR-006 and ADR-007 before starting a task.
- Implement only the current task, in order; tick its checkbox, commit, and add a line to `docs/CHANGELOG.md` when done. Push only at P1 (T10) and P2 (T17), or for a slim throwaway run a task names; run `flutter analyze` and `flutter test` locally first.
- Gates: no manifest or Dart-dependency work (T02, T05) before G0; no visible UI work (T14, T15) before G1; T16 only after G2; stop at every failing gate and report to the Product Owner.
- UI rule: before designing or building any real UI screen, stop and tell the Product Owner (impeccable, decision 2026-11-20). T13 is that stop. impeccable runs lean: no image comps, no reviewer subagents, one round, one screenshot per key state.
- Never loosen a gate (allow-list, exempt map, reviewed lists, banned phrases, floors) or use `tools:node="remove"` or a skip flag without the FR-12 procedure and a Product Owner decision.
- Never set a PRD or tech status to Approved, Rejected or Implemented; T12 sets `Under Discussion` only, and the Product Owner re-approves with `/approve`.
- Translations only through `/l10n-translate <lang>` typed by the Product Owner, status `AI-reviewed only`, reviewer brief with the FR-5 list.
- Device: check `adb devices` first; Realme 2 Pro for local runs; API 28 only in CI; check the foreground app before every screenshot; never record personal data seen on the phone; restore every changed setting; uninstall the test build after.
- Privacy: synthetic test images only; `[PLACEHOLDER]` for every credential, key, URL or sensitive value. No network call, clipboard use, persistence or explainer-open logging.
- If a requirement is unclear or wrong, stop and propose a PRD change.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-26 | First draft |
| 1.0 | 2026-11-26 | Approved by the Product Owner |
