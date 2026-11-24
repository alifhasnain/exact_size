import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// FEAT-002-T04 driver: copies decoder fixtures into the app's private files
/// folder (`files/fixtures/`) with `adb` + `run-as` (debug and profile builds
/// are debuggable), then hands over to the normal integration driver. The test
/// waits for the `.ready` marker written last.
///
/// ```
/// DEVICE=[id] LARGE_DIR=[dir with large_* files, optional] \
///   flutter drive --driver test_driver/push_fixtures_driver.dart \
///     --target integration_test/decode_matrix.dart -d [id]
/// ```
const _package = 'com.exactsize.exact_size';
const _tmp = '/data/local/tmp/exactsize_fixtures';

Future<void> main() async {
  final device = Platform.environment['DEVICE'];
  Future<void> adb(List<String> args) async {
    final r = await Process.run('adb', [if (device != null) ...['-s', device], ...args]);
    if (r.exitCode != 0) throw StateError('adb ${args.join(' ')}: ${r.stderr}');
  }

  final dirs = [
    'test_support/crop_fixtures',
    ?Platform.environment['LARGE_DIR'],
  ];
  await adb(['shell', 'rm -rf $_tmp && mkdir -p $_tmp']);
  for (final dir in dirs) {
    for (final f in Directory(dir).listSync().whereType<File>()) {
      if (f.path.endsWith('.md')) continue;
      await adb(['push', f.path, '$_tmp/']);
    }
  }
  await adb(['shell', 'chmod 644 $_tmp/*']);
  await adb([
    'shell',
    "run-as $_package sh -c 'rm -rf files/fixtures && mkdir -p files/fixtures && cp $_tmp/* files/fixtures/ && touch files/fixtures/.ready'",
  ]);
  await adb(['shell', 'rm -rf $_tmp']);
  await integrationDriver(responseDataCallback: _saveScreenshots);
}

/// Writes screenshots taken with `binding.takeScreenshot` to
/// `build/<target>/<name>.png` (FEAT-005-T17), then the usual response file.
/// Synthetic content only; never committed.
Future<void> _saveScreenshots(Map<String, dynamic>? data) async {
  final shots = (data?['screenshots'] as List<dynamic>?) ?? const [];
  for (final s in shots.cast<Map<String, dynamic>>()) {
    final f = File('build/screenshots/${s['screenshotName']}.png')..createSync(recursive: true);
    f.writeAsBytesSync((s['bytes'] as List<dynamic>).cast<int>());
  }
  await writeResponseData(data?..remove('screenshots'));
}
