import 'dart:typed_data';

import 'subsampling.dart';

/// Encoder used by the size search (tech.md). One instance is bound to one
/// request's pixels and DPI, so the search only varies the settings. Exists so
/// the search can run against a fake with scripted sizes (NFR-9).
abstract interface class Encoder {
  Uint8List encodeJpeg({
    required int quality,
    required Subsampling subsampling,
    required bool optimiseHuffman,
  });

  /// Lossless PNG at the best compression level (FR-9).
  Uint8List encodePng();
}
