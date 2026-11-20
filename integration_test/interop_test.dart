import 'package:es_codec/es_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// JNIgen binding works on a device (FEAT-004-T02, gate G0). The FFI side is
/// covered by jpeg_spike_test.dart. CI runs this on an API 28 emulator with
/// --dart-define=EXPECTED_SDK_INT=28.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
