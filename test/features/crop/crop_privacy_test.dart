import 'dart:io';

import 'package:exact_size/features/crop/data/crop_outcome_log.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-002-T20 (FR-17, FR-24, NFR-7): the crop module never writes files or
/// opens the source for writing, and logs only enum names.
final _writeApis = <RegExp>[
  RegExp(r'\bopenOutputStream\b'),
  RegExp(r'''['"](w|rw|wt|wa|rwt)['"]'''), // ContentResolver / ParcelFileDescriptor write modes
  RegExp(r'\.(writeAsBytes|writeAsString|writeAsBytesSync|writeAsStringSync|openWrite)\b'),
  RegExp(r'\.(delete|deleteSync)\('),
  RegExp(r'\bFileMode\.(write|append|writeOnly|writeOnlyAppend)\b'),
];

List<String> writeUses(String source) => [
      for (final (i, line) in source.split('\n').indexed)
        if (_writeApis.any((r) => r.hasMatch(line.replaceFirst(RegExp(r'//.*'), '')))) '${i + 1}: ${line.trim()}',
    ];

/// A log line may hold only the prefix and enum names.
final _allowedLine = RegExp(r'^exactsize\.crop outcome=[A-Z_]+$');

void main() {
  test('planted write calls are caught', () {
    for (final planted in [
      "resolver.openOutputStream(uri);",
      "resolver.openFileDescriptor(uri, 'rw'.toJString());",
      "file.writeAsBytesSync(bytes);",
      "await File(path).delete();",
      "f.openSync(mode: FileMode.write);",
    ]) {
      expect(writeUses('// ok\n$planted\n'), hasLength(1), reason: planted);
    }
    expect(writeUses("final mode = 'r'.toJString(); // writeAsBytes in a comment\n"), isEmpty);
  });

  test('lib/features/crop uses no write API', () {
    final hits = <String>[];
    var files = 0;
    for (final f in Directory('lib/features/crop').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      files++;
      hits.addAll(writeUses(f.readAsStringSync()).map((h) => '${f.path}:$h'));
    }
    expect(files, greaterThan(15));
    expect(hits, isEmpty);
  });

  test('every crop log line holds only enum names', () {
    final lines = <String>[];
    final log = CropOutcomeLog(lines.add);
    log.success();
    for (final r in Reason.values) {
      log.failure(r);
    }
    expect(lines, hasLength(Reason.values.length + 1));
    for (final l in lines) {
      expect(_allowedLine.hasMatch(l), isTrue, reason: l);
      expect(l.contains(RegExp(r'[/\:]|\.(jpe?g|png|heic|webp|gif)\b|content|file|Orientation|GPS|[0-9]')), isFalse, reason: l);
    }
  });
}
