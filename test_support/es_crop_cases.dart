import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:es_codec/es_codec.dart';
import 'package:exact_size/features/crop/domain/orientation.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pixel id of raw (x, y), spread over R and G so ids stay unique.
List<int> _id(int x, int y) => [x, y, x ^ y, 255];

/// FEAT-002-T14 checks shared by test/ (host) and integration_test/ (emulator;
/// adds the jnigraphics lock).
void defineEsCropTests() {
  test('es_orient gives the same grid as the Dart D4 mapping for all 8 transforms', () {
    for (final (w, h) in [(3, 2), (7, 5), (1, 4), (64, 33)]) {
      for (var exif = 1; exif <= 8; exif++) {
        final o = Orientation.fromExif(exif);
        final input = malloc<Uint8>(w * h * 4), output = malloc<Uint8>(w * h * 4);
        try {
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              input.asTypedList(w * h * 4).setAll((y * w + x) * 4, _id(x, y));
            }
          }
          orient(input, w, h, 4, output, mirrored: o.mirrored, quarterTurns: o.quarterTurns);
          final (ow, oh) = o.orientedSize(w, h);
          final out = output.asTypedList(w * h * 4);
          final inv = o.inverse;
          for (var y = 0; y < oh; y++) {
            for (var x = 0; x < ow; x++) {
              final (rx, ry) = inv.mapPoint(x + 0.5, y + 0.5, ow, oh);
              expect(out.sublist((y * ow + x) * 4, (y * ow + x) * 4 + 4), _id(rx.floor(), ry.floor()),
                  reason: 'EXIF $exif ${w}x$h at ($x, $y)');
            }
          }
        } finally {
          malloc.free(input);
          malloc.free(output);
        }
      }
    }
  });

  test('es_orient handles 3-channel buffers and refuses bad arguments', () {
    final input = malloc<Uint8>(6 * 3), output = malloc<Uint8>(6 * 3);
    addTearDown(() => [input, output].forEach(malloc.free));
    input.asTypedList(18).setAll(0, List.generate(18, (i) => i));
    orient(input, 3, 2, 3, output, mirrored: false, quarterTurns: 2); // 180°: pixel order reversed
    expect(output.asTypedList(18), [15, 16, 17, 12, 13, 14, 9, 10, 11, 6, 7, 8, 3, 4, 5, 0, 1, 2]);
    expect(() => orient(input, 3, 2, 3, output, mirrored: false, quarterTurns: 4), throwsStateError);
  });

  test('es_finish: one alpha 254 keeps RGBA; all 255 compacts to RGB with RGB unchanged', () {
    const w = 17, h = 9;
    final buf = malloc<Uint8>(w * h * 4);
    addTearDown(() => malloc.free(buf));
    Uint8List fill() {
      final b = buf.asTypedList(w * h * 4);
      for (var i = 0; i < w * h; i++) {
        b.setAll(i * 4, [i % 251, (i * 7) % 253, (i * 13) % 255, 255]);
      }
      return Uint8List.fromList(b);
    }

    var before = fill();
    buf[(5 * w + 3) * 4 + 3] = 254;
    expect(finishAlpha(buf, w, h), isTrue);
    before[(5 * w + 3) * 4 + 3] = 254;
    expect(buf.asTypedList(w * h * 4), before, reason: 'transparent buffer untouched');

    before = fill();
    expect(finishAlpha(buf, w, h), isFalse);
    final rgb = buf.asTypedList(w * h * 3);
    for (var i = 0; i < w * h; i++) {
      expect(rgb.sublist(i * 3, i * 3 + 3), before.sublist(i * 4, i * 4 + 3), reason: 'pixel $i');
    }
  });

  if (Platform.isAndroid) {
    test('jnigraphics lock reads a synthetic bitmap in place, values match Java', () {
      const w = 37, h = 11;
      final bmp = Bitmap.createBitmap$10(w, h, Bitmap$Config.ARGB_8888)!;
      try {
        bmp.premultiplied = false;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            bmp.setPixel(x, y, (0xff << 24) | (x * 6 << 16) | (y * 20 << 8) | ((x + y) & 0xff));
          }
        }
        withBitmapPixels(bmp, (p, bw, bh, stride) {
          expect((bw, bh), (w, h));
          expect(stride, greaterThanOrEqualTo(w * 4));
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final c = bmp.getPixel(x, y);
              final o = y * stride + x * 4;
              expect([p[o], p[o + 1], p[o + 2], p[o + 3]], [(c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff, (c >> 24) & 0xff],
                  reason: '($x, $y)');
            }
          }
        });
      } finally {
        bmp.recycle();
        bmp.release();
      }
    });
  }
}
