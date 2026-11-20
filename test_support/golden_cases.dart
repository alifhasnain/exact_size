import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/data/turbo_jpeg_encoder.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/compression/domain/subsampling.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_hashes.dart';
import 'synthetic_images.dart';

enum Kind { photo, signature }

/// One fixed (image, target) case. Names are stable keys into [goldenOutcomes].
final class GoldenCase {
  const GoldenCase(this.name, this.kind, this.width, this.height, this.maxKb,
      {this.minKb, this.format = OutputFormat.jpeg, this.channels = 3, this.seed = 1, this.dpi});
  final String name;
  final Kind kind;
  final int width, height, maxKb, channels, seed;
  final int? minKb, dpi;
  final OutputFormat format;

  Uint8List pixels() => switch (kind) {
        Kind.photo => syntheticPhoto(width, height, seed: seed, channels: channels),
        Kind.signature => syntheticSignature(width, height, seed: seed, channels: channels),
      };
}

const goldenCases = <GoldenCase>[
  GoldenCase('photo_640x480_20-50', Kind.photo, 640, 480, 50, minKb: 20),
  GoldenCase('photo_640x480_max100', Kind.photo, 640, 480, 100),
  GoldenCase('photo_640x480_49-50_narrow', Kind.photo, 640, 480, 50, minKb: 49),
  GoldenCase('photo_1200x900_100-200', Kind.photo, 1200, 900, 200, minKb: 100),
  GoldenCase('photo_1600x1250_200-500', Kind.photo, 1600, 1250, 500, minKb: 200),
  GoldenCase('photo_1600x1250_max300', Kind.photo, 1600, 1250, 300, seed: 2),
  GoldenCase('photo_300x300_max3_fail', Kind.photo, 300, 300, 3),
  GoldenCase('photo_300x300_10-20', Kind.photo, 300, 300, 20, minKb: 10),
  GoldenCase('photo_640x480_20-50_dpi300', Kind.photo, 640, 480, 50, minKb: 20, dpi: 300),
  GoldenCase('photo_800x600_png_max2000', Kind.photo, 800, 600, 2000, format: OutputFormat.png),
  GoldenCase('photo_640x480_png_20-50_fail', Kind.photo, 640, 480, 50, minKb: 20, format: OutputFormat.png),
  GoldenCase('photo_200x200_png_max200', Kind.photo, 200, 200, 200, format: OutputFormat.png, seed: 3),
  GoldenCase('photo_rgba_640x480_20-50', Kind.photo, 640, 480, 50, minKb: 20, channels: 4),
  GoldenCase('photo_rgba_400x300_png_max600', Kind.photo, 400, 300, 600, format: OutputFormat.png, channels: 4),
  GoldenCase('photo_rgba_1200x900_max150', Kind.photo, 1200, 900, 150, channels: 4, seed: 4),
  GoldenCase('sig_140x60_10-20_padded', Kind.signature, 140, 60, 20, minKb: 10),
  GoldenCase('sig_140x60_max10', Kind.signature, 140, 60, 10),
  GoldenCase('sig_300x100_20-50', Kind.signature, 300, 100, 50, minKb: 20, seed: 2),
  GoldenCase('sig_rgba_140x60_10-20', Kind.signature, 140, 60, 20, minKb: 10, channels: 4),
  GoldenCase('sig_140x60_png_max20', Kind.signature, 140, 60, 20, format: OutputFormat.png),
  GoldenCase('sig_140x60_png_10-20_fail', Kind.signature, 140, 60, 20, minKb: 10, format: OutputFormat.png),
  GoldenCase('sig_600x200_5-10', Kind.signature, 600, 200, 10, minKb: 5, seed: 3),
  GoldenCase('sig_rgba_600x200_png_max50', Kind.signature, 600, 200, 50, format: OutputFormat.png, channels: 4),
  GoldenCase('sig_300x100_49-50_narrow', Kind.signature, 300, 100, 50, minKb: 49, seed: 4),
  GoldenCase('photo_1024x768_80-100', Kind.photo, 1024, 768, 100, minKb: 80, seed: 2),
  GoldenCase('photo_1024x768_30-35', Kind.photo, 1024, 768, 35, minKb: 30, seed: 3),
  GoldenCase('photo_480x640_max25', Kind.photo, 480, 640, 25, seed: 4),
  GoldenCase('photo_2000x1000_150-250', Kind.photo, 2000, 1000, 250, minKb: 150, seed: 5),
  GoldenCase('photo_640x480_60-62', Kind.photo, 640, 480, 62, minKb: 60, seed: 5),
  GoldenCase('photo_320x240_max2_fail', Kind.photo, 320, 240, 2, seed: 6),
];

/// Runs [c] through the real runner (worker isolate, libjpeg-turbo, PNG) and
/// describes the outcome: `<format> <bytes> q<quality> pad<bytes> <sha256>`
/// or `FAIL <REASON> <closest bytes>`.
Future<String> runGolden(GoldenCase c) async {
  final px = NativePixelBuffer.allocate(
      width: c.width, height: c.height, channels: c.channels, hasTransparency: c.channels == 4);
  px.bytes.setAll(0, c.pixels());
  final plan = await const CompressionRunner().run(
      CompressionRequest(pixels: px, minKb: c.minKb, maxKb: c.maxKb, format: c.format, dpi: c.dpi));
  return switch (plan) {
    ReadyToWrite r =>
      '${r.format.name} ${r.bytes.length} q${r.quality ?? '-'} pad${r.paddingBytes} ${sha256.convert(r.bytes)}',
    PlanFailed(:final failure) => 'FAIL ${failure.reason.code} ${failure.closestBytes}',
  };
}

/// FEAT-004-T22 (FR-15, AC-6.1): every case twice, identical, and equal to the
/// recorded golden. Shared by test/ (host) and integration_test/ (emulator).
void defineGoldenDeterminismTests() {
  test('golden cases are byte-identical run to run and match the goldens', () async {
    final actual = <String, String>{};
    for (final c in goldenCases) {
      final first = await runGolden(c);
      expect(await runGolden(c), first, reason: '${c.name}: second run differs');
      actual[c.name] = first;
    }
    final mismatches = [
      for (final e in actual.entries)
        if (goldenOutcomes[e.key] != e.value) e.key,
    ];
    if (mismatches.isNotEmpty) {
      // Printed so a deliberate encoder change can update golden_hashes.dart.
      // ignore: avoid_print
      print('GOLDEN-ACTUAL-BEGIN\n'
          '${actual.entries.map((e) => "  '${e.key}': '${e.value}',").join('\n')}\n'
          'GOLDEN-ACTUAL-END');
    }
    expect(mismatches, isEmpty, reason: 'outcome differs from golden_hashes.dart');
    expect(actual.values.where((v) => v.contains(' pad') && !v.contains(' pad0 ')), isNotEmpty,
        reason: 'at least one padded case');
    expect(NativePixelBuffer.live, 0);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('changing a pinned encoder flag changes the output, so the goldens would fail', () {
    final px = NativePixelBuffer.allocate(width: 640, height: 480, channels: 3, hasTransparency: false);
    try {
      px.bytes.setAll(0, syntheticPhoto(640, 480));
      String hash({required bool huffman}) => sha256
          .convert(const TurboJpegEncoder().encodeJpeg(px.pointer,
              width: 640, height: 480, quality: 80, subsampling: Subsampling.yuv420, optimiseHuffman: huffman))
          .toString();
      expect(hash(huffman: true), hash(huffman: true));
      expect(hash(huffman: true), isNot(hash(huffman: false)));
    } finally {
      px.free();
    }
  });
}
