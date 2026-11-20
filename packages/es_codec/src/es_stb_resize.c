// Copyright (c) 2026 ExactSize authors. All rights reserved.
//
// Implementation unit for the vendored stb_image_resize2 (ADR-005,
// FEAT-002-T01). The header is compiled once here. Release builds keep only
// the symbols the app uses (hook/link.dart).
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize2.h"

#include "es_native.h"

int32_t es_resize_rgba_catmull_rom(const uint8_t *in, int32_t in_w, int32_t in_h,
                                   uint8_t *out, int32_t out_w, int32_t out_h,
                                   int32_t alpha) {
  void *r = stbir_resize(in, in_w, in_h, 0, out, out_w, out_h, 0,
                         alpha ? STBIR_RGBA : STBIR_4CHANNEL, STBIR_TYPE_UINT8,
                         STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM);
  return r == NULL ? -1 : 0;
}
