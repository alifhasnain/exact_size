import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/injection.dart';
import '../../compression/data/temp_files.dart';
import '../../crop/data/source_handle.dart';
import '../../crop/data/source_probe.dart';
import '../data/pick_outcome_log.dart';
import '../data/system_picker.dart';
import '../domain/pick_rules.dart';
import '../domain/pick_types.dart';

enum PickPhase { idle, awaitingSystemUi, opening }

/// Pick screen state (tech.md section 4). In memory only; nothing is restored (FR-16).
final class PickState {
  const PickState({
    this.phase = PickPhase.idle,
    this.showProgress = false,
    this.cameraAvailable = false,
    this.message,
    this.lastSource,
    this.current,
  });

  final PickPhase phase;

  /// Opening has taken over 500 ms (FR-13, T14).
  final bool showProgress;
  final bool cameraAvailable;

  /// Last refusal; cleared on the next launch.
  final PickMessage? message;

  /// For focus restore (AC-7.1).
  final PickSource? lastSource;

  /// The session image (FR-10); the flow listens to changes.
  final PickedImage? current;

  PickState copyWith({PickPhase? phase, bool? showProgress, bool? cameraAvailable, PickMessage? message, bool clearMessage = false, PickSource? lastSource}) =>
      PickState(
        phase: phase ?? this.phase,
        showProgress: showProgress ?? this.showProgress,
        cameraAvailable: cameraAvailable ?? this.cameraAvailable,
        message: clearMessage ? null : (message ?? this.message),
        lastSource: lastSource ?? this.lastSource,
        current: current,
      );
}

final pickControllerProvider = NotifierProvider<PickController, PickState>(PickController.new);

/// Launches the system picker or camera, opens the result once, keeps one image
/// (FR-1–FR-11, FR-15, tech.md section 4 steps 1–7).
class PickController extends Notifier<PickState> {
  late final SystemPicker _picker = getIt<SystemPicker>();
  late final TempFiles _cameraFiles = getIt<TempFiles>(instanceName: 'camera');
  late final SourceProbe _probe = getIt<SourceProbe>();
  late final PickOutcomeLog _log = getIt<PickOutcomeLog>();

  /// Bumped by every new result and by release(); a probe answer for an older
  /// generation is discarded.
  int _generation = 0;

  /// Camera file of [PickState.current], deleted only when a new image is accepted (FR-10).
  String? _currentFile;

  /// One in-flight result at a time.
  Future<void> _queue = Future.value();

  /// Camera file of the attempt being opened, for Cancel (FR-13).
  String? _attemptFile;

  /// Progress appears only if opening takes longer than this (FR-13, NFR-1).
  static const progressDelay = Duration(milliseconds: 500);

  @override
  PickState build() {
    final ready = _picker.resultReady.listen((_) => _drain());
    final lifecycle = AppLifecycleListener(onResume: _refreshCamera);
    ref.onDispose(() {
      _generation++; // late probe answers and progress timers are dropped
      ready.cancel();
      lifecycle.dispose();
    });
    unawaited(_refreshCamera());
    _drain(); // a result that arrived before Dart ran (FR-15)
    return const PickState();
  }

  /// Ignored unless idle (AC-5.4).
  Future<void> launch(PickSource source) async {
    if (state.phase != PickPhase.idle) return;
    state = state.copyWith(phase: PickPhase.awaitingSystemUi, lastSource: source, clearMessage: true);
    LaunchOutcome outcome;
    try {
      outcome = await _picker.launch(source);
    } on PlatformException {
      outcome = LaunchOutcome.unavailable;
    }
    if (!ref.mounted) return;
    switch (outcome) {
      case LaunchOutcome.launched:
      case LaunchOutcome.busy: // a launch is still outstanding; its result will arrive
        break;
      case LaunchOutcome.unavailable when source == PickSource.camera:
        state = state.copyWith(phase: PickPhase.idle, cameraAvailable: false);
      case LaunchOutcome.unavailable:
        _refuse(PickMessage.pickerUnavailable);
      case LaunchOutcome.lowSpace:
        _refuse(PickMessage.lowSpace);
    }
  }

