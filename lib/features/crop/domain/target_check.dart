import 'crop_types.dart';

/// Largest side in pixels (PRD section 8 [Assumption]).
const maxTargetSide = 10000;

/// Largest pixel count: 24 MP (PRD section 8, FEAT-004 OQ-4).
const maxTargetPixels = 24000000;

/// Message for a refused target (PRD section 8). The UI maps it to an ARB
/// string (FEAT-002-T10).
enum TargetDimensionsMessage {
  /// "Enter a width and height between 1 and 10,000 pixels."
  sideOutOfRange,

  /// "That size is too large for this app. Choose a smaller size."
  tooManyPixels,
}

/// Defensive re-check of W×H (FR-1). FEAT-005 validates entry first.
/// Returns null when the target is valid; otherwise the message for
/// `INVALID_TARGET_DIMENSIONS`.
TargetDimensionsMessage? checkTarget(Target t) {
  bool sideOk(int v) => v >= 1 && v <= maxTargetSide;
  if (!sideOk(t.width) || !sideOk(t.height)) return TargetDimensionsMessage.sideOutOfRange;
  if (t.width * t.height > maxTargetPixels) return TargetDimensionsMessage.tooManyPixels;
  return null;
}
