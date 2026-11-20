import 'package:exact_size/features/compression/data/memory_preflight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_support/memory_preflight_cases.dart';

/// FEAT-004-T18 on the device: the same checks, plus the tech.md assumption
/// that `/proc/meminfo` is readable on API 28–36.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineMemoryPreflightTests();

  test('real /proc/meminfo is readable and has MemAvailable', () async {
    final text = await readProcMeminfo();
    expect(text, isNotNull);
    expect(parseMemAvailable(text!), greaterThan(0));
    // A 2 MP job passes the real check on the test devices.
    expect(await const MemoryPreflight().check(width: 1600, height: 1250), isNull);
  });
}
