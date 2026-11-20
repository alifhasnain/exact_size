import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/size_search.dart';
import 'package:exact_size/features/compression/domain/subsampling.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_encoder.dart';

/// FEAT-004-T10: JPEG search main path (FR-5, FR-7, NFR-1 cap) on scripted curves.
void main() {
  final linear = linearCurve(atQ1: 1000, atQ100: 100000); // config A: q → 1000·q roughly

  SearchOutcome run(FakeEncoder enc, ByteWindow w, {bool mainPathOnly = true}) {
    final out = searchJpeg(enc, w);
    expect(enc.calls.length, lessThanOrEqualTo(maxPasses), reason: 'NFR-1 pass cap');
    if (mainPathOnly) {
      expect(enc.calls.every((c) => c.subsampling == Subsampling.yuv420 && c.optimiseHuffman), isTrue,
          reason: 'main path uses config A only');
    }
    return out;
  }

  test('monotonic curve, no min (AC-8.2): highest quality under the ceiling', () {
    final out = run(FakeEncoder(jpegSize: linear), ByteWindow.fromKb(maxKb: 50)) as SearchFit;
    expect((out.candidate.quality, out.candidate.size), (50, 50000));
  });

  test('monotonic curve with a min: highest fitting quality, inside the window', () {
    final w = ByteWindow.fromKb(minKb: 20, maxKb: 50);
    final out = run(FakeEncoder(jpegSize: linear), w) as SearchFit;
    expect(out.candidate.quality, 50);
    expect(w.contains(out.candidate.size), isTrue);
  });

  test('A@100 already inside the window: one pass', () {
    final enc = FakeEncoder(jpegSize: linear);
    final out = run(enc, ByteWindow.fromKb(minKb: 90, maxKb: 120)) as SearchFit;
    expect((out.candidate.quality, enc.calls.length), (100, 1));
  });

  test('non-monotonic curve: the fitting neighbour (q+2) is chosen', () {
    // ≤54 fit, 55 too big, 56 fits again (dip), ≥57 too big. Binary search lands on 54.
    final enc = FakeEncoder(jpegSize: (s, o, q) => switch (q) {
          <= 54 => 40000,
          56 => 49000,
          _ => 60000,
        });
    final out = run(enc, ByteWindow.fromKb(maxKb: 50)) as SearchFit;
    expect(out.candidate.quality, 56);
    expect(enc.calls.map((c) => c.quality), containsAllInOrder([54, 55, 56]));
  });

  test('fits only below quality 40 → TOO_DEGRADED', () {
    final enc = FakeEncoder(jpegSize: linear);
    final out = run(enc, ByteWindow.fromKb(maxKb: 30)) as SearchFailure; // fits at q ≤ 30
    expect((out.reason, out.direction), (Reason.tooDegraded, Direction.tooBig));
    expect(out.closestBytes, linear(Subsampling.yuv420, true, qFloor));
    expect(enc.calls.last.quality, 1, reason: 'A@1 decides');
  });

  test('A@1 above the ceiling → ABOVE_MAX', () {
    final enc = FakeEncoder(jpegSize: linearCurve(atQ1: 60000, atQ100: 900000));
    final out = run(enc, ByteWindow.fromKb(maxKb: 50)) as SearchFailure;
    expect((out.reason, out.closestBytes, out.direction), (Reason.aboveMax, 60000, Direction.tooBig));
  });

  test('A@100 below the floor leaves the main path (levers in size_search_floor_test)', () {
    final out = run(FakeEncoder(jpegSize: linear), ByteWindow.fromKb(minKb: 200, maxKb: 300),
        mainPathOnly: false);
    expect(out, isA<SearchBelowWindow>().having((o) => o.jumpCase, 'jumpCase', false));
  });

  test('every scripted curve stays within 10 passes and never exports below q40', () {
    final curves = [
      linear,
      linearCurve(atQ1: 500, atQ100: 2000000),
      (Subsampling s, bool o, int q) => 1000 + q * q * 30, // convex
      (Subsampling s, bool o, int q) => 50000 + (q % 7) * 3000, // jagged
    ];
    for (final curve in curves) {
      for (var maxKb = 2; maxKb <= 2000; maxKb += 37) {
        final w = ByteWindow.fromKb(maxKb: maxKb);
        final out = run(FakeEncoder(jpegSize: curve), w);
        if (out case SearchFit(:final candidate)) {
          expect(w.contains(candidate.size), isTrue);
          expect(candidate.quality, greaterThanOrEqualTo(qFloor));
        }
      }
    }
  });
}
