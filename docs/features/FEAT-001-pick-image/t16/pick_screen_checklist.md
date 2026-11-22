---
id: FEAT-001-T16-CHECKLIST
title: Pick screen — design checklist for the Product Owner (gate G3)
status: Proposed
version: 0.1
updated: 2026-11-22
links: [FEAT-001, FEAT-001-TECH, FEAT-001-TASKS, FEAT-002-T22-DESIGN]
---

# Pick screen — what the design must cover (gate G3)

This is the non-visual input for the impeccable design pass (https://github.com/pbakaus/impeccable). It lists the elements, states, constraints and strings the PRD requires. It contains no layout, colours or mock-up. The design must use no real photos: this screen shows none.

The engine behind the screen is built and tested (T02–T15):
- the system picker and camera bridge;
- `PickController` and its state;
- one image at a time, and the 500 ms progress with Cancel;
- the messages and their strings.

## 0. Flow (OQ-4, decided 2026-11-22: photo first)
- **Start screen:** the pick screen is the app's start screen, and FEAT-001 owns it. After process death the app opens here with nothing restored (FR-16).
- **After an image is accepted:** the app goes to the target step (FEAT-005 manual entry or FEAT-011 preset), then crop. A result waiting at start-up (FR-15, FR-17) and a share (FR-20) take the same route.
- **Start over:** clears the image and returns here (`release()`, FR-11).

## 1. Elements
| Element | Requirement | Source |
|---|---|---|
| Take a photo | Opens the camera in one tap, with no dialog | FR-1 |
| Choose from gallery | Opens the photo picker in one tap | FR-1 |
| Choose from files (Should) | Opens the document picker, images only | FR-21, OQ-3 |
| Camera disabled | When no camera app exists: the button stays visible but is disabled, with the reason as visible text. It is never hidden | FR-5 |
| Privacy line (Should) | One short line. FEAT-016 owns the final copy | FR-22 |
| Message area | Shows the last refusal: icon plus text, never colour alone, announced politely. Both buttons stay enabled. Cleared by the next launch | FR-14, NFR-4 |
| Opening progress | "Opening your photo…" with Cancel, only after 500 ms. Cancel returns to idle with no message | FR-13, AC-4.2 |

## 2. States (from `PickState`)
| State | What shows |
|---|---|
| idle, camera available | All buttons enabled |
| idle, no camera app | Camera disabled, with its reason |
| awaitingSystemUi | A system screen is on top. Our screen is unchanged; a second tap is ignored (AC-5.4) |
| opening, under 500 ms | No visible change |
| opening, 500 ms or more | Progress, the opening text and Cancel. Buttons are not usable |
| refusal | Message area with one of the 9 messages (section 4); buttons enabled |

## 3. Constraints
- **TalkBack order (AC-7.1):** Take a photo, Choose from gallery, (Choose from files), privacy line. Each has a label and role. Focus returns to the button used after a system screen closes without a pick.
- **Touch targets:** at least 48 dp, with 8 dp between them.
- **200% font (AC-7.2):** nothing is clipped, buttons stay at least 48 dp high, and the screen scrolls.
- **RTL (AC-7.4):** button order and text mirror; the camera and gallery icons do not.
- **Colour:** no information by colour alone. Text pairs meet WCAG AA.
- **System:** system Back works, and the layout is edge-to-edge with insets. Portrait and landscape are both supported.
- **Six languages,** all strings from ARB (AC-7.3). The longest messages are about 140 characters in English and longer in some languages.

## 4. Strings (T06, `lib/l10n/app_en.arb`)
Buttons and lines:
- `pickTakePhoto`
- `pickChooseGallery`
- `pickChooseFiles`
- `pickPrivacyNote`
- `pickOpening`
- `pickNoCamera` (the disabled-camera reason)

Messages:
- `pickPickerUnavailable`
- `pickCameraNoPhoto`
- `pickLowSpace`
- `pickCaptureLost`
- `pickItemNotOpenable`
- `pickSourceUnavailable`
- `cropUnsupportedInput`, `cropCorruptInput` and `cropSourceTooLarge`, shared with FEAT-002

Cancel uses Material's localised label.

## 5. Out of scope here
- The target step and presets (FEAT-005, FEAT-011).
- The privacy explainer (FEAT-016).
- Ads (FEAT-025).
- Onboarding.
