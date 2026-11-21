import 'crop_types.dart';

/// One of the 8 rotate/flip transforms (dihedral group D4) that turn the raw
/// stored image into the oriented image the user sees (FR-3, FR-21).
///
/// Applied as: mirror left-right first (if [mirrored]), then rotate
/// [quarterTurns] × 90° clockwise. Coordinates are continuous pixel edges:
/// a W×H image spans [0, W] × [0, H].
final class Orientation {
  const Orientation._(this.mirrored, this.quarterTurns);

  static const identity = Orientation._(false, 0);

  /// EXIF `Orientation` 1–8 (TIFF 6.0 / EXIF 2.32). Anything else, or null,
  /// means 1 (PRD section 8).
  factory Orientation.fromExif(int? value) => switch (value) {
        2 => const Orientation._(true, 0), // mirror horizontal
        3 => const Orientation._(false, 2), // rotate 180
        4 => const Orientation._(true, 2), // mirror vertical
        5 => const Orientation._(true, 3), // mirror horizontal, rotate 270 CW
        6 => const Orientation._(false, 1), // rotate 90 CW
        7 => const Orientation._(true, 1), // mirror horizontal, rotate 90 CW
        8 => const Orientation._(false, 3), // rotate 270 CW
        _ => identity,
      };

  /// A manual rotation of [turns] × 90° clockwise (negative = counter-clockwise).
  factory Orientation.rotation(int turns) => Orientation._(false, turns % 4);

  final bool mirrored;

  /// 0..3, clockwise.
  final int quarterTurns;

  bool get isIdentity => !mirrored && quarterTurns == 0;

  /// This transform followed by [next] (for example EXIF, then the user's turns).
  Orientation then(Orientation next) => Orientation._(
        mirrored != next.mirrored,
        (next.mirrored ? next.quarterTurns - quarterTurns : next.quarterTurns + quarterTurns) % 4,
      );

  /// Undoes this transform. Every mirrored element is its own inverse.
  Orientation get inverse => mirrored ? this : Orientation._(false, (4 - quarterTurns) % 4);

  /// Size after the transform of a [w]×[h] image.
  (int, int) orientedSize(int w, int h) => quarterTurns.isOdd ? (h, w) : (w, h);

  /// Maps a point of a [w]×[h] raw image to oriented coordinates.
  (double, double) mapPoint(double x, double y, int w, int h) {
    var (px, py, pw, ph) = (x, y, w, h);
    if (mirrored) px = pw - px;
    for (var i = 0; i < quarterTurns; i++) {
      (px, py) = (ph - py, px);
      (pw, ph) = (ph, pw);
    }
    return (px, py);
  }

  /// Maps a rectangle of a [w]×[h] raw image to oriented coordinates.
  CropRect mapRect(CropRect r, int w, int h) {
    final (x0, y0) = mapPoint(r.x.toDouble(), r.y.toDouble(), w, h);
    final (x1, y1) = mapPoint((r.x + r.w).toDouble(), (r.y + r.h).toDouble(), w, h);
    final (left, top) = (x0 < x1 ? x0 : x1, y0 < y1 ? y0 : y1);
    return CropRect(left.round(), top.round(), (x1 - x0).abs().round(), (y1 - y0).abs().round());
  }

  /// Maps a rectangle of the oriented image back to the [rawW]×[rawH] raw image.
  CropRect mapRectToRaw(CropRect oriented, int rawW, int rawH) {
    final (ow, oh) = orientedSize(rawW, rawH);
    return inverse.mapRect(oriented, ow, oh);
  }

  /// Affine matrix raw → oriented for painting the preview:
  /// x' = a·x + b·y + tx, y' = c·x + d·y + ty. Returned as (a, b, c, d, tx, ty).
  (double, double, double, double, double, double) matrix(int w, int h) {
    final (tx, ty) = mapPoint(0, 0, w, h);
    final (ax, ay) = mapPoint(1, 0, w, h);
    final (bx, by) = mapPoint(0, 1, w, h);
    return (ax - tx, bx - tx, ay - ty, by - ty, tx, ty);
  }

  @override
  bool operator ==(Object other) =>
      other is Orientation && other.mirrored == mirrored && other.quarterTurns == quarterTurns;
  @override
  int get hashCode => Object.hash(mirrored, quarterTurns);
  @override
  String toString() => 'Orientation(mirrored: $mirrored, quarterTurns: $quarterTurns)';
}
