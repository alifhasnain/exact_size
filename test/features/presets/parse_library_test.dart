import 'dart:convert';
import 'dart:io';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/presets/domain/parse_library.dart';
import 'package:exact_size/features/presets/domain/preset_types.dart';
import 'package:exact_size/features/target/domain/target_input.dart';
import 'package:exact_size/features/target/domain/validate_target_input.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-011-T01: runtime parse rules (tech section 5) on the synthetic fixture.
void main() {
  Map<String, Object?> fixture() =>
      jsonDecode(File('test/presets/fixtures/test_library.json').readAsStringSync()) as Map<String, Object?>;

  Map<String, Object?> spec([Map<String, Object?> over = const {}]) => {
    'kind': 'photo',
    'width': 200,
    'height': 230,
    'minKb': 20,
    'maxKb': 50,
    'format': 'jpeg',
    ...over,
  };

  Map<String, Object?> lib(List<Map<String, Object?>> specs) => {
    'schema': 1,
    'forms': [
      {'id': 'test-x', 'name': 'Test X', 'specs': specs},
    ],
  };

  test('fixture parses to 2 forms with every field', () {
    final l = parseLibrary(fixture());
    expect(l.skipped, 0);
    expect(l.forms.map((f) => f.id), ['test-form-a', 'test-form-b']);
    final a = l.forms.first;
    expect(a.category, FormCategory.examAdmission);
    expect(a.aliases, ['TFA']);
    expect(a.source.title, 'Test notice 1');
    expect(a.lastChecked, DateTime.utc(2026, 10, 1));
    expect(a.specs.map((s) => s.kind), [SpecKind.photo, SpecKind.signature]);
    expect(a.specs.first.notCovered, [const DpiNote(200), const BackgroundNote()]);
    expect(l.forms.last.specs.single.notCovered, [const ContentNote()]);
  });

  final bad = <String, Map<String, Object?>>{
    'width 0': spec({'width': 0}),
    'unknown kind': spec({'kind': 'thumbprint'}),
    'unknown format': spec({'format': 'webp'}),
    'unknown note code': spec({
      'notCovered': [
        {'code': 'glasses'},
      ],
    }),
    'dpi note without a number': spec({
      'notCovered': [
        {'code': 'dpi'},
      ],
    }),
    'min not below max': spec({'minKb': 50}),
    'decimal width': spec({'width': 200.5}),
    'too many pixels': spec({'width': 10000, 'height': 10000}),
  };
  for (final MapEntry(:key, :value) in bad.entries) {
    test('$key skips only that spec and counts it', () {
      final l = parseLibrary(
        lib([
          value,
          spec({'kind': 'signature', 'minKb': null, 'maxKb': 20}),
        ]),
      );
      expect(l.skipped, 1);
      expect(l.forms.single.specs.single.kind, SpecKind.signature);
    });
  }

  test('a repeated kind skips the second spec', () {
    final l = parseLibrary(
      lib([
        spec(),
        spec({'width': 300}),
      ]),
    );
    expect(l.skipped, 1);
    expect(l.forms.single.specs.single.width, 200);
  });

  test('a form with no valid spec, or without id or name, is dropped', () {
    final l = parseLibrary({
      'schema': 1,
      'forms': [
        {
          'id': 'test-x',
          'name': 'Test X',
          'specs': [
            spec({'width': 0}),
          ],
        },
        {
          'name': 'No id',
          'specs': [spec()],
        },
        {
          'id': 'test-y',
          'specs': [spec()],
        },
        'not a form',
      ],
    });
    expect(l.forms, isEmpty);
    expect(l.skipped, 5);
  });

  for (final root in <Object?>[
    null,
    [],
    {'forms': []},
    {'schema': 2, 'forms': []},
    {'schema': 1},
    {'schema': 1, 'forms': {}},
  ]) {
    test('root $root throws FormatException', () {
      expect(() => parseLibrary(root), throwsFormatException);
    });
  }

  test('unknown fields are ignored', () {
    final l = parseLibrary({
      'schema': 1,
      'future': true,
      'forms': [
        {
          'id': 'test-x',
          'name': 'Test X',
          'colour': 'red',
          'specs': [
            spec({'rotation': 90}),
          ],
        },
      ],
    });
    expect(l.skipped, 0);
    expect(l.forms.single.specs.single.width, 200);
  });

  test('minKb null gives an empty minimum field', () {
    final sig = parseLibrary(fixture()).forms.first.specs.last;
    expect(sig.minKb, isNull);
    expect(sig.input.minKb, '');
  });

  test('spec.target equals the TargetSpec manual entry of the same values gives', () {
    for (final s in parseLibrary(fixture()).forms.expand((f) => f.specs)) {
      final manual = validateTargetInput(
        TargetInput(
          width: '${s.width}',
          height: '${s.height}',
          minKb: s.minKb == null ? '' : '${s.minKb}',
          maxKb: '${s.maxKb}',
          format: s.format,
        ),
      );
      expect(manual, isA<TargetInputValid>());
      expect((manual as TargetInputValid).spec, s.target);
      expect(validateTargetInput(s.input), isA<TargetInputValid>());
      expect(s.target.format, OutputFormat.jpeg);
    }
  });

  test('AppliedPreset.toString holds no form id', () {
    const p = AppliedPreset(formId: 'test-form-a', kind: SpecKind.photo);
    expect(p.toString(), isNot(contains('test-form-a')));
    expect(p.toString(), isNot(contains('photo')));
    expect(p, const AppliedPreset(formId: 'test-form-a', kind: SpecKind.photo));
  });
}
