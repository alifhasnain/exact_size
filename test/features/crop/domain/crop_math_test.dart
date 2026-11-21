import 'dart:math';

import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';

SourceInfo src(int w, int h, {int exif = 1}) => SourceInfo(
      rawWidth: w,
      rawHeight: h,
      mime: 'image/jpeg',
      exifOrientation: exif,
      isAnimated: false,
      hasAlpha: false,
      decodePath: DecodePath.region,
    );

CropRect initialRect(SourceInfo s, Target t) => CropMath.toCropRect(CropMath.initial(s, t), s, t);

/// The rect is within 1 source px per side of some exact-ratio rect.
bool ratioOk(CropRect r, Target t) =>
    (r.h - r.w * t.height / t.width).abs() < 1 || (r.w - r.h * t.width / t.height).abs() < 1;

void main() {
  test('4000×3000 → 300×300 gives (500, 0, 3000, 3000)', () {
    expect(initialRect(src(4000, 3000), const Target(300, 300)), const CropRect(500, 0, 3000, 3000));
  });

  test('3000×4000 → 300×80 gives the centred full-width strip 3000×800', () {
    expect(initialRect(src(3000, 4000), const Target(300, 80)), const CropRect(0, 1600, 3000, 800));
  });

  test('140×60 ratio holds', () {
    const t = Target(140, 60);
    final r = initialRect(src(4000, 3000), t);
    expect(r.w, 4000);
    expect(r.h, 1714); // 4000 × 60 / 140 = 1714.29
    expect(ratioOk(r, t), isTrue);
  });

  test('square/square and equal-ratio sources give the whole image', () {
    expect(initialRect(src(1000, 1000), const Target(300, 300)), const CropRect(0, 0, 1000, 1000));
    expect(initialRect(src(4000, 3000), const Target(400, 300)), const CropRect(0, 0, 4000, 3000));
  });

  test('EXIF 6 swaps the oriented size', () {
    expect(initialRect(src(4000, 3000, exif: 6), const Target(300, 400)), const CropRect(0, 0, 3000, 4000));
  });

  test('1×1 and 7×7 sources give a valid rect', () {
    for (final s in [src(1, 1), src(7, 7)]) {
      for (final t in const [Target(300, 300), Target(300, 80), Target(80, 300)]) {
        final r = initialRect(s, t);
        expect(r.w >= 1 && r.h >= 1, isTrue);
        expect(r.x >= 0 && r.y >= 0 && r.x + r.w <= s.rawWidth && r.y + r.h <= s.rawHeight, isTrue, reason: '$r');
      }
    }
  });

  test('upscale factor: 200×200 → 300×300 is 1.5; 1000×100 uses the limiting axis', () {
    expect(CropMath.upscaleFactor(initialRect(src(200, 200), const Target(300, 300)), const Target(300, 300)), 1.5);
    final r = initialRect(src(1000, 100), const Target(300, 300));
    expect(r, const CropRect(450, 0, 100, 100));
    expect(CropMath.upscaleFactor(r, const Target(300, 300)), 3.0);
  });

  test('sample size', () {
    expect(CropMath.sampleSize(const CropRect(0, 0, 3000, 3000), const Target(300, 300)), 8);
    expect(CropMath.sampleSize(const CropRect(0, 0, 200, 200), const Target(300, 300)), 1);
    expect(CropMath.sampleSize(const CropRect(0, 0, 600, 600), const Target(300, 300)), 2);
    expect(CropMath.sampleSize(const CropRect(0, 0, 599, 600), const Target(300, 300)), 1);
    expect(CropMath.sampleSize(const CropRect(0, 0, 4000, 800), const Target(300, 80)), 8); // 800/8 = 100 ≥ 80
  });

  test('minimum crop: 32 px short side or 8× cover, capped at cover', () {
    // 4000×3000 → 300×300: cover 3000, cover/8 = 375 > 32.
    expect(CropMath.minWidth(4000, 3000, const Target(300, 300)), 375);
    // 200×200: cover 200, cover/8 = 25 < 32 → 32.
    expect(CropMath.minWidth(200, 200, const Target(300, 300)), 32);
    // 20×20: 32 > cover → capped at 20.
    expect(CropMath.minWidth(20, 20, const Target(300, 300)), 20);
    // Wide target 300×80 on 200×200: short side is the height, 32 px → width 120.
    expect(CropMath.minWidth(200, 200, const Target(300, 80)), 120);
  });

  test('10,000 seeded cases: inside the image, ratio within 1 px, deterministic', () {
    final rng = Random(7);
    for (var i = 0; i < 10000; i++) {
      final s = src(1 + rng.nextInt(12000), 1 + rng.nextInt(12000), exif: 1 + rng.nextInt(8));
      final t = Target(1 + rng.nextInt(10000), 1 + rng.nextInt(10000));
      final q = rng.nextInt(4);
      final (sw, sh) = CropMath.orientedSize(s, q);
      final state = CropState(
        cx: rng.nextDouble() * sw * 1.2 - sw * 0.1,
        cy: rng.nextDouble() * sh * 1.2 - sh * 0.1,
        cw: rng.nextDouble() * sw * 1.5,
        quarterTurns: q,
      );
      final r = CropMath.toCropRect(state, s, t);
      final reason = '$s ${sw}x$sh $t $state → $r';
      expect(r.w >= 1 && r.h >= 1, isTrue, reason: reason);
      expect(r.x >= 0 && r.y >= 0 && r.x + r.w <= sw && r.y + r.h <= sh, isTrue, reason: reason);
      // Tiny sources may not hold the ratio at 1 px (a 1×1 source with a
      // 300×80 target); everywhere else it holds.
      if (min(sw, sh) >= 32) expect(ratioOk(r, t), isTrue, reason: reason);
      expect(CropMath.toCropRect(state, s, t), r);
    }
  });
}
