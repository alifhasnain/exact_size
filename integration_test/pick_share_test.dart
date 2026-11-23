import 'dart:io';

import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/pick/presentation/pick_controller.dart';
import 'package:exact_size/features/pick/presentation/pick_view.dart';
import 'package:exact_size/main.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-001-T25 (FR-20, AC-8.1, AC-8.2, AC-8.5), warm start: the real app and
/// bridge receive shares fired by `test_driver/share_intent_driver.dart` through
/// ShareTargetActivity. The driver also checks AC-8.3, a second warm share and a
/// cold start after this test. Synthetic image only.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('warm shares: file:// and no grant refused, content accepted, no stream refused', (tester) async {
    // App data survives reinstalls: drop a request left by an aborted run before the driver serves.
    final request = File('${(await getApplicationSupportDirectory()).path}/share_request');
    if (request.existsSync()) request.deleteSync();
    await app.main();
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(PickView)));

    Future<PickState> shareAndWait(String kind, bool Function(PickState) done) async {
      await request.writeAsString(kind);
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200)); // live binding: pump does not wait
        await tester.pump();
        final s = c.read(pickControllerProvider);
        if (done(s)) return s;
      }
      fail('$kind share: no result within 20 s');
    }

    // AC-8.2: a file:// stream is refused before probing.
    var s = await shareAndWait('file', (s) => s.message != null);
    expect(s.message, PickMessage.itemNotOpenable);
    expect(find.text("We can't open that item. Choose a photo instead."), findsOneWidget);

    // AC-8.5: the stream without a read grant fails in the probe.
    s = await shareAndWait('nogrant', (s) => s.message == PickMessage.sourceUnavailable);
    expect(s.current, isNull);

    // AC-8.1: a granted MediaStore image goes on like a gallery pick (target step next).
    s = await shareAndWait('content', (s) => s.current != null);
    expect(s.current!.origin, PickOrigin.share);
    expect(s.current!.cameraFile, isNull, reason: 'shared images are never copied');
    expect(s.message, isNull);
    await tester.pumpAndSettle();
    expect(find.textContaining('120 x 80'), findsOneWidget);

    // A share without a stream: refused; the current image stays (AC-3.3).
    final current = s.current;
    s = await shareAndWait('nostream', (s) => s.message != null);
    expect(s.message, PickMessage.itemNotOpenable);
    expect(s.current, same(current));
  });
}
