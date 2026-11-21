import 'dart:ffi';

import 'package:integration_test/integration_test.dart';

import '../test_support/es_resample_cases.dart';

/// FEAT-002-T13 on the emulator: sizes, identity, stride, no fringe, goldens.
/// The goldens match on x86_64 (emulator); ARM devices check only that two
/// runs agree, because NEON may round differently (ADR-005, cross-device is Should).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineEsResampleTests(goldens: Abi.current() == Abi.androidX64 ? resampleGoldens : null);
}
