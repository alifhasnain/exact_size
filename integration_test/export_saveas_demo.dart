import 'package:exact_size/app.dart';
import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/export/data/export_bridge.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-007-T23 demo build (manual, not in CI, not shipped): the real app with the real bridge,
/// except that the first Save answers PERMISSION_DENIED, so "Choose where to save" (FR-10) shows on
/// an API 36 phone, where the API 28 refusal cannot happen. Save as, Share and Open are the real
/// system flows. Build with `-t integration_test/export_saveas_demo.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(ProviderScope(
    overrides: [exportBridgeProvider.overrideWithValue(_DeniedOnce(getIt<ExportBridge>()))],
    child: const ExactSizeApp(),
  ));
}

class _DeniedOnce implements ExportBridge {
  _DeniedOnce(this._real);
  final ExportBridge _real;
  var _denied = false;

  @override
  Future<BridgeSave> save({required String src, required String name, required String mime, required int bytes}) async {
    if (!_denied) {
      _denied = true;
      return const BridgeSaveError(ExportOutcome.permissionDenied);
    }
    return _real.save(src: src, name: name, mime: mime, bytes: bytes);
  }

  @override
  Future<BridgeSave> saveAs({required String src, required String name, required String mime, required int bytes}) =>
      _real.saveAs(src: src, name: name, mime: mime, bytes: bytes);

  @override
  Future<bool> itemExists(String ref) => _real.itemExists(ref);

  @override
  Future<bool> open(String ref, String mime) => _real.open(ref, mime);

  @override
  Future<bool> share(String path, String mime) => _real.share(path, mime);

  @override
  Future<void> sweepIncomplete() => _real.sweepIncomplete();
}
