import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/pixel_buffer.dart';

/// Lossless PNG encoder (ADR-002: pure-Dart `image` package, pinned).
///
/// Level 9 (FR-9), RGB or RGBA as given (alpha kept). Writes a `pHYs` chunk
/// only when [dpi] is set (FR-14); never `iCCP`, `eXIf` or text chunks, since
/// the image is built from bare pixels.
class DartPngEncoder {
  const DartPngEncoder();

  Uint8List encodePng(PixelBuffer px, {int? dpi}) {
    final b = px.bytes;
    final image = img.Image.fromBytes(
      width: px.width,
      height: px.height,
      bytes: b.buffer,
      bytesOffset: b.offsetInBytes,
      numChannels: px.channels,
    );
    return img.PngEncoder(
      level: 9,
      pixelDimensions: dpi == null ? null : img.PngPhysicalPixelDimensions.dpi(dpi),
    ).encode(image);
  }
}
