import 'dart:io';

import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-002-T15: PreviewDecoder on the pushed fixtures (push driver; large
/// 12/50 MP files when LARGE_DIR is set). Run through crop_data_matrix.dart.
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

  Future<(SourceInfo?, PreviewResult?)> preview(String name, {bool forceOom = false}) async {
    final h = SourceHandle(File('${dir.path}/$name').uri.toString());
    final p = await const SourceProbe().probe(h);
    if (p is! ProbeOk) return (null, null);
    return (p.info, await PreviewDecoder(debugForceOutOfMemory: forceOom).decode(h, p.info));
  }

  testWidgets('previews: long side ≤ 2048, first frame of animated files, unsupported variants refused', (_) async {
    final names = dir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => !n.startsWith('.')).toList()
      ..sort();
    var large = 0;
    for (final n in names) {
      final (info, r) = await preview(n);
      if (info == null) continue; // refused by the probe (damaged, too large)
      final desc = switch (r!) {
        PreviewOk(:final image, :final sampleSize) => '${image.width}x${image.height} s=$sampleSize',
        PreviewErr(:final reason) => reason.code,
      };
      // ignore: avoid_print
      print('PREVIEW $n ${info.rawWidth}x${info.rawHeight} $desc');
      if (n == 'depth10.heic') {
        expect(r, isA<PreviewErr>().having((e) => e.reason, 'reason', Reason.unsupportedInput), reason: n);
        continue;
      }
      if (n.startsWith('large_') && n.contains('.heic') && !n.contains('tiled') && !n.contains('12mp')) {
        continue; // single-frame HEIC ≥ 50 MP: platform decoder limit (T04 row 4)
      }
      expect(r, isA<PreviewOk>(), reason: '$n $desc');
      final ok = r as PreviewOk;
      expect(ok.image.width <= maxSide && ok.image.height <= maxSide, isTrue, reason: n);
      expect(ok.sampleSize, previewSampleSize(info.rawWidth, info.rawHeight), reason: n);
      if (n.startsWith('animated.')) {
        expect(info.isAnimated, isTrue, reason: n);
        expect((ok.image.width, ok.image.height), (info.rawWidth, info.rawHeight), reason: 'first frame, full size');
      }
      if (n.startsWith('large_')) large++;
      ok.image.dispose();
    }
    // ignore: avoid_print
    print('PREVIEW large files checked: $large');
  });

  testWidgets('a forced out-of-memory gives OUT_OF_MEMORY_HANDLED', (_) async {
    final (_, r) = await preview('orient_1_exif.jpg', forceOom: true);
    expect(r, isA<PreviewErr>().having((e) => e.reason, 'reason', Reason.outOfMemoryHandled));
  });
}
