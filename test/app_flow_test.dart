import 'dart:io';
import 'dart:math';

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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/fake_system_picker.dart';

const _info = SourceInfo(
    rawWidth: 40, rawHeight: 30, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
const _uri = 'content://media/external/images/media/[PLACEHOLDER]';
const _camUri = 'content://com.exactsize.exact_size.camera/camera/[PLACEHOLDER]';

class _Probe extends SourceProbe {
  @override
  Future<ProbeResult> probe(SourceHandle src) async => const ProbeOk(_info);
}

/// FEAT-005-T01 (R2, OQ-T5): the target route releases the image on pop only
/// when that image is still current. A newer pick or share closes the route
/// with popUntil and must keep the new image and its camera file.
void main() {
  late FakeSystemPicker picker;
  late Directory tmp;
  late TempFiles files;

  setUp(() async {
    await getIt.reset();
    picker = FakeSystemPicker();
    tmp = Directory.systemTemp.createTempSync('app_flow');
    files = TempFiles(tmp, folder: 'camera');
    await files.dir.create();
    getIt
      ..registerSingleton<SystemPicker>(picker)
      ..registerSingleton<TempFiles>(files, instanceName: 'camera')
      ..registerSingleton<SourceProbe>(_Probe())
      ..registerSingleton(PickOutcomeLog((_) {}));
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  String cam() {
    final r = Random.secure();
    final name = '${List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}.jpg';
    File('${files.dir.path}/$name').writeAsBytesSync(List.filled(10, 1));
    return name;
  }

  bool exists(String name) => File('${files.dir.path}/$name').existsSync();

  /// Lets the controller's real file I/O finish (it runs outside the fake clock).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
    }
  }

  Future<void> deliver(WidgetTester tester, SystemPickResult r) async {
    picker.deliver(r);
    await settle(tester);
  }

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ExactSizeApp(locale: Locale('en'))));
    await tester.pump();
    return ProviderScope.containerOf(tester.element(find.byType(PickScreen)));
  }

  int targetRoutes(WidgetTester tester) => find.textContaining('Target step', skipOffstage: false).evaluate().length;

  testWidgets('(a) a new pick or share mid-flow keeps the new image and its camera file', (tester) async {
    final c = await pumpApp(tester);
    PickState st() => c.read(pickControllerProvider);

    final a = cam();
    await deliver(tester, Captured(uri: _camUri, fileName: a));
    final imageA = st().current;
    expect(imageA?.cameraFile, a);
    expect(targetRoutes(tester), 1);

    final b = cam();
    await deliver(tester, Captured(uri: _camUri, fileName: b));
    expect(st().current, isNotNull, reason: 'the popUntil pop must not release B');
    expect(st().current, isNot(same(imageA)));
    expect(st().current!.cameraFile, b);
    expect(exists(b), isTrue);
    expect(exists(a), isFalse, reason: 'PickController deletes the previous camera file');
    expect(targetRoutes(tester), 1);

    await deliver(tester, const Picked(uri: _uri, origin: PickOrigin.share));
    expect(st().current?.origin, PickOrigin.share);
    expect(exists(b), isFalse);
    expect(targetRoutes(tester), 1);
  });

  testWidgets('(b) Back on the target step releases the image and empties the camera folder', (tester) async {
    final c = await pumpApp(tester);
    final a = cam();
    await deliver(tester, Captured(uri: _camUri, fileName: a));
    expect(c.read(pickControllerProvider).current, isNotNull);

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await settle(tester);

    expect(c.read(pickControllerProvider).current, isNull);
    expect(files.dir.listSync(), isEmpty);
    expect(targetRoutes(tester), 0);
    expect(find.byType(PickScreen), findsOneWidget);
  });
}
