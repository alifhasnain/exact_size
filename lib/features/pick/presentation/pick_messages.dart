import '../../../l10n/app_localizations.dart';
import '../domain/pick_types.dart';

/// Pick-screen text for each refusal (FEAT-001 PRD section 8). Probe
/// refusals reuse FEAT-002's strings: same message, one translation.
extension PickMessageText on PickMessage {
  String text(AppLocalizations l) => switch (this) {
        PickMessage.pickerUnavailable => l.pickPickerUnavailable,
        PickMessage.cameraNoPhoto => l.pickCameraNoPhoto,
        PickMessage.lowSpace => l.pickLowSpace,
        PickMessage.captureLost => l.pickCaptureLost,
        PickMessage.itemNotOpenable => l.pickItemNotOpenable,
        PickMessage.sourceUnavailable => l.pickSourceUnavailable,
        PickMessage.unsupported => l.cropUnsupportedInput,
        PickMessage.corrupt => l.cropCorruptInput,
        PickMessage.tooLarge => l.cropSourceTooLarge,
      };
}
