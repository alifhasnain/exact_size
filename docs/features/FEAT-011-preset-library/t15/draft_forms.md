---
id: FEAT-011-T15-FORMS
title: Draft list of application forms with photo/signature upload rules
status: Proposed
version: 0.1
updated: 2026-11-27
links: [../prd.md, ../tasks.md]
---

# DRAFT — unverified research, not for the app until the Product Owner confirms each row against the source

- Read on 2026-11-27 for every row. Values below are only what the cited page states; nothing is converted or guessed.
- Where a row says "needs a chosen exact px value", the source gives no single pixel size (only KB, a range, or cm/mm). The Product Owner must pick the exact value.
- Confidence: High = official issuer page or PDF with explicit numbers. Medium = official, but an older copy, a mirror, or the page does not name the form. Low = third-party only (none kept).
- No personal data is involved: these are public form rules.

Summary: 15 forms. BD 2, IN 6, PK 1, ID 1, MX 1, US 2, AE 1, BH 1. High 11, Medium 4, Low 0.

---

## 1. bd-bpsc-bcs
- **Name / issuer:** BCS and other BPSC online applications (BPSC Form-1). Issuer: Bangladesh Public Service Commission (portal run by Teletalk).
- **Country / category:** BD / job
- **Source:** "Photo/Sign Validator", http://dept.bpsc.gov.bd/node/photo (page footer "Copyright © 2026"). Cross-check: 51st BCS (Special) 2026 circular PDF on bpsc.gov.bd, https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/n/axvjbnqprylg/b/V2Ministry/o/office-bpsc/2026/8/4b70ae19-3f03-409c-8367-8ba77a8f1468.pdf (linked from https://bpsc.gov.bd/pages/psc-exams/6ab4f1d2a5bee3786104b263). Read 2026-11-27.
- **Photo:** 300 × 300 px; max 100 KB (stated as "less than 100 KB"); min KB not stated; format not stated on the validator page.
- **Signature:** 300 × 80 px; max 60 KB ("less than 60 KB"); min KB not stated.
- **Extra rules:** none on the validator page.
- **Quote:** "Photograph dimensions is 300 X 300 pixels (Width X Height) 2. The file size is less than 100 KB." / "Signature dimensions is 300 X 80 pixels (Width X Height) 2. The file size is less than 60 KB."
- **Notes:** The 51st BCS circular's Bangla text did not extract (legacy font), but its Latin fragments read "300 × 300 … pixel … File Size 100 KB" and "300 × 80 pixel … File Size 60 KB", which match. Format (JPG) not confirmed on these pages.
- **Confidence:** High

## 2. bd-teletalk-govt-jobs
- **Name / issuer:** Teletalk-hosted government recruitment applications (help text shared across portals). Example cited: Directorate of Secondary and Higher Education (DSHE) recruitment portal. Same text on Bangladesh Police (TRC) portal.
- **Country / category:** BD / job
- **Source:** "Help" page, http://dshe.teletalk.com.bd/options/help.php (no date shown); same text at http://police.teletalk.com.bd/trc/options/help.php. Read 2026-11-27.
- **Photo:** 300 × 300 px; max 100 KB; min not stated; format not stated in the quoted part.
- **Signature:** 300 × 80 px; max 60 KB.
- **Extra rules:** colour only; "Black & White, Monochrome, Grayscale, Face too Close or too distance, Blurred … will not be accepted"; sign on white paper with black ink pen.
- **Quote:** "Photo dimensions are 300 X 300 pixels (Width X Height). The file size is less than 100 kbytes." / "Dimensions of signature are 300 x 80 pixels (Width X Height). Ensure that the size of the scanned image is not more than 60kb."
- **Notes:** Each circular on Teletalk can differ; this is the portal-wide help text, not one circular. Same numbers as row 1, so the app may need only one preset for both (Product Owner decision).
- **Confidence:** High

