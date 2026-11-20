// FEAT-004-T26 (FR-7, gate G4): quality-floor study on the synthetic set.
// Run on the host (outputs are byte-identical across ABIs, gate G2):
//   flutter test tool/quality_floor_study.dart
// Writes docs/features/FEAT-004-kb-range-compression/t26/contact_sheet.png and
// prints the SSIM and stroke-breakup table. Not run in CI.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/data/turbo_jpeg_encoder.dart';
import 'package:exact_size/features/compression/domain/size_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../test_support/synthetic_images.dart';

const qualities = [30, 35, 40, 45, 50];

final class Sample {
  const Sample(this.name, this.signature, this.w, this.h, this.seed, {this.noise = 24});
  final String name;
  final bool signature;
  final int w, h, seed, noise;
  Uint8List rgb() => signature
      ? syntheticSignature(w, h, seed: seed)
      : syntheticPhoto(w, h, seed: seed, noise: noise);
}

const samples = [
  Sample('photo 1', false, 640, 480, 1),
  Sample('photo 2', false, 640, 480, 2),
  Sample('photo 3 smooth', false, 640, 480, 3, noise: 4),
  Sample('photo 4 smooth', false, 640, 480, 4, noise: 4),
  Sample('sig 300x100 a', true, 300, 100, 1),
  Sample('sig 300x100 b', true, 300, 100, 2),
  Sample('sig 140x60 a', true, 140, 60, 3),
  Sample('sig 140x60 b', true, 140, 60, 4),
];

Uint8List encode(Sample s, Uint8List rgb, int q) {
  final px = NativePixelBuffer.allocate(width: s.w, height: s.h, channels: 3, hasTransparency: false);
  try {
    px.bytes.setAll(0, rgb);
    // Config A, the main search path where the floor decides TOO_DEGRADED.
    return const TurboJpegEncoder().encodeJpeg(px.pointer,
        width: s.w,
        height: s.h,
        quality: q,
        subsampling: JpegConfig.a.subsampling,
        optimiseHuffman: JpegConfig.a.optimiseHuffman);
  } finally {
    px.free();
  }
}

Float64List luma(Uint8List rgb, int n) => Float64List.fromList(
    [for (var i = 0; i < n; i++) 0.299 * rgb[i * 3] + 0.587 * rgb[i * 3 + 1] + 0.114 * rgb[i * 3 + 2]]);

Uint8List rgbOf(img.Image im) {
  final out = Uint8List(im.width * im.height * 3);
  var i = 0;
  for (final p in im) {
    out[i++] = p.r.toInt();
    out[i++] = p.g.toInt();
    out[i++] = p.b.toInt();
  }
  return out;
}

/// Mean SSIM on luma over 8×8 windows with stride 4 (Wang et al. constants).
double ssim(Float64List a, Float64List b, int w, int h) {
  const c1 = (0.01 * 255) * (0.01 * 255), c2 = (0.03 * 255) * (0.03 * 255);
  var total = 0.0, count = 0;
  for (var y = 0; y + 8 <= h; y += 4) {
    for (var x = 0; x + 8 <= w; x += 4) {
      var ma = 0.0, mb = 0.0;
      for (var j = 0; j < 8; j++) {
        for (var i = 0; i < 8; i++) {
          ma += a[(y + j) * w + x + i];
          mb += b[(y + j) * w + x + i];
        }
      }
      ma /= 64;
      mb /= 64;
      var va = 0.0, vb = 0.0, cov = 0.0;
      for (var j = 0; j < 8; j++) {
        for (var i = 0; i < 8; i++) {
          final da = a[(y + j) * w + x + i] - ma, db = b[(y + j) * w + x + i] - mb;
          va += da * da;
          vb += db * db;
          cov += da * db;
        }
      }
      va /= 63;
      vb /= 63;
      cov /= 63;
      total += ((2 * ma * mb + c1) * (2 * cov + c2)) / ((ma * ma + mb * mb + c1) * (va + vb + c2));
      count++;
    }
  }
  return total / count;
}

