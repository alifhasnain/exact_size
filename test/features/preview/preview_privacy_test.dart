import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../compression/no_network_imports_test.dart' as network;

/// FEAT-006-T09 (FR-19, NFR-3, NFR-8): the preview feature logs only enum codes, stores nothing,
/// puts nothing in the image cache or the clipboard and sends nothing. Scans the whole folder,
/// so it also guards the check screen built later.
const _scanned = 'lib/features/preview';

final _bans = <RegExp>[
  RegExp(r'''import\s+['"]package:(shared_preferences|firebase\w*|google_mobile_ads|sentry\w*|amplitude\w*|mixpanel\w*|'''
      r'''appsflyer\w*|facebook\w*|unity_ads\w*|applovin\w*|crashlytics\w*|bugsnag\w*)[/'"]'''),
  RegExp(r'\b(Image\.file|Image\.memory|FileImage|MemoryImage)\b'), // never into imageCache
  RegExp(r'\b(restorationId|restorationScopeId|RestorationScope|RestorationMixin)\b'),
  RegExp(r'\bClipboard\b'),
  RegExp(r'\b(developer\.log|debugPrintStack)\b'),
];

/// Only SpecCheckLog may print.
final _printBan = RegExp(r'\b(print|debugPrint|log)\(');

List<String> _uses(String source, Iterable<RegExp> rules) => [
      for (final (i, line) in source.split('\n').indexed)
        if (rules.any((r) => r.hasMatch(line.replaceFirst(RegExp(r'//.*'), '')))) '${i + 1}: ${line.trim()}',
    ];

List<String> problems(String source, String path) => [
      ...network.networkUses(source),
      ..._uses(source, _bans),
      if (!path.endsWith('spec_check_log.dart')) ..._uses(source, [_printBan]),
    ];

void main() {
  test('each rule catches a planted token; comments are ignored', () {
    for (final p in [
      "import 'package:shared_preferences/shared_preferences.dart';",
      "import 'package:firebase_crashlytics/firebase_crashlytics.dart';",
      "import 'package:google_mobile_ads/google_mobile_ads.dart';",
      "import 'package:http/http.dart' as http;",
      'final s = await Socket.connect(host, 80);',
      'final c = HttpClient();',
      'Image.file(file)',
      'Image.memory(bytes)',
      'FileImage(file)',
      'MemoryImage(bytes)',
      "TextField(restorationId: 'x')",
      'Clipboard.setData(ClipboardData(text: size));',
      'developer.log(size);',
      'print(size);',
      'debugPrint(size);',
      'log(size);',
    ]) {
      expect(problems('// ok\n$p\n', 'lib/features/preview/presentation/x.dart'), isNotEmpty, reason: p);
    }
    expect(problems('debugPrint(line);\n', 'lib/features/preview/data/spec_check_log.dart'), isEmpty);
    expect(problems('// Image.file(f) and print(x) in a comment\n', 'lib/features/preview/presentation/x.dart'), isEmpty);
  });

  test('lib/features/preview breaks no rule', () {
    final files = Directory(_scanned).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
    expect(files, isNotEmpty);
    final hits = [
      for (final f in files)
        for (final h in problems(f.readAsStringSync(), f.path.replaceAll(r'\', '/'))) '${f.path}:$h',
    ];
    expect(hits, isEmpty);
  });
}
