import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart' as crop show Reason;
import 'package:exact_size/features/crop/presentation/recents_guard.dart';
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:exact_size/features/export/presentation/export_panel.dart';
import 'package:exact_size/features/export/presentation/result_screen.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../test_support/fake_check_overrides.dart';
import '../../../test_support/fake_export_bridge.dart';
import '../../../test_support/fake_output_measurer.dart';

class _Compression extends CompressionController {
  _Compression(this.initial);
  final CompressionRunState initial;
  var cancels = 0;

  @override
  CompressionRunState build() => initial;

  @override
  Future<void> cancel() async {
    cancels++;
    if (state case CompressionDone(result: final CompressionSuccess s)) {
      final f = File(s.tempFilePath);
      if (f.existsSync()) f.deleteSync();
    }
    state = const CompressionIdle();
  }
}

final class _Recents implements RecentsBinding {
  final calls = <bool>[];
  @override
  int get sdkInt => 36;
  @override
  void setRecentsScreenshotEnabled(bool enabled) => calls.add(enabled);
}

/// FEAT-006-T12: the result screen's success branch (tech 4.4), with the fake measurer and
/// decoder (NFR-6). Synthetic content only; the temp file name is a placeholder.
void main() {
  const spec = TargetSpec(width: 300, height: 300, maxKb: 50, format: OutputFormat.jpeg);
  late Directory tmp;
  late File temp;
  late FakeExportBridge bridge;
  late _Compression compression;
  late FakeOutputMeasurer measurer;
  late FakePreviewDecoder decoder;
  late _Recents recents;
  late ui.Image image;
  late List<String> logs;
  var startOvers = 0;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('result_check_test');
    temp = File('${tmp.path}/[PLACEHOLDER].jpg')..writeAsBytesSync(List.filled(48200, 1));
    bridge = FakeExportBridge();
    recents = _Recents();
    logs = [];
    startOvers = 0;
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  CompressionSuccess success() => CompressionSuccess(tempFilePath: temp.path, sizeBytes: 48200, format: OutputFormat.jpeg);

  String strip(String s) => s.replaceAll(RegExp('[\u2066-\u2069]'), '');
  Finder textContaining(String part) => find.byWidgetPredicate((w) => w is Text && strip(w.data ?? '').contains(part));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// The crop step stand-in ("crop", inside its own recents guard) pushes the result screen.
  Future<void> pump(
    WidgetTester tester, {
    MeasureResult measured = const Measured(fakeMeasured),
    PreviewResult? preview,
    Completer<MeasureResult>? measureGate,
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool push = true,
  }) async {
    if (push) {
      compression = _Compression(CompressionDone(success(), maxKb: 50));
      image = (await tester.runAsync(() => createTestImage(width: 30, height: 30)))!;
      measurer = FakeOutputMeasurer(measured)..gate = measureGate;
      decoder = FakePreviewDecoder(preview ?? PreviewOk(image, 1));
    }
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...fakeCheckOverrides(measurer: measurer, decoder: decoder, log: logs.add),
        compressionControllerProvider.overrideWith(() => compression),
        exportBridgeProvider.overrideWithValue(bridge),
        shareCopiesProvider.overrideWithValue(ShareCopies(TempFiles(tmp, folder: 'exactsize_share'))),
        exportLogProvider.overrideWithValue(ExportOutcomeLog((_) {})),
      ],
      child: ExactSizeApp(
        locale: locale,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: RecentsGuard(
              binding: recents,
              child: Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ResultScreen(
                              spec: spec,
                              recentsBinding: recents,
                              onStartOver: () {
                                startOvers++;
                                Navigator.of(context).popUntil((r) => r.isFirst);
                              },
                            ))),
                    child: const Text('crop'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    if (push) {
      await tester.tap(find.text('crop'));
      await settle(tester);
    }
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.runAsync(() async {
      await tester.tap(find.text(text));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('no verdict before the measurement completes (AC-1.4, FR-1)', (tester) async {
    final gate = Completer<MeasureResult>();
    await pump(tester, measureGate: gate);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Matches your target'), findsNothing);
    expect(find.byType(ExportPanel), findsNothing);
    gate.complete(const Measured(fakeMeasured));
    await settle(tester);
    expect(find.text('Matches your target'), findsOneWidget);
    expect(find.byType(ExportPanel), findsOneWidget);
  });

  testWidgets('matches: preview, headline, rows, caveat, panel, Done in that order (FR-7)', (tester) async {
    await pump(tester);
    double y(Finder f) => tester.getTopLeft(f).dy;
    final order = [
      find.byType(RawImage),
      find.text('Matches your target'),
      find.text('Size in pixels'),
      find.text('Format'),
      textContaining('We check pixels'),
      find.text('Save'),
      find.text('Done'),
    ].map(y).toList();
    for (var i = 1; i < order.length; i++) {
      expect(order[i], greaterThan(order[i - 1]), reason: 'item $i');
    }
    expect(find.byType(Image), findsNothing);
    expect(logs, ['exactsize.preview outcome=SPEC_MEETS']);
  });

  testWidgets('mismatch: message, rows, no panel, file gone, Back to the crop step (AC-3.1, AC-3.3, AC-3.5)', (tester) async {
    await pump(tester, measured: const Measured(MeasuredOutput(bytes: 50001, width: 300, height: 300, format: OutputFormat.jpeg, hasAlpha: false)));
    expect(textContaining("This file doesn't match your target"), findsOneWidget);
    expect(find.text("Doesn't meet"), findsOneWidget);
    expect(textContaining('Also fits'), findsNothing);
    expect(find.byType(ExportPanel), findsNothing);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Share'), findsNothing);
    expect(find.byType(RawImage), findsNothing);
    expect(temp.existsSync(), isFalse);
    // Only one action: Back. No export-anyway.
    expect(find.descendant(of: find.byType(SingleChildScrollView), matching: find.bySubtype<ButtonStyleButton>()) /* the body; the app bar has Back */, findsOneWidget);

    await tapText(tester, 'Back');
    expect(find.text('crop'), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
    expect(startOvers, 0, reason: 'photo and spec kept: no start over');
    expect(recents.calls, [false], reason: 'the crop step stays protected (nested guard)');
  });

  for (final (name, measured, preview) in [
    ('unreadable file', const Unreadable() as MeasureResult, null),
    ('non-OOM decode error', const Measured(fakeMeasured) as MeasureResult, const PreviewErr(crop.Reason.corruptInput) as PreviewResult),
  ]) {
    testWidgets('$name: FILE_MISSING text, no check, one key leaves once with no dialog (AC-3.4)', (tester) async {
      await pump(tester, measured: measured, preview: preview);
      expect(textContaining('The new file is no longer available.'), findsOneWidget);
      expect(find.text('Size in pixels'), findsNothing);
      expect(find.byType(ExportPanel), findsNothing);
      expect(find.descendant(of: find.byType(SingleChildScrollView), matching: find.bySubtype<ButtonStyleButton>()) /* the body; the app bar has Back */, findsOneWidget);

      await tapText(tester, 'Choose another photo');
      expect(find.text('Leave without saving?'), findsNothing);
      expect((compression.cancels, startOvers), (1, 1));
      expect(find.text('crop'), findsOneWidget);
    });
  }

  testWidgets('out of memory: placeholder, rows and panel (AC-4.4)', (tester) async {
    await pump(tester, preview: const PreviewErr(crop.Reason.outOfMemoryHandled));
    expect(find.text("Preview isn't available. The check below is still correct."), findsOneWidget);
    expect(find.text('Meets'), findsNWidgets(3));
    expect(find.byType(ExportPanel), findsOneWidget);
    expect(logs, ['exactsize.preview outcome=SPEC_MEETS', 'exactsize.preview outcome=PREVIEW_UNAVAILABLE']);
  });

  testWidgets('back while checking asks first; Leave leaves once and deletes the file (OQ-T7)', (tester) async {
    await pump(tester, measureGate: Completer<MeasureResult>());
    await back(tester);
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tapText(tester, 'Leave');
    expect((compression.cancels, startOvers), (1, 1));
    expect(temp.existsSync(), isFalse);
    expect(find.text('crop'), findsOneWidget);
  });

  testWidgets('back on a match with nothing saved asks first (FR-21)', (tester) async {
    await pump(tester);
    await back(tester);
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tapText(tester, 'Stay');
    expect(find.byType(ResultScreen), findsOneWidget);
    expect((compression.cancels, startOvers), (0, 0));
  });

  testWidgets('Done tapped twice after a save leaves once (AC-7.2)', (tester) async {
    await pump(tester);
    await tapText(tester, 'Save');
    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Done'));
      await tester.tap(find.text('Done'), warnIfMissed: false);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect((compression.cancels, startOvers), (1, 1));
  });

  testWidgets('size, locale and text scale changes keep the state; measure runs once (AC-7.4)', (tester) async {
    await pump(tester);
    tester.view.physicalSize = const Size(2400, 1080); // landscape
    addTearDown(tester.view.reset);
    await settle(tester);
    await pump(tester, locale: const Locale('es'), push: false);
    await settle(tester);
    await pump(tester, textScale: 2, push: false);
    await settle(tester);
    expect(find.text('Matches your target'), findsOneWidget);
    expect(measurer.calls, hasLength(1));
    expect(decoder.calls, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('after leaving, the preview is disposed and nothing is cached; a new run starts clean (AC-6.2)', (tester) async {
    imageCache.clear();
    await pump(tester);
    await tapText(tester, 'Save');
    await tester.ensureVisible(find.text('Done'));
    await tapText(tester, 'Done');
    expect(find.text('crop'), findsOneWidget);
    expect(image.debugDisposed, isTrue);
    expect(imageCache.currentSize, 0);

    final first = image;
    await pump(tester, measureGate: Completer<MeasureResult>());
    expect(find.text('Matches your target'), findsNothing, reason: 'nothing from the first run');
    expect(identical(first, image), isFalse);
  });
}
