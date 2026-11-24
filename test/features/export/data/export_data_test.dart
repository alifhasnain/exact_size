import 'dart:async';
import 'dart:io';

import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/export/data/android_export_bridge.dart';
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-007-T10: channel mapping, share copies, log format.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('exactsize/export');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const secret = '[PLACEHOLDER] secret text';

  /// Answers every call with [answer] (a value, or a function of the call).
  void reply(Object? Function(MethodCall c) answer) =>
      messenger.setMockMethodCallHandler(channel, (c) async => answer(c));
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<BridgeSave> save() => AndroidExportBridge().save(src: '/c/a.jpg', name: 'exactsize-1x1-aaaaaa.jpg', mime: 'image/jpeg', bytes: 3);

  group('AndroidExportBridge', () {
    test('every tech 4.1 save outcome maps', () async {
      final cases = <Object?, Object>{
        {'outcome': 'saved', 'name': 'exactsize-1x1-aaaaaa (1).jpg', 'ref': 'content://m/1'}: isA<BridgeSaved>()
            .having((s) => s.name, 'name', 'exactsize-1x1-aaaaaa (1).jpg')
            .having((s) => s.ref, 'ref', 'content://m/1'),
        {'outcome': 'nameTaken'}: isA<BridgeNameTaken>(),
        {'outcome': 'permissionDenied'}: _err(ExportOutcome.permissionDenied),
        {'outcome': 'noSpace'}: _err(ExportOutcome.noSpace),
        {'outcome': 'failed'}: _err(ExportOutcome.saveFailed),
        {'outcome': 'fileMissing'}: _err(ExportOutcome.fileMissing),
        {'outcome': 'cancelled'}: _err(ExportOutcome.saveCancelled),
      };
      for (final e in cases.entries) {
        reply((_) => e.key);
        expect(await save(), e.value, reason: '${e.key}');
      }
    });

    test('save sends the arguments as given', () async {
      MethodCall? seen;
      reply((c) {
        seen = c;
        return {'outcome': 'failed'};
      });
      await AndroidExportBridge().saveAs(src: '/c/a.jpg', name: 'n.jpg', mime: 'image/png', bytes: 7);
      expect(seen!.method, 'saveAs');
      expect(seen!.arguments, {'src': '/c/a.jpg', 'name': 'n.jpg', 'mime': 'image/png', 'bytes': 7});
    });

    test('garbage, missing keys, null and platform errors are failures, and the message is never printed', () async {
      final printed = <String>[];
      final old = debugPrint;
      debugPrint = (m, {wrapWidth}) => printed.add('$m');
      try {
        for (final raw in <Object?>[{'outcome': 'garbage'}, {'outcome': 'saved'}, {'outcome': 'saved', 'name': '', 'ref': 'x'}, null, 'x', 42]) {
          reply((_) => raw);
          expect(await save(), _err(ExportOutcome.saveFailed), reason: '$raw');
        }
        messenger.setMockMethodCallHandler(channel, (_) async => throw PlatformException(code: 'internalError', message: secret));
        expect(await save(), _err(ExportOutcome.saveFailed));
        expect(await AndroidExportBridge().itemExists('content://m/1'), isFalse);
        expect(await AndroidExportBridge().open('content://m/1', 'image/jpeg'), isFalse);
        expect(await AndroidExportBridge().share('/c/s.jpg', 'image/jpeg'), isFalse);
        await AndroidExportBridge().sweepIncomplete();
        messenger.setMockMethodCallHandler(channel, null); // MissingPluginException
        expect(await save(), _err(ExportOutcome.saveFailed));
      } finally {
        debugPrint = old;
      }
      expect(printed.where((l) => l.contains('PLACEHOLDER')), isEmpty);
    });

    test('itemExists, open and share map their answers', () async {
      final b = AndroidExportBridge();
      reply((c) => switch (c.method) { 'itemExists' => true, 'open' => 'opened', 'share' => 'opened', _ => null });
      expect((await b.itemExists('r'), await b.open('r', 'image/jpeg'), await b.share('p', 'image/jpeg')), (true, true, true));
      reply((c) => switch (c.method) { 'itemExists' => 'yes', 'open' => 'noViewer', 'share' => 'failed', _ => null });
      expect((await b.itemExists('r'), await b.open('r', 'image/jpeg'), await b.share('p', 'image/jpeg')), (false, false, false));
    });
  });

  group('ShareCopies', () {
    late Directory tmp;
    late ShareCopies copies;
    late File src;
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('share_copies_test');
      copies = ShareCopies(TempFiles(tmp, folder: 'exactsize_share'));
      src = File('${tmp.path}/src.bin')..writeAsBytesSync(List.generate(5000, (i) => i % 251));
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('copies under the given name with equal length', () async {
      final path = await copies.copy(src.path, 'exactsize-10x10-abcdef.jpg', 5000);
      expect(path, endsWith('exactsize_share${Platform.pathSeparator}exactsize-10x10-abcdef.jpg'));
      expect(File(path!).readAsBytesSync(), src.readAsBytesSync());
    });

    test('refuses a length mismatch or a missing source and leaves no copy', () async {
      expect(await copies.copy(src.path, 'exactsize-10x10-abcdef.jpg', 4999), isNull);
      expect(await copies.copy('${src.path}.missing', 'exactsize-10x10-abcdeg.jpg', 5000), isNull);
      final dir = Directory('${tmp.path}/exactsize_share');
      expect(dir.existsSync() ? dir.listSync() : const [], isEmpty);
    });

    test('deletes and sweeps', () async {
      final a = (await copies.copy(src.path, 'exactsize-10x10-aaaaaa.jpg', 5000))!;
      await copies.copy(src.path, 'exactsize-10x10-bbbbbb.jpg', 5000);
      await copies.delete(a);
      expect(File(a).existsSync(), isFalse);
      expect(await copies.sweep(), 1);
      expect(Directory('${tmp.path}/exactsize_share').listSync(), isEmpty);
    });
  });

  test('ExportOutcomeLog writes only the outcome code', () {
    final lines = <String>[];
    final log = ExportOutcomeLog(lines.add);
    ExportOutcome.values.forEach(log.outcome);
    expect(lines, hasLength(ExportOutcome.values.length));
    for (final l in lines) {
      expect(RegExp(r'^exactsize\.export outcome=[A-Z_]+$').hasMatch(l), isTrue, reason: l);
    }
  });

  test('unawaited sweeps cannot throw into the zone', () async {
    reply((_) => throw PlatformException(code: 'internalError'));
    await expectLater(AndroidExportBridge().sweepIncomplete(), completes);
    unawaited(Future<void>.value());
  });
}

Matcher _err(ExportOutcome o) => isA<BridgeSaveError>().having((e) => e.outcome, 'outcome', o);
