import 'dart:typed_data';

import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/jpeg_padder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../../../test_support/jpeg_markers.dart';
import '../../../../test_support/synthetic_image.dart';

/// FEAT-004-T12: FR-8 lever 4 (JPEG comment padding), AC-2.2, AC-2.3.
void main() {
  // A real baseline JPEG with JFIF APP0 (pure-Dart encoder, host only).
  final source = Uint8List.fromList(img.encodeJpg(
      img.Image.fromBytes(width: 64, height: 48, bytes: syntheticRgba(64, 48).buffer, numChannels: 4),
      quality: 80));

  /// Window that makes [padJpeg] add exactly [amount] bytes (target = lo + 1024 rule).
  ByteWindow windowFor(int amount) {
    // With hi − lo ≥ 2048 the target is lo + 1024, so pad = lo + 1024 − size.
    final lo = source.length + amount - 1024;
    return ByteWindow.bytes(lo, lo + 4096);
  }

  /// COM segment total sizes, parsed back from the padded file.
  List<int> comSegments(Uint8List b) {
    final sizes = <int>[];
    var i = 2;
    while (b[i] == 0xFF && b[i + 1] != 0xDA) {
      final len = (b[i + 2] << 8) | b[i + 3];
      if (b[i + 1] == 0xFE) sizes.add(len + 2);
      i += 2 + len;
    }
    return sizes;
  }

  final cases = {
    4: [4],
    5: [5],
    65537: [65537],
    65538: [65534, 4],
    65540: [65536, 4],
    200000: [65537, 65537, 65537, 3389],
  };
  cases.forEach((amount, expected) {
    test('pad $amount bytes → segments $expected', () {
      expect(segmentSizes(amount), expected);
      final out = padJpeg(source, windowFor(amount), jumpCase: false) as Padded;
      expect(out.paddingBytes, amount);
      expect(out.bytes.length, source.length + amount);
      expect(comSegments(out.bytes), expected);
    });
  });

  test('padded file: valid JPEG, APP0 first, EOI last, identical pixels, constant payload', () {
    final out = padJpeg(source, windowFor(70000), jumpCase: false) as Padded;
    final b = out.bytes;
    final info = parseJpeg(b);
    expect(info.markers.take(3), [0xD8, 0xE0, 0xFE], reason: 'COM spliced right after APP0');
    expect(b.sublist(b.length - 2), [0xFF, 0xD9], reason: 'nothing after EOI');
    expect(img.decodeJpg(b)!.getBytes(), img.decodeJpg(source)!.getBytes(), reason: 'pixels unchanged');
    // Every payload byte is 0x20: no user, device or time data (AC-2.3).
    var i = 2 + 2 + ((b[4] << 8) | b[5]); // after SOI + APP0
    while (b[i + 1] == 0xFE) {
      final len = (b[i + 2] << 8) | b[i + 3];
      expect(b.sublist(i + 4, i + 2 + len).every((x) => x == paddingByte), isTrue);
      i += 2 + len;
    }
  });

  test('target is lo + min(1024, (hi − lo) ÷ 2), capped at hi', () {
    final lo = source.length + 100;
    final narrow = padJpeg(source, ByteWindow.bytes(lo, lo + 200), jumpCase: true) as Padded;
    expect(narrow.bytes.length, lo + 100); // (hi − lo) ÷ 2 = 100
    final wide = padJpeg(source, ByteWindow.bytes(lo, lo + 50000), jumpCase: false) as Padded;
    expect(wide.bytes.length, lo + 1024);
  });

  test('room of 3 bytes fails (BELOW_MIN, or NO_FIT in the jump case); room of 4 pads', () {
    final s = source.length;
    final three = ByteWindow.bytes(s + 2, s + 3);
    expect((padJpeg(source, three, jumpCase: false) as PaddingFailed).reason, Reason.belowMin);
    expect((padJpeg(source, three, jumpCase: true) as PaddingFailed).reason, Reason.noFit);
    final four = padJpeg(source, ByteWindow.bytes(s + 2, s + 4), jumpCase: false) as Padded;
    expect((four.paddingBytes, four.bytes.length), (4, s + 4));
  });

  test('padding twice gives identical bytes (FR-15)', () {
    final w = windowFor(12345);
    expect((padJpeg(source, w, jumpCase: false) as Padded).bytes,
        (padJpeg(source, w, jumpCase: false) as Padded).bytes);
  });
}
