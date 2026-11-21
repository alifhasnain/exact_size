import 'package:exact_size/features/pick/data/android_system_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// FEAT-001-T12 on a device: the Kotlin bridge answers, and nothing is pending at rest.
/// The CI API 28 job runs it through bundle.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('bridge answers at rest', () async {
    final picker = AndroidSystemPicker();
    expect(await picker.cameraAvailable(), isA<bool>());
    expect(await picker.takeResult(), isNull);
    expect(await picker.pendingCaptureName(), isNull);
  });
}
