import 'package:integration_test/integration_test.dart';

import '../test_support/es_crop_cases.dart';

/// FEAT-002-T14 on the emulator: orient, finish, and pixels read in C through
/// the jnigraphics lock match the Java values.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineEsCropTests();
}
