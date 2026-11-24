import 'dart:async';
import 'dart:collection';

import 'package:exact_size/features/export/data/export_bridge.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';

/// One recorded bridge call (synthetic values only).
typedef BridgeCall = ({String method, String? name, String? ref});

/// In-memory [ExportBridge] for controller and widget tests (FEAT-007-T10).
/// Save and save-as answer from [saves] in order (default: saved under the requested name);
/// set [gate] to hold every save until it completes.
class FakeExportBridge implements ExportBridge {
  final saves = Queue<BridgeSave>();
  final saveAsResults = Queue<BridgeSave>();
  final existing = <String>{};
  final calls = <BridgeCall>[];
  bool viewer = true;
  bool chooser = true;
  Completer<void>? gate;
  var sweeps = 0;
  var _refs = 0;

  int count(String method) => calls.where((c) => c.method == method).length;

  Future<BridgeSave> _answer(Queue<BridgeSave> q, String method, String name) async {
    calls.add((method: method, name: name, ref: null));
    if (gate != null) await gate!.future;
    final r = q.isEmpty ? BridgeSaved(name: name, ref: 'content://fake/${++_refs}') : q.removeFirst();
    if (r is BridgeSaved) existing.add(r.ref);
    return r;
  }

  @override
  Future<BridgeSave> save({required String src, required String name, required String mime, required int bytes}) =>
      _answer(saves, 'save', name);

  @override
  Future<BridgeSave> saveAs({required String src, required String name, required String mime, required int bytes}) =>
      _answer(saveAsResults, 'saveAs', name);

  @override
  Future<bool> itemExists(String ref) async {
    calls.add((method: 'itemExists', name: null, ref: ref));
    return existing.contains(ref);
  }

  @override
  Future<bool> open(String ref, String mime) async {
    calls.add((method: 'open', name: null, ref: ref));
    return viewer;
  }

  @override
  Future<bool> share(String path, String mime) async {
    calls.add((method: 'share', name: null, ref: path));
    return chooser;
  }

  @override
  Future<void> sweepIncomplete() async => sweeps++;

  /// Shorthand for a queued error answer.
  void failNext(ExportOutcome o) => saves.add(BridgeSaveError(o));
}
