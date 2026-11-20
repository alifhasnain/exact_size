import 'package:es_codec/es_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image/image.dart' as img;

import '../test_support/synthetic_image.dart';

/// FEAT-004-T03 Done when: on the emulator profile, libjpeg-turbo encodes the 2 MP image.
/// Host version: test/jpeg_spike_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('2 MP synthetic image encodes at q85 and decodes to 1600x1250', () {
    const w = 1600, h = 1250;
    final jpeg = encodeRgba8ToJpeg(syntheticRgba(w, h), w, h, quality: 85);
    expect(jpeg.sublist(0, 2), [0xFF, 0xD8]); // SOI
    final decoded = img.decodeJpg(jpeg)!;
    expect((decoded.width, decoded.height), (w, h));
  });
}
