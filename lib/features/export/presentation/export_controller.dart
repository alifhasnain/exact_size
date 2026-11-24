import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/injection.dart';
import '../../compression/presentation/compression_providers.dart';
import '../data/export_bridge.dart';
import '../data/export_outcome_log.dart';
import '../data/share_copies.dart';
import '../domain/export_name.dart';
import '../domain/export_outcome.dart';
import '../domain/export_types.dart';

/// Services from the get_it container (ADR-001); tests override these providers.
final exportBridgeProvider = Provider<ExportBridge>((ref) => getIt<ExportBridge>());
final shareCopiesProvider = Provider<ShareCopies>((ref) => getIt<ShareCopies>());
final exportLogProvider = Provider<ExportOutcomeLog>((ref) => getIt<ExportOutcomeLog>());

/// Export screen state (tech.md section 4.2). Memory only, disposed with the screen (FR-25).
final class ExportState {
  const ExportState({this.busy = false, this.showProgress = false, this.saved, this.sharedOnce = false, this.message});

  /// A save or save-as is writing; more taps are ignored (FR-12, AC-5.1).
  final bool busy;

  /// Busy for 500 ms or more (FR-24, NFR-1).
  final bool showProgress;

  /// The last verified save of this result.
  final SavedItem? saved;

  /// Only for the leave check (FR-23); never displayed (FR-19).
  final bool sharedOnce;

  /// The last message; replaced by the next action.
  final ExportOutcome? message;

  ExportState _with({bool? busy, bool? showProgress, SavedItem? saved, bool? sharedOnce, ExportOutcome? message, bool keepMessage = true}) =>
      ExportState(
        busy: busy ?? this.busy,
        showProgress: showProgress ?? this.showProgress,
        saved: saved ?? this.saved,
        sharedOnce: sharedOnce ?? this.sharedOnce,
        message: message ?? (keepMessage ? this.message : null),
      );

  @override
  String toString() => 'ExportState(busy: $busy, saved: ${saved != null}, sharedOnce: $sharedOnce, message: ${message?.code})';
}

/// One export screen per FEAT-004 result: Save, Save as, Share, Open, leave (FEAT-007).
final exportControllerProvider =
    NotifierProvider.autoDispose.family<ExportController, ExportState, ExportInput>(ExportController.new);

class ExportController extends Notifier<ExportState> {
  ExportController(this.input);

  final ExportInput input;

  static const progressDelay = Duration(milliseconds: 500);
  static const maxNameTries = 5;

  final _secure = Random.secure();
  Future<void>? _writing;
  Timer? _progress;
  String? _shareCopy;

  ExportBridge get _bridge => ref.read(exportBridgeProvider);
  String get _mime => ExportName.mime(input.success.format);
  String _name() => ExportName.generate(input.size.width, input.size.height, input.success.format, _secure);

  @override
  ExportState build() {
    ref.onDispose(() => _progress?.cancel());
    return const ExportState();
  }

  /// FR-2: the result file is still there with the right length.
  bool _fileOk() {
    final f = File(input.success.tempFilePath);
    return f.existsSync() && f.lengthSync() == input.success.sizeBytes;
  }

  void _finish(ExportOutcome o, {SavedItem? saved, bool show = true}) {
    ref.read(exportLogProvider).outcome(o);
    if (!ref.mounted) return;
    state = ExportState(
      saved: saved ?? state.saved,
      sharedOnce: state.sharedOnce,
      message: show ? o : null,
    );
  }

  /// Runs one write with the busy flag and the 500 ms progress timer; a second tap is ignored.
  Future<void> _write(Future<void> Function() body) {
    if (state.busy) return _writing ?? Future.value();
    state = state._with(busy: true, keepMessage: false);
    _progress = Timer(progressDelay, () {
      if (ref.mounted && state.busy) state = state._with(showProgress: true);
    });
    return _writing = body().whenComplete(() {
      _progress?.cancel();
      _writing = null;
      if (ref.mounted && state.busy) state = state._with(busy: false, showProgress: false);
    });
  }

  /// Save to shared storage (FR-6, FR-7, FR-9, FR-11 to FR-14). The temp file is always kept.
  Future<void> save() => _write(() async {
        final saved = state.saved;
        if (saved != null && await _bridge.itemExists(saved.ref)) return _finish(ExportOutcome.alreadySaved);
        if (!_fileOk()) return _finish(ExportOutcome.fileMissing);
        for (var i = 0; i < maxNameTries; i++) {
          final r = await _bridge.save(src: input.success.tempFilePath, name: _name(), mime: _mime, bytes: input.success.sizeBytes);
          switch (r) {
            case BridgeSaved(:final name, :final ref):
              return _finish(ExportOutcome.saved, saved: SavedItem(ref: ref, displayName: name));
            case BridgeNameTaken():
              continue;
            case BridgeSaveError(:final outcome):
              return _finish(outcome == ExportOutcome.saveCancelled ? ExportOutcome.saveFailed : outcome);
          }
        }
        _finish(ExportOutcome.saveFailed);
      });

  /// "Choose where to save" (FR-10, Should): the system dialog; closing it shows nothing.
  Future<void> saveAs() => _write(() async {
        if (!_fileOk()) return _finish(ExportOutcome.fileMissing);
        final r = await _bridge.saveAs(src: input.success.tempFilePath, name: _name(), mime: _mime, bytes: input.success.sizeBytes);
        switch (r) {
          case BridgeSaved(:final name, :final ref):
            _finish(ExportOutcome.saved, saved: SavedItem(ref: ref, displayName: name, viaSaveAs: true));
          case BridgeSaveError(outcome: ExportOutcome.saveCancelled):
            _finish(ExportOutcome.saveCancelled, show: false);
          case BridgeSaveError(:final outcome):
            _finish(outcome);
          case BridgeNameTaken():
            _finish(ExportOutcome.saveFailed);
        }
      });

  /// Share through the system chooser (FR-17 to FR-20). One copy under the FR-4 name, reused.
  Future<void> share() async {
    if (state.busy) return;
    if (!_fileOk()) return _finish(ExportOutcome.fileMissing);
    final copies = ref.read(shareCopiesProvider);
    final copy = _shareCopy ??= await copies.copy(input.success.tempFilePath, _name(), input.success.sizeBytes);
    if (copy == null || !await _bridge.share(copy, _mime)) return _finish(ExportOutcome.shareFailed);
    ref.read(exportLogProvider).outcome(ExportOutcome.shareOpened);
    if (ref.mounted) state = ExportState(saved: state.saved, sharedOnce: true); // a share shows no message (FR-19)
  }

  /// Opens the saved item in a viewer (FR-15, Should).
  Future<void> open() async {
    final saved = state.saved;
    if (saved == null) return;
    if (await _bridge.open(saved.ref, _mime)) {
      if (ref.mounted) state = state._with(keepMessage: false);
    } else {
      _finish(ExportOutcome.openNoViewer);
    }
  }

  /// FR-23: leaving would lose the result.
  bool get needsLeaveConfirm => state.saved == null && !state.sharedOnce;

  /// FR-22, FR-24: waits for a running write, deletes the share copy, then drops the result and
  /// its temp file through FEAT-004. The caller then navigates.
  Future<void> leave() async {
    await _writing;
    final copy = _shareCopy;
    _shareCopy = null;
    if (copy != null) await ref.read(shareCopiesProvider).delete(copy);
    await ref.read(compressionControllerProvider.notifier).cancel();
  }
}
