// FEAT-002-T13 (gate G2, ADR-005): visual chart for the Product Owner.
// Run on the host:
//   flutter test tool/resampler_chart.dart
// Writes docs/features/FEAT-002-crop-resize/t13/resampler_chart.png: each
// synthetic fixture reduced (aliasing check) and enlarged (softness check),
// Catmull-Rom (pinned) next to Mitchell. Alpha cells sit on a checkerboard.
// Not run in CI.
import 'dart:io';
import 'dart:typed_data';

import 'package:es_codec/es_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../test_support/es_resample_cases.dart';

const fixtures = 'test_support/crop_fixtures';
const out = 'docs/features/FEAT-002-crop-resize/t13/resampler_chart.png';

final class Row {
  const Row(this.label, this.rgba, this.w, this.h, this.alpha, this.down, this.up);
  final String label;
  final Uint8List rgba;
  final int w, h;
  final bool alpha;

  /// Reduction and enlargement factors.
  final double down, up;
}

Row fromPng(String name, String label, double down, double up) {
  final im = img.decodePng(File('$fixtures/$name').readAsBytesSync())!.convert(numChannels: 4, format: img.Format.uint8);
  return Row(label, Uint8List.fromList(im.getBytes(order: img.ChannelOrder.rgba)), im.width, im.height,
      im.hasAlpha, down, up);
}

img.Image toImage(Uint8List rgba, int w, int h, {required bool alpha}) {
  final im = img.Image.fromBytes(width: w, height: h, bytes: rgba.buffer, numChannels: 4, order: img.ChannelOrder.rgba);
  if (!alpha) return im;
  final board = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final v = ((x ~/ 8) + (y ~/ 8)).isEven ? 200 : 255;
      board.setPixelRgb(x, y, v, v, v);
    }
  }
  return img.compositeImage(board, im);
}

void main() {
  test('write the resampler chart', () {
    final rows = [
      fromPng('chart_diagonal.png', 'Diagonal lines 400x300', 0.27, 2.5),
      fromPng('chart_zone_plate.png', 'Zone plate 256x256', 0.37, 2.5),
      fromPng('strip_strokes.png', 'Thin strokes 600x120 (signature-like)', 0.5, 2.0),
      fromPng('alpha_partial.png', 'Alpha gradient 120x80', 0.5, 3.0),
      Row('Red disc on transparent 160x160', redDiscOnTransparent(160), 160, 160, true, 0.23, 2.0),
    ];
    const pad = 16, labelH = 22;
    final cells = <List<img.Image>>[];
    for (final r in rows) {
      final dw = (r.w * r.down).round(), dh = (r.h * r.down).round();
      final uw = (r.w * r.up).round(), uh = (r.h * r.up).round();
      // Show enlargements cropped to the top-left 300×200 so detail is visible.
      img.Image up(ResampleFilter f) {
        final full = toImage(resampleBytes(r.rgba, r.w, r.h, uw, uh, alpha: r.alpha, filter: f), uw, uh, alpha: r.alpha);
        return img.copyCrop(full, x: 0, y: 0, width: uw < 300 ? uw : 300, height: uh < 200 ? uh : 200);
      }

      // Reductions are shown at 2x with nearest-neighbour so aliasing is visible.
      img.Image down(ResampleFilter f) => img.copyResize(
          toImage(resampleBytes(r.rgba, r.w, r.h, dw, dh, alpha: r.alpha, filter: f), dw, dh, alpha: r.alpha),
          width: dw * 2,
          height: dh * 2,
          interpolation: img.Interpolation.nearest);
      cells.add([
        toImage(r.rgba, r.w, r.h, alpha: r.alpha),
        down(ResampleFilter.catmullRom),
        down(ResampleFilter.mitchell),
        up(ResampleFilter.catmullRom),
        up(ResampleFilter.mitchell),
      ]);
    }
    const heads = ['Source', 'Reduced (shown 2x), Catmull-Rom', 'Reduced (shown 2x), Mitchell', 'Enlarged (crop), Catmull-Rom', 'Enlarged (crop), Mitchell'];
    final colW = [for (var c = 0; c < 5; c++) cells.map((r) => r[c].width).reduce((a, b) => a > b ? a : b)];
    final rowH = [for (final r in cells) r.map((c) => c.height).reduce((a, b) => a > b ? a : b)];
    final width = colW.reduce((a, b) => a + b) + pad * 6;
    final height = labelH + rowH.reduce((a, b) => a + b) + (labelH + pad) * rows.length + pad;
    final sheet = img.Image(width: width, height: height);
    img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
    var x = pad;
    for (var c = 0; c < 5; c++) {
      img.drawString(sheet, heads[c], font: img.arial14, x: x, y: 4, color: img.ColorRgb8(0, 0, 0));
      x += colW[c] + pad;
    }
    var y = labelH;
    for (var r = 0; r < rows.length; r++) {
      final factors = 'reduced x${rows[r].down}, enlarged x${rows[r].up}';
      img.drawString(sheet, '${rows[r].label}: $factors', font: img.arial14, x: pad, y: y + 4, color: img.ColorRgb8(60, 60, 60));
      y += labelH;
      x = pad;
      for (var c = 0; c < 5; c++) {
        img.compositeImage(sheet, cells[r][c], dstX: x, dstY: y);
        x += colW[c] + pad;
      }
      y += rowH[r] + pad;
    }
    Directory(File(out).parent.path).createSync(recursive: true);
    File(out).writeAsBytesSync(img.encodePng(sheet));
    // ignore: avoid_print
    print('wrote $out (${sheet.width}x${sheet.height})');
  });
}
