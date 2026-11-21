import 'dart:math';

import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/orientation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Applies [o] to a raw grid of letters (rows of equal length).
List<String> render(Orientation o, List<String> raw) {
  final h = raw.length, w = raw.first.length;
  final (ow, oh) = o.orientedSize(w, h);
  final inv = o.inverse;
  return [
    for (var y = 0; y < oh; y++)
      [
        for (var x = 0; x < ow; x++)
          () {
            final (rx, ry) = inv.mapPoint(x + 0.5, y + 0.5, ow, oh);
            return raw[ry.floor()][rx.floor()];
          }(),
      ].join(),
  ];
}

void main() {
  // Raw 3×2 grid:  abc
  //                def
  const raw = ['abc', 'def'];

  group('EXIF 1–8 turn the raw grid upright (hand-written expectations)', () {
    const expected = <int, List<String>>{
      1: ['abc', 'def'],
      2: ['cba', 'fed'], // mirror horizontal
      3: ['fed', 'cba'], // rotate 180
      4: ['def', 'abc'], // mirror vertical
      5: ['ad', 'be', 'cf'], // transpose
      6: ['da', 'eb', 'fc'], // rotate 90 CW
      7: ['fc', 'eb', 'da'], // transverse
      8: ['cf', 'be', 'ad'], // rotate 270 CW
    };
    for (final MapEntry(key: exif, value: grid) in expected.entries) {
      test('EXIF $exif', () => expect(render(Orientation.fromExif(exif), raw), grid));
    }
  });

  test('0, 9, -1 and missing map to 1', () {
    for (final v in [0, 9, -1, null]) {
      expect(Orientation.fromExif(v), Orientation.identity, reason: '$v');
    }
  });

  test('four clockwise quarter-turns compose to the original for every EXIF value', () {
    for (var exif = 1; exif <= 8; exif++) {
      var o = Orientation.fromExif(exif);
      final start = o;
      for (var i = 0; i < 4; i++) {
        o = o.then(Orientation.rotation(1));
      }
      expect(o, start, reason: 'EXIF $exif');
    }
  });

  test('composition matches applying one transform after the other', () {
    for (var a = 1; a <= 8; a++) {
      for (var b = 1; b <= 8; b++) {
        final oa = Orientation.fromExif(a), ob = Orientation.fromExif(b);
        expect(render(oa.then(ob), raw), render(ob, render(oa, raw)), reason: '$a then $b');
      }
      expect(Orientation.fromExif(a).then(Orientation.fromExif(a).inverse), Orientation.identity);
    }
  });

  test('raw → oriented → raw is identity for 1,000 seeded rects per transform', () {
    final rng = Random(2);
    for (var exif = 1; exif <= 8; exif++) {
      final o = Orientation.fromExif(exif);
      for (var i = 0; i < 1000; i++) {
        final w = 1 + rng.nextInt(5000), h = 1 + rng.nextInt(5000);
        final x = rng.nextInt(w), y = rng.nextInt(h);
        final r = CropRect(x, y, 1 + rng.nextInt(w - x), 1 + rng.nextInt(h - y));
        final oriented = o.mapRect(r, w, h);
        final (ow, oh) = o.orientedSize(w, h);
        expect(oriented.x >= 0 && oriented.y >= 0, isTrue);
        expect(oriented.x + oriented.w <= ow && oriented.y + oriented.h <= oh, isTrue);
        expect(o.mapRectToRaw(oriented, w, h), r, reason: 'EXIF $exif $r in ${w}x$h');
      }
    }
  });

  test('display matrix maps the raw corners like mapPoint', () {
    for (var exif = 1; exif <= 8; exif++) {
      final o = Orientation.fromExif(exif);
      final (a, b, c, d, tx, ty) = o.matrix(400, 300);
      for (final (x, y) in [(0.0, 0.0), (400.0, 0.0), (0.0, 300.0), (123.0, 45.0)]) {
        expect((a * x + b * y + tx, c * x + d * y + ty), o.mapPoint(x, y, 400, 300));
      }
    }
  });
}
