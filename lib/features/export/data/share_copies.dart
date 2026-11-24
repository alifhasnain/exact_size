import 'dart:io';

import '../../compression/data/temp_files.dart';

/// The share copy in `<cache>/exactsize_share/` under the FR-4 name, so the receiving app reads
/// that name (FR-5). FEAT-004's temp file is never renamed or moved (FR-22).
class ShareCopies {
  ShareCopies(this._files);

  final TempFiles _files;

  /// Copies [src] to [name] and checks the length (FR-3). Null on any failure, with no copy left.
  Future<String?> copy(String src, String name, int bytes) async {
    final target = File('${_files.dir.path}${Platform.pathSeparator}$name');
    try {
      await _files.dir.create(recursive: true);
      await File(src).copy(target.path);
      if (await target.length() == bytes) return target.path;
    } on FileSystemException {
      // fall through to cleanup
    }
    await _files.delete(target.path);
    return null;
  }

  Future<void> delete(String path) => _files.delete(path);

  /// App start: removes share copies left by an earlier run (FR-16).
  Future<int> sweep() => _files.sweep();
}
