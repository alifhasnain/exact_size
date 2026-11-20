import 'package:integration_test/integration_test.dart';

import '../test_support/turbo_jpeg_encoder_cases.dart';

/// FEAT-004-T06 Done when: marker layout, determinism and typed errors on the emulator.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineTurboJpegEncoderTests();
}
