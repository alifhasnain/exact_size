import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _info = SourceInfo(
    rawWidth: 4000, rawHeight: 3000, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);

/// FEAT-005-T12: fields, keyboard, focus order, format and hand-over.
void main() {
  late List<TargetSpec> specs;
  setUp(() => specs = []);

  Finder field(String label) => find.widgetWithText(TextField, label);
  String text(WidgetTester tester, String label) => tester.widget<TextField>(field(label)).controller!.text;

  /// The target screen on a phone; Continue pushes a fake crop route.
  Future<ValueNotifier<Locale>> pump(WidgetTester tester, {ProviderContainer? container}) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final locale = ValueNotifier(const Locale('en'));
    final c = container ?? ProviderContainer();
    if (container == null) addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: ValueListenableBuilder(
        valueListenable: locale,
        builder: (_, l, _) => ExactSizeApp(
          locale: l,
          home: Builder(
            builder: (context) => TargetScreen(
              info: _info,
              onContinue: (spec) {
                specs.add(spec);
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('crop'))));
              },
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return locale;
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('AC-1.1: fresh screen is empty with JPEG selected', (tester) async {
    await pump(tester);
    for (final l in ['Width', 'Height', 'Minimum size', 'Maximum size']) {
      expect(text(tester, l), isEmpty, reason: l);
    }
    expect(find.text('Optional'), findsOneWidget);
    final format = tester.widget<SegmentedButton<OutputFormat>>(find.byType(SegmentedButton<OutputFormat>));
    expect(format.selected, {OutputFormat.jpeg});
  });

  testWidgets('AC-1.2: 300/300/-/100 gives one spec with one tap (Continue)', (tester) async {
    await pump(tester);
    await tester.enterText(field('Width'), '300');
    await tester.enterText(field('Height'), '300');
    await tester.enterText(field('Maximum size'), '100');
    await tapContinue(tester);
    expect(specs, [const TargetSpec(width: 300, height: 300, maxKb: 100, format: OutputFormat.jpeg)]);
    expect(find.text('crop'), findsOneWidget);
  });

  testWidgets('AC-1.3: Next moves W, H, Min, Max; Done on Max closes the keyboard', (tester) async {
    await pump(tester);
    await tester.tap(field('Width'));
    await tester.pump();
    final order = <String>[];
    bool has(String l) => tester.widget<TextField>(field(l)).focusNode!.hasFocus;
    for (final l in ['Width', 'Height', 'Minimum size', 'Maximum size']) {
      expect(has(l), isTrue, reason: 'focus on $l');
      order.add(l);
      await tester.testTextInput.receiveAction(l == 'Maximum size' ? TextInputAction.done : TextInputAction.next);
      await tester.pump();
    }
    expect(order, hasLength(4));
    expect(['Width', 'Height', 'Minimum size', 'Maximum size'].any(has), isFalse, reason: 'Done unfocuses');
  });

  testWidgets('AC-2.1: Min 20 and Max 50 are handed on', (tester) async {
    await pump(tester);
    await tester.enterText(field('Width'), '300');
    await tester.enterText(field('Height'), '400');
    await tester.enterText(field('Minimum size'), '20');
    await tester.enterText(field('Maximum size'), '50');
    await tapContinue(tester);
    expect(specs.single.minKb, 20);
    expect(specs.single.maxKb, 50);
  });

  testWidgets('AC-4.1, AC-4.2: PNG selected and handed on; the selection cannot be cleared', (tester) async {
    await pump(tester);
    await tester.tap(find.text('PNG'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PNG')); // tapping the selected segment keeps it
    await tester.pumpAndSettle();
    final format = tester.widget<SegmentedButton<OutputFormat>>(find.byType(SegmentedButton<OutputFormat>));
    expect(format.selected, {OutputFormat.png});
    expect(format.emptySelectionAllowed, isFalse);
    await tester.enterText(field('Width'), '30');
    await tester.enterText(field('Height'), '30');
    await tester.enterText(field('Maximum size'), '10');
    await tapContinue(tester);
    expect(specs.single.format, OutputFormat.png);
  });

  testWidgets('AC-5.1: Arabic-Indic digits show as 300 after the field is left', (tester) async {
    await pump(tester);
    await tester.enterText(field('Width'), '٣٠٠');
    await tester.tap(field('Height'));
    await tester.pump();
    expect(text(tester, 'Width'), '300');
  });

  testWidgets('AC-8.1: Back from crop keeps the values', (tester) async {
    await pump(tester);
    await tester.enterText(field('Width'), '600');
    await tester.enterText(field('Height'), '800');
    await tester.enterText(field('Maximum size'), '200');
    await tapContinue(tester);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect([text(tester, 'Width'), text(tester, 'Height'), text(tester, 'Maximum size')], ['600', '800', '200']);
  });

  testWidgets('AC-8.2: values stay across a locale switch', (tester) async {
    final locale = await pump(tester);
    await tester.enterText(field('Width'), '600');
    locale.value = const Locale('es');
    await tester.pumpAndSettle();
    expect(find.text('600'), findsOneWidget);
    expect(find.byType(TargetScreen), findsOneWidget);
  });

  testWidgets('a new photo keeps the session values (FR-10)', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await pump(tester, container: c);
    await tester.enterText(field('Width'), '640');
    await tester.pumpWidget(const SizedBox());
    await pump(tester, container: c);
    expect(text(tester, 'Width'), '640');
  });

  testWidgets('a 10,000-character paste is cut to 32 characters, no error', (tester) async {
    await pump(tester);
    await tester.enterText(field('Width'), '1' * 10000);
    await tester.pump();
    expect(text(tester, 'Width'), hasLength(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard: digit keypad, no learning, suggestions or autocorrect; no autofill', (tester) async {
    await pump(tester);
    await tester.tap(field('Width'));
    await tester.pump();
    final args = tester.testTextInput.setClientArgs!;
    expect((args['inputType'] as Map)['name'], 'TextInputType.number');
    expect(args['autocorrect'], isFalse);
    expect(args['enableSuggestions'], isFalse);
    expect(args['enableIMEPersonalizedLearning'], isFalse);
    expect(args['inputAction'], 'TextInputAction.next');
    expect(args['autofill'], isNull);
    final f = tester.widget<TextField>(field('Width'));
    expect(f.restorationId, isNull);
    expect(f.spellCheckConfiguration, isNull);
  });
}
