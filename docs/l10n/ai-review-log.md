---
id: L10N-REVIEW-LOG
title: AI review log for translations
status: Proposed
version: 0.1
updated: 2026-11-21
links: [FEAT-019, VENDOR]
---

# AI review log

There is no native reviewer (Product Owner decision 2026-11-21). Every language below has the status **AI-reviewed only (no native speaker)**. The risk of residual errors is a [Hypothesis]. If a native speaker ever reviews a language, record it in that language's section.

## es (es-419)

- **Date:** 2026-11-21. Keys: all 65 untranslated (12 FEAT-001 pick, 53 FEAT-002/FEAT-004).
- **Models:** drafted by Claude Opus 5.5 (vendored skill `localize-es`). Blind back-translation review of all keys by Claude Sonnet. Second blind review of the high-risk keys by Claude Haiku.
- **Variant:** es-419, Latin American neutral. Register `tú`, because the source is consumer voice with contractions. Buttons use the infinitive. Simple past (pretérito indefinido). Digits 0–9; the numbers arrive already formatted from code.
- **Glossary:**

  | English | Spanish |
  |---|---|
  | phone | celular |
  | device | dispositivo (kept apart from "phone", as in English) |
  | photo / image | foto / imagen (as in English) |
  | crop area / frame | área de recorte |
  | crop (resize handle) | recorte |
  | size (KB) | tamaño |
  | dimensions | dimensiones |
  | file size | tamaño de archivo |
  | enlargement | ampliación |
  | zoom in / zoom out | Acercar / Alejar |
  | rotate clockwise / counter-clockwise | Girar en sentido horario / antihorario |
  | take a photo | tomar una foto (never `coger`) |
  | photo picker | selector de fotos |
  | gallery | galería |
  | enter (a value) | ingresar |
  | try again | inténtalo de nuevo |
  | stored online | guardada en la nube |
  | frame of an animation | fotograma |
  | padding | relleno |

- **Fixed after review (9):**
  - outcomeHintTryJpeg: "peso" → "tamaño de archivo".
  - noticeNarrowRange: "cuentan" → "calculan".
  - cropTargetTooLarge: "tamaño" → "dimensiones", to keep it apart from KB.
  - cropCancelled: now names the action ("Preparación cancelada").
  - cropHintLimitedPrecision: "marco" → "área de recorte"; "botones de movimiento y zoom".
  - cropAnnounceStrongEnlargement: "Tendrás que confirmar".
  - pickChooseFiles: article added.
  - pickPrivacyNote: "se quedan … a internet".
  - pickSourceUnavailable: "en la nube".
- **High-risk keys (second review):** pickPrivacyNote, noticeNarrowRange, noticeTransparencyFlattened, outcomeOutOfMemory, outcomeWriteFailed, pickLowSpace, pickSourceUnavailable, pickNoCamera, pickPickerUnavailable, pickCaptureLost, cropSourceUnavailable, cropConfirmEnlarge. The second review found no grammar errors.
- **Open list (Product Owner to decide):**
  1. **pickPrivacyNote** makes the absolute claim "nunca se suben a internet". It mirrors the English text, and the final copy belongs to FEAT-016. The reviewer asked for it to be scoped to the app ("desde esta app"). The claim must stay true once any ads, analytics or crash SDK ships. If the English wording changes, retranslate.
  2. **Reviewer suggestions not taken**, because they add content the English text does not have:
     - noticeNarrowRange: name the referent ("El rango de tamaño que elegiste").
     - cropSourceUnavailable: add "may have been deleted or moved".
     - cropConfirmEnlarge: split the sentence ("Tendría que ampliarse {factor}×").
  3. **Kept as in English, against a reviewer flag:**
     - "poco nítida" (soft) and "borrosa" (blurry) stay as two different words.
     - pickItemNotOpenable keeps the vague "elemento" (item).
     - The split between "celular" and "dispositivo" is kept.
  4. **English wording not yet confirmed by the Product Owner:** cropCancelled, cropHintLimitedPrecision, cropAnnounceNoEnlargement and cropAnnounceStrongEnlargement. Retranslate them if the English wording changes.
- **Status:** AI-reviewed only (no native speaker).
