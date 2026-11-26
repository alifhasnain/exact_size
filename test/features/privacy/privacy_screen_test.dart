import 'dart:async';
import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/pick/data/pick_outcome_log.dart';
import 'package:exact_size/features/pick/data/system_picker.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/pick/presentation/pick_controller.dart';
import 'package:exact_size/features/pick/presentation/pick_screen.dart';
import 'package:exact_size/features/privacy/presentation/privacy_screen.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../test_support/fake_system_picker.dart';

const _info = SourceInfo(
    rawWidth: 40, rawHeight: 30, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
const _uri = 'content://media/external/images/media/[PLACEHOLDER]';

class _Probe extends SourceProbe {
  Completer<ProbeResult>? gate;
  @override
  Future<ProbeResult> probe(SourceHandle src) async => gate != null ? gate!.future : const ProbeOk(_info);
}

/// FEAT-016-T14 (FR-2, FR-3, FR-4, NFR-2): the privacy explainer opened from the pick screen.
void main() {
  late FakeSystemPicker picker;
  late _Probe probe;
  late Directory tmp;
  late List<PickedImage> picked;
  final l = lookupAppLocalizations(const Locale('en'));

  setUp(() async {
    await getIt.reset();
    picker = FakeSystemPicker();
    probe = _Probe();
    picked = [];
    tmp = Directory.systemTemp.createTempSync('privacy_screen');
    getIt
      ..registerSingleton<SystemPicker>(picker)
      ..registerSingleton<TempFiles>(TempFiles(tmp, folder: 'camera'), instanceName: 'camera')
      ..registerSingleton<SourceProbe>(probe)
      ..registerSingleton(PickOutcomeLog((_) {}));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: ExactSizeApp(
        locale: const Locale('en'),
        home: PickScreen(onPicked: (context, image) {
          picked.add(image);
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('next step'))));
        }),
      ),
    ));
    await tester.pump();
    return container;
  }

  Finder entry() => find.widgetWithText(TextButton, l.privacyEntry);

  Future<void> open(WidgetTester tester) async {
    await tester.ensureVisible(entry());
    await tester.pumpAndSettle();
    await tester.tap(entry());
    await tester.pumpAndSettle();
  }

  testWidgets('one tap opens the explainer; Back returns to the same pick screen (AC-2.1)', (tester) async {
    final container = await pumpScreen(tester);
    final before = container.read(pickControllerProvider);
    expect(tester.getSize(entry()).height, greaterThanOrEqualTo(48));
    await open(tester);
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.text(l.privacyTitle), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsNothing);
    expect(find.byType(PickScreen), findsOneWidget);
    expect(container.read(pickControllerProvider), before);
  });

  testWidgets('title, then the six headings (a)-(f) as header nodes, each followed by its body (FR-3, AC-2.5)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);
    await open(tester);
    final headings = [
      l.privacyTitle,
      l.privacyOnPhoneTitle,
      l.privacyOfflineTitle,
      l.privacyKeptTitle,
      l.privacyCopiesTitle,
      l.privacyOutsideTitle,
      l.privacyReadsTitle,
    ];
    final bodies = [l.privacyOnPhone, l.privacyOffline, l.privacyKept, l.privacyCopies, l.privacyOutside, l.privacyReads];
    for (final h in headings) {
      expect(tester.getSemantics(find.text(h)).flagsCollection.isHeader, isTrue, reason: h);
    }
    final order = [
      headings[0],
      for (var i = 0; i < 6; i++) ...[headings[i + 1], bodies[i]],
    ];
    final tops = [for (final t in order) tester.getTopLeft(find.text(t)).dy];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: order[i]);
    }
    handle.dispose();
  });

  testWidgets('static text only: nothing tappable, no link, image or progress (FR-4, AC-2.2)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);
    await open(tester);
    for (final type in [InkWell, GestureDetector, Image, CircularProgressIndicator, LinearProgressIndicator, ButtonStyleButton]) {
      expect(find.descendant(of: find.byType(SingleChildScrollView), matching: find.byWidgetPredicate((w) => w.runtimeType == type || (type == ButtonStyleButton && w is ButtonStyleButton))),
          findsNothing, reason: '$type');
    }
    expect(find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Text)), findsNWidgets(13));
    final links = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byWidgetPredicate((w) => w is Semantics && ((w.properties.link ?? false) || (w.properties.button ?? false))));
    expect(links, findsNothing);
    handle.dispose();
  });

  testWidgets('a photo shared in while the explainer is open returns to the first route, then the next step', (tester) async {
    await pumpScreen(tester);
    await open(tester);
    picker.deliver(const Picked(uri: _uri, origin: PickOrigin.share));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsNothing);
    expect(picked, hasLength(1));
    expect(find.text('next step'), findsOneWidget);
  });

  testWidgets('the entry is disabled while a pick is opening', (tester) async {
    await pumpScreen(tester);
    expect(tester.widget<TextButton>(entry()).onPressed, isNotNull);
    probe.gate = Completer<ProbeResult>();
    picker.deliver(const Picked(uri: _uri, origin: PickOrigin.gallery));
    await tester.pump();
    expect(tester.widget<TextButton>(entry()).onPressed, isNull);
    probe.gate!.complete(const ProbeOk(_info));
    await tester.pumpAndSettle();
    expect(picked, hasLength(1));
    expect(find.byType(PrivacyScreen), findsNothing);
  });

  testWidgets('the entry has a text label and 48 dp; its chevron mirrors in RTL and is hidden from TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);
    expect(tester.getSemantics(entry()).label, l.privacyEntry);
    expect(tester.getSize(entry()).height, greaterThanOrEqualTo(48));
    expect(Icons.chevron_right.matchTextDirection, isTrue);
    expect(find.ancestor(of: find.byIcon(Icons.chevron_right), matching: find.byType(ExcludeSemantics)), findsWidgets);
    handle.dispose();
  });
}
