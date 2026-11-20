import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/target_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_encoder.dart';

/// FEAT-004-T09: every PRD section 8 row (FR-16).
void main() {
  TargetMessage? msg(String? max, {String? min, String? format = 'jpeg'}) =>
      switch (validateTarget(maxText: max, minText: min, format: format)) {
        InvalidTarget(:final message) => message,
        ValidTarget() => null,
      };

  test('max bounds: 1 and 10,241 rejected, 2 and 10,240 accepted', () {
    expect(msg('1'), TargetMessage.maxOutOfRange);
    expect(msg('2'), isNull);
    expect(msg('10240'), isNull);
    expect(msg('10241'), TargetMessage.maxOutOfRange);
  });

  test('min must be smaller than max', () {
    expect(msg('50', min: '50'), TargetMessage.minNotBelowMax);
    expect(msg('50', min: '60'), TargetMessage.minNotBelowMax);
    expect(msg('50', min: '20'), isNull);
    expect(msg('50', min: ''), isNull, reason: 'empty min = unset');
  });

  test('negative, zero, blank and NaN are not valid sizes', () {
    for (final bad in ['-5', '0', '', '   ', 'NaN', 'abc', null]) {
      expect(msg(bad), TargetMessage.invalidNumber, reason: 'max "$bad"');
    }
    expect(msg('50', min: '-1'), TargetMessage.invalidNumber);
    expect(msg('50', min: '0'), TargetMessage.invalidNumber);
  });

  test('decimals are rejected in R1 (OQ-5)', () {
    expect(msg('7.5'), TargetMessage.wholeNumbersOnly);
    expect(msg('50', min: '20.5'), TargetMessage.wholeNumbersOnly);
  });

  test('format must be JPEG or PNG', () {
    expect(msg('50', format: 'png'), isNull);
    for (final bad in ['webp', 'heic', '', null]) {
      expect(msg('50', format: bad), TargetMessage.chooseJpegOrPng, reason: '$bad');
    }
  });

  test('a valid target is typed', () {
    final v = validateTarget(maxText: ' 50 ', minText: '20', format: 'PNG') as ValidTarget;
    expect((v.minKb, v.maxKb, v.format), (20, 50, OutputFormat.png));
  });

  test('INVALID_TARGET is decided before any encoding', () {
    final encoder = FakeEncoder(jpegSize: linearCurve(atQ1: 1, atQ100: 2));
    final result = validateTarget(maxText: '0', format: 'jpeg');
    expect((result as InvalidTarget).reason, Reason.invalidTarget);
    expect(encoder.calls, isEmpty);
    expect(encoder.pngCalls, 0);
  });
}
