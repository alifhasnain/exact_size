import 'dart:typed_data';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/target_validator.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/target_check.dart';
import 'package:exact_size/features/target/domain/target_input.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_support/test_pixels.dart';

/// FEAT-005-T02: domain types (tech section 4). Synthetic numbers only.
void main() {
  const spec = TargetSpec(width: 4321, height: 987, minKb: 55, maxKb: 321, format: OutputFormat.png);

  test('dimensions and request map every field; the buffer moves into the request', () {
    expect(spec.dimensions, const Target(4321, 987));
    final pixels = TestPixels(2, 2, 3, Uint8List(12), hasTransparency: false);
    final r = spec.request(pixels);
    expect(r.pixels, same(pixels));
    expect(r.minKb, 55);
    expect(r.maxKb, 321);
    expect(r.format, OutputFormat.png);
    expect(r.dpi, isNull);
    const noMin = TargetSpec(width: 1, height: 2, maxKb: 3, format: OutputFormat.jpeg);
    expect(noMin.request(pixels).minKb, isNull);
  });

  test('equality covers every field', () {
    expect(spec, const TargetSpec(width: 4321, height: 987, minKb: 55, maxKb: 321, format: OutputFormat.png));
    expect(spec.hashCode, const TargetSpec(width: 4321, height: 987, minKb: 55, maxKb: 321, format: OutputFormat.png).hashCode);
    for (final other in const [
      TargetSpec(width: 4320, height: 987, minKb: 55, maxKb: 321, format: OutputFormat.png),
      TargetSpec(width: 4321, height: 986, minKb: 55, maxKb: 321, format: OutputFormat.png),
      TargetSpec(width: 4321, height: 987, maxKb: 321, format: OutputFormat.png),
      TargetSpec(width: 4321, height: 987, minKb: 55, maxKb: 320, format: OutputFormat.png),
      TargetSpec(width: 4321, height: 987, minKb: 55, maxKb: 321, format: OutputFormat.jpeg),
    ]) {
      expect(spec, isNot(other));
    }
  });

  test('TargetInput defaults to empty texts and JPEG (FR-2); copyWith and withText', () {
    const empty = TargetInput();
    expect([empty.width, empty.height, empty.minKb, empty.maxKb], everyElement(''));
    expect(empty.format, OutputFormat.jpeg);
    final i = empty.copyWith(width: '4321', format: OutputFormat.png);
    expect(i.width, '4321');
    expect(i.format, OutputFormat.png);
    expect(i.copyWith(height: '987').width, '4321');
    for (final f in [TargetField.width, TargetField.height, TargetField.minKb, TargetField.maxKb]) {
      final w = empty.withText(f, '987');
      expect(w.text(f), '987');
      expect(TargetField.values.where((g) => g != f).map(w.text), everyElement(''));
    }
    expect(empty.withText(TargetField.format, '1'), empty);
    expect(empty.copyWith(maxKb: '9'), const TargetInput(maxKb: '9'));
  });

  test('toString of a spec and an input holds none of the numbers (FR-14)', () {
    const input = TargetInput(width: '4321', height: '987', minKb: '55', maxKb: '321');
    for (final s in ['$spec', '$input']) {
      for (final n in ['4321', '987', '55', '321']) {
        expect(s, isNot(contains(n)));
      }
    }
  });

  test('firstField follows W, H, Min, Max (then format) for every subset of fields', () {
    const error = KbError(TargetMessage.invalidNumber);
    final fields = TargetField.values;
    for (var mask = 1; mask < 1 << fields.length; mask++) {
      final present = [for (var i = 0; i < fields.length; i++) if (mask & 1 << i != 0) fields[i]];
      final r = TargetInputInvalid({for (final f in present.reversed) f: error});
      expect(r.firstField, present.first, reason: 'subset $present');
    }
  });

  test('errors compare by message', () {
    expect(const PixelRangeError(TargetDimensionsMessage.tooManyPixels), const PixelRangeError(TargetDimensionsMessage.tooManyPixels));
    expect(const PixelRangeError(TargetDimensionsMessage.tooManyPixels), isNot(const PixelRangeError(TargetDimensionsMessage.sideOutOfRange)));
    expect(const KbError(TargetMessage.maxOutOfRange), isNot(const KbError(TargetMessage.minNotBelowMax)));
    expect(const PixelsNotWhole(), const PixelsNotWhole());
  });
}
