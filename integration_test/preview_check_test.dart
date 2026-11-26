import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/jpeg_padder.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/export/presentation/export_panel.dart';
import 'package:exact_size/features/export/presentation/result_screen.dart';
import 'package:exact_size/features/preview/presentation/preview_providers.dart';
import 'package:exact_size/features/preview/presentation/spec_check_controller.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// A FEAT-004 run that has already finished with [result]; cancel() deletes the file, as the real
/// controller does. Used only where a test file must be injected (T15 scope).
class _Injected extends CompressionController {
  _Injected(this.result);
  final CompressionSuccess result;

  @override
  CompressionRunState build() => CompressionDone(result, maxKb: 50);

  @override
  Future<void> cancel() async {
    final f = File(result.tempFilePath);
    if (f.existsSync()) f.deleteSync();
    state = const CompressionIdle();
  }
}

/// FEAT-006-T15 on a device: the real FileOutputMeasurer and PreviewDecoder, real FEAT-004
/// outputs, synthetic pixels only (gradients, stripes and solid colours; no photo). No paths or
/// file names are printed; timings are printed as numbers only.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory inject;
  late Set<String> outBefore;
  const runner = CompressionRunner();

  setUpAll(() async {
    if (!getIt.isRegistered<TempFiles>()) await configureDependencies();
    inject = Directory.systemTemp.createTempSync('preview_check');
    outBefore = await _outFiles();
  });
  tearDownAll(() => inject.deleteSync(recursive: true));

  /// A smooth synthetic picture with some texture: gradients and an XOR pattern.
  NativePixelBuffer pattern(int w, int h, {int seed = 0, bool flat = false}) {
    final px = NativePixelBuffer.allocate(width: w, height: h, channels: 3, hasTransparency: false);
    final b = px.bytes;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 3;
        b[i] = flat ? 90 : (x * 255 ~/ w);
        b[i + 1] = flat ? 140 : (y * 255 ~/ h);
        b[i + 2] = flat ? 200 : ((x ^ y ^ seed) & 0xFF);
      }
    }
    return px;
  }

  /// A large buffer built from copied stripes, so 24 MP fills in well under a second.
  NativePixelBuffer stripes(int w, int h) {
    final px = NativePixelBuffer.allocate(width: w, height: h, channels: 3, hasTransparency: false);
    final b = px.bytes;
    final row = Uint8List(w * 3);
    for (var x = 0; x < w; x++) {
      row[x * 3] = (x * 255 ~/ w);
      row[x * 3 + 1] = (x ~/ 50).isEven ? 60 : 180;
      row[x * 3 + 2] = 120;
    }
    for (var y = 0; y < h; y++) {
      b.setRange(y * w * 3, (y + 1) * w * 3, row);
    }
    return px;
  }

  Future<Uint8List> jpeg(NativePixelBuffer px, {required int maxKb, int? minKb}) async {
    final r = await runner.run(CompressionRequest(pixels: px, minKb: minKb, maxKb: maxKb, format: OutputFormat.jpeg));
    return (r as ReadyToWrite).bytes;
  }

  /// A PNG of one colour, encoded by the engine.
  Future<Uint8List> solidPng(int w, int h, Color color) async {
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = color);
    final img = await rec.endRecording().toImage(w, h);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return data!.buffer.asUint8List();
  }

  /// Pads a JPEG with neutral COM segments to exactly [length] bytes (FEAT-004's padder).
  Uint8List padTo(Uint8List jpeg, int length) =>
      (padJpeg(jpeg, ByteWindow.bytes(length, length), jumpCase: false) as Padded).bytes;

  CompressionSuccess injected(Uint8List bytes, OutputFormat format) {
    final f = File('${inject.path}/${Random().nextInt(1 << 30)}.${format == OutputFormat.jpeg ? 'jpg' : 'png'}')
      ..writeAsBytesSync(bytes, flush: true);
    return CompressionSuccess(tempFilePath: f.path, sizeBytes: bytes.length, format: format);
  }

  /// Keeps the check alive and waits for its verdict.
  Future<(SpecCheckState, ProviderSubscription<SpecCheckState>)> verdict(ProviderContainer c, TargetSpec spec) async {
    final sub = c.listen(specCheckControllerProvider(spec), (_, _) {});
    final sw = Stopwatch()..start();
    while (sub.read() is Checking || sub.read() is CheckIdle) {
      if (sw.elapsed > const Duration(seconds: 90)) fail('no verdict within 90 s');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return (sub.read(), sub);
  }

  Future<(int, int)> headerSize(Uint8List bytes) async {
    final buf = await ui.ImmutableBuffer.fromUint8List(bytes);
    final d = await ui.ImageDescriptor.encoded(buf);
    final size = (d.width, d.height);
    d.dispose();
    buf.dispose();
    return size;
  }

  ProviderContainer containerFor(CompressionSuccess? s, {List<Override> extra = const []}) {
    final c = ProviderContainer(overrides: [
      if (s != null) compressionControllerProvider.overrideWith(() => _Injected(s)),
      ...extra,
    ]);
    addTearDown(c.dispose);
    return c;
  }

  /// Real FEAT-004 run through the real controller (writes into cache/exactsize_out).
  Future<CheckMeets> realRun(ProviderContainer c, TargetSpec spec, NativePixelBuffer px) async {
    final pending = verdict(c, spec);
    await c.read(compressionControllerProvider.notifier).start(spec.request(px));
    final done = c.read(compressionControllerProvider);
    expect(done, isA<CompressionDone>());
    expect((done as CompressionDone).result, isA<CompressionSuccess>(), reason: 'FEAT-004 run for the test fixture');
    final (state, sub) = await pending;
    addTearDown(sub.close);
    expect(state, isA<CheckMeets>(), reason: 'no false "doesn\'t match" for a real output');
    return state as CheckMeets;
  }

  testWidgets('real flow, 300x300, 20-50 KB, JPEG: matches; values equal File.length and the header', (tester) async {
    final c = containerFor(null);
    const spec = TargetSpec(width: 300, height: 300, minKb: 20, maxKb: 50, format: OutputFormat.jpeg);
    final s = await realRun(c, spec, pattern(300, 300));
    final file = File(s.success.tempFilePath);
    final bytes = file.readAsBytesSync();
    expect(s.measured.bytes, file.lengthSync());
    expect((s.measured.width, s.measured.height), await headerSize(bytes));
    expect((bytes[0], bytes[1]), (0xFF, 0xD8));
    expect(s.measured.format, OutputFormat.jpeg);
    expect(s.check.meets, isTrue);
    await c.read(compressionControllerProvider.notifier).cancel();
  });

  for (final (name, spec, flat) in const [
    ('narrow 49-50 KB', TargetSpec(width: 300, height: 300, minKb: 49, maxKb: 50, format: OutputFormat.jpeg), false),
    ('max-only 30 KB', TargetSpec(width: 300, height: 300, maxKb: 30, format: OutputFormat.jpeg), false),
    ('PNG up to 500 KB', TargetSpec(width: 300, height: 300, maxKb: 500, format: OutputFormat.png), false),
    ('padded JPEG 40-50 KB', TargetSpec(width: 300, height: 300, minKb: 40, maxKb: 50, format: OutputFormat.jpeg), true),
  ]) {
    testWidgets('real FEAT-004 output, $name: matches', (tester) async {
      final c = containerFor(null);
      final s = await realRun(c, spec, pattern(300, 300, flat: flat));
      if (flat) expect(s.success.notices, contains(Notice.paddingAdded));
      await c.read(compressionControllerProvider.notifier).cancel();
    });
  }

  testWidgets('the preview comes from the output file: a blue file shows blue (AC-4.2)', (tester) async {
    const spec = TargetSpec(width: 300, height: 300, maxKb: 50, format: OutputFormat.png);
    final c = containerFor(injected(await solidPng(300, 300, const Color(0xFF0000FF)), OutputFormat.png));
    final (state, sub) = await verdict(c, spec);
    addTearDown(sub.close);
    final img = (state as CheckMeets).preview!;
    final rgba = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final i = ((img.height ~/ 2) * img.width + img.width ~/ 2) * 4;
    expect((rgba.getUint8(i), rgba.getUint8(i + 1), rgba.getUint8(i + 2)), (0, 0, 255));
  });

  testWidgets('24 MP output: no crash, values from the file, decode bounded to maxSide (AC-4.3)', (tester) async {
    const spec = TargetSpec(width: 6000, height: 4000, maxKb: 20000, format: OutputFormat.jpeg);
    final c = containerFor(injected(await jpeg(stripes(6000, 4000), maxKb: 20000), OutputFormat.jpeg));
    final (state, sub) = await verdict(c, spec);
    addTearDown(sub.close);
    final s = state as CheckMeets;
    expect((s.measured.width, s.measured.height), (6000, 4000));
    final cap = c.read(previewMaxSideProvider);
    expect(max(s.preview!.width, s.preview!.height), lessThanOrEqualTo(cap));
  });

  for (final (name, field) in const [
    ('floor - 1', 'size'),
    ('ceiling + 1', 'size'),
    ('width + 1', 'pixels'),
    ('format swap', 'format'),
  ]) {
    testWidgets('injected $name: mismatch, file deleted (no false "matches")', (tester) async {
      // The format swap has no floor, so only the format fails (a solid PNG is small).
      final spec = TargetSpec(width: 300, height: 300, minKb: field == 'format' ? null : 20, maxKb: 50, format: OutputFormat.jpeg);
      final window = ByteWindow.fromKb(minKb: 20, maxKb: 50);
      final small = await jpeg(pattern(300, 300, flat: true), maxKb: 10);
      final (bytes, format) = switch (name) {
        'floor - 1' => (padTo(small, window.lo - 1), OutputFormat.jpeg),
        'ceiling + 1' => (padTo(small, window.hi + 1), OutputFormat.jpeg),
        'width + 1' => (padTo(await jpeg(pattern(301, 300, flat: true), maxKb: 10), window.lo + 100), OutputFormat.jpeg),
        _ => (await solidPng(300, 300, const Color(0xFF808080)), OutputFormat.png),
      };
      final success = injected(bytes, format);
      final c = containerFor(success);
      final (state, sub) = await verdict(c, spec);
      addTearDown(sub.close);
      expect(state, isA<CheckMismatch>());
      final check = (state as CheckMismatch).check;
      expect((check.pixels, check.size, check.format), (field != 'pixels', field != 'size', field != 'format'));
      expect(File(success.tempFilePath).existsSync(), isFalse);
    });
  }

  Future<void> pumpUntil(WidgetTester tester, Finder f) async {
    final sw = Stopwatch()..start();
    while (f.evaluate().isEmpty) {
      if (sw.elapsed > const Duration(seconds: 60)) fail('not shown within 60 s: $f');
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, ProviderContainer c, TargetSpec spec) => tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: ExactSizeApp(locale: const Locale('en'), home: ResultScreen(spec: spec, onStartOver: () {})),
      ));

  testWidgets('out of memory (forced): placeholder, rows and panel (AC-4.4)', (tester) async {
    const spec = TargetSpec(width: 300, height: 300, minKb: 20, maxKb: 50, format: OutputFormat.jpeg);
    final small = await jpeg(pattern(300, 300, flat: true), maxKb: 10);
    final c = containerFor(injected(padTo(small, 30000), OutputFormat.jpeg),
        extra: [resultPreviewDecoderProvider.overrideWithValue(const PreviewDecoder(debugForceOutOfMemory: true))]);
    await pumpScreen(tester, c, spec);
    await pumpUntil(tester, find.text("Preview isn't available. The check below is still correct."));
    expect(find.text('Meets'), findsNWidgets(3));
    expect(find.byType(ExportPanel), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('FR-12: back from the background after the file was deleted shows FILE_MISSING', (tester) async {
    const spec = TargetSpec(width: 300, height: 300, minKb: 20, maxKb: 50, format: OutputFormat.jpeg);
    final small = await jpeg(pattern(300, 300, flat: true), maxKb: 10);
    final success = injected(padTo(small, 30000), OutputFormat.jpeg);
    final c = containerFor(success);
    await pumpScreen(tester, c, spec);
    await pumpUntil(tester, find.text('Matches your target'));
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    File(success.tempFilePath).deleteSync();
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await pumpUntil(tester, find.textContaining('The new file is no longer available.'));
    expect(find.byType(ExportPanel), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('timing: 20 success-to-verdict runs at 2 MP (NFR-1)', (tester) async {
    const spec = TargetSpec(width: 1600, height: 1250, maxKb: 2000, format: OutputFormat.jpeg);
    final bytes = await jpeg(pattern(1600, 1250), maxKb: 2000);
    final success = injected(bytes, OutputFormat.jpeg);
    final ms = <int>[];
    for (var i = 0; i < 20; i++) {
      final c = ProviderContainer(overrides: [compressionControllerProvider.overrideWith(() => _InjectedKeep(success))]);
      final sw = Stopwatch()..start();
      final (state, sub) = await verdict(c, spec);
      sw.stop();
      expect(state, isA<CheckMeets>());
      ms.add(sw.elapsedMilliseconds);
      sub.close();
      c.dispose();
    }
    ms.sort();
    // ignore: avoid_print
    print('FEAT006_TIMING 2MP jpeg median=${(ms[9] + ms[10]) / 2} ms p95=${ms[18]} ms max=${ms[19]} ms');
    File(success.tempFilePath).deleteSync();
  });

  testWidgets('nothing of these runs is left in cache/exactsize_out', (tester) async {
    expect(await _outFiles(), outBefore);
  });
}

/// Like [_Injected], but leaves the file in place so the timing loop can reuse it.
class _InjectedKeep extends _Injected {
  _InjectedKeep(super.result);
  @override
  Future<void> cancel() async => state = const CompressionIdle();
}

Future<Set<String>> _outFiles() async {
  final dir = (await TempFiles.appCache()).dir;
  if (!dir.existsSync()) return {};
  return dir.listSync().map((e) => e.path).toSet();
}
