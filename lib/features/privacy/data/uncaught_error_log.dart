import 'package:flutter/foundation.dart';

import '../../compression/data/outcome_log.dart' show LogSink;

void _debugPrintSink(String line) => debugPrint(line);

/// FEAT-016 FR-18: an uncaught error is logged as one enum line, never with its text, type, stack,
/// path or URI (an exception message can hold a file path). Neither handler reads the error.
///
/// Release and profile: the line replaces the default output. Debug: the line is written and the
/// previous handler still runs (red screen, full console dump), and the platform handler returns
/// false so default reporting runs too, so errors are never hidden from developers.
/// Called once from `main()`; widget tests keep flutter_test's own handler.
void installUncaughtErrorLog({LogSink sink = _debugPrintSink, bool debug = kDebugMode}) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    sink('exactsize.app outcome=UNCAUGHT source=FRAMEWORK');
    if (debug) previous?.call(details);
  };
  PlatformDispatcher.instance.onError = (_, _) {
    sink('exactsize.app outcome=UNCAUGHT source=PLATFORM');
    return !debug;
  };
}
