// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'turbojpeg.g.dart';

/// Encodes tightly packed RGBA8 pixels to JPEG with the bundled libjpeg-turbo
/// (TurboJPEG v3). Low-level building block; the app's `TurboJpegEncoder`
/// adapter (FEAT-004-T06) adds settings, metadata and error mapping.
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
  final handle = tj3InitVersion(
    TJINIT.TJINIT_COMPRESS.value,
    TURBOJPEG_VERSION_NUMBER,
  );
  if (handle == nullptr) throw StateError('tj3Init failed');
  final src = malloc<UnsignedChar>(rgba.length);
  final jpegBuf = calloc<Pointer<UnsignedChar>>(); // NULL: TurboJPEG allocates
  final jpegSize = calloc<Size>();
  try {
    src.cast<Uint8>().asTypedList(rgba.length).setAll(0, rgba);
    _check(handle, tj3Set(handle, TJPARAM.TJPARAM_QUALITY.value, quality));
    _check(handle, tj3Set(handle, TJPARAM.TJPARAM_SUBSAMP.value, subsampling.value));
    _check(
      handle,
      tj3Set(handle, TJPARAM.TJPARAM_OPTIMIZE.value, optimizeHuffman ? 1 : 0),
    );
    _check(
      handle,
      tj3Compress8(handle, src, width, 0, height, TJPF.TJPF_RGBA.value, jpegBuf, jpegSize),
    );
    return Uint8List.fromList(
      jpegBuf.value.cast<Uint8>().asTypedList(jpegSize.value),
    );
  } finally {
    tj3Free(jpegBuf.value.cast());
    calloc.free(jpegSize);
    calloc.free(jpegBuf);
    malloc.free(src);
    tj3Destroy(handle);
  }
}

void _check(Pointer<Void> handle, int result) {
  if (result != 0) {
    throw StateError('TurboJPEG: ${tj3GetErrorStr(handle).cast<Utf8>().toDartString()}');
  }
}
