import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/pick/presentation/pick_controller.dart';
import 'package:exact_size/features/pick/presentation/pick_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-001-T16 design review (manual, not in CI): the pick screen in each
/// state. Build with `-t integration_test/pick_screen_demo.dart`; pick the state
/// by writing its name to `files/demo_state` with `adb shell run-as`, then
/// restart the activity. States: idle, nocamera, message, opening, arabic, font200.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final f = File('${(await getApplicationSupportDirectory()).path}/demo_state');
  final name = f.existsSync() ? f.readAsStringSync().trim() : 'idle';
  final state = switch (name) {
    'nocamera' => const PickState(),
    'message' || 'arabic' => const PickState(
      cameraAvailable: true,
      message: PickMessage.sourceUnavailable,
    ),
    'opening' => const PickState(
      cameraAvailable: true,
      phase: PickPhase.opening,
      showProgress: true,
    ),
    'font200' => const PickState(
      cameraAvailable: true,
      message: PickMessage.lowSpace,
    ),
    _ => const PickState(cameraAvailable: true),
  };
  runApp(
    ExactSizeApp(
      locale: name == 'arabic' ? const Locale('ar') : const Locale('en'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(name == 'font200' ? 2 : 1)),
          child: PickView(state: state, onLaunch: (_) {}, onCancel: () {}),
        ),
      ),
    ),
  );
}
