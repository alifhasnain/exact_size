import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../features/compression/no_network_imports_test.dart' as network;

/// FEAT-016-T06 (FR-9, FR-4, FR-15, NFR-5, NFR-6): deny by default. Every Dart, Kotlin and Java
/// file under the roots is scanned, generated files included, so a new feature folder is covered
/// without editing this list. The per-feature privacy tests stay as they are.
const roots = [
  'lib',
  'packages/es_codec/lib',
  'packages/es_codec/hook',
  'android/app/src/main/kotlin',
  'android/app/src/main/java', // GeneratedPluginRegistrant.java, git-ignored: scanned when present
];

/// Fail closed: a root that suddenly holds far fewer files means the scan lost its target (T01 H4).
const floors = {'lib': 85, 'android/app/src/main/kotlin': 4};

/// `path: reason`. Empty in R1; each entry is recorded in the PRD change log (AC-6.3).
const exempt = <String, String>{};

const followFr12 = 'Follow FEAT-016 FR-12 (docs/features/FEAT-016-on-device-privacy/claims.md).';

final _dartRules = <RegExp>[
  RegExp(r'''import\s+['"]package:(webview_flutter|url_launcher|connectivity_plus|flutter_test|'''
      r'''firebase\w*|google_mobile_ads|sentry\w*|amplitude\w*|mixpanel\w*|appsflyer\w*|facebook\w*|unity_ads\w*|'''
      r'''applovin\w*|crashlytics\w*|bugsnag\w*)[/'"]'''),
  RegExp(r'\b(ConnectivityResult|WebView|Clipboard)\b'),
];

final _nativeRules = <RegExp>[
  RegExp(r'\b(java\.net\.|javax\.net\.|okhttp3|retrofit2|android\.webkit|com\.google\.firebase|com\.google\.android\.gms\.ads)'),
  RegExp(r'\b(HttpURLConnection|Socket|WebView|ConnectivityManager|ClipboardManager)\b'),
];

/// Only the FR-18 sink may print inside the privacy feature (NFR-6).
final _printBan = RegExp(r'\b(print|debugPrint)\(');

bool _skipped(String line) {
  final t = line.trim();
  return t.startsWith('*') || t.startsWith('/*') || t.startsWith('///');
}

List<String> _hits(String path, String source) {
  final dart = path.endsWith('.dart');
  final rules = dart ? _dartRules : _nativeRules;
  final printBanned = path.contains('lib/features/privacy/') && !path.endsWith('uncaught_error_log.dart');
  return [
    for (final (i, line) in source.split('\n').indexed)
      if (!_skipped(line))
        if (() {
          final code = line.replaceFirst(RegExp(r'//.*'), '');
          return rules.any((r) => r.hasMatch(code)) ||
              (dart && network.networkUses(code).isNotEmpty) ||
              (printBanned && _printBan.hasMatch(code));
        }())
          '$path:${i + 1}: ${line.trim()}',
  ];
}

Iterable<File> _files(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.kt') || f.path.endsWith('.java'));
}

String _rel(String path) => path.replaceAll(r'\', '/');

/// "path:line: text" for every banned use under [roots], except paths in [exempt].
List<String> scanTree(List<String> roots, {Map<String, String> exempt = const {}}) => [
      for (final root in roots)
        for (final f in _files(root))
          if (!exempt.containsKey(_rel(f.path))) ..._hits(_rel(f.path), f.readAsStringSync()),
    ];

List<String> floorProblems(Map<String, int> floors) => [
      for (final MapEntry(key: root, value: min) in floors.entries)
        if (_files(root).where((f) => !f.path.endsWith('.java')).length < min)
          'Root $root has fewer than $min source files: the scan lost its target. $followFr12',
    ];

List<String> exemptProblems(Map<String, String> exempt) => [
      for (final path in exempt.keys)
        if (!File(path).existsSync()) 'Exempt path $path no longer exists: remove it from the list. $followFr12',
    ];

void main() {
  test('no network, SDK, WebView, connectivity or clipboard use anywhere in app code (FR-9)', () {
    final hits = scanTree(roots, exempt: exempt);
    expect(hits, isEmpty,
        reason: '${hits.join('\n')}\nExactSize code must not use the network or clipboard. $followFr12');
  });

  test('every root still holds its files and every exempt path exists (NFR-5)', () {
    expect(floorProblems(floors), isEmpty);
    expect(exemptProblems(exempt), isEmpty);
  });

  group('self-tests (AC-4.2, AC-4.4)', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('fe016_scan'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('a network class in a new folder and java.net in Kotlin give exactly one hit each', () {
      final dart = File('${tmp.path}/features/new_feature/x.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// HttpClient in a comment is fine\nfinal c = HttpClient();\n');
      final kt = File('${tmp.path}/kotlin/X.kt')
        ..createSync(recursive: true)
        ..writeAsStringSync('package x\n/**\n * WebView in KDoc is fine\n */\nval u = java.net.URL("[PLACEHOLDER]")\nval ok = android.net.Uri.EMPTY\n');
      final hits = scanTree([tmp.path]);
      expect(hits, hasLength(2), reason: hits.join('\n'));
      expect(hits.where((h) => h.startsWith('${_rel(dart.path)}:2: ')), hasLength(1));
      expect(hits.where((h) => h.startsWith('${_rel(kt.path)}:5: ')), hasLength(1));

      dart.writeAsStringSync('final c = 1;\n');
      kt.writeAsStringSync('val ok = android.net.Uri.EMPTY\n');
      expect(scanTree([tmp.path]), isEmpty);
    });

    test('each token family is caught', () {
      for (final line in [
        "import 'package:url_launcher/url_launcher.dart';",
        "import 'package:webview_flutter/webview_flutter.dart';",
        "import 'package:connectivity_plus/connectivity_plus.dart';",
        "import 'package:flutter_test/flutter_test.dart';",
        "import 'package:google_mobile_ads/google_mobile_ads.dart';",
        'Clipboard.setData(data);',
        'final r = ConnectivityResult.none;',
        'Socket.connect(host, 443);',
      ]) {
        expect(_hits('lib/x.dart', line), hasLength(1), reason: line);
      }
      for (final line in ['import okhttp3.OkHttpClient', 'val c = getSystemService(ClipboardManager::class.java)', 'val w = WebView(this)']) {
        expect(_hits('android/x.kt', line), hasLength(1), reason: line);
      }
      expect(_hits('lib/features/privacy/presentation/x.dart', "debugPrint('x');"), hasLength(1));
      expect(_hits('lib/features/privacy/data/uncaught_error_log.dart', "debugPrint('x');"), isEmpty);
    });

    test('a root below its floor and a stale exempt path fail', () {
      expect(floorProblems({tmp.path: 1}), hasLength(1));
      expect(exemptProblems({'${tmp.path}/gone.dart': 'test'}), hasLength(1));
    });
  });
}
