import 'dart:io';
import 'dart:ui' as ui;

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart' hide Reason;
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart' show Reason, Target;
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:exact_size/features/export/presentation/result_screen.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../test_support/fake_check_overrides.dart';
import '../test_support/fake_export_bridge.dart';

/// Gate G2 reviews (manual, not in CI): the result screen in each state, for one phone screenshot
/// each. Build with `-t integration_test/result_screen_demo.dart`; pick the state by writing its
/// name to `files/demo_state` with `adb shell run-as`, then restart the activity.
/// FEAT-006 states: matches_padding, matches_png, preview_unavailable, mismatch, unreadable,
/// arabic (matches, ar), font200 (matches at 200%). FEAT-007 states: ready, saved, error,
/// permission. A fake bridge answers, so nothing is written to the gallery; the "file" is
/// synthetic bytes in the app cache, the fake measurer reports it and the preview is a painted
/// synthetic picture (no face, no signature).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final f = File('${support.path}/demo_state');
  final name = f.existsSync() ? f.readAsStringSync().trim() : 'matches_padding';
  final png = name == 'matches_png';
  final format = png ? OutputFormat.png : OutputFormat.jpeg;
  final cache = await getTemporaryDirectory();
  final temp = File('${cache.path}/demo_result.${png ? 'png' : 'jpg'}')..writeAsBytesSync(List.filled(48200, 1));
  final success = CompressionSuccess(
    tempFilePath: temp.path,
    sizeBytes: 48200,
    format: format,
    notices: name == 'matches_padding' || name == 'arabic' ? const {Notice.paddingAdded} : const {},
  );
  final spec = TargetSpec(width: 300, height: 300, minKb: 20, maxKb: 50, format: format);
  final measured = MeasuredOutput(bytes: name == 'mismatch' ? 50001 : 48200, width: 300, height: 300, format: format, hasAlpha: png);
  final image = await _picture(600, 600, alpha: png);
  final bridge = FakeExportBridge();
  switch (name) {
    case 'error':
      bridge.failNext(ExportOutcome.saveFailed);
    case 'permission':
      bridge.failNext(ExportOutcome.permissionDenied);
    case 'saved':
      bridge.saves.add(const BridgeSaved(name: 'exactsize-300x300-a1b2c3.jpg', ref: 'content://demo/1'));
  }
  runApp(ProviderScope(
    overrides: [
      ...fakeCheckOverrides(
        result: name == 'unreadable' ? const Unreadable() : Measured(measured),
        preview: name == 'preview_unavailable' ? const PreviewErr(Reason.outOfMemoryHandled) : PreviewOk(image, 1),
      ),
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
          child: _AutoSave(
            spec: spec,
            input: ExportInput(success, const Target(300, 300)),
            save: const {'saved', 'error', 'permission'}.contains(name),
          ),
        ),
      ),
    ),
  ));
}

/// Opaque bands with a disc, or the disc alone on transparency.
Future<ui.Image> _picture(int w, int h, {required bool alpha}) {
  final r = ui.PictureRecorder();
  final c = Canvas(r);
  if (!alpha) {
    c.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = const Color(0xFF2F6F8F));
    c.drawRect(Rect.fromLTWH(0, h * 0.6, w.toDouble(), h * 0.4), Paint()..color = const Color(0xFFE0C9A6));
  }
  c.drawCircle(Offset(w / 2, h / 2), w * 0.3, Paint()..color = const Color(0xFF7A9E3B));
  return r.endRecording().toImage(w, h);
}

class _Done extends CompressionController {
  _Done(this.result);
  final CompressionSuccess result;
  @override
  CompressionRunState build() => CompressionDone(result, maxKb: 50);
  @override
  Future<void> cancel() async {}
}

/// Shows the result screen and, for the message states, taps Save once after the check.
class _AutoSave extends ConsumerStatefulWidget {
  const _AutoSave({required this.spec, required this.input, required this.save});
  final TargetSpec spec;
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
      Future<void>.delayed(const Duration(milliseconds: 500), () => ref.read(exportControllerProvider(widget.input).notifier).save());
    }
  }

  @override
  Widget build(BuildContext context) => ResultScreen(spec: widget.spec, onStartOver: () {});
}
