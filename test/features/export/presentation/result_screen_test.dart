import 'dart:async';
import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:exact_size/features/export/presentation/export_panel.dart';
import 'package:exact_size/features/export/presentation/result_screen.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../test_support/fake_check_overrides.dart';
import '../../../../test_support/fake_export_bridge.dart';

/// A compression controller in a fixed state; cancel() records and deletes the temp file.
class _Compression extends CompressionController {
  _Compression(this.initial);
  final CompressionRunState initial;
  var cancels = 0;

  @override
  CompressionRunState build() => initial;

  @override
  Future<void> cancel() async {
    cancels++;
    final s = state;
    if (s is CompressionDone && s.result is CompressionSuccess) {
      final f = File((s.result as CompressionSuccess).tempFilePath);
      if (f.existsSync()) f.deleteSync();
    }
    state = const CompressionIdle();
  }
}

/// FEAT-007-T19: the temporary result screen and its leave handling.
void main() {
  late Directory tmp;
  late File temp;
  late FakeExportBridge bridge;
  late _Compression compression;
  var startOvers = 0;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('result_screen_test');
    temp = File('${tmp.path}/0123456789abcdef.jpg')..writeAsBytesSync(List.filled(48200, 1));
    bridge = FakeExportBridge();
    startOvers = 0;
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  CompressionRunState success() =>
      CompressionDone(CompressionSuccess(tempFilePath: temp.path, sizeBytes: 48200, format: OutputFormat.jpeg), maxKb: 50);

  /// Pushes the result screen above a home page, as the crop step does.
  Future<void> pump(WidgetTester tester, CompressionRunState state) async {
    compression = _Compression(state);
    final image = await tester.runAsync(() => createTestImage(width: 30, height: 30));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...fakeCheckOverrides(image: image),
        compressionControllerProvider.overrideWith(() => compression),
        exportBridgeProvider.overrideWithValue(bridge),
        shareCopiesProvider.overrideWithValue(ShareCopies(TempFiles(tmp, folder: 'exactsize_share'))),
        exportLogProvider.overrideWithValue(ExportOutcomeLog((_) {})),
      ],
      child: ExactSizeApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ResultScreen(
                          spec: const TargetSpec(width: 300, height: 300, maxKb: 50, format: OutputFormat.jpeg),
                          onStartOver: () {
                            startOvers++;
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                        ))),
                child: const Text('home'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// FEAT-006: the check above the panel makes the page taller than the test view, so
  /// Save and Done are scrolled into view before a tap (no assertion changes).
  Finder visible(WidgetTester tester, String text) {
    final f = find.text(text);
    tester.ensureVisible(f);
    return f;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('no Save or Share while running or after a failure (FR-1)', (tester) async {
    await pump(tester, const CompressionRunning(pass: 1, maxPasses: 8, maxKb: 50));
    expect(find.byType(ExportPanel), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(compression.cancels, 1, reason: 'Cancel stops the run and goes back');
    expect(find.byType(ResultScreen), findsNothing);
  });

  testWidgets('a failure shows its message and Back, no Save or Share (FR-1)', (tester) async {
    await pump(tester, const CompressionDone(CompressionFailure(reason: Reason.noFit, closestBytes: 60000), maxKb: 50));
    expect(find.byType(ExportPanel), findsNothing);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('Back with nothing saved asks; Stay keeps the screen; Leave leaves once (FR-22, FR-23)', (tester) async {
    await pump(tester, success());
    await back(tester);
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect((compression.cancels, startOvers), (0, 0));

    await tester.tap(visible(tester, 'Done'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Leave'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect((compression.cancels, startOvers), (1, 1));
    expect(temp.existsSync(), isFalse);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Back after a save leaves without a dialog', (tester) async {
    await pump(tester, success());
    await tester.runAsync(() async {
      await tester.tap(visible(tester, 'Save'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.binding.handlePopRoute();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsNothing);
    expect((compression.cancels, startOvers), (1, 1));
  });

  testWidgets('leave during a slow save waits for it, then the temp file is gone (FR-24)', (tester) async {
    await pump(tester, success());
    bridge.gate = Completer<void>();
    await tester.tap(visible(tester, 'Save'));
    await tester.pump();
    await tester.tap(visible(tester, 'Done'));
    await tester.pump(); // a save is running and nothing is saved yet: the dialog asks
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Leave'));
    await tester.pump(const Duration(milliseconds: 300));
    expect((compression.cancels, startOvers), (0, 0), reason: 'waits for the write');
    bridge.gate!.complete();
    await tester.pumpAndSettle();
    expect((compression.cancels, startOvers), (1, 1));
    expect(temp.existsSync(), isFalse);
    expect(bridge.count('save'), 1);
  });
}
