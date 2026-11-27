import 'dart:convert';
import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/presets/domain/parse_library.dart';
import 'package:exact_size/features/presets/domain/preset_types.dart';
import 'package:exact_size/features/presets/presentation/preset_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-011-T10: the form list on the synthetic fixture (FR-6..FR-10, FR-14, FR-15, NFR-8).
/// FEAT-014-T08: source lines on each card (FR-2, FR-3, FR-4, FR-8, AC-2.1..2.4).
void main() {
  Map<String, Object?> fixtureJson() =>
      jsonDecode(File('test/presets/fixtures/test_library.json').readAsStringSync()) as Map<String, Object?>;
  final forms = parseLibrary(fixtureJson()).forms;

  ({Object? value, bool popped}) result = (value: null, popped: false);
  Future<void> pump(WidgetTester tester, [List<PresetForm>? list]) async {
    result = (value: null, popped: false);
    // FEAT-014 made each card three lines taller; a tall view keeps all three fixture cards built.
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ExactSizeApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final v = await PresetListScreen.open(context, list ?? forms);
              result = (value: v, popped: true);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('sections with headings, forms and spec rows (AC-1.2, AC-3.1, AC-3.3)', (tester) async {
    await pump(tester);
    expect(find.text('Forms'), findsOneWidget);
    expect(find.text('ZZ'), findsOneWidget); // unknown country shows its code
    expect(find.textContaining('Test Form A'), findsOneWidget);
    expect(find.textContaining('Test Form B'), findsOneWidget);
    expect(find.textContaining('Exams and admissions'), findsOneWidget);
    expect(find.text('Photo'), findsNWidgets(3)); // A, B and C (all built in the tall view)
    expect(find.text('Signature'), findsOneWidget); // A only: no invented row for B
    expect(find.textContaining('200 × 230'), findsOneWidget);
    // Test Form C (KB-only): its row says no pixel size is stated, with no note (FR-6, 2.0).
    final c = find.textContaining('Pixel size not stated');
    await tester.scrollUntilVisible(c, 100, scrollable: find.byType(Scrollable).last);
    expect(
      tester.widget<Text>(c).data!.replaceAll(RegExp('[\u2066-\u2069]'), ''),
      'Pixel size not stated · 10–200 KB · JPEG',
    );
  });

  testWidgets('tapping a spec pops its PresetPick (AC-1.3)', (tester) async {
    await pump(tester);
    // Test Form B's photo row, found by its own summary (the list builds rows lazily).
    final b = find.ancestor(of: find.textContaining('300 × 300'), matching: find.byType(InkWell));
    await tester.ensureVisible(b);
    await tester.pumpAndSettle();
    await tester.tap(b);
    await tester.pumpAndSettle();
    expect(result, (value: const PresetPick(formId: 'test-form-b', kind: SpecKind.photo), popped: true));
    expect(find.byType(PresetListScreen), findsNothing);
  });

  testWidgets('the list filters on every keystroke (AC-2.1)', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'board');
    await tester.pump();
    expect(find.textContaining('Test Form B'), findsOneWidget);
    expect(find.textContaining('Test Form A'), findsNothing);
    await tester.enterText(find.byType(TextField), 'tfa');
    await tester.pump();
    expect(find.textContaining('Test Form A'), findsOneWidget);
    expect(find.textContaining('Test Form B'), findsNothing);
    await tester.tap(find.byIcon(Icons.close)); // clear shows all again
    await tester.pump();
    expect(find.textContaining('Test Form B'), findsOneWidget);
  });

  testWidgets('no match shows the empty state; Enter sizes yourself pops null (AC-2.3)', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('No form matches.'), findsOneWidget);
    expect(find.text('ExactSize is not affiliated with the organisations listed.'), findsOneWidget);
    await tester.tap(find.text('Enter sizes yourself'));
    await tester.pumpAndSettle();
    expect(result, (value: null, popped: true));
  });

  testWidgets('the search field never learns, suggests or autofills (AC-2.4)', (tester) async {
    await pump(tester);
    final f = tester.widget<TextField>(find.byType(TextField));
    expect(f.autocorrect, isFalse);
    expect(f.enableSuggestions, isFalse);
    expect(f.enableIMEPersonalizedLearning, isFalse);
    expect(f.autofillHints, isNull);
  });

  testWidgets('DPI, background and content notes show with an icon (AC-5.1, AC-5.2)', (tester) async {
    await pump(tester);
    expect(find.textContaining('asks for'), findsOneWidget);
    expect(find.textContaining('does not change backgrounds'), findsOneWidget);
    expect(find.textContaining('other rules for this image'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNWidgets(3));
  });

  testWidgets('a skipped spec is absent and nothing throws (AC-6.2)', (tester) async {
    final json = fixtureJson();
    (((json['forms']! as List).first as Map)['specs']! as List).add({'kind': 'photo', 'width': 0});
    final library = parseLibrary(json);
    expect(library.skipped, 1);
    await pump(tester, library.forms);
    expect(tester.takeException(), isNull);
    expect(find.text('Photo'), findsNWidgets(3)); // A, B and C; the skipped second photo of A is absent
  });

  testWidgets('a 10,000-character paste is cut to 100 with no exception (NFR-8)', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'x' * 10000);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text.length, 100);
    expect(find.text('No form matches.'), findsOneWidget);
  });

  testWidgets('the footer ends the list; Back pops null', (tester) async {
    await pump(tester);
    final footer = find.text('ExactSize is not affiliated with the organisations listed.');
    await tester.scrollUntilVisible(footer, 100, scrollable: find.byType(Scrollable).last);
    expect(footer, findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(result, (value: null, popped: true));
  });

  group('FEAT-014 card source lines', () {
    String plain(String t) => t.replaceAll(RegExp('[\u2066-\u2069]'), '');
    Finder lines(String title) => find.textContaining('Source: \u2068$title\u2069');
    const linesA = 'Source: Test notice 1 (Test Issuer)\nWebsite: notice.example.test\nLast checked: 2026-10-01';

    testWidgets('AC-2.1: each card shows its lines once, Website left out for Test Form C', (tester) async {
      await pump(tester);
      expect(lines('Test notice 1'), findsOneWidget); // Test Form A has two specs, still one text
      expect(plain(tester.widget<Text>(lines('Test notice 1')).data!), linesA);
      expect(
        plain(tester.widget<Text>(lines('Test notice 2')).data!),
        'Source: Test notice 2 (Test Board)\nWebsite: notice.example.test\nLast checked: 2026-11-20',
      );
      expect(
        plain(tester.widget<Text>(lines('Test notice 3')).data!),
        'Source: Test notice 3 (Test Office)\nLast checked: 2026-11-20',
      );
    });

    testWidgets('AC-2.2: after a search the remaining card keeps the same lines', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'tfa');
      await tester.pump();
      expect(lines('Test notice 2'), findsNothing);
      expect(plain(tester.widget<Text>(lines('Test notice 1')).data!), linesA);
    });

    testWidgets('AC-2.3: lines sit between the issuer line and the first spec key', (tester) async {
      await pump(tester);
      final issuer = find.textContaining('Exams and admissions');
      final source = lines('Test notice 1');
      final firstKey = find.ancestor(of: find.textContaining('200 × 230'), matching: find.byType(InkWell));
      expect(tester.getRect(issuer).bottom, lessThanOrEqualTo(tester.getRect(source).top));
      expect(tester.getRect(source).bottom, lessThanOrEqualTo(tester.getRect(firstKey).top));
      expect(find.descendant(of: firstKey, matching: source), findsNothing);
    });

    testWidgets('AC-2.4: no prompt on the list; the footer stays last', (tester) async {
      await pump(tester);
      expect(find.textContaining('before you upload'), findsNothing);
      expect(find.byIcon(Icons.history), findsNothing);
      final footer = find.text('ExactSize is not affiliated with the organisations listed.');
      await tester.scrollUntilVisible(footer, 100, scrollable: find.byType(Scrollable).last);
      expect(tester.getRect(footer).top, greaterThan(tester.getRect(lines('Test notice 3')).bottom));
    });

    testWidgets('FR-8: tap and long-press on the lines do nothing', (tester) async {
      await pump(tester);
      final source = lines('Test notice 1');
      await tester.tap(source, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.longPress(source, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(result.popped, isFalse);
      expect(find.byType(PresetListScreen), findsOneWidget);
      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      expect(find.ancestor(of: source, matching: find.byType(InkWell)), findsNothing);
      expect(find.ancestor(of: source, matching: find.byType(GestureDetector)), findsNothing);
    });
  });
}
