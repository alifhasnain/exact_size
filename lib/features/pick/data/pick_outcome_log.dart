import 'package:flutter/foundation.dart' show debugPrint;

import '../domain/pick_types.dart';

/// Where log lines go; replaceable in tests.
typedef PickLogSink = void Function(String line);

void _debugPrintSink(String line) => debugPrint(line);

/// Pick outcome logging (FR-19, NFR-6). Inputs are enums only, so a line can
/// hold no origin, URI, file name or size.
class PickOutcomeLog {
  const PickOutcomeLog([this._sink = _debugPrintSink]);

  final PickLogSink _sink;

  void accepted() => _sink('exactsize.pick outcome=ACCEPTED');

  void cancelled() => _sink('exactsize.pick outcome=CANCELLED');

  void refused(PickMessage m) =>
      _sink('exactsize.pick outcome=${m.name.replaceAllMapped(RegExp('[A-Z]'), (x) => '_${x[0]}').toUpperCase()}');
}
