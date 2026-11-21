// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:ffi';

import 'package:jni/jni.dart';

import 'bitmap_pixels.dart';
import 'es_native.g.dart';

/// Lossless D4 transform (FEAT-002-T14): mirror left-right first if
/// [mirrored], then rotate [quarterTurns] x 90° clockwise, the same order as
/// the app's `Orientation`. [output] holds the same byte count as [input];
/// it is [height] x [width] for odd turns.
void orient(Pointer<Uint8> input, int width, int height, int channels, Pointer<Uint8> output,
    {required bool mirrored, required int quarterTurns}) {
  if (es_orient(input, width, height, channels, output, mirrored ? 1 : 0, quarterTurns) != 0) {
    throw StateError('orient failed');
  }
}

/// Alpha scan (FEAT-002-T14, FR-14): true when any alpha is below 255 (the
/// buffer stays RGBA); false after compacting the tight RGBA buffer in place
/// to tight RGB.
bool finishAlpha(Pointer<Uint8> rgba, int width, int height) {
  final r = es_finish(rgba, width, height);
  if (r < 0) throw StateError('finish failed');
  return r == 1;
}

/// Runs [use] with an ARGB_8888 Bitmap's pixels locked in place through
/// jnigraphics (no copy, no Java array), then unlocks on every path.
/// [use] gets the pixel pointer, size and row stride in bytes. Android only.
T withBitmapPixels<T>(JObject bitmap, T Function(Pointer<Uint8> pixels, int width, int height, int stride) use) {
  return using((arena) {
    final vm = arena<Pointer<Void>>();
    // ignore: invalid_use_of_internal_member
    if (Jni.env.GetJavaVM(vm.cast()) != 0) throw const BitmapPixelsException(-1);
    // ignore: invalid_use_of_internal_member
    final ref = bitmap.reference.pointer.cast<Void>();
    final pixels = arena<Pointer<Uint8>>(), w = arena<Int32>(), h = arena<Int32>(), stride = arena<Int32>();
    final rc = es_bitmap_lock(vm.value, ref, pixels, w, h, stride);
    if (rc != 0) throw BitmapPixelsException(rc);
    try {
      return use(pixels.value, w.value, h.value, stride.value);
    } finally {
      es_bitmap_unlock(vm.value, ref);
    }
  });
}
