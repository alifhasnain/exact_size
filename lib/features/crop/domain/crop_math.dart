import 'dart:math' as math;

import 'crop_types.dart';
import 'orientation.dart';

/// Gesture state of the crop frame, in oriented source pixels (after EXIF and
/// [quarterTurns]). The crop height is always `cw · H / W` (FR-4).
final class CropState {
  const CropState({required this.cx, required this.cy, required this.cw, this.quarterTurns = 0});

  /// Centre of the crop region.
  final double cx;
  final double cy;

  /// Width of the crop region.
  final double cw;

  /// Manual clockwise rotation, 0..3 (FR-21).
  final int quarterTurns;

  CropState copyWith({double? cx, double? cy, double? cw, int? quarterTurns}) => CropState(
        cx: cx ?? this.cx,
        cy: cy ?? this.cy,
        cw: cw ?? this.cw,
        quarterTurns: quarterTurns ?? this.quarterTurns,
      );

  @override
  bool operator ==(Object other) =>
      other is CropState && other.cx == cx && other.cy == cy && other.cw == cw && other.quarterTurns == quarterTurns;
  @override
  int get hashCode => Object.hash(cx, cy, cw, quarterTurns);
  @override
  String toString() => 'CropState(cx: $cx, cy: $cy, cw: $cw, quarterTurns: $quarterTurns)';
}

/// Pure, deterministic crop maths (FR-4, FR-7, FR-8, FR-11, FR-12).
abstract final class CropMath {
  /// Shorter side of the crop region at maximum zoom, in source pixels (FR-4).
  static const minShortSide = 32;

  /// Maximum zoom relative to the cover scale (FR-4).
  static const maxZoom = 8;

  /// Transform from the raw stored image to what the user sees.
  static Orientation orientation(SourceInfo info, int quarterTurns) =>
      Orientation.fromExif(info.exifOrientation).then(Orientation.rotation(quarterTurns));

  /// Source size in oriented space.
  static (int, int) orientedSize(SourceInfo info, int quarterTurns) =>
      orientation(info, quarterTurns).orientedSize(info.rawWidth, info.rawHeight);

  /// Widest crop at ratio W:H that fits the [sw]×[sh] oriented source: the
  /// minimum zoom, no empty area in the frame.
  static double coverWidth(int sw, int sh, Target t) => math.min(sw.toDouble(), sh * t.width / t.height);

  /// Narrowest crop: shorter side 32 px or 8× the cover scale, whichever is
  /// reached first while zooming in; never wider than the cover (tiny sources).
  static double minWidth(int sw, int sh, Target t) {
    final cover = coverWidth(sw, sh, t);
    final at32 = t.width >= t.height ? minShortSide * t.width / t.height : minShortSide.toDouble();
    return math.min(cover, math.max(cover / maxZoom, at32));
  }

  /// Largest centred crop at ratio W:H (FR-4 initial state).
  static CropState initial(SourceInfo info, Target t, {int quarterTurns = 0}) {
    final (sw, sh) = orientedSize(info, quarterTurns);
    return CropState(cx: sw / 2, cy: sh / 2, cw: coverWidth(sw, sh, t), quarterTurns: quarterTurns);
  }

  /// Clamps width to [min, cover] and the region to the image.
  static CropState clamp(CropState s, int sw, int sh, Target t) {
    final cw = s.cw.clamp(minWidth(sw, sh, t), coverWidth(sw, sh, t));
    final ch = cw * t.height / t.width;
    return s.copyWith(
      cw: cw,
      cx: s.cx.clamp(cw / 2, math.max(cw / 2, sw - cw / 2)),
      cy: s.cy.clamp(ch / 2, math.max(ch / 2, sh - ch / 2)),
    );
  }

  /// Rounds the state once into an integer rect inside the oriented image
  /// (FR-8): the side that would overflow is fixed first, the other follows
  /// the ratio, so one side is within 0.5 px of the exact ratio.
  static CropRect toCropRect(CropState s, SourceInfo info, Target t) {
    final (sw, sh) = orientedSize(info, s.quarterTurns);
    final c = clamp(s, sw, sh, t);
    var w = c.cw.round().clamp(1, sw);
    var h = (w * t.height / t.width).round().clamp(1, sh);
    if (w * t.height / t.width > sh + 0.5) {
      w = (h * t.width / t.height).round().clamp(1, sw);
    }
    final x = (c.cx - w / 2).round().clamp(0, sw - w);
    final y = (c.cy - h / 2).round().clamp(0, sh - h);
    return CropRect(x, y, w, h);
  }

  /// `max(W / cropW, H / cropH)` on the rounded rect (FR-11).
  static double upscaleFactor(CropRect r, Target t) => math.max(t.width / r.w, t.height / r.h);

  /// Largest power of two `s` with `cropW / s ≥ W` and `cropH / s ≥ H`, else 1
  /// (FR-7): the decode never shrinks the crop region below the target.
  static int sampleSize(CropRect r, Target t) {
    var s = 1;
    while (r.w / (s * 2) >= t.width && r.h / (s * 2) >= t.height) {
      s *= 2;
    }
    return s;
  }
}
