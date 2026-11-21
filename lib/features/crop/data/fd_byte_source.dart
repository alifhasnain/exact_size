import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'byte_source.dart';

typedef _PreadC = IntPtr Function(Int32 fd, Pointer<Uint8> buf, IntPtr count, Int64 offset);
typedef _PreadDart = int Function(int fd, Pointer<Uint8> buf, int count, int offset);
typedef _LseekC = Int64 Function(Int32 fd, Int64 offset, Int32 whence);
typedef _LseekDart = int Function(int fd, int offset, int whence);

final DynamicLibrary _libc = DynamicLibrary.open('libc.so');
final _pread = _libc.lookupFunction<_PreadC, _PreadDart>('pread64');
final _lseek = _libc.lookupFunction<_LseekC, _LseekDart>('lseek64');

/// Reads an open file descriptor (from `ParcelFileDescriptor`) with libc
/// `pread`, so the file's bytes never cross JNI and the shared file offset is
/// not moved. Android only. The caller owns and closes [fd].
final class FdByteSource implements ByteSource {
  FdByteSource(this.fd, this.length);
  final int fd;

  @override
  final int length;

  @override
  Uint8List read(int offset, int count) {
    if (offset < 0 || offset >= length || count <= 0) return Uint8List(0);
    final n = count < length - offset ? count : length - offset;
    final buf = malloc<Uint8>(n);
    try {
      var got = 0;
      while (got < n) {
        final r = _pread(fd, buf + got, n - got, offset + got);
        if (r <= 0) break; // EOF or error: return what was read
        got += r;
      }
      return Uint8List.fromList(buf.asTypedList(got));
    } finally {
      malloc.free(buf);
    }
  }

  /// Moves the shared file offset back to the start before a Java reader
  /// (`ExifInterface`, `BitmapFactory`) that reads from the current position.
  void rewind() => _lseek(fd, 0, 0);
}
