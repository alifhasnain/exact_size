import '../../crop/data/source_handle.dart';
import '../../crop/domain/crop_types.dart';

/// What the user tapped on the pick screen (FR-1, FR-21).
enum PickSource { camera, gallery, files }

/// Where a result came from. Decides camera-file lifetime only; never logged
/// or persisted (PRD section 1).
enum PickOrigin { camera, gallery, files, share }

/// Answer of the bridge to a launch request (FR-3, FR-5, AC-5.4).
enum LaunchOutcome { launched, busy, unavailable, lowSpace }

/// One message per refusal on the pick screen (PRD section 8).
enum PickMessage {
  pickerUnavailable,
  cameraNoPhoto,
  lowSpace,
  captureLost,
  itemNotOpenable,
  sourceUnavailable, // pick-time variant of FEAT-002's SOURCE_UNAVAILABLE
  unsupported,
  corrupt,
  tooLarge,
}

/// The session image handed to the flow (PRD section 1, FR-7, FR-10). The
/// camera file, when there is one, is owned by FEAT-001 (FR-11).
final class PickedImage {
  const PickedImage({required this.handle, required this.info, required this.origin, this.cameraFile});
  final SourceHandle handle;
  final SourceInfo info;
  final PickOrigin origin;

  /// Random file name inside the app-private camera folder; null otherwise.
  final String? cameraFile;

  @override
  String toString() => 'PickedImage(<redacted>)';
}

/// A result from the system picker bridge (tech.md section 4). Every
/// `toString` is redacted: URIs and file names never reach a log (FR-19).
sealed class SystemPickResult {
  const SystemPickResult();
  @override
  String toString() => '$runtimeType(<redacted>)';
}

final class Picked extends SystemPickResult {
  const Picked({required this.uri, required this.origin, this.fromOwnApp = false});
  final String uri;
  final PickOrigin origin;

  /// A share whose URI belongs to ExactSize's own provider (FR-20).
  final bool fromOwnApp;
}

final class Captured extends SystemPickResult {
  const Captured({required this.uri, required this.fileName});
  final String uri;
  final String fileName;
}

final class Cancelled extends SystemPickResult {
  const Cancelled({required this.origin, this.fileName});
  final PickOrigin origin;
  final String? fileName;
}

/// The camera returned after a process restart without a usable file (FR-17).
final class CaptureLost extends SystemPickResult {
  const CaptureLost({this.fileName});
  final String? fileName;
}

final class NotOpenable extends SystemPickResult {
  const NotOpenable({required this.origin});
  final PickOrigin origin;
}
