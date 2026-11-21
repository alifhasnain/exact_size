import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:exact_size/features/crop/data/byte_source.dart';
import 'package:exact_size/features/crop/data/container_check.dart';
import 'package:exact_size/features/crop/data/heif_orientation.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/orientation.dart';
import 'package:flutter_test/flutter_test.dart';

const dir = 'test_support/crop_fixtures';
ByteSource fixture(String name) => MemoryByteSource(File('$dir/$name').readAsBytesSync());

void main() {
  group('checkContainer on the T02 fixtures (FEAT-002-T30)', () {
    final expected = <String, (ContainerFormat, int, int)>{
      'alpha_opaque.png': (ContainerFormat.png, 0, 0),
      'animated.gif': (ContainerFormat.gif, 0, 0),
      'animated.webp': (ContainerFormat.webp, 0, 0),
      'cmyk.jpg': (ContainerFormat.jpeg, 0, 0),
      'depth10.heic': (ContainerFormat.heif, 0, 0),
      'depth16.png': (ContainerFormat.png, 0, 0),
      'orient_1_exif.jpg': (ContainerFormat.jpeg, 120, 80),
      'orient_6_exif.jpg': (ContainerFormat.jpeg, 80, 120),
      'orient_1.heic': (ContainerFormat.heif, 120, 80),
      'orient_6_irot_only.heic': (ContainerFormat.heif, 80, 120),
      'size_1x1.png': (ContainerFormat.png, 1, 1),
      'size_7x7.png': (ContainerFormat.png, 7, 7),
      'size_200x200.png': (ContainerFormat.png, 200, 200),
      'size_1000x100.png': (ContainerFormat.png, 1000, 100),
    };

    test('every valid small fixture gets a format and a size', () {
      final names = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList()..sort();
      const damaged = {'truncated.jpg', 'corrupt.png', 'not_an_image.jpg', 'claims_200000001px.png', 'MANIFEST.md'};
      for (final n in names.where((n) => !damaged.contains(n))) {
        final r = checkContainer(fixture(n));
        expect(r, isA<ContainerOk>(), reason: n);
        final ok = r as ContainerOk;
        final e = expected[n];
        if (e != null) {
          expect(ok.format, e.$1, reason: n);
          if (e.$2 > 0) expect((ok.width, ok.height), (e.$2, e.$3), reason: n);
        }
        final ext = n.split('.').last;
        expect(ok.format, switch (ext) {
          'jpg' => ContainerFormat.jpeg,
          'png' => ContainerFormat.png,
          'webp' => ContainerFormat.webp,
          'gif' => ContainerFormat.gif,
          _ => ContainerFormat.heif,
        }, reason: n);
      }
    });

    for (final (name, reason) in [
      ('truncated.jpg', Reason.corruptInput),
      ('corrupt.png', Reason.corruptInput),
      ('not_an_image.jpg', Reason.corruptInput),
      ('claims_200000001px.png', Reason.imageTooLarge),
    ]) {
      test('$name → ${reason.code}', () {
        final r = checkContainer(fixture(name));
        expect(r, isA<ContainerError>().having((e) => e.reason, 'reason', reason));
      });
    }

    test('progressive JPEG (SOF2) is flagged, baseline is not', () {
      final b = File('$dir/orient_1_exif.jpg').readAsBytesSync();
      expect((checkContainer(MemoryByteSource(b)) as ContainerOk).progressive, isFalse);
      final sof = [for (var i = 0; i + 1 < b.length; i++) if (b[i] == 0xff && b[i + 1] == 0xc0) i].first;
      final p = Uint8List.fromList(b)..[sof + 1] = 0xc2; // same frame header, progressive marker
      expect((checkContainer(MemoryByteSource(p)) as ContainerOk).progressive, isTrue);
    });

    test('bytes after a JPEG EOI (camera trailers) are allowed; an empty file is corrupt', () {
      final b = File('$dir/orient_1_exif.jpg').readAsBytesSync();
      final trailer = Uint8List.fromList([...b, ...List.filled(500, 0x41)]);
      expect(checkContainer(MemoryByteSource(trailer)), isA<ContainerOk>());
      expect(checkContainer(MemoryByteSource(Uint8List(0))), isA<ContainerError>());
    });
  });

  group('heifOrientation (ADR-004 v1.1)', () {
    test('HEIC orientation 1–8 via EXIF only, irot/imir only, and both', () {
      expect(heifOrientation(fixture('orient_1.heic')), 1);
      for (var n = 2; n <= 8; n++) {
        for (final kind in ['exif_only', 'irot_only', 'irot_and_exif']) {
          expect(heifOrientation(fixture('orient_${n}_$kind.heic')), n, reason: 'orient_${n}_$kind');
        }
      }
    });

    test('the raw stored size turned by the result matches the upright 120×80 pattern', () {
      for (var n = 1; n <= 8; n++) {
        final name = n == 1 ? 'orient_1.heic' : 'orient_${n}_irot_only.heic';
        final ok = checkContainer(fixture(name)) as ContainerOk;
        expect(Orientation.fromExif(heifOrientation(fixture(name))).orientedSize(ok.width, ok.height), (120, 80),
            reason: name);
      }
    });

    test('non-HEIF and damaged input give 1', () {
      expect(heifOrientation(fixture('orient_6_exif.jpg')), 1);
      expect(heifOrientation(MemoryByteSource(Uint8List(0))), 1);
    });
  });

  test('10,000 seeded truncations and byte flips never throw and stay fast', () {
    final rng = Random(30);
    final files = Directory(dir).listSync().whereType<File>().where((f) => !f.path.endsWith('.md')).toList();
    final sw = Stopwatch();
    var slowest = 0;
    for (var i = 0; i < 10000; i++) {
      final src = files[rng.nextInt(files.length)].readAsBytesSync();
      final Uint8List mutated;
      if (rng.nextBool()) {
        mutated = Uint8List.sublistView(src, 0, rng.nextInt(src.length + 1));
      } else {
        mutated = Uint8List.fromList(src);
        for (var k = 0; k < 1 + rng.nextInt(8); k++) {
          if (mutated.isEmpty) break;
          mutated[rng.nextInt(mutated.length)] = rng.nextInt(256);
        }
      }
      sw
        ..reset()
        ..start();
      final r = checkContainer(MemoryByteSource(mutated));
      final o = heifOrientation(MemoryByteSource(mutated));
      sw.stop();
      slowest = max(slowest, sw.elapsedMilliseconds);
      expect(r, isA<ContainerResult>());
      expect(o, inInclusiveRange(1, 8));
    }
    expect(slowest, lessThan(50));
  });
}
