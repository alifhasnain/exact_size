import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'library_rules.dart';

/// FEAT-011-T04 (FR-19, AC-7.1..7.3): the shipped preset file passes the CI rules, and each
/// rule fails as expected with a message naming the form id, kind and rule.
void main() {
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, Object?>;
  final countries = selectCases(en['presetCountry']! as String)..remove('other');
  final categories = selectCases(en['presetCategory']! as String);
  final now = DateTime.now();

  test('the shipped file passes every rule', () {
    final shipped = jsonDecode(File('assets/presets/presets.json').readAsStringSync());
    expect(libraryProblems(shipped, today: now, countries: countries, categories: categories, shipped: true), isEmpty);
  });

  test('the ARB holds the four category cases and no ZZ country', () {
    expect(categories, {'job', 'exam_admission', 'visa_passport', 'other'});
    expect(countries, isNot(contains('ZZ')));
  });

  group('self-tests', () {
    final today = DateTime(2026, 11, 27);
    Map<String, Object?> fixture() =>
        jsonDecode(File('test/presets/fixtures/test_library.json').readAsStringSync()) as Map<String, Object?>;
    List<String> check(Map<String, Object?> json, {bool shipped = false}) =>
        libraryProblems(json, today: today, countries: {'ZZ', 'XY'}, categories: categories, shipped: shipped);
    Map<String, Object?> formA(Map<String, Object?> json) => (json['forms']! as List).first as Map<String, Object?>;
    Map<String, Object?> photoA(Map<String, Object?> json) => (formA(json)['specs']! as List).first as Map<String, Object?>;

    test('the fixture passes with its own key set', () => expect(check(fixture()), isEmpty));

    final cases = <String, (void Function(Map<String, Object?>), String)>{
      'width 0 (AC-7.1)': ((j) => photoA(j)['width'] = 0, 'Form test-form-a photo: size outside engine limits.'),
      'min 10 with max 5 (AC-7.1)': (
        (j) => photoA(j)
          ..['minKb'] = 10
          ..['maxKb'] = 5,
        'Form test-form-a photo: KB range invalid.',
      ),
      'width 15 px (AC-7.1)': ((j) => photoA(j)['width'] = 15, 'Form test-form-a photo: size outside engine limits.'),
      'missing source title (AC-7.2)': (
        (j) => (formA(j)['source']! as Map)['title'] = '',
        'Form test-form-a: source title and a valid last-checked date are required.',
      ),
      'missing lastChecked (AC-7.2)': (
        (j) => formA(j).remove('lastChecked'),
        'Form test-form-a: source title and a valid last-checked date are required.',
      ),
      'a future date (AC-7.2)': (
        (j) => formA(j)['lastChecked'] = '2026-11-28',
        'Form test-form-a: source title and a valid last-checked date are required.',
      ),
      'an impossible date': (
        (j) => formA(j)['lastChecked'] = '2026-02-30',
        'Form test-form-a: source title and a valid last-checked date are required.',
      ),
      'duplicate id (AC-7.3)': (
        (j) => ((j['forms']! as List)[1] as Map)['id'] = 'test-form-a',
        'Form id test-form-a is duplicated or not a valid slug.',
      ),
      'unknown field': ((j) => photoA(j)['rotation'] = 90, 'Form test-form-a photo: unknown field rotation.'),
      'non-slug id': ((j) => formA(j)['id'] = 'Test_Form', 'Form id Test_Form is duplicated or not a valid slug.'),
      'dpi 0': (
        (j) => photoA(j)['notCovered'] = [
          {'code': 'dpi', 'dpi': 0},
        ],
        'Form test-form-a photo: unknown or repeated note.',
      ),
      'dpi 1201': (
        (j) => photoA(j)['notCovered'] = [
          {'code': 'dpi', 'dpi': 1201},
        ],
        'Form test-form-a photo: unknown or repeated note.',
      ),
      'repeated note': (
        (j) => photoA(j)['notCovered'] = [
          {'code': 'background'},
          {'code': 'background'},
        ],
        'Form test-form-a photo: unknown or repeated note.',
      ),
      'country without a key': ((j) => formA(j)['country'] = 'QQ', 'Form test-form-a: country QQ has no string key.'),
      'repeated kind': (
        (j) => ((formA(j)['specs']! as List)[1] as Map)['kind'] = 'photo',
        'Form test-form-a: 1–2 specs, one per kind.',
      ),
      'format webp': ((j) => photoA(j)['format'] = 'webp', 'Form test-form-a photo: format must be jpeg or png.'),
      'missing issuer': ((j) => formA(j)['issuer'] = ' ', 'Form test-form-a: name and issuer are required.'),
      'unknown category': ((j) => formA(j)['category'] = 'sports', 'Form test-form-a: unknown category.'),
    };
    for (final MapEntry(key: name, value: (plant, message)) in cases.entries) {
      test(name, () {
        final json = fixture();
        plant(json);
        expect(check(json), contains(message));
      });
    }

    test('a KB-only spec (width and height null) passes (FR-3, 2.0)', () {
      final json = fixture();
      photoA(json)
        ..['width'] = null
        ..['height'] = null
        ..['minKb'] = 10
        ..['maxKb'] = 200;
      expect(check(json), isEmpty);
    });

    test('only one of width and height null fails naming id and kind', () {
      final json = fixture();
      photoA(json)['height'] = null;
      expect(check(json), contains('Form test-form-a photo: give both width and height, or neither.'));
      expect(check(json), isNot(contains('Form test-form-a photo: size outside engine limits.')));
    });

    test('a KB-only spec with maxKb null fails "KB range invalid."', () {
      final json = fixture();
      photoA(json)
        ..['width'] = null
        ..['height'] = null
        ..['maxKb'] = null;
      expect(check(json), contains('Form test-form-a photo: KB range invalid.'));
    });

    test('a missing width key still fails as a missing field', () {
      final json = fixture();
      photoA(json).remove('width');
      expect(check(json), contains('Form test-form-a photo: missing field width.'));
    });

    test('a test- id in the shipped file', () {
      expect(check(fixture(), shipped: true), contains('Form test-form-a: test entries must not ship (FR-1).'));
    });

    test('selectCases reads top-level cases only', () {
      expect(selectCases('{code, select, IN{India} BD{Bangladesh {x}} other{{code}}}'), {'IN', 'BD', 'other'});
    });
  });
}
