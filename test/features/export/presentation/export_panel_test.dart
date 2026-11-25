import 'dart:async';
import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:exact_size/features/export/presentation/export_panel.dart';
import 'package:exact_size/ui/booth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../test_support/fake_export_bridge.dart';

/// FEAT-007-T18: ExportPanel with FakeExportBridge and a real temp file.
void main() {
  late Directory tmp;
  late FakeExportBridge bridge;
  late CompressionSuccess success;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('export_panel_test');
    final temp = File('${tmp.path}/0123456789abcdef.jpg')..writeAsBytesSync(List.filled(3000, 5));
    success = CompressionSuccess(tempFilePath: temp.path, sizeBytes: 3000, format: OutputFormat.jpeg);
    bridge = FakeExportBridge();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        exportBridgeProvider.overrideWithValue(bridge),
        shareCopiesProvider.overrideWithValue(ShareCopies(TempFiles(tmp, folder: 'exactsize_share'))),
        exportLogProvider.overrideWithValue(ExportOutcomeLog((_) {})),
      ],
      child: ExactSizeApp(
        locale: const Locale('en'),
        home: Scaffold(body: SingleChildScrollView(child: ExportPanel(success: success, size: const Target(300, 300)))),
      ),
    ));
    await tester.pumpAndSettle();
  }

  String strip(String s) => s.replaceAll(RegExp('[\u2066-\u2069]'), '');
  Finder textContaining(String part) => find.byWidgetPredicate((w) => w is Text && strip(w.data ?? '').contains(part));
  Future<void> tap(WidgetTester tester, String label) async {
    await tester.runAsync(() async {
      await tester.tap(find.text(label));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('Save shows the folder and file name in one live region (FR-11, NFR-2)', (tester) async {
    await pump(tester);
    expect(find.text('Open'), findsNothing, reason: 'Open only after a save');
    await tap(tester, 'Save');
    final saved = textContaining('Saved to Pictures/ExactSize as exactsize-300x300-');
    expect(saved, findsOneWidget);
    final live = find.ancestor(of: saved, matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.liveRegion ?? false)));
    expect(live, findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('PERMISSION_DENIED shows the message with Share and "Choose where to save" enabled (FR-9, FR-10)', (tester) async {
    bridge.failNext(ExportOutcome.permissionDenied);
    await pump(tester);
    expect(find.text('Choose where to save'), findsNothing);
    await tap(tester, 'Save');
    expect(textContaining('ExactSize needs the Storage permission'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(find.ancestor(of: find.text('Choose where to save'), matching: find.bySubtype<ButtonStyleButton>())).enabled,
        isTrue);
    expect(tester.widget<ButtonStyleButton>(find.ancestor(of: find.text('Share'), matching: find.bySubtype<ButtonStyleButton>())).enabled, isTrue);
  });

  testWidgets('a successful Share shows no message; a failed one shows SHARE_FAILED (AC-3.5, FR-20)', (tester) async {
    await pump(tester);
    await tap(tester, 'Share');
    expect(find.byType(BoothNotice), findsNothing);
    expect(textContaining('Couldn'), findsNothing);
    bridge.chooser = false;
    await tap(tester, 'Share');
    expect(textContaining("Couldn't open the share menu."), findsOneWidget);
  });

  testWidgets('Save tapped twice while busy makes one call; Save is inactive and says Saving… (FR-12, FR-24)', (tester) async {
    await pump(tester);
    bridge.gate = Completer<void>();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Saving…'), findsOneWidget, reason: 'text, not colour alone');
    final save = tester.widget<ButtonStyleButton>(find.ancestor(of: find.text('Saving…'), matching: find.bySubtype<ButtonStyleButton>()));
    expect(save.enabled, isFalse);
    await tester.tap(find.text('Saving…'));
    bridge.gate!.complete();
    await tester.pumpAndSettle();
    expect(bridge.count('save'), 1);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('privacy line and chat hint are shown; no image in the panel (FR-21, FR-26)', (tester) async {
    await pump(tester);
    expect(find.text('Saving puts a copy in your gallery or a folder you pick. Sharing gives a copy to the app you choose.'), findsOneWidget);
    expect(find.text('Some chat apps shrink photos. For a form, save the file and choose it in the upload window.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(RawImage), findsNothing);
  });
}

