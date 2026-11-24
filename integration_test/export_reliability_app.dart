import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/export/data/android_export_bridge.dart';
import 'package:exact_size/features/export/domain/export_name.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-007-T22 reliability app (debug build, driven by tool/export_reliability.dart; not shipped).
/// A killed process cannot report through flutter drive, so this app reports to `files/rel_report`
/// (JSON lines) and the host script reads it with `run-as`. The mode comes from `files/rel_mode`:
///   kill      on start: count unfinished saves, sweep, count again, check every visible ExactSize
///             file against the blob hash, delete them, report; then save a ~50 MB synthetic blob
///             (the host kills the process during the copy) and report when it finishes
///   lowspace  one save of the blob; reports the outcome (the host fills the disk first)
///   timing    20 saves of a 1 MB synthetic file; reports the median in ms
/// Synthetic bytes only; nothing is logged.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ColoredBox(color: Color(0xFF5A1622)));
  final files = (await getApplicationSupportDirectory()).path;
  final mode = File('$files/rel_mode').existsSync() ? File('$files/rel_mode').readAsStringSync().trim() : 'kill';
  final report = File('$files/rel_report');
  void say(Map<String, Object?> m) => report.writeAsStringSync('${jsonEncode(m)}\n', mode: FileMode.append, flush: true);
  final bridge = AndroidExportBridge();
  const debug = MethodChannel('exactsize/export');
  final cache = (await getTemporaryDirectory()).path;
  final folder = Directory('/storage/emulated/0/Pictures/ExactSize');

  Future<File> blob(String name, int bytes) async {
    final f = File('$cache/$name');
    if (!f.existsSync() || f.lengthSync() != bytes) {
      final data = Uint8List(bytes);
      final r = Random(7);
      for (var i = 0; i < bytes; i++) {
        data[i] = r.nextInt(256);
      }
      f.writeAsBytesSync(data, flush: true);
    }
    return f;
  }

  Future<BridgeSave> save(File src) =>
      bridge.save(src: src.path, name: ExportName.generate(1, 1, OutputFormat.jpeg, Random.secure()), mime: 'image/jpeg', bytes: src.lengthSync());

  try {
    switch (mode) {
      case 'kill':
        final src = await blob('rel_blob.bin', 50 * 1024 * 1024);
        final hashFile = File('$cache/rel_blob.sha');
        if (!hashFile.existsSync()) hashFile.writeAsStringSync('${sha256.convert(src.readAsBytesSync())}');
        final hash = hashFile.readAsStringSync();
        final before = await debug.invokeMethod<int>('debugCountIncomplete');
        await bridge.sweepIncomplete();
        final after = await debug.invokeMethod<int>('debugCountIncomplete');
        var visible = 0, bad = 0;
        if (folder.existsSync()) {
          for (final f in folder.listSync().whereType<File>()) {
            final n = f.uri.pathSegments.last;
            if (n.startsWith('.')) continue; // .pending-* / .part are what the counts above cover
            visible++;
            if ('${sha256.convert(f.readAsBytesSync())}' != hash) bad++;
            f.deleteSync();
          }
        }
        say({'event': 'start', 'before': before, 'after': after, 'visible': visible, 'badHash': bad});
        final t = Stopwatch()..start();
        say({'event': 'saving'});
        final r = await save(src);
        say({'event': 'saved', 'ok': r is BridgeSaved, 'ms': t.elapsedMilliseconds});
      case 'lowspace':
        final r = await save(await blob('rel_blob.bin', 50 * 1024 * 1024));
        say({'event': 'lowspace', 'result': r is BridgeSaveError ? r.outcome.code : r is BridgeSaved ? 'SAVED' : 'NAME_TAKEN'});
        if (r is BridgeSaved && folder.existsSync()) {
          for (final f in folder.listSync().whereType<File>()) {
            f.deleteSync();
          }
        }
      case 'timing':
        final src = await blob('rel_1mb.bin', 1024 * 1024);
        final times = <int>[];
        for (var i = 0; i < 20; i++) {
          final t = Stopwatch()..start();
          final r = await save(src);
          times.add(t.elapsedMilliseconds);
          if (r is! BridgeSaved) say({'event': 'timingFailed', 'i': i});
        }
        times.sort();
        if (folder.existsSync()) {
          for (final f in folder.listSync().whereType<File>()) {
            f.deleteSync();
          }
        }
        say({'event': 'timing', 'medianMs': times[10], 'minMs': times.first, 'maxMs': times.last});
    }
  } on Object catch (e) {
    say({'event': 'error', 'type': e.runtimeType.toString()});
  }
}
