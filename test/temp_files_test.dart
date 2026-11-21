import 'dart:io';
import 'dart:typed_data';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/compression_service.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/compression_runner_cases.dart';

/// FEAT-004-T17: temp output, WRITE_FAILED, start-up sweep (FR-20, AC-6.3).
void main() {
  late Directory cache;
  late TempFiles files;
  late CompressionService service;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('exactsize_test_cache');
    files = TempFiles(cache);
    service = CompressionService(const CompressionRunner(), files);
  });
  tearDown(() => cache.delete(recursive: true));

  List<FileSystemEntity> outputs() => files.dir.existsSync() ? files.dir.listSync() : [];

  test('success leaves exactly one file with a random name, inside the app cache', () async {
    final r = await service.compress(CompressionRequest(
        pixels: syntheticBuffer(320, 240), maxKb: 30, format: OutputFormat.jpeg)) as CompressionSuccess;
    expect(outputs(), hasLength(1));
    final name = r.tempFilePath.split(Platform.pathSeparator).last;
    expect(name, matches(RegExp(r'^[0-9a-f]{32}\.jpg$')), reason: 'random, no user data');
    expect(File(r.tempFilePath).absolute.path, startsWith(cache.absolute.path));
    expect(File(r.tempFilePath).lengthSync(), r.sizeBytes);
    expect(NativePixelBuffer.live, 0);
  });

  test('failure and cancel leave the folder empty', () async {
    final failed = await service.compress(CompressionRequest(
        pixels: syntheticBuffer(64, 48), minKb: 100, maxKb: 200, format: OutputFormat.png));
    expect((failed as CompressionFailure).reason, Reason.pngBelowMin);
    final cancel = CancelSignal()..cancel();
    final cancelled = await service.compress(
        CompressionRequest(pixels: syntheticBuffer(64, 48), maxKb: 20, format: OutputFormat.jpeg),
        cancel: cancel);
    cancel.dispose();
    expect((cancelled as CompressionFailure).reason, Reason.cancelled);
    expect(outputs(), isEmpty);
  });

  test('a write error returns WRITE_FAILED and leaves no file', () async {
    // The output folder's path is taken by a plain file, so nothing can be written there.
    File(files.dir.path).writeAsStringSync('[PLACEHOLDER]');
    final r = await service.compress(CompressionRequest(
        pixels: syntheticBuffer(320, 240), maxKb: 30, format: OutputFormat.jpeg));
    expect((r as CompressionFailure).reason, Reason.writeFailed);
    expect(r.closestBytes, isNotNull);
    expect(cache.listSync().whereType<File>().map((f) => f.path), [files.dir.path],
        reason: 'only the blocking file, no output');
  });

  test('the start-up sweep deletes planted leftovers', () async {
    files.dir.createSync(recursive: true);
    for (final n in ['a.jpg', 'b.png', 'c.tmp']) {
      File('${files.dir.path}${Platform.pathSeparator}$n').writeAsBytesSync(Uint8List(10));
    }
    expect(await files.sweep(), 3);
    expect(outputs(), isEmpty);
    expect(await TempFiles(cache).sweep(), 0, reason: 'nothing left to sweep');
  });

  test('FEAT-001-T04: sweep(keep:) spares one file; camera and output folders stay apart', () async {
    final camera = TempFiles(cache, folder: 'camera');
    expect(camera.dir.path, isNot(files.dir.path));
    for (final f in [camera, files]) {
      f.dir.createSync(recursive: true);
      for (final n in ['keep.jpg', 'x.jpg', 'y.jpg']) {
        File('${f.dir.path}${Platform.pathSeparator}$n').writeAsBytesSync(Uint8List(4));
      }
    }
    expect(await camera.sweep(keep: 'keep.jpg'), 2);
    expect(camera.dir.listSync().map((e) => e.uri.pathSegments.last), ['keep.jpg']);
    expect(files.dir.listSync(), hasLength(3), reason: 'the camera sweep never touches the output folder');
    expect(await camera.sweep(), 1);
    expect(camera.dir.listSync(), isEmpty);
    expect(await files.sweep(), 3);
  });
}
