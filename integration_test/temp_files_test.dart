import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:io';
import 'dart:typed_data';

/// FEAT-004-T17 on a device: the output folder is in the app's private cache.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('app cache output folder: write, then sweep', () async {
    final files = await TempFiles.appCache();
    expect(files.dir.path, contains('com.exactsize.exact_size'), reason: 'app-private storage');
    expect(files.dir.path, contains('cache'));
    final path = await files.write(Uint8List(100), OutputFormat.png);
    expect(path, startsWith(files.dir.path));
    expect(await files.sweep(), greaterThanOrEqualTo(1));
    expect(files.dir.listSync(), isEmpty);
  });

  test('FEAT-001-T04: camera folder is app-private and separate', () async {
    final camera = await TempFiles.appCache(folder: 'camera');
    final out = await TempFiles.appCache();
    expect(camera.dir.path, contains('com.exactsize.exact_size'));
    expect(camera.dir.path, endsWith('camera'));
    final a = await camera.write(Uint8List(10), OutputFormat.jpeg), b = await camera.write(Uint8List(10), OutputFormat.jpeg);
    final o = await out.write(Uint8List(10), OutputFormat.png);
    expect(await camera.sweep(keep: a.split('/').last), 1);
    expect(File(a).existsSync() && !File(b).existsSync() && File(o).existsSync(), isTrue);
    await camera.sweep();
    await out.sweep();
  });
}
