import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/compression/domain/size_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/bitmap_factory.dart';
import 'corpus_harness.dart';

/// FEAT-004-T24 Done when: 100% of exports in window; ≥ 99% success on
/// feasible targets; 100% of infeasible targets fail; reports the pass-cap
/// rate and the padding share for 140×60 signatures at 10–20 KB.
/// FEAT-004-T25 (risk R6): every padded file must decode with Android's
/// BitmapFactory at its own size; the corpus runs on API 28 (CI) and API 36.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('500-export corpus', () async {
    final runs = <CorpusRun>[];
    final cases = buildCorpus();
    final clock = Stopwatch()..start();
    // A few cases at a time: each runs the runner and its reference on
    // separate isolates, so the emulator's cores are used.
    const parallel = 3;
    for (var i = 0; i < cases.length; i += parallel) {
      runs.addAll(await Future.wait([for (final c in cases.skip(i).take(parallel)) runCase(c)]));
      if (runs.length % 99 < parallel) {
        // ignore: avoid_print
        print('CORPUS progress ${runs.length}/${cases.length} after ${clock.elapsed.inSeconds} s');
      }
    }

    final outside = [
      for (final r in runs)
        if (r.plan case ReadyToWrite(:final bytes) when !r.c.window.contains(bytes.length)) '${r.c}: ${bytes.length} B',
    ];
    final feasible = runs.where((r) => r.feasible).toList();
    final missed = [
      for (final r in feasible)
        if (!r.exported) '${r.c}: ${(r.plan as PlanFailed).failure.reason.code}',
    ];
    final infeasibleExported = [
      for (final r in runs)
        if (!r.feasible && r.exported) '${r.c}',
    ];
    final undecodable = [
      for (final r in runs)
        if (r.padded && bitmapFactorySize((r.plan as ReadyToWrite).bytes) != (r.c.width, r.c.height)) '${r.c}',
    ];
    final exports = runs.where((r) => r.exported).length;
    final capped = runs.where((r) => r.passes == maxPasses).length;
    final sig = runs.where((r) => r.c.kind == TargetKind.signature10to20).toList();
    final sigPadded = sig.where((r) => r.padded).length;
    final reasons = <String, int>{};
    for (final r in runs) {
      final key = switch (r.plan) {
        ReadyToWrite w => w.paddingBytes > 0 ? 'EXPORT_PADDED' : 'EXPORT',
        PlanFailed(:final failure) => failure.reason.code,
      };
      reasons[key] = (reasons[key] ?? 0) + 1;
    }
    final successRate = feasible.isEmpty ? 1.0 : (feasible.length - missed.length) / feasible.length;

    // ignore: avoid_print
    print('CORPUS cases=${runs.length} exports=$exports feasible=${feasible.length} '
        'feasibleSuccess=${(successRate * 100).toStringAsFixed(2)}% missed=${missed.length} '
        'capBinds=$capped (${(capped * 100 / runs.length).toStringAsFixed(1)}%) '
        'sig140x60_10to20=${sig.length} padded=$sigPadded '
        'paddedDecoded=${runs.where((r) => r.padded).length - undecodable.length}/${runs.where((r) => r.padded).length} '
        'runS=${runs.fold(0, (t, r) => t + r.runMs) ~/ 1000} referenceS=${runs.fold(0, (t, r) => t + r.referenceMs) ~/ 1000} '
        'outcomes=${(reasons.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}:${e.value}').join(',')}');
    for (final m in missed) {
      // ignore: avoid_print
      print('CORPUS missed $m');
    }

    expect(exports, greaterThanOrEqualTo(500), reason: 'at least 500 exports');
    expect(outside, isEmpty, reason: 'every export inside its window (FR-6)');
    expect(infeasibleExported, isEmpty, reason: 'infeasible targets never export');
    expect(undecodable, isEmpty, reason: 'padded files decode with BitmapFactory (R6)');
    expect(successRate, greaterThanOrEqualTo(0.99), reason: 'feasible targets succeed (NFR-8)');
    expect(NativePixelBuffer.live, 0);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
