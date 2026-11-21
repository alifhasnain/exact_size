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
- **Open list decision:** the Product Owner accepted it as logged on 2026-11-21. The translation stays as it is.
- **Status:** AI-reviewed only (no native speaker).

## pt (pt-BR)

- **Date:** 2026-11-21. Keys: all 65 untranslated, written to `app_pt.arb`. `app_pt_BR.arb` stays almost empty and falls back to `pt`, so gen-l10n no longer lists `pt_BR` as untranslated.
- **Models:** drafted by Claude Opus 5.5 (vendored skill `localize-pt`, variant pt-BR). Blind back-translation review of all keys by Claude Sonnet. Second blind review of the high-risk keys by Claude Haiku.
- **Variant:** pt-BR. Register `você` with full forms (no `pra`/`tá`). Buttons use the infinitive. Imperatives use the `você` form (Escolha, Tente, Insira). Proclisis, except for the standard `conecte-se`. Digits 0–9; the numbers arrive already formatted from code.
- **Glossary:**

  | English | Portuguese |
  |---|---|
  | phone | celular |
  | device | dispositivo |
  | photo / image | foto / imagem |
  | crop area | área de corte |
  | resize crop | redimensionar corte |
  | size (KB) | tamanho |
  | dimensions | dimensões |
  | file size | tamanho de arquivo |
  | range | faixa de tamanho |
  | enlargement | ampliação |
  | zoom in / zoom out | Aumentar zoom / Diminuir zoom |
  | rotate clockwise / counter-clockwise | Girar no sentido horário / anti-horário |
  | take a photo | tirar uma foto |
  | photo picker | seletor de fotos |
  | gallery | galeria |
  | enter (a value) | inserir |
  | try again | tente novamente |
  | stored online | salva na nuvem |
  | frame of an animation | quadro |
  | padding | preenchimento |
  | soft / blurry | pouco nítida / borrada |

- **Fixed after review (6):**
  - outcomeHintJpegWouldFit: "no tamanho pedido".
  - noticeNarrowRange: "de outra forma" and "faixa de tamanho".
  - cropHintLimitedPrecision: "fina" → "estreita"; "botões de movimento e zoom".
  - cropAnnounceStrongEnlargement: "Ampliação acentuada".
  - pickCaptureLost: "se perdeu".
- **High-risk keys (second review):** the same 12 as for es. The second review found no grammar errors.
- **Open list (Product Owner to decide):**
  1. **pickPrivacyNote:** "nunca são enviadas para a internet" is an absolute claim, the same as in English and es. A reviewer suggested "O app não envia suas fotos para a internet". The final copy belongs to FEAT-016.
  2. **Reviewer suggestions not taken,** because they add content the English text does not have. This is the same call as for es.
     - noticePaddingAdded: "dados de preenchimento ao arquivo".
     - cropSourceUnavailable: "removed or moved; choose another".
     - cropConfirmEnlarge: "too small for this form".
     - pickCaptureLost: rewording as "não foi concluída" changes the meaning.
     - pickChooseFiles: naming the Files app ("em Arquivos"); its name differs between phone makers.
  3. **Kept as in English, against a reviewer flag:**
     - pickItemNotOpenable keeps "esse item".
     - cropTargetTooLarge keeps "Essas" (for English "That").
     - The split between "celular" and "dispositivo" is kept.
  4. **English wording not yet confirmed by the Product Owner:** the same four keys as for es.
- **Open list decision:** the Product Owner accepted it as logged on 2026-11-21.
- **Status:** AI-reviewed only (no native speaker).

## hi (hi-IN)

- **Date:** 2026-11-21. Keys: all 65 untranslated.
- **Models:** drafted by Claude Opus 5.5 (vendored skill `localize-hi`). Blind back-translation review of all keys by Claude Sonnet. Second blind review of the high-risk keys by Claude Haiku.
- **Variant:** Modern Standard Hindi in Devanagari. Formal `आप` imperatives (-ें), with tech loanwords (फ़ाइल, ऐप, ज़ूम, स्टोरेज). The danda (।) ends sentences. JPEG, PNG and KB stay in Latin script. Digits 0–9 (Latin), because the numbers arrive already formatted from code and the Flutter `hi` locale uses Latin digits [Assumption].
- **Glossary:**

  | English | Hindi |
  |---|---|
  | phone | फ़ोन |
  | device | डिवाइस |
  | photo | फ़ोटो (feminine) |
  | image | इमेज (feminine) |
  | pixel dimensions | (पिक्सेल) माप |
  | size (KB) | साइज़ |
  | file size | फ़ाइल साइज़ |
  | range | साइज़ रेंज |
  | crop area | क्रॉप क्षेत्र |
  | enlarge | बड़ा करना |
  | soft / blurry | थोड़ी धुंधली / धुंधली |
  | zoom in / zoom out | ज़ूम इन करें / ज़ूम आउट करें |
  | move | खिसकाएँ |
  | rotate clockwise / counter-clockwise | घड़ी की दिशा में / घड़ी की उल्टी दिशा में घुमाएँ |
  | take a photo | फ़ोटो लें |
  | photo picker | फ़ोटो चुनने की स्क्रीन |
  | gallery | गैलरी |
  | enter | डालें |
  | try again | फिर से कोशिश करें |
  | stored online | क्लाउड में सेव |
  | whole number | बिना दशमलव वाली संख्या |
  | padding | पैडिंग |
  | px | पिक्सेल |

- **Fixed after review (13):**
  - outcomeCantReachRange, outcomeCantReachMax and outcomeImageTooLarge: "पिक्सेल माप", so they are not confused with KB.
  - outcomeHintTryJpeg: "PNG फ़ाइल का साइज़".
  - noticePaddingAdded: "फ़ाइल में".
  - targetWholeNumbersOnly: "बिना दशमलव वाली संख्या".
  - cropCancelled: "प्रक्रिया रद्द की गई".
  - cropNoticeEnlarged: "px" → "पिक्सेल".
  - cropButtonCentre: "बीच में लाएँ".
  - cropAnnounceStrongEnlargement: "हम आपसे पूछेंगे".
  - noticeNarrowRange: "साइज़ रेंज".
  - noticeTransparencyFlattened: "सफ़ेद कर दिए गए हैं".
  - cropConfirmEnlarge: "इसे {factor}× बड़ा करना पड़ेगा".
- **High-risk keys (second review):** the same 12 as for es. The second review found no grammar errors.
- **Open list (Product Owner to decide):**
  1. **pickPrivacyNote:** "कभी इंटरनेट पर अपलोड नहीं होतीं" ("never uploaded to the internet") is an absolute claim, the same as in English, es and pt. The reviewer pointed out that the user later uploads the resized photo to the form themselves, so "never" can read as false. It suggested limiting the claim to the app. The final copy belongs to FEAT-016. This applies to every language.
  2. **Reviewer suggestions not taken,** because they add or change meaning:
     - pickCaptureLost: name a cause ("not saved" or "camera closed").
     - outcomeWriteFailed: add "your original is safe".
     - pickItemNotOpenable: drop "आइटम".
     - cropConfirmEnlarge: "continue with this photo".
  3. **Kept as in English, against a reviewer flag:**
     - The split between इमेज and फ़ोटो is kept.
     - The split between डिवाइस and फ़ोन is kept.
     - "पैडिंग" is kept as a loanword.
  4. **English wording not yet confirmed by the Product Owner:** the same four keys as for es.
- **Status:** AI-reviewed only (no native speaker).
