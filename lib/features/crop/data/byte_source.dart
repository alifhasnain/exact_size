import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Random read access to a source file, for the pure-Dart parsers
/// (`ContainerCheck`, `HeifOrientation`). Reads past the end return fewer
/// bytes, never throw.
abstract interface class ByteSource {
  int get length;

  /// Up to [count] bytes from [offset] (fewer at the end of the file).
  Uint8List read(int offset, int count);
}

/// Bytes already in memory (tests, small headers).
final class MemoryByteSource implements ByteSource {
  MemoryByteSource(this._bytes);
  final Uint8List _bytes;

  @override
  int get length => _bytes.length;

  @override
  Uint8List read(int offset, int count) {
    if (offset < 0 || offset >= _bytes.length || count <= 0) return Uint8List(0);
    return Uint8List.sublistView(_bytes, offset, math.min(_bytes.length, offset + count));
  }
}

/// A file opened read-only (FR-17); the caller closes [file].
final class FileByteSource implements ByteSource {
  FileByteSource(this.file) : length = file.lengthSync();
  final RandomAccessFile file;

  @override
  final int length;

  @override
  Uint8List read(int offset, int count) {
    if (offset < 0 || offset >= length || count <= 0) return Uint8List(0);
    file.setPositionSync(offset);
    return file.readSync(math.min(count, length - offset));
  }
}
