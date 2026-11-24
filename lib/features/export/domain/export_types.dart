import '../../compression/domain/compression_result.dart';
import '../../crop/domain/crop_types.dart';
import 'export_outcome.dart';

/// The last verified save of the current result (FR-11, FR-12). [ref] is a content
/// URI (API 29+, save-as) or a path (API 28); never logged or shown.
final class SavedItem {
  const SavedItem({required this.ref, required this.displayName, this.viaSaveAs = false});
  final String ref;
  final String displayName;
  final bool viaSaveAs;

  @override
  String toString() => 'SavedItem(viaSaveAs: $viaSaveAs)';
}

/// Result of one bridge save or save-as call (tech 4.1).
sealed class BridgeSave {
  const BridgeSave();
}

final class BridgeSaved extends BridgeSave {
  const BridgeSaved({required this.name, required this.ref});
  final String name;
  final String ref;

  @override
  String toString() => 'BridgeSaved()';
}

/// API 28 only: the final name exists; the caller draws a new TOKEN (FR-13).
final class BridgeNameTaken extends BridgeSave {
  const BridgeNameTaken();

  @override
  String toString() => 'BridgeNameTaken()';
}

/// noSpace, saveFailed, permissionDenied, fileMissing or saveCancelled.
final class BridgeSaveError extends BridgeSave {
  const BridgeSaveError(this.outcome);
  final ExportOutcome outcome;

  @override
  String toString() => 'BridgeSaveError(${outcome.code})';
}

/// One export screen's input: FEAT-004's result and the output pixel size.
/// Family key: equal when it is the same result object and size.
final class ExportInput {
  const ExportInput(this.success, this.size);
  final CompressionSuccess success;
  final Target size;

  @override
  bool operator ==(Object other) => other is ExportInput && identical(other.success, success) && other.size == size;
  @override
  int get hashCode => Object.hash(identityHashCode(success), size);
  @override
  String toString() => 'ExportInput()';
}
