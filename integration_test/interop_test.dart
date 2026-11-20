import 'package:es_codec/es_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// FEAT-004-T02 / gate G0: FFIgen and JNIgen bindings work on a device.
/// CI runs it on an API 28 emulator with --dart-define=EXPECTED_SDK_INT=28.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('FFIgen binding calls into C', () {
    expect(esProbeAdd(2, 3), 5);
  });

  test('JNIgen binding reads Build.VERSION.SDK_INT', () {
    const expected = int.fromEnvironment('EXPECTED_SDK_INT');
    final sdk = androidSdkInt();
    if (expected > 0) {
      expect(sdk, expected);
    } else {
      expect(sdk, greaterThanOrEqualTo(28));
    }
  });
}
