import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart' show Target;
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:exact_size/features/export/presentation/result_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../test_support/fake_export_bridge.dart';

/// FEAT-007-T20 gate G2 review (manual, not in CI): the result screen in each state, for one phone
/// screenshot each. Build with `-t integration_test/result_screen_demo.dart`; pick the state by
/// writing its name to `files/demo_state` with `adb shell run-as`, then restart the activity.
/// States: ready, saved, error, permission (forced permission-denied layout), arabic (saved, ar),
/// font200 (saved at 200%). A fake bridge answers, so nothing is written to the gallery; the
/// "file" is synthetic bytes in the app cache.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final f = File('${support.path}/demo_state');
  final name = f.existsSync() ? f.readAsStringSync().trim() : 'ready';
  final cache = await getTemporaryDirectory();
  final temp = File('${cache.path}/demo_result.jpg')..writeAsBytesSync(List.filled(48200, 1));
  final success = CompressionSuccess(tempFilePath: temp.path, sizeBytes: 48200, format: OutputFormat.jpeg);
  final bridge = FakeExportBridge();
  switch (name) {
    case 'error':
      bridge.failNext(ExportOutcome.saveFailed);
    case 'permission':
      bridge.failNext(ExportOutcome.permissionDenied);
    case 'saved' || 'arabic' || 'font200':
      bridge.saves.add(const BridgeSaved(name: 'exactsize-300x300-a1b2c3.jpg', ref: 'content://demo/1'));
  }
  runApp(ProviderScope(
    overrides: [
      compressionControllerProvider.overrideWith(() => _Done(success)),
      exportBridgeProvider.overrideWithValue(bridge),
      shareCopiesProvider.overrideWithValue(ShareCopies(TempFiles(cache, folder: 'demo_share'))),
      exportLogProvider.overrideWithValue(ExportOutcomeLog((_) {})),
    ],
    child: ExactSizeApp(
      locale: name == 'arabic' ? const Locale('ar') : const Locale('en'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(name == 'font200' ? 2 : 1)),
          child: _AutoSave(input: ExportInput(success, const Target(300, 300)), save: name != 'ready'),
        ),
      ),
    ),
  ));
}

class _Done extends CompressionController {
  _Done(this.result);
  final CompressionSuccess result;
  @override
  CompressionRunState build() => CompressionDone(result, maxKb: 50);
  @override
  Future<void> cancel() async {}
}

/// Shows the result screen and, for the message states, taps Save once after the first frame.
class _AutoSave extends ConsumerStatefulWidget {
  const _AutoSave({required this.input, required this.save});
  final ExportInput input;
  final bool save;

  @override
  ConsumerState<_AutoSave> createState() => _AutoSaveState();
}

class _AutoSaveState extends ConsumerState<_AutoSave> {
  @override
  void initState() {
    super.initState();
    if (widget.save) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(exportControllerProvider(widget.input).notifier).save());
    }
  }

  @override
  Widget build(BuildContext context) => ResultScreen(size: widget.input.size, onStartOver: () {});
}
