import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/domain/pixel_buffer.dart';
import 'package:exact_size/features/crop/data/crop_renderer.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/presentation/recents_guard.dart';
import '../../../../test_support/test_pixels.dart';
import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_reducers.dart' show Edge;
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/presentation/crop_canvas.dart';
import 'package:exact_size/features/crop/presentation/crop_controller.dart';
import 'package:exact_size/features/crop/presentation/crop_messages.dart';
import 'package:exact_size/features/crop/presentation/crop_screen.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction, SemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

SourceInfo source(int w, int h, {bool alpha = false}) => SourceInfo(
      rawWidth: w,
      rawHeight: h,
      mime: alpha ? 'image/png' : 'image/jpeg',
      exifOrientation: 1,
      isAnimated: false,
      hasAlpha: alpha,
      decodePath: DecodePath.region,
    );

/// Synthetic preview: a flat colour, sized like a sampled decode.
Future<ui.Image> preview(WidgetTester tester, int w, int h) async => (await tester.runAsync(() {
      final r = ui.PictureRecorder();
      Canvas(r).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = const Color(0xFF8899AA));
      return r.endRecording().toImage(w, h);
    }))!;

final class FakeRecents implements RecentsBinding {
  @override
  int get sdkInt => 34;
  final calls = <bool>[];
  @override
  void setRecentsScreenshotEnabled(bool enabled) => calls.add(enabled);
}

/// Instant fake render: an exact W×H buffer, or [result] when given.
CropRenderFn fakeRender({List<RenderRequest>? log, RenderResult? result, Duration delay = Duration.zero}) =>
    (req, cancel) async {
      log?.add(req);
      if (delay > Duration.zero) {
        final end = DateTime.now().add(delay);
        while (DateTime.now().isBefore(end) && !cancel.isCancelled) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        if (cancel.isCancelled) return const RenderErr(Reason.cancelled);
      }
      return result ??
          RenderOk(TestPixels(req.target.width, req.target.height, 3,
              Uint8List(req.target.width * req.target.height * 3), hasTransparency: false));
    };

/// Pumps the crop screen on a 360×800 dp phone; returns the provider container.
Future<ProviderContainer> pumpScreen(WidgetTester tester, SourceInfo info, Target target,
    {void Function(PixelBuffer)? onContinue,
    VoidCallback? onChooseAnother,
    Locale? locale,
    CropRenderFn? render,
    RecentsBinding? recents,
    double textScale = 1,
    bool pushed = false}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final image = await preview(tester, (info.rawWidth / 4).ceil(), (info.rawHeight / 4).ceil());
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: ExactSizeApp(
      locale: locale ?? const Locale('en'),
      home: Builder(builder: (context) {
        final screen = MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: CropScreen(
            src: SourceHandle('file:///synthetic/photo.jpg'),
            render: render ?? fakeRender(),
            recentsBinding: recents ?? FakeRecents(),
            preview: image,
            info: info,
            target: target,
            onContinue: onContinue ?? (_) {},
            onChooseAnother: onChooseAnother ?? () {},
          ),
        );
        if (!pushed) return screen;
        // Pushed as a second route, so the app bar shows Back.
        return TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen)),
          child: const Text('open'),
        );
      }),
    ),
  ));
  await tester.pumpAndSettle();
  if (pushed) {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
  return container;
}

Rect canvasFrame(WidgetTester tester, Target t) =>
    CropFrameLayout.of(tester.getSize(find.byType(CropCanvas)), t).frame;

