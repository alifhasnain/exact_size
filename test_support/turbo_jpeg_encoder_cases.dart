import 'dart:ffi';

import 'package:exact_size/features/compression/data/turbo_jpeg_encoder.dart';
import 'package:exact_size/features/compression/domain/subsampling.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import 'jpeg_markers.dart';
import 'synthetic_image.dart';

/// FEAT-004-T06 checks, shared by test/ (host) and integration_test/ (emulator).
void defineTurboJpegEncoderTests() {
  const w = 640, h = 480;
  late Pointer<Uint8> pixels;
  const encoder = TurboJpegEncoder();

  setUpAll(() {
    final rgb = syntheticRgba(w, h, channels: 3);
    pixels = malloc<Uint8>(rgb.length)..asTypedList(rgb.length).setAll(0, rgb);
  });
  tearDownAll(() => malloc.free(pixels));

  for (final (sub, lumaSampling) in [(Subsampling.yuv420, 0x22), (Subsampling.yuv444, 0x11)]) {
    test('marker layout for ${sub.name}', () {
      final jpeg = encoder.encodeJpeg(pixels,
          width: w, height: h, quality: 85, subsampling: sub, optimiseHuffman: true, dpi: 300);
      final info = parseJpeg(jpeg);
      expect(info.markers.first, 0xD8, reason: 'SOI');
      expect(info.markers[1], 0xE0, reason: 'APP0 directly after SOI');
      expect(info.jfif, (units: 1, xDensity: 300, yDensity: 300));
      expect(info.markers, isNot(contains(0xE1)), reason: 'no APP1 (EXIF)');
      expect(info.markers, isNot(contains(0xE2)), reason: 'no APP2 (ICC)');
      expect(info.sof!.marker, 0xC0, reason: 'SOF0 baseline');
      expect(info.sof!.sampling, [lumaSampling, 0x11, 0x11]);
      expect(jpeg.sublist(jpeg.length - 2), [0xFF, 0xD9], reason: 'EOI last');
    });
  }

  test('no DPI keeps the JFIF aspect default', () {
    final jpeg = encoder.encodeJpeg(pixels,
        width: w, height: h, quality: 75, subsampling: Subsampling.yuv420, optimiseHuffman: false);
    expect(parseJpeg(jpeg).jfif, (units: 0, xDensity: 1, yDensity: 1));
  });

  test('two encodes of the same input are byte-identical', () {
    Object enc() => encoder.encodeJpeg(pixels,
        width: w, height: h, quality: 60, subsampling: Subsampling.yuv444, optimiseHuffman: true);
    expect(enc(), enc());
  });

  test('invalid parameters give the typed error, not a crash', () {
    Matcher kind(JpegEncodeErrorKind k) =>
        throwsA(isA<JpegEncodeException>().having((e) => e.kind, 'kind', k));
    expect(
        () => encoder.encodeJpeg(pixels,
            width: w, height: h, quality: 0, subsampling: Subsampling.yuv420, optimiseHuffman: true),
        kind(JpegEncodeErrorKind.invalidParameter));
    expect(
        () => encoder.encodeJpeg(pixels,
            width: w, height: h, quality: 80, subsampling: Subsampling.yuv420,
            optimiseHuffman: true, dpi: 70000),
        kind(JpegEncodeErrorKind.invalidParameter));
    expect(
        () => encoder.encodeJpeg(nullptr,
            width: w, height: h, quality: 80, subsampling: Subsampling.yuv420, optimiseHuffman: true),
        kind(JpegEncodeErrorKind.invalidParameter));
  });
}
