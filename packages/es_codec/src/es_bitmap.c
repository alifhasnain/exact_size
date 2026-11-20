// Copyright (c) 2026 ExactSize authors. All rights reserved.
#include "es_native.h"

#ifdef __ANDROID__
#include <android/bitmap.h>
#include <jni.h>
#include <string.h>

int32_t es_bitmap_copy_rgba(void *java_vm, void *bitmap, uint8_t *out, int64_t out_len,
                            int32_t *width, int32_t *height) {
  JavaVM *vm = (JavaVM *)java_vm;
  JNIEnv *env = NULL;
  int attached = 0;
  if ((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6) == JNI_EDETACHED) {
    if ((*vm)->AttachCurrentThread(vm, &env, NULL) != JNI_OK) return -1;
    attached = 1;
  }
  if (env == NULL) return -1;
  int32_t rc = 0;
  AndroidBitmapInfo info;
  void *pixels = NULL;
  if (AndroidBitmap_getInfo(env, (jobject)bitmap, &info) != ANDROID_BITMAP_RESULT_SUCCESS) {
    rc = -2;
  } else if (info.format != ANDROID_BITMAP_FORMAT_RGBA_8888) {
    rc = -3;
  } else if ((int64_t)info.width * info.height * 4 > out_len) {
    rc = -4;
  } else if (AndroidBitmap_lockPixels(env, (jobject)bitmap, &pixels) != ANDROID_BITMAP_RESULT_SUCCESS) {
    rc = -5;
  } else {
    const size_t row = (size_t)info.width * 4;
    for (uint32_t y = 0; y < info.height; y++) {
      memcpy(out + (size_t)y * row, (const uint8_t *)pixels + (size_t)y * info.stride, row);
    }
    AndroidBitmap_unlockPixels(env, (jobject)bitmap);
    *width = (int32_t)info.width;
    *height = (int32_t)info.height;
  }
  if (attached) (*vm)->DetachCurrentThread(vm);
  return rc;
}
#else
int32_t es_bitmap_copy_rgba(void *java_vm, void *bitmap, uint8_t *out, int64_t out_len,
                            int32_t *width, int32_t *height) {
  (void)java_vm; (void)bitmap; (void)out; (void)out_len; (void)width; (void)height;
  return -100;
}
#endif
