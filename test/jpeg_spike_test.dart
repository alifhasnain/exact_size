import 'package:es_codec/es_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../test_support/synthetic_image.dart';

/// FEAT-004-T03 on the host (Windows MSVC / Linux CI): libjpeg-turbo builds and encodes.
/// The emulator version is integration_test/jpeg_spike_test.dart.
void main() {
  test('2 MP synthetic image encodes at q85 and decodes to 1600x1250', () {
    const w = 1600, h = 1250;
    final jpeg = encodeRgba8ToJpeg(syntheticRgba(w, h), w, h, quality: 85);
    expect(jpeg.sublist(0, 2), [0xFF, 0xD8]); // SOI
    final decoded = img.decodeJpg(jpeg)!;
    expect((decoded.width, decoded.height), (w, h));
  });
}
