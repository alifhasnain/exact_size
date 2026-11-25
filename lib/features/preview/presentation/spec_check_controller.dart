import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../compression/domain/compression_result.dart' show CompressionSuccess, OutputFormat;
import '../../compression/presentation/compression_providers.dart';
import '../../crop/data/preview_decoder.dart';
import '../../crop/data/source_handle.dart';
import '../../crop/domain/crop_types.dart';
import '../../target/domain/target_spec.dart';
import '../data/spec_check_log.dart';
import '../domain/measured_output.dart';
import '../domain/spec_check.dart';
import 'preview_providers.dart';

/// Check screen state (tech 4.3). Memory only.
sealed class SpecCheckState {
  const SpecCheckState();
}

/// No success yet: the screen shows FEAT-007's running or failure branch.
final class CheckIdle extends SpecCheckState {
  const CheckIdle();
}

final class Checking extends SpecCheckState {
  const Checking();
}

/// All three fields meet. [preview] null means "Preview isn't available" (FR-14).
final class CheckMeets extends SpecCheckState {
  const CheckMeets(this.success, this.measured, this.check, this.preview);
  final CompressionSuccess success;
  final MeasuredOutput measured;
  final SpecCheck check;
  final ui.Image? preview;
}

/// A field does not match (FR-10); the file has been deleted.
final class CheckMismatch extends SpecCheckState {
  const CheckMismatch(this.measured, this.check);
  final MeasuredOutput measured;
  final SpecCheck check;
}

/// The file is gone, damaged or not what FEAT-004 reported (FR-11).
final class CheckUnreadable extends SpecCheckState {
  const CheckUnreadable(this.success);
  final CompressionSuccess success;
}

final specCheckControllerProvider =
    NotifierProvider.autoDispose.family<SpecCheckController, SpecCheckState, TargetSpec>(SpecCheckController.new);

/// Measures the FEAT-004 output, checks it against [spec] and decodes the preview (tech 4.3).
/// Owns the preview image: disposed on every transition and on dispose (FR-19).
class SpecCheckController extends Notifier<SpecCheckState> {
  SpecCheckController(this.spec);

  /// The spec captured when the run started (FR-3).
  final TargetSpec spec;

  var _started = false;
  var _rechecking = false;
  ui.Image? _image; // the preview held by the current state

  @override
  SpecCheckState build() {
    ref.onDispose(() => _image?.dispose());
    final lifecycle = AppLifecycleListener(onResume: _onResume); // FR-12
    ref.onDispose(lifecycle.dispose);
    // Once started, later run states are ignored: the Idle after cancel() or leave() resets nothing.
    ref.listen(compressionControllerProvider, (_, next) => _onRun(next));
    final now = ref.read(compressionControllerProvider);
    Future.microtask(() => _onRun(now)); // state cannot change inside build
    return const CheckIdle();
  }

  void _onRun(CompressionRunState run) {
    if (_started || !ref.mounted) return;
    if (run case CompressionDone(result: final CompressionSuccess s)) {
      _started = true;
      _set(const Checking());
      _check(s);
    }
  }

  /// FR-12: back from the background while the result is shown, measure once more. A file that
  /// still matches is equal by construction (bytes == sizeBytes), so nothing is redrawn.
  Future<void> _onResume() async {
    final s = state;
    if (s is! CheckMeets || _rechecking) return;
    _rechecking = true;
    try {
      await _measure(s.success);
    } finally {
      _rechecking = false;
    }
  }

  /// Steps 2 and 3: the matching measurement, or null after moving to unreadable or mismatch
  /// (or when the controller was disposed meanwhile).
  Future<(MeasuredOutput, SpecCheck)?> _measure(CompressionSuccess s) async {
    final log = ref.read(specCheckLogProvider);
    final r = await ref.read(outputMeasurerProvider).measure(s.tempFilePath, expectedBytes: s.sizeBytes);
    if (!ref.mounted) return null;
    final MeasuredOutput m;
    switch (r) {
      case Measured(:final output):
        m = output;
      case Unreadable():
        log.outcome(SpecOutcome.unreadable);
        _set(CheckUnreadable(s));
        return null;
    }
    final c = checkSpec(m, spec);
    if (!c.meets) {
      log.outcome(SpecOutcome.mismatch, {
        if (!c.pixels) SpecField.dimensions,
        if (!c.size) SpecField.size,
        if (!c.format) SpecField.format,
      });
      _set(CheckMismatch(m, c));
      await ref.read(compressionControllerProvider.notifier).cancel(); // the single deleter (FR-10)
      return null;
    }
    return (m, c);
  }

  Future<void> _check(CompressionSuccess s) async {
    final log = ref.read(specCheckLogProvider);
    final v = await _measure(s);
    if (v == null) return;
    final (m, c) = v;
    final p = await ref.read(resultPreviewDecoderProvider).decode(
          SourceHandle(Uri.file(s.tempFilePath).toString()),
          SourceInfo(
            rawWidth: m.width,
            rawHeight: m.height,
            mime: m.format == OutputFormat.jpeg ? 'image/jpeg' : 'image/png',
            exifOrientation: 1,
            isAnimated: false,
            hasAlpha: m.hasAlpha,
            decodePath: DecodePath.region,
          ),
          maxSide: ref.read(previewMaxSideProvider),
        );
    if (!ref.mounted) {
      if (p is PreviewOk) p.image.dispose(); // late arrival
      return;
    }
    switch (p) {
      case PreviewOk(:final image):
        log.outcome(SpecOutcome.meets);
        _set(CheckMeets(s, m, c, image));
      case PreviewErr(reason: Reason.outOfMemoryHandled):
        log
          ..outcome(SpecOutcome.meets)
          ..outcome(SpecOutcome.previewUnavailable);
        _set(CheckMeets(s, m, c, null));
      case PreviewErr():
        log.outcome(SpecOutcome.unreadable);
        _set(CheckUnreadable(s));
    }
  }

  void _set(SpecCheckState next) {
    final old = _image;
    _image = next is CheckMeets ? next.preview : null;
    state = next;
    if (old != null && !identical(old, _image)) old.dispose();
  }
}
