// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:ffi';

import 'es_native.g.dart';

/// stb_image_resize2 Catmull-Rom resize of tight 4-channel 8-bit pixels
/// (ADR-005). [alpha]: straight RGBA (premultiplied inside stb) or opaque.
/// FEAT-002-T03 spike entry point; es_resample (FEAT-002-T13) replaces it.
void resizeRgbaCatmullRom(Pointer<Uint8> input, int inWidth, int inHeight, Pointer<Uint8> output,
    int outWidth, int outHeight, {required bool alpha}) {
  if (es_resize_rgba_catmull_rom(input, inWidth, inHeight, output, outWidth, outHeight, alpha ? 1 : 0) != 0) {
    throw StateError('stb resize failed');
  }
}
