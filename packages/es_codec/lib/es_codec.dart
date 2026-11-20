// Copyright (c) 2026 ExactSize authors. All rights reserved.

/// Native image codec bindings (ADR-001, ADR-002): bundled libjpeg-turbo via
/// FFI, plus Android APIs via JNIgen.
library;

import 'src/android/android_build.g.dart';

export 'src/android/android_graphics.g.dart' show Bitmap, Bitmap$$Methods, Bitmap$Config, BitmapFactory, BitmapFactory$Options, BitmapFactory$Options$$Methods;
export 'src/bitmap_pixels.dart' show BitmapPixelsException, copyBitmapRgba, copyBitmapViaDirectBuffer;
export 'src/licenses.dart' show registerEsCodecLicenses;
export 'src/resample.dart' show resizeRgbaCatmullRom;
export 'src/turbojpeg.g.dart' show TJSAMP;
export 'src/turbojpeg_encode.dart'
    show TurboJpegException, encodeJpeg, encodeRgba8ToJpeg;

/// Android `Build.VERSION.SDK_INT` (JNIgen binding).
int androidSdkInt() => Build$VERSION.SDK_INT;
