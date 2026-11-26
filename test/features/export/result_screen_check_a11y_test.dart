import 'dart:io';
import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart' as crop show Reason;
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:exact_size/features/export/presentation/result_screen.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/preview/presentation/check_messages.dart';
import 'package:exact_size/features/preview/presentation/spec_check_view.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../test_support/fake_check_overrides.dart';
import '../../../test_support/fake_export_bridge.dart';
import '../../../test_support/tolerant_golden_comparator.dart';

class _Done extends CompressionController {
  _Done(this.result);
  final CompressionSuccess result;
  @override
  CompressionRunState build() => CompressionDone(result, maxKb: 50);
  @override
  Future<void> cancel() async {}
}

enum _State { matches, matchesPng, unavailable, mismatch, unreadable }

/// A synthetic picture (no face, no signature): opaque bands, or a disc on transparency.
Future<ui.Image> _picture(int w, int h, {required bool alpha}) {
  final r = ui.PictureRecorder();
  final c = Canvas(r);
  final size = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  if (!alpha) {
    c.drawRect(size, Paint()..color = const Color(0xFF2F6F8F));
    c.drawRect(Rect.fromLTWH(0, h * 0.6, w.toDouble(), h * 0.4), Paint()..color = const Color(0xFFE0C9A6));
  }
  c.drawCircle(size.center, w * 0.3, Paint()..color = const Color(0xFF7A9E3B));
  return r.endRecording().toImage(w, h);
}

/// FEAT-006-T14: accessibility, 200% font, RTL and goldens of the check states (G1 design).
void main() {
  late Directory tmp;
  late FakeExportBridge bridge;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('result_check_a11y');
    bridge = FakeExportBridge();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester, _State state, {Locale locale = const Locale('en'), double textScale = 1}) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final png = state == _State.matchesPng;
    final format = png ? OutputFormat.png : OutputFormat.jpeg;
    final temp = File('${tmp.path}/[PLACEHOLDER].${png ? 'png' : 'jpg'}')..writeAsBytesSync(List.filled(48200, 1));
    final success = CompressionSuccess(
      tempFilePath: temp.path,
      sizeBytes: 48200,
      format: format,
      notices: state == _State.matches ? const {Notice.paddingAdded} : const {},
    );
    final image = await tester.runAsync(() => _picture(60, 60, alpha: png));
    final measured = MeasuredOutput(
        bytes: state == _State.mismatch ? 50001 : 48200, width: 300, height: 300, format: format, hasAlpha: png);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...fakeCheckOverrides(
          result: state == _State.unreadable ? const Unreadable() : Measured(measured),
          preview: state == _State.unavailable ? const PreviewErr(crop.Reason.outOfMemoryHandled) : PreviewOk(image!, 1),
        ),
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
            child: ResultScreen(
              spec: TargetSpec(width: 300, height: 300, minKb: 20, maxKb: 50, format: format),
              onStartOver: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  for (final s in [_State.matches, _State.mismatch, _State.unreadable]) {
    testWidgets('${s.name}: tap targets, labels and text contrast meet the guidelines (NFR-2)', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, s);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets('one live region for the verdict besides the panel; each row reads as its sentence (AC-8.2)', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, _State.matches);
    final live = find.byWidgetPredicate((w) => w is Semantics && (w.properties.liveRegion ?? false));
    final verdict = live.evaluate().where((e) => find.descendant(of: find.byWidget(e.widget), matching: find.text('Matches your target')).evaluate().isNotEmpty);
    expect(verdict, hasLength(1));
    expect(live, findsNWidgets(2), reason: 'the verdict and the panel message region');

    final l = lookupAppLocalizations(const Locale('en'));
    final rows = tester.widgetList<Semantics>(find.byWidgetPredicate((w) => w is Semantics && w.excludeSemantics)).toList();
    expect(rows, hasLength(3));
    final m = CheckMessages(l);
    expect(rows.first.properties.label, m.rowSentence(l.checkLabelPixels, m.pixels(300, 300), m.pixels(300, 300), true));
    for (final r in rows) {
      final node = tester.getSemantics(find.byWidget(r));
      expect(node.label, r.properties.label);
    }
    handle.dispose();
  });

  testWidgets('ar: RTL, mirrored rows, values in LTR isolates, digits 0-9 (AC-8.3)', (tester) async {
    await pump(tester, _State.matches, locale: const Locale('ar'));
    expect(Directionality.of(tester.element(find.byType(ResultScreen))), TextDirection.rtl);
    final l = lookupAppLocalizations(const Locale('ar'));
    // Mirrored: the row label starts at the right edge of the slip (page 24 + slip 16 padding).
    expect(tester.getRect(find.text(l.checkLabelPixels)).right, closeTo(360 - 24 - 16, 0.5));
    expect(tester.getRect(find.text(l.checkTarget).first).right, closeTo(360 - 24 - 16, 0.5));
    // The spec slip's values (prose such as the caveat may name KB as a word).
    for (final t in tester.widgetList<Text>(find.descendant(of: find.byType(SpecSlip), matching: find.byType(Text)))) {
      final data = t.data ?? '';
      expect(RegExp('[٠-٩۰-۹]').hasMatch(data), isFalse, reason: data);
      // Every digit, KB and format name sits inside an isolate. "px" is part of the translated
      // pattern (each language writes its own unit, as FEAT-007's ready line did); until T16
      // translates checkPixels, ar falls back to the English "px".
      final outside = data.replaceAll(RegExp('[\u2066\u2068][^\u2069]*\u2069'), '');
      expect(RegExp(r'[0-9]|KB|JPEG|PNG').hasMatch(outside), isFalse, reason: data);
    }
  });

  for (final locale in ['en', 'ar', 'hi']) {
    testWidgets('$locale at 200% on 360x640: no overflow, no sideways scroll, Save, Share and Done reachable (AC-8.1)', (tester) async {
      await pump(tester, _State.matches, locale: Locale(locale), textScale: 2);
      expect(tester.takeException(), isNull);
      final l = lookupAppLocalizations(Locale(locale));
      for (final text in [l.exportSave, l.exportShare, l.exportDone]) {
        await tester.scrollUntilVisible(find.text(text), 80, scrollable: find.byType(Scrollable).first);
        expect(tester.getRect(find.text(text)).right, lessThanOrEqualTo(360));
      }
      for (final s in tester.widgetList<Scrollable>(find.byType(Scrollable))) {
        expect(s.axisDirection, anyOf(AxisDirection.down, AxisDirection.up), reason: 'no horizontal scroll');
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final s in [_State.mismatch, _State.unreadable]) {
    testWidgets('${s.name} at 200% in hi: no overflow', (tester) async {
      await pump(tester, s, locale: const Locale('hi'), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  }

  group('goldens (G1 design, 360x640)', () {
    setUpAll(() => useTolerantGoldens(tolerance: 0.025)); // text anti-aliasing differs on Linux CI

    for (final locale in ['en', 'ar']) {
      for (final s in _State.values) {
        testWidgets('$locale ${s.name}', (tester) async {
          await pump(tester, s, locale: Locale(locale));
          await expectLater(find.byType(ResultScreen), matchesGoldenFile('goldens/check_${locale}_${s.name}.png'));
        });
      }
    }
    for (final locale in ['en', 'hi']) {
      testWidgets('$locale 200%', (tester) async {
        await pump(tester, _State.matches, locale: Locale(locale), textScale: 2);
        await expectLater(find.byType(ResultScreen), matchesGoldenFile('goldens/check_${locale}_font200.png'));
      });
    }
  });
}
