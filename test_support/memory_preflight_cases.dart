import 'dart:typed_data';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/memory_preflight.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/data/turbo_jpeg_encoder.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/encoder.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/compression/domain/subsampling.dart';
import 'package:flutter_test/flutter_test.dart';

import 'compression_runner_cases.dart';

/// Synthetic meminfo text in the kernel's format (values made up).
String meminfo(int availableKb) => '''
MemTotal:        2048000 kB
MemFree:          120000 kB
MemAvailable:   ${availableKb.toString().padLeft(8)} kB
Buffers:           20000 kB
''';

MemoryPreflight withMeminfo(String? text) => MemoryPreflight(readMeminfo: () async => text);

const _ample = 8 * 1024 * 1024; // 8 GB in kB

// Encoders that run out of memory on the first pass. Top-level so the worker
// isolate can receive them.
Encoder _dartHeapOom(Encoder _) => const _ThrowingEncoder(OutOfMemoryError());
Encoder _libjpegOom(Encoder _) => const _ThrowingEncoder(
    JpegEncodeException(JpegEncodeErrorKind.outOfMemory, 'Memory allocation failure'));

final class _ThrowingEncoder implements Encoder {
  const _ThrowingEncoder(this.error);
  final Object error;
  @override
  Uint8List encodeJpeg(
          {required int quality, required Subsampling subsampling, required bool optimiseHuffman}) =>
      throw error;
  @override
  Uint8List encodePng() => throw error;
}

/// FEAT-004-T18 checks, shared by test/ (host) and integration_test/ (emulator).
void defineMemoryPreflightTests() {
  group('pixel cap (OQ-4)', () {
    final preflight = withMeminfo(meminfo(_ample));

    test('24,000,000 px is allowed', () async {
      expect(await preflight.check(width: 6000, height: 4000), isNull);
    });

    test('24,000,001 px is IMAGE_TOO_LARGE', () async {
      final r = await preflight.check(width: 24000001, height: 1);
      expect(r?.reason, Reason.imageTooLarge);
      expect((r?.closestBytes, r?.direction), (null, null));
    });
  });

  group('MemAvailable', () {
    test('low MemAvailable is IMAGE_TOO_LARGE; enough passes', () async {
      // 2 MP × 16 B/px × 2 headroom = 64,000,000 B = 62,500 kB.
      expect((await withMeminfo(meminfo(62499)).check(width: 1600, height: 1250))?.reason,
          Reason.imageTooLarge);
      expect(await withMeminfo(meminfo(62500)).check(width: 1600, height: 1250), isNull);
    });

    test('unreadable or malformed meminfo skips the check without a crash', () async {
      final failing = MemoryPreflight(readMeminfo: () async => throw Exception('denied'));
      for (final p in [withMeminfo(null), withMeminfo(''), withMeminfo('MemAvailable: lots'), failing]) {
        expect(await p.check(width: 6000, height: 4000), isNull);
      }
      // The pixel cap still applies.
      expect((await withMeminfo(null).check(width: 24000001, height: 1))?.reason,
          Reason.imageTooLarge);
    });

    test('parseMemAvailable reads kB as bytes', () {
      expect(parseMemAvailable(meminfo(123456)), 123456 * 1024);
      expect(parseMemAvailable('MemTotal: 1 kB\n'), isNull);
    });
  });

  group('allocation failures', () {
    test('a null native allocation is OutOfMemoryError, nothing leaks', () {
      final before = NativePixelBuffer.live;
      // 2^60 bytes: more than any 64-bit address space, so malloc returns null
      // even where the kernel overcommits (2 TiB succeeded on the API 28 emulator).
      expect(
          () => NativePixelBuffer.allocate(
              width: 1 << 30, height: 1 << 28, channels: 4, hasTransparency: true),
          throwsA(isA<OutOfMemoryError>()));
      expect(NativePixelBuffer.live, before);
    });

    test('runner: low memory gives IMAGE_TOO_LARGE before any encode; buffer freed', () async {
      var passes = 0;
      final r = await CompressionRunner(preflight: withMeminfo(meminfo(1))).run(
          CompressionRequest(pixels: syntheticBuffer(320, 240), maxKb: 50, format: OutputFormat.jpeg),
          onProgress: (_, _) => passes++);
      expect(((r as PlanFailed).failure.reason, passes), (Reason.imageTooLarge, 0));
      expect(NativePixelBuffer.live, 0);
    });

    for (final (name, wrap) in [('Dart heap', _dartHeapOom), ('libjpeg-turbo', _libjpegOom)]) {
      test('runner: $name out of memory gives OUT_OF_MEMORY_HANDLED; buffer freed', () async {
        for (final format in OutputFormat.values) {
          final r = await CompressionRunner(preflight: withMeminfo(null), wrapEncoder: wrap).run(
              CompressionRequest(pixels: syntheticBuffer(320, 240), maxKb: 50, format: format));
          expect((r as PlanFailed).failure.reason, Reason.outOfMemoryHandled);
        }
        expect(NativePixelBuffer.live, 0);
      });
    }

    test('isAllocationFailure: only memory errors', () {
      expect(isAllocationFailure(const OutOfMemoryError()), isTrue);
      for (final kind in JpegEncodeErrorKind.values) {
        expect(isAllocationFailure(JpegEncodeException(kind, '')),
            kind == JpegEncodeErrorKind.initFailed || kind == JpegEncodeErrorKind.outOfMemory);
      }
      expect(isAllocationFailure(StateError('x')), isFalse);
    });
  });
}
