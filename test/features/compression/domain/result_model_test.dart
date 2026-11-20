import 'dart:io';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/subsampling.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_encoder.dart';

/// FEAT-004-T08: result model, reason codes, pure domain layer, fake encoder.
void main() {
  test('Success carries size, quality, format, subsampling, Huffman, padding, notices', () {
    const s = CompressionSuccess(
      tempFilePath: '[PLACEHOLDER]',
      sizeBytes: 20480,
      format: OutputFormat.jpeg,
      quality: 82,
      subsampling: Subsampling.yuv444,
      optimisedHuffman: true,
      paddingBytes: 512,
      notices: {Notice.paddingAdded},
    );
    expect(
      (s.sizeBytes, s.quality, s.format, s.subsampling, s.optimisedHuffman, s.paddingBytes),
      (20480, 82, OutputFormat.jpeg, Subsampling.yuv444, true, 512),
    );
    expect(s.notices, {Notice.paddingAdded});
  });

  test('Failure has no file path field', () {
    const f = CompressionFailure(
        reason: Reason.belowMin, closestBytes: 9000, direction: Direction.tooSmall);
    expect((f.reason, f.closestBytes, f.direction, f.jpegWouldFit), (Reason.belowMin, 9000, Direction.tooSmall, false));
    final src = File('lib/features/compression/domain/compression_result.dart').readAsStringSync();
    final failureClass = src.substring(src.indexOf('final class CompressionFailure'));
    expect(failureClass.toLowerCase(), isNot(contains('path;')),
        reason: 'a failure must never point at a file (FR-6, FR-11)');
  });

  test('Reason codes match FEAT-004 PRD section 5 exactly', () {
    final prd = File('docs/features/FEAT-004-kb-range-compression/prd.md').readAsLinesSync();
    final line = prd.firstWhere((l) => l.startsWith('**Error flows:**'));
    final prdCodes = RegExp(r'`([A-Z_]+)`').allMatches(line).map((m) => m[1]).toList();
    expect(Reason.values.map((r) => r.code).toList(), prdCodes);
  });

  test('domain layer has no Flutter or Riverpod imports', () {
    final files = Directory('lib/features/compression/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final f in files) {
      for (final line in f.readAsLinesSync().where((l) => l.startsWith('import '))) {
        expect(line, isNot(matches(RegExp(r"package:(flutter|flutter_riverpod|riverpod|material_ui|cupertino_ui)/"))),
            reason: f.path);
      }
    }
  });

  test('fake encoder follows the scripted curve and records calls', () {
    final enc = FakeEncoder(jpegSize: linearCurve(atQ1: 1000, atQ100: 100000), pngSize: 777);
    final a = enc.encodeJpeg(quality: 100, subsampling: Subsampling.yuv420, optimiseHuffman: true);
    final b = enc.encodeJpeg(quality: 100, subsampling: Subsampling.yuv444, optimiseHuffman: false);
    expect((a.length, b.length, enc.encodePng().length), (100000, 147000, 777));
    expect(enc.calls, hasLength(2));
    expect(enc.pngCalls, 1);
  });
}
