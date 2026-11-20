import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/injection.dart';
import '../data/compression_runner.dart';
import '../data/compression_service.dart';
import '../data/temp_files.dart';
import '../domain/compression_request.dart';
import '../domain/compression_result.dart';
import '../domain/size_search.dart' as search;
import 'outcome_messages.dart';

/// State of one compression run, exposed to FEAT-006 (FR-17, FR-19).
sealed class CompressionRunState {
  const CompressionRunState();
}

final class CompressionIdle extends CompressionRunState {
  const CompressionIdle();
}

final class CompressionRunning extends CompressionRunState {
  const CompressionRunning({required this.pass, required this.maxPasses, required this.maxKb, this.minKb});

  /// 0 until the first encode pass starts.
  final int pass;
  final int maxPasses;
  final int? minKb;
  final int maxKb;
}

/// Finished: success (with the temp file) or failure. [minKb]/[maxKb] are the
/// target, needed for the failure message (FR-11).
final class CompressionDone extends CompressionRunState {
  const CompressionDone(this.result, {required this.maxKb, this.minKb});
  final CompressionResult result;
  final int? minKb;
  final int maxKb;
}

/// The FEAT-004 service from the get_it container (ADR-001 v1.1).
final compressionServiceProvider = Provider<CompressionService>((ref) => getIt<CompressionService>());

final compressionControllerProvider =
    NotifierProvider<CompressionController, CompressionRunState>(CompressionController.new);

/// Starts, tracks and cancels one compression at a time.
///
/// A request can be started once: its pixels move to the service (ADR-003),
/// so starting the same request again, for example when a screen is rebuilt
/// after rotation, is ignored. So is a start while a run is going.
class CompressionController extends Notifier<CompressionRunState> {
  CancelSignal? _cancel;
  CompressionRequest? _started;

  @override
  CompressionRunState build() => const CompressionIdle();

  Future<void> start(CompressionRequest request) async {
    if (state is CompressionRunning || identical(request, _started)) return;
    await _discardResult(); // a new run replaces an unexported result
    _started = request;
    final cancel = _cancel = CancelSignal();
    state = CompressionRunning(pass: 0, maxPasses: search.maxPasses, minKb: request.minKb, maxKb: request.maxKb);
    final CompressionResult result;
    try {
      result = await ref.read(compressionServiceProvider).compress(
            request,
            cancel: cancel,
            onProgress: (pass, max) {
              if (ref.mounted && identical(_cancel, cancel)) {
                state = CompressionRunning(pass: pass, maxPasses: max, minKb: request.minKb, maxKb: request.maxKb);
              }
            },
          );
    } finally {
      _cancel = null;
      cancel.dispose();
    }
    if (!ref.mounted) {
      if (result is CompressionSuccess) await getIt<TempFiles>().delete(result.tempFilePath);
      return;
    }
    state = CompressionDone(result, minKb: request.minKb, maxKb: request.maxKb);
  }

  /// Cancels the run (FR-17), or drops a finished result that was not
  /// exported, deleting its temp file (FR-20).
  Future<void> cancel() async {
    final running = _cancel;
    if (running != null) {
      running.cancel(); // the service returns CANCELLED and leaves no file
      return;
    }
    await _discardResult();
    state = const CompressionIdle();
  }

  Future<void> _discardResult() async {
    final s = state;
    if (s is CompressionDone && s.result is CompressionSuccess) {
      await getIt<TempFiles>().delete((s.result as CompressionSuccess).tempFilePath);
    }
  }
}

/// One announcement per state for `SemanticsService.announce` or a live
/// region (NFR-5); null when idle. Failures use the same text as the screen.
String? announcementFor(CompressionRunState state, OutcomeMessages messages) => switch (state) {
      CompressionIdle() => null,
      // Before the first pass reports, announce step 1: the run has started.
      CompressionRunning(:final pass, :final maxPasses) => messages.progress(pass == 0 ? 1 : pass, maxPasses),
      CompressionDone(result: final CompressionSuccess s) => messages.success(s),
      CompressionDone(result: final CompressionFailure f, :final minKb, :final maxKb) =>
        messages.failure(f, minKb: minKb, maxKb: maxKb).message,
    };
