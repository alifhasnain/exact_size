import 'package:exact_size/features/crop/presentation/recents_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// FEAT-002-T19 on the device: the real binding runs without a crash on any
/// API level (API 28: no call; API 33+: off then on).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('RecentsGuard with the real binding: no crash', (tester) async {
    const binding = AndroidRecentsBinding();
    expect(binding.sdkInt, greaterThanOrEqualTo(28));
    await tester.pumpWidget(const RecentsGuard(child: SizedBox()));
    await tester.pumpWidget(const SizedBox());
  });
}
