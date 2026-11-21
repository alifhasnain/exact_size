import '../domain/pick_types.dart';

/// The system picker bridge seen from Dart (tech.md section 4, ADR-006).
/// Errors arrive as a `PlatformException` with an enum code and no message.
abstract interface class SystemPicker {
  /// A camera app can take a photo (FR-5).
  Future<bool> cameraAvailable();

  Future<LaunchOutcome> launch(PickSource source);

  /// The pending result, or null; reading it clears it (FR-15).
  Future<SystemPickResult?> takeResult();

  /// The camera file name while the camera app is open (FR-11, FR-17).
  Future<String?> pendingCaptureName();

  /// Fires when a result is waiting; then call [takeResult].
  Stream<void> get resultReady;
}
