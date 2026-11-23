import '../../../l10n/app_localizations.dart';
import '../../compression/presentation/outcome_messages.dart';
import '../../crop/domain/crop_types.dart';
import '../../crop/presentation/crop_messages.dart';
import '../domain/target_hints.dart';
import '../domain/target_input.dart';

/// Localised text for the target step (FR-15, NFR-4). Pixel and KB messages
/// are FEAT-002's and FEAT-004's own mappings, so their limits, number format
/// and bidi isolates stay in one place (NFR-5). Labels are read from
/// [AppLocalizations] directly.
class TargetMessages {
  TargetMessages(this._l10n)
      : _crop = CropMessages(_l10n),
        _outcome = OutcomeMessages(_l10n);

  final AppLocalizations _l10n;
  final CropMessages _crop;
  final OutcomeMessages _outcome;

  String error(TargetError e) => switch (e) {
        PixelRangeError(:final message) => _crop.target(message),
        PixelsNotWhole() => _l10n.targetPixelsNotWhole,
        KbError(:final message) => _outcome.target(message),
      };

  /// "Your photo: 4000×3000 px" (FR-12), size isolated.
  String photoSize(TargetHints h) => _l10n.targetPhotoSize(_crop.size(Target(h.photoWidth, h.photoHeight)));

  /// FR-11 notice; reuses FEAT-002's text (OQ-T3).
  String enlarged(Target t) => _l10n.cropNoticeEnlarged(_crop.size(t));

  /// FR-13 notice.
  String get verySmall => _l10n.targetHintVerySmall;
}
