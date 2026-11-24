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
- **2026-11-24, FEAT-005 target step (12 keys):** targetPixelsNotWhole, targetLabelWidth/Height/Min/Max, targetOptional, targetUnitPx, targetUnitKb, targetFormatLabel, targetPhotoSize, targetUsePhotoSize, targetHintVerySmall. Drafted by Claude Opus 5.5 (`localize-es`), blind back-translation review by Claude Sonnet. New glossary: width / height = Ancho / Alto; minimum / maximum size = Tamaño mínimo / máximo (KB unit beside the field); use photo size = Usar las dimensiones de la foto (pixel size keeps "dimensiones"); units px and KB kept. Fixed after review (1): targetHintVerySmall was a bare fragment that could read as "your photo is small"; now "La imagen quedará muy pequeña. Revisa las dimensiones que pide tu formulario." Not taken: "Tamaño mínimo del archivo" (longer; the KB unit beside the field already disambiguates, as in English). No high-risk keys. Open list: none.
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
- **Open list decision:** the Product Owner accepted it as logged on 2026-11-21.
- **Status:** AI-reviewed only (no native speaker).

## id (Bahasa Indonesia)

- **Date:** 2026-11-21. Keys: all 65 untranslated.
- **Models:** drafted by Claude Opus 5.5 (vendored skill `localize-id`). Blind back-translation review of all keys by Claude Sonnet. Second blind review of the high-risk keys by Claude Haiku.
- **Variant:** Indonesian, not Malaysian. Formal register (bahasa baku) with "Anda"; "kami" is the app speaking. Buttons use short imperatives. "file" is kept rather than "berkas", since both are accepted in UI. Number formatting (1.234,56) comes from code via the `id` locale [Assumption].
- **Glossary:**

  | English | Indonesian |
  |---|---|
  | phone | ponsel |
  | device | perangkat |
  | photo / image | foto / gambar |
  | dimensions | dimensi |
  | size (KB) | ukuran |
  | file size | ukuran file |
  | range | rentang ukuran |
  | crop area | area pangkas |
  | enlarge (upscale) | perbesar / pembesaran |
  | zoom in / zoom out | Perbesar tampilan / Perkecil tampilan |
  | move | geser |
  | rotate clockwise / counter-clockwise | Putar searah / berlawanan arah jarum jam |
  | soft / blurry | kurang tajam / buram |
  | take a photo | ambil foto |
  | photo picker | pemilih foto |
  | gallery | galeri |
  | storage | ruang penyimpanan |
  | enter | masukkan |
  | try again | coba lagi |
  | stored online | tersimpan di cloud |
  | whole number | bilangan bulat |
  | padding | data pengisi |
  | frame (animation) | frame |

- **Fixed after review (16):**
  - outcomeCantReachMax: "ukuran file".
  - outcomeHintTryJpeg: "ditambah"; "coba gunakan JPEG".
  - outcomeOutOfMemory: "tidak cukup".
  - outcomeWriteFailed: "ruang penyimpanan".
  - noticeNarrowRange: "sehingga … dapat".
  - noticePaddingAdded: "Gambar itu sendiri".
  - targetMinNotBelowMax: "daripada".
  - cropHintLimitedPrecision: "tampak sangat sempit".
  - cropButtonZoomIn and cropButtonZoomOut: "… tampilan", so they are not confused with upscaling.
  - cropAreaState: "bagian kiri/kanan".
  - pickCameraNoPhoto: "Tidak ada foto yang diterima".
  - pickLowSpace: "ruang penyimpanan".
  - pickCaptureLost: "ambil foto lagi".
  - pickSourceUnavailable: "sambungkan ponsel".
  - cropSourceUnavailable: "pilih ulang".
- **High-risk keys (second review):** the same 12 as for es. The second review found no grammar errors.
- **Open list (Product Owner to decide):**
  1. **pickPrivacyNote:** the absolute "never uploaded" claim, the same issue as in every language. The suggested scoping is "tidak diunggah ke internet oleh aplikasi ini" ("not uploaded to the internet by this app"). It belongs to FEAT-016.
  2. **pickCaptureLost:** the reviewers for hi and id both said "photo lost" can read as a photo deleted from the gallery, and suggested "the photo was not received from the camera". That is a question about the English wording (FEAT-001 FR-17), so every language would follow it.
  3. **Reviewer suggestions not taken:**
     - "berkas" for "file".
     - A next step added to noticeNarrowRange ("check the portal's requirements").
     - "galeri" for "photo picker": wrong, because the picker can be the file picker.
     - A rewording of pickItemNotOpenable.
     - "tidak memerlukan pembesaran" for cropAnnounceNoEnlargement: "lagi" ("any more") is correct, because the announcement fires after a change.
  4. **Kept as in English, against a reviewer flag:** the split between ponsel and perangkat. "Silakan" is used on some failure messages but not others.
  5. **English wording not yet confirmed by the Product Owner:** the same four keys as for es.
