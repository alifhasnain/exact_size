import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FEAT-007-T05 (FR-8, FR-27, NFR-5): the export Kotlin never logs, never asks
/// for READ_EXTERNAL_STORAGE and never reads exception text.
final _bans = <RegExp>[
  RegExp(r'\bLog\.[a-z]+\('),
  RegExp(r'\bprintln\('),
  RegExp(r'\.printStackTrace\('),
  RegExp(r'\bREAD_EXTERNAL_STORAGE\b'),
  RegExp(r'\.(message|localizedMessage|cause|stackTrace)\b'),
];

List<String> hits(String source) => [
      for (final (i, line) in source.split('\n').indexed)
        if (_bans.any((r) => r.hasMatch(line.replaceFirst(RegExp(r'//.*'), '')))) '${i + 1}: ${line.trim()}',
    ];

const _dir = 'android/app/src/main/kotlin/com/exactsize/exact_size';

void main() {
  test('planted tokens are caught, comments are not', () {
    for (final p in ['Log.i("x", name)', 'println(uri)', 'e.printStackTrace()', 'Manifest.permission.READ_EXTERNAL_STORAGE', 'msg = e.message',
      'e.localizedMessage', 't.cause']) {
      expect(hits('// ok\n$p\n'), hasLength(1), reason: p);
    }
    expect(hits('// Log.d("x", e.message) in a comment\n'), isEmpty);
  });

  test('ExportBridge.kt and ShareFileProvider.kt hold none of the banned tokens', () {
    for (final n in ['ExportBridge.kt', 'ShareFileProvider.kt']) {
      final f = File('$_dir/$n');
      expect(f.existsSync(), isTrue, reason: n);
      expect(hits(f.readAsStringSync()), isEmpty, reason: n);
    }
  });
}
