import 'package:integration_test/integration_test.dart';

import '../test_support/compression_runner_cases.dart';

/// FEAT-004-T16 Done when: progress, cancel, leak counter and layout checks on the emulator.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineCompressionRunnerTests();
}
