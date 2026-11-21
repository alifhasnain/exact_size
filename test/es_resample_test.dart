import '../test_support/es_resample_cases.dart';

/// FEAT-002-T13 on the host; the emulator run is integration_test/es_resample_test.dart.
void main() => defineEsResampleTests(goldens: resampleGoldens);
