import 'compression_result.dart';
import 'pixel_buffer.dart';

/// Prepares pixels for JPEG (FR-12, ADR-003): composites RGBA onto white and
/// compacts 4 → 3 channels in the same buffer, with no new pixel allocation.
///
/// Integer composite with round-half-up:
/// `out = (c·a + 255·(255 − a) + 127) ÷ 255`. Returns the `transparencyFlattened`
/// notice only when some pixel was actually transparent; RGB input is untouched.
Set<Notice> flattenForJpeg(PixelBuffer px) {
  if (px.channels == 3) return const {};
  final b = px.bytes;
  final n = px.width * px.height;
  // Forward pass: pixel i is read from 4i before being written to 3i (≤ 4i),
  // so compaction never overwrites unread data.
  for (var i = 0, src = 0, dst = 0; i < n; i++, src += 4, dst += 3) {
    final a = b[src + 3];
    if (a == 255) {
      b[dst] = b[src];
      b[dst + 1] = b[src + 1];
      b[dst + 2] = b[src + 2];
    } else {
      final white = 255 * (255 - a) + 127;
      b[dst] = (b[src] * a + white) ~/ 255;
      b[dst + 1] = (b[src + 1] * a + white) ~/ 255;
      b[dst + 2] = (b[src + 2] * a + white) ~/ 255;
    }
  }
  final hadTransparency = px.hasTransparency;
  px.markAlphaRemoved();
  return hadTransparency ? {Notice.transparencyFlattened} : const {};
}
