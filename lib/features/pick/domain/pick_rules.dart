import '../../crop/domain/crop_types.dart';
import 'pick_types.dart';

/// Pure rules for picking (FR-6, FR-8, FR-10, FR-11, FR-14, FR-20).
abstract final class PickRules {
  /// Only a well-formed `content://` URI is handed on (FR-8); a share from
  /// ExactSize's own provider is refused (FR-20).
  static bool acceptable(Picked p) {
    if (p.origin == PickOrigin.share && p.fromOwnApp) return false;
    final uri = Uri.tryParse(p.uri);
    return uri != null && uri.scheme == 'content' && uri.host.isNotEmpty;
  }

  /// A camera result counts only if the file exists and is not empty (FR-6).
  static bool captureUsable({required bool exists, required int length}) => exists && length > 0;

  /// Probe refusal at pick time → the pick-screen message (PRD section 8, FR-14).
  static PickMessage message(Reason r) => switch (r) {
        Reason.unsupportedInput => PickMessage.unsupported,
        Reason.corruptInput => PickMessage.corrupt,
        Reason.imageTooLarge || Reason.outOfMemoryHandled => PickMessage.tooLarge,
        Reason.sourceUnavailable => PickMessage.sourceUnavailable,
        // Not produced by the probe; a safe generic refusal if they ever are.
        Reason.invalidTargetDimensions || Reason.cancelled || Reason.internalError => PickMessage.itemNotOpenable,
      };

  /// Camera files to delete after an attempt (FR-10, FR-11): a cancelled,
  /// lost or refused attempt drops its own file; an accepted one keeps its
  /// file and drops the previous session's.
  static Set<String> filesToDelete({required bool accepted, String? attemptFile, String? previousFile}) => {
        if (accepted) ?(previousFile == attemptFile ? null : previousFile) else ?attemptFile,
      };
}
