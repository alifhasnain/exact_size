import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:flutter/services.dart' show SystemChannels;
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
  Future<ValueNotifier<Locale>> pump(WidgetTester tester, {ProviderContainer? container, SourceInfo info = _info}) async {
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
              info: info,
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
    final button = find.widgetWithText(FilledButton, 'Continue');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
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

  group('errors (T13)', () {
    const sizeMsg = 'Enter a width and height between 1 and 10,000 pixels.';
    late List<String> announced;
    Finder msg(String t) => find.byWidgetPredicate(
        (w) => w is Text && w.data?.replaceAll(RegExp('[\u2068\u2069]'), '') == t);

    setUp(() => announced = []);

    Future<void> listen(WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (msg) async {
        final m = msg as Map;
        if (m['type'] == 'announce') announced.add(((m['data'] as Map)['message'] as String).replaceAll(RegExp('[\u2068\u2069]'), ''));
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
    }

    Future<void> fill(WidgetTester tester, {String w = '300', String h = '300', String min = '', String max = '100'}) async {
      await tester.enterText(field('Width'), w);
      await tester.enterText(field('Height'), h);
      await tester.enterText(field('Minimum size'), min);
      await tester.enterText(field('Maximum size'), max);
    }

    testWidgets('AC-2.2, AC-2.3: Min at or above Max shows the message at Min, nothing handed on', (tester) async {
      await pump(tester);
      for (final (min, max) in [('50', '20'), ('50', '50')]) {
        await fill(tester, min: min, max: max);
        await tapContinue(tester);
        expect(find.text('Minimum must be smaller than maximum.'), findsOneWidget, reason: '$min/$max');
        expect(specs, isEmpty);
      }
    });

    testWidgets('AC-3.1: empty Width: size message, focus on Width, announced once, nothing handed on', (tester) async {
      await listen(tester);
      await pump(tester);
      await fill(tester, w: '');
      await tester.tap(field('Maximum size'));
      await tester.pump();
      await tapContinue(tester);
      expect(msg(sizeMsg), findsOneWidget);
      expect(tester.widget<TextField>(field('Width')).focusNode!.hasFocus, isTrue);
      expect(announced, [sizeMsg]);
      expect(specs, isEmpty);
      await fill(tester, w: '0');
      await tapContinue(tester);
      expect(msg(sizeMsg), findsOneWidget);
    });

    testWidgets('AC-3.2: 6001 x 4000 is too large', (tester) async {
      await pump(tester);
      await fill(tester, w: '6001', h: '4000');
      await tapContinue(tester);
      expect(find.text('That size is too large for this app. Choose a smaller size.'), findsOneWidget);
      expect(specs, isEmpty);
    });

    testWidgets('AC-3.3, AC-5.3: decimals in Max give the whole-number message', (tester) async {
      await pump(tester);
      for (final max in ['7.5', '7,5', '1,000', '٧٫٥']) {
        await fill(tester, max: max);
        await tapContinue(tester);
        expect(find.text('Use whole numbers of KB.'), findsOneWidget, reason: max);
      }
      await fill(tester, w: '1.000');
      await tapContinue(tester);
      expect(find.text('Use whole numbers of pixels.'), findsOneWidget);
      expect(specs, isEmpty);
    });

    testWidgets('AC-3.4: the error clears on the fixing keystroke', (tester) async {
      await pump(tester);
      await fill(tester, max: '1');
      await tapContinue(tester);
      expect(find.text('Enter a maximum size between 2 and 10,240.'), findsNothing);
      expect(find.textContaining('Enter a maximum size between'), findsOneWidget);
      await tester.enterText(field('Maximum size'), '12');
      await tester.pump();
      expect(find.textContaining('Enter a maximum size between'), findsNothing);
    });

    testWidgets('AC-3.5: every invalid field shows its own message at once', (tester) async {
      await pump(tester);
      await fill(tester, w: '1.5', h: '0', min: 'x', max: '1');
      await tapContinue(tester);
      expect(find.text('Use whole numbers of pixels.'), findsOneWidget);
      expect(msg(sizeMsg), findsOneWidget);
      expect(find.text('Enter a valid size in KB.'), findsOneWidget);
      expect(find.textContaining('Enter a maximum size between'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNWidgets(4), reason: 'icon and text, not colour alone');
    });

    testWidgets('no error while typing in a fresh field; shown when the field is left', (tester) async {
      await pump(tester);
      await tester.tap(field('Width'));
      await tester.enterText(field('Width'), '0');
      await tester.pump();
      expect(msg(sizeMsg), findsNothing);
      await tester.tap(field('Height'));
      await tester.pump();
      expect(msg(sizeMsg), findsOneWidget);
    });
  });

  group('photo line and hints (T14)', () {
    SourceInfo src(int w, int h, {int exif = 1}) => SourceInfo(
        rawWidth: w, rawHeight: h, mime: 'image/jpeg', exifOrientation: exif, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
    Finder plain(String t) => find.byWidgetPredicate(
        (w) => w is Text && w.data?.replaceAll(RegExp('[\u2068\u2069]'), '') == t);

    testWidgets('AC-7.1: a 200x200 photo with a 300x300 target shows the enlarge notice; Continue hands on', (tester) async {
      await pump(tester, info: src(200, 200));
      await tester.enterText(field('Width'), '300');
      await tester.enterText(field('Height'), '300');
      await tester.enterText(field('Maximum size'), '50');
      await tester.pump();
      expect(plain('This photo is smaller than 300×300 px, so it will be enlarged and may look soft.'), findsOneWidget);
      await tapContinue(tester);
      expect(specs, hasLength(1));
    });

    testWidgets('AC-7.2: 10x10 shows the very-small notice; no notice for a fitting size', (tester) async {
      await pump(tester);
      await tester.enterText(field('Width'), '10');
      await tester.enterText(field('Height'), '10');
      await tester.pump();
      expect(find.text('Very small image. Check the size on your form.'), findsOneWidget);
      await tester.enterText(field('Width'), '300');
      await tester.enterText(field('Height'), '300');
      await tester.pump();
      expect(find.text('Very small image. Check the size on your form.'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('AC-7.3: Use photo size fills 4000 x 3000; a 12,000-wide photo hides it', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Use photo size'));
      await tester.pump();
      expect([text(tester, 'Width'), text(tester, 'Height')], ['4000', '3000']);
      await tester.pumpWidget(const SizedBox());
      await pump(tester, info: src(12000, 1000));
      expect(find.text('Use photo size'), findsNothing);
    });

    testWidgets('AC-7.4: EXIF 6 shows the size as seen, 3000×4000', (tester) async {
      await pump(tester, info: src(4000, 3000, exif: 6));
      expect(plain('Your photo: 3,000×4,000 px'), findsOneWidget);
      await tester.tap(find.text('Use photo size'));
      await tester.pump();
      expect([text(tester, 'Width'), text(tester, 'Height')], ['3000', '4000']);
    });
  });
}
