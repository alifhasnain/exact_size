import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../compression/no_network_imports_test.dart' as network;
import '../crop/crop_privacy_test.dart' as writes;

/// FEAT-005-T07 (FR-14, NFR-3, NFR-6): the target step stores, logs and sends
/// nothing. Scans lib/features/target/ and lib/app_flow.dart.
const scanned = ['lib/features/target', 'lib/app_flow.dart'];

final _banned = <RegExp>[
  RegExp(r'''import\s+['"]package:shared_preferences'''),
  RegExp(r'''import\s+['"]dart:io['"]'''),
  RegExp(r'\b(print|debugPrint|log|debugPrintStack)\('),
  RegExp(r'\b(OutcomeLog|CropOutcomeLog|PickOutcomeLog|developer\.log)\b'),
  RegExp(r'\b(restorationId|restorationScopeId|RestorationScope|RestorationMixin)\b'),
  RegExp(r'\bClipboard\.setData\b'),
];

/// Domain code stays pure Dart (tech section 2).
final _domainBanned = RegExp(r'''import\s+['"]package:(material_ui|cupertino_ui|flutter\w*)[/'"]''');

List<String> uses(String source, Iterable<RegExp> rules) => [
      for (final (i, line) in source.split('\n').indexed)
        if (rules.any((r) => r.hasMatch(line.replaceFirst(RegExp(r'//.*'), '')))) '${i + 1}: ${line.trim()}',
    ];

/// Every problem in [source]: network, write APIs, the target bans, and for
/// domain files the Flutter import ban.
List<String> problems(String source, {required bool domain}) => [
      ...network.networkUses(source),
      ...writes.writeUses(source),
      ...uses(source, _banned),
      if (domain) ...uses(source, [_domainBanned]),
    ];

Iterable<File> _files() sync* {
  for (final p in scanned) {
    if (p.endsWith('.dart')) {
      yield File(p);
    } else {
      yield* Directory(p).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    }
  }
}

bool _isDomain(File f) => f.path.replaceAll(r'\', '/').contains('/target/domain/');

void main() {
  test('planted uses are caught', () {
    for (final planted in [
      "import 'package:shared_preferences/shared_preferences.dart';",
      "import 'dart:io';",
      "print(spec);",
      "debugPrint('x');",
      "log('x');",
      "final l = getIt<OutcomeLog>();",
      "TextField(restorationId: 'w')",
      "RestorationScope(child: c)",
      "Clipboard.setData(ClipboardData(text: t));",
      "import 'package:http/http.dart';",
      "file.writeAsStringSync(t);",
    ]) {
      expect(problems('// ok\n$planted\n', domain: false), isNotEmpty, reason: planted);
    }
    for (final planted in [
      "import 'package:flutter/foundation.dart';",
      "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      "import 'package:material_ui/material_ui.dart';",
    ]) {
      expect(problems(planted, domain: true), hasLength(1), reason: planted);
      expect(problems(planted, domain: false), isEmpty, reason: planted);
    }
    expect(problems("final a = catalog(x); // print('x') in a comment\n", domain: true), isEmpty);
  });

  test('lib/features/target and lib/app_flow.dart hold none of them', () {
    final hits = <String>[];
    var files = 0;
    for (final f in _files()) {
      files++;
      hits.addAll(problems(f.readAsStringSync(), domain: _isDomain(f)).map((h) => '${f.path}:$h'));
    }
    expect(files, greaterThanOrEqualTo(7), reason: 'scanned the real code');
    expect(hits, isEmpty);
  });
}
