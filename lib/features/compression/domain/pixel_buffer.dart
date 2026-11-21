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

  /// Crop metadata from FEAT-002 (ADR-003): max(W/cropW, H/cropH) of the
  /// rendered crop; 1.0 when not from a crop.
  double get upscaleFactor;

  /// Integer crop rectangle in oriented source space (after EXIF and manual
  /// rotation); null when not from a crop. No path, file name or EXIF value.
  ({int x, int y, int w, int h})? get cropRect;

  /// Manual clockwise rotation only: 0, 90, 180 or 270 (FEAT-002 OQ-13).
  int get rotationApplied;

  /// Called after the alpha channel was composited away in place: from now on
  /// the buffer holds width × height × 3 bytes of RGB (stride width × 3) and
  /// no transparency.
  void markAlphaRemoved();
}
