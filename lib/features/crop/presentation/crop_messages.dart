import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/crop_reducers.dart';
import '../domain/crop_types.dart';
import '../domain/target_check.dart';

/// Part of the photo inside the frame, in physical directions (AC-9.1).
enum CropPosition { centre, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight }

/// Upscale level for the FR-11 notice and its announcements (AC-5.4).
enum UpscaleLevel {
  /// Factor ≤ 1.0: no notice.
  none,

  /// 1.0 < factor ≤ 2.0: information notice.
  enlarged,

  /// Factor > 2.0: notice, and "Continue anyway" confirmation at Continue.
  strong;

  static UpscaleLevel of(double factor) => factor > 2.0
      ? strong
      : factor > 1.0
          ? enlarged
          : none;
}

/// Maps crop reasons, notices and accessibility state to localised text
/// (FR-22, NFR-6). Every number, percentage and "W×H" is wrapped in Unicode
/// first-strong isolates (U+2068 … U+2069) so it stays readable in Arabic.
/// No message is built by concatenation.
class CropMessages {
  CropMessages(this._l10n)
      : _number = NumberFormat.decimalPattern(_l10n.localeName),
        _factor = NumberFormat('#,##0.#', _l10n.localeName),
        _percent = NumberFormat.percentPattern(_l10n.localeName);

  final AppLocalizations _l10n;
  final NumberFormat _number;
  final NumberFormat _factor;
  final NumberFormat _percent;

  /// Text for a failure. `INVALID_TARGET_DIMENSIONS` needs [targetMessage]
  /// (per-side or too large); without it the per-side text is used.
  String reason(Reason r, {TargetDimensionsMessage? targetMessage}) => switch (r) {
        Reason.invalidTargetDimensions => target(targetMessage ?? TargetDimensionsMessage.sideOutOfRange),
        Reason.unsupportedInput => _l10n.cropUnsupportedInput,
        Reason.corruptInput => _l10n.cropCorruptInput,
        Reason.sourceUnavailable => _l10n.cropSourceUnavailable,
        Reason.imageTooLarge => _l10n.cropSourceTooLarge,
        Reason.outOfMemoryHandled => _l10n.cropOutOfMemory,
        Reason.cancelled => _l10n.cropCancelled,
        Reason.internalError => _l10n.outcomeInternalError, // same PRD text as FEAT-004
      };

  /// PRD section 8 target messages (FR-1).
  String target(TargetDimensionsMessage m) => switch (m) {
        TargetDimensionsMessage.sideOutOfRange =>
          _l10n.cropTargetSideOutOfRange(_iso(_number.format(1)), _iso(_number.format(maxTargetSide))),
        TargetDimensionsMessage.tooManyPixels => _l10n.cropTargetTooLarge,
      };

  /// "300×80", isolated.
  String size(Target t) => _iso(_l10n.pixelSize(_number.format(t.width), _number.format(t.height)));

  /// FR-11 notice text for [factor], or null when no notice is shown.
  String? upscaleNotice(double factor, Target t) =>
      UpscaleLevel.of(factor) == UpscaleLevel.none ? null : _l10n.cropNoticeEnlarged(size(t));

  /// FR-11 confirmation text (factor > 2.0).
  String confirmEnlarge(double factor) => _l10n.cropConfirmEnlarge(_iso(_factor.format(factor)));

  String get animatedNotice => _l10n.cropNoticeAnimated;
  String get limitedPrecisionHint => _l10n.cropHintLimitedPrecision;

  /// Polite announcement when the upscale level changes to [level] (AC-9.4).
  String upscaleAnnouncement(UpscaleLevel level, double factor, Target t) => switch (level) {
        UpscaleLevel.none => _l10n.cropAnnounceNoEnlargement,
        UpscaleLevel.enlarged => _l10n.cropNoticeEnlarged(size(t)),
        UpscaleLevel.strong => _l10n.cropAnnounceStrongEnlargement(_iso(_factor.format(factor))),
      };

  /// Crop area label (AC-9.1); [zoom] is relative to the cover scale (1.0 = 100%).
  String areaState(double zoom, CropPosition position) =>
      _l10n.cropAreaState(_iso(_percent.format(zoom)), position.name);

  /// Announcement for a move that stopped at an edge (AC-9.3); null for none.
  String? edgeReached(Edge e) => e == Edge.none ? null : _l10n.cropEdgeReached(e.name);

  /// Screen-reader label of a corner handle (AC-13.7).
  String handleLabel(Corner c) => _l10n.cropHandleLabel(c.name);

  static String _iso(String s) => '\u2068$s\u2069';
}
