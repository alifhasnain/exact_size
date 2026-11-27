import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../compression/data/outcome_log.dart' show LogSink;
import '../domain/parse_library.dart';
import '../domain/preset_types.dart';

void _debugPrintSink(String line) => debugPrint(line);

/// Reads the bundled preset library (FEAT-011 FR-1, FR-18: no network).
/// Logs enum lines only (FR-16, FR-17): no form id, count or error text.
class PresetAssetSource {
  const PresetAssetSource({this._bundle, this._sink = _debugPrintSink});

  static const path = 'assets/presets/presets.json';

  final AssetBundle? _bundle;
  final LogSink _sink;

  Future<PresetLibrary> loadPresets() async {
    final PresetLibrary library;
    try {
      library = parseLibrary(jsonDecode(await (_bundle ?? rootBundle).loadString(path, cache: false)));
    } catch (_) {
      _sink('exactsize.presets outcome=LOAD_FAILED');
      rethrow;
    }
    if (library.skipped > 0) _sink('exactsize.presets outcome=SPEC_SKIPPED');
    return library;
  }
}
