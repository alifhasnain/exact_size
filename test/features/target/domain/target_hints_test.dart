import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/target/domain/target_hints.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-005-T05: photo line, "Use photo size", upscale and very-small hints.
void main() {
  SourceInfo src(int w, int h, {int exif = 1}) => SourceInfo(
      rawWidth: w, rawHeight: h, mime: 'image/jpeg', exifOrientation: exif, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);

  test('EXIF 6: a 4000x3000 source is a 3000x4000 photo', () {
    final h = targetHints(src(4000, 3000, exif: 6));
    expect((h.photoWidth, h.photoHeight), (3000, 4000));
    expect(targetHints(src(4000, 3000)).photoWidth, 4000);
  });

  test('enlarges when the target is bigger than the crop can cover', () {
    expect(targetHints(src(200, 200), width: 300, height: 300).enlarges, isTrue);
    expect(targetHints(src(300, 300), width: 300, height: 300).enlarges, isFalse);
    expect(targetHints(src(4000, 3000), width: 300, height: 300).enlarges, isFalse);
    // Oriented size counts: 3000 wide after EXIF 6, so a 3500-wide target enlarges.
    expect(targetHints(src(4000, 3000, exif: 6), width: 3500, height: 100).enlarges, isTrue);
  });

  test('"Use photo size" only when the photo is a valid target', () {
    expect(targetHints(src(12000, 1000)).canUsePhotoSize, isFalse);
    expect(targetHints(src(6001, 4000)).canUsePhotoSize, isFalse);
    expect(targetHints(src(4000, 3000)).canUsePhotoSize, isTrue);
  });

  test('very small below 16 px a side', () {
    expect(targetHints(src(4000, 3000), width: 15, height: 300).verySmall, isTrue);
    expect(targetHints(src(4000, 3000), width: 300, height: 15).verySmall, isTrue);
    expect(targetHints(src(4000, 3000), width: 16, height: 16).verySmall, isFalse);
  });

  test('an invalid or missing size gives no enlarge and no very-small hint', () {
    for (final (w, h) in [(0, 10), (10, 0), (10001, 5), (6001, 4000), (null, 10), (10, null)]) {
      final hints = targetHints(src(10, 10), width: w, height: h);
      expect(hints.enlarges, isFalse, reason: '$w x $h');
      expect(hints.verySmall, isFalse, reason: '$w x $h');
    }
  });
}
