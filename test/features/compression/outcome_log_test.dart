import 'dart:io';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/compression_service.dart';
import 'package:exact_size/features/compression/data/memory_preflight.dart';
import 'package:exact_size/features/compression/data/outcome_log.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_support/compression_runner_cases.dart';

/// FEAT-004-T21 / NFR-7: a full logged run writes only enum names.
void main() {
  test('success, failure and cancel log only enum names', () async {
    final cache = Directory.systemTemp.createTempSync('exactsize_t21_');
    addTearDown(() => cache.deleteSync(recursive: true));
    final lines = <String>[];
    final service = CompressionService(
        CompressionRunner(preflight: MemoryPreflight(readMeminfo: () async => null)), TempFiles(cache), OutcomeLog(lines.add));

    final ok = await service.compress(
        CompressionRequest(pixels: syntheticBuffer(200, 150, channels: 4), maxKb: 50, format: OutputFormat.jpeg, dpi: 300));
    final failed = await service.compress(
        CompressionRequest(pixels: syntheticBuffer(64, 48), minKb: 100, maxKb: 200, format: OutputFormat.png));
    final cancel = CancelSignal()..cancel();
    final cancelled = await service.compress(
        CompressionRequest(pixels: syntheticBuffer(64, 48), maxKb: 20, format: OutputFormat.jpeg),
        cancel: cancel);
    cancel.dispose();

    expect(ok, isA<CompressionSuccess>());
    expect((failed as CompressionFailure).reason, Reason.pngBelowMin);
    expect((cancelled as CompressionFailure).reason, Reason.cancelled);
    expect(lines, [
      'exactsize.compression outcome=SUCCESS format=jpeg notices=transparencyFlattened',
      'exactsize.compression outcome=PNG_BELOW_MIN',
      'exactsize.compression outcome=CANCELLED',
    ]);
    final path = (ok as CompressionSuccess).tempFilePath;
    for (final line in lines) {
      expect(line, isNot(matches(RegExp(r'[/\\]|\.(jpe?g|png)\b|[0-9]'))), reason: line);
      expect(line, isNot(contains(path.split(Platform.pathSeparator).last)));
    }
  });
}
