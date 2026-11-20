import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/compression_runner_cases.dart';

/// FEAT-004-T16: the UI isolate keeps rendering while a compression runs on the
/// worker isolate. Frame timings are informational (Product Owner 2026-11-20).
/// Not named *_test.dart; run in profile mode:
///   flutter drive --profile --driver=test_driver/integration_test.dart \
///     --target=integration_test/runner_jank.dart -d DEVICE_ID
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('frames during a 2 MP search', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator()))));
    await binding.watchPerformance(() async {
      final run = const CompressionRunner().run(CompressionRequest(
          pixels: syntheticBuffer(1600, 1250), minKb: 100, maxKb: 120, format: OutputFormat.jpeg));
      var done = false;
      run.whenComplete(() => done = true);
      while (!done) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 16)));
      }
      expect(await run, isNotNull);
    }, reportKey: 'runner_frames');
  });
}
