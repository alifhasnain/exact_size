// Copyright (c) 2026 ExactSize authors. All rights reserved.
//
// es_codec's own C entry points (FFIgen reads this header).
#ifndef ES_NATIVE_H
#define ES_NATIVE_H

#include <stdint.h>

#ifdef _WIN32
#define ES_EXPORT __declspec(dllexport)
#else
#define ES_EXPORT __attribute__((visibility("default")))
#endif

// FEAT-002-T03: copies an ARGB_8888 android.graphics.Bitmap into [out] as
// tightly packed RGBA (width * height * 4 bytes) through jnigraphics
// (AndroidBitmap_lockPixels), so the pixels never pass through a Java array.
// [java_vm] is the process JavaVM*, [bitmap] a JNI reference to the Bitmap.
// Writes the size to [width]/[height]. Returns 0 on success, or:
// -1 no JNI env, -2 getInfo failed, -3 not RGBA_8888, -4 [out] too small,
// -5 lockPixels failed, -100 not built for Android.
ES_EXPORT int32_t es_bitmap_copy_rgba(void *java_vm, void *bitmap, uint8_t *out,
                                      int64_t out_len, int32_t *width, int32_t *height);

// FEAT-002-T13 (ADR-005, FR-8, FR-9, FR-14): one stb_image_resize2 pass from
// 4-channel 8-bit pixels at [in_stride] bytes per row to a tight
// [out_w] x [out_h] x 4 buffer, separate x/y scales, clamped edges.
// [alpha] 1 = straight RGBA (stb premultiplies internally, no dark fringe),
// 0 = opaque 4-channel. [filter] 0 = Catmull-Rom (the pinned production
// filter), 1 = Mitchell (comparison chart only). Returns 0, or -1 on bad
// arguments or allocation failure.
ES_EXPORT int32_t es_resample(const uint8_t *in, int32_t in_w, int32_t in_h, int32_t in_stride,
                              uint8_t *out, int32_t out_w, int32_t out_h, int32_t alpha,
                              int32_t filter);

#endif
