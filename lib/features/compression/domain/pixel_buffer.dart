/// Pixels handed from FEAT-002 to FEAT-004 (ADR-003), as the domain sees them.
/// The native-memory implementation and its ownership rules live in the data
/// layer (FEAT-004-T16); the domain never touches the bytes.
abstract interface class PixelBuffer {
  int get width;
  int get height;

  /// 3 (RGB) or 4 (RGBA); tightly packed, stride = width × channels.
  int get channels;
  bool get hasTransparency;
}
