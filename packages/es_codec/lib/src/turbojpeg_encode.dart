// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'turbojpeg.g.dart';

/// A TurboJPEG call failed. [message] is libjpeg-turbo's own text; it never
/// contains pixel data or file names.
class TurboJpegException implements Exception {
  const TurboJpegException(this.stage, this.code, this.message);

  /// Which step failed: `init`, `set` (a parameter was rejected) or `compress`.
  final String stage;

  /// `TJERR` value (0 = warning, 1 = fatal), or -1 when unknown (init).
  final int code;
  final String message;

  @override
  String toString() => 'TurboJpegException($stage, $code): $message';
}

/// Encodes tightly packed 8-bit pixels at [pixels] (native memory, not
/// copied) to a baseline JPEG with the bundled libjpeg-turbo (ADR-002).
///
/// [channels] is 3 (RGB) or 4 (RGBA; alpha ignored). Output: JFIF APP0 with
/// density in dots per inch when [dpi] is set (else the 1:1 aspect default),
/// no EXIF, no ICC, never progressive or arithmetic-coded. Deterministic for
/// a given build. Throws [ArgumentError] for bad sizes and
/// [TurboJpegException] when libjpeg-turbo rejects a value or fails.
Uint8List encodeJpeg(
  Pointer<Uint8> pixels,
  int width,
  int height,
  int channels, {
  required int quality,
  required TJSAMP subsampling,
  required bool optimizeHuffman,
  int? dpi,
}) {
  if (width <= 0 || height <= 0) throw ArgumentError('width and height must be > 0');
  if (channels != 3 && channels != 4) throw ArgumentError('channels must be 3 or 4');
  if (pixels == nullptr) throw ArgumentError('pixels is null');

  final handle = tj3InitVersion(TJINIT.TJINIT_COMPRESS.value, TURBOJPEG_VERSION_NUMBER);
  if (handle == nullptr) {
    throw const TurboJpegException('init', -1, 'tj3Init failed');
  }
  final jpegBuf = calloc<Pointer<UnsignedChar>>(); // NULL: TurboJPEG allocates
  final jpegSize = calloc<Size>();
  try {
    void set(TJPARAM param, int value) {
      if (tj3Set(handle, param.value, value) != 0) _throw(handle, 'set');
    }

    set(TJPARAM.TJPARAM_QUALITY, quality);
    set(TJPARAM.TJPARAM_SUBSAMP, subsampling.value);
    set(TJPARAM.TJPARAM_OPTIMIZE, optimizeHuffman ? 1 : 0);
    set(TJPARAM.TJPARAM_PROGRESSIVE, 0); // baseline only (tech.md)
    set(TJPARAM.TJPARAM_ARITHMETIC, 0);
    if (dpi != null) {
      set(TJPARAM.TJPARAM_DENSITYUNITS, 1); // 1 = dots per inch (JFIF)
      set(TJPARAM.TJPARAM_XDENSITY, dpi);
      set(TJPARAM.TJPARAM_YDENSITY, dpi);
    }
    final format = channels == 3 ? TJPF.TJPF_RGB : TJPF.TJPF_RGBA;
    final rc = tj3Compress8(
      handle,
      pixels.cast(),
      width,
      width * channels, // pitch: tightly packed (ADR-003)
      height,
      format.value,
      jpegBuf,
      jpegSize,
    );
    if (rc != 0) _throw(handle, 'compress');
    return Uint8List.fromList(jpegBuf.value.cast<Uint8>().asTypedList(jpegSize.value));
  } finally {
    tj3Free(jpegBuf.value.cast());
    calloc.free(jpegSize);
    calloc.free(jpegBuf);
    tj3Destroy(handle);
  }
}

/// Convenience for tests and the benchmark: copies Dart-heap RGBA8 pixels into
/// native memory, then calls [encodeJpeg].
Uint8List encodeRgba8ToJpeg(
  Uint8List rgba,
  int width,
  int height, {
  required int quality,
  TJSAMP subsampling = TJSAMP.TJSAMP_420,
  bool optimizeHuffman = false,
}) {
  if (rgba.length != width * height * 4) {
    throw ArgumentError('rgba must hold width * height * 4 bytes');
  }
  final src = malloc<Uint8>(rgba.length);
  try {
    src.asTypedList(rgba.length).setAll(0, rgba);
    return encodeJpeg(src, width, height, 4,
        quality: quality, subsampling: subsampling, optimizeHuffman: optimizeHuffman);
  } finally {
    malloc.free(src);
  }
}

Never _throw(Pointer<Void> handle, String stage) {
  throw TurboJpegException(
    stage,
    tj3GetErrorCode(handle),
    tj3GetErrorStr(handle).cast<Utf8>().toDartString(),
  );
}
