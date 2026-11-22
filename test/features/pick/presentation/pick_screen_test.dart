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
import 'package:exact_size/features/pick/presentation/pick_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../test_support/fake_system_picker.dart';
import '../../../../test_support/tolerant_golden_comparator.dart';

const _info = SourceInfo(
    rawWidth: 40, rawHeight: 30, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
const _uri = 'content://media/external/images/media/[PLACEHOLDER]';

class _Probe extends SourceProbe {
  Completer<ProbeResult>? gate;
  @override
  Future<ProbeResult> probe(SourceHandle src) async => gate != null ? gate!.future : const ProbeOk(_info);
}

/// FEAT-001-T17: the pick screen on the real PickController with a fake bridge
/// and probe: launches, disabled camera, refusals, progress and Cancel, one
/// hand-off per accepted image, and goldens of the G3 design (no photos).
void main() {
  late FakeSystemPicker picker;
  late _Probe probe;
  late Directory tmp;
  late List<PickedImage> picked;

  setUp(() async {
    await getIt.reset();
    picker = FakeSystemPicker();
    probe = _Probe();
    picked = [];
    tmp = Directory.systemTemp.createTempSync('pick_screen');
    getIt
      ..registerSingleton<SystemPicker>(picker)
      ..registerSingleton<TempFiles>(TempFiles(tmp, folder: 'camera'), instanceName: 'camera')
      ..registerSingleton<SourceProbe>(probe)
      ..registerSingleton(PickOutcomeLog((_) {}));
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: ExactSizeApp(
        locale: const Locale('en'),
        home: PickScreen(onPicked: (context, image) {
          picked.add(image);
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('next step'))));
        }),
      ),
    ));
    await tester.pump();
  }

  Finder key(String label) => find.widgetWithText(FilledButton, label);
  bool enabled(WidgetTester tester, String label) => tester.widget<FilledButton>(key(label)).onPressed != null;

  testWidgets('one tap gives one launch; a second tap while the system UI is open is ignored', (tester) async {
    await pumpScreen(tester);
    await tester.tap(key('Take a photo'));
    await tester.pump();
    await tester.tap(key('Choose from gallery'));
    await tester.pump();
    expect(picker.launches, [PickSource.camera]);
  });

  testWidgets('no camera app: camera disabled, not hidden, with the reason; Semantics says unavailable', (tester) async {
    picker.camera = false;
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);
    expect(key('Take a photo'), findsOneWidget);
    expect(enabled(tester, 'Take a photo'), isFalse);
    expect(find.text('No camera app was found on this phone. Choose a photo from the gallery instead.'), findsOneWidget);
    expect(tester.getSemantics(key('Take a photo')), isSemantics(isButton: true, hasEnabledState: true, isEnabled: false));
    expect(enabled(tester, 'Choose from gallery'), isTrue);
    handle.dispose();
  });

  testWidgets('a refusal shows its message in a live region; both buttons stay enabled', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);
    picker.deliver(const NotOpenable(origin: PickOrigin.gallery));
    await tester.pump();
    await tester.pump();
    final text = find.text("We can't open that item. Choose a photo instead.");
    expect(text, findsOneWidget);
    expect(find.ancestor(of: text, matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true)),
        findsOneWidget);
    expect(enabled(tester, 'Take a photo'), isTrue);
    expect(enabled(tester, 'Choose from gallery'), isTrue);
    handle.dispose();
  });

  testWidgets('progress and Cancel appear at 500 ms, not before; Cancel returns to idle', (tester) async {
    probe.gate = Completer();
    await pumpScreen(tester);
    picker.deliver(const Picked(uri: _uri, origin: PickOrigin.gallery));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 499));
    expect(find.text('Opening your photo…'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Opening your photo…'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('Opening your photo…'), findsNothing);
    expect(enabled(tester, 'Take a photo'), isTrue);
    probe.gate!.complete(const ProbeOk(_info));
    await tester.pump();
    expect(picked, isEmpty);
  });

  testWidgets('an accepted image is handed on once; a newer one closes the later step first', (tester) async {
    await pumpScreen(tester);
    picker.deliver(const Picked(uri: _uri, origin: PickOrigin.gallery));
    await tester.pumpAndSettle();
    expect(picked, hasLength(1));
    expect(find.text('next step'), findsOneWidget);
    picker.signal(); // nothing new in the slot
    await tester.pumpAndSettle();
    expect(picked, hasLength(1));
    picker.deliver(const Picked(uri: _uri, origin: PickOrigin.share)); // e.g. a share mid-flow
    await tester.pumpAndSettle();
    expect(picked, hasLength(2));
    expect(find.text('next step'), findsOneWidget); // one later step, not two
  });

  group('goldens (G3 design, t16/pick_screen_design.md)', () {
    // Made on Windows, checked on Linux CI: see TolerantGoldenComparator.
    setUpAll(useTolerantGoldens);

    testWidgets('idle', (tester) async {
      await pumpScreen(tester);
      await expectLater(find.byType(PickScreen), matchesGoldenFile('goldens/pick_idle.png'));
    });

    testWidgets('no camera', (tester) async {
      picker.camera = false;
      await pumpScreen(tester);
      await expectLater(find.byType(PickScreen), matchesGoldenFile('goldens/pick_no_camera.png'));
    });

    testWidgets('message', (tester) async {
      await pumpScreen(tester);
      picker.deliver(const NotOpenable(origin: PickOrigin.gallery));
      await tester.pump();
      await tester.pump();
      await expectLater(find.byType(PickScreen), matchesGoldenFile('goldens/pick_message.png'));
    });
  });
}
