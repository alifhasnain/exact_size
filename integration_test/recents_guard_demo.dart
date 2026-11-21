import 'package:exact_size/features/crop/presentation/recents_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// FEAT-002-T19 manual evidence (not in CI): shows a synthetic red/blue screen
/// under RecentsGuard for 40 s, so `adb exec-out screencap` and the recents
/// thumbnail can be compared from the host.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('guarded synthetic screen', (tester) async {
    await tester.pumpWidget(const RecentsGuard(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          Expanded(child: ColoredBox(color: Color(0xFFE53935), child: SizedBox.expand())),
          Expanded(child: ColoredBox(color: Color(0xFF1E88E5), child: SizedBox.expand())),
        ]),
      ),
    ));
    // ignore: avoid_print
    print('RECENTS_DEMO_READY');
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 40)));
  });
}
