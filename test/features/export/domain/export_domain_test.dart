import 'dart:io';
import 'dart:math';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/export/domain/export_name.dart';
import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-007-T03: FR-4 name, outcome code list, redacted toString, secure random.
void main() {
  group('ExportName', () {
    test('10,000 names match FR-4, fit 40 characters and never repeat', () {
      // Seeded so the no-repeat check is deterministic: with Random.secure() a repeat among 10,000
      // draws from 36^6 tokens happens in about 2% of runs (birthday bound). The app uses secure.
      final rnd = Random(20261124);
      final seen = <String>{};
      for (var i = 0; i < 10000; i++) {
        final n = ExportName.generate(999999, 999999, i.isEven ? OutputFormat.jpeg : OutputFormat.png, rnd);
        expect(ExportName.pattern.hasMatch(n), isTrue, reason: n);
        expect(n.length, lessThanOrEqualTo(ExportName.maxLength));
        expect(seen.add(n), isTrue, reason: 'repeat');
      }
    });

    test('1x1 and 999999x999999 are valid; out-of-range sizes are refused', () {
      expect(ExportName.generate(1, 1, OutputFormat.jpeg, Random.secure()), startsWith('exactsize-1x1-'));
      expect(ExportName.generate(999999, 999999, OutputFormat.png, Random.secure()), endsWith('.png'));
      expect(() => ExportName.generate(1000000, 1, OutputFormat.jpeg, Random.secure()), throwsArgumentError);
      expect(() => ExportName.generate(0, -1, OutputFormat.jpeg, Random.secure()), throwsArgumentError);
    });

    test('extension and MIME follow the format', () {
      expect((ExportName.ext(OutputFormat.jpeg), ExportName.mime(OutputFormat.jpeg)), ('jpg', 'image/jpeg'));
      expect((ExportName.ext(OutputFormat.png), ExportName.mime(OutputFormat.png)), ('png', 'image/png'));
    });
  });

  test('ExportOutcome codes equal the PRD section 5 list', () {
    final prd = File('docs/features/FEAT-007-export-share/prd.md').readAsStringSync();
    final flows = prd.split('\n').firstWhere((l) => l.startsWith('**Error flows:**'));
    final codes = RegExp(r'`([A-Z_]+)`').allMatches(flows).map((m) => m[1]).toSet();
    expect(ExportOutcome.values.map((o) => o.code).toSet(), codes);
    expect(ExportOutcome.values.length, codes.length);
  });

  test('toString hides names, refs and sizes', () {
    const name = 'exactsize-300x300-[PLACEHOLDER].jpg';
    const ref = 'content://[PLACEHOLDER]/42';
    final values = <Object>[
      const SavedItem(ref: ref, displayName: name),
      const BridgeSaved(name: name, ref: ref),
      const BridgeNameTaken(),
      const BridgeSaveError(ExportOutcome.noSpace),
      const ExportInput(CompressionSuccess(tempFilePath: '/[PLACEHOLDER]/a.jpg', sizeBytes: 51234, format: OutputFormat.jpeg),
          Target(300, 300)),
    ];
    for (final v in values) {
      final s = v.toString();
      for (final secret in [name, ref, '[PLACEHOLDER]', '51234', '300']) {
        expect(s, isNot(contains(secret)), reason: '${v.runtimeType}');
      }
    }
  });

  test('ExportInput equality: same result object and size', () {
    const s = CompressionSuccess(tempFilePath: 'x', sizeBytes: 1, format: OutputFormat.png);
    const t = CompressionSuccess(tempFilePath: 'x', sizeBytes: 1, format: OutputFormat.png);
    expect(const ExportInput(s, Target(1, 2)), const ExportInput(s, Target(1, 2)));
    expect(ExportInput(s, const Target(1, 2)) == ExportInput(t, const Target(1, 2)), identical(s, t));
  });

  group('source rules', () {
    final lib = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    String norm(File f) => f.path.replaceAll(r'\', '/');

    test('every ExportName.generate call site passes Random.secure() or a field set to it', () {
      for (final f in lib) {
        final src = f.readAsStringSync();
        for (final line in src.split('\n').where((l) => l.contains('ExportName.generate('))) {
          final arg = RegExp(r'ExportName\.generate\(.*,\s*([\w.()]+)\)').firstMatch(line)?[1];
          final ok = arg == 'Random.secure()' || (arg != null && RegExp('\\b${RegExp.escape(arg)}\\s*=\\s*Random\\.secure\\(\\)').hasMatch(src));
          expect(ok, isTrue, reason: '${norm(f)}: $line');
        }
      }
    });

    test('the call-site rule refuses a plain Random', () {
      bool ok(String src) {
        final arg = RegExp(r'ExportName\.generate\(.*,\s*([\w.()]+)\)').firstMatch(src)?[1];
        return arg == 'Random.secure()' || (arg != null && RegExp('\\b${RegExp.escape(arg)}\\s*=\\s*Random\\.secure\\(\\)').hasMatch(src));
      }

      expect(ok('final r = Random(1);\nExportName.generate(1, 1, f, r)'), isFalse);
      expect(ok('final _s = Random.secure();\nExportName.generate(1, 1, f, _s)'), isTrue);
    });

    test('no Random( in lib/features/export and no Flutter, Riverpod, get_it or channel import in its domain', () {
      for (final f in lib.where((f) => norm(f).contains('lib/features/export/'))) {
        final src = f.readAsStringSync();
        expect(RegExp(r'\bRandom\(').hasMatch(src), isFalse, reason: norm(f));
        if (norm(f).contains('/export/domain/')) {
          expect(RegExp(r"import 'package:(flutter|flutter_riverpod|riverpod|get_it|injectable)").hasMatch(src), isFalse, reason: norm(f));
          expect(src, isNot(contains('services.dart')), reason: norm(f));
        }
      }
    });
  });
}
