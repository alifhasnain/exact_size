import 'dart:io';

import 'package:exact_size/features/pick/data/pick_outcome_log.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-001-T05 (FR-8, FR-19, NFR-6, NFR-8): the pick module never reads file
/// names, never decodes pixels, logs only enum names, and its Kotlin side
/// never logs.
final _dartBans = <RegExp>[
  RegExp(r'\bOpenableColumns\b'),
  RegExp(r'\bDISPLAY_NAME\b'),
  RegExp(r'\bBitmapFactory\b'),
  RegExp(r"import 'dart:ui'"),
  RegExp(r'\b(PixelBuffer|NativePixelBuffer|instantiateImageCodec|decodeImageFromList)\b'),
];
final _kotlinBans = <RegExp>[RegExp(r'\bLog\.[a-z]+\('), RegExp(r'\bprintln\('), RegExp(r'\.printStackTrace\(')];

List<String> hits(String source, List<RegExp> bans) => [
      for (final (i, line) in source.split('\n').indexed)
        if (bans.any((r) => r.hasMatch(line.replaceFirst(RegExp(r'//.*'), '')))) '${i + 1}: ${line.trim()}',
    ];

List<File> dartFiles() =>
    Directory('lib/features/pick').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

List<File> kotlinFiles() => [
      for (final n in ['MainActivity.kt', 'ShareTargetActivity.kt'])
        if (File('android/app/src/main/kotlin/com/exactsize/exact_size/$n').existsSync())
          File('android/app/src/main/kotlin/com/exactsize/exact_size/$n'),
    ];

void main() {
  test('planted tokens are caught', () {
    for (final p in ['cursor.getString(OpenableColumns.DISPLAY_NAME);', "import 'dart:ui' as ui;", 'final b = BitmapFactory.decodeFile(p);', 'NativePixelBuffer.allocate(1, 1)']) {
      expect(hits('// ok\n$p\n', _dartBans), isNotEmpty, reason: p);
    }
    for (final p in ['Log.d("x", uri.toString())', 'println(uri)', 'e.printStackTrace()']) {
      expect(hits('// ok\n$p\n', _kotlinBans), hasLength(1), reason: p);
    }
    expect(hits('// Log.d("x", "y") in a comment\n', _kotlinBans), isEmpty);
  });

  test('lib/features/pick reads no names and decodes no pixels', () {
    final files = dartFiles();
    expect(files, isNotEmpty);
    expect([for (final f in files) ...hits(f.readAsStringSync(), _dartBans).map((h) => '${f.path}:$h')], isEmpty);
  });

  test('Kotlin bridge never logs', () {
    expect([for (final f in kotlinFiles()) ...hits(f.readAsStringSync(), _kotlinBans).map((h) => '${f.path}:$h')], isEmpty);
  });

  test('every pick log line holds only enum names', () {
    final lines = <String>[];
    final log = PickOutcomeLog(lines.add)
      ..accepted()
      ..cancelled();
    PickMessage.values.forEach(log.refused);
    expect(lines, hasLength(PickMessage.values.length + 2));
    for (final l in lines) {
      expect(RegExp(r'^exactsize\.pick outcome=[A-Z_]+$').hasMatch(l), isTrue, reason: l);
    }
    expect(lines, contains('exactsize.pick outcome=SOURCE_UNAVAILABLE'));
  });
}
