---
id: FEAT-007
title: Export and share
status: Under Discussion
version: 1.2
updated: 2026-11-25
links: [ROADMAP, BRIEF, RESEARCH, ADR-001, ADR-006, FEAT-001, FEAT-002, FEAT-004, FEAT-005, FEAT-006, FEAT-010, FEAT-016, FEAT-018, FEAT-019, FEAT-022, FEAT-023, FEAT-025, FEAT-027]
---

# FEAT-007 — Export and share

## 1. Overview
FEAT-007 is the last step of the flow. It takes the file FEAT-004 produced (a temp file in app-private cache) and lets the user get it out of the app in one of two ways: **Save** (a copy in the phone's gallery or shared storage) or **Share** (hand the file to another app through the Android share sheet). The bytes are never changed. Nothing is uploaded by ExactSize and no network is used; the file leaves the phone only through the user's own share action. At the end of the flow it deletes the temp file and calls FEAT-001 `release()`. Release: MVP (R1 Phase A), Must, roadmap effort 0.5 pw, RICE 60000 [Fact](docs/roadmap.md, FEAT-007 row). The scope below probably exceeds 0.5 pw, as happened to FEAT-001, 002 and 004: [Assumption] 1.0–1.5 pw (two Android write paths by API level, a share provider, a build check, six-language strings, kill and low-space tests); Stage 6 re-estimates.

**Contract (what FEAT-007 receives and owns)**
| Item | Contract |
|---|---|
| Input | `CompressionSuccess`: `tempFilePath`, `sizeBytes`, `format` (jpeg or png), notices [Fact](lib/features/compression/domain/compression_result.dart). Output pixel size W×H comes from the target (`TargetSpec`) [Fact](docs/features/FEAT-005-manual-target/prd.md, section 1). A `CompressionFailure` carries no path, so a failed or out-of-range file can never reach export [Fact](lib/features/compression/domain/compression_result.dart; docs/features/FEAT-004-kb-range-compression/prd.md, FR-6, AC-4.3). |
| Ownership | Ownership of the success file passes to FEAT-006/FEAT-007, which delete it after export or discard; the start-up sweep removes leftovers [Fact](docs/features/FEAT-004-kb-range-compression/tech.md, data section; FEAT-004 FR-20). Today `CompressionController.cancel()` deletes an unexported result and a new run replaces it [Fact](lib/features/compression/presentation/compression_providers.dart). The file lives in `<cache>/exactsize_out/<random>.jpg\|png` [Fact](lib/features/compression/data/temp_files.dart). |
| Flow position | pick (FEAT-001) → target (FEAT-005) → crop (FEAT-002) → compress (FEAT-004) → preview (FEAT-006) → export (FEAT-007) [Fact](FEAT-001 prd section 5 step 6; FEAT-005 prd section 5; FEAT-004 prd section 5 step 5). |
| Today | A dev-only stand-in screen shows the run state; FEAT-006 is meant to replace it [Fact](lib/app_flow.dart, `_AfterCropStandIn`). |
| End of flow | Start-over calls `release()` on the pick controller (deletes the camera file) and ends the crop session [Fact](docs/features/FEAT-001-pick-image/prd.md, FR-11; lib/app_flow.dart, `_chooseAnother`). |

**Scope boundaries**
| Owned by FEAT-007 | Owned elsewhere (not duplicated here) |
|---|---|
| Save to shared storage; Share through the share sheet; file name and MIME of what leaves the app; the API 28 write permission; export messages; temp-file cleanup and `release()` at flow end | Preview and "meets spec" display: **FEAT-006**. Size and format of the file: **FEAT-004** |
| What the default exported name contains (FR-4) | Customer-named files and recents: **FEAT-023** (operator, Later). Batch export: **FEAT-022** (Later) |
| Never editing the bytes (FR-3) | EXIF/GPS stripping: **FEAT-018** (FEAT-004 writes metadata inside its size search and nothing edits the file afterwards [Fact](FEAT-004 prd section 11)). DPI: **FEAT-010** |
| Messages and strings for export | Privacy explainer, no-network verification: **FEAT-016**. Translation: **FEAT-019**. Ads: **FEAT-025** |

**Default behaviour without FEAT-018 and FEAT-023.** The exported file is exactly what FEAT-004 produced. Its name is `exactsize-<W>x<H>-<TOKEN>.jpg|png` (for example `exactsize-300x300-[TOKEN].jpg`): fixed prefix, the output pixel size, and 6 random characters. It never contains the user's name, a source file name, a date or time, a device value or any other personal data, because the receiving app and the portal can read it (FR-4).

## 2. Problem statement
Applicants, students, operators and visa applicants finish the crop and size steps, but the result sits in app-private cache where the portal's upload picker cannot see it [Fact](FEAT-004 prd section 10: nothing is written to public storage until the user exports). Without export the output cannot reach the portal [Fact](docs/roadmap.md, FEAT-007 rationale). The vision's metric is under 30 s median from opening the app to an exported file [Fact](docs/product/vision.md, success metrics), so export must be one tap on most phones.

**Evidence gap.** `docs/research/competitors.md` has no finding on how rival tools save or share (its gaps cover KB range, privacy, signatures, batch and languages), so nothing here is benchmarked against competitors. The Android claims below are [Hypothesis] from Android developer documentation, not re-verified in this session. Stage 6 must confirm each one.
- **H1** From Android 10 (API 29) an app can add its own image to Pictures through MediaStore with no permission, and a pending flag hides the row from other apps until the write is finished.
- **H2** On Android 9 (API 28) writing to public Pictures needs `WRITE_EXTERNAL_STORAGE` at runtime; the manifest entry can be capped with `maxSdkVersion="28"`. The Android docs say an app that declares WRITE is implicitly granted READ, so on API 28 the grant would also let ExactSize read the user's shared storage (see section 10, flag 1).
- **H3** The system "save as" dialog (`ACTION_CREATE_DOCUMENT`) needs no permission on any API level.
- **H4** The share sheet does not tell the app whether the user completed the share, and the receiving app may read the file later than the moment it is picked.
- **H5** A `FileProvider` returns the real file name as the display name, so the receiving app would see the cache file's random hex name unless the file carries the FR-4 name.
- **H6** Some chat and social apps recompress images they send as photos, which changes the KB. Widely reported, not in our research.
- **H7** Whether a gallery app shows a folder, and whether a cloud gallery backs it up, depends on the gallery app, the phone maker and user settings.

## 3. Goals & success metrics
| Goal | Metric | Target |
|---|---|---|
| Export works first time | Saves with enough space (and, on API 28, permission granted) that end in a complete, readable file | 100% on the R1 emulator matrix, API 28 and latest [Fact](docs/roadmap.md, Phase A exit) |
| Output untouched | Saved or shared file equals the FEAT-004 file (length and SHA-256 in tests) | 100%; 0 re-encodes |
| No partial file | Visible incomplete files after a process kill during save (kill test, 20 kills at random points per API level) | 0 |
| Fast | Tap Save to confirmation for a file up to 1 MB on the 2 GB emulator profile | ≤ 1 s median [Assumption]; feeds the under-30 s journey [Fact](vision) |
| Few taps | Taps from the result to a saved file | 1 on API 29+; 2 on API 28 (Save, Allow) |
| Least privilege | Permissions added by this feature | 0 on API 29+; only `WRITE_EXTERNAL_STORAGE` capped at API 28 (FR-8) |
| Nothing left behind | Files of this session left in app storage after the flow ends, incl. camera file | 0 |
| Private logs | File names, URIs, paths or sizes in release logs and crash reports | 0 |
| No network | Network calls made by export | 0 (verified under FEAT-016) |
| Honest status | "Saved" shown when not saved, or "sent" shown for a share | 0 |

First-try success (the vision's 99%) is measured in pre-release device tests, not production telemetry [Fact](FEAT-004 prd, OQ-11, decided 2026-11-20); FEAT-007 adds no counter in R1.

**Non-goals:** uploading to portals; editing or watermarking; EXIF stripping (FEAT-018); custom names (FEAT-023); batch or multi-file share (FEAT-022); export history or recents; cloud save; exporting an out-of-range file [Fact](FEAT-004 OQ-7: no export-anyway in R1); a second format or PDF; telling the user whether the receiving app accepted the file.

## 4. User stories
- **US-1** As an applicant, I want to save the result to my phone with one tap, so that I can pick it in the portal's upload dialog.
  - **AC-1.1** Given a successful result on Android 10 or later, when I tap Save, then no permission prompt appears, a copy is saved in `Pictures/ExactSize` (default, OQ-2) and I see "Saved to [FOLDER] as [FILENAME]."
  - **AC-1.2** Given the save finished, when I compare the saved file with the FEAT-004 file, then the bytes are identical and the length equals `sizeBytes`.
  - **AC-1.3** Given the save finished, when I open the Android system file picker and browse Images or the ExactSize folder, then the file is listed under the name shown.
  - **AC-1.4** Given the save finished, when I list the folder, then it holds exactly one new file: no temp, pending, duplicate or `.part` item is visible.
- **US-2** As an applicant on Android 9, I want a permission request only when I tap Save, so that I know why it is asked.
  - **AC-2.1** Given API 28 and no permission, when I tap Save, then the system permission dialog opens; nothing was requested at app start or before this tap.
  - **AC-2.2** Given I allow it, when the dialog closes, then the save runs without another tap and shows the confirmation.
  - **AC-2.3** Given I deny it, when the dialog closes, then nothing is saved, I see the permission message (section 8), the result is kept, and Share (and "Choose where to save", FR-10) work.
  - **AC-2.4** Given I denied with "don't ask again" so the dialog no longer opens, when I tap Save, then the same message appears at once and the app does not loop on the request.
  - **AC-2.5** Given API 29 or later, when I use any export action, then no storage permission is requested.
- **US-3** As an applicant, I want to share the file to another app, so that I can attach it where I am filling the form.
  - **AC-3.1** Given a successful result, when I tap Share, then the system share sheet opens, lists apps that accept the image, and does not list ExactSize.
  - **AC-3.2** Given I choose an app, when it reads the file, then it gets exactly one read-only file with the same bytes and `sizeBytes`, the MIME matching the format, and the FR-4 name.
  - **AC-3.3** Given API 28 and no storage permission, when I tap Share, then it works with no prompt and nothing is written to shared storage.
  - **AC-3.4** Given I dismiss the sheet without choosing, when I am back, then I am on the same screen with no message, the file is still available, and Save and Share still work.
  - **AC-3.5** Given I chose an app and returned, when I look at the screen, then it shows no "sent" or delivery status.
- **US-4** As a user with a nearly full phone, I want a plain message and a way to retry, so that a failed save costs me nothing.
  - **AC-4.1** Given there is not enough free space, when I tap Save, then I see the no-space message, no partial file exists in shared storage, and the result is kept.
  - **AC-4.2** Given I freed space, when I tap Save again, then the save succeeds without running the compression again.
  - **AC-4.3** Given any other write failure (storage removed, provider returns nothing), when I tap Save, then I see the save-failed message, no partial file remains and Save can be retried.
  - **AC-4.4** Given the share sheet cannot be opened, when I tap Share, then I see the share-failed message and the result is kept.
- **US-5** As a user, I want Save to be safe to tap twice, so that I do not get duplicate copies of my ID photo.
  - **AC-5.1** Given a save is running, when I tap Save again, then nothing happens and one file is created.
  - **AC-5.2** Given I already saved this result and the saved file still exists, when I tap Save, then I see "Already saved as [FILENAME] in [FOLDER]." and no second file is created.
  - **AC-5.3** Given I saved, then deleted that file in my gallery, when I tap Save, then it is saved again.
  - **AC-5.4** Given I tap Share twice, when each sheet closes, then no extra copy exists in shared storage.
- **US-6** As a cyber café operator, I want every export to get a unique, neutral name, so that different customers' files never overwrite each other and no name reveals a customer.
  - **AC-6.1** Given 100 exports in a row with the same size, when I list the folder, then there are 100 distinct files and none was overwritten.
  - **AC-6.2** Given any export, when I read the name, then it matches the FR-4 pattern and contains no personal data.
  - **AC-6.3** Given a file with the chosen name already exists, when I save, then the existing file is untouched and the new file gets another name, shown in the confirmation.
- **US-7** As a user whose gallery app does not show the saved file, I want to see where it went, so that I can still upload it.
  - **AC-7.1** Given a save succeeded, when I read the confirmation, then it names the folder and file in plain words and stays until I leave the screen.
  - **AC-7.2** Given a save succeeded, when I tap Open (Should, FR-15), then the saved file opens in a viewer app.
  - **AC-7.3** Given no app can open it, when I tap Open, then I see a short message and Share still works.
- **US-8** As a user with an ID photo or signature, I want the app to leave nothing behind except what I chose to save, so that my image is not scattered.
  - **AC-8.1** Given I leave the export step (Start over, Done or back), when I check, then the temp file is deleted, the camera file is released and the only copy left is the one I saved.
  - **AC-8.2** Given I saved nothing and shared nothing, when I press back, then I am asked "Leave without saving? The new file will be deleted. Your gallery photos stay as they are." (Should) and Stay keeps me on the screen.
  - **AC-8.3** Given the app is killed while I am on the export screen, when I reopen it, then it starts on the pick screen with no restored result and the cache holds no output file after the start-up sweep.
  - **AC-8.4** Given I saved and the app was killed afterwards, when I look in the gallery, then my saved file is complete and unchanged.
  - **AC-8.5** Given a full export session, when release logs and crash reports are read, then they hold only enum outcome codes: no file name, URI, path or size.
- **US-9** As a Spanish, Portuguese, Hindi, Indonesian or Arabic speaker, or a TalkBack user, I want the export screen in my language and announced, so that I understand what happened.
  - **AC-9.1** Given any of the 6 languages, when I use export, then every label and message is in that language; in Arabic the layout is mirrored and the file name and folder path stay left-to-right and unbroken, with digits 0-9.
  - **AC-9.2** Given TalkBack is on, when a save succeeds or fails, then the result is announced once; buttons are at least 48 dp; status is never shown by colour alone.

## 5. User flows
**Main flow (Android 10+)**
1. FEAT-004 returns success. The result screen shows the achieved size and format, the Save and Share actions and the one-line privacy note (FR-26).
2. The user taps Save. The app checks the temp file (FR-2), writes a hidden pending item in `Pictures/ExactSize`, copies the bytes (FR-3), checks the length, makes the item visible and shows the confirmation with Open (FR-6, FR-11).
3. Or the user taps Share. The app opens the chooser with one read-only file named by FR-4, without ExactSize in the list (FR-17). No status follows (FR-19).
4. The user taps Start over or Done (or back, with the FR-23 check). The temp file is deleted, `release()` runs, the crop session ends, and the pick screen opens (FR-22).

**Alternate flows**
- **Android 9 Save (FR-7):** Save asks for the permission once; on allow it writes a `.part` file in public Pictures/ExactSize, checks it, renames it to the final name and asks the media scanner to index it.
- **Permission denied (FR-9, FR-10):** message with Share and "Choose where to save"; the save-as dialog writes through the URI the user picks; cancelling it changes nothing.
- **Save again (FR-12):** checks the saved item exists; shows "Already saved" or saves again.
- **Leave while saving (FR-24):** the leave action waits for the write to finish or fail.

**Error flows:** `NO_SPACE`, `SAVE_FAILED`, `PERMISSION_DENIED`, `FILE_MISSING`, `SHARE_FAILED`. In all of them the result is kept (except `FILE_MISSING`), no partial file stays, and the user can retry or use the other action. Success and info codes: `SAVED`, `ALREADY_SAVED`, `SHARE_OPENED`, `SAVE_CANCELLED` (save-as dialog closed), `OPEN_NO_VIEWER` (Open tapped, no app can open the file; Save and Share still work).

**Behaviour until FEAT-006 exists (FR-29).** FEAT-007 builds the export area as a self-contained panel that takes one `CompressionSuccess` plus the output size and shows Save, Share, messages and the privacy note. It also builds a minimal result screen that replaces the dev stand-in for Phase A testing: progress with Cancel while running (existing behaviour), the existing failure message from the FEAT-004 outcome messages with a way back, and on success the line "Ready: [W] × [H] px, [SIZE] KB, [FORMAT]" plus the panel. The numbers come from FEAT-004's result and are not recomputed (FEAT-004 FR-19). The screen shows no image preview and makes no "meets spec" claim; both belong to FEAT-006. When FEAT-006 ships it takes over the screen and embeds the panel, so FEAT-007 needs no change. If FEAT-006 is built first, FEAT-007 is only the panel. Whether to build 007 before 006 is OQ-3.

## 6. Functional requirements
| ID | Requirement | Story | Priority (MoSCoW) |
|---|---|---|---|
| FR-1 | The system shall show Save and Share only for a `CompressionSuccess`, together with the achieved format and size from the result. It shall show neither while a run is in progress nor after a failure. | US-1, US-3 | Must |
| FR-2 | Before any save or share the system shall check that the temp file exists and that its byte length equals `sizeBytes`. If not, nothing is exported and the `FILE_MISSING` message is shown. | US-4 | Must |
| FR-3 | The system shall write the bytes of the FEAT-004 file unchanged, for Save and for Share: no decode, re-encode, resize, metadata edit or recompression. After a save it shall compare the written length with `sizeBytes`; on mismatch it shall delete the copy and report `SAVE_FAILED`. | US-1, US-3 | Must |
| FR-4 | The exported file name shall match `exactsize-<W>x<H>-<TOKEN>.<ext>`: W and H are the output pixels in ASCII digits (1 to 6 each), TOKEN is 6 characters from `a-z0-9` drawn from a secure random source for each export, `ext` is `jpg` or `png` in lower case matching the format. Length is at most 40 characters. The name is the same in all 6 languages and shall contain no user name, source file name, date, time, device value or value derived from the image. | US-6 | Must |
| FR-5 | The name the receiving app reads on Share (the display name of the shared item) and the name stored on Save shall both follow FR-4, not the random cache name. | US-3, US-6 | Must |
| FR-6 | On Android 10 and later, Save shall add the file through MediaStore to `Pictures/ExactSize` with the MIME of the format, with no permission. The item shall stay hidden (pending) until the bytes are complete and checked (FR-3), then become visible. | US-1 | Must |
| FR-7 | On Android 9, Save shall request `WRITE_EXTERNAL_STORAGE` at runtime only when the user taps Save and the permission is missing. After a grant it shall write the full file under a non-media temporary name in the ExactSize folder of public Pictures, check it (FR-3), rename it to the final name and request a media scan. | US-2 | Must |
| FR-8 | The manifest shall declare `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion="28"` and no other storage or media permission. The merged-manifest build check shall fail on `WRITE_EXTERNAL_STORAGE` without a cap of 28 or lower, and keeps failing on the permissions it already bans [Fact](android/app/build.gradle.kts, FEAT-001 FR-18). Export code shall never read, list or delete shared-storage items except the items under its own ExactSize folder that it created (FR-16). | US-2 | Must |
| FR-9 | When the permission is refused, the system shall save nothing, keep the result, show the `PERMISSION_DENIED` message and keep Share (and FR-10) available. It shall ask at most once per Save tap. | US-2 | Must |
| FR-10 | The system should offer "Choose where to save" after a refusal on API 28 (and may offer it as a secondary action on every version): it opens the system save-as dialog with the FR-4 name and the right MIME, needs no permission, and writes through the URI the user picks. Closing the dialog changes nothing and shows no message. | US-2, US-4 | Should |
| FR-11 | After a verified save the system shall show "Saved to [FOLDER] as [FILENAME]." as a live region that stays until the user leaves the screen. [FILENAME] is read back from the saved item, so a system conflict rename is shown. After a save-as save, only the name is shown. | US-1, US-7 | Must |
| FR-12 | While a save runs, further Save taps shall be ignored. After a successful save of the current result, Save shall check that the saved item still exists: if yes, show `ALREADY_SAVED` and create nothing; if not, save again. | US-5 | Must |
| FR-13 | Save shall never overwrite or delete an existing file. If the chosen name is taken it shall draw a new TOKEN (at most 5 tries, then `SAVE_FAILED`). On API 29+ the system may instead rename a taken name itself (observed form `<name> (1).<ext>`, FEAT-007-T01 spike); Save then keeps the system name, reads it back and shows it (FR-11). FR-4 and AC-6.2 apply to the name ExactSize requests; a system-added suffix is accepted (odds about 1 in 2 billion per save). | US-6 | Must |
| FR-14 | On a low-space or any other write error the system shall delete the partial output (pending item or `.part` file), keep the temp file, show `NO_SPACE` or `SAVE_FAILED`, and leave Save retryable. | US-4 | Must |
| FR-15 | After a save the system should offer Open, which opens the saved item in a viewer app with a read grant. If no app can handle it, a short message is shown. | US-7 | Should |
| FR-16 | At app start the system shall remove incomplete items it created in shared storage (pending MediaStore items, `.part` files) and nothing else; it shall never remove a completed file. On API 28 it does this only if the permission is already granted and shall never ask for it at start. | US-8 | Must |
| FR-17 | Share shall open the Android chooser for one `ACTION_SEND` stream with MIME `image/jpeg` or `image/png`, a read-only per-intent grant to exactly that file, ExactSize's own components excluded, no storage permission and no write to shared storage. | US-3 | Must |
| FR-18 | The shared URI shall come from a FileProvider that is not exported and is limited to the folder holding the shared file. It shall be separate from the camera provider, or the camera provider's scope change shall be recorded as a FEAT-001 change [Fact](docs/features/FEAT-001-pick-image/prd.md, AC-6.4). The build check and FEAT-001's refusal of "its own FileProvider" in the share target (FR-20 there) shall cover the new authority. | US-3 | Must |
| FR-19 | After the chooser returns, the system shall change no state and show no "shared" or "sent" message. The file stays available until the flow ends. | US-3 | Must |
| FR-20 | If the chooser cannot be launched, the system shall show the `SHARE_FAILED` message and keep the result. | US-4 | Must |
| FR-21 | The system should show one short hint near Share that some chat apps shrink photos and that a form upload is safer from a saved file (text in section 8). | US-3 | Should |
| FR-22 | When the user leaves the export step (Start over, Done, system back) the system shall delete the temp output file and any shared copy, clear the compression state, call FEAT-001 `release()`, end the crop session and open the pick screen. | US-8 | Must |
| FR-23 | If nothing was saved or shared in this session, leaving shall first ask "Leave without saving? The new file will be deleted. Your gallery photos stay as they are." with Stay and Leave. A save-as save counts as saved. | US-8 | Should |
| FR-24 | If the user leaves while a save is writing, the system shall wait for the write to finish or fail (FR-14) before deleting the temp file. Writes longer than 500 ms show progress. | US-8 | Must |
| FR-25 | The system shall keep no export state across process death. After a restart the app opens on the pick screen with no result, file path or saved-item reference [Fact](docs/features/FEAT-001-pick-image/prd.md, FR-16). | US-8 | Must |
| FR-26 | The export area shall show one plain line: "Saving puts a copy in your gallery or a folder you pick. Sharing gives a copy to the app you choose." (final copy belongs to FEAT-016). | US-1, US-3 | Must |
| FR-27 | Logging shall use only the shared enum-only wrapper and only the outcome codes in section 5. File names, URIs, paths, sizes and platform exception text shall never be logged or put in crash reports [Fact](lib/features/compression/data/outcome_log.dart; FEAT-001 FR-19). | US-8 | Must |
| FR-28 | Export shall use no network API and shall pass no file, name or path to any ad, analytics or crash SDK. | US-8 | Must |
| FR-29 | Until FEAT-006 exists, the system shall provide the panel and the minimal result screen described in section 5 and shall remove the dev stand-in. | US-1, US-3 | Must |
| FR-30 | All new strings shall be added to `app_en.arb` with ICU placeholders and translated through FEAT-019 (`/l10n-translate`), status "AI-reviewed only". Placeholders are never translated; paths and file names are shown as isolated left-to-right text. | US-9 | Must |

## 7. Non-functional requirements
| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | Copy runs off the UI thread in chunks (no decode, no full-file buffer beyond the chunk); Save to confirmation ≤ 1 s median for a file up to 1 MB on the 2 GB emulator profile [Assumption]; progress after 500 ms. |
| NFR-2 | Accessibility | TalkBack announces the save result once through a live region; touch targets at least 48 dp; text scales with system font size; no status by colour alone; messages state what happened and one next action. |
| NFR-3 | Offline / poor network | Every export path works in airplane mode and uses no network (FR-28). |
| NFR-4 | Localisation | English, es-419, pt-BR, hi, id, ar (RTL, Western digits 0-9) [Fact](CLAUDE.md, Localization). Messages short and plain; status "AI-reviewed only", never "native-reviewed". |
| NFR-5 | Privacy & security | Least privilege (FR-8); FileProvider not exported and scoped (FR-18); one file per grant; secure random token; enum-only logs (FR-27); the export screen treated as showing identity data. |
| NFR-6 | Reliability | A file visible in shared storage is complete and equals the source; a kill at any point leaves no visible partial file (kill test, section 3). |
| NFR-7 | Compatibility | API 28 to latest; tested on the API 28 and latest emulators [Fact](docs/roadmap.md, Phase A exit). Behaviour on real gallery apps and phone makers is [Hypothesis] until tested on at least one real device. |
| NFR-8 | Store compliance | Play permissions declaration and Data safety answers match section 10; to be verified before release (OQ-10). |
| NFR-9 | Testability | Save and share logic sits behind interfaces so unit tests use a fake store and a fake launcher; MediaStore, permission and kill behaviour are tested on emulators. |

## 8. Validation rules
| Field / input | Rule | Error message |
|---|---|---|
| Source temp file | Exists, readable, length equals `sizeBytes` (FR-2) | "This file is no longer available. Choose the photo again to make a new one." (`FILE_MISSING`) |
| Output format | `jpeg` or `png` only; maps to `image/jpeg` or `image/png` and `jpg` or `png` | Not user-visible; export refused as `SAVE_FAILED` |
| File name | Matches `^exactsize-[0-9]{1,6}x[0-9]{1,6}-[a-z0-9]{6}\.(jpg\|png)$`, at most 40 characters (FR-4) | Not user-visible; after 5 name collisions: "Couldn't save the file. Try again, or share it instead." |
| Storage permission (API 28 only) | Granted before any write (FR-7) | "ExactSize needs your permission to save to your gallery. You can still share the file or choose where to save it." (`PERMISSION_DENIED`) |
| Write | Written length equals `sizeBytes` (FR-3) | No space: "There isn't enough free space on this phone to save the file. Free some space and try again." (`NO_SPACE`). Other: "Couldn't save the file. Try again, or share it instead." (`SAVE_FAILED`) |
| Share intent | One stream, one file, read-only grant, ExactSize excluded (FR-17) | "Couldn't open the share menu. Try again, or save the file instead." (`SHARE_FAILED`) |
| Saved again | Saved item still resolves (FR-12) | Info: "Already saved as [FILENAME] in [FOLDER]." (`ALREADY_SAVED`) |
| Success | Item complete and length verified | "Saved to [FOLDER] as [FILENAME]." (`SAVED`) |
| Open | A viewer app exists (FR-15) | "No app on this phone can open this file. You can still share it." (`OPEN_NO_VIEWER`) |
| Leave | Nothing saved or shared (FR-23) | "Leave without saving? The new file will be deleted. Your gallery photos stay as they are." Buttons: "Stay", "Leave" |
| Share hint (Should) | Shown near Share (FR-21) | "Some chat apps shrink photos. For a form, save the file and choose it in the upload window." |

## 9. Edge cases & error states
| Case | Expected behaviour |
|---|---|
| No free space | Write fails; partial item deleted; temp file kept; `NO_SPACE` message; after the user frees space Save works without re-running compression (AC-4.1, AC-4.2). No space pre-check is required; the write error is the source of truth. |
| Save denied on API 28 | `PERMISSION_DENIED`; nothing written; result kept; Share and save-as stay available; "don't ask again" gives the same message at once without a loop (AC-2.3, AC-2.4). |
| Share sheet dismissed | No message, no state change, file kept, both actions still work (AC-3.4). |
| Target app rejects the file or cannot read it | ExactSize cannot know (H4), so it shows nothing and claims nothing. The user stays on the screen and can Share to another app or Save. If the user already left the screen the file is gone and must be created again (see "Start over right after Share"). |
| Target app recompresses the file | Not detectable; the FR-21 hint steers form uploads to a saved file. The first-try metric covers the file ExactSize produces, not what a chat app does to it [Hypothesis, H6]. |
| Export twice | Save: second tap shows `ALREADY_SAVED`, no second file; saves again if the item was deleted (AC-5.2, AC-5.3). Share twice is fine and writes nothing (AC-5.4). Double tap while saving is ignored (AC-5.1). |
| App killed during save | API 29+: the item is still pending and invisible; the start-up sweep removes it (FR-16). API 28: a `.part` file is not a media file and the sweep removes it when the permission is already granted. No visible partial file. The cache file is swept by FEAT-004's start-up sweep and the user re-runs from the pick screen. |
| Gallery app hides the file | The confirmation names the folder and file; Open (Should) shows the file; the system file picker lists it under Images; Share still works. ExactSize cannot make a gallery app show a folder [Hypothesis, H7]. |
| File name collision | Existing file never touched; new TOKEN drawn (at most 5 tries); on API 29+ a system conflict rename is read back and shown (FR-11, FR-13). |
| Process death after export | The saved copy in shared storage stays complete. The app restarts on the pick screen with no memory of the export (FR-25); the cache temp is swept; no duplicate appears. If the user exports the same photo again it gets a new name. |
| Process death while a receiving app still reads the shared file | The cache file may be swept at the next start, so a slow receiving app may fail [Hypothesis, H4]. Residual risk, accepted for R1; the user can Save and attach from the saved file. |
| Start over right after Share | Leaving deletes the cache file (FR-22). An app that reads the file late fails. Mitigation is the same as above; see OQ-8. |
| User picks ExactSize in the share sheet | Prevented: ExactSize is excluded from the chooser (FR-17). If it were reached anyway, FEAT-001 refuses its own FileProvider URIs [Fact](FEAT-001 prd FR-20) and ExactSize registers as an image share target [Fact](android/app/src/main/AndroidManifest.xml, `ShareTargetActivity`). |
| Permission dialog open when the system kills the app | The request result is dropped; the app restarts on the pick screen (FR-25). No half state. |
| Leave or back while saving | The leave waits for the write (FR-24). |
| Saved file deleted outside the app, then Save | The item no longer resolves; Save saves again (AC-5.3). |
| Storage removed or MediaStore returns nothing | `SAVE_FAILED`; partial output removed; retryable. |
| Save-as dialog closed | `SAVE_CANCELLED`; no message; nothing written. |
| Orientation or font change | The activity handles these without recreation [Fact](android/app/src/main/AndroidManifest.xml, `configChanges`); the panel keeps its state. |
| FEAT-018 not yet built | Export is what FEAT-004 wrote; FEAT-004 re-encodes from pixels so source metadata is not carried over [Fact](FEAT-004 prd FR-2). FEAT-007 adds no metadata to the file (system gallery records such as date added live in the system database, not in the file). |
| Image shows a payment card or another sensitive item | ExactSize cannot know. The file is opaque bytes: no detection, no logging, same handling as any file. |

## 10. Compliance & data privacy
- **Money / payments involved? PCI-DSS scope?** N/A for this feature. FEAT-007 moves an image file and a file name. It handles no card number, token, merchant credential, wallet or payment instrument, and no money moves through it. A user could choose a photo that happens to show a payment card; export treats every file as opaque bytes (no OCR, no detection, nothing logged, nothing sent except by the user's own share), so ExactSize does not store, process or transmit cardholder data on its own account [Assumption: legal reading to be confirmed, OQ-10]. In-app purchases are Google Play Billing (FEAT-026) and out of this feature.
- **Bangladesh Bank requirements that apply:** N/A for this feature, reason: no payment instrument, wallet, payment service or money movement, and no financial data, so no Bangladesh Bank payment or PSP/PSO rule is engaged. Consistent with the brief's compliance scope [Assumption](docs/product/vision.md) and the research note [Hypothesis](docs/research/competitors.md, Market notes). Revisit if the product ever takes payments itself (for example an operator edition that bills customers in-app) or sends customer data to a server.
- **Personal data, purpose, retention, consent:**
  - Photos and signatures are personal data; signatures are identity-sensitive; faces can be biometric-adjacent; students include minors [Fact](docs/features/FEAT-004-kb-range-compression/prd.md, section 10; vision compliance scope).
  - **Where the file goes.** (1) App-private cache with a random name until the flow ends, then deleted. (2) On Save: one copy in shared storage, readable by the gallery app, by other apps the user has given media access, and possibly backed up by a cloud gallery if the user or phone maker turned that on [Hypothesis, H7]. This copy is outside ExactSize's control. (3) On Share: a copy goes to the app the user picks, and that app's own policy applies; ExactSize cannot take it back. Nothing goes to any ExactSize server (none exists) and no network is used.
  - **Retention:** ExactSize keeps nothing after the flow ends and has no history or recents in R1. Saved copies stay until the user deletes them; the app never deletes a saved file. FEAT-023 recents would need its own review [Fact](docs/roadmap.md, FEAT-023 row).
  - **Consent:** no data is collected, so no consent screen is needed. Each export is a user action on one file. FR-26 states plainly where a copy goes.
  - **Privacy flags raised proactively.** (1) On API 28 the write permission may implicitly include reading all shared storage (H2). This conflicts with FEAT-001's "no broad storage access" stance, so FR-8 forbids any read or listing beyond ExactSize's own items, and OQ-1 offers a no-permission alternative. (2) A saved ID photo or signature in the gallery can be seen by other apps and cloud sync (H7); OQ-2 covers the folder choice and FR-26 the notice. (3) The file name is readable by the portal and the receiving app, so FR-4 bans personal data in it and the token is random, never derived from the image or device. (4) Share targets such as messaging and cloud-drive apps upload what they receive; that is the user's choice, stated in FR-26. (5) If FEAT-006 shows the image on the same screen, the recents-thumbnail rule applies [Fact](docs/features/FEAT-002-crop-resize/prd.md, FR-26). (6) Children's privacy: FEAT-007 collects nothing from under-13 users; the ad SDK is separate (FEAT-025) and must receive no file, name or path (FR-28).
  - **What is logged:** only enum outcome codes (`SAVED`, `ALREADY_SAVED`, `NO_SPACE`, `SAVE_FAILED`, `PERMISSION_DENIED`, `FILE_MISSING`, `SHARE_OPENED`, `SHARE_FAILED`, `SAVE_CANCELLED`, `OPEN_NO_VIEWER`) through the shared wrapper. Never the file name, URI, path, size, MIME, folder or platform exception text, in debug or release builds and crash reports (FR-27). Nothing that identifies the file or the user.
  - **Play Data safety and permissions [Hypothesis, verify before release]:** FEAT-007 sends nothing off the device, so it adds no "data collected" entry; a share chosen by the user through the system chooser is a user-initiated transfer to the user's own choice of app, which Google's Data safety rules may treat differently from developer sharing. `WRITE_EXTERNAL_STORAGE` capped at API 28 should not need the Play photo and video permission declaration, which targets the READ_MEDIA permissions. The ad SDK (FEAT-025) is the main exposure, so the store label must not say "no data collected" unless the ad SDK is accounted for [Fact](docs/roadmap.md, FEAT-016 row). The in-app explainer (FEAT-016) should say that copies in the gallery or in a receiving app are outside the app's control.
  - **Markets:** the launch is global [Fact](docs/product/vision.md). ExactSize processes on-device and transmits nothing, so exposure under local data-protection law is probably low [Hypothesis]; no market-specific law was checked for this draft (OQ-10).
  - Examples and tests use synthetic images and `[PLACEHOLDER]` values such as `exactsize-300x300-[TOKEN].jpg`; never real people's photos or signatures.

## 11. Dependencies
- **FEAT-004 (Implemented):** `CompressionSuccess`, temp-file ownership and start-up sweep, `CompressionController` discard behaviour. The tech plan must reconcile friendly naming for Share with delete-by-path (renaming or copying the cache file must not leave an orphan; FR-22).
- **FEAT-006 (Proposed):** the roadmap lists it as FEAT-007's dependency; see OQ-3 and the interim behaviour in section 5.
- **FEAT-001:** `release()` at flow end (FR-11); refusal of ExactSize's own FileProvider in the share target must cover the new authority; the build check and AC-6.4 (camera provider scope) must be kept or amended through a FEAT-001 change log.
- **FEAT-002:** recents-thumbnail rule when pixels are shown (FR-26 there).
- **FEAT-016:** final privacy copy for FR-26 and the explainer; no-network verification. **FEAT-018:** soft; metadata guarantee. **FEAT-019:** six-language strings. **FEAT-025:** the ad SDK must receive nothing from export. **FEAT-027:** only enum codes, local-only or opt-in, not in R1.
- **ADR-001:** minSdk 28 and JNIgen for MediaStore calls [Fact](docs/adr/ADR-001-app-stack.md, minimum Android version; JNIgen line). Stage 6 needs an ADR for the export bridge: MediaStore and share through JNIgen, a thin native layer as in ADR-006, or a Dart plugin. A plugin can add a FileProvider or permissions silently, so the merged-manifest check applies [Hypothesis].
- **UI design:** this is a real screen, so the Product Owner is told before design and it is designed with impeccable [Fact](CLAUDE.md, Implementation; decision 2026-11-20).
- **Content / legal:** permission disclosure text for the store listing [Fact](docs/roadmap.md, FEAT-007 row, "storage permission disclosures"); Data safety answers; compliance review (OQ-10).
- **Stage 6 checks:** each H1 to H7; whether `WRITE_EXTERNAL_STORAGE` grants read in practice on API 28; pending-item visibility for the sweep; share display-name behaviour; effort re-estimate.

## 12. Open questions
- [x] **OQ-1 (blocking) API 28 write route.** A: `WRITE_EXTERNAL_STORAGE` capped at API 28, asked on the first Save tap, with save-as as the fallback after a refusal (this draft). B: no permission on API 28; Save always opens the system save-as dialog. Trade-off: A is one tap and lands in the gallery, but the grant may also allow reading all shared storage (H2) and needs a permission disclosure; B is least privilege and matches FEAT-001's stance, but costs more steps and the file may land where the portal picker does not show it. **Proposed default: A**, with FR-8 limiting code to its own items. The security-first alternative is B; the Product Owner decides. If B, FR-7 to FR-9 and US-2 change. **Decided 2026-11-24 by the Product Owner: A, WRITE_EXTERNAL_STORAGE capped at API 28, asked only on the Save tap, save-as as the fallback after a refusal; FR-8 limits code to its own items.**
- [ ] **OQ-2 (non-blocking, before Stage 6) Save destination.** A: `Pictures/ExactSize` (this draft, visible in the gallery and the picker's Images list). B: `Download/ExactSize` (less likely to show as a photo album, still scannable and syncable [Hypothesis]). **Proposed default: A.** Either way a saved ID photo is visible to other apps (privacy flag 2).
- [x] **OQ-3 (blocking for planning) Order versus FEAT-006.** The roadmap says FEAT-007 depends on FEAT-006 (M, 0.8 pw, not built). **Proposed default: build FEAT-007 first** as the panel plus the minimal result screen (FR-29), treat the dependency as soft, and have FEAT-006 embed the panel. Why it matters: the end-to-end loop can be tested earlier, but FEAT-007 carries a throwaway result screen (about 0.1–0.2 pw [Assumption]) and the roadmap row needs a note. Alternative: build FEAT-006 first, then the panel only. **Decided 2026-11-24 by the Product Owner: build FEAT-007 first with the minimal result screen (FR-29); the FEAT-006 dependency is soft and FEAT-006 embeds the panel.**
- [ ] **OQ-4 (non-blocking) Save twice.** Proposed default: idempotent per result with an existence check (FR-12). Alternative: every tap makes a new copy (duplicates of an ID photo).
- [ ] **OQ-5 (non-blocking) Leaving the screen.** Proposed default: explicit "Start over" or "Done" button, and a confirm on back only when nothing was saved or shared (FR-23, Should). Alternative: no confirm.
- [ ] **OQ-6 (non-blocking) Save-as dialog and Open.** Proposed default: keep both as Should (FR-10, FR-15), since they are the recovery paths for a refused permission and a hiding gallery. Cut order if effort grows: FR-21, FR-23, FR-15, FR-10.
- [ ] **OQ-7 (non-blocking) File name pattern.** Proposed default: `exactsize-<W>x<H>-<TOKEN>.<ext>`. Alternatives: a date-stamped name (reveals when the user made it; rejected here) or a fixed word such as "photo" (not known: FEAT-005 has no photo or signature type). Some portals may restrict file names (length, characters) [Assumption, no research]; the pattern is short ASCII for that reason.
- [ ] **OQ-8 (non-blocking) Share from the cache copy.** Draft: Share reads the temp file, so no gallery copy is made, but a slow receiving app can fail after the user leaves (H4). Alternative: keep the file until the next app start after a Share, which leaves personal data in cache longer. **Proposed default: delete at flow end.**
- [ ] **OQ-9 (non-blocking) Chat-app hint (FR-21).** Proposed default: show it. H6 is [Hypothesis]; a hands-on test with one popular chat app would confirm it before the copy is final.
- [ ] **OQ-10 (non-blocking, before release) Compliance review.** Confirm the Data safety reading, the permissions declaration, the PCI "opaque bytes" reading and local data-protection law for the launch markets with whoever handles legal and store compliance. **Proposed default:** treat as open until reviewed; ship no "no data collected" claim.
- [ ] **OQ-11 (non-blocking) Effort.** Roadmap says 0.5 pw; this draft [Assumption] 1.0–1.5 pw. **Proposed default:** Stage 6 re-estimates and the roadmap is updated by the Product Owner.

## Change log
| Version | Date | Change |
|---|---|---|
| 0.1 | 2026-11-24 | First draft |
| 1.0 | 2026-11-24 | Approved by Product Owner; OQ-1 = A (permission on API 28), OQ-3 = FEAT-007 first |
| 1.1 | 2026-11-24 | Clarification (FEAT-007-T02, Product Owner choice): new info code `OPEN_NO_VIEWER` in sections 5, 8 and 10; FR-13 accepts the API 29+ system conflict rename seen in the T01 spike. No scope change |
| 1.1 | 2026-11-24 | Approved by Product Owner |
| 1.2 | 2026-11-25 | Clarification (FEAT-007-T21 Spanish review, Product Owner asked to fix the English first): FR-23 / AC-8.2 leave text names the new file and says gallery photos stay ("This file" could read as the original photo); `FILE_MISSING` text names the next step instead of "Please create it again"; FR-26 privacy line also covers "Choose where to save". Texts only, no behaviour change |
