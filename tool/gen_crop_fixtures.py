"""FEAT-002-T02: synthetic crop/decoder fixtures.

Every image is drawn from patterns (quadrants, arrows, lines, zone plates,
strokes). No real photos, faces or signatures. Runs offline.

Setup (dev machine only, never shipped):
    python -m venv .venv-fixtures
    .venv-fixtures/Scripts/python -m pip install -r tool/crop_fixtures_requirements.txt
Small committed set (writes test_support/crop_fixtures/ and MANIFEST.md):
    .venv-fixtures/Scripts/python -I tool/gen_crop_fixtures.py
Large set, not committed (12/50/100/200 MP), then push to a device:
    .venv-fixtures/Scripts/python -I tool/gen_crop_fixtures.py --large <dir> [--mp 12,50]
    adb push <dir> /sdcard/Download/exactsize_large/
"""
import argparse
import hashlib
import io
import math
import struct
import sys
import zlib
from pathlib import Path

import PIL
import pillow_heif
from PIL import Image, ImageDraw, ImageOps, PngImagePlugin

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "test_support" / "crop_fixtures"

# EXIF orientation N: display = raw.transpose(TO_DISPLAY[N]); RAW_FROM_UPRIGHT is the inverse.
T = Image.Transpose
TO_DISPLAY = {2: T.FLIP_LEFT_RIGHT, 3: T.ROTATE_180, 4: T.FLIP_TOP_BOTTOM, 5: T.TRANSPOSE,
              6: T.ROTATE_270, 7: T.TRANSVERSE, 8: T.ROTATE_90}
RAW_FROM_UPRIGHT = {2: T.FLIP_LEFT_RIGHT, 3: T.ROTATE_180, 4: T.FLIP_TOP_BOTTOM, 5: T.TRANSPOSE,
                    6: T.ROTATE_90, 7: T.TRANSVERSE, 8: T.ROTATE_270}


