import 'dart:typed_data';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/flattener.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_support/test_pixels.dart';

/// FEAT-004-T14: FR-12 composite onto white, 4 → 3 channels in place.
void main() {
  // Rounding rule: out = (c·a + 255·(255 − a) + 127) ÷ 255, integer division
  // (round half up). Expected values below are worked out by hand from it.
  test('exact RGB for alpha 0, 1, 128, 254, 255', () {
    const c = [200, 100, 0]; // source R, G, B for every pixel
    final alphas = [0, 1, 128, 254, 255];
    final rgba = Uint8List.fromList([for (final a in alphas) ...[...c, a]]);
    final px = TestPixels(alphas.length, 1, 4, rgba, hasTransparency: true);
    TestPixels.allocations = 0;

    final notices = flattenForJpeg(px);

    expect(px.bytes.sublist(0, alphas.length * 3), [
      255, 255, 255, // a = 0: white
      255, 254, 254, // a = 1: 65097/255, 64997/255, 64897/255
      227, 177, 127, // a = 128: 58112/255, 45312/255, 32512/255
      200, 101, 1, // a = 254: 51182/255, 25782/255, 382/255
      200, 100, 0, // a = 255: unchanged
    ]);
    expect(px.channels, 3);
    expect(px.hasTransparency, isFalse);
    expect(notices, {Notice.transparencyFlattened});
    expect(identical(px.bytes, rgba), isTrue, reason: 'same buffer, written in place');
    expect(TestPixels.allocations, 0, reason: 'no new pixel allocation');
  });

  test('opaque 3-channel input is untouched and gets no notice', () {
    final rgb = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
    final px = TestPixels(2, 1, 3, rgb, hasTransparency: false);
    expect(flattenForJpeg(px), isEmpty);
    expect(px.channels, 3);
    expect(px.bytes, [1, 2, 3, 4, 5, 6]);
  });

  test('4-channel input without transparency is compacted without a notice', () {
    final px = TestPixels(2, 1, 4, Uint8List.fromList([9, 8, 7, 255, 6, 5, 4, 255]), hasTransparency: false);
    expect(flattenForJpeg(px), isEmpty);
    expect(px.channels, 3);
    expect(px.bytes.sublist(0, 6), [9, 8, 7, 6, 5, 4]);
  });
}
