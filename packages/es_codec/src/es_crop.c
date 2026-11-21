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

int32_t es_orient(const uint8_t *in, int32_t w, int32_t h, int32_t channels, uint8_t *out,
                  int32_t mirrored, int32_t quarter_turns) {
  if (in == NULL || out == NULL || w <= 0 || h <= 0 || channels < 1 || channels > 4 ||
      quarter_turns < 0 || quarter_turns > 3) {
    return -1;
  }
  const int32_t ow = (quarter_turns & 1) ? h : w;
  for (int32_t y = 0; y < h; y++) {
    const uint8_t *row = in + (size_t)y * w * channels;
    for (int32_t x = 0; x < w; x++) {
      const int32_t x1 = mirrored ? w - 1 - x : x;
      int32_t ox, oy;
      switch (quarter_turns) {
        case 0: ox = x1; oy = y; break;
        case 1: ox = h - 1 - y; oy = x1; break;
        case 2: ox = w - 1 - x1; oy = h - 1 - y; break;
        default: ox = y; oy = w - 1 - x1; break;
      }
      const uint8_t *src = row + (size_t)x * channels;
      uint8_t *dst = out + ((size_t)oy * ow + ox) * channels;
      for (int32_t c = 0; c < channels; c++) dst[c] = src[c];
    }
  }
  return 0;
}

int32_t es_finish(uint8_t *rgba, int32_t w, int32_t h) {
  if (rgba == NULL || w <= 0 || h <= 0) return -1;
  const size_t n = (size_t)w * h;
  for (size_t i = 0; i < n; i++) {
    if (rgba[i * 4 + 3] != 255) return 1;
  }
  // In place is safe: the write index (3i) never passes the read index (4i).
  for (size_t i = 0; i < n; i++) {
    rgba[i * 3] = rgba[i * 4];
    rgba[i * 3 + 1] = rgba[i * 4 + 1];
    rgba[i * 3 + 2] = rgba[i * 4 + 2];
  }
  return 0;
}
