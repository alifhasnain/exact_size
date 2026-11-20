import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/compression_service.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// FEAT-004-T20 on the device: main() resolves the get_it container (the
/// cache folder comes from path_provider) and the app starts.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts with the DI container ready', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('ExactSize'), findsOneWidget);
    expect(getIt<CompressionService>(), isNotNull);
    expect(getIt<TempFiles>().dir.path, contains('exactsize_out'));
  });
}
