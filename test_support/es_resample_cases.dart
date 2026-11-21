import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:es_codec/es_codec.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import 'synthetic_images.dart';

/// Resamples tight or strided RGBA [src] ([w]×[h], [stride] bytes per row) to [ow]×[oh].
Uint8List resampleBytes(Uint8List src, int w, int h, int ow, int oh,
    {int? stride, bool alpha = false, ResampleFilter filter = ResampleFilter.catmullRom}) {
  final s = stride ?? w * 4;
  final input = malloc<Uint8>(s * h);
  final output = malloc<Uint8>(ow * oh * 4);
  try {
    input.asTypedList(s * h).setAll(0, src);
    resample(input, w, h, s, output, ow, oh, alpha: alpha, filter: filter);
    return Uint8List.fromList(output.asTypedList(ow * oh * 4));
  } finally {
    malloc.free(input);
    malloc.free(output);
  }
}

Uint8List photoRgba(int w, int h, {int seed = 1}) => syntheticPhoto(w, h, seed: seed, channels: 4);

/// Red opaque disc on fully transparent black (alpha 0, RGB 0): the classic
/// dark-fringe trap for resamplers that do not premultiply.
Uint8List redDiscOnTransparent(int size) {
  final b = Uint8List(size * size * 4);
  final c = size / 2, r = size * 0.35;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x + 0.5 - c, dy = y + 0.5 - c;
      if (dx * dx + dy * dy <= r * r) {
        final o = (y * size + x) * 4;
        b[o] = 255;
        b[o + 3] = 255;
      }
    }
  }
  return b;
}

/// Golden cases: name → (source, w, h, ow, oh, alpha, filter).
final goldenCases = <String, (Uint8List Function(), int, int, int, int, bool, ResampleFilter)>{
  'photo_1200x900_to_300x300': (() => photoRgba(1200, 900), 1200, 900, 300, 300, false, ResampleFilter.catmullRom),
  'photo_1200x900_to_300x80': (() => photoRgba(1200, 900, seed: 2), 1200, 900, 300, 80, false, ResampleFilter.catmullRom),
  'photo_933x400_to_140x60': (() => photoRgba(933, 400, seed: 3), 933, 400, 140, 60, false, ResampleFilter.catmullRom),
  'photo_120x80_to_600x400': (() => photoRgba(120, 80, seed: 4), 120, 80, 600, 400, false, ResampleFilter.catmullRom),
  'photo_1x1_to_300x300': (() => photoRgba(1, 1, seed: 5), 1, 1, 300, 300, false, ResampleFilter.catmullRom),
  'photo_301x299_to_300x300': (() => photoRgba(301, 299, seed: 6), 301, 299, 300, 300, false, ResampleFilter.catmullRom),
  'disc_alpha_256_to_37': (() => redDiscOnTransparent(256), 256, 256, 37, 37, true, ResampleFilter.catmullRom),
  'disc_alpha_40_to_300': (() => redDiscOnTransparent(40), 40, 40, 300, 300, true, ResampleFilter.catmullRom),
  'photo_800x600_to_200x150_mitchell': (() => photoRgba(800, 600, seed: 7), 800, 600, 200, 150, false, ResampleFilter.mitchell),
  'photo_7x7_to_300x80': (() => photoRgba(7, 7, seed: 8), 7, 7, 300, 80, false, ResampleFilter.catmullRom),
};

/// SHA-256 per golden case. Identical on Windows (MSVC), Linux (clang) and
/// the API 28 x86_64 emulator; ARM builds may round differently (NEON).
const resampleGoldens = <String, String>{
  'photo_1200x900_to_300x300': 'ffbb4f3b1b4fb75bf50b684e4759bab53b50b88c5a6c29b8c673052a28dc956c',
  'photo_1200x900_to_300x80': '3aa8d80ce10bea6ee3079f1aa7a06e327b9c51d68442cdf1cee98bc596149c19',
  'photo_933x400_to_140x60': 'ed049371cacd4b0207d4ebc1b530d7ecd75e2812a4643501e58cc9417736e5ef',
  'photo_120x80_to_600x400': 'fcad24c24e42f06b5928606874c522555c0873281c621dcff593de5f0a28339c',
  'photo_1x1_to_300x300': 'dec16fcf71a7f80a1738b6dcd6526c4367e1534c34d97a55e0dc20c9956c746b',
  'photo_301x299_to_300x300': 'a75195f5f8984f523b232c8c1b989f7631d6a432fbc4d2a5e4fc139b02489701',
  'disc_alpha_256_to_37': 'a4c42983925776703065a54c6ce4bdd483a043bacaf6b314945acbf16805145b',
  'disc_alpha_40_to_300': 'db270c7ead880c8309ecd6f542946c82d76e27de0127413914a6356218cb61ac',
  'photo_800x600_to_200x150_mitchell': 'fba28a24d95f9ef4e46d1167c71cbe2504ada2da55433510626fe76cc303ede5',
  'photo_7x7_to_300x80': 'c56ab9badf4b0eb4245cbc081c2755b6b7f1e428a58832b93ce2f2198e6b8225',
};

