import 'package:exact_size/app.dart';
import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/preview/presentation/preview_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-006-T17 demo build (manual, not in CI, not shipped): the real app, except that the real
/// measurer's result reports a file 1 MB larger than it is, so a real flow ends in the check's
/// mismatch state (AC-3.1, AC-3.3) on a phone. Build with `-t integration_test/check_mismatch_demo.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(ProviderScope(
    overrides: [outputMeasurerProvider.overrideWithValue(_TooBig(getIt<OutputMeasurer>()))],
    child: const ExactSizeApp(),
  ));
}

class _TooBig implements OutputMeasurer {
  _TooBig(this._real);
  final OutputMeasurer _real;

  @override
  Future<MeasureResult> measure(String path, {required int expectedBytes}) async => switch (await _real.measure(path, expectedBytes: expectedBytes)) {
        Measured(:final output) => Measured(MeasuredOutput(
            bytes: output.bytes + 1024 * 1024,
            width: output.width,
            height: output.height,
            format: output.format,
            hasAlpha: output.hasAlpha,
          )),
        final other => other,
      };
}
