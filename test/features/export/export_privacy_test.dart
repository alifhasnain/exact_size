import 'dart:io';

import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/export/data/export_outcome_log.dart';
import 'package:exact_size/features/export/data/share_copies.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:exact_size/features/export/presentation/export_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_support/fake_export_bridge.dart';
import '../compression/no_network_imports_test.dart' as network;

/// FEAT-007-T15 (FR-3, FR-8, FR-27, FR-28, NFR-3, NFR-5): the export feature logs only outcome
/// codes, stores nothing, decodes nothing, sends nothing, and its Kotlin never logs or reads
/// beyond its own items. All export privacy rules in one place.
const _scanned = 'lib/features/export';
const _kotlin = 'android/app/src/main/kotlin/com/exactsize/exact_size';

final _dartBans = <RegExp>[
  RegExp(r'''import\s+['"]package:(shared_preferences|image|es_codec|firebase\w*|google_mobile_ads|sentry\w*|amplitude\w*|mixpanel\w*)[/'"]'''),
  RegExp(r'\b(instantiateImageCodec|decodeImageFromList|ImageDescriptor|PixelBuffer)\b'),
  RegExp(r'''import\s+['"]dart:ui['"]'''),
  RegExp(r'\b(restorationId|restorationScopeId|RestorationScope|RestorationMixin)\b'),
  RegExp(r'\bClipboard\.setData\b'),
  RegExp(r'\b(developer\.log|debugPrintStack)\b'),
];

/// Only ExportOutcomeLog may print.
final _printBan = RegExp(r'\b(print|debugPrint|log)\(');

/// Domain code stays pure Dart (ADR-001).
final _domainBan = RegExp(r'''import\s+['"]package:(flutter\w*|riverpod|get_it|injectable|material_ui)[/'"]|services\.dart''');

final _kotlinBans = <RegExp>[
  RegExp(r'\bLog\.[a-z]+\('),
  RegExp(r'\bprintln\('),
  RegExp(r'\.printStackTrace\('),
  RegExp(r'\bREAD_EXTERNAL_STORAGE\b'),
  RegExp(r'\.(message|localizedMessage|cause|stackTrace)\b'),
];

List<String> uses(String source, Iterable<RegExp> rules) => [
      for (final (i, line) in source.split('\n').indexed)
        if (rules.any((r) => r.hasMatch(line.replaceFirst(RegExp(r'//.*'), '')))) '${i + 1}: ${line.trim()}',
    ];

/// Every Dart problem in [source] for a file at [path].
List<String> dartProblems(String source, String path) => [
      ...network.networkUses(source),
      ...uses(source, _dartBans),
      if (!path.endsWith('export_outcome_log.dart')) ...uses(source, [_printBan]),
      if (path.contains('/domain/')) ...uses(source, [_domainBan]),
    ];