void main() {
  group('T23 canvas', () {
    test('frame layout: square for 300×300, ≥ 24 dp margins', () {
      final l = CropFrameLayout.of(const Size(360, 500), const Target(300, 300));
      expect(l.frame.width, closeTo(l.frame.height, 1e-9));
      expect(l.frame.left, greaterThanOrEqualTo(24));
      expect(l.thin, isFalse);
    });

    testWidgets('4000×3000 → 300×300: square frame over the centred area', (tester) async {
      final c = await pumpScreen(tester, source(4000, 3000), const Target(300, 300));
      final f = canvasFrame(tester, const Target(300, 300));
      expect(f.width, closeTo(f.height, 1e-9));
      final r = c.read(cropControllerProvider)!.cropRect;
      expect((r.x, r.y, r.w, r.h), (500, 0, 3000, 3000));
    });

    testWidgets('3000×4000 → 300×80 on 360 dp: strip fully visible and ≥ 48 dp high', (tester) async {
      await pumpScreen(tester, source(3000, 4000), const Target(300, 80));
      final canvas = tester.getRect(find.byType(CropCanvas));
      final f = canvasFrame(tester, const Target(300, 80)).shift(canvas.topLeft);
      expect(f.height, greaterThanOrEqualTo(48));
      expect(canvas.contains(f.topLeft) && canvas.contains(f.bottomRight), isTrue);
      expect(find.textContaining('very thin'), findsNothing);
    });

    testWidgets('1000:10 shows the full-width thin frame and the hint', (tester) async {
      await pumpScreen(tester, source(3000, 4000), const Target(1000, 10));
      final l = CropFrameLayout.of(tester.getSize(find.byType(CropCanvas)), const Target(1000, 10));
      expect(l.thin, isTrue);
      expect(l.frame.width, 360 - 2 * CropFrameLayout.margin);
      expect(find.textContaining('very thin'), findsOneWidget);
    });

    testWidgets('a drag far beyond the edge stops at the edge', (tester) async {
      final c = await pumpScreen(tester, source(4000, 3000), const Target(300, 300));
      await tester.drag(find.byType(CropCanvas), const Offset(-2000, 0));
      await tester.pumpAndSettle();
      final r = c.read(cropControllerProvider)!.cropRect;
      expect(r.x + r.w, 4000, reason: 'photo dragged left: crop at the right edge');
      await tester.drag(find.byType(CropCanvas), const Offset(4000, 0));
      await tester.pumpAndSettle();
      expect(c.read(cropControllerProvider)!.cropRect.x, 0);
    });

    testWidgets('pinch zooms in; one gesture holds until fingers lift', (tester) async {
      final c = await pumpScreen(tester, source(4000, 3000), const Target(300, 300));
      final before = c.read(cropControllerProvider)!.crop.cw;
      final centre = tester.getCenter(find.byType(CropCanvas));
      final a = await tester.startGesture(centre - const Offset(20, 0));
      final b = await tester.startGesture(centre + const Offset(20, 0), pointer: 2);
      for (var i = 0; i < 5; i++) {
        await a.moveBy(const Offset(-10, 0));
        await b.moveBy(const Offset(10, 0));
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(c.read(cropControllerProvider)!.crop.cw, lessThan(before));
    });

    testWidgets('checkerboard only under transparent sources', (tester) async {
      const grey = Color(0xFFD0D0D0);
      final checker = paints..something((m, args) => m == #drawRect && (args[1] as Paint).color.toARGB32() == grey.toARGB32());
      await pumpScreen(tester, source(1600, 900, alpha: true), const Target(300, 80));
      final canvasPaint = find.descendant(of: find.byType(CropCanvas), matching: find.byType(CustomPaint));
      expect(tester.renderObject(canvasPaint.first), checker);
      await pumpScreen(tester, source(1600, 900), const Target(300, 80));
      expect(tester.renderObject(canvasPaint.first), isNot(checker));
    });
  });

  group('T24 semantics, Centre/Reset, upscale notice and dialog', () {
    testWidgets('crop area exposes the 8 actions; each equals the controller result', (tester) async {
      final handle = tester.ensureSemantics();
      final info = source(4000, 3000);
      const t = Target(300, 300);
      final c = await pumpScreen(tester, info, t);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^Crop area, zoom')));
      final actions = {
        for (final id in node.getSemanticsData().customSemanticsActionIds!)
          CustomSemanticsAction.getAction(id)!.label!: id,
      };
      expect(actions.keys, unorderedEquals(['Move left', 'Move right', 'Move up', 'Move down', 'Zoom in', 'Zoom out', 'Centre', 'Reset']));

      final reference = ProviderContainer();
      addTearDown(reference.dispose);
      reference.read(cropControllerProvider.notifier).start(info, t);
      final byLabel = {
        'Move left': CropAction.moveLeft,
        'Move right': CropAction.moveRight,
        'Move up': CropAction.moveUp,
        'Move down': CropAction.moveDown,
        'Zoom in': CropAction.zoomIn,
        'Zoom out': CropAction.zoomOut,
        'Centre': CropAction.centre,
        'Reset': CropAction.reset,
      };
      // Zoom in first so every move has room.
      for (final label in ['Zoom in', ...byLabel.keys]) {
        final id = tester.getSemantics(find.bySemanticsLabel(RegExp('^Crop area, zoom'))).id;
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(id, SemanticsAction.customAction, actions[label]);
        await tester.pump();
        reference.read(cropControllerProvider.notifier).perform(byLabel[label]!);
        expect(c.read(cropControllerProvider)!.cropRect, reference.read(cropControllerProvider)!.cropRect, reason: label);
      }
      handle.dispose();
    });

    testWidgets('Centre and Reset are labelled and at least 48 dp', (tester) async {
      await pumpScreen(tester, source(4000, 3000), const Target(300, 300));
      for (final label in ['Centre', 'Reset']) {
        final size = tester.getSize(find.widgetWithText(TextButton, label));
        expect(size.width >= 48 && size.height >= 48, isTrue, reason: label);
      }
    });

    testWidgets('200×200 at 300×300: notice with icon and text, Continue works', (tester) async {
      PixelBuffer? got;
      await pumpScreen(tester, source(200, 200), const Target(300, 300), onContinue: (s) => got = s);
      expect(find.textContaining('smaller than'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect((got?.width, got?.height), (300, 300));
    });

    testWidgets('above 2.0 Continue asks first; both choices work', (tester) async {
      var continued = 0, other = 0;
      await pumpScreen(tester, source(100, 100), const Target(300, 300),
          onContinue: (_) => continued++, onChooseAnother: () => other++);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue anyway'));
      await tester.pumpAndSettle();
      expect((continued, other), (1, 0));
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose another photo'));
      await tester.pumpAndSettle();
      expect((continued, other), (1, 1));
    });

    testWidgets('zooming across 1.0 shows the notice and announces once', (tester) async {
      final c = await pumpScreen(tester, source(400, 400), const Target(300, 300));
      expect(find.textContaining('smaller than'), findsNothing);
      await tester.tap(find.byTooltip('Zoom in')); // 400 → 320 px: 0.94
      await tester.pumpAndSettle();
      expect(find.textContaining('smaller than'), findsNothing);
      await tester.tap(find.byTooltip('Zoom in')); // 256 px: 1.17
      await tester.pumpAndSettle();
      expect(find.textContaining('smaller than'), findsOneWidget);
      expect(c.read(cropControllerProvider)!.announcements.whereType<UpscaleAnnouncement>(), hasLength(1));
      final live = find.ancestor(of: find.textContaining('smaller than'), matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.liveRegion ?? false)));
      expect(live, findsOneWidget);
    });
  });

  group('T25 Continue flow', () {
    /// Fake render that takes [ms] on the test clock and honours cancel.
    CropRenderFn slowRender(int ms, List<RenderRequest> log) => (req, cancel) async {
          log.add(req);
          for (var t = 0; t < ms && !cancel.isCancelled; t += 10) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          if (cancel.isCancelled) return const RenderErr(Reason.cancelled);
          return fakeRender()(req, cancel);
        };

    testWidgets('a double tap on Continue starts one render', (tester) async {
      final log = <RenderRequest>[];
      await pumpScreen(tester, source(4000, 3000), const Target(300, 300), render: slowRender(100, log));
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(log, hasLength(1));
    });

    testWidgets('progress after 500 ms; cancel returns with nothing handed off', (tester) async {
      final log = <RenderRequest>[];
      var handed = 0;
      await pumpScreen(tester, source(4000, 3000), const Target(300, 300),
          render: slowRender(5000, log), onContinue: (_) => handed++);
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Cancelled. Your photo was not changed.'), findsOneWidget);
      expect(handed, 0);
    });

    testWidgets('each failure shows its message and one next action', (tester) async {
      final m = CropMessages(lookupAppLocalizations(const Locale('en')));
      for (final reason in Reason.values.where((r) => r != Reason.cancelled)) {
        var other = 0;
        await pumpScreen(tester, source(4000, 3000), const Target(300, 300),
            render: fakeRender(result: RenderErr(reason)), onChooseAnother: () => other++);
        await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
        await tester.pumpAndSettle();
        expect(find.text(m.reason(reason)), findsOneWidget, reason: reason.code);
        final actions = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton));
        expect(actions, findsOneWidget, reason: reason.code);
        await tester.tap(actions);
        await tester.pumpAndSettle();
        expect(other, reason == Reason.invalidTargetDimensions ? 0 : 1, reason: reason.code);
      }
    });

    testWidgets('animated source shows the first-frame notice', (tester) async {
      const info = SourceInfo(
          rawWidth: 400, rawHeight: 400, mime: 'image/gif', exifOrientation: 1, isAnimated: true, hasAlpha: false, decodePath: DecodePath.full);
      await pumpScreen(tester, info, const Target(300, 300));
      expect(find.textContaining('animated'), findsOneWidget);
    });

    testWidgets('a new target changes the frame ratio and the output size', (tester) async {
      final log = <RenderRequest>[];
      PixelBuffer? got;
      final info = source(4000, 3000);
      await pumpScreen(tester, info, const Target(300, 300), render: fakeRender(log: log), onContinue: (p) => got = p);
      final c = await pumpScreen(tester, info, const Target(300, 80), render: fakeRender(log: log), onContinue: (p) => got = p);
      final f = canvasFrame(tester, const Target(300, 80));
      expect(f.width / f.height, closeTo(300 / 80, 1e-9));
      expect(c.read(cropControllerProvider)!.target, const Target(300, 80));
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(log.single.target, const Target(300, 80));
      expect((got?.width, got?.height), (300, 80));
    });

    testWidgets('the screen is hidden from the recents thumbnail (RecentsGuard)', (tester) async {
      final recents = FakeRecents();
      await pumpScreen(tester, source(4000, 3000), const Target(300, 300), recents: recents);
      expect(recents.calls, [false]);
    });
  });

  group('T26 RTL, 200% text, rotation, split-screen', () {
    testWidgets('Arabic: app bar, control rows and Continue mirror; canvas and moves do not', (tester) async {
      double cx(Finder f) => tester.getCenter(f).dx;
      final info = source(4000, 3000);
      const t = Target(300, 300);
      final en = await pumpScreen(tester, info, t, pushed: true);
      final enRect = en.read(cropControllerProvider)!.cropRect;
      await tester.pumpWidget(const SizedBox()); // fresh navigator
      final ar = await pumpScreen(tester, info, t, pushed: true, locale: const Locale('ar'));
      final l = lookupAppLocalizations(const Locale('ar'));
      expect(Directionality.of(tester.element(find.byType(CropScreen))), TextDirection.rtl);
      // Mirrored: Back on the right of the title, Continue before the print, rotate group order.
      expect(cx(find.byType(BackButton)), greaterThan(cx(find.byType(AppBar))));
      expect(cx(find.widgetWithText(FilledButton, l.cropButtonContinue)), lessThan(cx(find.byType(CropPrint))));
      expect(cx(find.byTooltip(l.cropButtonRotateCounterclockwise)), greaterThan(cx(find.byTooltip(l.cropButtonZoomIn))));
      // Physical: move arrows stay left-to-right, the crop is the same rect, a move goes physically left.
      final moves = [l.cropButtonMoveLeft, l.cropButtonMoveUp, l.cropButtonMoveDown, l.cropButtonMoveRight]
          .map((m) => cx(find.byTooltip(m)))
          .toList();
      expect(moves, orderedEquals([...moves]..sort()));
      expect(ar.read(cropControllerProvider)!.cropRect, enRect);
      await tester.tap(find.byTooltip(l.cropButtonZoomIn));
      await tester.pump();
      final before = ar.read(cropControllerProvider)!.cropRect.x;
      await tester.tap(find.byTooltip(l.cropButtonMoveLeft));
      await tester.pump();
      expect(ar.read(cropControllerProvider)!.cropRect.x, lessThan(before));
    });

    testWidgets('200% text: every control reachable by scrolling; frame fully visible', (tester) async {
      var handed = 0;
      await pumpScreen(tester, source(4000, 3000), const Target(300, 300), textScale: 2, onContinue: (_) => handed++);
      final canvas = tester.getRect(find.byType(CropCanvas));
      final f = canvasFrame(tester, const Target(300, 300)).shift(canvas.topLeft);
      expect(canvas.top >= 0 && canvas.bottom <= 800, isTrue);
      expect(canvas.contains(f.topLeft) && canvas.contains(f.bottomRight - const Offset(1, 1)), isTrue);
      expect(f.shortestSide, greaterThanOrEqualTo(48));
      for (final label in ['Rotate clockwise', 'Zoom in', 'Move right']) {
        await tester.ensureVisible(find.byTooltip(label));
      }
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Reset'));
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(handed, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rotation and split-screen keep the cropRect', (tester) async {
      final c = await pumpScreen(tester, source(4000, 3000), const Target(300, 80));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.tap(find.byTooltip('Move up'));
      await tester.pumpAndSettle();
      final rect = c.read(cropControllerProvider)!.cropRect;
      for (final size in [const Size(800, 360), const Size(360, 380), const Size(360, 800)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(c.read(cropControllerProvider)!.cropRect, rect, reason: '$size');
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });
  });

  group('T27 corner handles', () {
    Finder handle(String corner) =>
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Resize crop, $corner corner');
    Offset at(WidgetTester tester, String corner) => tester.getCenter(handle(corner));

    testWidgets('300×80: four 48 dp handle areas that do not overlap', (tester) async {
      await pumpScreen(tester, source(3000, 4000), const Target(300, 80));
      final rects = [for (final c in ['top-left', 'top-right', 'bottom-left', 'bottom-right']) tester.getRect(handle(c))];
      for (final r in rects) {
        expect(r.width >= 48 && r.height >= 48, isTrue);
      }
      for (var i = 0; i < 4; i++) {
        for (var j = i + 1; j < 4; j++) {
          final o = rects[i].intersect(rects[j]);
          expect(o.width <= 0 || o.height <= 0, isTrue, reason: '$i/$j overlap');
        }
      }
    });

    testWidgets('dragging out past the image edge stops there, opposite corner fixed', (tester) async {
      final c = await pumpScreen(tester, source(4000, 3000), const Target(300, 300));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      final before = c.read(cropControllerProvider)!.cropRect;
      await tester.dragFrom(at(tester, 'top-left'), const Offset(-400, -400));
      await tester.pumpAndSettle();
      final r = c.read(cropControllerProvider)!.cropRect;
      expect((r.x + r.w, r.y + r.h), (before.x + before.w, before.y + before.h));
      expect(r.w, greaterThan(before.w));
      expect(r.x == 0 || r.y == 0, isTrue, reason: 'stopped at an image edge');
    });

    testWidgets('shrinking stops at the minimum and updates the notice', (tester) async {
      final c = await pumpScreen(tester, source(400, 400), const Target(300, 300));
      expect(find.textContaining('smaller than'), findsNothing);
      await tester.dragFrom(at(tester, 'bottom-right'), const Offset(-600, -600));
      await tester.pumpAndSettle();
      expect(c.read(cropControllerProvider)!.crop.cw, CropMath.minWidth(400, 400, const Target(300, 300)));
      expect(find.textContaining('smaller than'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('release re-fits the view and leaves the cropRect unchanged; pinch is ignored', (tester) async {
      final c = await pumpScreen(tester, source(4000, 3000), const Target(300, 300));
      final fitted = tester.getRect(handle('top-left'));
      final g = await tester.startGesture(at(tester, 'bottom-right'));
      await g.moveBy(const Offset(-40, -40));
      await g.moveBy(const Offset(-40, -40));
      await tester.pump();
      expect(tester.getRect(handle('top-left')), fitted, reason: 'opposite corner stays put while dragging');
      final fittedBr = canvasFrame(tester, const Target(300, 300)).shift(tester.getTopLeft(find.byType(CropCanvas))).bottomRight;
      expect(tester.getCenter(handle('bottom-right')), isNot(fittedBr), reason: 'the frame follows the finger');
      final during = c.read(cropControllerProvider)!.crop;
      // A second finger joins and spreads: ignored while the handle holds.
      final g2 = await tester.startGesture(tester.getCenter(find.byType(CropCanvas)), pointer: 9);
      await g2.moveBy(const Offset(80, 60));
      await tester.pump();
      expect(c.read(cropControllerProvider)!.crop, during);
      await g2.up();
      await g.up();
      await tester.pumpAndSettle();
      expect(c.read(cropControllerProvider)!.crop, during);
      final f = canvasFrame(tester, const Target(300, 300)).shift(tester.getTopLeft(find.byType(CropCanvas)));
      expect(tester.getCenter(handle('bottom-right')), f.bottomRight, reason: 're-fitted to the frame');
    });

    testWidgets('TalkBack labels; handles stay at physical corners in Arabic', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpScreen(tester, source(4000, 3000), const Target(300, 300), locale: const Locale('ar'));
      final l = lookupAppLocalizations(const Locale('ar'));
      Offset atAr(String corner) {
        final label = l.cropHandleLabel(corner);
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: corner);
        return tester.getCenter(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label));
      }
      for (final c in ['topLeft', 'topRight', 'bottomLeft', 'bottomRight']) {
        atAr(c);
      }
      expect(atAr('topLeft').dx, lessThan(atAr('topRight').dx));
      expect(atAr('topLeft').dy, lessThan(atAr('bottomLeft').dy));
      semantics.dispose();
    });
  });

  group('T28 rotate, move and zoom buttons', () {
    const buttons = {
      'Rotate clockwise': CropAction.rotateClockwise,
      'Rotate counter-clockwise': CropAction.rotateCounterclockwise,
      'Zoom in': CropAction.zoomIn,
      'Zoom out': CropAction.zoomOut,
      'Move left': CropAction.moveLeft,
      'Move right': CropAction.moveRight,
      'Move up': CropAction.moveUp,
      'Move down': CropAction.moveDown,
    };

    testWidgets('each button equals its reducer; all are labelled and ≥ 48 dp', (tester) async {
      final info = source(4000, 3000);
      const t = Target(300, 80);
      final c = await pumpScreen(tester, info, t);
      final reference = ProviderContainer();
      addTearDown(reference.dispose);
      reference.read(cropControllerProvider.notifier).start(info, t);
      for (final label in ['Zoom in', 'Zoom in', ...buttons.keys]) {
        final f = find.byTooltip(label);
        final size = tester.getSize(f);
        expect(size.width >= 48 && size.height >= 48, isTrue, reason: label);
        await tester.tap(f);
        await tester.pumpAndSettle();
        reference.read(cropControllerProvider.notifier).perform(buttons[label]!);
        expect(c.read(cropControllerProvider)!.cropRect, reference.read(cropControllerProvider)!.cropRect, reason: label);
      }
    });

    testWidgets('long-press repeats a move until released and stops at the edge', (tester) async {
      final c = await pumpScreen(tester, source(4000, 3000), const Target(300, 300));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      final g = await tester.startGesture(tester.getCenter(find.byTooltip('Move left')));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      final session = c.read(cropControllerProvider)!;
      expect(session.cropRect.x, 0, reason: 'repeated until the left edge');
      expect(session.announcements.whereType<EdgeAnnouncement>().single.edge, Edge.left);
      await g.up();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Move right'));
      await tester.pumpAndSettle();
      final moved = c.read(cropControllerProvider)!.cropRect;
      await tester.pump(const Duration(seconds: 1));
      expect(c.read(cropControllerProvider)!.cropRect, moved, reason: 'no repeat after release');
    });

    testWidgets('rotate keeps the frame ratio and shows no empty area', (tester) async {
      final info = source(4000, 3000);
      const t = Target(300, 80);
      final c = await pumpScreen(tester, info, t);
      for (final label in ['Rotate clockwise', 'Rotate clockwise', 'Rotate counter-clockwise']) {
        await tester.tap(find.byTooltip(label));
        await tester.pumpAndSettle();
        final s = c.read(cropControllerProvider)!;
        final (sw, sh) = CropMath.orientedSize(info, s.crop.quarterTurns);
        final r = s.cropRect;
        expect(r.x >= 0 && r.y >= 0 && r.x + r.w <= sw && r.y + r.h <= sh, isTrue, reason: '$label: inside the photo');
        expect(r.w / r.h, closeTo(300 / 80, 300 / 80 / r.h + 1e-9), reason: '$label: ratio');
        final f = canvasFrame(tester, t);
        expect(f.width / f.height, closeTo(300 / 80, 1e-9));
      }
    });
  });
}
