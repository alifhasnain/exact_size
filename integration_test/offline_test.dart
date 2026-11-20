import 'dart:io';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/compression_service.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_support/compression_runner_cases.dart';

/// FEAT-004-T25 / AC-6.2: compression completes with networking off. Runs
/// only with --dart-define=OFFLINE=true, after tool/run_offline_test.sh has
/// turned networking off; the first check proves it is off.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const offline = bool.fromEnvironment('OFFLINE');

  test('JPEG and PNG compression complete with no network', () async {
    // Test-only probe: the lookup must fail, or the device is still online.
    await expectLater(
        InternetAddress.lookup('example.com').timeout(const Duration(seconds: 10)), throwsA(anything));

    final cache = Directory.systemTemp.createTempSync('exactsize_offline_');
    final service = CompressionService(const CompressionRunner(), TempFiles(cache));
    for (final (format, maxKb) in [(OutputFormat.jpeg, 50), (OutputFormat.png, 500)]) {
      final r = await service.compress(
          CompressionRequest(pixels: syntheticBuffer(320, 240), maxKb: maxKb, format: format));
      expect(r, isA<CompressionSuccess>(), reason: format.name);
    }
    cache.deleteSync(recursive: true);
  }, skip: offline ? false : 'needs --dart-define=OFFLINE=true with networking off (tool/run_offline_test.sh)');
}
