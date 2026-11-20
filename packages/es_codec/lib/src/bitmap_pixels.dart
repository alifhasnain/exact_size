// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:ffi';

import 'package:jni/jni.dart';

import 'android/android_graphics.g.dart';
import 'es_native.g.dart';

/// Copying a Bitmap's pixels failed; [code] is the es_bitmap_copy_rgba result.
class BitmapPixelsException implements Exception {
  const BitmapPixelsException(this.code);
  final int code;
  @override
  String toString() => 'BitmapPixelsException($code)';
}

/// Copies an ARGB_8888 `android.graphics.Bitmap` into [out] as tight RGBA
/// through jnigraphics (FEAT-002-T03, ADR-004): no Java array is created.
/// Returns (width, height). Works on any isolate; Android only.
(int, int) copyBitmapRgba(JObject bitmap, Pointer<Uint8> out, int outLength) {
  return using((arena) {
    final vm = arena<Pointer<Void>>();
    // jni 1.2.1 (pinned) marks env and reference @internal; JNIgen's own
    // generated code uses them the same way. Recheck on a jni upgrade.
    // ignore: invalid_use_of_internal_member
    if (Jni.env.GetJavaVM(vm.cast()) != 0) throw const BitmapPixelsException(-1);
    final w = arena<Int32>(), h = arena<Int32>();
    // ignore: invalid_use_of_internal_member
    final ref = bitmap.reference.pointer;
    final rc = es_bitmap_copy_rgba(vm.value, ref.cast(), out, outLength, w, h);
    if (rc != 0) throw BitmapPixelsException(rc);
    return (w.value, h.value);
  });
}

/// Fallback path (ADR-004, measured in FEAT-002-T03): `Bitmap.copyPixelsToBuffer`
/// into a direct `ByteBuffer` that wraps [out] (malloc memory), so no Java
/// array either. Use when jnigraphics is unavailable. Copies
/// rowBytes × height bytes; [outLength] must be at least that.
void copyBitmapViaDirectBuffer(Bitmap bitmap, Pointer<Uint8> out, int outLength) {
  // ignore: invalid_use_of_internal_member
  final ref = Jni.env.NewDirectByteBuffer(out.cast(), outLength);
  // ignore: invalid_use_of_internal_member
  final buffer = JObject.fromReference(JGlobalReference(ref)) as JByteBuffer;
  try {
    bitmap.copyPixelsToBuffer(buffer);
  } finally {
    buffer.release();
  }
}
