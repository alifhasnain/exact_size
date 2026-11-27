import 'dart:convert';
import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/presets/data/preset_asset_source.dart';
import 'package:exact_size/features/presets/presentation/preset_list_screen.dart';
import 'package:exact_size/features/presets/presentation/preset_providers.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:exact_size/ui/booth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Serves one string as the preset asset.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(utf8.encode(text));
}

const _big = SourceInfo(
  rawWidth: 4000,
  rawHeight: 3000,
  mime: 'image/jpeg',
  exifOrientation: 1,
  isAnimated: false,
  hasAlpha: false,
  decodePath: DecodePath.region,
);

/// FEAT-011-T11: the target-step row and its wiring (FR-5, FR-11..FR-14, FR-16, AC-1, AC-4, AC-5, AC-6.1).
/// FEAT-014-T07: the source block under the applied row (FR-1, FR-5..FR-8, FR-12, AC-1, AC-3, AC-4.3, AC-4.4, AC-5.3).
void main() {
  final fixture = File('test/presets/fixtures/test_library.json').readAsStringSync();
  late List<TargetSpec> specs;
  // The device date the row sees; Test Form A was checked 2026-10-01.
  late DateTime now;
  late List<String> sunk;
  setUp(() {
    specs = [];
    now = DateTime(2026, 10, 16);
    sunk = [];
  });

  Finder field(String label) => find.widgetWithText(TextField, label);
  String text(WidgetTester tester, String label) => tester.widget<TextField>(field(label)).controller!.text;
  final choose = find.text('Choose a form');
  final applied = find.textContaining('Test Form A');
  final row = find.ancestor(of: find.byIcon(Icons.list_alt), matching: find.byType(InkWell));

  Future<void> pump(WidgetTester tester, {String? asset, SourceInfo info = _big}) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final c = ProviderContainer(
      overrides: [
        presetSourceProvider.overrideWithValue(PresetAssetSource(bundle: _Bundle(asset ?? fixture), sink: sunk.add)),
        presetClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: ExactSizeApp(
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => TargetScreen(
              info: info,
              onContinue: (spec) {
                specs.add(spec);
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('crop'))));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the list and taps the [index]th spec key whose kind is [kind].
  Future<void> pick(WidgetTester tester, String kind, [int index = 0]) async {
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(PresetListScreen), findsOneWidget);
    final key = find.ancestor(of: find.text(kind), matching: find.byType(InkWell)).at(index);
    await tester.ensureVisible(key);
    await tester.pumpAndSettle();
    await tester.tap(key);
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Continue');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  List<String> notices(WidgetTester tester) => [
    for (final n in tester.widgetList<BoothNotice>(find.byType(BoothNotice))) n.text,
  ];

  testWidgets('the row shows with all five fields usable (AC-1.1)', (tester) async {
    await pump(tester);
    expect(choose, findsOneWidget);
    for (final label in ['Width', 'Height', 'Minimum size', 'Maximum size']) {
      expect(field(label), findsOneWidget);
    }
    expect(find.text('JPEG'), findsOneWidget);
    await tester.enterText(field('Width'), '300');
    expect(text(tester, 'Width'), '300');
  });

  testWidgets('a load failure shows the message and manual entry works (AC-6.1)', (tester) async {
    await pump(tester, asset: '{"schema": 1, "forms": [');
    expect(choose, findsNothing);
    expect(find.text('The form list could not be opened. You can enter sizes yourself.'), findsOneWidget);
    await tester.enterText(field('Width'), '300');
    await tester.enterText(field('Height'), '400');
    await tester.enterText(field('Maximum size'), '100');
    await tapContinue(tester);
    expect(specs.single, const TargetSpec(width: 300, height: 400, maxKb: 100, format: OutputFormat.jpeg));
  });

  testWidgets('zero forms hide the row (OQ-T1)', (tester) async {
    await pump(tester, asset: '{"schema": 1, "forms": []}');
    expect(choose, findsNothing);
    expect(find.byType(BoothNotice), findsNothing);
  });

  testWidgets('a pick fills every field with the keyboard closed and shows the label (AC-4.1, AC-4.3)', (tester) async {
    await pump(tester);
    await tester.enterText(field('Width'), '300');
    await pick(tester, 'Photo');
    expect(
      [
        for (final l in ['Width', 'Height', 'Minimum size', 'Maximum size']) text(tester, l),
      ],
      ['200', '230', '20', '50'],
    );
    expect(tester.widget<SegmentedButton<OutputFormat>>(find.byType(SegmentedButton<OutputFormat>)).selected, {
      OutputFormat.jpeg,
    });
    expect(tester.testTextInput.isVisible, isFalse);
    expect(choose, findsNothing);
    final label = tester.widget<Text>(applied).data!;
    expect(label.replaceAll(RegExp('[\u2066-\u2069]'), ''), 'Test Form A · Photo');
  });

  testWidgets('no minimum leaves Minimum empty (AC-4.2)', (tester) async {
    await pump(tester);
    await tester.enterText(field('Minimum size'), '5');
    await pick(tester, 'Signature');
    expect(text(tester, 'Minimum size'), '');
    expect([text(tester, 'Width'), text(tester, 'Height'), text(tester, 'Maximum size')], ['140', '60', '20']);
  });

  testWidgets('an edit returns the label to Choose a form; the same values (Arabic-Indic too) bring it back (AC-4.4)', (
    tester,
  ) async {
    await pump(tester);
    await pick(tester, 'Photo');
    await tester.enterText(field('Width'), '201');
    await tester.pump();
    expect(choose, findsOneWidget);
    expect(find.byType(BoothNotice), findsNothing);
    await tester.enterText(field('Width'), '٢٠٠');
    await tester.pump();
    expect(applied, findsOneWidget);
  });

  testWidgets('Continue hands over the same TargetSpec as manual entry (AC-4.5)', (tester) async {
    await pump(tester);
    await pick(tester, 'Photo');
    await tapContinue(tester);
    expect(specs.single, const TargetSpec(width: 200, height: 230, minKb: 20, maxKb: 50, format: OutputFormat.jpeg));
  });

  testWidgets('the upscale notice shows as for manual entry (AC-4.6)', (tester) async {
    const small = SourceInfo(
      rawWidth: 100,
      rawHeight: 100,
      mime: 'image/jpeg',
      exifOrientation: 1,
      isAnimated: false,
      hasAlpha: false,
      decodePath: DecodePath.region,
    );
    await pump(tester, info: small, asset: '{"schema": 1, "forms": []}');
    await tester.enterText(field('Width'), '300');
    await tester.enterText(field('Height'), '300');
    await tester.pump();
    final manual = notices(tester);
    expect(manual, isNotEmpty);

    await pump(tester, info: small, asset: fixture);
    await pick(tester, 'Photo', 1); // Test Form B photo: 300 × 300, content note
    final withPreset = notices(tester);
    for (final n in manual) {
      expect(withPreset, contains(n));
    }
  });

  testWidgets('notes show while applied and nothing is blocked (AC-5.1..5.3)', (tester) async {
    await pump(tester);
    await pick(tester, 'Photo');
    final n = notices(tester).join('\n');
    expect(n, contains('DPI'));
    expect(n, contains('does not change backgrounds'));
    await tapContinue(tester);
    expect(specs, hasLength(1));
  });

  testWidgets('Back from the list leaves the values unchanged (AC-1.4)', (tester) async {
    await pump(tester);
    await tester.enterText(field('Width'), '300');
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(text(tester, 'Width'), '300');
    expect(choose, findsOneWidget);
  });

  testWidgets('photo then signature switches the values (AC-3.2)', (tester) async {
    await pump(tester);
    await pick(tester, 'Photo');
    await pick(tester, 'Signature');
    expect(
      [text(tester, 'Width'), text(tester, 'Height'), text(tester, 'Minimum size'), text(tester, 'Maximum size')],
      ['140', '60', '', '20'],
    );
    expect(tester.widget<Text>(applied).data!, contains('Signature'));
  });

  // FEAT-011-T20 (PRD 2.0): KB-only presets on the target step (FR-26, AC-4.7 to AC-4.9).
  const kbNote = "This form sets no pixel size. Enter a width and height, or use your photo's size.";
  final appliedC = find.textContaining('Test Form C');

  Future<void> pickC(WidgetTester tester) async {
    await tester.tap(row);
    await tester.pumpAndSettle();
    // The list builds rows lazily: scroll Test Form C's row into view first.
    final summary = find.textContaining('Pixel size not stated');
    await tester.scrollUntilVisible(
      summary,
      200,
      scrollable: find.descendant(of: find.byType(PresetListScreen), matching: find.byType(Scrollable)).last,
    );
    final key = find.ancestor(of: summary, matching: find.byType(InkWell));
    await tester.ensureVisible(key);
    await tester.pumpAndSettle();
    await tester.tap(key);
    await tester.pumpAndSettle();
  }

  List<String> values(WidgetTester tester) => [
    for (final l in ['Width', 'Height', 'Minimum size', 'Maximum size']) text(tester, l),
  ];

  testWidgets('AC-4.7: a KB-only pick keeps Width and Height, fills KB and format, shows the FR-26 line first', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(field('Width'), '300');
    await tester.enterText(field('Height'), '400');
    await tester.enterText(field('Maximum size'), '9');
    await pickC(tester);
    expect(values(tester), ['300', '400', '10', '200']);
    expect(tester.widget<SegmentedButton<OutputFormat>>(find.byType(SegmentedButton<OutputFormat>)).selected, {
      OutputFormat.jpeg,
    });
    expect(tester.widget<Text>(appliedC).data!.replaceAll(RegExp('[\u2066-\u2069]'), ''), 'Test Form C · Photo');
    expect(notices(tester).first, kbNote);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('AC-4.8: editing Width or Height keeps the label; Min, Max or format drops it until restored', (
    tester,
  ) async {
    await pump(tester);
    await pickC(tester);
    await tester.enterText(field('Width'), '500');
    await tester.enterText(field('Height'), '');
    await tester.pump();
    expect(appliedC, findsOneWidget);
    expect(notices(tester), contains(kbNote));
    for (final (label, changed, restored) in [('Minimum size', '11', '10'), ('Maximum size', '199', '200')]) {
      await tester.enterText(field(label), changed);
      await tester.pump();
      expect(choose, findsOneWidget, reason: label);
      expect(notices(tester), isNot(contains(kbNote)), reason: label);
      await tester.enterText(field(label), restored);
      await tester.pump();
      expect(appliedC, findsOneWidget, reason: label);
    }
    await tester.ensureVisible(find.text('PNG'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PNG'));
    await tester.pump();
    expect(choose, findsOneWidget);
    await tester.tap(find.text('JPEG'));
    await tester.pump();
    expect(appliedC, findsOneWidget);
  });

  testWidgets('AC-4.9: with Width and Height empty, Continue shows FEAT-005 errors and fills nothing in', (
    tester,
  ) async {
    await pump(tester);
    await pickC(tester);
    expect(values(tester), ['', '', '10', '200']);
    await tapContinue(tester);
    expect(specs, isEmpty);
    expect(find.byIcon(Icons.error_outline), findsWidgets);
    expect(values(tester), ['', '', '10', '200']);
    expect(appliedC, findsOneWidget);
  });

  testWidgets('"Use photo size" after a KB-only pick fills the photo size and keeps the label', (tester) async {
    await pump(tester);
    await pickC(tester);
    await tester.tap(find.text('Use photo size'));
    await tester.pump();
    expect(values(tester), ['4000', '3000', '10', '200']);
    expect(appliedC, findsOneWidget);
    await tapContinue(tester);
    expect(specs.single, const TargetSpec(width: 4000, height: 3000, minKb: 10, maxKb: 200, format: OutputFormat.jpeg));
  });

  testWidgets('the FR-26 line is absent for a full spec', (tester) async {
    await pump(tester);
    await pick(tester, 'Photo');
    expect(applied, findsOneWidget);
    expect(notices(tester), isNot(contains(kbNote)));
  });

  testWidgets('the KB-only pick announcement is the label followed by the FR-26 line', (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
      msg,
    ) async {
      final m = msg as Map;
      if (m['type'] == 'announce') {
        announced.add(((m['data'] as Map)['message'] as String).replaceAll(RegExp('[\u2066-\u2069]'), ''));
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
        SystemChannels.accessibility,
        null,
      ),
    );
    await pump(tester);
    await pickC(tester);
    expect(announced.last, 'Test Form C · Photo\n$kbNote');
  });

  group('FEAT-014 source block', () {
    final block = find.ancestor(of: find.byIcon(Icons.history), matching: find.byType(BoothNotice));
    String plain(String t) => t.replaceAll(RegExp('[\u2066-\u2069]'), '');
    String blockText(WidgetTester tester) => plain(tester.widget<BoothNotice>(block).text);
    const normal = "Check these sizes against your form's notice or instructions before you upload. They can change.";
    const old =
        "These sizes were last checked more than 90 days ago. Check your form's notice or instructions before you upload.";
    const linesA = 'Source: Test notice 1 (Test Issuer)\nWebsite: notice.example.test\nLast checked: 2026-10-01';

    testWidgets('AC-1.1: source, website, date and prompt under the applied row; Continue works', (tester) async {
      await pump(tester);
      await pick(tester, 'Photo');
      expect(blockText(tester), '$linesA\n$normal');
      await tapContinue(tester);
      expect(specs, hasLength(1));
    });

    testWidgets('AC-1.2, AC-1.4: Test Form C has no Website line; KB-only line first, block last', (tester) async {
      await pump(tester);
      await pickC(tester);
      expect(blockText(tester), 'Source: Test notice 3 (Test Office)\nLast checked: 2026-11-20\n$normal');
      expect(notices(tester).first, contains('sets no pixel size'));
      expect(notices(tester).last, tester.widget<BoothNotice>(block).text);
    });

    testWidgets('AC-1.3: an edit hides the block with the notes; restoring the value brings both back', (tester) async {
      await pump(tester);
      await pick(tester, 'Photo');
      await tester.enterText(field('Maximum size'), '49');
      await tester.pumpAndSettle();
      expect(block, findsNothing);
      expect(notices(tester).join(), isNot(contains('DPI')));
      await tester.enterText(field('Maximum size'), '50');
      await tester.pumpAndSettle();
      expect(block, findsOneWidget);
      expect(notices(tester).join(), contains('DPI'));
    });

    testWidgets('AC-1.5: the DPI and background notes come before the block', (tester) async {
      await pump(tester);
      await pick(tester, 'Photo');
      final n = notices(tester);
      expect(n, hasLength(3));
      expect(n[0], contains('DPI'));
      expect(n[1], contains('backgrounds'));
      expect(plain(n[2]), startsWith('Source:'));
    });

    testWidgets('AC-1.6, FR-8: tap and long-press on the block do nothing', (tester) async {
      await pump(tester);
      await pick(tester, 'Photo');
      await tester.ensureVisible(block);
      await tester.pumpAndSettle();
      await tester.tap(block, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.longPress(block, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(PresetListScreen), findsNothing);
      expect(find.text('crop'), findsNothing);
      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      expect(find.byType(SelectableText), findsNothing);
      expect(find.descendant(of: block, matching: find.byType(InkWell)), findsNothing);
      expect(find.descendant(of: block, matching: find.byType(GestureDetector)), findsNothing);
      expect(blockText(tester), '$linesA\n$normal');
    });

    testWidgets('AC-1.7: no block with no applied spec, and none on a load failure', (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.history), findsNothing);
      await pump(tester, asset: '{ not json');
      expect(find.text('The form list could not be opened. You can enter sizes yourself.'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsNothing);
    });

    for (final (date, days, prompt) in [
      (DateTime(2026, 12, 31), 91, old),
      (DateTime(2026, 12, 30), 90, normal),
      (DateTime(2026, 9, 27), -4, normal),
    ]) {
      testWidgets('AC-3.1..3.3: $days days after the check shows the ${prompt == old ? 'old-check' : 'normal'} prompt', (
        tester,
      ) async {
        now = date;
        await pump(tester);
        await pick(tester, 'Photo');
        expect(blockText(tester), '$linesA\n$prompt');
      });
    }

    testWidgets('AC-3.4: the old-check prompt changes no value and Continue works', (tester) async {
      now = DateTime(2099);
      await pump(tester);
      await pick(tester, 'Photo');
      expect(blockText(tester), endsWith(old));
      expect(values(tester), ['200', '230', '20', '50']);
      await tapContinue(tester);
      expect(specs, hasLength(1));
    });

    testWidgets('AC-3.5: a later date is read on the next build after the list', (tester) async {
      await pump(tester);
      await pick(tester, 'Photo');
      expect(blockText(tester), endsWith(normal));
      now = DateTime(2026, 12, 31);
      await pick(tester, 'Photo');
      expect(blockText(tester), endsWith(old));
    });

    testWidgets('AC-4.3: no log line or loader message holds the form id, title, host or date', (tester) async {
      final logs = <String>[];
      final saved = debugPrint;
      debugPrint = (m, {wrapWidth}) => logs.add('$m');
      try {
        await pump(tester);
        await pick(tester, 'Photo');
        await tester.ensureVisible(block);
        await tester.pumpAndSettle();
        expect(block, findsOneWidget);
      } finally {
        debugPrint = saved;
      }
      for (final line in [...logs, ...sunk]) {
        for (final secret in ['test-form-a', 'Test notice 1', 'notice.example.test', '2026-10-01']) {
          expect(line, isNot(contains(secret)));
        }
      }
    });

    testWidgets('AC-4.4: a fresh start shows no block', (tester) async {
      await pump(tester);
      await pick(tester, 'Photo');
      expect(block, findsOneWidget);
      await pump(tester);
      expect(block, findsNothing);
      expect(choose, findsOneWidget);
    });

    testWidgets('AC-5.3: the block is one semantics node and the icon has no label', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await pick(tester, 'Photo');
      expect(find.bySemanticsLabel(RegExp('Source:')), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Source:')));
      expect(plain(node.label), '$linesA\n$normal');
      expect(tester.widget<Icon>(find.byIcon(Icons.history)).semanticLabel, isNull);
      expect(tester.getRect(row).top, lessThan(tester.getRect(block).top));
      handle.dispose();
    });

    testWidgets('NFR-7, AC-6.3: empty title, no date, 300-character URL or a control character never break the block', (
      tester,
    ) async {
      final json = jsonDecode(fixture) as Map<String, Object?>;
      final a = (json['forms']! as List).first as Map<String, Object?>;
      a['source'] = {'title': '', 'url': 'https://notice.example.test/${'a' * 270}'};
      a.remove('lastChecked');
      await pump(tester, asset: jsonEncode(json));
      await pick(tester, 'Photo');
      expect(tester.takeException(), isNull);
      expect(blockText(tester), 'Website: notice.example.test\n$normal');
      expect(blockText(tester), isNot(contains('()')));

      a['source'] = {'title': 'Test \u202Enotice', 'url': 'https://no\u202Etice.example.test/'};
      await pump(tester, asset: jsonEncode(json));
      await pick(tester, 'Photo');
      expect(tester.takeException(), isNull);
      expect(blockText(tester), startsWith('Source: Test'));
      expect(blockText(tester), isNot(contains('Website:')));
    });
  });
}
