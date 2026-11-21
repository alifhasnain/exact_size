// Copyright (c) 2026 ExactSize authors. All rights reserved.
//
// FEAT-002 crop pipeline native steps (ADR-005). stb_image_resize2's
// implementation is compiled in es_stb_resize.c; this unit uses its API only.
#include "stb_image_resize2.h"

#include "es_native.h"

int32_t es_resample(const uint8_t *in, int32_t in_w, int32_t in_h, int32_t in_stride,
                    uint8_t *out, int32_t out_w, int32_t out_h, int32_t alpha,
                    int32_t filter) {
  if (in == NULL || out == NULL || in_w <= 0 || in_h <= 0 || out_w <= 0 || out_h <= 0 ||
      in_stride < in_w * 4 || (filter != 0 && filter != 1)) {
    return -1;
  }
  void *r = stbir_resize(in, in_w, in_h, in_stride, out, out_w, out_h, out_w * 4,
                         alpha ? STBIR_RGBA : STBIR_4CHANNEL, STBIR_TYPE_UINT8,
                         STBIR_EDGE_CLAMP,
                         filter == 0 ? STBIR_FILTER_CATMULLROM : STBIR_FILTER_MITCHELL);
  return r == NULL ? -1 : 0;
}
