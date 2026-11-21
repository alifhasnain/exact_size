import 'dart:io';
import 'dart:math' as math;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/crop/data/crop_renderer.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/presentation/crop_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-002-T29, gate G5 (NFR-1, NFR-2, NFR-5, NFR-8, FR-6, FR-25): memory
/// limits and reliability on the large set, timings for information. Prints
/// `G5 ...` lines. Run with the large set pushed (LARGE_DIR) and airplane mode
/// on:
///   DEVICE=[id] LARGE_DIR=[dir] flutter drive \
///     --driver test_driver/push_fixtures_driver.dart \
///     --target integration_test/crop_g5_profile.dart -d [id]
/// A missing large file skips its check (CI caches only the 12 and 50 MP set).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUpAll(() async {
    dir = Directory('${(await getApplicationSupportDirectory()).path}/fixtures');
    for (var i = 0; i < 1200 && !File('${dir.path}/.ready').existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(File('${dir.path}/.ready').existsSync(), isTrue, reason: 'fixtures were not pushed');
  });

  // ignore: avoid_print
  void report(String line) => print('G5 $line');

  int statusKb(String key) {
    final line = File('/proc/self/status').readAsLinesSync().firstWhere((l) => l.startsWith('$key:'));
    return int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
  }

  /// Runs [body] and returns the peak resident memory above the start, in MB.
  /// Resets the kernel's peak (VmHWM) where allowed; otherwise (API 36 denies
  /// it) samples VmRSS every 5 ms on this isolate while the render runs on its
  /// worker, which can miss a spike shorter than that.
  Future<double> peakMb(Future<void> Function() body) async {
    var hwm = true;
    try {
      File('/proc/self/clear_refs').writeAsStringSync('5');
    } on FileSystemException {
      hwm = false;
    }
    final before = statusKb('VmRSS');
    var peak = before, done = false;
    final run = body().whenComplete(() => done = true);
    while (!hwm && !done) {
      peak = math.max(peak, statusKb('VmRSS'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await run;
    peak = hwm ? statusKb('VmHWM') : math.max(peak, statusKb('VmRSS'));
    report('memory method=${hwm ? 'VmHWM' : 'VmRSS sampled 5 ms'}');
    return (peak - before) / 1024;
  }

  SourceHandle? handle(String name) {
    final f = File('${dir.path}/$name');
    return f.existsSync() ? SourceHandle(f.uri.toString()) : null;
  }

  Future<RenderResult> render(SourceHandle h, SourceInfo info, Target t) =>
      const CropRenderer().render(RenderRequest(
          src: h, info: info, cropRect: CropMath.toCropRect(CropMath.initial(info, t), info, t), quarterTurns: 0, target: t));

  String stats(List<int> ms) {
    ms.sort();
    final p95 = ms[math.min(ms.length - 1, (ms.length * 0.95).ceil() - 1)];
    return 'median=${ms[ms.length ~/ 2]} ms p95=$p95 ms n=${ms.length}';
  }

  /// 2 warm-ups, then [n] timed renders.
  Future<String> timeRenders(SourceHandle h, SourceInfo info, Target t, {int n = 20}) async {
    final ms = <int>[];
    for (var i = 0; i < n + 2; i++) {
      final sw = Stopwatch()..start();
      final r = await render(h, info, t);
      sw.stop();
      expect(r, isA<RenderOk>(), reason: r is RenderErr ? r.reason.code : '');
      ((r as RenderOk).pixels as NativePixelBuffer).free();
      if (i >= 2) ms.add(sw.elapsedMilliseconds);
    }
    return stats(ms);
  }

  const twoMp = Target(1600, 1250);

  testWidgets('12 MP: first frame, 12 → 2 MP renders and peak memory ≤ 200 MB', (tester) async {
    final h = handle('large_12mp_4000x3000_baseline.jpg');
    if (h == null) return markTestSkipped('12 MP fixture not pushed');
    final sw = Stopwatch()..start();
    final info = ((await const SourceProbe().probe(h)) as ProbeOk).info;
    final probeMs = sw.elapsedMilliseconds;
    final preview = (await const PreviewDecoder().decode(h, info) as PreviewOk).image;
    await tester.pumpWidget(ProviderScope(
      child: ExactSizeApp(
        locale: const Locale('en'),
        home: CropScreen(src: h, preview: preview, info: info, target: const Target(300, 300), onContinue: (_) {}, onChooseAnother: () {}),
      ),
    ));
    await tester.pump();
    await tester.pump(); // the crop session starts after the first frame
    report('first_frame_12mp probe=$probeMs ms total=${sw.elapsedMilliseconds} ms (FR-25, info)');
    preview.dispose();

    report('render_12mp_to_2mp ${await timeRenders(h, info, twoMp)} (NFR-1, info)');
    final mb = await peakMb(() async {
      final r = await render(h, info, twoMp);
      ((r as RenderOk).pixels as NativePixelBuffer).free();
    });
    report('memory_12mp_to_2mp attributable=${mb.toStringAsFixed(1)} MB (limit 200)');
    expect(mb, lessThanOrEqualTo(200));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('50 MP: renders to 2 MP; 24 MP target peak ≤ 350 MB or a handled refusal', () async {
    final h = handle('large_50mp_8164x6124_baseline.jpg');
    if (h == null) return markTestSkipped('50 MP fixture not pushed');
    final info = ((await const SourceProbe().probe(h)) as ProbeOk).info;
    report('render_50mp_to_2mp ${await timeRenders(h, info, twoMp)} (NFR-1, info)');
    RenderResult? r;
    final mb = await peakMb(() async => r = await render(h, info, const Target(6000, 4000)));
    final outcome = r is RenderErr ? (r! as RenderErr).reason.code : 'SUCCESS';
    if (r case RenderOk(:final NativePixelBuffer pixels)) pixels.free();
    report('memory_50mp_to_24mp attributable=${mb.toStringAsFixed(1)} MB outcome=$outcome (limit 350)');
    expect(mb <= 350 || outcome == Reason.imageTooLarge.code || outcome == Reason.outOfMemoryHandled.code, isTrue);
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('100 MP, 200 MP, corrupt, 1×1 and extreme ratio: handled outcome, no crash', () async {
    const allowed = {'SUCCESS', 'IMAGE_TOO_LARGE', 'OUT_OF_MEMORY_HANDLED', 'CORRUPT_INPUT', 'UNSUPPORTED_INPUT'};
    final cases = [
      ('large_100mp_11547x8660_baseline.jpg', twoMp),
      ('large_100mp_11547x8660.heic', twoMp),
      ('large_200mp_16329x12248_baseline.jpg', twoMp),
      ('large_200mp_16329x12248.png', twoMp),
      ('corrupt.png', const Target(300, 300)),
      ('not_an_image.jpg', const Target(300, 300)),
      ('size_1x1.png', const Target(300, 300)),
      ('chart_diagonal.png', const Target(1000, 10)),
      ('large_12mp_4000x3000_baseline.jpg', const Target(1000, 10)),
    ];
    for (final (name, t) in cases) {
      final h = handle(name);
      if (h == null) {
        report('outcome $name skipped (not pushed)');
        continue;
      }
      final sw = Stopwatch()..start();
      final p = await const SourceProbe().probe(h);
      final String outcome;
      if (p is ProbeErr) {
        outcome = p.reason.code;
      } else {
        final r = await render(h, (p as ProbeOk).info, t);
        outcome = r is RenderErr ? r.reason.code : 'SUCCESS';
        if (r case RenderOk(:final NativePixelBuffer pixels)) {
          expect((pixels.width, pixels.height), (t.width, t.height), reason: name);
          pixels.free();
        }
      }
      report('outcome $name -> ${t.width}x${t.height}: $outcome in ${sw.elapsedMilliseconds} ms');
      expect(allowed, contains(outcome), reason: name);
    }
    expect(CropRenderer.liveNativeBlocks, 0);
    expect(NativePixelBuffer.live, 0);
  }, timeout: const Timeout(Duration(minutes: 15)));
}
