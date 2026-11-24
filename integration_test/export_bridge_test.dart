import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/export/data/android_export_bridge.dart';
import 'package:exact_size/features/export/domain/export_name.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:exact_size/features/pick/data/android_system_picker.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test_support/synthetic_images.dart';

/// FEAT-007-T06/T07/T09/T11: the export bridge on a device through the real
/// AndroidExportBridge, synthetic bytes only. testWidgets only (flutter drive
/// does not report plain test() failures).
///
/// With `--dart-define=EXPORT_DRIVER=true` the host driver test_driver/export_driver.dart
/// answers requests (API 28 grant, own-share intent, planting a .part). With
/// `EXPORT_MODE=revoked` (API 28, permission revoked and user-fixed by the CI script)
/// only the refusal checks run.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const driver = bool.fromEnvironment('EXPORT_DRIVER');
  const revoked = String.fromEnvironment('EXPORT_MODE') == 'revoked';
  const debugCh = MethodChannel('exactsize/export');
  final bridge = AndroidExportBridge();
  final folder = Directory('/storage/emulated/0/Pictures/ExactSize');
  final secure = Random.secure();

  Future<T?> run<T>(WidgetTester t, Future<T> Function() f) => t.runAsync<T>(f);
  Set<String> own() => folder.existsSync() ? folder.listSync().map((e) => e.uri.pathSegments.last).toSet() : <String>{};
  Future<int> sdk(WidgetTester t) async =>
      int.parse((await run(t, () => Process.run('getprop', ['ro.build.version.sdk'])))!.stdout.toString().trim());
  String name(int w, int h) => ExportName.generate(w, h, OutputFormat.jpeg, Random.secure());
  void cleanup(Set<String> before) {
    for (final n in own().difference(before)) {
      File('${folder.path}/$n').deleteSync();
    }
  }

  /// Hands [command] to the host driver without waiting.
  Future<void> request(WidgetTester t, String command) async => run(t, () async {
        final dir = (await getApplicationSupportDirectory()).path;
        final reply = File('$dir/export_reply');
        if (reply.existsSync()) reply.deleteSync();
        await File('$dir/export_request').writeAsString(command);
      });

  /// Waits for the driver's reply to the last request.
  Future<String> reply(WidgetTester t) async => (await run(t, () async {
        final f = File('${(await getApplicationSupportDirectory()).path}/export_reply');
        for (var i = 0; i < 150; i++) {
          if (f.existsSync()) return f.readAsStringSync().trim();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        throw StateError('driver did not answer');
      }))!;

  Future<String> ask(WidgetTester t, String command) async {
    await request(t, command);
    return reply(t);
  }

  Future<File> source(WidgetTester t, {int side = 700}) async => (await run(t, () async {
        final dir = Directory('${(await getTemporaryDirectory()).path}/export_bridge_test')..createSync(recursive: true);
        final jpg = img.encodeJpg(img.Image.fromBytes(width: side, height: side, bytes: syntheticPhoto(side, side, noise: 90).buffer, numChannels: 3),
            quality: 95);
        return File('${dir.path}/src$side.jpg')..writeAsBytesSync(jpg);
      }))!;

  Future<BridgeSave> save(WidgetTester t, File src, String name, {int? bytes}) async =>
      (await run(t, () => bridge.save(src: src.path, name: name, mime: 'image/jpeg', bytes: bytes ?? src.lengthSync())))!;

  if (revoked) {
    testWidgets('API 28 without the permission: denied, then "never ask again", then refused at once; the sweep keeps a .part (FR-9, AC-2.4, FR-16)', (t) async {
      final src = await source(t, side: 50);
      Future<BridgeSave?> attempt() => run(t, () => bridge.save(src: src.path, name: name(50, 50), mime: 'image/jpeg', bytes: src.lengthSync()));
      final before = own();
      for (final step in ['deny', 'denyforever']) {
        await request(t, step); // the driver answers the system dialog this save opens
        expect(await attempt(), isA<BridgeSaveError>().having((e) => e.outcome, 'outcome', ExportOutcome.permissionDenied), reason: step);
        expect(await reply(t), 'done', reason: step);
      }
      final r = await run(t, () => bridge.save(src: src.path, name: name(50, 50), mime: 'image/jpeg', bytes: src.lengthSync())
          .timeout(const Duration(seconds: 10))); // a dialog would hang the call
      expect(r, isA<BridgeSaveError>().having((e) => e.outcome, 'outcome', ExportOutcome.permissionDenied));
      expect(await ask(t, 'nodialog'), 'none');
      expect(own().difference(before), isEmpty);
      expect(await ask(t, 'plant'), 'done');
      await run(t, bridge.sweepIncomplete);
      expect(await ask(t, 'checkpart'), 'present');
    });
    return;
  }

  testWidgets('setup: API 28 storage grant through the driver', (t) async {
    if (await sdk(t) <= 28 && driver) {
      expect(await ask(t, 'grant'), 'done');
      await run(t, () => Future<void>.delayed(const Duration(seconds: 3))); // remount after a grant (T01: about 2 s)
    }
  });

  testWidgets('save: bytes equal, one new visible file, nothing partial (AC-1.2, AC-1.4); itemExists follows deletion (AC-5.3)', (t) async {
    final api = await sdk(t);
    if (api <= 28 && !driver) return;
    final src = await source(t);
    expect(src.lengthSync(), greaterThan(300 * 1024));
    final before = own();
    final n = name(700, 700);
    try {
      final r = await save(t, src, n);
      expect(r, isA<BridgeSaved>());
      r as BridgeSaved;
      expect(r.name, n);
      expect(own().difference(before), {n}, reason: 'one new file, no .part or .pending-* entry');
      final saved = File('${folder.path}/$n').readAsBytesSync();
      expect(saved.length, src.lengthSync());
      expect(sha256.convert(saved), sha256.convert(src.readAsBytesSync()));
      expect(await run(t, () => bridge.itemExists(r.ref)), isTrue);
      File('${folder.path}/$n').deleteSync();
      expect(await run(t, () => bridge.itemExists(r.ref)), isFalse);
    } finally {
      cleanup(before);
    }
  });

  testWidgets('a length mismatch or a missing source is fileMissing and leaves nothing (FR-2, FR-3)', (t) async {
    if (await sdk(t) <= 28 && !driver) return;
    final src = await source(t, side: 50);
    final before = own();
    for (final (path, bytes) in [(src.path, src.lengthSync() + 1), ('${src.path}.missing', src.lengthSync()), (src.path, 0)]) {
      final r = await run(t, () => bridge.save(src: path, name: name(50, 50), mime: 'image/jpeg', bytes: bytes));
      expect(r, isA<BridgeSaveError>().having((e) => e.outcome, 'outcome', ExportOutcome.fileMissing), reason: '$bytes');
    }
    expect(own().difference(before), isEmpty);
  });

  testWidgets('100 saves give 100 distinct files with FR-4 names (AC-6.1)', (t) async {
    if (await sdk(t) <= 28 && !driver) return;
    final src = await source(t, side: 20);
    final before = own();
    try {
      for (var i = 0; i < 100; i++) {
        final r = await save(t, src, ExportName.generate(20, 20, OutputFormat.jpeg, secure));
        expect(r, isA<BridgeSaved>(), reason: 'save $i');
      }
      final created = own().difference(before);
      expect(created, hasLength(100));
      expect(created.every(ExportName.pattern.hasMatch), isTrue);
    } finally {
      cleanup(before);
    }
  });

  testWidgets('API 28: a taken name is nameTaken and the existing file stays untouched (AC-6.3, FR-13)', (t) async {
    if (await sdk(t) > 28 || !driver) return;
    final src = await source(t, side: 20);
    final before = own();
    final n = name(20, 20);
    folder.createSync(recursive: true);
    final existing = File('${folder.path}/$n')..writeAsBytesSync(List.filled(64, 7));
    try {
      expect(await save(t, src, n), isA<BridgeNameTaken>());
      expect(existing.readAsBytesSync(), List.filled(64, 7));
      expect(own().difference(before), {n}, reason: 'no .part left');
    } finally {
      cleanup(before);
    }
  });

  testWidgets('share copies: the guard refuses other folders, the receiver reads the FR-4 name (FR-5, FR-18, H5)', (t) async {
    final out = Directory('${(await run(t, getTemporaryDirectory))!.path}/exactsize_out')..createSync(recursive: true);
    final stray = File('${out.path}/0123456789abcdef.jpg')..writeAsBytesSync([1, 2, 3]);
    expect(await run(t, () => bridge.share(stray.path, 'image/jpeg')), isFalse);
    stray.deleteSync();
    final share = Directory('${(await run(t, getTemporaryDirectory))!.path}/exactsize_share')..createSync(recursive: true);
    final n = name(300, 300);
    final copy = File('${share.path}/$n')..writeAsBytesSync([1, 2, 3]);
    expect(await run(t, () => debugCh.invokeMethod<String>('debugShareDisplayName', {'path': copy.path})), n);
    if (driver) {
      // FR-18 with FEAT-001 FR-20: our own share URI sent back to ExactSize is marked as our own.
      final picker = AndroidSystemPicker();
      expect(await ask(t, 'ownshare:$n'), 'done');
      SystemPickResult? got;
      for (var i = 0; i < 50 && got == null; i++) {
        await run(t, () => Future<void>.delayed(const Duration(milliseconds: 200)));
        got = await run<SystemPickResult?>(t, picker.takeResult);
      }
      expect(got, isA<Picked>().having((p) => p.fromOwnApp, 'fromOwnApp', isTrue));
    }
    copy.deleteSync();
  });

  testWidgets('sweep removes planted unfinished saves and keeps a completed file (FR-16)', (t) async {
    final api = await sdk(t);
    if (api == 29 || (api <= 28 && !driver)) return; // no API 29 device; API 28 needs the grant
    final src = await source(t, side: 50);
    final before = own();
    final n = name(50, 50);
    expect(await save(t, src, n), isA<BridgeSaved>());
    final hash = sha256.convert(File('${folder.path}/$n').readAsBytesSync());
    try {
      await run(t, () => debugCh.invokeMethod<void>('debugPlantIncomplete'));
      await run(t, () => debugCh.invokeMethod<void>('debugPlantIncomplete'));
      expect(await run(t, () => debugCh.invokeMethod<int>('debugCountIncomplete')), 2);
      await run(t, bridge.sweepIncomplete);
      expect(await run(t, () => debugCh.invokeMethod<int>('debugCountIncomplete')), 0);
      expect(sha256.convert(File('${folder.path}/$n').readAsBytesSync()), hash);
    } finally {
      cleanup(before);
    }
  });

  // Manual (FEAT-007-T08): needs a person, or adb taps, on the system save dialog.
  if (const bool.fromEnvironment('SAVE_AS')) {
    testWidgets('save-as: saved with equal length, then cancelled (manual)', (t) async {
      final src = await source(t);
      // ignore: avoid_print
      print('T08 source bytes=${src.lengthSync()}');
      for (final step in ['save', 'cancel']) {
        final r = (await run(t, () => bridge.saveAs(
            src: src.path, name: '${'exactsize-700x700-t08$step'.substring(0, 24)}.jpg', mime: 'image/jpeg', bytes: src.lengthSync())))!;
        // ignore: avoid_print
        print('T08 $step result=$r');
        expect(r, step == 'save' ? isA<BridgeSaved>() : isA<BridgeSaveError>().having((e) => e.outcome, 'o', ExportOutcome.saveCancelled));
      }
    }, timeout: const Timeout(Duration(minutes: 4)));
  }
}
