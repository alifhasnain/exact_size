import 'dart:io';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_support/synthetic_images.dart';

/// FEAT-004-T25 (NFR-2, gate G3): peak memory attributable to FEAT-004 for a
/// 2 MP target is at most 150 MB on the 2 GB emulator profile. Measured in
/// the app process: VmHWM (peak resident set) after the runs minus VmRSS
/// before them, with the peak counter reset first where the kernel allows.
/// This counts the 2 MP pixel buffer as well. Search times are printed for
/// information only (NFR-1 is not a gate).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  int statusKb(String key) {
    final line = File('/proc/self/status').readAsLinesSync().firstWhere((l) => l.startsWith('$key:'));
    return int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
  }

  test('2 MP target: peak memory <= 150 MB', () async {
    const w = 1600, h = 1250;
    final pixels = syntheticPhoto(w, h, seed: 7);
    final targets = <(int?, int, OutputFormat)>[
      (200, 500, OutputFormat.jpeg), // main path
      (null, 150, OutputFormat.jpeg), // low max
      (1200, 1500, OutputFormat.jpeg), // floor path, may pad
      (null, 10240, OutputFormat.png), // lossless 2 MP PNG
    ];

    var resetOk = true;
    try {
      File('/proc/self/clear_refs').writeAsStringSync('5'); // resets VmHWM
    } on FileSystemException {
      resetOk = false; // then the peak may include earlier start-up memory: stricter
    }
    final before = statusKb('VmRSS');
    final times = <String>[];
    for (final (minKb, maxKb, format) in targets) {
      final px = NativePixelBuffer.allocate(width: w, height: h, channels: 3, hasTransparency: false);
      px.bytes.setAll(0, pixels);
      final sw = Stopwatch()..start();
      final plan = await const CompressionRunner()
          .run(CompressionRequest(pixels: px, minKb: minKb, maxKb: maxKb, format: format));
      times.add('${format.name} ${minKb ?? '-'}-$maxKb KB: ${sw.elapsedMilliseconds} ms '
          '${plan is ReadyToWrite ? 'export' : (plan as PlanFailed).failure.reason.code}');
    }
    final peak = statusKb('VmHWM');
    final attributableMb = (peak - before) / 1024;
    // ignore: avoid_print
    print('MEMORY 2MP before=${before ~/ 1024} MB peak=${peak ~/ 1024} MB '
        'attributable=${attributableMb.toStringAsFixed(1)} MB hwmReset=$resetOk | ${times.join(' | ')}');
    expect(attributableMb, lessThanOrEqualTo(150));
    expect(NativePixelBuffer.live, 0);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
