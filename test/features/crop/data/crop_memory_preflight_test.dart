import 'package:exact_size/features/crop/data/crop_memory_preflight.dart';
import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';

SourceInfo jpeg(int w, int h, {bool progressive = false}) => SourceInfo(
      rawWidth: w,
      rawHeight: h,
      mime: 'image/jpeg',
      exifOrientation: 1,
      isAnimated: false,
      hasAlpha: false,
      decodePath: DecodePath.region,
      isProgressive: progressive,
    );

MeminfoText mem(int availableMb) => () async => 'MemTotal: 2000000 kB\nMemAvailable: ${availableMb * 1024} kB\n';

typedef MeminfoText = Future<String?> Function();

void main() {
  Future<Reason?> check(SourceInfo info, Target t, MeminfoText reader, {bool reorient = false}) {
    final raw = CropRect(0, 0, info.rawWidth, info.rawHeight < info.rawWidth ? info.rawHeight : info.rawWidth);
    return CropMemoryPreflight(readMeminfo: reader)
        .check(info: info, raw: raw, sample: CropMath.sampleSize(raw, t), target: t, reorient: reorient);
  }

  test('12 MP → 2 MP with ample memory passes', () async {
    expect(await check(jpeg(4000, 3000), const Target(1414, 1414), mem(900)), isNull);
    expect(await check(jpeg(4000, 3000, progressive: true), const Target(1414, 1414), mem(900)), isNull);
  });

  test('24 MP target with low MemAvailable gives IMAGE_TOO_LARGE', () async {
    expect(await check(jpeg(8000, 6000), const Target(6000, 4000), mem(150)), Reason.imageTooLarge);
    expect(await check(jpeg(8000, 6000), const Target(6000, 4000), mem(2000)), isNull);
  });

  test('progressive 200 MP JPEG needs far more than baseline (T04 factors)', () {
    const raw = CropRect(0, 0, 16329, 12248);
    final base = CropMemoryPreflight.estimate(info: jpeg(16329, 12248), raw: raw, sample: 16, target: const Target(1000, 750), reorient: false);
    final prog = CropMemoryPreflight.estimate(
        info: jpeg(16329, 12248, progressive: true), raw: raw, sample: 16, target: const Target(1000, 750), reorient: false);
    expect(prog, greaterThan(base * 3));
    expect(prog, greaterThan(650 << 20)); // about 700 MB working memory
  });

  test('a transform buffer is counted when the output is re-oriented', () {
    const raw = CropRect(0, 0, 3000, 3000);
    final a = CropMemoryPreflight.estimate(info: jpeg(4000, 3000), raw: raw, sample: 8, target: const Target(300, 300), reorient: false);
    final b = CropMemoryPreflight.estimate(info: jpeg(4000, 3000), raw: raw, sample: 8, target: const Target(300, 300), reorient: true);
    expect(b - a, 300 * 300 * 4);
  });

  test('unreadable or malformed meminfo: no crash and no refusal', () async {
    expect(await check(jpeg(8000, 6000), const Target(6000, 4000), () async => null), isNull);
    expect(await check(jpeg(8000, 6000), const Target(6000, 4000), () async => throw StateError('x')), isNull);
    expect(await check(jpeg(8000, 6000), const Target(6000, 4000), () async => 'garbage'), isNull);
  });
}
