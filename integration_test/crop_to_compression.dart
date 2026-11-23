import 'dart:io';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart' show Notice, OutputFormat;
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/compression/domain/pixel_buffer.dart';
import 'package:exact_size/features/crop/data/crop_renderer.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-004-T27 (FR-1, FR-12, FR-13, FR-18, US-5): FEAT-002's real pixel
/// producer feeds FEAT-004 end to end. The crop render hands an ADR-003
/// buffer to CompressionRunner, which owns and frees it. Run through
/// crop_data_matrix.dart (fixtures and, for the 12/50 MP cases, LARGE_DIR).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUpAll(() async {
    dir = Directory('${(await getApplicationSupportDirectory()).path}/fixtures');
    for (var i = 0; i < 600 && !File('${dir.path}/.ready').existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(File('${dir.path}/.ready').existsSync(), isTrue, reason: 'fixtures were not pushed');
  });

  SourceHandle? handle(String name) {
    final f = File('${dir.path}/$name');
    return f.existsSync() ? SourceHandle(f.uri.toString()) : null;
  }

  /// Probe and render the default crop; the probe or render reason on failure.
  Future<(PixelBuffer?, Reason?)> produce(SourceHandle h, Target t) async {
    final p = await const SourceProbe().probe(h);
    if (p is ProbeErr) return (null, p.reason);
    final info = (p as ProbeOk).info;
    final r = await const CropRenderer().render(RenderRequest(
        src: h, info: info, cropRect: CropMath.toCropRect(CropMath.initial(info, t), info, t), quarterTurns: 0, target: t));
    return switch (r) {
      RenderOk(:final pixels) => (pixels, null),
      RenderErr(:final reason) => (null, reason),
    };
  }

  Future<PlanResult> compress(PixelBuffer px, {int? minKb = 40, int maxKb = 120, OutputFormat format = OutputFormat.jpeg}) =>
      const CompressionRunner().run(CompressionRequest(pixels: px, minKb: minKb, maxKb: maxKb, format: format));

  String outcome(PlanResult r) => r is ReadyToWrite ? 'READY' : (r as PlanFailed).failure.reason.code;

  testWidgets('AC-5.1: JPEG, PNG, HEIC and WebP sources of the same size behave the same', (_) async {
    const t = Target(600, 600);
    final names = [
      'large_12mp_4000x3000_baseline.jpg',
      'large_12mp_4000x3000.png',
      'large_12mp_4000x3000.heic',
      'large_12mp_4000x3000.webp',
    ];
    if (names.any((n) => handle(n) == null)) return markTestSkipped('12 MP set not pushed (LARGE_DIR)');
    final outcomes = <String, String>{};
    for (final n in names) {
      final (px, reason) = await produce(handle(n)!, t);
      expect(reason, isNull, reason: n);
      expect((px!.width, px.height, px.channels, px.hasTransparency), (600, 600, 3, false), reason: n);
      final r = await compress(px); // ownership moves to the runner
      outcomes[n] = outcome(r);
      if (r is ReadyToWrite) {
        expect(r.bytes.length, inInclusiveRange(40 * 1024, 120 * 1024), reason: n);
      }
    }
    // ignore: avoid_print
    print('T27 AC-5.1 $outcomes');
    expect(outcomes.values.toSet(), {'READY'});
  });

  testWidgets('hasTransparency travels with the buffer: PNG keeps alpha, JPEG flattens', (_) async {
    const t = Target(150, 100);
    final (alpha, _) = await produce(handle('alpha_partial.png')!, t);
    expect(alpha!.hasTransparency, isTrue);
    final png = await compress(alpha, minKb: null, maxKb: 200, format: OutputFormat.png);
    expect(png, isA<ReadyToWrite>());
    final (again, _) = await produce(handle('alpha_partial.png')!, t);
    final jpeg = await compress(again!, minKb: null, maxKb: 50);
    expect((jpeg as ReadyToWrite).notices, contains(Notice.transparencyFlattened));
    final (opaque, _) = await produce(handle('alpha_opaque.png')!, t);
    expect(opaque!.hasTransparency, isFalse);
    expect(opaque.channels, 3);
    (opaque as NativePixelBuffer).free(); // not handed over: the caller frees it
  });

  testWidgets('AC-5.2: a corrupt file and an undecodable variant give a clear reason, no crash', (_) async {
    // Gate G1 (ADR-004 v1.1): corrupt → CORRUPT_INPUT; a format the device
    // cannot decode (10-bit HEIC) → UNSUPPORTED_INPUT. Nothing reaches FEAT-004.
    for (final (name, expected) in [
      ('corrupt.png', Reason.corruptInput),
      ('not_an_image.jpg', Reason.corruptInput),
      ('depth10.heic', Reason.unsupportedInput),
    ]) {
      final (px, reason) = await produce(handle(name)!, const Target(300, 300));
      expect(px, isNull, reason: name);
      expect(reason, expected, reason: name);
    }
  });

  testWidgets('AC-5.3: a 50 MP source completes or returns IMAGE_TOO_LARGE, no crash', (_) async {
    var ran = 0;
    for (final n in ['large_50mp_8164x6124_baseline.jpg', 'large_50mp_8164x6124.heic']) {
      final h = handle(n);
      if (h == null) continue;
      ran++;
      final (px, reason) = await produce(h, const Target(1600, 1250));
      if (px == null) {
        expect(reason, anyOf(Reason.imageTooLarge, Reason.outOfMemoryHandled, Reason.unsupportedInput), reason: n);
        continue;
      }
      final r = await compress(px, minKb: 200, maxKb: 500);
      // ignore: avoid_print
      print('T27 AC-5.3 $n -> ${outcome(r)}');
      expect(outcome(r), anyOf('READY', 'IMAGE_TOO_LARGE'), reason: n);
    }
    if (ran == 0) markTestSkipped('50 MP set not pushed (LARGE_DIR)');
  });

  testWidgets('leak counters are 0 after the run', (_) async {
    expect(NativePixelBuffer.live, 0);
    expect(CropRenderer.liveNativeBlocks, 0);
  });
}
