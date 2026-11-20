import 'dart:io';

import '../domain/compression_result.dart';
import 'turbo_jpeg_encoder.dart';

/// Reads the text of `/proc/meminfo`; null when it can't be read.
typedef MeminfoReader = Future<String?> Function();

/// Memory pre-flight before a compression starts (FR-18, NFR-2, tech.md R2).
///
/// Refuses targets above 24 MP (PRD OQ-4) and jobs whose estimated working
/// memory, with 2× headroom, is more than `MemAvailable`. Both give
/// `IMAGE_TOO_LARGE` instead of risking a low-memory kill. If meminfo can't be
/// read, only the pixel cap applies and allocation failures are caught later
/// ([isAllocationFailure]).
class MemoryPreflight {
  const MemoryPreflight({this.readMeminfo = readProcMeminfo});

  final MeminfoReader readMeminfo;

  /// Largest target W×H (PRD OQ-4, decided 2026-11-20).
  static const maxPixels = 24000000;

  /// Encoder working memory per target pixel [Hypothesis; T25 measures]:
  /// JPEG with optimised Huffman keeps 4:4:4 coefficients (6 B/px) plus up to
  /// three compressed copies (native output, Dart copy, best so far; ≤ 3 B/px
  /// each). PNG keeps about four copies of the pixels (≤ 4 B/px each).
  static const workingBytesPerPixel = 16;

  static const headroom = 2;

  /// Null when the job may start, else the `IMAGE_TOO_LARGE` failure.
  Future<CompressionFailure?> check({required int width, required int height}) async {
    final pixels = width * height;
    if (pixels > maxPixels) return _tooLarge;
    final String? text;
    try {
      text = await readMeminfo();
    } catch (_) {
      return null; // unreadable: check skipped
    }
    final available = text == null ? null : parseMemAvailable(text);
    if (available == null) return null;
    return pixels * workingBytesPerPixel * headroom > available ? _tooLarge : null;
  }

  static const _tooLarge = CompressionFailure(reason: Reason.imageTooLarge);
}

/// `MemAvailable` in bytes, or null if the line is missing or malformed.
int? parseMemAvailable(String meminfo) {
  final m = RegExp(r'^MemAvailable:\s+(\d+)\s+kB\s*$', multiLine: true).firstMatch(meminfo);
  return m == null ? null : int.parse(m.group(1)!) * 1024;
}

/// Default reader: `/proc/meminfo` via `dart:io` (tech.md: no platform channel).
Future<String?> readProcMeminfo() async {
  try {
    return await File('/proc/meminfo').readAsString();
  } on FileSystemException {
    return null;
  }
}

/// True when [error] means memory ran out: a Dart-heap failure, a native
/// allocation that returned null ([OutOfMemoryError] from our allocators), or
/// libjpeg-turbo failing to allocate. Mapped to `OUT_OF_MEMORY_HANDLED`.
bool isAllocationFailure(Object error) =>
    error is OutOfMemoryError ||
    (error is JpegEncodeException &&
        (error.kind == JpegEncodeErrorKind.initFailed ||
            error.kind == JpegEncodeErrorKind.outOfMemory));
