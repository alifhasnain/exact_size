import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/preview/domain/spec_check.dart';
import 'package:exact_size/features/preview/presentation/spec_check_controller.dart';
import 'package:exact_size/features/preview/presentation/spec_check_view.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:exact_size/ui/booth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-006-T11: SpecCheckView built to the G1 design (t10/check_design.md). Synthetic values only.
void main() {
  const spec = TargetSpec(width: 300, height: 300, minKb: 20, maxKb: 50, format: OutputFormat.jpeg);
  const success = CompressionSuccess(tempFilePath: '[PLACEHOLDER].jpg', sizeBytes: 48200, format: OutputFormat.jpeg);

  MeasuredOutput out(int w, int h, {int bytes = 48200, OutputFormat f = OutputFormat.jpeg, bool alpha = false}) =>
      MeasuredOutput(bytes: bytes, width: w, height: h, format: f, hasAlpha: alpha);

  String strip(String s) => s.replaceAll(RegExp('[\u2066-\u2069]'), '');
  Finder textContaining(String part) => find.byWidgetPredicate((w) => w is Text && strip(w.data ?? '').contains(part));

  Future<ui.Image?> image(WidgetTester tester, int w, int h) => tester.runAsync(() => createTestImage(width: w, height: h));

  Future<void> pump(WidgetTester tester, CheckMeets state, {TargetSpec target = spec, Size size = const Size(360, 640)}) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ExactSizeApp(
      locale: const Locale('en'),
      home: Theme(
        data: Booth.theme(ThemeData()),
        child: Scaffold(
          body: ListView(padding: const EdgeInsets.all(24), children: [SpecCheckView(spec: target, state: state), const SizedBox(height: 2000)]),
        ),
      ),
    ));
    await tester.pump();
  }

  CheckMeets meets(MeasuredOutput m, ui.Image? img, {TargetSpec target = spec, CompressionSuccess s = success}) =>
      CheckMeets(s, m, checkSpec(m, target), img);

  testWidgets('three rows in fixed order with target and measured values; all meet (AC-1.1, AC-2.1)', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, meets(out(300, 300), await image(tester, 30, 30)));

    expect(find.text('Matches your target'), findsOneWidget);
    expect(find.text('Meets'), findsNWidgets(3));
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4)); // headline + three rows
    expect(find.text("Doesn't meet"), findsNothing);

    final rows = tester.widgetList<Semantics>(find.byWidgetPredicate((w) => w is Semantics && w.excludeSemantics))
        .map((s) => strip(s.properties.label!))
        .toList();
    expect(rows, [
      'Size in pixels: target 300 × 300 px, this file 300 × 300 px, Meets.',
      'File size: target 20–50 KB, this file 48.2 KB, Meets.',
      'Format: target JPEG, this file JPEG, Meets.',
    ]);
    expect(find.text('Target'), findsNWidgets(3));
    expect(find.text('This file'), findsNWidgets(3));
    handle.dispose();
  });

  testWidgets('max-only target reads "Up to" (AC-1.3)', (tester) async {
    const maxOnly = TargetSpec(width: 300, height: 300, maxKb: 50, format: OutputFormat.jpeg);
    await pump(tester, meets(out(300, 300), await image(tester, 30, 30), target: maxOnly), target: maxOnly);
    expect(textContaining('Up to 50 KB'), findsOneWidget);
  });

  testWidgets('1,024 line shown for a normal window, hidden for a narrow one (AC-2.4); caveat present (AC-2.5)', (tester) async {
    await pump(tester, meets(out(300, 300), await image(tester, 30, 30)));
    expect(textContaining('Also fits if your portal counts 1 KB as 1,024 bytes.'), findsOneWidget);
    expect(find.text('We check pixels, KB and format. Some forms also check the photo itself, such as the face or background.'), findsOneWidget);

    const narrow = TargetSpec(width: 300, height: 300, minKb: 49, maxKb: 50, format: OutputFormat.jpeg);
    await pump(tester, meets(out(300, 300, bytes: 49500), await image(tester, 30, 30), target: narrow), target: narrow);
    expect(textContaining('Also fits'), findsNothing);
  });

  testWidgets('each notice once; none gives no notice widget (AC-5.1, AC-5.2)', (tester) async {
    await pump(tester, meets(out(300, 300), await image(tester, 30, 30)));
    expect(find.byType(BoothNotice), findsNothing);

    const all = CompressionSuccess(
      tempFilePath: '[PLACEHOLDER].jpg',
      sizeBytes: 48200,
      format: OutputFormat.jpeg,
      notices: {Notice.transparencyFlattened, Notice.narrowRange, Notice.paddingAdded},
    );
    await pump(tester, meets(out(300, 300), await image(tester, 30, 30), s: all));
    expect(find.byType(BoothNotice), findsNWidgets(3));
    expect(find.textContaining('This range is very narrow.'), findsOneWidget);
    expect(find.textContaining('Padding was added'), findsOneWidget);
    expect(find.textContaining('JPEG has no transparency'), findsOneWidget);
  });

  test('preview box keeps the measured aspect, ≤ 40% of the height, ≤ 4 device px per px (AC-4.1, FR-14)', () {
    for (final (w, h) in [(300, 300), (140, 60), (6000, 4000), (60, 2000)]) {
      final box = previewBoxSize(w, h, maxWidth: 278, screenHeight: 640, devicePixelRatio: 3);
      expect((box.width / box.height - w / h).abs() * box.height, lessThanOrEqualTo(1), reason: '$w×$h aspect');
      expect(box.height, lessThanOrEqualTo(0.4 * 640 + 1e-9), reason: '$w×$h height');
      expect(box.width, lessThanOrEqualTo(278 + 1e-9), reason: '$w×$h width');
      expect(box.width / w * 3, lessThanOrEqualTo(4 + 1e-9), reason: '$w×$h scale');
    }
    // A small output is capped by the enlargement, not stretched to the width.
    expect(previewBoxSize(140, 60, maxWidth: 278, screenHeight: 640, devicePixelRatio: 3).width, closeTo(140 * 4 / 3, 1e-9));
  });

  testWidgets('rendered box follows the measured size, not the bitmap (FR-14)', (tester) async {
    // A 6000×4000 output decoded at a reduced 750×500.
    await pump(tester, meets(out(6000, 4000), await image(tester, 750, 500)));
    final box = tester.getSize(find.byType(RawImage));
    expect((box.width / box.height - 1.5).abs() * box.height, lessThanOrEqualTo(1));
    expect(box.height, lessThanOrEqualTo(0.4 * 640));
    expect(box.width, closeTo(360 - 48 - 32 - 2, 0.01)); // page and stage padding, hairline frame
  });

  testWidgets('preview text alternative is width, height and format only (AC-4.6)', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, meets(out(300, 300, f: OutputFormat.jpeg), await image(tester, 30, 30)));
    final node = tester.getSemantics(find.byType(RawImage));
    expect(strip(node.label), 'Preview of your new file, 300 × 300 px, JPEG.');
    expect(find.text('Shown scaled to fit your screen.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no gesture on the preview: a drag on it scrolls the page (AC-4.7, FR-17)', (tester) async {
    await pump(tester, meets(out(300, 300), await image(tester, 30, 30)));
    final preview = find.byType(RawImage);
    expect(find.ancestor(of: preview, matching: find.byType(GestureDetector)), findsNothing);
    expect(find.ancestor(of: preview, matching: find.byType(InteractiveViewer)), findsNothing);
    final before = tester.getTopLeft(preview).dy;
    await tester.drag(preview, const Offset(0, -100));
    await tester.pump();
    expect(tester.getTopLeft(preview).dy, lessThan(before - 50));
  });

  testWidgets('transparent PNG is drawn over the checkerboard (FR-15)', (tester) async {
    const png = TargetSpec(width: 300, height: 300, maxKb: 50, format: OutputFormat.png);
    await pump(tester, meets(out(300, 300, f: OutputFormat.png, alpha: true), await image(tester, 30, 30), target: png), target: png);
    final paint = tester.widget<CustomPaint>(find.ancestor(of: find.byType(RawImage), matching: find.byType(CustomPaint)).first);
    expect(paint.painter, isNotNull);
  });

  testWidgets('null image shows the placeholder and keeps the rows (AC-4.4)', (tester) async {
    await pump(tester, meets(out(300, 300), null));
    expect(find.text("Preview isn't available. The check below is still correct."), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);
    expect(find.text('Shown scaled to fit your screen.'), findsNothing);
    expect(find.text('Meets'), findsNWidgets(3));
  });

  testWidgets('a failing row shows the "Doesn\'t meet" status (SpecSlip, FR-5)', (tester) async {
    final m = out(301, 300, bytes: 50001);
    final c = checkSpec(m, spec);
    await tester.pumpWidget(ExactSizeApp(
      locale: const Locale('en'),
      home: Scaffold(body: SpecSlip(spec: spec, measured: m, check: c, showAlsoFits: false)),
    ));
    expect(find.text("Doesn't meet"), findsNWidgets(2));
    expect(find.text('Meets'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsNWidgets(2));
    expect(textContaining('50.1 KB'), findsOneWidget); // rounded away from the target (FR-6)
    expect(textContaining('Also fits'), findsNothing);
  });

  testWidgets('no Image widget and nothing in the image cache (FR-19)', (tester) async {
    imageCache.clear();
    await pump(tester, meets(out(300, 300), await image(tester, 30, 30)));
    expect(find.byType(Image), findsNothing);
    expect(imageCache.currentSize, 0);
  });
}
