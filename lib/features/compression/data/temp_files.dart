import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/compression_result.dart';

/// The final file could not be written (low storage, unwritable folder).
final class TempWriteException implements Exception {
  const TempWriteException(this.detail);
  final String detail; // OS message only; never contains pixel data
  @override
  String toString() => 'TempWriteException: $detail';
}

/// App-private temp output (FR-20, ADR-003): only the final file is written,
/// as `<cache>/exactsize_out/<random>.jpg|png`. The name is 128 random bits,
/// so it carries no user data. Failures, cancels and the start-up sweep leave
/// the folder empty. Shared with FEAT-002 (its FR-18 sweep). FEAT-001 uses a
/// second instance on `<cache>/camera/` for camera captures (its FR-11).
class TempFiles {
  TempFiles(Directory cacheDir, {String folder = 'exactsize_out'})
      : dir = Directory('${cacheDir.path}${Platform.pathSeparator}$folder');

  /// The app's own cache directory (Android `Context.getCacheDir`).
  static Future<TempFiles> appCache({String folder = 'exactsize_out'}) async =>
      TempFiles(await getTemporaryDirectory(), folder: folder);

  final Directory dir;
  static final _random = Random.secure();

  /// Writes [bytes] and returns the file path, or throws [TempWriteException]
  /// leaving no partial file behind.
  Future<String> write(Uint8List bytes, OutputFormat format) async {
    final name = List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final file = File('${dir.path}${Platform.pathSeparator}$name.${format == OutputFormat.jpeg ? 'jpg' : 'png'}');
    try {
      await dir.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on FileSystemException catch (e) {
      await delete(file.path);
      throw TempWriteException(e.osError?.message ?? e.message);
    }
  }

  /// Deletes one output file; a missing file is fine.
  Future<void> delete(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // already gone, or the folder itself is unusable: nothing to clean
    }
  }

  /// Deletes everything left in the folder except the entry named [keep]
  /// (call at app start, FR-20; FEAT-001 keeps a pending capture, its FR-17).
  /// Returns how many entries were removed.
  Future<int> sweep({String? keep}) async {
    if (!await dir.exists()) return 0;
    var removed = 0;
    await for (final e in dir.list()) {
      if (keep != null && e.uri.pathSegments.where((s) => s.isNotEmpty).last == keep) continue;
      try {
        await e.delete(recursive: true);
        removed++;
      } on FileSystemException {
        // in use or protected: try again at the next start
      }
    }
    return removed;
  }
}
