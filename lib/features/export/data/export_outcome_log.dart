import 'package:flutter/foundation.dart' show debugPrint;

import '../domain/export_outcome.dart';

/// Where log lines go; replaceable in tests.
typedef ExportLogSink = void Function(String line);

void _debugPrintSink(String line) => debugPrint(line);

/// Export outcome logging (FR-27). The only input is an [ExportOutcome], so a line can hold no
/// file name, URI, path, size or exception text.
class ExportOutcomeLog {
  const ExportOutcomeLog([this._sink = _debugPrintSink]);

  final ExportLogSink _sink;

  void outcome(ExportOutcome o) => _sink('exactsize.export outcome=${o.code}');
}
