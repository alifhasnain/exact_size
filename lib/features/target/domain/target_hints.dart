import '../../crop/domain/crop_math.dart';
import '../../crop/domain/crop_types.dart';
import '../../crop/domain/target_check.dart';

/// FR-13 hint threshold, not a limit (PRD OQ-12 [Assumption]).
const smallTargetHintPx = 16;

/// What the target step tells the user about the photo and the chosen size
/// (FR-11, FR-12, FR-13).
final class TargetHints {
  const TargetHints({
    required this.photoWidth,
    required this.photoHeight,
    required this.canUsePhotoSize,
    required this.enlarges,
    required this.verySmall,
  });

  /// Photo size after EXIF orientation (the photo line).
  final int photoWidth;
  final int photoHeight;

  /// "Use photo size" is offered only when the photo itself is a valid target.
  final bool canUsePhotoSize;

  /// The target is larger than the crop can cover: the photo gets enlarged.
  final bool enlarges;

  /// A side is under [smallTargetHintPx].
  final bool verySmall;
}

/// Hints for [info] and the typed size; [width] and [height] count only when
/// both are given and pass `checkTarget`, so an invalid size shows no hint.
TargetHints targetHints(SourceInfo info, {int? width, int? height}) {
  final (pw, ph) = CropMath.orientedSize(info, 0);
  final target = width != null && height != null ? Target(width, height) : null;
  final valid = target != null && checkTarget(target) == null;
  return TargetHints(
    photoWidth: pw,
    photoHeight: ph,
    canUsePhotoSize: checkTarget(Target(pw, ph)) == null,
    enlarges: valid && target.width / CropMath.coverWidth(pw, ph, target) > 1.0,
    verySmall: valid && (target.width < smallTargetHintPx || target.height < smallTargetHintPx),
  );
}
