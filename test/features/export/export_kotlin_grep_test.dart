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

/// FR-8, FR-16: a MediaStore collection query must use SWEEP_SELECTION (our folder and our package),
/// and files may only be listed in Pictures/ExactSize. Returns the offending line numbers.
List<int> scopeHits(String src) {
  final lines = src.split('\n').map((l) => l.replaceFirst(RegExp(r'//.*'), '')).toList();
  return [
    for (final (i, l) in lines.indexed)
      if ((l.contains('query(collection') || RegExp(r'query\(MediaStore\.').hasMatch(l)) &&
              !lines.sublist(i < 6 ? 0 : i - 6, i + 3 > lines.length ? lines.length : i + 3).any((x) => x.contains('SWEEP_SELECTION')) ||
          l.contains('listFiles') && !l.contains('exactSizeDir().listFiles'))
        i + 1,
  ];
}

void main() {
  test('planted tokens are caught, comments are not', () {
    for (final p in ['Log.i("x", name)', 'println(uri)', 'e.printStackTrace()', 'Manifest.permission.READ_EXTERNAL_STORAGE', 'msg = e.message',
      'e.localizedMessage', 't.cause']) {
      expect(hits('// ok\n$p\n'), hasLength(1), reason: p);
    }
    expect(hits('// Log.d("x", e.message) in a comment\n'), isEmpty);
  });

  test('scope rule catches an unscoped collection query and a stray listFiles', () {
    expect(scopeHits('val c = resolver.query(collection, null, null, null, null)'), [1]);
    expect(scopeHits('resolver.query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, null, null, null, null)'), [1]);
    expect(scopeHits('File("/sdcard").listFiles()'), [1]);
    expect(scopeHits('putString(X, SWEEP_SELECTION)\nresolver.query(collection, p, q, null)\nexactSizeDir().listFiles()'), isEmpty);
  });

  test('ExportBridge.kt scopes every collection query and file listing to its own items', () {
    final src = File('$_dir/ExportBridge.kt').readAsStringSync();
    expect(scopeHits(src), isEmpty);
    final def = RegExp(r'SWEEP_SELECTION = ([^\n]+\n[^\n]+)').firstMatch(src)![1]!;
    expect(def, allOf(contains('RELATIVE_PATH'), contains('OWNER_PACKAGE_NAME')));
  });

  test('ExportBridge.kt and ShareFileProvider.kt hold none of the banned tokens', () {
    for (final n in ['ExportBridge.kt', 'ShareFileProvider.kt']) {
      final f = File('$_dir/$n');
      expect(f.existsSync(), isTrue, reason: n);
      expect(hits(f.readAsStringSync()), isEmpty, reason: n);
    }
  });
}
