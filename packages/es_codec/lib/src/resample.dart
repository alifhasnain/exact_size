// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:ffi';

import 'es_native.g.dart';

/// Resampling filter. Catmull-Rom is the pinned production filter (ADR-005);
/// Mitchell exists only for the gate G2 comparison chart.
enum ResampleFilter { catmullRom, mitchell }

/// One stb_image_resize2 pass (ADR-005, FR-8, FR-9, FR-14) from 4-channel
/// 8-bit pixels with [inStride] bytes per row to a tight [outWidth] x
/// [outHeight] x 4 buffer. [alpha]: straight RGBA, premultiplied inside stb
/// so edges get no dark fringe; otherwise opaque 4-channel.
/// Throws [StateError] on bad arguments or allocation failure.
void resample(Pointer<Uint8> input, int inWidth, int inHeight, int inStride, Pointer<Uint8> output, int outWidth,
    int outHeight,
    {required bool alpha, ResampleFilter filter = ResampleFilter.catmullRom}) {
  final r = es_resample(input, inWidth, inHeight, inStride, output, outWidth, outHeight, alpha ? 1 : 0,
      filter == ResampleFilter.catmullRom ? 0 : 1);
  if (r != 0) throw StateError('resample failed');
}
