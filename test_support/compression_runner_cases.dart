import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'synthetic_image.dart';

/// Synthetic ADR-003 buffer (FEAT-002 is not built yet): tight stride, 3 or 4 channels.
NativePixelBuffer syntheticBuffer(int w, int h, {int channels = 3, int seed = 1}) {
  final src = syntheticRgba(w, h, channels: channels, seed: seed);
  if (channels == 4) {
    for (var i = 3; i < src.length; i += 4) {
      src[i] = (i ~/ 4) % 2 == 0 ? 255 : 100; // some transparency
    }
  }
  final px = NativePixelBuffer.allocate(
      width: w, height: h, channels: channels, hasTransparency: channels == 4);
  px.bytes.setAll(0, src);
  return px;
}

/// FEAT-004-T16 checks, shared by test/ (host) and integration_test/ (emulator).
void defineCompressionRunnerTests() {
  const runner = CompressionRunner();

  test('progress is monotonic and ends at the pass count used', () async {
    final events = <int>[];
    final r = await runner.run(
      CompressionRequest(
          pixels: syntheticBuffer(320, 240), minKb: 4, maxKb: 8, format: OutputFormat.jpeg),
      onProgress: (pass, max) {
        expect(max, 10);
        events.add(pass);
      },
    ) as ReadyToWrite;
    expect(events, [for (var i = 1; i <= events.length; i++) i]);
    expect(events.length, inInclusiveRange(1, 10));
    expect(ByteWindow.fromKb(minKb: 4, maxKb: 8).contains(r.bytes.length), isTrue);
    expect(NativePixelBuffer.live, 0);
  });

  test('cancel during a search stops it early with CANCELLED', () async {
    // Passes an uncancelled run of the same job needs.
    var fullPasses = 0;
    await runner.run(
        CompressionRequest(
            pixels: syntheticBuffer(1600, 1250), minKb: 100, maxKb: 120, format: OutputFormat.jpeg),
        onProgress: (pass, _) => fullPasses = pass);

    final cancel = CancelSignal();
    final events = <int>[];
    final r = await runner.run(
      CompressionRequest(
          pixels: syntheticBuffer(1600, 1250), minKb: 100, maxKb: 120, format: OutputFormat.jpeg),
      cancel: cancel,
      onProgress: (pass, _) {
        events.add(pass);
        if (pass == 1) cancel.cancel();
      },
    ) as PlanFailed;
    cancel.dispose();
    expect(r.failure.reason, Reason.cancelled);
    // The flag is checked before every pass, so the worker stops at its next
    // pass. Progress messages already in flight can show a pass or two more on
    // a fast phone, but the run never finishes the search.
    expect(events.length, lessThan(fullPasses), reason: 'full run: $fullPasses passes');
    expect(NativePixelBuffer.live, 0);
  });

  test('a cancel before the first pass encodes nothing', () async {
    final cancel = CancelSignal()..cancel();
    var passes = 0;
    final r = await runner.run(
        CompressionRequest(pixels: syntheticBuffer(320, 240), maxKb: 20, format: OutputFormat.jpeg),
        cancel: cancel,
        onProgress: (_, _) => passes++) as PlanFailed;
    cancel.dispose();
    expect((r.failure.reason, passes), (Reason.cancelled, 0));
  });

  test('RGBA to JPEG is flattened and says so; PNG keeps working through the runner', () async {
    final jpeg = await runner.run(CompressionRequest(
        pixels: syntheticBuffer(200, 150, channels: 4), maxKb: 50, format: OutputFormat.jpeg));
    expect((jpeg as ReadyToWrite).notices, contains(Notice.transparencyFlattened));
    final png = await runner.run(CompressionRequest(
        pixels: syntheticBuffer(200, 150, channels: 4), maxKb: 500, format: OutputFormat.png));
    expect((png as ReadyToWrite).format, OutputFormat.png);
    expect(NativePixelBuffer.live, 0);
  });

  test('stride or size mismatch is rejected before any encode, and the buffer is still freed', () async {
    for (final badChannels in [5, 4]) {
      final px = syntheticBuffer(10, 10)..channels = badChannels; // 5: bad stride; 4: too few bytes
      var passes = 0;
      await expectLater(
        runner.run(CompressionRequest(pixels: px, maxKb: 10, format: OutputFormat.jpeg),
            onProgress: (_, _) => passes++),
        throwsArgumentError,
      );
      expect(passes, 0);
    }
    expect(NativePixelBuffer.live, 0);
  });

  test('leak counter is 0 after 100 mixed runs (success, failure, cancel)', () async {
    for (var i = 0; i < 100; i++) {
      final px = syntheticBuffer(64, 48, seed: i);
      switch (i % 3) {
        case 0: // success
          expect(await runner.run(CompressionRequest(pixels: px, maxKb: 20, format: OutputFormat.jpeg)),
              isA<ReadyToWrite>());
        case 1: // failure: a tiny PNG can't reach 100 KB
          final r = await runner.run(
              CompressionRequest(pixels: px, minKb: 100, maxKb: 200, format: OutputFormat.png));
          expect((r as PlanFailed).failure.reason, Reason.pngBelowMin);
        default: // cancelled before the first pass
          final cancel = CancelSignal()..cancel();
          final r = await runner.run(
              CompressionRequest(pixels: px, maxKb: 20, format: OutputFormat.jpeg),
              cancel: cancel);
          cancel.dispose();
          expect((r as PlanFailed).failure.reason, Reason.cancelled);
      }
    }
    expect(NativePixelBuffer.live, 0);
  });
}
