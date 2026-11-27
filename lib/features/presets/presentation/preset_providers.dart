import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preset_asset_source.dart';
import '../domain/preset_types.dart';

/// The loader; tests override it with a fake bundle or sink.
final presetSourceProvider = Provider<PresetAssetSource>((ref) => const PresetAssetSource());

/// Loaded once per app run and kept (FEAT-011 FR-12); a load error is an AsyncError (FR-16).
/// No retry: a broken bundled file stays broken, and a retry would repeat the log line.
final presetLibraryProvider = FutureProvider<PresetLibrary>(
  (ref) => ref.watch(presetSourceProvider).loadPresets(),
  retry: (_, _) => null,
);

/// The preset picked this session (FR-12). Memory only: no persistence and no
/// restoration, like `targetFormProvider` (FR-17, AC-8.1).
final appliedPresetProvider = NotifierProvider<AppliedPresetController, AppliedPreset?>(AppliedPresetController.new);

class AppliedPresetController extends Notifier<AppliedPreset?> {
  @override
  AppliedPreset? build() => null;

  void apply(AppliedPreset preset) => state = preset;

  void clear() => state = null;
}
