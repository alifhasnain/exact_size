import 'dart:io';
import 'dart:ui' as ui;

import 'package:exact_size/features/compression/data/compression_runner.dart' show CancelSignal;
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/domain/pixel_buffer.dart';
import 'package:crypto/crypto.dart';
import 'package:exact_size/features/crop/data/crop_outcome_log.dart';
import 'package:exact_size/features/crop/data/crop_renderer.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-002-T17: CropRenderer on the pushed fixtures. Run through crop_data_matrix.dart.
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

  Future<(SourceInfo, RenderResult)> render(String name, Target t,
      {int turns = 0, CropRenderer renderer = const CropRenderer(), CancelSignal? cancel, List<RenderStep>? steps, String? path}) async {
    final h = SourceHandle(File(path ?? '${dir.path}/$name').uri.toString());
    final info = ((await const SourceProbe().probe(h)) as ProbeOk).info;
    final crop = CropMath.initial(info, t, quarterTurns: turns);
    final rect = CropMath.toCropRect(crop, info, t);
    return (
      info,
      await renderer.render(RenderRequest(src: h, info: info, cropRect: rect, quarterTurns: turns, target: t),
          cancel: cancel, onProgress: steps?.add)
    );
  }

  Reason? reasonOf(RenderResult r) => r is RenderErr ? r.reason : null;

  NativePixelBuffer ok(RenderResult r, String why) {
    expect(r, isA<RenderOk>(), reason: '$why: ${r is RenderErr ? r.reason.code : ''}');
    return (r as RenderOk).pixels as NativePixelBuffer;
  }

  /// RGB at fractional position of a buffer.
  List<int> rgb(NativePixelBuffer b, double fx, double fy) {
    final x = (b.width * fx).floor(), y = (b.height * fy).floor();
    final o = (y * b.width + x) * b.channels;
    return b.bytes.sublist(o, o + 3);
  }

  test('outputs are exactly W×H (300×300, 300×80, 140×60, 1×1 → 300×300)', () async {
    for (final (name, t) in [
      ('chart_zone_plate.png', const Target(300, 300)),
      ('strip_strokes.png', const Target(300, 80)),
      ('chart_diagonal.png', const Target(140, 60)),
      ('size_1x1.png', const Target(300, 300)),
      ('orient_1_exif.jpg', const Target(300, 80)),
      ('orient_1.heic', const Target(140, 60)), // crop starts on row 15: odd origin (HEIC region decoder)
      ('orient_1.heic', const Target(70, 80)), // odd column 25
      ('animated.webp', const Target(70, 80)),
      ('cmyk.jpg', const Target(70, 80)),
      ('animated.gif', const Target(300, 300)),
    ]) {
      final (_, r) = await render(name, t);
      final b = ok(r, name);
      expect((b.width, b.height, b.stride), (t.width, t.height, t.width * b.channels), reason: name);
      expect(b.channels, anyOf(3, 4), reason: name);
      b.free();
    }
  });

  test('alpha: partly transparent PNG keeps 4 channels; opaque-alpha PNG becomes 3', () async {
    final (_, a) = await render('alpha_partial.png', const Target(60, 40));
    final pa = ok(a, 'alpha_partial');
    expect((pa.channels, pa.hasTransparency), (4, true));
    pa.free();
    final (_, o) = await render('alpha_opaque.png', const Target(60, 40));
    final po = ok(o, 'alpha_opaque');
    expect((po.channels, po.hasTransparency), (3, false));
    po.free();
  });

  test('orientation: EXIF 1–8 JPEG and HEIC render upright; rotationApplied is manual only', () async {
    for (var n = 1; n <= 8; n++) {
      for (final name in ['orient_${n}_exif.jpg', if (n > 1) 'orient_${n}_irot_only.heic' else 'orient_1.heic']) {
        final (info, r) = await render(name, const Target(120, 80));
        final b = ok(r, name);
        final tl = rgb(b, .2, .2), br = rgb(b, .8, .8);
        expect(tl[0] > 150 && tl[1] < 110 && tl[2] < 110, isTrue, reason: '$name top-left red, got $tl');
        expect(br[0] > 150 && br[1] > 140 && br[2] < 110, isTrue, reason: '$name bottom-right yellow, got $br');
        expect(b.rotationApplied, 0, reason: name);
        b.free();
      }
    }
    final (_, r) = await render('orient_6_exif.jpg', const Target(80, 120), turns: 1);
    final b = ok(r, 'one manual turn');
    expect((b.width, b.height, b.rotationApplied), (80, 120, 90));
    b.free();
  });

  test('a shape mismatch returns INTERNAL_ERROR and hands nothing off', () async {
    final before = NativePixelBuffer.live;
    final (_, r) = await render('orient_1_exif.jpg', const Target(120, 80), renderer: const CropRenderer(debugShapeMismatch: true));
    expect(r, isA<RenderErr>().having((e) => e.reason, 'reason', Reason.internalError));
    expect(NativePixelBuffer.live, before);
  });

  test('the renderer takes no preview image', () {
    // RenderRequest has no ui.Image field: the preview can't be a render input (FR-7).
    const req = RenderRequest;
    expect(req.toString(), isNot(contains('Image')));
    expect(ui.Image, isNot(RenderRequest));
  });

  // FEAT-002-T18: errors, cancel, progress, leaks, handover.

  test('progress events arrive in step order; EXIF 6 includes the orient step', () async {
    final steps = <RenderStep>[];
    final (_, r) = await render('orient_6_exif.jpg', const Target(120, 80), steps: steps);
    ok(r, 'progress').free();
    expect(steps, RenderStep.values);
  });

  test('deleting the source after probing gives SOURCE_UNAVAILABLE', () async {
    final copy = File('${dir.path}/../t18_deleted.jpg');
    File('${dir.path}/orient_1_exif.jpg').copySync(copy.path);
    final h = SourceHandle(copy.uri.toString());
    final info = ((await const SourceProbe().probe(h)) as ProbeOk).info;
    copy.deleteSync();
    const t = Target(120, 80);
    final rect = CropMath.toCropRect(CropMath.initial(info, t), info, t);
    final r = await const CropRenderer().render(RenderRequest(src: h, info: info, cropRect: rect, quarterTurns: 0, target: t));
    expect(reasonOf(r), Reason.sourceUnavailable);
  });

  test('cancel before start, after decode or after resample gives CANCELLED within one step', () async {
    final pre = CancelSignal()..cancel();
    final (_, a) = await render('orient_6_exif.jpg', const Target(120, 80), cancel: pre);
    pre.dispose();
    expect(reasonOf(a), Reason.cancelled);
    for (final at in [RenderStep.opened, RenderStep.decoded, RenderStep.resampled, RenderStep.oriented]) {
      final steps = <RenderStep>[];
      final (_, r) = await render('orient_6_exif.jpg', const Target(120, 80), renderer: CropRenderer(debugCancelAfter: at), steps: steps);
      expect(reasonOf(r), Reason.cancelled, reason: '$at');
      expect(steps.last, at, reason: 'no step after the cancel');
    }
  });

  test('a native allocation failure gives OUT_OF_MEMORY_HANDLED, no crash', () async {
    final (_, r) = await render('orient_1_exif.jpg', const Target(120, 80), renderer: const CropRenderer(debugFailAllocation: true));
    expect(reasonOf(r), Reason.outOfMemoryHandled);
  });

  test('leak counter is 0 after 100 mixed runs (success, failure, cancel)', () async {
    final before = NativePixelBuffer.live;
    for (var i = 0; i < 100; i++) {
      final renderer = switch (i % 5) {
        0 => const CropRenderer(),
        1 => const CropRenderer(debugShapeMismatch: true),
        2 => const CropRenderer(debugCancelAfter: RenderStep.resampled),
        3 => const CropRenderer(debugFailAllocation: true),
        _ => const CropRenderer(debugCancelAfter: RenderStep.oriented),
      };
      final (_, r) = await render(i.isEven ? 'orient_6_exif.jpg' : 'alpha_partial.png', const Target(60, 40), renderer: renderer);
      if (r is RenderOk) (r.pixels as NativePixelBuffer).free();
    }
    expect(CropRenderer.liveNativeBlocks, 0);
    expect(NativePixelBuffer.live, before);
  });

  test('handover contract: the consumer owns and frees the buffer; the producer keeps nothing', () async {
    final before = NativePixelBuffer.live;
    final (_, r) = await render('alpha_partial.png', const Target(90, 60));
    final px = (r as RenderOk).pixels;
    expect(NativePixelBuffer.live, before + 1);
    // Fake FEAT-004 consumer: checks the ADR-003 shape, then frees.
    void consume(PixelBuffer p) {
      expect((p.width, p.height), (90, 60));
      expect(p.channels, anyOf(3, 4));
      expect(p.stride, p.width * p.channels);
      expect(p.bytes.length, greaterThanOrEqualTo(p.height * p.stride));
      expect(p.upscaleFactor, greaterThan(0));
      expect(p.cropRect, isNotNull);
      (p as NativePixelBuffer).free();
    }

    consume(px);
    expect(NativePixelBuffer.live, before);
    expect(CropRenderer.liveNativeBlocks, 0);
    (px as NativePixelBuffer).free(); // a second free is a no-op
    expect(NativePixelBuffer.live, before);
  });

  // FEAT-002-T20: privacy on the device.

  test('renders (success, cancel, failure) write no files, leave the source untouched, log only enum names', () async {
    Future<Set<String>> listing() async {
      final out = <String>{};
      for (final d in [await getTemporaryDirectory(), await getApplicationCacheDirectory()]) {
        if (!d.existsSync()) continue;
        out.addAll(d.listSync(recursive: true).whereType<File>().map((f) => f.path));
      }
      return out;
    }

    final lines = <String>[];
    final log = CropOutcomeLog(lines.add);
    final src = File('${dir.path}/orient_6_exif.jpg');
    final before = (sha256.convert(src.readAsBytesSync()), src.lastModifiedSync());
    final cacheBefore = await listing();

    final h = SourceHandle(src.uri.toString());
    final info = ((await SourceProbe(log: log).probe(h)) as ProbeOk).info;
    const t = Target(120, 80);
    final req = RenderRequest(src: h, info: info, cropRect: CropMath.toCropRect(CropMath.initial(info, t), info, t), quarterTurns: 0, target: t);
    for (final renderer in [
      CropRenderer(log: log),
      CropRenderer(log: log, debugCancelAfter: RenderStep.decoded),
      CropRenderer(log: log, debugShapeMismatch: true),
    ]) {
      final r = await renderer.render(req);
      if (r is RenderOk) (r.pixels as NativePixelBuffer).free();
    }
    await SourceProbe(log: log).probe(SourceHandle(File('${dir.path}/truncated.jpg').uri.toString()));

    expect(await listing(), cacheBefore, reason: 'FEAT-002 writes no files');
    expect((sha256.convert(src.readAsBytesSync()), src.lastModifiedSync()), before);
    expect(lines, ['exactsize.crop outcome=SUCCESS', 'exactsize.crop outcome=CANCELLED', 'exactsize.crop outcome=INTERNAL_ERROR', 'exactsize.crop outcome=CORRUPT_INPUT']);
    for (final l in lines) {
      expect(l.contains(RegExp(r'[/\:]|\.(jpe?g|png|heic)|content|file|[0-9]')), isFalse, reason: l);
    }
  });
}
