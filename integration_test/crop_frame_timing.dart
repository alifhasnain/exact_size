import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/presentation/crop_canvas.dart';
import 'package:exact_size/features/crop/presentation/crop_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-002-T29 (FR-25, informational): crop screen frame timings during a
/// scripted drag and pinch on a synthetic 2048 px preview. Not named
/// *_test.dart; run in profile mode:
///   flutter drive --profile --driver=test_driver/integration_test.dart \
///     --target=integration_test/crop_frame_timing.dart -d DEVICE_ID
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('frames during drag and pinch', (tester) async {
    final r = ui.PictureRecorder();
    Canvas(r).drawRect(
      const Rect.fromLTWH(0, 0, 1536, 2048),
      Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(1536, 2048), [const Color(0xFF9EC5E8), const Color(0xFF34495E)]),
    );
    final preview = await r.endRecording().toImage(1536, 2048); // a 12 MP source decoded at sample 2
    const info = SourceInfo(
        rawWidth: 3000, rawHeight: 4000, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
    await tester.pumpWidget(ProviderScope(
      child: ExactSizeApp(
        home: CropScreen(
            src: SourceHandle('file:///synthetic/never-rendered.jpg'),
            preview: preview,
            info: info,
            target: const Target(300, 300),
            onContinue: (_) {},
            onChooseAnother: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    final centre = tester.getCenter(find.byType(CropCanvas));
    await binding.watchPerformance(() async {
      final a = await tester.startGesture(centre);
      for (var i = 0; i < 120; i++) {
        await a.moveBy(Offset(i < 60 ? 3 : -3, i < 60 ? 2 : -2));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      final p = await tester.startGesture(centre - const Offset(30, 0));
      final q = await tester.startGesture(centre + const Offset(30, 0), pointer: 2);
      for (var i = 0; i < 120; i++) {
        final d = Offset(i < 60 ? 1.5 : -1.5, 0);
        await p.moveBy(-d);
        await q.moveBy(d);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await p.up();
      await q.up();
      await tester.pumpAndSettle();
    }, reportKey: 'crop_frames');
  });
}