## 3. in-ibps-crp-clerk
- **Name / issuer:** IBPS Common Recruitment Process (Clerks), "Guidelines for scanning and Upload of Documents". Issuer: Institute of Banking Personnel Selection.
- **Country / category:** IN / job
- **Source:** PDF "Guidelines for scanning and Upload of Documents", https://ibpsreg.ibps.in/crpcsaxvjl25/uploads/loadpdf.php?file=k7m5p+fQ15erzNvW1Mrd4NPSnJp9sc%2FKYaao1bWrpok%3D&t=1LHArOLA2di0yczXwNDa083LmNWypw%3D%3D (no date in text; URL path "crpcsaxvjl25" suggests CRP CSA-XV, July 2025 — [Assumption]). Same numbers in another IBPS-hosted annexure, https://ibpsreg.ibps.in/ibsofeb26/... (Annexure II, 2026). Read 2026-11-27.
- **Photo:** 200 × 230 px ("preferred"); 20–50 KB; JPG/JPEG.
- **Signature:** 140 × 60 px ("preferred"); 10–20 KB; JPG/JPEG.
- **Extra rules:** recent passport-style colour photo, light (preferably white) background; no caps, hats or dark glasses; glasses allowed without reflections; religious headwear allowed if face not covered; photo label "(4.5cm × 3.5cm)"; scanner at least 200 dpi; signature in black ink, not in capital letters. A live photo is also captured by webcam/phone (separate from the upload). The form also asks for left thumb impression (240 × 240 px, 20–50 KB) and handwritten declaration (800 × 400 px, 50–100 KB), not in scope.
- **Quote:** "Dimensions 200 x 230 pixels (preferred). Size of file should be between 20kb–50 kb." / "Dimensions 140 x 60 pixels (preferred) … Size of file should be between 10kb – 20kb"
- **Notes:** "preferred" means the pixel size may not be enforced exactly.
- **Confidence:** High

## 4. in-upsc-caf
- **Name / issuer:** UPSC Common Application Form (all UPSC exams). Issuer: Union Public Service Commission.
- **Country / category:** IN / exam_admission (also recruitment)
- **Source:** PDF "Instructions for Uploading the Photo & Signature", https://upsconline.nic.in/caf/assets/PDF/instruction-photo-signature-upload-upsc.pdf (no date shown). Cross-check: Combined Medical Services Examination 2026, Notice No. 9/2026-CMS, dated 11.03.2026, https://upsc.gov.in/uploads/2026/05/Combined-Medical-Services-Examination-2026-Notice-E.pdf. Read 2026-11-27.
- **Photo:** px not stated; 20–200 KB; JPG; file named "photo".
- **Signature:** "350 - 500 pixels" (no width/height split); 20–100 KB; JPG; file named "signature"; three signatures one below the other in one image.
- **Extra rules:** plain white background; face covers at least 75% (3/4) of the photo; both ears visible; no dark/coloured glasses; avoid glare on eyeglasses; photo must not be signed; no uniform. Live photo capture is also mandatory and is matched against the upload.
- **Quote:** "Upload a photo named photo in jpg format with a file size between 20KB and 200KB." / "i. File size: 20 KB – 100 KB ii. Image dimensions: 350 - 500 pixels"
- **Notes:** Photo: KB only, no pixels — needs a chosen exact px value. Signature: pixel RANGE 350–500 with no axis stated — needs a chosen exact px value. Notice 9/2026 confirms 20–200 KB photo and 20–100 KB signature.
- **Confidence:** High

