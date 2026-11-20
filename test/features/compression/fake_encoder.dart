import 'dart:typed_data';

import 'package:exact_size/features/compression/domain/encoder.dart';
import 'package:exact_size/features/compression/domain/subsampling.dart';

/// Size of a JPEG for one (config, quality) pair; the search tests script it.
typedef SizeCurve = int Function(
    Subsampling subsampling, bool optimiseHuffman, int quality);

/// Test encoder (NFR-9): returns zero-filled bytes whose length follows a
/// scripted size curve, and records every call so tests can count passes.
class FakeEncoder implements Encoder {
  FakeEncoder({required this.jpegSize, this.pngSize = 0});

  final SizeCurve jpegSize;
  final int pngSize;
  final calls = <({Subsampling subsampling, bool optimiseHuffman, int quality})>[];
  int pngCalls = 0;

  @override
  Uint8List encodeJpeg({
    required int quality,
    required Subsampling subsampling,
    required bool optimiseHuffman,
  }) {
    calls.add((subsampling: subsampling, optimiseHuffman: optimiseHuffman, quality: quality));
    return Uint8List(jpegSize(subsampling, optimiseHuffman, quality));
  }

  @override
  Uint8List encodePng() {
    pngCalls++;
    return Uint8List(pngSize);
  }
}

/// A plausible monotonic curve: size grows with quality; 4:4:4 adds ~40 %,
/// standard Huffman adds ~5 %.
SizeCurve linearCurve({required int atQ1, required int atQ100}) =>
    (subsampling, optimise, q) {
      var size = atQ1 + (atQ100 - atQ1) * (q - 1) ~/ 99;
      if (subsampling == Subsampling.yuv444) size = size * 14 ~/ 10;
      if (!optimise) size = size * 105 ~/ 100;
      return size;
    };
