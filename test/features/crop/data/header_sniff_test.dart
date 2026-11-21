import 'dart:io';

import 'package:exact_size/features/crop/data/byte_source.dart';
import 'package:exact_size/features/crop/data/container_check.dart';
import 'package:exact_size/features/crop/data/header_sniff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ({bool animated, bool alpha}) sniff(String name) {
    final src = MemoryByteSource(File('test_support/crop_fixtures/$name').readAsBytesSync());
    final ok = checkContainer(src) as ContainerOk;
    return sniffHeader(src, ok.format);
  }

  test('animation flags (WebP, GIF; stills are not animated)', () {
    expect(sniff('animated.webp').animated, isTrue);
    expect(sniff('animated.gif').animated, isTrue);
    for (final still in ['orient_1_exif.jpg', 'alpha_partial.png', 'orient_1.heic', 'gray.png']) {
      expect(sniff(still).animated, isFalse, reason: still);
    }
  });

  test('alpha flags from the header', () {
    expect(sniff('alpha_partial.png').alpha, isTrue);
    expect(sniff('alpha_opaque.png').alpha, isTrue); // has an alpha channel; es_finish drops it later
    expect(sniff('gray.png').alpha, isFalse);
    expect(sniff('orient_1_exif.jpg').alpha, isFalse);
    expect(sniff('orient_1.heic').alpha, isFalse);
  });
}