## 5. in-ssc-cgl (signature only)
- **Name / issuer:** Combined Graduate Level Examination, 2026. Issuer: Staff Selection Commission.
- **Country / category:** IN / job
- **Source:** Notice, "To be uploaded on the website of the Commission … on 21-05-2026", https://ssc.gov.in/api/attachment/uploads/masterData/NoticeBoards/Notice_of_adv_cgl_2025.pdf (file name says 2025, text is CGL 2026). Read 2026-11-27.
- **Photo:** not uploaded — captured live by webcam/mobile in the form. Not a preset.
- **Signature:** 10–20 KB; JPEG/JPG; about 6.0 cm × 2.0 cm (para 9.6) — see conflict.
- **Extra rules:** blurred or miniature signatures rejected; live photo without cap or spectacles.
- **Quote:** "Candidates are required to upload the scanned signature in JPEG/JPG format (10 to 20 KB). Image dimension of the signature should be about 6.0 cm (width) x 2.0 cm (height)."
- **Notes:** Same notice, Annexure section says "about 4.0 cm (Width) x 2.0 cm (Height)". Two values in one source; cm only and "about" — needs a chosen exact px value.
- **Confidence:** High

## 6. in-nta-neet-ug
- **Name / issuer:** NEET (UG) 2026, Information Bulletin. Issuer: National Testing Agency.
- **Country / category:** IN / exam_admission
- **Source:** "Information Bulletin for NEET(UG)-2026", https://cdnbbsr.s3waas.gov.in/s37bc1ec1d9c3426357e69acd5bf320061/uploads/2026/02/20260208939209382.pdf (application window 08 Feb–08 Mar 2026; listed on https://neet.nta.nic.in/documents/). Read 2026-11-27.
- **Photo:** px not stated; 10–200 KB; JPG/JPEG.
- **Signature:** px not stated; 10–100 KB; JPG/JPEG.
- **Extra rules:** colour or black & white; 80% face (without mask) incl. ears; white background; photo taken after 01 January 2026; live photo also captured.
- **Quote:** "80% area of the image should be candidate's face. Photograph should be in JPG/JPEG format (clearly legible) between 10 kb to 200 kb." / "Signature file should be in JPG/JPEG format between 10 kb to 100 kb"
- **Notes:** KB only, no pixels — needs a chosen exact px value (photo and signature). This is the 2026 cycle (exam held); NEET 2027 bulletin not checked.
- **Confidence:** High

## 7. in-nta-jee-main
- **Name / issuer:** JEE (Main) 2027, Information Bulletin. Issuer: National Testing Agency.
- **Country / category:** IN / exam_admission
- **Source:** "Information Bulletin-Joint Entrance Examination (Main) – 2027", https://cdnbbsr.s3waas.gov.in/s3f8e59f4b2fe7c5705bf878bbd494ccdf/uploads/2026/10/202610241890224107.pdf (uploaded Oct 2026; listed on https://jeemain.nta.nic.in/documents/). Read 2026-11-27.
- **Photo:** px not stated; 10–200 kB; JPG/JPEG.
- **Signature:** px not stated; 10–100 kB; JPG/JPEG.
- **Extra rules:** colour; 80% face incl. ears, without mask; white background; live photo also captured.
- **Quote:** "Size of the photograph should be between 10 kB to 200 kB and in JPG/JPEG format (clearly legible)." / "Signature file should be JPG/JPEG format (clearly legible) between 10 kB to 100 kB."
- **Notes:** KB only — needs a chosen exact px value. Same KB as NEET but NEET allows black & white; JEE says colour.
- **Confidence:** High

## 8. in-evisa
- **Name / issuer:** Indian e-Visa application. Issuer: Government of India (Indian Visa Online).
- **Country / category:** IN / visa_passport
- **Source:** "e-Visa" page, https://indianvisaonline.gov.in/evisa/tvoa.html (no date shown). Read 2026-11-27.
- **Photo:** square ("height and width … must be equal"), px not stated; 10 KB–1 MB; JPEG.
- **Signature:** not asked.
- **Extra rules:** full face, front view, eyes open, without spectacles; head centred, top of hair to bottom of chin; plain light-coloured or white background; no shadows; no borders.
- **Quote:** "Format - JPEG Size Minimum 10 KB Maximum 1 MB The height and width of the Photo must be equal."
- **Notes:** No pixels — needs a chosen exact px value. Max is in MB (1 MB); app must decide 1000 or 1024 KB. Search snippets cite a separate guide (visa/VSS_IMAGE.pdf) with 350–1000 px and max 300 KB for the regular (non-e) visa; not read, not used.
- **Confidence:** High

