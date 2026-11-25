import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/app_flow.dart';
import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart' show OutputFormat;
import 'package:exact_size/features/compression/domain/pixel_buffer.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/pick/data/pick_outcome_log.dart';
import 'package:exact_size/features/pick/data/system_picker.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/crop/presentation/crop_controller.dart';
import 'package:exact_size/features/crop/presentation/crop_screen.dart';
import 'package:exact_size/features/export/presentation/export_panel.dart';
import 'package:exact_size/features/export/presentation/result_screen.dart';
import 'package:exact_size/features/pick/presentation/pick_controller.dart';
import 'package:exact_size/features/pick/presentation/pick_screen.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/fake_system_picker.dart';
import '../test_support/test_pixels.dart';

const _info = SourceInfo(
    rawWidth: 40, rawHeight: 30, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
const _uri = 'content://media/external/images/media/[PLACEHOLDER]';
const _camUri = 'content://com.exactsize.exact_size.camera/camera/[PLACEHOLDER]';

class _Probe extends SourceProbe {
  @override
  Future<ProbeResult> probe(SourceHandle src) async => const ProbeOk(_info);
}

/// Hands out pre-made previews, or waits on [gate], or answers [error].
/// Records starts and cancels instead of compressing (T11).
class _FakeCompression extends CompressionController {
  final requests = <CompressionRequest>[];
  var cancels = 0;
  @override
  Future<void> start(CompressionRequest request) async {
    requests.add(request);
    state = CompressionRunning(pass: 0, maxPasses: 8, minKb: request.minKb, maxKb: request.maxKb);
  }

  @override
  Future<void> cancel() async => cancels++;
}

class _Decoder implements PreviewDecoder {
  final previews = <ui.Image>[];
  final handed = <ui.Image>[];
  Completer<PreviewResult>? gate;
  Reason? error;
  @override
  bool get debugForceOutOfMemory => false;
  @override
  Future<PreviewResult> decode(SourceHandle src, SourceInfo info, {int maxSide = 2048}) async {
    if (gate != null) return gate!.future;
    if (error != null) return PreviewErr(error!);
    final image = previews.removeAt(0);
    handed.add(image);
    return PreviewOk(image, 1);
  }
}

/// FEAT-005-T01 (R2, OQ-T5): the target route releases the image on pop only
/// when that image is still current. A newer pick or share closes the route
/// with popUntil and must keep the new image and its camera file.
void main() {
  late FakeSystemPicker picker;
  late Directory tmp;
  late TempFiles files;
  late _Decoder decoder;

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
    decoder = _Decoder();
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

  Future<ProviderContainer> pumpApp(WidgetTester tester, {List<Override> overrides = const []}) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [previewDecoderProvider.overrideWithValue(decoder), ...overrides],
      child: const ExactSizeApp(locale: Locale('en')),
    ));
    await tester.pump();
    return ProviderScope.containerOf(tester.element(find.byType(PickScreen)));
  }

  int targetRoutes(WidgetTester tester) => find.byType(TargetScreen, skipOffstage: false).evaluate().length;

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

  group('crop step (T10)', () {
    const spec = TargetSpec(width: 30, height: 30, maxKb: 50, format: OutputFormat.jpeg);

    Future<ui.Image> image(WidgetTester tester) async => (await tester.runAsync(() {
          final r = ui.PictureRecorder();
          Canvas(r).drawRect(const Rect.fromLTWH(0, 0, 40, 30), Paint()..color = const Color(0xFF8899AA));
          return r.endRecording().toImage(40, 30);
        }))!;

    /// App with one gallery image on the target step; returns the container.
    Future<ProviderContainer> onTargetStep(WidgetTester tester, {List<Override> overrides = const []}) async {
      final c = await pumpApp(tester, overrides: overrides);
      await deliver(tester, const Picked(uri: _uri, origin: PickOrigin.gallery));
      return c;
    }

    void openCrop(WidgetTester tester, ProviderContainer c, TargetSpec s) => openCropStep(
        tester.element(find.byType(TargetScreen)), c.read(pickControllerProvider).current!, s);

    testWidgets('progress at 500 ms, not 499; a decode error shows the reason; Choose another releases once',
        (tester) async {
      decoder.gate = Completer();
      final c = await onTargetStep(tester);
      final picked = c.read(pickControllerProvider).current;
      openCrop(tester, c, spec);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 499));
      expect(find.text('Opening your photo…'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Opening your photo…'), findsOneWidget);

      decoder.gate!.complete(const PreviewErr(Reason.corruptInput));
      await tester.pumpAndSettle();
      expect(find.text('Opening your photo…'), findsNothing);
      expect(find.text("We can't read this file. Choose another photo."), findsOneWidget);

      final states = <PickState>[];
      c.listen(pickControllerProvider, (_, next) => states.add(next));
      await tester.tap(find.text('Choose another photo'));
      await settle(tester);
      expect(states.where((s) => s.current == null), hasLength(1), reason: 'one release, none from the T01 guard');
      expect(c.read(pickControllerProvider).current, isNull);
      expect(picked, isNotNull);
      expect(c.read(cropControllerProvider), isNull);
      expect(find.byType(PickScreen), findsOneWidget);
      expect(targetRoutes(tester), 0);
    });

    testWidgets('the preview is disposed when the crop route goes', (tester) async {
      decoder.previews.add(await image(tester));
      final c = await onTargetStep(tester);
      openCrop(tester, c, spec);
      await tester.pumpAndSettle();
      expect(find.byType(CropScreen), findsOneWidget);
      expect(decoder.handed.single.debugDisposed, isFalse);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(decoder.handed.single.debugDisposed, isTrue);
      expect(c.read(pickControllerProvider).current, isNotNull, reason: 'Back from crop keeps the photo');
    });

    testWidgets('re-entry with the same spec keeps the crop; a changed spec starts it again', (tester) async {
      for (var i = 0; i < 3; i++) {
        decoder.previews.add(await image(tester));
      }
      final c = await onTargetStep(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator));

      openCrop(tester, c, spec);
      await tester.pumpAndSettle();
      final initial = c.read(cropControllerProvider)!.crop;
      c.read(cropControllerProvider.notifier).drag(-6, 0);
      final moved = c.read(cropControllerProvider)!.crop;
      expect(moved, isNot(initial));
      nav.pop();
      await tester.pumpAndSettle();

      openCrop(tester, c, spec);
      await tester.pumpAndSettle();
      expect(c.read(cropControllerProvider)!.crop, moved);
      nav.pop();
      await tester.pumpAndSettle();

      openCrop(tester, c, const TargetSpec(width: 40, height: 20, maxKb: 50, format: OutputFormat.jpeg));
      await tester.pumpAndSettle();
      expect(c.read(cropControllerProvider)!.target.height, 20);
      expect(c.read(cropControllerProvider)!.crop, isNot(moved));
    });

    testWidgets('Continue hands the same buffer to compression once with the spec; leaving the running result screen cancels (T11, FEAT-007-T19)',
        (tester) async {
      decoder.previews.add(await image(tester));
      final compression = _FakeCompression();
      final rendered = <PixelBuffer>[];
      final c = await onTargetStep(tester, overrides: [
        compressionControllerProvider.overrideWith(() => compression),
        cropRenderProvider.overrideWithValue((req, cancel) async {
          final p = TestPixels(req.target.width, req.target.height, 3, Uint8List(req.target.width * req.target.height * 3),
              hasTransparency: false);
          rendered.add(p);
          return RenderOk(p);
        }),
      ]);
      const withMin = TargetSpec(width: 30, height: 30, minKb: 20, maxKb: 50, format: OutputFormat.png);
      openCrop(tester, c, withMin);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // route transition; the result spinner never settles

      expect(compression.requests, hasLength(1));
      final r = compression.requests.single;
      expect(r.pixels, same(rendered.single), reason: 'the buffer moves, not copied (ADR-003)');
      expect((r.minKb, r.maxKb, r.format), (20, 50, OutputFormat.png));
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byType(ExportPanel), findsNothing, reason: 'no Save or Share while running (FR-1)');

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(compression.cancels, 1);
      expect(compression.requests, hasLength(1));
      expect(find.byType(CropScreen), findsOneWidget, reason: 'back on crop');
    });
  });
}
