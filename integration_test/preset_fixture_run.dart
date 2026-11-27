import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/crop/data/crop_renderer.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/presets/data/preset_asset_source.dart';
import 'package:exact_size/features/presets/domain/parse_library.dart';
import 'package:exact_size/features/presets/domain/preset_types.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'preset_fixture_data.dart';

/// FEAT-011-T08 (FR-20, NFR-1, NFR-9): every preset spec runs through the real engine on
/// generated synthetic images (no binary committed, OQ-T2): probe, default crop at W x H, then
/// compression to the KB range and format, the same calls as crop_to_compression.dart.
/// A size, KB or cannot-reach outcome fails unless the spec has an engineReview reason.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Map<SpecKind, SourceHandle> sources;

  Future<File> writePng(String name, int w, int h, void Function(Canvas c, Random r) paint) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), Random(7));
    final image = await recorder.endRecording().toImage(w, h);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return File('${dir.path}/$name')..writeAsBytesSync(png!.buffer.asUint8List());
  }

  setUpAll(() async {
    dir = Directory('${(await getApplicationSupportDirectory()).path}/preset_fixture')..createSync(recursive: true);
    // Photo-like: a gradient under many small coloured dots, so JPEG has texture to keep.
    final photo = await writePng('photo.png', 1200, 1380, (c, r) {
      c.drawRect(
        const Rect.fromLTWH(0, 0, 1200, 1380),
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, const Offset(1200, 1380), const [
            Color(0xFF7A90A8),
            Color(0xFFE2C9A6),
          ]),
      );
      for (var i = 0; i < 6000; i++) {
        c.drawCircle(
          Offset(r.nextDouble() * 1200, r.nextDouble() * 1380),
          2 + r.nextDouble() * 10,
          Paint()..color = Color.fromARGB(128, r.nextInt(256), r.nextInt(256), r.nextInt(256)),
        );
      }
    });
    // Signature-like: dark strokes on white.
    final signature = await writePng('signature.png', 900, 400, (c, r) {
      c.drawRect(const Rect.fromLTWH(0, 0, 900, 400), Paint()..color = const Color(0xFFFFFFFF));
      final path = Path()..moveTo(60, 250);
      for (var x = 60.0; x < 840; x += 30) {
        path.quadraticBezierTo(x + 15, 80 + r.nextDouble() * 240, x + 30, 150 + r.nextDouble() * 150);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = const Color(0xFF101830),
      );
    });
    sources = {
      SpecKind.photo: SourceHandle(photo.uri.toString()),
      SpecKind.signature: SourceHandle(signature.uri.toString()),
    };
  });

  tearDownAll(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// One line per spec that failed and has no engineReview; empty means the library passes.
  Future<List<String>> run(PresetLibrary library) async {
    final problems = <String>[];
    for (final form in library.forms) {
      for (final spec in form.specs) {
        final at = '${form.id} ${spec.kind.name}';
        final src = sources[spec.kind]!;
        final t = Target(spec.width, spec.height);
        final info = (await const SourceProbe().probe(src) as ProbeOk).info;
        final r = await const CropRenderer().render(
          RenderRequest(
            src: src,
            info: info,
            cropRect: CropMath.toCropRect(CropMath.initial(info, t), info, t),
            quarterTurns: 0,
            target: t,
          ),
        );
        final String outcome;
        switch (r) {
          case RenderErr(:final reason):
            outcome = reason.code;
          case RenderOk(:final pixels):
            final size = (pixels.width, pixels.height);
            final result = await const CompressionRunner().run(
              CompressionRequest(pixels: pixels, minKb: spec.minKb, maxKb: spec.maxKb, format: spec.format),
            );
            final window = ByteWindow.fromKb(minKb: spec.minKb, maxKb: spec.maxKb);
            outcome = switch (result) {
              ReadyToWrite(:final bytes) when size == (spec.width, spec.height) && window.contains(bytes.length) =>
                'READY',
              ReadyToWrite() => 'SIZE_OR_KB_MISMATCH',
              PlanFailed(:final failure) => failure.reason.code,
            };
        }
        // ignore: avoid_print
        print('FR-20 $at -> $outcome');
        if (outcome != 'READY' && (spec.engineReview?.trim() ?? '').isEmpty) problems.add('$at: $outcome');
      }
    }
    return problems;
  }

  testWidgets('the shipped library loads and every spec reaches its target (FR-20, NFR-1)', (_) async {
    final sw = Stopwatch()..start();
    final library = await const PresetAssetSource().loadPresets();
    // ignore: avoid_print
    print('FR-20 shipped library: ${library.forms.length} forms, loaded in ${sw.elapsedMilliseconds} ms');
    expect(library.skipped, 0);
    expect(await run(library), isEmpty);
  });

  testWidgets('the synthetic fixture library reaches every target', (_) async {
    final library = parseLibrary(presetFixtureLibrary);
    expect(library.forms, hasLength(2));
    expect(await run(library), isEmpty);
  });

  testWidgets('a planted unreachable spec is reported, and passes once it has an engineReview', (_) async {
    Map<String, Object?> planted(String? review) => {
      'schema': 1,
      'forms': [
        {
          'id': 'test-unreachable',
          'name': 'Test Unreachable',
          'specs': [
            {
              'kind': 'photo',
              'width': 4000,
              'height': 4000,
              'minKb': null,
              'maxKb': 2,
              'format': 'jpeg',
              'engineReview': ?review,
            },
          ],
        },
      ],
    };
    final reported = await run(parseLibrary(planted(null)));
    expect(reported, hasLength(1));
    expect(reported.single, startsWith('test-unreachable photo: '));
    expect(await run(parseLibrary(planted('Synthetic test: a reason the Product Owner accepts.'))), isEmpty);
  });
}