  /// Cancel while opening (FR-13): the attempt is dropped, its camera file deleted,
  /// no message; a late probe answer is discarded by the generation check.
  Future<void> cancelOpening() async {
    if (state.phase != PickPhase.opening) return;
    _generation++;
    final file = _attemptFile;
    _attemptFile = null;
    state = state.copyWith(phase: PickPhase.idle, showProgress: false);
    await _delete(file);
  }

  /// Ends the session: no image, empty camera folder (FR-11; called at start-over and flow end).
  Future<void> release() async {
    _generation++;
    _currentFile = null;
    state = PickState(cameraAvailable: state.cameraAvailable);
    await _cameraFiles.sweep();
  }

  Future<void> _refreshCamera() async {
    bool available;
    try {
      available = await _picker.cameraAvailable();
    } on PlatformException {
      available = false;
    }
    if (ref.mounted) state = state.copyWith(cameraAvailable: available);
  }

  void _drain() => _queue = _queue.then((_) => _takeAndHandle());

  Future<void> _takeAndHandle() async {
    SystemPickResult? result;
    try {
      result = await _picker.takeResult();
    } on PlatformException {
      return;
    }
    if (result == null || !ref.mounted) return;
    try {
      await _handle(result);
    } on Object {
      // Never rethrown or printed: dart:io errors carry paths (NFR-6). The queue stays usable.
      _generation++; // a pending progress timer must not fire
      final file = _attemptFile;
      _attemptFile = null;
      await _delete(file);
      if (ref.mounted) _refuse(PickMessage.itemNotOpenable);
    }
  }

  Future<void> _handle(SystemPickResult result) async {
    final generation = ++_generation;
    switch (result) {
      case Cancelled(:final fileName):
        await _delete(fileName);
        state = state.copyWith(phase: PickPhase.idle);
        _log.cancelled();
      case CaptureLost(:final fileName):
        await _delete(fileName);
        _refuse(PickMessage.captureLost);
      case NotOpenable():
        _refuse(PickMessage.itemNotOpenable);
      case Picked():
        if (!PickRules.acceptable(result)) return _refuse(PickMessage.itemNotOpenable);
        await _open(generation, result.uri, result.origin, null);
      case Captured(:final uri, :final fileName):
        // One stat call: no gap between an exists check and a length read.
        final stat = await _cameraFile(fileName).stat();
        if (!PickRules.captureUsable(exists: stat.type != FileSystemEntityType.notFound, length: stat.size)) {
          await _delete(fileName);
          return _refuse(PickMessage.cameraNoPhoto);
        }
        await _open(generation, uri, PickOrigin.camera, fileName);
    }
  }

  Future<void> _open(int generation, String uri, PickOrigin origin, String? cameraFile) async {
    state = state.copyWith(phase: PickPhase.opening, showProgress: false);
    _attemptFile = cameraFile;
    final timer = Timer(progressDelay, () {
      if (generation == _generation) state = state.copyWith(showProgress: true);
    });
    final probe = await _probe.probe(SourceHandle(uri));
    timer.cancel();
    if (generation != _generation) return _delete(cameraFile); // cancelled, superseded or released
    _attemptFile = null;
    switch (probe) {
      case ProbeErr(:final reason):
        await _delete(cameraFile); // AC-3.2; current and its file stay (AC-3.3)
        _refuse(PickRules.message(reason));
      case ProbeOk(:final info):
        final previous = _currentFile;
        _currentFile = cameraFile;
        state = PickState(
          cameraAvailable: state.cameraAvailable,
          lastSource: state.lastSource,
          current: PickedImage(handle: SourceHandle(uri), info: info, origin: origin, cameraFile: cameraFile),
        );
        for (final name in PickRules.filesToDelete(accepted: true, attemptFile: cameraFile, previousFile: previous)) {
          await _delete(name);
        }
        _log.accepted();
    }
  }

  void _refuse(PickMessage message) {
    state = state.copyWith(phase: PickPhase.idle, showProgress: false, message: message);
    _log.refused(message);
  }

  File _cameraFile(String name) => File('${_cameraFiles.dir.path}${Platform.pathSeparator}$name');

  Future<void> _delete(String? name) async {
    if (name != null) await _cameraFiles.delete(_cameraFile(name).path);
  }
}
