import 'dart:ffi';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:es_codec/es_codec.dart';
import 'package:ffi/ffi.dart';

import '../domain/crop_types.dart';
import 'platform_decode.dart';
import 'source_handle.dart';

/// Result of [PreviewDecoder.decode] (tech.md section 4).
sealed class PreviewResult {
  const PreviewResult();
}

/// Display-only preview. The renderer never takes a `ui.Image`: it re-decodes
/// from the [SourceHandle] (FR-7).
final class PreviewOk extends PreviewResult {
  const PreviewOk(this.image, this.sampleSize);

  /// Raw orientation (EXIF is applied when painting); long side ≤ [maxSide].
  final ui.Image image;
  final int sampleSize;
}

final class PreviewErr extends PreviewResult {
  const PreviewErr(this.reason);
  final Reason reason;
}

/// Longest preview side in pixels (FR-25).
const maxSide = 2048;

/// Smallest power of two that brings the long side to [maxSide] or less.
int previewSampleSize(int w, int h) {
  final long = w > h ? w : h;
  var s = 1;
  while (long / s > maxSide) {
    s *= 2;
  }
  return s;
}

/// Decodes a reduced preview off the UI thread (FR-7, FR-10, FR-18, FR-25):
/// same decode path as the render, sampled so the long side is ≤ 2048, first
/// frame of animated files. The bitmap is recycled on every path; pixels reach
/// Dart through jnigraphics, never a Java array.
class PreviewDecoder {
  const PreviewDecoder({this.debugForceOutOfMemory = false});

  /// Test hook: behave as if the decoder ran out of memory.
  final bool debugForceOutOfMemory;

  Future<PreviewResult> decode(SourceHandle src, SourceInfo info) async {
    final uri = src.uri;
    final forceOom = debugForceOutOfMemory;
    final r = await Isolate.run(() => _decodePixels(uri, info, forceOom));
    if (r case (final TransferableTypedData px, final int w, final int h, final int s)) {
      final bytes = px.materialize().asUint8List();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
      final codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      return PreviewOk(frame.image, s);
    }
    return PreviewErr(r as Reason);
  }

  /// Worker isolate: (pixels, width, height, sample) or a [Reason].
  static Object _decodePixels(String uri, SourceInfo info, bool forceOom) {
    if (forceOom) return Reason.outOfMemoryHandled;
    final ParcelFileDescriptor pfd;
    try {
      pfd = openReadOnly(uri);
    } on DecodeFailure catch (e) {
      return e.reason;
    }
    Bitmap? bmp;
    Pointer<Uint8>? out;
    try {
      final s = previewSampleSize(info.rawWidth, info.rawHeight);
      // Premultiplied: the engine reads raw rgba8888 as premultiplied.
      bmp = decodeSampled(pfd, info, sample: s, premultiplied: true);
      final n = bmp.width * bmp.height * 4;
      out = malloc<Uint8>(n);
      final (w, h) = copyBitmapRgba(bmp, out, n);
      return (TransferableTypedData.fromList([out.asTypedList(w * h * 4)]), w, h, s);
    } on DecodeFailure catch (e) {
      return e.reason;
    } on ArgumentError {
      return Reason.outOfMemoryHandled; // malloc refused
    } on Object {
      return Reason.unsupportedInput;
    } finally {
      if (out != null) malloc.free(out);
      bmp?.recycle();
      bmp?.release();
      try {
        pfd.close();
      } on Object {
        // already closed
      }
      pfd.release();
    }
  }
}