## 9. pk-fpsc
- **Name / issuer:** FPSC online application (posts and CSS). Issuer: Federal Public Service Commission.
- **Country / category:** PK / job
- **Source:** "Guidelines for Online Application Submission at FPSC" (file name "…updated_09-09-2025"), https://cp.fpsc.gov.pk/gr_one/Guidelines_for_Online_Application_Submission_FPSC_updated_09-09-2025.pdf. Read 2026-11-27.
- **Photo:** px not stated; max "less than 30 KB"; jpg/jpeg.
- **Signature:** not asked in this guide.
- **Extra rules:** recent passport-size picture; avoid informal pictures.
- **Quote:** "The picture size must be less than 30 KB and in "jpeg" format only. Avoid uploading informal pictures."
- **Notes:** KB only — needs a chosen exact px value. No minimum KB.
- **Confidence:** High

## 10. id-cpns-sscasn
- **Name / issuer:** Seleksi CPNS via SSCASN (pas foto upload). Issuers: Badan Kepegawaian Negara (portal) and each hiring agency.
- **Country / category:** ID / job
- **Source:** (a) "Pengumuman Nomor KP.01.02/A/4395/2024 tentang Penerimaan CPNS Kemenkes 2024", https://casn.kemkes.go.id/documents24/cpns/PENGUMUMAN_PENERIMAAN_CPNS_KEMENKES_2024.pdf. (b) "Pengumuman Seleksi CPNS BKN TA 2024", https://www.bkn.go.id/wp-content/uploads/2024/08/00.-Pengumuman-Seleksi-CPNS-BKN-TA-2024.pdf. (c) "Buku Panduan SSCASN" v1.1, https://sscasn.bkn.go.id/assets/dokumen/buku_panduan_pendaftaran_sscasn_v1_1.pdf. Read 2026-11-27.
- **Photo:** 4 × 6 cm (Kemenkes 2024); px not stated; min 80 KB per uploaded file (SSCASN guide); max "depends on file type" set by the agency — not stated in the sources read; format PDF or JPEG per document type.
- **Signature:** not asked.
- **Extra rules:** red background; formal clothing (BKN) / at least a shirt (Kemenkes); recent.
- **Quote:** "Pas foto terbaru ukuran 4x6 cm, sekurang-kurangnya menggunakan kemeja dengan latar belakang berwarna merah." / "ukuran minimal setiap berkas adalah 80 KB dengan ukuran maksimal tergantung jenis berkas"
- **Notes:** cm only — needs a chosen exact px value. Max KB unknown: search snippets cite "maksimal 200 Kb" from the SSCASN 2023 FAQ (https://sscasn2023.bkn.go.id/faqcpns), but that site did not load, so it is NOT read and NOT used. Rules vary per agency and year; 2026 formation not checked. The SSCASN account also does a liveness selfie (not an upload).
- **Confidence:** Medium

## 11. mx-unam-suayed
- **Name / issuer:** Concurso de Selección Noviembre 2026, licenciatura SUAyED (open and distance). Issuer: Universidad Nacional Autónoma de México (CASE/UNAM).
- **Country / category:** MX / exam_admission
- **Source:** "Instructivo" for the November 2026 selection, https://case.unam.mx/assets/docs/ingreso/instructivo-suayed-noviembre-2026.pdf (upload window 9–14 Oct 2026). Read 2026-11-27.
- **Photo:** px not stated; max 200 KB; JPG or JPEG.
- **Signature:** px not stated; max 200 KB; JPG or JPEG; scanned (not photographed), black ink on white unlined paper.
- **Extra rules:** colour; white background (no textured wall or curtains); no cap, hat, prescription glasses, dark glasses or novelty contact lenses; ears visible; no selfies; no crops from another ID.
- **Quote:** "Cada archivo deberá estar en formato JPG o JPEG y tener un peso máximo de 200 KB."
- **Notes:** KB only — needs a chosen exact px value (photo and signature). The 200 KB rule also covers the ID scan in the same tab. Only SUAyED checked; the main (in-person) UNAM selection notice was not checked.
- **Confidence:** High

## 12. us-dv-lottery
- **Name / issuer:** Diversity Immigrant Visa Program entry (DV-2026 instructions). Issuer: U.S. Department of State.
- **Country / category:** US / visa_passport
- **Source:** "Instructions For The 2026 Diversity Immigrant Visa Program (DV-2026)" as republished by U.S. Embassy in Cameroon, https://cm.usembassy.gov/instructions-for-the-2026-diversity-immigrant-visa-program-dv-2026/ (no date shown). travel.state.gov returned a bot-verification page and was not read. Read 2026-11-27.
- **Photo:** 600 × 600 px; max 240 kB; min not stated; JPEG; square.
- **Signature:** not asked.
- **Extra rules:** taken within the last six months; plain white or off-white background; full face, neutral expression, eyes open; no eyeglasses; no hat/head covering unless worn daily for religious reasons; no uniforms; scanned prints must be 2 × 2 in (51 × 51 mm) at 300 pixels per inch.
- **Quote:** "In JPEG (.jpg) file format Equal to or less than 240 kB (kilobytes) in file size In a square aspect ratio (height must equal width) 600×600 pixels in dimension"
- **Notes:** Embassy copy of the DV-2026 cycle; DV-2027/2028 instructions not found. Product Owner should confirm on travel.state.gov in a normal browser.
- **Confidence:** Medium

## 13. us-visa-digital-image
- **Name / issuer:** U.S. visa digital image technical specifications (the generic visa photo spec; DS-160 link is an [Assumption]). Issuer: U.S. Department of State, page by U.S. Embassy in Belgium.
- **Country / category:** US / visa_passport
- **Source:** "Photos - U.S. Embassy in Belgium", https://be.usembassy.gov/photos/ (no date shown). Read 2026-11-27.
- **Photo:** min 600 × 600 px, max 1200 × 1200 px, square; max 240 kilobytes; JPEG (JFIF); 24-bit colour, sRGB.
- **Signature:** not asked.
- **Extra rules:** compression ratio ≤ 20:1; scanned prints at least 2 × 2 in, scanned at ≥ 300 pixels per inch.
- **Quote:** "Minimum acceptable dimensions are 600 pixels (width) – 600 pixels (height). Maximum acceptable dimensions are 1200 pixels (width) – 1200 pixels (height)." / "File Size Must be less than or equal to 240 kilobytes."
- **Notes:** Pixel RANGE 600–1200 — needs a chosen exact px value. The page does not name the DS-160; the official DS-160/CEAC and travel.state.gov pages were behind bot verification and not read. Consider merging with row 12 if the PO picks 600 × 600.
- **Confidence:** Medium

## 14. ae-icp-personal-photo
- **Name / issuer:** ICP smart services personal photo (visa, residency, ID applications). Issuer: Federal Authority for Identity, Citizenship, Customs and Port Security (ICP), UAE.
- **Country / category:** AE / visa_passport
- **Source:** PDF "Personal Photo Specifications", https://smartservices.icp.gov.ae/echannels/web/client/manual/icao/icao_english.pdf (no date); ICP FAQ, https://icp.gov.ae/en/faq/. Read 2026-11-27.
- **Photo:** 35–40 mm wide (PDF); 3.5 × 4.5 cm (FAQ, stated for passport renewal from abroad); px not stated; KB not stated; format not stated.
- **Signature:** not asked.
- **Extra rules:** no more than 6 months old; face 70–80% of the photo; head and top of shoulders; plain light-coloured background (PDF) / white background (FAQ); no hats or sunglasses; medical glasses only if eyes visible; neutral expression.
- **Quote:** "no more than 6 months old … 35–40mm in width … so that your face takes up 70–80% of the photograph" (PDF text is right-to-left mangled as "-6months", "40–35mm", "%80–70").
- **Notes:** mm/cm only and no KB — needs a chosen exact px value and a KB limit is unknown. The two ICP sources give different wording for size and background.
- **Confidence:** Medium

## 15. bh-iga-id-card
- **Name / issuer:** Bahrain ID card photo (digital photo). Issuer: Information & eGovernment Authority (iGA), Kingdom of Bahrain.
- **Country / category:** BH / other (identity card)
- **Source:** PDF "ID Card Photo Requirements" (English), https://www.iga.gov.bh/Media/Others/ID%20card%20photo/ID%20Card%20Photo%20Requierments%20English.pdf (no date); Arabic version at the same folder. Read 2026-11-27.
- **Photo:** "Minimum 933x1244 pixels"; also "1244 × 933 pixels"; 32.5 mm × 43 mm, 3:4; 300 DPI; max 2 MB; jpeg/jpg; min KB not stated.
- **Signature:** not asked.
- **Extra rules:** colour, white background; not older than 6 months; no editing; face 70–80%; 3–4 mm space above head; no tinted glasses or coloured lenses; head covering allowed if face fully visible.
- **Quote:** "The size of the picture must not exceed 2 MB." / "The resolution of the image must be 1244 × 933 pixels." / "Minimum 933x1244 pixels"
- **Notes:** Internal inconsistency: 32.5 × 43 mm at 300 DPI is about 384 × 508 px, not 933 × 1244. One line says "minimum", another says "must be" — treat 933 × 1244 (W × H, 3:4 portrait) as [Hypothesis] pending PO check. Whether the photo is uploaded online (vs. taken at a centre) is not stated in the PDF.
- **Confidence:** High (official, numbers explicit) — but read the note.

---

## Looked for, could not source (not included)
- **Brazil — ENEM 2026:** Edital nº 64/2026 (copy at https://abmes.org.br/arquivos/legislacoes/Edital-inep-064-2026-05-21.pdf) has no photo upload at registration; the only 2 MB/JPG rule is for supporting documents. DOU original did not load.
- **Brazil — Cebraspe concursos:** Câmara dos Deputados Edital nº 1 – CD/PLF, 23 Jan 2026 requires a photo upload (head and shoulders, last six months) but gives no px, KB or format; says to follow the system's instructions.
- **Bangladesh — GST university admission and NTRCA teacher registration:** only newspaper reports (GST: 300 × 300 px, 100 KB per Prothom Alo); official portals returned 403 or had no spec.
- **India — RRB (Railway) CENs:** rrbchennai/rrbbbs sites unreachable from here; search snippets only.
- **USA — DS-160 / travel.state.gov / CEAC / dvprogram.state.gov:** bot verification page; not read (rows 12–13 use embassy copies instead).
- **Pakistan — PPSC:** "Photograph Guidelines" PDF on ppsc.gop.pk unreachable. NADRA not researched (photos are taken live at centres/app, [Assumption]).
- **Nepal — Lok Sewa Aayog:** no official spec found.
- **Indonesia — SSCASN 200 KB FAQ and SNPMB/UTBK:** FAQ site down; UTBK 2026 guide says "unggah pas foto berwarna terbaru" with no size.
- **Saudi Arabia — eVisa and Qiyas; Egypt — e-Visa:** only third-party pages (200 × 200 px, 5–100 KB) for Saudi eVisa; nothing for Qiyas or Egypt. Dropped as Low.
- **Colombia — ICFES Saber 11:** no photo spec found on icfes.gov.co.
