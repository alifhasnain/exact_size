import 'package:exact_size/app.dart';
import 'package:exact_size/di/injection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('app starts and shows the app name', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ExactSizeApp()));
    await tester.pumpAndSettle();
    expect(find.text('ExactSize'), findsOneWidget);
  });

  testWidgets('Arabic locale lays out right-to-left', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ExactSizeApp(locale: Locale('ar'))),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Localizations.localeOf(context).languageCode, 'ar');
  });

  test('DI container configures without errors', () async {
    configureDependencies();
    await getIt.reset();
  });
}
