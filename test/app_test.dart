import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/compression_service.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:flutter/services.dart';
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
    TestWidgetsFlutterBinding.ensureInitialized();
    final cache = Directory.systemTemp.createTempSync('exactsize_di_');
    // path_provider has no host implementation in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => cache.path);
    await configureDependencies();
    expect(getIt<CompressionService>(), isNotNull);
    expect(getIt<TempFiles>().dir.path, startsWith(cache.path));
    await getIt.reset();
    cache.deleteSync(recursive: true);
  });
}
