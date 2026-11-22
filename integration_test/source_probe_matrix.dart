import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-002-T12: SourceProbe on every T02 small fixture (and the large set
/// when pushed), through file:// URIs and the same ContentResolver path as a
/// picked content:// URI. Run with test_driver/push_fixtures_driver.dart
/// (not named `_test`: it needs the pushed fixtures, see bundle.dart).
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

  /// Expected result per fixture; null orientation = don't check.
  Object expected(String n) {
    if (n == 'not_an_image.jpg' || n == 'truncated.jpg' || n == 'corrupt.png' || n == 'zero_bytes.jpg') return Reason.corruptInput;
    if (n == 'claims_200000001px.png' || n == 'claims_250mp.png') return Reason.imageTooLarge;
    if (n == 'video_ftyp_only.mp4') return Reason.corruptInput; // ftyp without a HEIF brand
    final m = RegExp(r'^orient_(\d)').firstMatch(n);
    final orientation = switch (m?.group(1)) {
      null => 1,
      '0' || '9' => 1,
      final d => int.parse(d),
    };
    return (orientation: orientation);
  }

  test('probe gives the expected SourceInfo or Reason for every fixture, original untouched', () async {
    final names = dir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => !n.startsWith('.')).toList()
      ..sort();
    expect(names.length, greaterThanOrEqualTo(53));
    for (final n in names) {
      final file = File('${dir.path}/$n');
      final before = (sha256.convert(file.readAsBytesSync()), file.lastModifiedSync());
      final r = await const SourceProbe().probe(SourceHandle(file.uri.toString()));
      final after = (sha256.convert(file.readAsBytesSync()), file.lastModifiedSync());
      expect(after, before, reason: '$n changed');

      final e = expected(n);
      final desc = switch (r) {
        ProbeOk(:final info) =>
          '${info.rawWidth}x${info.rawHeight} ${info.mime} exif=${info.exifOrientation} anim=${info.isAnimated} '
              'alpha=${info.hasAlpha} ${info.decodePath.name}',
        ProbeErr(:final reason) => reason.code,
      };
      // ignore: avoid_print
      print('PROBE $n $desc');

      if (n == 'depth10.heic') {
        // API 28 refuses bounds (UNSUPPORTED_INPUT); API 36 reads bounds and
        // fails later at decode (T04 row 7).
        expect(r is ProbeOk || (r as ProbeErr).reason == Reason.unsupportedInput, isTrue, reason: n);
        continue;
      }
      if (e is Reason) {
        expect(r, isA<ProbeErr>().having((x) => x.reason, 'reason', e), reason: n);
        continue;
      }
      expect(r, isA<ProbeOk>(), reason: '$n $desc');
      final info = (r as ProbeOk).info;
      expect(info.exifOrientation, (e as ({int orientation})).orientation, reason: n);
      if (n.startsWith('animated.')) {
        expect(info.isAnimated, isTrue, reason: n);
        expect(info.decodePath, n.endsWith('.gif') ? DecodePath.full : DecodePath.region, reason: n);
      } else if (!n.startsWith('large_')) {
        expect(info.isAnimated, isFalse, reason: n);
      }
      if (n.startsWith('alpha_')) expect(info.hasAlpha, isTrue, reason: n);
      if (n.endsWith('.heic')) expect(info.decodePath, DecodePath.region, reason: n);
    }
  });

  test('a missing file gives SOURCE_UNAVAILABLE; the handle never prints its URI', () async {
    final missing = SourceHandle(File('${dir.path}/[PLACEHOLDER]-missing.jpg').uri.toString());
    expect(await const SourceProbe().probe(missing), isA<ProbeErr>().having((e) => e.reason, 'reason', Reason.sourceUnavailable));
    expect(missing.toString(), isNot(contains('file:')));
    expect(missing.toString(), isNot(contains('missing')));
  });
}
