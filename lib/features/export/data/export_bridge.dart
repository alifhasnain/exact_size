import '../domain/export_types.dart';

/// The Kotlin export bridge (ADR-007, tech.md section 4.2). Implementations never log:
/// arguments and results hold file names, URIs and paths (FR-27).
abstract interface class ExportBridge {
  Future<BridgeSave> save({required String src, required String name, required String mime, required int bytes});

  Future<BridgeSave> saveAs({required String src, required String name, required String mime, required int bytes});

  /// False on any error (FR-12).
  Future<bool> itemExists(String ref);

  /// False when no app can open the item (FR-15).
  Future<bool> open(String ref, String mime);

  /// False when the chooser could not be launched (FR-20).
  Future<bool> share(String path, String mime);

  /// Removes this app's unfinished saves; never asks for a permission (FR-16).
  Future<void> sweepIncomplete();
}
