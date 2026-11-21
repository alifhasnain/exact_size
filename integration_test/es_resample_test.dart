import 'package:integration_test/integration_test.dart';

import '../test_support/es_resample_cases.dart';

/// FEAT-002-T13 on the emulator: sizes, identity, stride, no fringe, and the
/// goldens stable over two runs (device hashes may differ from the host's).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineEsResampleTests();
}
