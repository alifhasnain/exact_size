import 'dart:typed_data';

import 'package:exact_size/features/compression/data/dart_png_encoder.dart';
import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/compression/domain/png_plan.dart';
import 'package:exact_size/features/compression/domain/size_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../../test_support/synthetic_image.dart';
import '../../../test_support/test_pixels.dart';
import 'fake_encoder.dart';

/// FEAT-004-T15: PNG path (FR-9, FR-10, FR-14), AC-3.1–3.3.
void main() {
  group('planPng (scripted sizes)', () {
    final window = ByteWindow.fromKb(minKb: 20, maxKb: 50); // [20,480, 50,000]
    var prepared = 0;
    void prepare() => prepared++;
    setUp(() => prepared = 0);

    test('in range → ready to write as PNG, one encode, no probe', () {
      final enc = FakeEncoder(jpegSize: (s, o, q) => 1, pngSize: 30000);
      final r = planPng(enc, window, prepareForJpegProbe: prepare) as ReadyToWrite;
      expect((r.format, r.bytes.length, r.paddingBytes), (OutputFormat.png, 30000, 0));
      expect((enc.pngCalls, enc.calls.length, prepared), (1, 0, 0));
    });

    test('above max → PNG_ABOVE_MAX; JPEG probe at q40 says it would fit', () {
      final enc = FakeEncoder(jpegSize: (s, o, q) => 45000, pngSize: 90000);
      final f = (planPng(enc, window, prepareForJpegProbe: prepare) as PlanFailed).failure;
      expect((f.reason, f.closestBytes, f.direction, f.jpegWouldFit),
          (Reason.pngAboveMax, 90000, Direction.tooBig, true));
      expect(enc.calls.single.quality, qFloor);
      expect(prepared, 1, reason: 'alpha flattened before the probe');
    });

    test('above max → PNG_ABOVE_MAX; JPEG probe says it would not fit', () {
      final enc = FakeEncoder(jpegSize: (s, o, q) => 70000, pngSize: 90000);
      final f = (planPng(enc, window, prepareForJpegProbe: prepare) as PlanFailed).failure;
      expect((f.reason, f.jpegWouldFit), (Reason.pngAboveMax, false));
    });

    test('below min → PNG_BELOW_MIN, no padding, no probe', () {
      final enc = FakeEncoder(jpegSize: (s, o, q) => 1, pngSize: 5000);
      final f = (planPng(enc, window, prepareForJpegProbe: prepare) as PlanFailed).failure;
      expect((f.reason, f.closestBytes, f.direction), (Reason.pngBelowMin, 5000, Direction.tooSmall));
      expect((enc.calls.length, prepared), (0, 0));
    });
  });

  group('DartPngEncoder (real PNG)', () {
    const w = 96, h = 64;
    const encoder = DartPngEncoder();

    for (final channels in [3, 4]) {
      test('lossless: decoded pixels equal the input ($channels channels)', () {
        final src = syntheticRgba(w, h, channels: channels);
        if (channels == 4) {
          for (var i = 3; i < src.length; i += 4) {
            src[i] = (i ~/ 4) % 256; // varied alpha
          }
        }
        final px = TestPixels(w, h, channels, Uint8List.fromList(src), hasTransparency: channels == 4);
        final png = encoder.encodePng(px);
        final decoded = img.decodePng(png)!;
        expect((decoded.width, decoded.height, decoded.numChannels), (w, h, channels));
        expect(decoded.getBytes(), src);
      });
    }

    test('pHYs adds exactly 21 bytes when DPI is set; no iCCP, eXIf or text chunks', () {
      final px = TestPixels(w, h, 3, syntheticRgba(w, h, channels: 3), hasTransparency: false);
      final plain = encoder.encodePng(px);
      final withDpi = encoder.encodePng(px, dpi: 300);
      expect(withDpi.length - plain.length, 21);
      final chunks = _chunkTypes(withDpi);
      expect(chunks, contains('pHYs'));
      expect(chunks.toSet().intersection({'iCCP', 'eXIf', 'tEXt', 'zTXt', 'iTXt'}), isEmpty);
      expect(_chunkTypes(plain), isNot(contains('pHYs')));
    });
  });
}

List<String> _chunkTypes(Uint8List png) {
  final types = <String>[];
  var i = 8; // PNG signature
  while (i + 8 <= png.length) {
    final len = (png[i] << 24) | (png[i + 1] << 16) | (png[i + 2] << 8) | png[i + 3];
    types.add(String.fromCharCodes(png.sublist(i + 4, i + 8)));
    i += 12 + len;
  }
  return types;
}