- **Open list decision:** the Product Owner accepted it as logged on 2026-11-21.
- **Status:** AI-reviewed only (no native speaker).

## ar (Modern Standard Arabic)

- **Date:** 2026-11-21. Keys: all 65 untranslated.
- **Models:** drafted by Claude Opus 5.5 (vendored skill `localize-ar`). Blind back-translation review of all keys by Claude Sonnet. Second blind review of the high-risk keys by Claude Haiku.
- **Variant:** MSA in the standard formal register. Instructions use the masculine singular imperative, the usual convention in Arabic UI. Single-action buttons use the masdar (متابعة, توسيط, التقاط صورة). Failures use the impersonal تعذّر. Arabic punctuation (، ؟). No bidi marks in the strings: isolates are added in code. JPEG, PNG and KB stay in Latin script.
- **Digits:** checked in code. `NumberFormat('ar')` from intl formats 10240.5 as "10,240.5" and 150 % as "150‎%‎", in Western digits 0–9 as decided. No open item.
- **Glossary:**

  | English | Arabic |
  |---|---|
  | phone | هاتف |
  | device | جهاز |
  | photo / image | صورة (one word; Arabic does not separate them) |
  | dimensions | الأبعاد |
  | size (KB) | الحجم |
  | file size | حجم الملف |
  | range | نطاق الحجم |
  | crop area | منطقة الاقتصاص |
  | enlarge (upscale) | تكبير / ستُكبَّر |
  | zoom in / zoom out | تقريب / تبعيد |
  | zoom level | مستوى التقريب |
  | compression | ضغط الصورة |
  | portal | البوابات الإلكترونية |
  | form | النموذج الإلكتروني |
  | soft / blurry | أقل وضوحًا / ضبابية |
  | take a photo | التقاط صورة |
  | photo picker | أداة اختيار الصور |
  | gallery | المعرض |
  | free up | حرّر |
  | try again | حاول مرة أخرى / يُرجى المحاولة مرة أخرى |
  | stored online | محفوظة في التخزين السحابي |
  | padding | بيانات حشو |
  | frame (animation) | الإطار |
  | pixels | بكسل |

- **Fixed after review (25):**
  - Failure messages: "لا يمكننا" → "تعذّر", and "أقرب نتيجة".
  - Crop term: "القص" → "الاقتصاص", in the crop area, the handles, the edge announcement and the hint.
  - Zoom: "تكبير/تصغير العرض" → "تقريب/تبعيد", so zoom is not confused with upscaling or "width".
  - Compression: "ضغط الصورة", because "الضغط" alone can read as "pressure".
  - Passive constructions: "أُضيفت", "أُلغيت" and "ستُكبَّر".
  - cropButtonContinueAnyway: indefinite "متابعة".
  - "الجزء الأوسط".
  - "تكبير مفرط".
  - "بوحدة KB".
  - "التخزين السحابي".
  - "نطاق الحجم".
  - cropConfirmEnlarge: "من الحجم المطلوب".
  - pickCaptureLost: changed to "بينما كانت الكاميرا مفتوحة". The back-translation showed that the draft "أثناء فتح الكاميرا" meant "while the camera was opening", which is meaning drift.
- **High-risk keys (second review):** the same 12 as for es. No grammar errors remain.
- **Open list (Product Owner to decide):**
  1. **pickPrivacyNote:** the absolute "never uploaded" claim, as in every language. The suggested scoping is "ولا يرفعها التطبيق إلى أي خادم أبدًا" ("and the app never uploads them to any server"). It belongs to FEAT-016.
  2. **pickCameraNoPhoto:** now reads "لم تلتقط الكاميرا أي صورة" ("the camera took no photo"), because the reviewer called the literal "did not return" a calque. This is a slight shift from the English "didn't return a photo".
  3. **Masculine singular address:** this is the standard default in Arabic UI. A gender-neutral alternative (يُرجى + masdar throughout) is possible but reads more formal.
  4. **Reviewer suggestions not taken:**
     - A next step added to noticeNarrowRange.
     - "No longer exists" for cropSourceUnavailable: that changes the meaning, so I used "تعذّر العثور" instead.
     - "file" instead of "item" in pickItemNotOpenable.
  5. **English wording not yet confirmed by the Product Owner:** the same four keys as for es, plus pickCaptureLost (see id).
- **Open list decision:** the Product Owner accepted it as logged on 2026-11-21.
- **Status:** AI-reviewed only (no native speaker).

## Notes across languages

- **es number format:** the `es` locale in intl formats numbers Spain-style (10.240,5), while es-419 usually writes 10,240.5. The strings receive numbers that are already formatted, so the text is unaffected, but the numbers a Latin American user sees use comma decimals. Fixing it would need an `es_419` locale or a number-format override; this needs a Product Owner decision.
