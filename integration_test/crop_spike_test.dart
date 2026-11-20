import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:es_codec/es_codec.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:jni/jni.dart';

import '../test_support/synthetic_images.dart';

/// FEAT-002-T03 spike (ADR-004 items 3 and 4, ADR-005), on the emulator
/// profile at API 28 (CI) and the latest API: (a) JNIgen from a worker
/// isolate, (b) C reads bitmap pixels with no Java array, (c) informational
/// timings. C is built at -O3 in every build mode, so the C timings hold in
/// debug test runs too.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('(a) BitmapFactory via JNIgen inside a worker isolate returns the expected size', () async {
    final png = img.encodePng(img.Image.fromBytes(
        width: 120, height: 80, bytes: syntheticPhoto(120, 80).buffer, numChannels: 3));
    final size = await Isolate.run(() {
      final bytes = JByteArray(png.length)..setRange(0, png.length, png);
      final bitmap = BitmapFactory.decodeByteArray(bytes, 0, png.length)!;
      try {
        return (bitmap.width, bitmap.height, Isolate.current.debugName);
      } finally {
        bitmap.recycle();
        bitmap.release();
        bytes.release();
      }
    });
    expect((size.$1, size.$2), (120, 80));
  });

  /// 4×3 opaque bitmap with a known colour per pixel.
  Bitmap knownBitmap() {
    final b = Bitmap.createBitmap$10(4, 3, Bitmap$Config.ARGB_8888)!;
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 4; x++) {
        b.setPixel(x, y, 0xFF000000 | (x * 60) << 16 | (y * 80) << 8 | 17);
      }
    }
    return b;
  }

  void expectKnown(Uint8List rgba) {
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 4; x++) {
        final p = (y * 4 + x) * 4;
        expect(rgba.sublist(p, p + 4), [x * 60, y * 80, 17, 255], reason: 'pixel $x,$y');
      }
    }
  }

  test('(b) C reads a synthetic bitmap through jnigraphics, also from a worker isolate', () async {
    final out = malloc<Uint8>(48);
    final bitmap = knownBitmap();
    try {
      expect(copyBitmapRgba(bitmap, out, 48), (4, 3));
      expectKnown(Uint8List.fromList(out.asTypedList(48)));
    } finally {
      bitmap
        ..recycle()
        ..release();
      malloc.free(out);
    }
    final fromWorker = await Isolate.run(() {
      final out = malloc<Uint8>(48);
      final bitmap = knownBitmap();
      try {
        copyBitmapRgba(bitmap, out, 48);
        return Uint8List.fromList(out.asTypedList(48));
      } finally {
        bitmap
          ..recycle()
          ..release();
        malloc.free(out);
      }
    });
    expectKnown(fromWorker);
  });

  test('(b) fallback: copyPixelsToBuffer into a direct buffer over malloc memory', () {
    final out = malloc<Uint8>(48);
    final bitmap = knownBitmap();
    try {
      copyBitmapViaDirectBuffer(bitmap, out, 48);
      expectKnown(Uint8List.fromList(out.asTypedList(48)));
    } finally {
      bitmap
        ..recycle()
        ..release();
      malloc.free(out);
    }
  });

  test('(c) timings, informational', () {
    String stats(List<int> us) {
      us.sort();
      final p95 = us[((us.length - 1) * 0.95).round()];
      return 'median ${(us[us.length ~/ 2] / 1000).toStringAsFixed(1)} ms, p95 ${(p95 / 1000).toStringAsFixed(1)} ms';
    }

    List<int> time(int runs, void Function() body) {
      for (var i = 0; i < 2; i++) {
        body(); // warm-up
      }
      return [
        for (var i = 0; i < runs; i++) (Stopwatch()..start()..also(body)).elapsedMicroseconds,
      ];
    }

    final lines = <String>[];
    // 12 MP bitmap → malloc buffer: jnigraphics vs copyPixelsToBuffer.
    const bw = 4000, bh = 3000, len = bw * bh * 4;
    final bitmap = Bitmap.createBitmap$10(bw, bh, Bitmap$Config.ARGB_8888)!;
    final out = malloc<Uint8>(len);
    try {
      lines.add('copy 12 MP jnigraphics: ${stats(time(10, () => copyBitmapRgba(bitmap, out, len)))}');
      lines.add('copy 12 MP copyPixelsToBuffer: ${stats(time(10, () => copyBitmapViaDirectBuffer(bitmap, out, len)))}');
    } finally {
      bitmap
        ..recycle()
        ..release();
      malloc.free(out);
    }
    // stb Catmull-Rom (ADR-005).
    for (final (iw, ih, ow, oh, label) in const [
      (4000, 3000, 1633, 1225, '12 MP -> 2 MP'),
      (5774, 4330, 5657, 4243, '25 MP -> 24 MP'),
    ]) {
      final src = malloc<Uint8>(iw * ih * 4), dst = malloc<Uint8>(ow * oh * 4);
      try {
        src.asTypedList(iw * ih * 4).setAll(0, syntheticPhoto(iw, ih, channels: 4));
        lines.add('stb $label RGBA: ${stats(time(20, () => resizeRgbaCatmullRom(src, iw, ih, dst, ow, oh, alpha: true)))}');
      } finally {
        malloc.free(src);
        malloc.free(dst);
      }
    }
    // ignore: avoid_print
    print('SPIKE sdk=${androidSdkInt()} | ${lines.join(' | ')}');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

extension on Stopwatch {
  Stopwatch also(void Function() body) {
    body();
    stop();
    return this;
  }
}