/// Ink pixels (luma < 128) and their 4-connected components.
(int ink, int parts) inkStats(Float64List y, int w, int h) {
  final ink = List<bool>.generate(w * h, (i) => y[i] < 128);
  final seen = List<bool>.filled(w * h, false);
  var parts = 0, count = 0;
  for (var i = 0; i < w * h; i++) {
    if (!ink[i]) continue;
    count++;
    if (seen[i]) continue;
    parts++;
    final stack = [i];
    seen[i] = true;
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      final px = p % w, py = p ~/ w;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = px + dx, ny = py + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        final n = ny * w + nx;
        if (ink[n] && !seen[n]) {
          seen[n] = true;
          stack.add(n);
        }
      }
    }
  }
  return (count, parts);
}

img.Image imageOf(Uint8List rgb, int w, int h) =>
    img.Image.fromBytes(width: w, height: h, bytes: rgb.buffer, numChannels: 3);

void main() {
  test('quality floor study', () {
    final rows = <String>[];
    final ssimByClass = {
      for (final c in ['photo noisy', 'photo smooth', 'signature']) c: {for (final q in qualities) q: <double>[]}
    };
    // Contact sheet: original + each quality; photos as a 2× crop, signatures 3×.
    const cell = 300, labelH = 18;
    final sheet = img.Image(width: cell * (qualities.length + 1), height: (cell ~/ 2 + labelH) * samples.length + labelH);
    img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
    for (final (col, label) in [('original', 0), for (final q in qualities) ('q$q', qualities.indexOf(q) + 1)]
        .map((e) => (e.$2, e.$1))) {
      img.drawString(sheet, label, font: img.arial14, x: col * cell + 4, y: 2, color: img.ColorRgb8(0, 0, 0));
    }

    for (final (r, s) in samples.indexed) {
      final rgb = s.rgb();
      final n = s.w * s.h;
      final y0 = luma(rgb, n);
      final (ink0, parts0) = s.signature ? inkStats(y0, s.w, s.h) : (0, 0);
      final top = labelH + r * (cell ~/ 2 + labelH);
      img.drawString(sheet, s.name, font: img.arial14, x: 4, y: top, color: img.ColorRgb8(0, 0, 0));
      void place(Uint8List pixels, int col) {
        final full = imageOf(pixels, s.w, s.h);
        final view = s.signature
            ? img.copyResize(full, width: s.w * 3 > cell ? cell : s.w * 3, interpolation: img.Interpolation.nearest)
            : img.copyResize(img.copyCrop(full, x: 240, y: 180, width: cell ~/ 2, height: cell ~/ 4),
                width: cell, interpolation: img.Interpolation.nearest);
        img.compositeImage(sheet, img.copyCrop(view, x: 0, y: 0, width: math.min(view.width, cell), height: math.min(view.height, cell ~/ 2)),
            dstX: col * cell, dstY: top + labelH);
      }

      place(rgb, 0);
      for (final (i, q) in qualities.indexed) {
        final jpeg = encode(s, rgb, q);
        final decoded = rgbOf(img.decodeJpg(jpeg)!);
        final yq = luma(decoded, n);
        final v = ssim(y0, yq, s.w, s.h);
        ssimByClass[s.signature ? 'signature' : (s.noise < 24 ? 'photo smooth' : 'photo noisy')]![q]!.add(v);
        var breakup = '';
        if (s.signature) {
          final (ink, parts) = inkStats(yq, s.w, s.h);
          breakup = ' ink ${(ink * 100 / ink0).toStringAsFixed(0)}% parts $parts/$parts0';
        }
        rows.add('${s.name.padRight(16)} q$q ${jpeg.length.toString().padLeft(6)} B ssim ${v.toStringAsFixed(4)}$breakup');
        place(decoded, i + 1);
      }
    }

    final out = File('docs/features/FEAT-004-kb-range-compression/t26/contact_sheet.png')..createSync(recursive: true);
    out.writeAsBytesSync(img.encodePng(sheet, level: 9));
    // ignore: avoid_print
    print([
      'T26 per image:',
      ...rows,
      'T26 mean SSIM by class (floor now $qFloor):',
      for (final e in ssimByClass.entries)
        '${e.key.padRight(13)} ${qualities.map((q) => 'q$q ${(e.value[q]!.reduce((a, b) => a + b) / e.value[q]!.length).toStringAsFixed(4)}').join('  ')}',
    ].join('\n'));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
