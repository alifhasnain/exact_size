# Crop fixtures (FEAT-002-T02)

Synthetic, pattern-only images for the decoder, orientation and crop tests. No real photos,
faces or signatures. Regenerate with `tool/gen_crop_fixtures.py` (setup in its header).

Generator: Python 3.13.9, Pillow 11.3.0, pillow-heif 1.1.1 (libheif 1.20.2, x265 HEVC encoder (4.1+1-1d117be)).

Orientation convention: every `orient_*` file displays the same upright pattern (red quadrant
top-left, white arrow pointing up, black dot top-left) once its orientation is applied.

Byte-stable: two runs give identical files (checked 2026-11-21).

Large set (not committed): `tool/gen_crop_fixtures.py --large <dir> [--mp 12,50,100,200]` writes a
diagonal-line chart at each size as baseline JPEG, progressive JPEG, PNG, WebP (when no side
exceeds 16,383 px) and HEIC; then `adb push <dir> /sdcard/Download/exactsize_large/`. No network
is used. 12 MP takes about 10 s and 50 MP about 1 min on the dev PC.

| File | Purpose | Bytes | SHA-256 |
|---|---|---|---|
| `alpha_opaque.png` | PNG with an alpha channel, every pixel opaque | 385 | `85624255d9a590f922248405d581fbe496238a94c8831a9e17e1098de060ec00` |
| `alpha_partial.png` | PNG with partial alpha (gradient) | 437 | `2ba0017d81be11ecd2351a78420a52ce1da80ff52c4c6f561a7bf6281598e171` |
| `animated.gif` | Animated GIF, 3 frames; first frame upright | 2020 | `54f6740fe990dc4117a101f5675ecaf1a3edad46c14f54548f192a9de387ca06` |
| `animated.webp` | Animated WebP, 3 frames; first frame upright | 902 | `fb451015dfbaf44f6eaaac12daf1bf0350e15849fe749117bec30796c50a8b23` |
| `chart_diagonal.png` | Diagonal-line chart (aliasing check) | 1988 | `0abf65507ef6633b51f4da69ee7fa3bff8870ca77ae37919a18a4de0800c0924` |
| `chart_zone_plate.png` | Zone plate (resampling check) | 126979 | `2b76adda866ba9fa508a4ef56a91d0ae189941746a46a7604b8f6d5849bd9e50` |
| `claims_200000001px.png` | PNG header claiming 66,666,667 x 3 = 200,000,001 px, no pixel data | 45 | `42757ee05a1eacb9c78a76b978eeeb28e4a5d3f263b4d11d11909966cd65eeb5` |
| `cmyk.jpg` | CMYK JPEG (Adobe marker) | 3120 | `e6c3723844fae553358f71abf774fe4b0a6052a0858617ce8a3c3cb225bb2f01` |
| `corrupt.png` | PNG with zeroed IDAT bytes (bad CRC and data) | 379 | `4cbe56dd1367f4c7e909db6e13ac5ebb1cb4e64f70e95687d9d54d36f16abb0d` |
| `depth10.heic` | 10-bit HEIC | 1443 | `381e428fc1d74bf32a8ad3becc346ed579e16dc0eefa51e0be72d425ec559a32` |
| `depth16.png` | 16-bit grayscale PNG | 201 | `56dcf3c862094a9d9812d8ae0a1a8c2e8de27e8d0c31a7bd8fb03b948957d7e1` |
| `display_p3.png` | PNG tagged Display P3 (cHRM/gAMA) | 439 | `46f7f30edb4f5e22b812deb990c40307c9a1f8a65ea65e44695d6fa949043514` |
| `gray.png` | 8-bit grayscale PNG | 260 | `cfe44e1f2e32d7de542da62e2f6a1b7c3df353507180bb392ce9a20d390370aa` |
| `zero_bytes.jpg` | Empty file named .jpg (0 bytes) | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `not_an_image.jpg` | Text file with a .jpg name | 52 | `8751c3fcb0e7b85ca86993a55bcb054e4e6695d9e91ce3357f5963d78a37e967` |
| `orient_0_exif.jpg` | EXIF orientation 0 (invalid); treat as 1 | 2190 | `c47fdcc6218ad9e326b80780b0a8645a8555b99da2aa22298c45177cb6961d57` |
| `orient_1.heic` | HEIC, no transform | 1775 | `666f18b686e569d90ad71cdd99ea2b4471bf0d8ae5e84feee8670df8695219c4` |
| `orient_1_exif.jpg` | EXIF orientation 1; shows upright arrow, red top-left | 2190 | `16180b6dd871a604c4f555a76d5f4eaa0b7688439a8e09b375ad017882f2047b` |
| `orient_2_exif.jpg` | EXIF orientation 2; shows upright arrow, red top-left | 2196 | `f0cf978b6e2cd1f1419fe200df5a91362b4c8b8e8d4671d27fc98fc84c61df3b` |
| `orient_2_exif_only.heic` | HEIC orientation 2 in EXIF only (no irot/imir) | 1961 | `032e9c2dc086d99df5e29f1cd714a0b7cf04e1760f2716a8ef03b51534b8e17d` |
| `orient_2_irot_and_exif.heic` | HEIC orientation 2 as irot/imir plus matching EXIF (phone style) | 1971 | `415d08377bf9213e02447130a2a133d8419d7529fb876b40e86334410d2e0002` |
| `orient_2_irot_only.heic` | HEIC orientation 2 as irot/imir only (EXIF says 1) | 1971 | `d0fa518b65d18ff7195bb16d95bf6e7e6445d430c133fd779d7ec81c882536a1` |
| `orient_3_exif.jpg` | EXIF orientation 3; shows upright arrow, red top-left | 2207 | `eb1e830c156a30062723ed6614cc460083b9e9bf64118fce6d64907497aa74c5` |
| `orient_3_exif_only.heic` | HEIC orientation 3 in EXIF only (no irot/imir) | 1724 | `b3c76ea7e75aba8faa3b8dc6404f3f8579852f4ef12c5af0cbcf323d0cf5aa28` |
| `orient_3_irot_and_exif.heic` | HEIC orientation 3 as irot/imir plus matching EXIF (phone style) | 1734 | `decbe6cadd78b54e9ecce5217e6c2ce3d6b59623bdc9dffdcb53ef821561a818` |
| `orient_3_irot_only.heic` | HEIC orientation 3 as irot/imir only (EXIF says 1) | 1734 | `2b989efd6c6c0e40c62c91f3d68ac02427e516330657e254e1dc3c3daa2a0ebf` |
| `orient_4_exif.jpg` | EXIF orientation 4; shows upright arrow, red top-left | 2186 | `a6f218e57d53c41c9813eab295134a39fd6430e6c96628893087e504d067a238` |
| `orient_4_exif_only.heic` | HEIC orientation 4 in EXIF only (no irot/imir) | 1896 | `289754efed6ea0ef95da352b2ca04519fce2891c3f07a7192f1c44580f0833ce` |
| `orient_4_irot_and_exif.heic` | HEIC orientation 4 as irot/imir plus matching EXIF (phone style) | 1906 | `c4d2d0fd818f74f9ba23631cecba32bd743a827c7053b9219dae9741dfefcb1b` |
| `orient_4_irot_only.heic` | HEIC orientation 4 as irot/imir only (EXIF says 1) | 1906 | `2be71198673cc1136d7faf0b7670e6bd3d0525d7d52377ddbe4120f4c5dd2fec` |
| `orient_5_exif.jpg` | EXIF orientation 5; shows upright arrow, red top-left | 2212 | `7d65879cb1fde4f3c5a2c953a407498fce1b4da2d8248c77899469cf27c079c9` |
| `orient_5_exif_only.heic` | HEIC orientation 5 in EXIF only (no irot/imir) | 1893 | `567d6a9de46a222714ca28490edf04debe8b8fb18c700e6f1d8e66998d1ac488` |
| `orient_5_irot_and_exif.heic` | HEIC orientation 5 as irot/imir plus matching EXIF (phone style) | 1913 | `2a92a653d6375d93e28525c8380b1c4ab54d7ad713e91fa0da5329d891e5676d` |
| `orient_5_irot_only.heic` | HEIC orientation 5 as irot/imir only (EXIF says 1) | 1913 | `f5204b84af60b35ff470f6e13b613575ff9166c948c0375c08da066012be0110` |
| `orient_6_exif.jpg` | EXIF orientation 6; shows upright arrow, red top-left | 2235 | `4aacbea41b3c01734414d39fb7423ddf04972bad6d8da20faf29a2b67612343a` |
| `orient_6_exif_only.heic` | HEIC orientation 6 in EXIF only (no irot/imir) | 2020 | `21f0b1d0c116049b6dea565248efc94b862874259fa27e81abf89acb127a2e6c` |
| `orient_6_irot_and_exif.heic` | HEIC orientation 6 as irot/imir plus matching EXIF (phone style) | 2030 | `37bd3805892d99afac22d38325ab61a467a7831d88af0f97bfbc4b48f34e1d2f` |
| `orient_6_irot_only.heic` | HEIC orientation 6 as irot/imir only (EXIF says 1) | 2030 | `c9e354d8f72e473af601fc072311de010692aa58571ef38bb9976d91b72d2570` |
| `orient_7_exif.jpg` | EXIF orientation 7; shows upright arrow, red top-left | 2234 | `e985c1b0b24b3917b5624fcbf61ece200dbce687ef3ba23c7a17dbb2cac9d18c` |
| `orient_7_exif_only.heic` | HEIC orientation 7 in EXIF only (no irot/imir) | 1780 | `aa2d2a4923d5ba2004126794e56d7d9e07d94ea5ca512e08383ceff630247dd2` |
| `orient_7_irot_and_exif.heic` | HEIC orientation 7 as irot/imir plus matching EXIF (phone style) | 1800 | `83555120ede95886d1d82168d6a1578f5ab1f4271bd8f2abafe766be33eb9bf2` |
| `orient_7_irot_only.heic` | HEIC orientation 7 as irot/imir only (EXIF says 1) | 1800 | `794b9109104b1ec9db6c93d17306dc2704e424835178e5b44e26978456959124` |
| `orient_8_exif.jpg` | EXIF orientation 8; shows upright arrow, red top-left | 2223 | `f29a3816582e0b2691d689b1724bc27581ca90cd9917559caf2ff9a3e39e2ce7` |
| `orient_8_exif_only.heic` | HEIC orientation 8 in EXIF only (no irot/imir) | 1934 | `ccb1925d0afc23d8fc0f579c008da848d118f4542f05be0c4135f51eb8b364d4` |
| `orient_8_irot_and_exif.heic` | HEIC orientation 8 as irot/imir plus matching EXIF (phone style) | 1944 | `1cfa811284f8cd292c25a59b0305a6925691dc25a7b89b6e9d36eec273024b02` |
| `orient_8_irot_only.heic` | HEIC orientation 8 as irot/imir only (EXIF says 1) | 1944 | `6e1f46c99477c22056470f0e3712726c023064f930cf54a55fde871fb93eaf8e` |
| `orient_9_exif.jpg` | EXIF orientation 9 (invalid); treat as 1 | 2190 | `caca6da2329a887fbeaa34b56f8e64bf40562a65fa7ccdd20fcdd46e2e611608` |
| `orient_missing.jpg` | No EXIF at all; upright | 2154 | `c24ff73febb5fe65b964b3960ec3fb69f0b42f92a8e2d0b7649e3af8022c25cd` |
| `size_1000x100.png` | 1000x100 pattern | 726 | `13db14d5c1bbe62fadb56a6b3172b3f6e74f81ad9e46209a99529bbb81c41c80` |
| `size_1x1.png` | 1x1 pattern | 69 | `9853e99cb7e9817f7ee8b6fb9ade7c8e023d2520647034a098f7f85ed81e9cb0` |
| `size_200x200.png` | 200x200 pattern | 654 | `f956d3ef3e8d5a64ed58f6567ee2b44cdcf038f5dd3ed2faf8ea0485f75c725e` |
| `size_7x7.png` | 7x7 pattern | 115 | `ef239c06af2e52a23d6afc7eba539463351b8a04b552512b795444e5c1e3dec6` |
| `strip_strokes.png` | Thin-stroke strip, signature-like, synthetic | 1586 | `251ed8755c036150a2dc55ed7dbcd87920986f83091f6c3c247d4cb4a700d5b3` |
| `truncated.jpg` | JPEG cut in half | 1077 | `320936651a46d4448c1e4068a831d9f8ba7bacfcba5db33b8b2a6027862ab40f` |
