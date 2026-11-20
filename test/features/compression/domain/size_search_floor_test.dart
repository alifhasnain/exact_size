import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/size_search.dart';
import 'package:exact_size/features/compression/domain/subsampling.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_encoder.dart';

/// FEAT-004-T11: FR-8 levers 1–3 (floor path) and the OQ-12 jump case.
void main() {
  /// Curve scripted per config: [a], [b], [c] map quality → bytes.
  SizeCurve perConfig(int Function(int q) a, int Function(int q) b, int Function(int q) c) =>
      (s, opt, q) => s == Subsampling.yuv420 ? a(q) : (opt ? b(q) : c(q));

  JpegConfig configOf(({Subsampling subsampling, bool optimiseHuffman, int quality}) call) =>
      JpegConfig.values.firstWhere(
          (c) => c.subsampling == call.subsampling && c.optimiseHuffman == call.optimiseHuffman);

  ({SearchOutcome out, List<JpegConfig> order}) run(SizeCurve curve, ByteWindow w) {
    final enc = FakeEncoder(jpegSize: curve);
    final out = searchJpeg(enc, w);
    final order = enc.calls.map(configOf).toList();
    expect(enc.calls.length, lessThanOrEqualTo(maxPasses));
    // A → B → C: configs never go backwards in the call log.
    for (var i = 1; i < order.length; i++) {
      expect(order[i].index, greaterThanOrEqualTo(order[i - 1].index), reason: '$order');
    }
    return (out: out, order: order);
  }

  final w = ByteWindow.fromKb(minKb: 20, maxKb: 50); // [20,480, 50,000]

  group('floor path (A@100 below the floor)', () {
    test('success at B@100', () {
      final r = run(perConfig((q) => 10000, (q) => 30000, (q) => 99999), w);
      final c = (r.out as SearchFit).candidate;
      expect((c.quality, c.subsampling, c.optimiseHuffman), (100, Subsampling.yuv444, true));
      expect(r.order, [JpegConfig.a, JpegConfig.b]);
    });

    test('success inside the B quality search', () {
      // B: q ≤ 70 → 40,000 (fits), above → 60,000.
      final r = run(perConfig((q) => 10000, (q) => q <= 70 ? 40000 : 60000, (q) => 99999), w);
      final c = (r.out as SearchFit).candidate;
      expect((c.quality, c.subsampling), (70, Subsampling.yuv444));
      expect(r.order.toSet(), {JpegConfig.a, JpegConfig.b});
    });

    test('success at C@100', () {
      final r = run(perConfig((q) => 10000, (q) => 15000, (q) => 25000), w);
      final c = (r.out as SearchFit).candidate;
      expect((c.quality, c.subsampling, c.optimiseHuffman), (100, Subsampling.yuv444, false));
      expect(r.order, [JpegConfig.a, JpegConfig.b, JpegConfig.c]);
    });

    test('hand-off to padding from C@100 when C is still below the floor', () {
      final r = run(perConfig((q) => 10000, (q) => 15000, (q) => 18000), w);
      final o = r.out as SearchBelowWindow;
      expect((o.candidate.size, o.candidate.optimiseHuffman, o.jumpCase), (18000, false, false));
    });

    test('hand-off to padding from B@100 when C jumps over the ceiling', () {
      final r = run(perConfig((q) => 10000, (q) => 15000, (q) => 60000), w);
      final o = r.out as SearchBelowWindow;
      expect((o.candidate.size, o.candidate.subsampling, o.candidate.optimiseHuffman), (15000, Subsampling.yuv444, true));
    });

    test('hand-off to padding from the B-search file when it lands below the floor', () {
      // B jumps from 15,000 (q ≤ 80) straight over the ceiling.
      final r = run(perConfig((q) => 10000, (q) => q <= 80 ? 15000 : 60000, (q) => 99999), w);
      final o = r.out as SearchBelowWindow;
      expect((o.candidate.quality, o.candidate.size, o.jumpCase), (80, 15000, false));
    });
  });

  group('jump case (OQ-12, narrow window)', () {
    final narrow = ByteWindow.fromKb(minKb: 49, maxKb: 50); // [49,000, 50,000]

    test('B at the same quality lands inside the window', () {
      // A: ≤ 60 → 45,000, above → 52,000 (jumps over 49–50 KB). B@60 = 49,500.
      final r = run(perConfig((q) => q <= 60 ? 45000 : 52000, (q) => 49500, (q) => 99999), narrow);
      final c = (r.out as SearchFit).candidate;
      expect((c.quality, c.subsampling), (60, Subsampling.yuv444));
    });

    test('neither B nor C fits: largest file under the ceiling goes to padding', () {
      final r = run(perConfig((q) => q <= 60 ? 45000 : 52000, (q) => 51000, (q) => 53000), narrow);
      final o = r.out as SearchBelowWindow;
      expect((o.candidate.size, o.candidate.subsampling, o.jumpCase), (45000, Subsampling.yuv420, true));
      expect(r.order.where((c) => c != JpegConfig.a), [JpegConfig.b, JpegConfig.c]);
    });
  });

  test('progressive is never requested: the Encoder API has no such setting', () {
    // Configs are baseline only (tech.md); TurboJpegEncoder sets PROGRESSIVE = 0 (T06).
    expect(JpegConfig.values.map((c) => (c.subsampling, c.optimiseHuffman)), [
      (Subsampling.yuv420, true),
      (Subsampling.yuv444, true),
      (Subsampling.yuv444, false),
    ]);
  });
}
