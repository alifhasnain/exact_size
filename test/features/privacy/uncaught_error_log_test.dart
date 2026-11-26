import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:exact_size/features/privacy/data/uncaught_error_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-016-T09 (FR-18, NFR-6, NFR-8): uncaught errors are logged as enum codes only.
void main() {
  const secret = '[PLACEHOLDER_PATH]';
  late FlutterExceptionHandler? savedFlutter;
  late ErrorCallback? savedPlatform;

  setUp(() {
    savedFlutter = FlutterError.onError;
    savedPlatform = PlatformDispatcher.instance.onError;
  });
  tearDown(() {
    FlutterError.onError = savedFlutter;
    PlatformDispatcher.instance.onError = savedPlatform;
  });

  FlutterErrorDetails details() => FlutterErrorDetails(exception: Exception('cannot open $secret'), library: 'test');

  test('release: one enum line per error, without the message, and nothing else runs', () {
    var previousCalls = 0;
    FlutterError.onError = (_) => previousCalls++;
    final lines = <String>[];
    installUncaughtErrorLog(sink: lines.add, debug: false);

    FlutterError.onError!(details());
    final handled = PlatformDispatcher.instance.onError!(Exception('cannot open $secret'), StackTrace.current);

    expect(lines, ['exactsize.app outcome=UNCAUGHT source=FRAMEWORK', 'exactsize.app outcome=UNCAUGHT source=PLATFORM']);
    expect(lines.join('\n'), isNot(contains(secret)));
    expect(lines.join('\n'), isNot(contains('Exception')));
    expect(previousCalls, 0);
    expect(handled, isTrue);
  });

  test('debug: the line is written, the previous handler runs once, the platform handler returns false', () {
    var previousCalls = 0;
    FlutterError.onError = (_) => previousCalls++;
    final lines = <String>[];
    installUncaughtErrorLog(sink: lines.add, debug: true);

    FlutterError.onError!(details());
    final handled = PlatformDispatcher.instance.onError!(Exception(secret), StackTrace.current);

    expect(lines, hasLength(2));
    expect(previousCalls, 1);
    expect(handled, isFalse);
  });
}
