import 'dart:io';
import 'dart:math';

import 'package:exact_size/app.dart';
import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/presentation/crop_controller.dart';
import 'package:exact_size/features/crop/presentation/crop_screen.dart';
import 'package:exact_size/features/pick/data/system_picker.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/pick/presentation/pick_screen.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../test_support/fake_system_picker.dart';

/// FEAT-005-T17 (FR-1, FR-10, FR-14, NFR-2, NFR-4, NFR-7, NFR-9): the real app
/// flow pick → target → crop → compression on a pushed synthetic fixture. Only
/// the system picker is faked: a capture is copied into the camera folder and
/// delivered through the app's own FileProvider URI, as in pick_data_matrix.
/// en, ar and hi at text scale 2.0, one screenshot per state (empty, error,
/// valid; saved by the driver under build/target_flow/). App storage holds no
/// new file afterwards except the accepted capture.
///   DEVICE=[id] flutter drive --driver test_driver/push_fixtures_driver.dart \
///     --target integration_test/target_flow.dart -d [id]
const _authority = 'content://com.exactsize.exact_size.camera';
const _fixture = 'chart_diagonal.png'; // 400×300, synthetic

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late Directory cache;
  late Directory fixtures;
  late TempFiles camera;
  late FakeSystemPicker picker;
  late Set<String> baseline;
  var surfaceReady = false;

  Set<String> storage() => {
        for (final root in [cache, support])
          if (root.existsSync())
            for (final f in root.listSync(recursive: true).whereType<File>())
              if (!f.path.startsWith(fixtures.path) && !f.path.endsWith('profileInstalled')) f.path,
      };

  String capture() {
    final r = Random.secure();
    final name = '${List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}.png';
    File('${fixtures.path}/$_fixture').copySync('${camera.dir.path}/$name');
    return name;
  }

  setUpAll(() async {
    support = await getApplicationSupportDirectory();
    cache = await getTemporaryDirectory();
    fixtures = Directory('${support.path}/fixtures');
    for (var i = 0; i < 600 && !File('${fixtures.path}/.ready').existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(File('${fixtures.path}/.ready').existsSync(), isTrue, reason: 'fixtures were not pushed');
    await getIt.reset();
    await configureDependencies();
    picker = FakeSystemPicker();
    getIt
      ..unregister<SystemPicker>()
      ..registerSingleton<SystemPicker>(picker);
    camera = getIt<TempFiles>(instanceName: 'camera');
    await camera.dir.create(recursive: true);
    await camera.sweep();
    await getIt<TempFiles>().sweep();
    baseline = storage();
  });

  /// Pumps until [done] holds, with real time passing (live binding).
  Future<void> waitFor(WidgetTester tester, bool Function() done, String what, {int seconds = 30}) async {
    for (var i = 0; i < seconds * 10 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    }
    expect(done(), isTrue, reason: what);
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    if (!surfaceReady) {
      await binding.convertFlutterSurfaceToImage();
      surfaceReady = true;
    }
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  Finder field(int i) => find.byType(TextField).at(i);
  String text(WidgetTester tester, int i) => tester.widget<TextField>(field(i)).controller!.text;

  Future<void> type(WidgetTester tester, List<String> values) async {
    for (final (i, v) in values.indexed) {
      await tester.enterText(field(i), v);
    }
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    final button = find.byType(FilledButton).last;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
  }

  for (final locale in ['en', 'ar', 'hi']) {
    testWidgets('$locale at 200%: target, crop, compression; Back keeps values; a new photo keeps them', (tester) async {
      surfaceReady = false; // the binding reverts the image surface after each test
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      // A fresh container per locale: a fresh app start (AC-1.1).
      await tester.pumpWidget(ProviderScope(key: UniqueKey(), child: ExactSizeApp(locale: Locale(locale))));
      await tester.pumpAndSettle();
      final c = ProviderScope.containerOf(tester.element(find.byType(PickScreen)));

      final first = capture();
      picker.deliver(Captured(uri: '$_authority/camera/$first', fileName: first));
      await waitFor(tester, () => find.byType(TargetScreen).evaluate().isNotEmpty, 'target step opens');
      expect([for (var i = 0; i < 4; i++) text(tester, i)], everyElement(''), reason: 'empty on a fresh start');
      await shot(tester, '${locale}_empty');

      await type(tester, ['1.5', '0', 'x', '1']);
      await tapContinue(tester);
      await tester.pumpAndSettle();
      expect(find.byType(CropScreen), findsNothing, reason: 'nothing handed on');
      expect(find.byIcon(Icons.error_outline), findsWidgets);
      await tester.scrollUntilVisible(field(0), -100, scrollable: find.byType(Scrollable).first);
      await shot(tester, '${locale}_error');

      await type(tester, ['300', '300', '', '60']);
      await shot(tester, '${locale}_valid');
      await tapContinue(tester);
      await waitFor(tester, () => find.byType(CropScreen).evaluate().isNotEmpty, 'crop opens after the decode');
      expect(c.read(cropControllerProvider)!.target.height, 300);

      // Back from crop keeps the values (AC-8.1); a changed size starts the crop again.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect([for (var i = 0; i < 4; i++) text(tester, i)], ['300', '300', '', '60']);
      await type(tester, ['400', '200', '', '60']);
      await tapContinue(tester);
      await waitFor(tester, () => find.byType(CropScreen).evaluate().isNotEmpty, 'crop reopens');
      expect(c.read(cropControllerProvider)!.target.height, 200);

      // Continue on crop: real render, buffer moves to FEAT-004, compression finishes READY.
      final cropContinue = find.descendant(of: find.byType(CropScreen), matching: find.byType(FilledButton)).last;
      await tester.ensureVisible(cropContinue);
      await tester.pumpAndSettle();
      await tester.tap(cropContinue);
      await waitFor(tester, () => c.read(compressionControllerProvider) is CompressionDone, 'compression finishes',
          seconds: 60);
      final done = c.read(compressionControllerProvider) as CompressionDone;
      expect(done.result, isA<CompressionSuccess>(), reason: 'READY on the stand-in');
      expect(done.maxKb, 60);

      // Leaving the stand-in drops the unexported result and its temp file (FR-14).
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await waitFor(tester, () => c.read(compressionControllerProvider) is CompressionIdle, 'result dropped');
      expect(storage().difference(baseline), {'${camera.dir.path}/$first'}, reason: 'only the accepted capture');

      // A new photo: values kept, errors hidden (FR-10).
      tester.state<NavigatorState>(find.byType(Navigator)).pop(); // back to the target step
      await tester.pumpAndSettle();
      await type(tester, ['0', '200', '', '60']);
      await tapContinue(tester);
      await tester.pumpAndSettle();
      final second = capture();
      picker.deliver(Captured(uri: '$_authority/camera/$second', fileName: second));
      await waitFor(tester, () => File('${camera.dir.path}/$first').existsSync() == false, 'previous capture deleted');
      await tester.pumpAndSettle();
      expect(find.byType(TargetScreen), findsOneWidget);
      expect(text(tester, 1), '200');
      expect(find.byIcon(Icons.error_outline), findsNothing, reason: 'errors hidden for the new photo');

      // Back from the target step: start-over, the camera folder is emptied.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await waitFor(tester, () => storage().difference(baseline).isEmpty, 'camera folder emptied');
    });
  }
}
