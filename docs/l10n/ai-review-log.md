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
- **2026-11-25, FEAT-007 export (23 keys):** exportSave … exportSaving. Drafted by Claude Opus 5.5 (`localize-es`), blind back-translation review by Claude Sonnet, second blind review of the high-risk keys by Claude Haiku. New glossary: Save / Share / Open = Guardar / Compartir / Abrir; Choose where to save = Elegir dónde guardar; Done = Listo; Ready (result line) = Imagen lista; saved to/as = Se guardó en … como … (pretérito indefinido); share menu = menú para compartir; upload window = selector de archivos; Leave / Stay = Salir / Quedarse; Saving… = Guardando…. No meaning drift against the English. Fixed after review (1): exportShareHint "ventana para subir archivos" (calque) → "selector de archivos". High-risk keys: exportPrivacy, exportNoSpace, exportSaveFailed, exportPermissionDenied, exportFileMissing, exportShareFailed, exportNoViewer, exportShareHint, exportLeaveTitle, exportLeaveBody; the second review found no grammar errors. Open list (Product Owner to decide; each mirrors the English, so a change starts in app_en.arb and all languages follow): (1) exportLeaveBody "Este archivo se eliminará": both reviewers read it as possibly deleting the original photo; suggestion: name the finished copy and say the original stays. (2) exportFileMissing "Vuelve a crearlo": vague; both reviewers suggest naming the action (process the photo again). (3) exportPrivacy says saving puts a copy in the gallery, which is not true after "Choose where to save". Not taken: "teléfono/dispositivo" instead of "celular" (glossary); "Para un formulario" kept terse as in English; non-breaking spaces around × (code, not ARB). Mechanical checks: keys equal English, placeholders identical, gen-l10n and analyze clean.
- **2026-11-25, open list decision:** the Product Owner chose to fix the English first (PRD FEAT-007 1.2, Under Discussion). New English: exportLeaveBody "The new file will be deleted. Your gallery photos stay as they are."; exportFileMissing "This file is no longer available. Choose the photo again to make a new one."; exportPrivacy "Saving puts a copy in your gallery or a folder you pick. Sharing gives a copy to the app you choose." Spanish retranslated: "Se eliminará el archivo nuevo. Las fotos de tu galería no se modifican."; "Este archivo ya no está disponible. Vuelve a elegir la foto para crear uno nuevo."; "Al guardar, se crea una copia en tu galería o en la carpeta que elijas. Al compartir, la app que elijas recibe una copia." Blind review by Claude Sonnet: fixed "no cambian" → "no se modifican". Not taken: "Tus fotos originales" (an in-app camera capture is deleted on leave, so only gallery photos are promised); "El archivo exportado" (adds a word the English does not have); the repeated "que elijas" (mirrors the English). The reviewer asked whether shared copies keep EXIF/GPS: the output is re-encoded from pixels and FEAT-002 passes on no EXIF; verifying the stripping belongs to FEAT-018. Open list: none.
- **2026-11-25, pt open list decision (also changes es):** the Product Owner chose to fix the English first. New English (PRD FEAT-007 1.3, Under Discussion): exportPermissionDenied "ExactSize needs the Storage permission to save to your gallery. Turn it on in Settings. You can also share the file or choose where to save it."; exportFileMissing "The new file is no longer available. Your gallery photos stay as they are. Choose the photo again to make a new one.". Spanish: "ExactSize necesita el permiso de Almacenamiento para guardar en tu galería. Actívalo en Configuración. También puedes compartir el archivo o elegir dónde guardarlo."; "El archivo nuevo ya no está disponible. Las fotos de tu galería no se modificaron. Vuelve a elegir la foto para crear el archivo otra vez." Blind review by Claude Sonnet: fixed "crear uno nuevo" (could read as a new photo) and the tense ("no se modificaron"). Android 9 system names used: Almacenamiento, Configuración. Not taken: naming the Permisos page (the English does not). Open list: none.
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
- **2026-11-24, FEAT-005 target step (12 keys, in `app_pt.arb`):** targetPixelsNotWhole, targetLabelWidth/Height/Min/Max, targetOptional, targetUnitPx, targetUnitKb, targetFormatLabel, targetPhotoSize, targetUsePhotoSize, targetHintVerySmall. Drafted by Claude Opus 5.5 (`localize-pt`, pt-BR), blind back-translation review by Claude Sonnet. New glossary: width / height = Largura / Altura; minimum / maximum size = Tamanho mínimo / máximo; use photo size = Usar as dimensões da foto; units px and KB kept. targetHintVerySmall drafted as "A imagem ficará muito pequena. Confira as dimensões que seu formulário pede." (clearer than a bare fragment, as for es). The review found no errors. Not taken: "A foto" instead of "A imagem" in targetHintVerySmall, because the English says "image" there (the output, not the source photo). No back-translation drift. No high-risk keys. Open list: none.
- **2026-11-25, FEAT-007 export (23 keys, in `app_pt.arb`; texts from PRD 1.2):** drafted by Claude Opus 5.5 (`localize-pt`, pt-BR), blind back-translation review by Claude Sonnet, second blind review of the high-risk keys by Claude Haiku. New glossary: Save / Share / Open = Salvar / Compartilhar / Abrir; Choose where to save = Escolher onde salvar; Done = Concluído; Ready = Imagem pronta; saved = Arquivo salvo em … como …; share menu = menu de compartilhamento; file picker = seletor de arquivos; Leave / Stay = Sair / Ficar; Saving… = Salvando…; delete = excluir. No meaning drift against the English; no pt-PT forms. Fixed after review (3): exportFileMissing "um novo" → "um novo arquivo" (could read as a new photo); exportShareHint "Para um formulário" → "Para enviar em um formulário"; exportSaveFailed "compartilhe o arquivo" → "compartilhe-o" (repetition; the second reviewer preferred the old form, kept the fix). Checked: the {size} decimal comes from code with the locale (NumberFormat), so pt shows "48,2 KB". High-risk keys: the same 10 as for es; the second review found no grammar errors. Open list (each mirrors the English; a change starts in app_en.arb): (1) exportPermissionDenied gives no route to turn the permission on in Settings (both reviewers; es reviewer too). (2) exportFileMissing "Este arquivo" may still read as the user's photo; the second reviewer suggests adding that photos are unchanged. Not taken: "aparelho/dispositivo" for "celular" (glossary); "reduzem a qualidade" for "comprimem" (English "shrink" is about size); one term for "cópia" and "arquivo" (the English uses both). Mechanical checks: keys equal English, placeholders identical, gen-l10n and analyze clean.
- **2026-11-25, open list decision:** the Product Owner chose to fix the English first. New English (PRD FEAT-007 1.3, Under Discussion): exportPermissionDenied "ExactSize needs the Storage permission to save to your gallery. Turn it on in Settings. You can also share the file or choose where to save it."; exportFileMissing "The new file is no longer available. Your gallery photos stay as they are. Choose the photo again to make a new one.". Portuguese: "O ExactSize precisa da permissão de Armazenamento para salvar na galeria. Ative-a nas Configurações. Você também pode compartilhar o arquivo ou escolher onde salvá-lo."; "O novo arquivo não está mais disponível. As fotos da sua galeria continuam como estão. Escolha a foto novamente para criar o arquivo outra vez." Blind review by Claude Sonnet: fixed the repeated "novo arquivo". Android 9 system names used: Armazenamento, Configurações. Not taken: "Configurações do app" and "Sua foto original" (the English says neither; an in-app camera capture is not in the gallery). Open list: none.
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
- **2026-11-24, FEAT-005 target step (12 keys):** targetPixelsNotWhole, targetLabelWidth/Height/Min/Max, targetOptional, targetUnitPx, targetUnitKb, targetFormatLabel, targetPhotoSize, targetUsePhotoSize, targetHintVerySmall. Drafted by Claude Opus 5.5 (`localize-hi`), blind back-translation review by Claude Sonnet. New glossary: width / height = चौड़ाई / ऊँचाई; minimum / maximum size = न्यूनतम / अधिकतम साइज़; optional = वैकल्पिक; format = फ़ॉर्मेट; use photo size = फ़ोटो का माप इस्तेमाल करें; px unit = पिक्सेल (as logged), KB in Latin script. Fixed after review (2): targetFormatLabel spelling फ़ॉर्मैट → फ़ॉर्मेट (more common UI spelling); targetHintVerySmall "अपने फ़ॉर्म" → "अपने आवेदन फ़ॉर्म", so it cannot read as this screen's input form. Not taken: उपयोग करें for इस्तेमाल करें (normal in app UIs). No back-translation drift. No high-risk keys. Open list: none.
- **2026-11-25, FEAT-007 export (23 keys; texts from PRD 1.3):** drafted by Claude Opus 5.5 (`localize-hi`), blind back-translation review by Claude Sonnet, second blind review of the high-risk keys by Claude Haiku. Gender decision: फ़ाइल is feminine (सेव हो गई, सेव हो रही है), as most current Hindi phone UIs write it; the earlier keys avoid agreement on it, so nothing conflicts. New glossary: Save / Share / Open = सेव करें / शेयर करें / खोलें; Choose where to save = सेव करने की जगह चुनें; Done = हो गया; Ready = इमेज तैयार है (output = इमेज, as logged); saved as = … नाम से सेव हो गई; share menu = शेयर मेन्यू; instead = इसके बजाय; Leave / Stay = वापस जाएँ / यहीं रहें; delete (leave) = हटा दी जाएगी; Storage permission = स्टोरेज की अनुमति; Settings = सेटिंग; px = पिक्सेल. Fixed after review (7): "इसकी जगह" → "इसके बजाय" (जगह already meant place and space); NoSpace "कुछ" → "थोड़ी"; NoViewer reworded so it cannot read as "no apps at all"; FileMissing "उपलब्ध नहीं" → "नहीं मिल रही" and "कोई बदलाव नहीं हुआ"; LeaveBody "मिटा" → "हटा" and the same gallery sentence; Leave and the title "बाहर निकलें" → "वापस जाएँ" (could read as quitting the app); ShareHint "अपलोड विंडो" (calque) → "अपलोड करते समय वही फ़ाइल चुनें". No meaning drift against the English. High-risk keys: the same 10 as for es; the second review found no grammar errors. Open list: (1) "स्टोरेज" and "सेटिंग" as the Android 9 Hindi names are [Assumption], not checked on a Hindi phone; both reviewers also preferred "अनुमति दें" over "चालू करें" (kept: the English says "turn on"). (2) Reviewer asked the privacy line to say the receiving app handles its copy by its own rules, and the leave text to say what else is lost: both add content the English does not have (final privacy copy belongs to FEAT-016). Not taken: "साइज़ घटा या बदल" for "छोटा कर" (English "shrink"); one word for इमेज/फ़ोटो (logged split). Mechanical checks: keys equal English, placeholders identical, gen-l10n and analyze clean; hi at 200% passes the result-screen layout test.
- **2026-11-25, open list decision:** the Product Owner delegated it ("do what's best"). (1) Checked Android's own Hindi strings (framework-res on the Realme 2 Pro, API 36): Settings = "सेटिंग" (confirmed); the storage group is "Files" / "फ़ाइल" on API 36, and the API 28 label could not be checked here, so "स्टोरेज की अनुमति" stays as a plain description. exportPermissionDenied now says "सेटिंग में जाकर अनुमति दें" (go to Settings and allow), matching the "अनुमति दें" (Allow) choice on Android's permission screen, as both reviewers suggested. (2) Not adding the receiving-app rules or other losses: they add content the English does not have, the same call as for the other languages. Open list: none.
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
- **2026-11-25, FEAT-007 export (23 keys; texts from PRD 1.3):** drafted by Claude Opus 5.5 (`localize-id`), blind back-translation review by Claude Sonnet, second blind review of the high-risk keys by Claude Haiku. Checked against Android's own Indonesian strings (framework-res on the Realme 2 Pro): Settings = "Setelan". New glossary: Save / Share / Open = Simpan / Bagikan / Buka; Choose where to save = Pilih lokasi penyimpanan; Done = Selesai; Ready = Gambar siap (output = gambar, as logged); saved as = File disimpan di … sebagai …; share menu = menu berbagi; instead = sebagai gantinya; the new (result) file = file hasil; storage permission = izin penyimpanan; allow = izinkan; Leave / Stay = Kembali / Tetap di sini; Saving… = Menyimpan…. No Malaysian forms; no meaning drift against the English. Fixed after review (5): "File baru" → "File hasil" (could read as any new file) and "Pilih ulang foto" in FileMissing and LeaveBody; PermissionDenied "Aktifkan izin itu" → "Izinkan akses penyimpanan di Setelan" (Android's permission screen says "Izinkan"); ShareHint "memperkecil" → "mengompres"; Privacy with an explicit actor ("Jika Anda menyimpan…"); Leave and the title "Keluar" → "Kembali" (both reviewers: could read as quitting the app; Leave goes back to choosing a photo). High-risk keys: the same 10 as for es; the second review found no grammar errors. Not taken: "perangkat" for "ponsel" (glossary); "aplikasi pesan" for "aplikasi chat"; a line that saved copies stay (the leave dialog appears only when nothing was saved or shared). Open list: none. Mechanical checks: keys equal English, placeholders identical, gen-l10n and analyze clean.
- **Status:** AI-reviewed only (no native speaker).