def arrow_pattern(w=120, h=80):
    """Asymmetric: four coloured quadrants, an up arrow, a dot top-left.
    Any rotation or mirror changes which colour sits top-left and where the arrow points."""
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w // 2 - 1, h // 2 - 1], fill=(220, 40, 40))       # top-left red
    d.rectangle([w // 2, 0, w - 1, h // 2 - 1], fill=(40, 180, 60))      # top-right green
    d.rectangle([0, h // 2, w // 2 - 1, h - 1], fill=(40, 70, 220))      # bottom-left blue
    d.rectangle([w // 2, h // 2, w - 1, h - 1], fill=(240, 210, 40))     # bottom-right yellow
    cx = w // 2
    d.polygon([(cx, 8), (cx - 14, 30), (cx + 14, 30)], fill=(255, 255, 255))  # arrow head (up)
    d.rectangle([cx - 5, 30, cx + 5, h - 10], fill=(255, 255, 255))           # arrow shaft
    d.ellipse([4, 4, 14, 14], fill=(0, 0, 0))                                 # top-left marker
    return im


def exif_bytes(orientation):
    ex = Image.Exif()
    ex[0x0112] = orientation
    return ex.tobytes()


def patch_exif_orientation(data: bytes, old: int, new: int) -> bytes:
    """Rewrites the one EXIF orientation entry (tag 0x0112, SHORT) in place."""
    for order, tag in ((b"II", struct.pack("<HHI", 0x0112, 3, 1)), (b"MM", struct.pack(">HHI", 0x0112, 3, 1))):
        i = data.find(tag)
        if i >= 0:
            fmt = "<H" if order == b"II" else ">H"
            assert struct.unpack(fmt, data[i + 8:i + 10])[0] == old, "unexpected orientation value"
            return data[:i + 8] + struct.pack(fmt, new) + data[i + 10:]
    raise ValueError("no EXIF orientation entry")


def jpeg(im, **kw):
    b = io.BytesIO()
    im.save(b, format="JPEG", quality=92, **kw)
    return b.getvalue()


def png(im, **kw):
    b = io.BytesIO()
    im.save(b, format="PNG", optimize=False, compress_level=9, **kw)
    return b.getvalue()


def heic(im, **kw):
    b = io.BytesIO()
    pillow_heif.from_pillow(im).save(b, format="HEIF", quality=90, **kw)
    return b.getvalue()


def same(a, b, tol=40):
    """Mean absolute difference per channel; lossy codecs allowed some error."""
    a, b = a.convert("RGB"), b.convert("RGB")
    if a.size != b.size:
        return False
    da, db = a.tobytes(), b.tobytes()
    return sum(abs(x - y) for x, y in zip(da, db)) / len(da) < tol


def zone_plate(n=256):
    im = Image.new("L", (n, n))
    px = im.load()
    for y in range(n):
        for x in range(n):
            r2 = (x - n / 2) ** 2 + (y - n / 2) ** 2
            px[x, y] = int(127.5 + 127.5 * math.cos(math.pi * r2 / n))
    return im.convert("RGB")


def diagonal_chart(w=400, h=300):
    im = Image.new("RGB", (w, h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for k in range(-h, w, 12):
        d.line([(k, 0), (k + h, h)], fill=(0, 0, 0), width=1)
    for x in range(0, w, 50):
        d.line([(x, 0), (x, h)], fill=(200, 0, 0), width=1)
    return im


def stroke_strip(w=600, h=120, seed=3):
    im = Image.new("RGB", (w, h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    pts = [(x, h / 2 + (h / 3) * math.sin(x * 0.045 + seed) * math.cos(x * 0.011)) for x in range(20, w - 20, 2)]
    d.line(pts, fill=(20, 24, 60), width=2)
    return im


def p3_png(im):
    """PNG tagged with Display P3 primaries via cHRM + gAMA (no ICC file needed)."""
    def fixed(v):
        return struct.pack(">I", round(v * 100000))
    chrm = b"".join(fixed(v) for v in (0.3127, 0.3290, 0.680, 0.320, 0.265, 0.690, 0.150, 0.060))
    info = PngImagePlugin.PngInfo()
    info.add(b"cHRM", chrm)
    info.add(b"gAMA", struct.pack(">I", 45455))
    return png(im, pnginfo=info)


def png_header_only(width, height):
    """Valid signature and IHDR claiming width×height, then IEND: no pixel data."""
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IEND", b"")


def small_set():
    files = {}  # name -> (bytes, purpose)
    up = arrow_pattern()

    # Orientation 1–8: JPEG with EXIF; HEIC three ways.
    for n in range(1, 9):
        raw = up if n == 1 else up.transpose(RAW_FROM_UPRIGHT[n])
        files[f"orient_{n}_exif.jpg"] = (jpeg(raw, exif=exif_bytes(n)), f"EXIF orientation {n}; shows upright arrow, red top-left")
        if n == 1:
            files["orient_1.heic"] = (heic(raw), "HEIC, no transform")
            continue
        both = heic(raw, exif=exif_bytes(n))  # libheif writes irot/imir and keeps EXIF n
        files[f"orient_{n}_irot_and_exif.heic"] = (both, f"HEIC orientation {n} as irot/imir plus matching EXIF (phone style)")
        files[f"orient_{n}_irot_only.heic"] = (patch_exif_orientation(both, n, 1), f"HEIC orientation {n} as irot/imir only (EXIF says 1)")
        plain = heic(raw, exif=exif_bytes(1))
        files[f"orient_{n}_exif_only.heic"] = (patch_exif_orientation(plain, 1, n), f"HEIC orientation {n} in EXIF only (no irot/imir)")
    for n, label in ((0, "0 (invalid)"), (9, "9 (invalid)")):
        files[f"orient_{n}_exif.jpg"] = (jpeg(up, exif=exif_bytes(n)), f"EXIF orientation {label}; treat as 1")
    files["orient_missing.jpg"] = (jpeg(up), "No EXIF at all; upright")

    # Alpha, depth, colour.
    rgba = up.convert("RGBA")
    a = Image.linear_gradient("L").resize(up.size)
    partial = rgba.copy(); partial.putalpha(a)
    files["alpha_partial.png"] = (png(partial), "PNG with partial alpha (gradient)")
    files["alpha_opaque.png"] = (png(rgba), "PNG with an alpha channel, every pixel opaque")
    g16 = Image.linear_gradient("L").resize((256, 64)).convert("I").point(lambda v: v * 257).convert("I;16")
    files["depth16.png"] = (png(g16), "16-bit grayscale PNG")
    files["gray.png"] = (png(up.convert("L")), "8-bit grayscale PNG")
    files["display_p3.png"] = (p3_png(up), "PNG tagged Display P3 (cHRM/gAMA)")
    files["cmyk.jpg"] = (jpeg(up.convert("CMYK")), "CMYK JPEG (Adobe marker)")

    # Animation.
    frames = [up, up.transpose(T.ROTATE_180), up.transpose(T.FLIP_LEFT_RIGHT)]
    b = io.BytesIO(); frames[0].save(b, format="WEBP", save_all=True, append_images=frames[1:], duration=200, loop=0, lossless=True)
    files["animated.webp"] = (b.getvalue(), "Animated WebP, 3 frames; first frame upright")
    b = io.BytesIO(); frames[0].save(b, format="GIF", save_all=True, append_images=frames[1:], duration=200, loop=0)
    files["animated.gif"] = (b.getvalue(), "Animated GIF, 3 frames; first frame upright")

    # 10-bit HEIC (16-bit source, saved as 10-bit).
    pillow_heif.options.SAVE_HDR_TO_12_BIT = False
    hdr = pillow_heif.from_bytes(mode="RGB;16", size=up.size, data=b"".join(
        struct.pack("<HHH", r * 257, g * 257, bb * 257) for r, g, bb in up.getdata()))
    b = io.BytesIO(); hdr.save(b, format="HEIF", quality=90)
    files["depth10.heic"] = (b.getvalue(), "10-bit HEIC")

    # Broken input.
    good = jpeg(up)
    files["truncated.jpg"] = (good[: len(good) // 2], "JPEG cut in half")
    p = bytearray(png(up)); i = p.find(b"IDAT"); p[i + 10:i + 30] = bytes(20)
    files["corrupt.png"] = (bytes(p), "PNG with zeroed IDAT bytes (bad CRC and data)")
    files["zero_bytes.jpg"] = (b"", "Empty file named .jpg (0 bytes)")
    files["not_an_image.jpg"] = (b"This is a plain text file named .jpg, not an image.\n", "Text file with a .jpg name")
    files["claims_200000001px.png"] = (png_header_only(66666667, 3), "PNG header claiming 66,666,667 x 3 = 200,000,001 px, no pixel data")

    # Sizes and charts.
    for w, h in ((1, 1), (7, 7), (200, 200), (1000, 100)):
        files[f"size_{w}x{h}.png"] = (png(arrow_pattern().resize((w, h), Image.NEAREST)), f"{w}x{h} pattern")
    files["chart_diagonal.png"] = (png(diagonal_chart()), "Diagonal-line chart (aliasing check)")
    files["chart_zone_plate.png"] = (png(zone_plate()), "Zone plate (resampling check)")
    files["strip_strokes.png"] = (png(stroke_strip()), "Thin-stroke strip, signature-like, synthetic")
    return files


def self_check(files):
    """Each orientation fixture must display upright in Pillow's own reader."""
    up = arrow_pattern()
    for name, (data, _) in files.items():
        if name.startswith("orient_") and name.endswith(".jpg") and name[7] in "12345678":
            shown = ImageOps.exif_transpose(Image.open(io.BytesIO(data)))
            assert same(shown, up), f"{name} is not upright"
        if name.endswith(("_irot_and_exif.heic", "_irot_only.heic")) or name == "orient_1.heic":
            shown = pillow_heif.open_heif(io.BytesIO(data)).to_pillow()  # libheif applies irot/imir
            assert same(shown, up), f"{name} is not upright"
        if name.endswith("_exif_only.heic"):
            n = int(name.split("_")[1])
            shown = pillow_heif.open_heif(io.BytesIO(data)).to_pillow().transpose(TO_DISPLAY[n])
            assert same(shown, up), f"{name} EXIF orientation does not make it upright"


def write_small():
    files = small_set()
    self_check(files)
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.iterdir():
        if old.name != "MANIFEST.md":
            old.unlink()
    rows = []
    for name in sorted(files):
        data, purpose = files[name]
        (OUT / name).write_bytes(data)
        rows.append(f"| `{name}` | {purpose} | {len(data)} | `{hashlib.sha256(data).hexdigest()}` |")
    gen = (f"Python {sys.version.split()[0]}, Pillow {PIL.__version__}, pillow-heif {pillow_heif.__version__} "
           f"(libheif {pillow_heif.libheif_version()}, {pillow_heif.libheif_info()['HEIF']})")
    (OUT / "MANIFEST.md").write_text(
        "# Crop fixtures (FEAT-002-T02)\n\n"
        "Synthetic, pattern-only images for the decoder, orientation and crop tests. No real photos,\n"
        "faces or signatures. Regenerate with `tool/gen_crop_fixtures.py` (setup in its header).\n\n"
        f"Generator: {gen}.\n\n"
        "Orientation convention: every `orient_*` file displays the same upright pattern (red quadrant\n"
        "top-left, white arrow pointing up, black dot top-left) once its orientation is applied.\n\n"
        "Byte-stable: two runs give identical files (checked 2026-11-21).\n\n"
        "Large set (not committed): `tool/gen_crop_fixtures.py --large <dir> [--mp 12,50,100,200]` writes a\n"
        "diagonal-line chart at each size as baseline JPEG, progressive JPEG, PNG, WebP (when no side\n"
        "exceeds 16,383 px) and HEIC; then `adb push <dir> /sdcard/Download/exactsize_large/`. No network\n"
        "is used. 12 MP takes about 10 s and 50 MP about 1 min on the dev PC.\n\n"
        "| File | Purpose | Bytes | SHA-256 |\n|---|---|---|---|\n" + "\n".join(rows) + "\n",
        encoding="utf-8", newline="\n")
    print(f"wrote {len(files)} fixtures to {OUT}")


def write_large(out_dir: Path, mps):
    """12/50/100/200 MP in baseline JPEG, progressive JPEG, PNG, WebP (≤ 16383 px a side) and HEIC."""
    out_dir.mkdir(parents=True, exist_ok=True)
    for mp in mps:
        w = int(math.sqrt(mp * 1e6 * 4 / 3)); h = int(mp * 1e6 / w)
        im = diagonal_chart(w, h)  # cheap to draw at any size, compresses well
        stem = f"large_{mp}mp_{w}x{h}"
        im.save(out_dir / f"{stem}_baseline.jpg", quality=90)
        im.save(out_dir / f"{stem}_progressive.jpg", quality=90, progressive=True)
        im.save(out_dir / f"{stem}.png", compress_level=6)
        if max(w, h) <= 16383:
            im.save(out_dir / f"{stem}.webp", quality=80)
        pillow_heif.from_pillow(im).save(out_dir / f"{stem}.heic", quality=80)
        print(f"wrote {stem}.*")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--large", type=Path, help="write the large set here instead of the small set")
    ap.add_argument("--mp", default="12,50,100,200", help="megapixel sizes for --large")
    args = ap.parse_args()
    if args.large:
        write_large(args.large, [int(v) for v in args.mp.split(",")])
    else:
        write_small()
