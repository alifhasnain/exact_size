import 'crop_math.dart';
import 'crop_types.dart';

/// Physical move direction (no RTL mirroring: the crop area is drawn in
/// physical coordinates, FR-23).
enum MoveDirection { left, right, up, down }

/// Edge a move stopped at, for the TalkBack announcement (FR-5).
enum Edge { none, left, right, top, bottom }

/// Result of a move: the new state and the edge it hit, if any.
typedef MoveResult = ({CropState state, Edge edgeReached});

/// Pure reducers on [CropState] (FR-4, FR-5, FR-27). Every result is clamped:
/// inside the image, `min ≤ cw ≤ cover`, ratio exactly W:H.
abstract final class CropReducers {
  /// Move step: 5% of the visible crop region (FR-27 [Assumption]).
  static const moveStep = 0.05;

  /// Zoom button / action factor per press [Assumption: PRD gives no step].
  static const zoomStep = 1.25;

  static (int, int) _size(CropState s, SourceInfo info) => CropMath.orientedSize(info, s.quarterTurns);

  /// Moves the crop region by ([dx], [dy]) oriented source pixels.
  static CropState drag(CropState s, double dx, double dy, SourceInfo info, Target t) {
    final (sw, sh) = _size(s, info);
    return CropMath.clamp(s.copyWith(cx: s.cx + dx, cy: s.cy + dy), sw, sh, t);
  }

  /// Zooms by [scale] (> 1 zooms in, so the crop region shrinks) about the
  /// focal point ([fx], [fy]) in oriented source pixels, which stays put where
  /// the clamps allow.
  static CropState pinch(CropState s, double scale, double fx, double fy, SourceInfo info, Target t) {
    final (sw, sh) = _size(s, info);
    final cw = (s.cw / scale).clamp(CropMath.minWidth(sw, sh, t), CropMath.coverWidth(sw, sh, t));
    final k = cw / s.cw;
    return CropMath.clamp(s.copyWith(cw: cw, cx: fx + (s.cx - fx) * k, cy: fy + (s.cy - fy) * k), sw, sh, t);
  }

  /// Zoom in/out action or button: a pinch with the focal point at the frame
  /// centre.
  static CropState zoom(CropState s, {required bool zoomIn, required SourceInfo info, required Target t}) =>
      pinch(s, zoomIn ? zoomStep : 1 / zoomStep, s.cx, s.cy, info, t);

  /// Nudge action or button: 5% of the crop region in [direction]; stops at the
  /// image edge and reports it.
  static MoveResult move(CropState s, MoveDirection direction, SourceInfo info, Target t) {
    final ch = s.cw * t.height / t.width;
    final (dx, dy) = switch (direction) {
      MoveDirection.left => (-s.cw * moveStep, 0.0),
      MoveDirection.right => (s.cw * moveStep, 0.0),
      MoveDirection.up => (0.0, -ch * moveStep),
      MoveDirection.down => (0.0, ch * moveStep),
    };
    final next = drag(s, dx, dy, info, t);
    // Stopped short of the full step: the region now touches that edge.
    final short = (next.cx - s.cx - dx).abs() > 1e-9 || (next.cy - s.cy - dy).abs() > 1e-9;
    final edge = !short
        ? Edge.none
        : switch (direction) {
            MoveDirection.left => Edge.left,
            MoveDirection.right => Edge.right,
            MoveDirection.up => Edge.top,
            MoveDirection.down => Edge.bottom,
          };
    return (state: next, edgeReached: edge);
  }

  /// Centres the crop region on the image, keeping zoom and rotation.
  static CropState centre(CropState s, SourceInfo info, Target t) {
    final (sw, sh) = _size(s, info);
    return CropMath.clamp(s.copyWith(cx: sw / 2, cy: sh / 2), sw, sh, t);
  }

  /// Back to the initial crop: largest centred area, no manual rotation.
  static CropState reset(SourceInfo info, Target t) => CropMath.initial(info, t);
}
