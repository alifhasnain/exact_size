import 'dart:math' as math;
import 'dart:typed_data';

/// FEAT-004-T22 synthetic image generator. Seeded and deterministic; never a
/// real photo or signature (tasks.md). RGB with [channels] = 3, RGBA with 4.

/// Photo-like: smooth gradients, fine noise and a few soft shapes. In RGBA the
/// shapes are partly transparent, so flattening is exercised.
Uint8List syntheticPhoto(int width, int height, {int seed = 1, int channels = 3}) {
  final out = Uint8List(width * height * channels);
  final rnd = _Lcg(seed);
  final shapes = [
    for (var k = 0; k < 6; k++)
      (
        cx: rnd.next(width),
        cy: rnd.next(height),
        r: 10 + rnd.next(math.max(11, math.min(width, height) ~/ 3)),
        color: [rnd.next(256), rnd.next(256), rnd.next(256)],
        alpha: 80 + rnd.next(176),
      ),
  ];
  var i = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var r = (x * 200) ~/ width + 30;
      var g = (y * 180) ~/ height + 40;
      var b = ((x + y) * 160) ~/ (width + height) + 60;
      var a = 255;
      for (final s in shapes) {
        final dx = x - s.cx, dy = y - s.cy;
        if (dx * dx + dy * dy <= s.r * s.r) {
          r = (r + s.color[0]) >> 1;
          g = (g + s.color[1]) >> 1;
          b = (b + s.color[2]) >> 1;
          if (channels == 4) a = math.min(a, s.alpha);
        }
      }
      final n = rnd.next(24) - 12; // sensor-like noise
      out[i++] = (r + n).clamp(0, 255);
      out[i++] = (g + n).clamp(0, 255);
      out[i++] = (b + n).clamp(0, 255);
      if (channels == 4) out[i++] = a;
    }
  }
  return out;
}

/// Signature-like: thin dark strokes (1–2 px wavy lines) on white. In RGBA
/// the background is transparent and the strokes are opaque.
Uint8List syntheticSignature(int width, int height, {int seed = 1, int channels = 3}) {
  final out = Uint8List(width * height * channels);
  for (var i = 0; i < out.length; i += channels) {
    out[i] = out[i + 1] = out[i + 2] = 255;
    if (channels == 4) out[i + 3] = 0;
  }
  final rnd = _Lcg(seed);
  final strokes = 2 + rnd.next(3);
  for (var k = 0; k < strokes; k++) {
    final amp = height * (0.15 + rnd.next(20) / 100);
    final freq = 0.03 + rnd.next(60) / 1000;
    final phase = rnd.next(628) / 100;
    final mid = height * (0.3 + rnd.next(40) / 100);
    final thick = 1 + rnd.next(2);
    final x0 = rnd.next(width ~/ 4), x1 = width - rnd.next(width ~/ 4);
    for (var x = x0; x < x1; x++) {
      final yc = (mid + amp * math.sin(x * freq + phase)).round();
      for (var t = 0; t < thick; t++) {
        final y = yc + t;
        if (y < 0 || y >= height) continue;
        final p = (y * width + x) * channels;
        out[p] = 20;
        out[p + 1] = 24;
        out[p + 2] = 60; // dark blue ink
        if (channels == 4) out[p + 3] = 255;
      }
    }
  }
  return out;
}

/// Small LCG: the same sequence on every platform.
final class _Lcg {
  _Lcg(this._s);
  int _s;
  int next(int bound) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return (_s >> 8) % bound;
  }
}
