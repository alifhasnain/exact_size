import 'dart:typed_data';

import 'package:exact_size/features/compression/domain/pixel_buffer.dart';

/// Dart-heap stand-in for the native PixelBuffer (ADR-003); counts allocations.
class TestPixels implements PixelBuffer {
  TestPixels(this.width, this.height, this.channels, this.bytes, {required this.hasTransparency}) {
    allocations++;
  }
  static int allocations = 0;

  @override
  final int width, height;
  @override
  int channels;
  @override
  bool hasTransparency;
  @override
  final Uint8List bytes;

  @override
  int get stride => width * channels;

  @override
  double get upscaleFactor => 1.0;
  @override
  ({int x, int y, int w, int h})? get cropRect => null;
  @override
  int get rotationApplied => 0;

  @override
  void markAlphaRemoved() {
    channels = 3;
    hasTransparency = false;
  }
}
