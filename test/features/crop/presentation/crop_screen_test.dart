import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/presentation/crop_canvas.dart';
import 'package:exact_size/features/crop/presentation/crop_controller.dart';
import 'package:exact_size/features/crop/presentation/crop_screen.dart';
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

/// Pumps the crop screen on a 360×800 dp phone; returns the provider container.
Future<ProviderContainer> pumpScreen(WidgetTester tester, SourceInfo info, Target target,
    {void Function(CropSession)? onContinue, VoidCallback? onChooseAnother, Locale? locale}) async {
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
      home: CropScreen(
        preview: image,
        info: info,
        target: target,
        onContinue: onContinue ?? (_) {},
        onChooseAnother: onChooseAnother ?? () {},
      ),
    ),
  ));
  await tester.pumpAndSettle();
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
}