- **2026-11-24, FEAT-005 target step (12 keys):** targetPixelsNotWhole, targetLabelWidth/Height/Min/Max, targetOptional, targetUnitPx, targetUnitKb, targetFormatLabel, targetPhotoSize, targetUsePhotoSize, targetHintVerySmall. Drafted by Claude Opus 5.5 (`localize-id`), blind back-translation review by Claude Sonnet. New glossary: width / height = Lebar / Tinggi; minimum / maximum size = Ukuran minimum / maksimum; optional = Opsional; use photo size = Gunakan dimensi foto; px unit = piksel (as in the existing crop strings), KB kept. The review found no errors and no Malaysian terms; no back-translation drift. Not taken: "Periksalah" (optional softer form). No high-risk keys. Open list: none.

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
- **2026-11-24, FEAT-005 target step (12 keys):** targetPixelsNotWhole, targetLabelWidth/Height/Min/Max, targetOptional, targetUnitPx, targetUnitKb, targetFormatLabel, targetPhotoSize, targetUsePhotoSize, targetHintVerySmall. Drafted by Claude Opus 5.5 (`localize-ar`), blind back-translation review by Claude Sonnet. Digits: Western 0–9 (checked in code on 2026-11-21; unchanged). No bidi marks in the strings; the photo size in targetPhotoSize gets U+2068/U+2069 isolates in code (CropMessages.size), covered by a widget test. New glossary: width / height = العرض / الارتفاع; minimum / maximum size = الحد الأدنى / الأقصى للحجم; optional = اختياري; file format = صيغة الملف; use photo size = استخدام أبعاد الصورة (masdar button); px unit = بكسل, KB in Latin script. Fixed after review (1): targetFormatLabel "الصيغة" → "صيغة الملف" ("الصيغة" alone can read as formula or wording). Not taken: "أبعاد صورتك" in targetPhotoSize (the English says "Your photo"); dropping the shadda in تحقّق (the logged strings already use shadda, e.g. تعذّر). No back-translation drift. No high-risk keys. Open list: none.
- **2026-11-25, FEAT-007 export (23 keys; texts from PRD 1.3):** drafted by Claude Opus 5.5 (`localize-ar`), blind back-translation review by Claude Sonnet, second blind review of the high-risk keys by Claude Haiku. Digits: Western 0–9 (NumberFormat('ar'), unchanged; T20 test covers it). Checked against Android's own Arabic strings (framework-res on the Realme 2 Pro): Settings = "الإعدادات". New glossary: Save / Share / Open = حفظ / مشاركة / فتح (masdar); Choose where to save = اختيار مكان الحفظ; Done = تم; Ready = الصورة جاهزة; saved as = تم حفظ الملف في … باسم …; already saved = تم حفظ هذا الملف مسبقًا; share menu = قائمة المشاركة; instead = بدلًا من ذلك; the new (result) file = الملف الذي أنشأته; storage permission = إذن التخزين; Leave / Stay = الرجوع / البقاء; Saving… = جارٍ الحفظ…; upload = الرفع. Fixed after review (7): AlreadySaved "سبق حفظ" → "تم حفظ … مسبقًا" (register as the other saved texts); PermissionDenied "اسمح به من الإعدادات" → "انتقل إلى الإعدادات وامنح الإذن"; "الملف الجديد" → "الملف الذي أنشأته" in FileMissing and LeaveBody (first reviewer: ambiguous; second: "الناتج" too technical); ShareHint "تصغّر" → "تضغط" and "عند رفعه"; Leave "رجوع" → "الرجوع" (definite like "البقاء"). Code fix from the review: the ready line put width and height in two separate isolates, so Arabic showed "H × W"; ExportMessages.ready now keeps "W × H" in one LTR isolate (order as on the target step), tested in every locale. High-risk keys: the same 10 as for es; the second review found no grammar errors. Not taken: "جهاز" for "هاتف" (glossary); "مساحة تخزين" for "مساحة خالية" (the English says free space; matches pickLowSpace); adding "the shared copy leaves the app" or "you will need to create it again" (content the English does not have). Open list: none. Mechanical checks: keys equal English, placeholders identical, gen-l10n reports no untranslated keys in any language, analyze clean; Arabic goldens regenerated.
- **Status:** AI-reviewed only (no native speaker).

## Notes across languages

- **es number format:** the `es` locale in intl formats numbers Spain-style (10.240,5), while es-419 usually writes 10,240.5. The strings receive numbers that are already formatted, so the text is unaffected, but the numbers a Latin American user sees use comma decimals. Fixing it would need an `es_419` locale or a number-format override; this needs a Product Owner decision.
