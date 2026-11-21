import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/crop/data/crop_renderer.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_reducers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/orientation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-002-T21, gate G4 (FR-3, FR-12, FR-13, FR-21, NFR-3, NFR-10):
/// orientation of preview and render against the fixture's known upright
/// pattern (red top-left, green top-right, blue bottom-left, yellow
/// bottom-right; ImageDecoder is not a reliable oracle on API 28, FEAT-002-TECH
/// v1.1 R4), same-device determinism, re-crop and four-rotation identity.
/// Run through crop_data_matrix.dart.
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

  String colour(int r, int g, int b) {
    if (r > 180 && g < 110 && b < 110) return 'red';
    if (g > 140 && r < 110 && b < 130) return 'green';
    if (b > 170 && r < 110) return 'blue';
    if (r > 190 && g > 170 && b < 110) return 'yellow';
    return 'other($r,$g,$b)';
  }

  const upright = ['red', 'green', 'blue', 'yellow'];
  const points = [(.2, .2), (.8, .2), (.2, .8), (.8, .8)];

  Future<(SourceHandle, SourceInfo)> probe(String name) async {
    final h = SourceHandle(File('${dir.path}/$name').uri.toString());
    return (h, ((await const SourceProbe().probe(h)) as ProbeOk).info);
  }

  Future<NativePixelBuffer> render(SourceHandle h, SourceInfo info, CropState s, Target t) async {
    final r = await const CropRenderer().render(
        RenderRequest(src: h, info: info, cropRect: CropMath.toCropRect(s, info, t), quarterTurns: s.quarterTurns, target: t));
    expect(r, isA<RenderOk>(), reason: r is RenderErr ? r.reason.code : '');
    return (r as RenderOk).pixels as NativePixelBuffer;
  }

  List<String> renderColours(NativePixelBuffer b) => [
        for (final (fx, fy) in points)
          () {
            final o = ((b.height * fy).floor() * b.width + (b.width * fx).floor()) * b.channels;
            return colour(b.bytes[o], b.bytes[o + 1], b.bytes[o + 2]);
          }(),
      ];

  final fixtures = [
    for (var n = 1; n <= 8; n++) ...[
      'orient_${n}_exif.jpg',
      if (n == 1) 'orient_1.heic' else ...['orient_${n}_exif_only.heic', 'orient_${n}_irot_only.heic'],
    ],
  ];

  test('all orientations (JPEG, HEIC by EXIF and by irot/imir) are upright and not mirrored in preview and render', () async {
    expect(fixtures, hasLength(23));
    for (final name in fixtures) {
      final (h, info) = await probe(name);
      const t = Target(120, 80);
      final b = await render(h, info, CropMath.initial(info, t), t);
      expect(renderColours(b), upright, reason: '$name render');
      b.free();

      // Preview: raw-orientation image; the screen paints it through the same
      // D4 transform, so it is sampled through the inverse mapping.
      final p = await const PreviewDecoder().decode(h, info) as PreviewOk;
      final bytes = (await p.image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final o = Orientation.fromExif(info.exifOrientation);
      final (ow, oh) = o.orientedSize(p.image.width, p.image.height);
      final got = [
        for (final (fx, fy) in points)
          () {
            final (rx, ry) = o.inverse.mapPoint(ow * fx, oh * fy, ow, oh);
            final i = (ry.floor() * p.image.width + rx.floor()) * 4;
            return colour(bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2));
          }(),
      ];
      expect(got, upright, reason: '$name preview');
      p.image.dispose();
    }
  });

  test('same device, same OS build: two renders are byte-identical', () async {
    for (final name in ['orient_6_exif.jpg', 'orient_7_irot_only.heic', 'alpha_partial.png', 'chart_zone_plate.png']) {
      final (h, info) = await probe(name);
      const t = Target(97, 61);
      final s = CropMath.initial(info, t);
      final a = await render(h, info, s, t), b = await render(h, info, s, t);
      expect(sha256.convert(a.bytes), sha256.convert(b.bytes), reason: name);
      a.free();
      b.free();
    }
  });

  test('re-crops and mixed gestures ending in the same cropRect equal a fresh render', () async {
    final (h, info) = await probe('chart_diagonal.png');
    const t = Target(150, 100);
    final fresh = CropMath.initial(info, t);
    var s = fresh;
    for (var i = 0; i < 20; i++) {
      s = CropReducers.drag(s, 37.0 * (i.isEven ? 1 : -1), 11, info, t);
      s = CropReducers.pinch(s, i.isEven ? 1.3 : 1 / 1.3, 200, 150, info, t);
      s = CropReducers.handle(s, Corner.values[i % 4], 9, -7, info, t);
    }
    // A re-crop: zoom in, move, then back to the same zoom and centre.
    s = CropReducers.centre(CropReducers.zoom(CropReducers.zoom(s, zoomIn: true, info: info, t: t), zoomIn: false, info: info, t: t), info, t);
    s = CropReducers.reset(info, t);
    expect(CropMath.toCropRect(s, info, t), CropMath.toCropRect(fresh, info, t));
    final a = await render(h, info, s, t), b = await render(h, info, fresh, t);
    expect(sha256.convert(a.bytes), sha256.convert(b.bytes));
    a.free();
    b.free();
  });

  test('four rotations equal no rotation; one turn equals the unrotated render turned 90°', () async {
    final (h, info) = await probe('orient_1_exif.jpg'); // 120×80
    const t = Target(120, 80);
    var s = CropMath.initial(info, t);
    for (var i = 0; i < 4; i++) {
      s = CropReducers.rotate(s, clockwise: true, info: info, t: t);
    }
    final a = await render(h, info, s, t), b = await render(h, info, CropMath.initial(info, t), t);
    expect(sha256.convert(a.bytes), sha256.convert(b.bytes));
    a.free();

    // Full crop at 1:1, so the resample is the identity and only the turn differs.
    const t90 = Target(80, 120);
    final turned = await render(h, info, CropMath.initial(info, t90, quarterTurns: 1), t90);
    expect(turned.rotationApplied, 90);
    expect(renderColours(turned), ['blue', 'red', 'yellow', 'green'], reason: 'turned clockwise');
    var same = true;
    for (var y = 0; y < 120 && same; y++) {
      for (var x = 0; x < 80 && same; x++) {
        // Turned (x, y) comes from unrotated (y, 79 - x).
        final ti = (y * 80 + x) * turned.channels, ui0 = ((79 - x) * 120 + y) * b.channels;
        for (var c = 0; c < 3; c++) {
          if (turned.bytes[ti + c] != b.bytes[ui0 + c]) same = false;
        }
      }
    }
    expect(same, isTrue, reason: 'pixel-identical to the unrotated render turned 90° clockwise');
    turned.free();
    b.free();
  });
}
