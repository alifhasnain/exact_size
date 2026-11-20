import 'package:es_codec/es_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';

import '../test_support/synthetic_image.dart';

/// FEAT-004-T04 speed spike: per-pass encode time of libjpeg-turbo (ADR-002
/// Option C) vs the pure-Dart `image` package (Option B) on the 2 MP synthetic
/// image. Informational only on the emulator (Product Owner, 2026-11-20).
/// Not named *_test.dart, so CI's debug-mode `flutter test integration_test` skips it.
///
/// Run in profile mode (debug-mode JIT timings mean nothing):
///   flutter drive --profile --driver=test_driver/integration_test.dart \
///     --target=integration_test/encoder_benchmark.dart -d DEVICE_ID
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('encoder per-pass timing, 2 MP', () {
    const w = 1600, h = 1250, warmUp = 2, runs = 20;
    final rgba = syntheticRgba(w, h);
    final image = img.Image.fromBytes(
      width: w,
      height: h,
      bytes: rgba.buffer,
      numChannels: 4,
    );

    // Config A: 4:2:0 + optimised Huffman. Config C: 4:4:4 + standard Huffman.
    // The image package has no Huffman option, so B/A uses standard Huffman.
    final cases = <String, int Function(int q)>{};
    for (final q in [40, 75, 100]) {
      cases['C/A q$q'] = (q) => encodeRgba8ToJpeg(rgba, w, h,
              quality: q, subsampling: TJSAMP.TJSAMP_420, optimizeHuffman: true)
          .length;
      cases['C/C q$q'] = (q) => encodeRgba8ToJpeg(rgba, w, h,
              quality: q, subsampling: TJSAMP.TJSAMP_444)
          .length;
      cases['B/A q$q'] = (q) =>
          img.encodeJpg(image, quality: q, chroma: img.JpegChroma.yuv420).length;
      cases['B/C q$q'] = (q) =>
          img.encodeJpg(image, quality: q, chroma: img.JpegChroma.yuv444).length;
    }

    final results = <String, Map<String, num>>{};
    for (final entry in cases.entries) {
      final q = int.parse(entry.key.split('q').last);
      for (var i = 0; i < warmUp; i++) {
        entry.value(q);
      }
      final ms = <double>[];
      var bytes = 0;
      for (var i = 0; i < runs; i++) {
        final sw = Stopwatch()..start();
        bytes = entry.value(q);
        sw.stop();
        ms.add(sw.elapsedMicroseconds / 1000);
      }
      ms.sort();
      results[entry.key] = {
        'median_ms': (ms[runs ~/ 2 - 1] + ms[runs ~/ 2]) / 2,
        'p95_ms': ms[(runs * 0.95).ceil() - 1],
        'bytes': bytes,
      };
    }
    binding.reportData = {'encoder_benchmark_2mp': results};
    expect(results, hasLength(12));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
