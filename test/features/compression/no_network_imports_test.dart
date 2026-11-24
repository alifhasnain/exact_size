import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FEAT-004-T21 / NFR-6, FEAT-002-T20 / NFR-5: the image pipeline makes no
/// network calls. Network packages and dart:io network classes may not appear
/// in the compression or crop features or in es_codec.
const scannedDirs = ['lib/features/compression', 'lib/features/crop', 'lib/features/pick', 'lib/features/export', 'packages/es_codec/lib', 'packages/es_codec/hook'];

final _banned = <RegExp>[
  RegExp(r'''import\s+['"]package:(http|dio|web_socket_channel|grpc|socket_io_client)[/'"]'''),
  RegExp(r'''import\s+['"]dart:(html|_http)['"]'''),
  RegExp(r'\b(HttpClient|HttpServer|HttpOverrides|RawSocket|SecureSocket|RawSecureSocket|Socket|ServerSocket|'
      r'RawDatagramSocket|WebSocket|InternetAddress|NetworkInterface)\b'),
];

/// Banned uses in [source] (comments ignored), as "line: text".
List<String> networkUses(String source) => [
      for (final (i, line) in source.split('\n').indexed)
        if (_banned.any((r) => r.hasMatch(line.replaceFirst(RegExp(r'//.*'), ''))))
          '${i + 1}: ${line.trim()}',
    ];

void main() {
  test('planted network imports and classes are caught', () {
    for (final planted in [
      "import 'package:http/http.dart' as http;",
      "import 'package:web_socket_channel/io.dart';",
      'final c = HttpClient();',
      'Socket.connect(host, 443);',
      'await WebSocket.connect(url);',
    ]) {
      expect(networkUses('// fine\n$planted\n'), hasLength(1), reason: planted);
    }
    expect(networkUses("import 'dart:io';\nfinal f = File('x'); // HttpClient in a comment\n"), isEmpty);
  });

  test('compression and crop features and es_codec use no network APIs', () {
    final hits = <String>[];
    var files = 0;
    for (final dir in scannedDirs) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        files++;
        hits.addAll(networkUses(f.readAsStringSync()).map((h) => '${f.path}:$h'));
      }
    }
    expect(files, greaterThan(20), reason: 'scanned the real code');
    expect(hits, isEmpty);
  });
}
