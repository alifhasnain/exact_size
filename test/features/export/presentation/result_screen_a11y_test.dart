import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart' show Target;
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:exact_size/features/export/presentation/result_screen.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:exact_size/ui/booth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../test_support/fake_export_bridge.dart';
import '../../../../test_support/tolerant_golden_comparator.dart';

class _Done extends CompressionController {
  _Done(this.result);
  final CompressionSuccess result;
  @override
  CompressionRunState build() => CompressionDone(result, maxKb: 50);
  @override
  Future<void> cancel() async {}
}

/// FEAT-007-T20: accessibility, 200% font, RTL and goldens of the result screen (G1 design).
void main() {
  late Directory tmp;
  late CompressionSuccess success;
  late FakeExportBridge bridge;
  const name = 'exactsize-300x300-a1b2c3.jpg';

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('result_a11y_test');
    final temp = File('${tmp.path}/0123456789abcdef.jpg')..writeAsBytesSync(List.filled(48200, 1));
    success = CompressionSuccess(tempFilePath: temp.path, sizeBytes: 48200, format: OutputFormat.jpeg);
    bridge = FakeExportBridge();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en'), double textScale = 1}) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        compressionControllerProvider.overrideWith(() => _Done(success)),
        exportBridgeProvider.overrideWithValue(bridge),
        shareCopiesProvider.overrideWithValue(ShareCopies(TempFiles(tmp, folder: 'exactsize_share'))),
        exportLogProvider.overrideWithValue(ExportOutcomeLog((_) {})),
      ],
      child: ExactSizeApp(
        locale: locale,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: ResultScreen(size: const Target(300, 300), onStartOver: () {}),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Taps the amber Save key (any language) and waits for the result.
  Future<void> save(WidgetTester tester) async {
    final key = find.byType(FilledButton).first;
    await tester.ensureVisible(key);
    await tester.pumpAndSettle();
    await tester.tap(key);
    await tester.pumpAndSettle();
  }

  Finder notice() => find.byType(BoothNotice);
  String noticeText(WidgetTester tester) => tester.widget<BoothNotice>(notice()).text;

  testWidgets('AC-9.1: Arabic mirrors; the saved name and folder are each one LTR isolate', (tester) async {
    bridge.saves.add(const BridgeSaved(name: name, ref: 'content://m/1'));
    await pump(tester, locale: const Locale('ar'));
    expect(Directionality.of(tester.element(find.byType(ResultScreen))), TextDirection.rtl);
    await save(tester);
    final text = noticeText(tester);
    expect('\u2066$name\u2069'.allMatches(text), hasLength(1));
    expect('\u2066${'Pictures/ExactSize'}\u2069'.allMatches(text), hasLength(1));
    expect(RegExp('[٠-٩]').hasMatch(text), isFalse, reason: 'Western digits 0-9');
  });

  testWidgets('AC-9.2: one live region holds the save result; status has text; tap targets meet the guideline', (tester) async {
    await pump(tester);
    await save(tester);
    final live = find.ancestor(of: notice(), matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.liveRegion ?? false)));
    expect(live, findsOneWidget);
    expect(noticeText(tester), isNotEmpty);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    for (final b in find.bySubtype<ButtonStyleButton>().evaluate()) {
      expect(tester.getSize(find.byWidget(b.widget)).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('a new result replaces the message rather than adding a second one (one announcement per result)', (tester) async {
    await pump(tester);
    await save(tester);
    await save(tester); // already saved
    expect(notice(), findsOneWidget);
  });

  for (final locale in ['en', 'ar', 'hi']) {
    testWidgets('$locale at 200% on 360x640: no overflow, message wraps, keys stay reachable', (tester) async {
      bridge.failNext(ExportOutcome.permissionDenied);
      await pump(tester, locale: Locale(locale), textScale: 2);
      await save(tester);
      expect(tester.takeException(), isNull);
      expect(notice(), findsOneWidget);
      final saveAs = find.byIcon(Icons.folder_open);
      await tester.ensureVisible(saveAs);
      expect(tester.getSize(find.ancestor(of: saveAs, matching: find.bySubtype<ButtonStyleButton>())).height, greaterThanOrEqualTo(48));
    });
  }

  // FEAT-007-T21: every locale shows its own texts, never the English fallback.
  final en = lookupAppLocalizations(const Locale('en'));
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('$locale: result screen and panel render in that language (T21)', (tester) async {
      final l = lookupAppLocalizations(locale);
      await pump(tester, locale: locale);
      for (final text in [l.exportSave, l.exportShare, l.exportDone, l.exportPrivacy, l.exportShareHint]) {
        if (locale.languageCode != 'en') expect(text, isNot(anyOf(en.exportSave, en.exportShare, en.exportDone, en.exportPrivacy, en.exportShareHint)));
        await tester.scrollUntilVisible(find.text(text), 50, scrollable: find.byType(Scrollable).first);
        expect(find.text(text), findsOneWidget, reason: '$locale: $text');
      }
      expect(tester.takeException(), isNull);
    });
  }

  group('goldens (G1 design, 360x640)', () {
    // Text-heavy screens: Windows-made goldens differ on Linux CI by 1.5–1.8% from text
    // anti-aliasing alone (run 45638925079); a moved or missing control changes far more.
    setUpAll(() => useTolerantGoldens(tolerance: 0.025));

    for (final locale in ['en', 'ar']) {
      testWidgets('$locale ready', (tester) async {
        await pump(tester, locale: Locale(locale));
        await expectLater(find.byType(ResultScreen), matchesGoldenFile('goldens/result_${locale}_ready.png'));
      });
      testWidgets('$locale saved', (tester) async {
        bridge.saves.add(const BridgeSaved(name: name, ref: 'content://m/1'));
        await pump(tester, locale: Locale(locale));
        await save(tester);
        await tester.scrollUntilVisible(notice(), 50, scrollable: find.byType(Scrollable).first);
        await expectLater(find.byType(ResultScreen), matchesGoldenFile('goldens/result_${locale}_saved.png'));
      });
      testWidgets('$locale error', (tester) async {
        bridge.failNext(ExportOutcome.saveFailed);
        await pump(tester, locale: Locale(locale));
        await save(tester);
        await tester.scrollUntilVisible(notice(), 50, scrollable: find.byType(Scrollable).first);
        await expectLater(find.byType(ResultScreen), matchesGoldenFile('goldens/result_${locale}_error.png'));
      });
    }
    testWidgets('en 200%', (tester) async {
      bridge.saves.add(const BridgeSaved(name: name, ref: 'content://m/1'));
      await pump(tester, textScale: 2);
      await save(tester);
      await expectLater(find.byType(ResultScreen), matchesGoldenFile('goldens/result_en_font200.png'));
    });
  });
}
