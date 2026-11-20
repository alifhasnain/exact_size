import 'dart:typed_data';

import 'package:jni/jni.dart';

/// Decodes [jpeg] with Android's own `BitmapFactory` (tech.md risk R6: padded
/// files must open in the system decoder). Returns (width, height), or null
/// when Android can't decode it. Test-only; called through JNI directly.
(int, int)? bitmapFactorySize(Uint8List jpeg) {
  final factory = JClass.forName('android/graphics/BitmapFactory');
  final bitmapClass = JClass.forName('android/graphics/Bitmap');
  final array = JByteArray(jpeg.length)..setRange(0, jpeg.length, jpeg);
  try {
    final bitmap = factory
        .staticMethodId('decodeByteArray', '([BII)Landroid/graphics/Bitmap;')
        .callNullable(factory, JObject.type, [array, JValueInt(0), JValueInt(jpeg.length)]);
    if (bitmap == null) return null;
    try {
      int dim(String getter) => bitmapClass.instanceMethodId(getter, '()I').call(bitmap, jint.type, []);
      return (dim('getWidth'), dim('getHeight'));
    } finally {
      bitmapClass.instanceMethodId('recycle', '()V').call(bitmap, jvoid.type, []);
      bitmap.release();
    }
  } finally {
    array.release();
    factory.release();
    bitmapClass.release();
  }
}
