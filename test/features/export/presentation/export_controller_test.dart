import 'dart:async';
import 'dart:io';

import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/domain/export_name.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_support/fake_export_bridge.dart';

/// Records cancel() and deletes the temp file, as FEAT-004's controller does.
class _FakeCompression extends CompressionController {
  static var cancels = 0;
  static String? temp;

  @override
  CompressionRunState build() => const CompressionIdle();

  @override
  Future<void> cancel() async {
    cancels++;
    if (temp != null && File(temp!).existsSync()) File(temp!).deleteSync();
  }
}

/// FEAT-007-T12 to T14: ExportController with FakeExportBridge and real files in a temp dir.
void main() {
  late Directory tmp;
  late File temp;
  late FakeExportBridge bridge;
  late List<String> log;
  late ExportInput input;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('export_controller_test');
    temp = File('${tmp.path}/0123456789abcdef.jpg')..writeAsBytesSync(List.generate(4000, (i) => i % 256));
    bridge = FakeExportBridge();
    log = [];
    input = ExportInput(CompressionSuccess(tempFilePath: temp.path, sizeBytes: 4000, format: OutputFormat.jpeg), const Target(300, 300));
    _FakeCompression.cancels = 0;
    _FakeCompression.temp = temp.path;
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      exportBridgeProvider.overrideWithValue(bridge),
      shareCopiesProvider.overrideWithValue(ShareCopies(TempFiles(tmp, folder: 'exactsize_share'))),
      exportLogProvider.overrideWithValue(ExportOutcomeLog(log.add)),
      compressionControllerProvider.overrideWith(_FakeCompression.new),
    ]);
    addTearDown(c.dispose);
    c.listen(exportControllerProvider(input), (_, _) {}); // keep the autoDispose provider alive
    return c;
  }

  ExportController ctl(ProviderContainer c) => c.read(exportControllerProvider(input).notifier);
  ExportState st(ProviderContainer c) => c.read(exportControllerProvider(input));
  List<String> shareFiles() {
    final d = Directory('${tmp.path}/exactsize_share');
    return d.existsSync() ? d.listSync().map((e) => e.uri.pathSegments.last).toList() : [];
  }

  group('T12 save', () {
    test('a missing file or a wrong length is FILE_MISSING with no bridge call (FR-2)', () async {
      final c = container();
      temp.writeAsBytesSync([1, 2, 3]);
      await ctl(c).save();
      expect(st(c).message, ExportOutcome.fileMissing);
      temp.deleteSync();
      await ctl(c).save();
      expect(st(c).message, ExportOutcome.fileMissing);
      expect(bridge.count('save'), 0);
      expect(log, ['exactsize.export outcome=FILE_MISSING', 'exactsize.export outcome=FILE_MISSING']);
    });

    test('success is SAVED with the read-back name and an FR-4 request name (FR-4, FR-11)', () async {
      final c = container();
      bridge.saves.add(const BridgeSaved(name: 'exactsize-300x300-aaaaaa (1).jpg', ref: 'content://m/1'));
      await ctl(c).save();
      expect(st(c).message, ExportOutcome.saved);
      expect(st(c).saved!.displayName, 'exactsize-300x300-aaaaaa (1).jpg');
      expect(st(c).busy, isFalse);
      expect(ExportName.pattern.hasMatch(bridge.calls.single.name!), isTrue);
      expect(bridge.calls.single.name, startsWith('exactsize-300x300-'));
      expect(temp.existsSync(), isTrue, reason: 'the temp file is kept');
    });

    test('nameTaken once draws a new name; five times is SAVE_FAILED (FR-13)', () async {
      var c = container();
      bridge.saves.add(const BridgeNameTaken());
      await ctl(c).save();
      expect(bridge.count('save'), 2);
      expect(bridge.calls[0].name, isNot(bridge.calls[1].name));
      expect(st(c).message, ExportOutcome.saved);

      bridge = FakeExportBridge();
      for (var i = 0; i < 5; i++) {
        bridge.saves.add(const BridgeNameTaken());
      }
      c = container();
      await ctl(c).save();
      expect(bridge.count('save'), 5);
      expect(st(c).message, ExportOutcome.saveFailed);
    });

    test('noSpace, saveFailed and permissionDenied keep the temp file and Save stays retryable (FR-9, FR-14)', () async {
      for (final o in [ExportOutcome.noSpace, ExportOutcome.saveFailed, ExportOutcome.permissionDenied]) {
        bridge = FakeExportBridge()..failNext(o);
        final c = container();
        await ctl(c).save();
        expect(st(c).message, o);
        expect(st(c).busy, isFalse);
        expect(temp.existsSync(), isTrue);
        await ctl(c).save();
        expect(st(c).message, ExportOutcome.saved, reason: 'retry after $o');
      }
    });

    test('a second Save during a slow save makes no second bridge call (AC-5.1)', () async {
      final c = container();
      bridge.gate = Completer<void>();
      final first = ctl(c).save();
      await Future<void>.delayed(Duration.zero);
      expect(st(c).busy, isTrue);
      final second = ctl(c).save();
      bridge.gate!.complete();
      await Future.wait([first, second]);
      expect(bridge.count('save'), 1);
    });

    test('repeat Save: ALREADY_SAVED while the item exists, saves again once it is gone (AC-5.2, AC-5.3)', () async {
      final c = container();
      await ctl(c).save();
      await ctl(c).save();
      expect(st(c).message, ExportOutcome.alreadySaved);
      expect(bridge.count('save'), 1);
      bridge.existing.clear();
      await ctl(c).save();
      expect(st(c).message, ExportOutcome.saved);
      expect(bridge.count('save'), 2);
    });

    testWidgets('progress shows after 500 ms of saving, not at 499 ms (FR-24, NFR-1)', (tester) async {
      final c = container();
      bridge.gate = Completer<void>();
      unawaited(ctl(c).save());
      await tester.pump(const Duration(milliseconds: 499));
      expect(st(c).showProgress, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(st(c).showProgress, isTrue);
      bridge.gate!.complete();
      await tester.pump();
      expect((st(c).busy, st(c).showProgress), (false, false));
    });

    test('a new container starts empty (FR-25)', () async {
      var c = container();
      await ctl(c).save();
      c.dispose();
      c = container();
      expect((st(c).saved, st(c).message, st(c).sharedOnce), (null, null, false));
    });
  });

  group('T13 share, save as, leave', () {
    test('two Shares make one copy and two chooser calls, no shared-storage save; no message (AC-3.5, AC-5.4)', () async {
      final c = container();
      await ctl(c).share();
      await ctl(c).share();
      expect(shareFiles(), hasLength(1));
      expect(ExportName.pattern.hasMatch(shareFiles().single), isTrue);
      expect(bridge.count('share'), 2);
      expect(bridge.count('save'), 0);
      expect(st(c).message, isNull);
      expect(st(c).sharedOnce, isTrue);
      expect(log, everyElement('exactsize.export outcome=SHARE_OPENED'));
    });

    test('a chooser that does not open is SHARE_FAILED and keeps the temp file (FR-20)', () async {
      final c = container();
      bridge.chooser = false;
      await ctl(c).share();
      expect(st(c).message, ExportOutcome.shareFailed);
      expect(st(c).sharedOnce, isFalse);
      expect(temp.existsSync(), isTrue);
    });

    test('save-as: cancel shows nothing and saves nothing; success counts as saved (FR-10, FR-23)', () async {
      final c = container();
      bridge.saveAsResults.add(const BridgeSaveError(ExportOutcome.saveCancelled));
      await ctl(c).saveAs();
      expect((st(c).message, st(c).saved), (null, null));
      expect(log.last, 'exactsize.export outcome=SAVE_CANCELLED');
      expect(ctl(c).needsLeaveConfirm, isTrue);
      await ctl(c).saveAs();
      expect(st(c).message, ExportOutcome.saved);
      expect(st(c).saved!.viaSaveAs, isTrue);
      expect(ctl(c).needsLeaveConfirm, isFalse);
    });

    test('needsLeaveConfirm only when nothing was saved or shared (FR-23)', () async {
      var c = container();
      expect(ctl(c).needsLeaveConfirm, isTrue);
      await ctl(c).share();
      expect(ctl(c).needsLeaveConfirm, isFalse);
      c.dispose();
      c = container();
      await ctl(c).save();
      expect(ctl(c).needsLeaveConfirm, isFalse);
    });

    test('leave during a slow save waits, then the share copy and the temp file are gone, cancel ran once (FR-22, FR-24)', () async {
      final c = container();
      await ctl(c).share();
      bridge.gate = Completer<void>();
      final saving = ctl(c).save();
      await Future<void>.delayed(Duration.zero);
      var left = false;
      final leaving = ctl(c).leave().then((_) => left = true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(left, isFalse, reason: 'waits for the write');
      bridge.gate!.complete();
      await Future.wait([saving, leaving]);
      expect(bridge.count('save'), 1);
      expect(shareFiles(), isEmpty);
      expect(temp.existsSync(), isFalse);
      expect(_FakeCompression.cancels, 1);
    });
  });

  group('T14 open', () {
    test('nothing saved: open does nothing', () async {
      final c = container();
      await ctl(c).open();
      expect(bridge.count('open'), 0);
      expect(st(c).message, isNull);
    });

    test('a viewer opens with no message; no viewer shows OPEN_NO_VIEWER and Save/Share still work (FR-15)', () async {
      final c = container();
      await ctl(c).save();
      await ctl(c).open();
      expect(bridge.calls.last, (method: 'open', name: null, ref: st(c).saved!.ref));
      expect(st(c).message, isNull);
      bridge.viewer = false;
      await ctl(c).open();
      expect(st(c).message, ExportOutcome.openNoViewer);
      expect(log.last, 'exactsize.export outcome=OPEN_NO_VIEWER');
      await ctl(c).save();
      expect(st(c).message, ExportOutcome.alreadySaved);
      await ctl(c).share();
      expect(bridge.count('share'), 1);
    });

    test('open after save-as uses the document ref (OQ-T3)', () async {
      final c = container();
      bridge.saveAsResults.add(const BridgeSaved(name: 'exactsize-300x300-bbbbbb.jpg', ref: 'content://doc/9'));
      await ctl(c).saveAs();
      await ctl(c).open();
      expect(bridge.calls.last.ref, 'content://doc/9');
    });
  });
}
