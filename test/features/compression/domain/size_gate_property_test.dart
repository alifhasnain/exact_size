import 'dart:math';

import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/compression/domain/size_search.dart';
import 'package:exact_size/features/compression/domain/subsampling.dart';
import 'package:exact_size/features/compression/domain/target_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_encoder.dart';

/// FEAT-004-T13: final gate (FR-6) and failure details (FR-11) on 1,000 seeded
/// random targets and size curves.
void main() {
  test('1,000 random targets: success always in window, failures always explained', () {
    final rnd = Random(20261121);
    var successes = 0, padded = 0, failures = 0;
    for (var i = 0; i < 1000; i++) {
      // Random target: max 2..10,240 KB, min unset in a third of the cases.
      final maxKb = 2 + rnd.nextInt(10239);
      final minKb = rnd.nextInt(3) == 0 ? null : 1 + rnd.nextInt(maxKb - 1);
      final window = ByteWindow.fromKb(minKb: minKb, maxKb: maxKb);

      // Random curve: grows with quality (power 1..3), jagged noise, per-config factors.
      final base = 200 + rnd.nextInt(3000000);
      final span = rnd.nextInt(6000000);
      final power = 1 + rnd.nextDouble() * 2;
      final jitter = rnd.nextInt(4000);
      final seed = rnd.nextInt(1 << 30);
      final b444 = 1.0 + rnd.nextDouble() * 0.8, stdHuff = 1.0 + rnd.nextDouble() * 0.1;
      int curve(Subsampling s, bool opt, int q) {
        var size = base + span * pow(q / 100, power);
        size += Random(seed + q).nextInt(jitter + 1); // deterministic non-monotonic noise
        if (s == Subsampling.yuv444) size *= b444;
        if (!opt) size *= stdHuff;
        return size.round();
      }

      final enc = FakeEncoder(jpegSize: curve);
      final result = planJpeg(enc, window);
      expect(enc.calls.length, lessThanOrEqualTo(maxPasses), reason: 'case $i');
      switch (result) {
        case ReadyToWrite(:final bytes, :final notices, :final paddingBytes, :final quality):
          successes++;
          expect(window.contains(bytes.length), isTrue, reason: 'case $i: $window ${bytes.length}');
          expect(quality, greaterThanOrEqualTo(qFloor), reason: 'case $i');
          expect(notices.contains(Notice.narrowRange), window.narrow, reason: 'case $i');
          if (paddingBytes > 0) {
            padded++;
            expect(notices, contains(Notice.paddingAdded), reason: 'case $i');
          }
        case PlanFailed(:final failure):
          failures++;
          expect(failure.closestBytes, isNotNull, reason: 'case $i ${failure.reason}');
          expect(failure.direction, isNotNull, reason: 'case $i ${failure.reason}');
          expect(failure.direction == Direction.tooBig, failure.closestBytes! > window.hi,
              reason: 'case $i: direction matches the closest size');
      }
    }
    // The random space must exercise every branch, or the property proves little.
    expect([successes, padded, failures].every((n) => n > 0), isTrue,
        reason: 'successes $successes, padded $padded, failures $failures');
  });

  test('INVALID_TARGET and CANCELLED carry no closest size or direction', () {
    final invalid = (validateTarget(maxText: 'abc', format: 'jpeg') as InvalidTarget).failure;
    const cancelled = CompressionFailure(reason: Reason.cancelled);
    for (final f in [invalid, cancelled]) {
      expect((f.closestBytes, f.direction), (null, null));
    }
  });
}
