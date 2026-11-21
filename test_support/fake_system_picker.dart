import 'dart:async';

import 'package:exact_size/features/pick/data/system_picker.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';

/// In-memory [SystemPicker] for controller and widget tests (FEAT-001-T12).
class FakeSystemPicker implements SystemPicker {
  bool camera = true;
  LaunchOutcome nextLaunch = LaunchOutcome.launched;
  String? pendingName;
  SystemPickResult? slot;
  final launches = <PickSource>[];
  final _ready = StreamController<void>.broadcast();

  /// Puts [r] in the slot and signals it, like the bridge after onActivityResult.
  void deliver(SystemPickResult r) {
    slot = r;
    signal();
  }

  /// Signals resultReady without changing the slot.
  void signal() => _ready.add(null);

  @override
  Stream<void> get resultReady => _ready.stream;

  @override
  Future<bool> cameraAvailable() async => camera;

  @override
  Future<LaunchOutcome> launch(PickSource source) async {
    launches.add(source);
    return nextLaunch;
  }

  @override
  Future<SystemPickResult?> takeResult() async {
    final r = slot;
    slot = null;
    return r;
  }

  @override
  Future<String?> pendingCaptureName() async => pendingName;
}