/// FR-8, FR-16: a MediaStore collection query must use SWEEP_SELECTION (our folder and package),
/// and files may only be listed in Pictures/ExactSize. Offending line numbers.
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
  group('Dart', () {
    test('planted tokens are caught in each rule', () {
      for (final p in [
        "import 'package:shared_preferences/shared_preferences.dart';",
        "import 'package:image/image.dart' as img;",
        "import 'package:es_codec/es_codec.dart';",
        "import 'package:firebase_analytics/firebase_analytics.dart';",
        "import 'package:http/http.dart' as http;",
        "import 'dart:ui' as ui;",
        'await instantiateImageCodec(bytes);',
        "TextField(restorationId: 'x')",
        'Clipboard.setData(ClipboardData(text: name));',
        'developer.log(name);',
      ]) {
        expect(dartProblems('// ok\n$p\n', 'lib/features/export/presentation/x.dart'), isNotEmpty, reason: p);
      }
      expect(dartProblems("debugPrint(name);\n", 'lib/features/export/presentation/x.dart'), hasLength(1));
      expect(dartProblems("debugPrint(line);\n", 'lib/features/export/data/export_outcome_log.dart'), isEmpty);
      expect(dartProblems("import 'package:flutter/services.dart';\n", 'lib/features/export/domain/x.dart'), hasLength(1));
      expect(dartProblems('// debugPrint(name) in a comment\n', 'lib/features/export/presentation/x.dart'), isEmpty);
    });

    test('lib/features/export breaks no rule', () {
      final files = Directory(_scanned).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
      expect(files, isNotEmpty);
      final hits = [
        for (final f in files)
          for (final h in dartProblems(f.readAsStringSync(), f.path.replaceAll(r'\', '/'))) '${f.path}:$h',
      ];
      expect(hits, isEmpty);
    });
  });

  group('Kotlin', () {
    test('planted tokens are caught, comments are not', () {
      for (final p in ['Log.i("x", name)', 'println(uri)', 'e.printStackTrace()', 'Manifest.permission.READ_EXTERNAL_STORAGE', 'msg = e.message',
        'e.localizedMessage', 't.cause']) {
        expect(uses('// ok\n$p\n', _kotlinBans), hasLength(1), reason: p);
      }
      expect(uses('// Log.d("x", e.message) in a comment\n', _kotlinBans), isEmpty);
      expect(scopeHits('val c = resolver.query(collection, null, null, null, null)'), [1]);
      expect(scopeHits('resolver.query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, null, null, null, null)'), [1]);
      expect(scopeHits('File("/sdcard").listFiles()'), [1]);
      expect(scopeHits('putString(X, SWEEP_SELECTION)\nresolver.query(collection, p, q, null)\nexactSizeDir().listFiles()'), isEmpty);
    });

    test('ExportBridge.kt and ShareFileProvider.kt hold no banned token', () {
      for (final n in ['ExportBridge.kt', 'ShareFileProvider.kt']) {
        final f = File('$_kotlin/$n');
        expect(f.existsSync(), isTrue, reason: n);
        expect(uses(f.readAsStringSync(), _kotlinBans), isEmpty, reason: n);
      }
    });

    test('ExportBridge.kt scopes every collection query and file listing to its own items', () {
      final src = File('$_kotlin/ExportBridge.kt').readAsStringSync();
      expect(scopeHits(src), isEmpty);
      final def = RegExp(r'SWEEP_SELECTION = ([^\n]+\n[^\n]+)').firstMatch(src)![1]!;
      expect(def, allOf(contains('RELATIVE_PATH'), contains('OWNER_PACKAGE_NAME')));
    });
  });

  test('log audit: every export line is a bare outcome code, never a name, URI or path (FR-27)', () async {
    final tmp = Directory.systemTemp.createTempSync('export_privacy_test');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final temp = File('${tmp.path}/[PLACEHOLDER].jpg')..writeAsBytesSync(List.filled(2000, 9));
    final input = ExportInput(CompressionSuccess(tempFilePath: temp.path, sizeBytes: 2000, format: OutputFormat.jpeg), const Target(300, 300));
    final bridge = FakeExportBridge()
      ..saves.addAll([const BridgeNameTaken(), const BridgeSaved(name: 'exactsize-300x300-[PLACEHOLDER] (1).jpg', ref: 'content://media/[PLACEHOLDER]')])
      ..saveAsResults.addAll([const BridgeSaveError(ExportOutcome.saveCancelled), const BridgeSaved(name: 'exactsize-300x300-x.jpg', ref: '/storage/[PLACEHOLDER]')]);
    final lines = <String>[];
    final c = ProviderContainer(overrides: [
      exportBridgeProvider.overrideWithValue(bridge),
      shareCopiesProvider.overrideWithValue(ShareCopies(TempFiles(tmp, folder: 'exactsize_share'))),
      exportLogProvider.overrideWithValue(ExportOutcomeLog(lines.add)),
      compressionControllerProvider.overrideWith(_NoCompression.new),
    ]);
    addTearDown(c.dispose);
    c.listen(exportControllerProvider(input), (_, _) {});
    final ctl = c.read(exportControllerProvider(input).notifier);
    await ctl.save();
    await ctl.save(); // already saved
    bridge.existing.clear();
    bridge.failNext(ExportOutcome.noSpace);
    await ctl.save();
    await ctl.saveAs();
    await ctl.saveAs();
    await ctl.share();
    bridge.viewer = false;
    await ctl.open();
    bridge.chooser = false;
    await ctl.share();
    temp.writeAsBytesSync([1]);
    await ctl.save();
    await ctl.leave();
    expect(lines.length, greaterThanOrEqualTo(9));
    for (final l in lines) {
      expect(RegExp(r'^exactsize\.export outcome=[A-Z_]+$').hasMatch(l), isTrue, reason: l);
      for (final bad in ['exactsize-', 'content://', '/data/', '/storage/', 'Pictures', 'PLACEHOLDER']) {
        expect(l, isNot(contains(bad)), reason: l);
      }
    }
  });
}

class _NoCompression extends CompressionController {
  @override
  CompressionRunState build() => const CompressionIdle();

  @override
  Future<void> cancel() async {}
}
