import 'dart:ffi';
import 'dart:io';

import 'package:es_codec/es_codec.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jni/jni.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-002-T04 spike, gate G1 (ADR-004, ADR-005): what Android's decoders do
/// with each fixture. Run with test_driver/push_fixtures_driver.dart, which
/// copies the fixtures into files/fixtures/. Prints one DECODE line per file
/// and the HEIC orientation comparison; asserts only the G1 conditions.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUpAll(() async {
    dir = Directory('${(await getApplicationSupportDirectory()).path}/fixtures');
    for (var i = 0; i < 600 && !File('${dir.path}/.ready').existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(File('${dir.path}/.ready').existsSync(), isTrue, reason: 'fixtures were not pushed');
  });

  int rssKb() {
    final line = File('/proc/self/status').readAsLinesSync().firstWhere((l) => l.startsWith('VmRSS:'));
    return int.parse(RegExp(r'(\d+)').firstMatch(line)!.group(1)!);
  }

  String colourAt(Bitmap b, double fx, double fy) {
    final c = b.getPixel((b.width * fx).floor(), (b.height * fy).floor());
    final r = (c >> 16) & 0xff, g = (c >> 8) & 0xff, bl = c & 0xff;
    if (r > 180 && g < 100 && bl < 100) return 'red';
    if (g > 140 && r < 100 && bl < 120) return 'green';
    if (bl > 180 && r < 100) return 'blue';
    if (r > 200 && g > 180 && bl < 100) return 'yellow';
    return 'other';
  }

  /// Upright = landscape with red top-left and yellow bottom-right (T02 pattern).
  bool upright(Bitmap b) => b.width > b.height && colourAt(b, .2, .2) == 'red' && colourAt(b, .8, .8) == 'yellow';

  BitmapFactory$Options options({int sample = 1, bool bounds = false}) => BitmapFactory$Options()
    ..inJustDecodeBounds = bounds
    ..inSampleSize = sample
    ..inPreferredConfig = Bitmap$Config.ARGB_8888
    ..inPreferredColorSpace = ColorSpace.get(ColorSpace$Named.SRGB)
    ..inPremultiplied = false;

  String describe(Bitmap b) =>
      '${b.width}x${b.height} ${b.config?.toString() ?? '-'} ${b.colorSpace?.name?.toDartString() ?? '-'} '
      'premul=${b.isPremultiplied}';

  /// Region decode of the whole image at [sample]; falls back to a full
  /// decode when the region decoder can't open the file.
  ({String path, String result, int deltaKb, Bitmap? bitmap}) decode(String file, int sample) {
    final path = '${dir.path}/$file';
    final before = rssKb();
    final jpath = path.toJString();
    try {
      // newInstance(String) is API 31+; this overload works from API 10 (deprecated in 31).
      // ignore: deprecated_member_use
      final region = BitmapRegionDecoder.newInstance$7(jpath, false);
      if (region != null) {
        final rect = Rect.new$2(0, 0, region.width, region.height);
        final b = region.decodeRegion(rect, options(sample: sample));
        region.recycle();
        return (path: 'region', result: b == null ? 'null' : describe(b), deltaKb: rssKb() - before, bitmap: b);
      }
    } catch (e) {
      final msg = '$e'.split('\n').first;
      if (msg.contains('OutOfMemory')) return (path: 'region', result: 'OOM', deltaKb: rssKb() - before, bitmap: null);
      // region decoder can't open it: try a full decode below
    }
    try {
      final b = BitmapFactory.decodeFile$1(jpath, options(sample: sample));
      return (path: 'full', result: b == null ? 'null' : describe(b), deltaKb: rssKb() - before, bitmap: b);
    } catch (e) {
      final msg = '$e'.split('\n').first;
      return (path: 'full', result: msg.contains('OutOfMemory') ? 'OOM' : 'error', deltaKb: rssKb() - before, bitmap: null);
    } finally {
      jpath.release();
    }
  }

  (int, int, String) bounds(String file) {
    final o = options(bounds: true);
    final p = '${dir.path}/$file'.toJString();
    BitmapFactory.decodeFile$1(p, o);
    p.release();
    return (o.outWidth, o.outHeight, o.outMimeType?.toDartString() ?? '-');
  }

  void free(Bitmap? b) {
    b?.recycle();
    b?.release();
  }

  test('decode matrix (small fixtures)', () {
    final names = dir.listSync().map((e) => e.uri.pathSegments.last).where((n) => !n.startsWith('.') && !n.startsWith('large_')).toList()
      ..sort();
    for (final n in names) {
      final (w, h, mime) = bounds(n);
      final d = decode(n, 1);
      // ignore: avoid_print
      print('DECODE $n bounds=${w}x$h $mime ${d.path} ${d.result} upright=${d.bitmap != null && upright(d.bitmap!)}');
      free(d.bitmap);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('HEIC orientation: EXIF read by ExifInterface vs ImageDecoder oracle', () {
    final names = dir.listSync().map((e) => e.uri.pathSegments.last).where((n) => n.endsWith('.heic') && n.startsWith('orient_')).toList()
      ..sort();
    for (final n in names) {
      final path = '${dir.path}/$n';
      final jpath = path.toJString();
      final exif = ExifInterface.new$4(jpath);
      final orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 1);
      exif.release();
      // Oracle: ImageDecoder applies the container's transforms itself.
      final bytes = File(path).readAsBytesSync();
      final buffer = JByteBuffer.allocateDirect(bytes.length)..asUint8List().setAll(0, bytes);
      final hw = ImageDecoder.decodeBitmap(ImageDecoder.createSource$6(buffer));
      final oracle = hw?.copy(Bitmap$Config.ARGB_8888, false);
      free(hw);
      // Ours: BitmapFactory, then EXIF orientation applied by us (FEAT-002 Orientation).
      final raw = BitmapFactory.decodeFile$1(jpath, options());
      jpath.release();
      // ignore: avoid_print
      print('HEIC $n exif=$orientation raw=${raw!.width}x${raw.height} rawUpright=${upright(raw)} '
          'rawTopLeft=${colourAt(raw, .2, .2)} oracle=${oracle!.width}x${oracle.height} oracleUpright=${upright(oracle)}');
      free(raw);
      free(oracle);
      buffer.release();
    }
  });

  test('large sources: bounds, region decode with inSampleSize, memory', () {
    final names = dir.listSync().map((e) => e.uri.pathSegments.last).where((n) => n.startsWith('large_')).toList()..sort();
    if (names.isEmpty) {
      markTestSkipped('no large set pushed (LARGE_DIR)');
      return;
    }
    for (final n in names) {
      final (w, h, mime) = bounds(n);
      // Preview-style decode: long side ≤ 2048 (FEAT-002-T15).
      var s = 1;
      while ((w > h ? w : h) / s > 2048) {
        s *= 2;
      }
      final sw = Stopwatch()..start();
      final d = decode(n, s);
      // ignore: avoid_print
      print('LARGE $n bounds=${w}x$h $mime sample=$s ${d.path} ${d.result} rssDelta=${d.deltaKb ~/ 1024} MB ${sw.elapsedMilliseconds} ms');
      free(d.bitmap);
    }
  }, timeout: const Timeout(Duration(minutes: 20)));

  test('NFR-2: 12 MP source to a 2 MP target, and a 24 MP target region', () {
    final names = dir.listSync().map((e) => e.uri.pathSegments.last).toList();
    final twelve = names.where((n) => n.startsWith('large_12mp') && n.endsWith('baseline.jpg')).firstOrNull;
    final fifty = names.where((n) => n.startsWith('large_50mp') && n.endsWith('baseline.jpg')).firstOrNull;
    if (twelve == null || fifty == null) {
      markTestSkipped('needs the 12 and 50 MP large set');
      return;
    }
    // 12 MP → 2 MP: region decode at sample 2 (≥ target), then stb to exact size.
    final base = rssKb();
    final d12 = decode(twelve, 2);
    final b = d12.bitmap!;
    final (bw, bh) = (b.width, b.height);
    final bytes = bw * bh * 4;
    final src = malloc<Uint8>(bytes), dst = malloc<Uint8>(1633 * 1225 * 4);
    copyBitmapRgba(b, src, bytes);
    free(b);
    resample(src, bw, bh, bw * 4, dst, 1633, 1225, alpha: false);
    final peak12 = (rssKb() - base) ~/ 1024;
    malloc
      ..free(src)
      ..free(dst);
    // 24 MP target: a 24 MP region of the 50 MP source at sample 1.
    final base24 = rssKb();
    final jpath = '${dir.path}/$fifty'.toJString();
    // ignore: deprecated_member_use
    final region = BitmapRegionDecoder.newInstance$7(jpath, false)!;
    final r24 = region.decodeRegion(Rect.new$2(0, 0, 5657, 4243), options());
    final peak24 = (rssKb() - base24) ~/ 1024;
    region.recycle();
    jpath.release();
    // ignore: avoid_print
    print('NFR2 12MP->2MP rssDelta=$peak12 MB (limit 200) | 24MP region ${r24?.width}x${r24?.height} rssDelta=$peak24 MB (limit 350)');
    free(r24);
    expect(peak12, lessThanOrEqualTo(200));
    expect(peak24, lessThanOrEqualTo(350));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
