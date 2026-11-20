import 'dart:typed_data';

/// Pixels handed from FEAT-002 to FEAT-004 (ADR-003), as the domain sees them.
/// The native-memory implementation and its ownership rules live in the data
/// layer (FEAT-004-T16).
abstract interface class PixelBuffer {
  int get width;
  int get height;

  /// 3 (RGB) or 4 (RGBA).
  int get channels;

  /// Bytes per row; must equal width × channels (tightly packed, ADR-003).
  int get stride;
  bool get hasTransparency;

  /// View of the pixel memory itself (native memory for the real buffer), so
  /// writes change the buffer in place. Holds at least width × height × channels bytes.
  Uint8List get bytes;

  /// Called after the alpha channel was composited away in place: from now on
  /// the buffer holds width × height × 3 bytes of RGB (stride width × 3) and
  /// no transparency.
  void markAlphaRemoved();
}
