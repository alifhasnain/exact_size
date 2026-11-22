import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/compression_service.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/pick/data/pick_outcome_log.dart';
import 'package:exact_size/features/pick/data/system_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/fake_system_picker.dart';

void main() {
  // The start screen is the pick screen (FEAT-001 OQ-4); its controller reads get_it.
  setUp(() async {
    await getIt.reset();
    getIt
      ..registerSingleton<SystemPicker>(FakeSystemPicker())
      ..registerSingleton<TempFiles>(TempFiles(Directory.systemTemp, folder: 'exactsize_app_test_camera'), instanceName: 'camera')
      ..registerSingleton<SourceProbe>(const SourceProbe())
      ..registerSingleton(const PickOutcomeLog());
  });

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
    await getIt.reset(); // drop the setUp fakes
    await configureDependencies();
    expect(getIt<CompressionService>(), isNotNull);
    expect(getIt<TempFiles>().dir.path, startsWith(cache.path));
    await getIt.reset();
    cache.deleteSync(recursive: true);
  });
}
