import 'dart:io';

import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/target_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkTarget (FR-1, PRD section 8)', () {
    const side = TargetDimensionsMessage.sideOutOfRange;
    for (final (w, h, expected) in <(int, int, TargetDimensionsMessage?)>[
      (0, 100, side),
      (100, 0, side),
      (1, 1, null),
      (10000, 1, null),
      (1, 10000, null),
      (10001, 1, side),
      (1, 10001, side),
      (-1, 100, side),
      (100, -5, side),
      (6000, 4000, null), // exactly 24,000,000
      (4000, 6000, null),
      (10000, 2400, null), // 24,000,000
      (10000, 2401, TargetDimensionsMessage.tooManyPixels), // 24,010,000
    ]) {
      test('${w}x$h → ${expected?.name ?? 'valid'}', () {
        expect(checkTarget(Target(w, h)), expected);
      });
    }

    // No W, H ≤ 10,000 multiply to exactly 24,000,001, so the boundary is
    // checked with products just above 24 MP.
    test('just above 24 MP is refused as too large', () {
      expect(checkTarget(const Target(4899, 4899)), TargetDimensionsMessage.tooManyPixels); // 24,000,201
      expect(checkTarget(const Target(8000, 3001)), TargetDimensionsMessage.tooManyPixels); // 24,008,000
      expect(checkTarget(const Target(4898, 4899)), null); // 23,995,302
    });
  });

  test('Reason.values is exactly the FR-16 list', () {
    expect(Reason.values.map((r) => r.code), [
      'INVALID_TARGET_DIMENSIONS',
      'UNSUPPORTED_INPUT',
      'CORRUPT_INPUT',
      'SOURCE_UNAVAILABLE',
      'IMAGE_TOO_LARGE',
      'OUT_OF_MEMORY_HANDLED',
      'CANCELLED',
      'INTERNAL_ERROR',
    ]);
  });

  test('crop domain has no Flutter, Riverpod, get_it or JNI imports', () {
    final banned = RegExp(r'''import\s+['"]package:(flutter|flutter_riverpod|riverpod|get_it|injectable|jni|es_codec)[/'"]''');
    final hits = [
      for (final f in Directory('lib/features/crop/domain').listSync(recursive: true).whereType<File>())
        for (final line in f.readAsLinesSync())
          if (banned.hasMatch(line)) '${f.path}: $line',
    ];
    expect(Directory('lib/features/crop/domain').existsSync(), isTrue);
    expect(hits, isEmpty);
  });
}
