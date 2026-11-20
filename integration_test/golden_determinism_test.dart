import 'package:integration_test/integration_test.dart';

import '../test_support/golden_cases.dart';

/// FEAT-004-T22 Done when: golden determinism on the emulator (AC-6.1).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineGoldenDeterminismTests();
}
