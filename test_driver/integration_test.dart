import 'package:integration_test/integration_test_driver.dart';

/// Driver for `flutter drive --profile` benchmarks (FEAT-004-T04).
/// Writes the test's reportData to build/integration_response_data.json.
Future<void> main() => integrationDriver();
