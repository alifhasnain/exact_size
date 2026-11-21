import 'dart:io';
import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/presentation/crop_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-002-T22 design review (manual, not in CI): the crop screen on synthetic
/// images. Build with `-t integration_test/crop_screen_demo.dart`; pick the
/// state by writing its name to `files/demo_state` with `adb shell run-as`,
/// then restart the activity. States: normal, signature, enlarged, strong,
/// extreme, arabic, font200.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final f = File('${(await getApplicationSupportDirectory()).path}/demo_state');
  final state = f.existsSync() ? f.readAsStringSync().trim() : 'normal';
  final signature = state == 'signature';
  final image = await (signature ? _signature() : _portrait());

  const photo = SourceInfo(rawWidth: 3000, rawHeight: 4000, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
  final (info, target) = switch (state) {
    'signature' => (
        const SourceInfo(rawWidth: 1600, rawHeight: 900, mime: 'image/png', exifOrientation: 1, isAnimated: false, hasAlpha: true, decodePath: DecodePath.region),
        const Target(300, 80)
      ),
    'enlarged' || 'arabic' || 'font200' => (
        const SourceInfo(rawWidth: 150, rawHeight: 200, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region),
        const Target(300, 300)
      ),
    'strong' => (
        const SourceInfo(rawWidth: 90, rawHeight: 120, mime: 'image/gif', exifOrientation: 1, isAnimated: true, hasAlpha: false, decodePath: DecodePath.full),
        const Target(300, 300)
      ),
    'extreme' => (photo, const Target(1000, 10)),
    _ => (photo, const Target(300, 300)),
  };

  runApp(ProviderScope(
    child: ExactSizeApp(
      locale: state == 'arabic' ? const Locale('ar') : null,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(state == 'font200' ? 2 : 1)),
          child: CropScreen(
              src: SourceHandle('file:///synthetic/demo.jpg'), // never rendered in the demo
              preview: image,
              info: info,
              target: target,
              onContinue: (_) {},
              onChooseAnother: () {}),
        ),
      ),
    ),
  ));
}

/// Synthetic portrait: plain backdrop and a faceless head-and-shoulders shape.
Future<ui.Image> _portrait() {
  const w = 750.0, h = 1000.0;
  final r = ui.PictureRecorder();
  final c = Canvas(r);
  c.drawRect(
    const Rect.fromLTWH(0, 0, w, h),
    Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, h), [const Color(0xFF9EC5E8), const Color(0xFFE8EEF4)]),
  );
  final body = Paint()..color = const Color(0xFF34495E);
  c
    ..drawOval(const Rect.fromLTWH(140, 620, 470, 520), body)
    ..drawCircle(const Offset(375, 430), 150, Paint()..color = const Color(0xFFC9A27E))
    ..drawRect(const Rect.fromLTWH(330, 560, 90, 80), Paint()..color = const Color(0xFFC9A27E));
  return r.endRecording().toImage(w.toInt(), h.toInt());
}

/// Synthetic signature-like strokes on transparency.
Future<ui.Image> _signature() {
  const w = 800.0, h = 450.0;
  final r = ui.PictureRecorder();
  final c = Canvas(r);
  final ink = Paint()
    ..color = const Color(0xFF1A237E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  c.drawPath(
    Path()
      ..moveTo(90, 300)
      ..cubicTo(150, 80, 230, 80, 240, 260)
      ..cubicTo(250, 360, 330, 120, 380, 240)
      ..cubicTo(420, 330, 470, 150, 530, 230)
      ..cubicTo(580, 300, 640, 200, 720, 210)
      ..moveTo(120, 340)
      ..lineTo(700, 320),
    ink,
  );
  return r.endRecording().toImage(w.toInt(), h.toInt());
}
