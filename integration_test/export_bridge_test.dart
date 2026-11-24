import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test_support/synthetic_images.dart';

/// FEAT-007 bridge checks on a device through the real channel, synthetic bytes
/// only (T06; completed with a host driver in T11). testWidgets only: plain
/// test() failures are not reported under flutter drive.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('exactsize/export');
  final folder = Directory('/storage/emulated/0/Pictures/ExactSize');

  Future<T?> run<T>(WidgetTester t, Future<T> Function() f) => t.runAsync<T>(f);
  Future<Map<Object?, Object?>> save(WidgetTester t, Map<String, Object> args) async =>
      (await run(t, () => ch.invokeMapMethod<Object?, Object?>('save', args)))!;
  Set<String> own() => folder.existsSync() ? folder.listSync().map((e) => e.uri.pathSegments.last).toSet() : <String>{};

  Future<File> source(WidgetTester t) async => (await run(t, () async {
        final dir = Directory('${(await getTemporaryDirectory()).path}/export_bridge_test')..createSync(recursive: true);
        final jpg = img.encodeJpg(img.Image.fromBytes(width: 700, height: 700, bytes: syntheticPhoto(700, 700, noise: 90).buffer, numChannels: 3),
            quality: 95);
        return File('${dir.path}/src.jpg')..writeAsBytesSync(jpg);
      }))!;

  testWidgets('API 29+ save: bytes equal, one new visible file, nothing pending (AC-1.2, AC-1.4)', (t) async {
    if (!Platform.isAndroid || int.parse((await run(t, () => Process.run('getprop', ['ro.build.version.sdk'])))!.stdout.toString().trim()) < 29) {
      return; // API 28 path: T07
    }
    final src = await source(t);
    final bytes = src.lengthSync();
    expect(bytes, greaterThan(300 * 1024));
    final before = own();
    final name = 'exactsize-700x700-t06${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}';
    final r = await save(t, {'src': src.path, 'name': '$name.jpg', 'mime': 'image/jpeg', 'bytes': bytes});
    final created = own().difference(before);
    try {
      expect(r['outcome'], 'saved');
      expect(r['name'], '$name.jpg');
      expect((r['ref'] as String).startsWith('content://'), isTrue);
      expect(created, {'$name.jpg'}, reason: 'exactly one new file, no .pending-* entry');
      final saved = File('${folder.path}/$name.jpg').readAsBytesSync();
      expect(saved.length, bytes);
      expect(sha256.convert(saved), sha256.convert(src.readAsBytesSync()));
      expect(await run(t, () => ch.invokeMethod<bool>('itemExists', {'ref': r['ref']})), isTrue);
    } finally {
      for (final n in created) {
        File('${folder.path}/$n').deleteSync();
      }
    }
    expect(own().difference(before), isEmpty);
  });

  testWidgets('API 29+ save refuses a length mismatch or a missing source and leaves nothing (FR-2, FR-3)', (t) async {
    final src = await source(t);
    final before = own();
    final n = src.lengthSync();
    for (final args in [
      {'src': src.path, 'name': 'exactsize-1x1-t06bad.jpg', 'mime': 'image/jpeg', 'bytes': n + 1},
      {'src': '${src.path}.missing', 'name': 'exactsize-1x1-t06mis.jpg', 'mime': 'image/jpeg', 'bytes': n},
      {'src': src.path, 'name': 'exactsize-1x1-t06zer.jpg', 'mime': 'image/jpeg', 'bytes': 0},
    ]) {
      expect((await save(t, args))['outcome'], 'fileMissing', reason: '${args['bytes']}');
    }
    expect(own().difference(before), isEmpty);
  });

  testWidgets('sweep removes a planted unfinished save and keeps a completed file (FR-16)', (t) async {
    final sdk = int.parse((await run(t, () => Process.run('getprop', ['ro.build.version.sdk'])))!.stdout.toString().trim());
    if (sdk < 30) return; // API 28 in CI through the T11 driver (needs pm grant); no API 29 device
    final src = await source(t);
    final before = own();
    final name = 'exactsize-700x700-t09${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}.jpg';
    final r = await save(t, {'src': src.path, 'name': name, 'mime': 'image/jpeg', 'bytes': src.lengthSync()});
    expect(r['outcome'], 'saved');
    final hash = sha256.convert(File('${folder.path}/$name').readAsBytesSync());
    try {
      await run(t, () => ch.invokeMethod<void>('debugPlantIncomplete'));
      await run(t, () => ch.invokeMethod<void>('debugPlantIncomplete'));
      expect(await run(t, () => ch.invokeMethod<int>('debugCountIncomplete')), 2);
      await run(t, () => ch.invokeMethod<void>('sweepIncomplete'));
      expect(await run(t, () => ch.invokeMethod<int>('debugCountIncomplete')), 0);
      expect(sha256.convert(File('${folder.path}/$name').readAsBytesSync()), hash);
    } finally {
      for (final n in own().difference(before)) {
        File('${folder.path}/$n').deleteSync();
      }
    }
  });

  // Manual (FEAT-007-T08): needs a person, or adb taps, on the system save dialog.
  if (const bool.fromEnvironment('SAVE_AS')) {
    testWidgets('save-as: saved with equal length, then cancelled (manual)', (t) async {
      final src = await source(t);
      // ignore: avoid_print
      print('T08 source bytes=${src.lengthSync()}');
      for (final step in ['save', 'cancel']) {
        final r = (await run(t, () => ch.invokeMapMethod<Object?, Object?>('saveAs',
            {'src': src.path, 'name': '${'exactsize-700x700-t08$step'.substring(0, 24)}.jpg', 'mime': 'image/jpeg', 'bytes': src.lengthSync()})))!;
        // ignore: avoid_print
        print('T08 $step outcome=${r['outcome']} nameIsFr4=${r['name'] == null ? null : RegExp(r'^exactsize-700x700-t08[a-z]{3}\.jpg$').hasMatch(r['name'] as String)}');
        expect(r['outcome'], step == 'save' ? 'saved' : 'cancelled');
      }
    }, timeout: const Timeout(Duration(minutes: 4)));
  }
}