String goldenHash(String name) {
  final (src, w, h, ow, oh, alpha, filter) = goldenCases[name]!;
  return sha256.convert(resampleBytes(src(), w, h, ow, oh, alpha: alpha, filter: filter)).toString();
}

/// FEAT-002-T13 checks, shared by test/ (host) and integration_test/ (emulator).
/// [goldens]: expected SHA-256 per case for this platform, or null to check
/// only that two runs agree (float SIMD paths may differ by ABI, ADR-005).
void defineEsResampleTests({Map<String, String>? goldens}) {
  test('output is exactly W×H for the task sizes', () {
    for (final (w, h, ow, oh) in [(3000, 3000, 300, 300), (3000, 800, 300, 80), (2333, 1000, 140, 60), (1, 1, 300, 300)]) {
      final out = resampleBytes(photoRgba(w, h), w, h, ow, oh);
      expect(out.length, ow * oh * 4, reason: '${w}x$h → ${ow}x$oh');
    }
  });

  test('same-size resample is the identity (maximum deviation reported)', () {
    for (final (w, h) in [(300, 300), (140, 60), (1, 1)]) {
      final src = photoRgba(w, h, seed: 9);
      final out = resampleBytes(src, w, h, w, h);
      var maxDev = 0;
      for (var i = 0; i < src.length; i++) {
        final d = (src[i] - out[i]).abs();
        if (d > maxDev) maxDev = d;
      }
      // ignore: avoid_print
      print('IDENTITY ${w}x$h max deviation $maxDev');
      expect(maxDev, lessThanOrEqualTo(1), reason: 'identity within the pinned algorithm');
    }
  });

  test('a padded row stride gives the same pixels as a tight one', () {
    const w = 97, h = 61, pad = 12;
    final tight = photoRgba(w, h, seed: 10);
    final strided = Uint8List((w * 4 + pad) * h);
    for (var y = 0; y < h; y++) {
      strided.setRange(y * (w * 4 + pad), y * (w * 4 + pad) + w * 4, tight, y * w * 4);
    }
    expect(resampleBytes(strided, w, h, 40, 25, stride: w * 4 + pad), resampleBytes(tight, w, h, 40, 25));
  });

  test('red opaque shape on transparent pixels: no dark fringe (AC-6.3)', () {
    for (final (size, out) in [(256, 37), (256, 101), (40, 300)]) {
      final o = resampleBytes(redDiscOnTransparent(size), size, size, out, out, alpha: true);
      var edge = 0;
      for (var i = 0; i < o.length; i += 4) {
        if (o[i + 3] == 0) continue;
        if (o[i + 3] < 255) edge++;
        expect(o[i], greaterThanOrEqualTo(253), reason: '$size→$out px ${i ~/ 4} R');
        expect(o[i + 1], lessThanOrEqualTo(2), reason: '$size→$out px ${i ~/ 4} G');
        expect(o[i + 2], lessThanOrEqualTo(2), reason: '$size→$out px ${i ~/ 4} B');
      }
      expect(edge, greaterThan(0), reason: 'the test must see partly transparent edge pixels');
    }
  });

  test('bad arguments throw, never crash', () {
    expect(() => resampleBytes(photoRgba(4, 4), 4, 4, 0, 4), throwsStateError);
    final buf = malloc<Uint8>(64);
    addTearDown(() => malloc.free(buf));
    expect(() => resample(buf, 4, 4, 8, buf, 4, 4, alpha: false), throwsStateError); // stride < width × 4
  });

  test('golden SHA-256 for ${goldenCases.length} cases, stable over two runs', () {
    for (final name in goldenCases.keys) {
      final first = goldenHash(name);
      expect(goldenHash(name), first, reason: '$name differs between two runs');
      // ignore: avoid_print
      if (goldens == null) print("GOLDEN ${Platform.operatingSystem} '$name': '$first',");
      if (goldens != null) expect(first, goldens[name], reason: name);
    }
  });
}
