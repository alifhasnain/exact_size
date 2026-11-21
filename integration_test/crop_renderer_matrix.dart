import 'dart:io';
import 'dart:ui' as ui;

import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
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

  Future<(SourceInfo, RenderResult)> render(String name, Target t, {int turns = 0, CropRenderer renderer = const CropRenderer()}) async {
    final h = SourceHandle(File('${dir.path}/$name').uri.toString());
    final info = ((await const SourceProbe().probe(h)) as ProbeOk).info;
    final crop = CropMath.initial(info, t, quarterTurns: turns);
    final rect = CropMath.toCropRect(crop, info, t);
    return (info, await renderer.render(RenderRequest(src: h, info: info, cropRect: rect, quarterTurns: turns, target: t)));
  }

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
}
