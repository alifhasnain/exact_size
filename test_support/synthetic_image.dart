import 'dart:typed_data';

/// Deterministic synthetic 8-bit test image (gradients, noise, hard edges),
/// RGBA by default or RGB with [channels] = 3.
/// Never a real photo (tasks.md: synthetic test data only). T22 replaces this
/// with the full generator.
Uint8List syntheticRgba(int width, int height, {int seed = 1, int channels = 4}) {
  final out = Uint8List(width * height * channels);
  var s = seed;
  var i = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      s = (s * 1103515245 + 12345) & 0x7fffffff; // LCG noise, fixed seed
      final noise = (s >> 16) & 0x1f;
      final edge = ((x ~/ 64) + (y ~/ 64)).isEven ? 40 : 0; // checker edges
      out[i++] = ((x * 255) ~/ width + noise) & 0xff;
      out[i++] = ((y * 255) ~/ height + edge) & 0xff;
      out[i++] = (((x + y) * 255) ~/ (width + height) + noise) & 0xff;
      if (channels == 4) out[i++] = 255;
    }
  }
  return out;
}
