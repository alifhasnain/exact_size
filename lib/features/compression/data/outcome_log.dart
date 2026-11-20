import 'package:flutter/foundation.dart' show debugPrint;

import '../domain/compression_result.dart';

/// Where log lines go; replaceable in tests.
typedef LogSink = void Function(String line);

void _debugPrintSink(String line) => debugPrint(line);

/// Outcome logging (NFR-7, PRD section 10). Every input is an enum, so a line
/// can only hold enum names: no paths, file names, sizes or pixel data.
class OutcomeLog {
  const OutcomeLog([this._sink = _debugPrintSink]);

  final LogSink _sink;

  void success(OutputFormat format, Set<Notice> notices) =>
      _sink('exactsize.compression outcome=SUCCESS format=${format.name}${_notices(notices)}');

  void failure(Reason reason, Set<Notice> notices) =>
      _sink('exactsize.compression outcome=${reason.code}${_notices(notices)}');

  static String _notices(Set<Notice> notices) =>
      notices.isEmpty ? '' : ' notices=${(notices.map((n) => n.name).toList()..sort()).join(',')}';
}
