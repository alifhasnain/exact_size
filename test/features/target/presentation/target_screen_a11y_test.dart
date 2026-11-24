import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';

import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../test_support/tolerant_golden_comparator.dart';

const _info = SourceInfo(
  rawWidth: 4000,
  rawHeight: 3000,
  mime: 'image/jpeg',
  exifOrientation: 1,
  isAnimated: false,
  hasAlpha: false,
  decodePath: DecodePath.region,
);

/// FEAT-005-T15: accessibility, 200% font, RTL and goldens (G1 design).
void main() {
  /// The target screen at [size] dp, with [textScale] and a bottom inset (keyboard).
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(360, 640),
    double textScale = 1,
    double keyboard = 0,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: ExactSizeApp(
          locale: locale,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: TargetScreen(info: _info, onContinue: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<Finder> fields() => [for (var i = 0; i < 4; i++) find.byType(TextField, skipOffstage: false).at(i)];

  Future<void> fillValid(WidgetTester tester) async {
    final f = fields();
    await tester.enterText(f[0], '300');
    await tester.enterText(f[1], '400');
    await tester.enterText(f[3], '100');
    await tester.pumpAndSettle();
  }

  Future<void> continueInvalid(WidgetTester tester) async {
    final f = fields();
    await tester.enterText(f[0], '1.5');
    await tester.enterText(f[1], '0');
    await tester.enterText(f[2], 'x');
    await tester.enterText(f[3], '1');
    final button = find.byType(FilledButton);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(fields()[0], -100, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  testWidgets('AC-1.3 in Arabic: Width is right of Height; Next still goes W, H, Min, Max', (tester) async {
    await pump(tester, locale: const Locale('ar'), size: const Size(420, 900));
    final f = fields();
    expect(tester.getCenter(f[0]).dx, greaterThan(tester.getCenter(f[1]).dx), reason: 'reading order is right to left');
    await tester.tap(f[0]);
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      expect(tester.widget<TextField>(f[i]).focusNode!.hasFocus, isTrue, reason: 'field $i');
      await tester.testTextInput.receiveAction(i == 3 ? TextInputAction.done : TextInputAction.next);
      await tester.pump();
    }
  });

  testWidgets('AC-4.3: each format option exposes its name, selected state and exclusive group', (tester) async {
    final h = tester.ensureSemantics();
    await pump(tester, size: const Size(360, 900));
    expect(
      tester.getSemantics(find.text('JPEG')),
      matchesSemantics(
        label: 'JPEG',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('PNG')),
      matchesSemantics(
        label: 'PNG',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasSelectedState: true,
        isSelected: false,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    h.dispose();
  });

  testWidgets('AC-5.4: Arabic mirrors the layout; field digits stay LTR 0-9', (tester) async {
    await pump(tester, locale: const Locale('ar'), size: const Size(420, 900));
    expect(Directionality.of(tester.element(find.byType(TextField).first)), TextDirection.rtl);
    await tester.enterText(fields()[0], '٣٠٠');
    await tester.tap(fields()[1]);
    await tester.pump();
    final w = tester.widget<TextField>(fields()[0]);
    expect(w.textDirection, TextDirection.ltr);
    expect(w.textAlign, TextAlign.right, reason: 'digits away from the unit at the RTL start (phone check: "px1.5")');
    expect(w.controller!.text, '300');
    // The photo line wraps its size in isolates so the digits keep their order.
    expect(
      find.byWidgetPredicate((x) => x is Text && (x.data ?? '').contains('\u20684,000×3,000\u2069')),
      findsOneWidget,
    );
  });

  testWidgets('AC-6.1: 200% text at 360x640 with the keyboard open: no overflow, Continue reachable', (tester) async {
    await pump(tester, textScale: 2, keyboard: 300);
    expect(tester.takeException(), isNull);
    await continueInvalid(tester);
    expect(tester.takeException(), isNull, reason: 'errors at 200% do not overflow');
    final button = find.byType(FilledButton);
    await tester.scrollUntilVisible(button, 100, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final r = tester.getRect(button);
    expect(r.bottom, lessThanOrEqualTo(640 - 300), reason: 'above the keyboard');
    expect(tester.getSize(fields()[0]).width, greaterThan(200), reason: 'W/H row became a column');
  });

  testWidgets('AC-6.2: each field reads label, unit, required/optional, value and error', (tester) async {
    final h = tester.ensureSemantics();
    await pump(tester, size: const Size(360, 1200));
    await continueInvalid(tester);
    SemanticsData data(int i) => tester.getSemantics(fields()[i]).getSemanticsData();
    final w = data(0);
    expect(w.label, allOf(contains('Width'), contains('px')));
    expect(w.value, '1.5');
    expect(w.hint, 'Use whole numbers of pixels.');
    expect(w.flagsCollection.isRequired, Tristate.isTrue);
    final min = data(2);
    expect(min.label, allOf(contains('Minimum size'), contains('KB'), contains('Optional')));
    expect(min.flagsCollection.isRequired, isNot(Tristate.isTrue));
    expect(min.hint, 'Enter a valid size in KB.');
    expect(data(3).label, allOf(contains('Maximum size'), contains('KB')));
    expect(data(3).flagsCollection.isRequired, Tristate.isTrue);
    h.dispose();
  });

  testWidgets('AC-6.3: every control is at least 48 dp', (tester) async {
    await pump(tester, size: const Size(360, 1200));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    for (final f in fields()) {
      expect(tester.getSize(f).height, greaterThanOrEqualTo(48));
    }
  });

  group('goldens (G1 design, 360x640)', () {
    setUpAll(useTolerantGoldens);

    for (final locale in ['en', 'ar']) {
      testWidgets('$locale empty', (tester) async {
        await pump(tester, locale: Locale(locale));
        await expectLater(find.byType(TargetScreen), matchesGoldenFile('goldens/target_${locale}_empty.png'));
      });
      testWidgets('$locale filled', (tester) async {
        await pump(tester, locale: Locale(locale));
        await fillValid(tester);
        await expectLater(find.byType(TargetScreen), matchesGoldenFile('goldens/target_${locale}_filled.png'));
      });
      testWidgets('$locale error', (tester) async {
        await pump(tester, locale: Locale(locale));
        await continueInvalid(tester);
        await expectLater(find.byType(TargetScreen), matchesGoldenFile('goldens/target_${locale}_error.png'));
      });
    }
    testWidgets('en 200%', (tester) async {
      await pump(tester, textScale: 2);
      await expectLater(find.byType(TargetScreen), matchesGoldenFile('goldens/target_en_font200.png'));
    });
  });

  test('format enum covers the segments', () => expect(OutputFormat.values, hasLength(2)));
}
