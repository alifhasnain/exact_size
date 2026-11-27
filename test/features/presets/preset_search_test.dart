import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/presets/domain/parse_library.dart';
import 'package:exact_size/features/presets/domain/preset_search.dart';
import 'package:exact_size/features/presets/domain/preset_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-011-T07 (FR-8, FR-6, NFR-1, NFR-7, NFR-8): search key, filter, grouping, fuzz.
void main() {
  final fixture = parseLibrary(jsonDecode(File('test/presets/fixtures/test_library.json').readAsStringSync())).forms;
  const spec = PresetSpec(kind: SpecKind.photo, width: 200, height: 200, maxKb: 50, format: OutputFormat.jpeg);
  PresetForm form(
    String id,
    String name,
    String country, {
    String issuer = 'Test Issuer',
    FormCategory c = FormCategory.other,
  }) => PresetForm(
    id: id,
    name: name,
    issuer: issuer,
    country: country,
    category: c,
    source: const PresetSource(title: 't'),
    specs: const [spec],
  );
  final forms = [
    ...fixture,
    form('test-form-2', 'Test Form 2', 'XY'),
    form('test-form-c', 'Test Form C', 'XY', issuer: 'Board of Testing'),
    form('test-forme', 'Test Formé', 'ZZ'),
  ];
  String category(PresetForm f) => switch (f.category) {
    FormCategory.job => 'Jobs',
    FormCategory.examAdmission => 'Exams and admissions',
    FormCategory.visaPassport => 'Visa and passport',
    FormCategory.other => 'Other',
  };
  String country(String code) => switch (code) {
    'ZZ' => 'Zedland',
    'XY' => 'Exland',
    _ => code,
  };
  List<String> ids(String q) => [for (final s in filterForms(forms, q, category, country)) ...s.forms.map((f) => f.id)];

  for (final (i, q) in ['TEST form a', '  test   form  a ', '\u200Ftest\u200F form a', '\u2066Test Form A\u2069'].indexed) {
    test('query $i matches Test Form A (AC-2.2)', () => expect(ids(q), contains('test-form-a')));
  }

  test('Arabic-Indic and Devanagari digits match a form with 2 in its name (AC-2.2)', () {
    expect(ids('test form ٢'), ['test-form-2']);
    expect(ids('test form २'), ['test-form-2']);
  });

  test('diacritics fold both ways', () {
    expect(ids('test forme'), contains('test-forme'));
    expect(ids('TEST FORMÉ'), ['test-forme']);
  });

  test('alias, issuer, country name and category label each match (AC-2.1)', () {
    expect(ids('tfa'), ['test-form-a']);
    expect(ids('board of'), ['test-form-c']);
    expect(ids('exland'), ['test-form-2', 'test-form-c']);
    expect(ids('exams and'), ['test-form-a']);
  });

  test('empty query returns all, sections by country name, forms by name', () {
    final sections = filterForms(forms, '', category, country);
    expect(sections.map((s) => s.name), ['Exland', 'Zedland']);
    expect(sections.last.forms.map((f) => f.id), ['test-form-a', 'test-form-b', 'test-forme']);
    expect(ids(''), hasLength(forms.length));
    expect(
      filterForms(
        forms.reversed.toList(),
        '',
        category,
        country,
      ).map((s) => s.forms.map((f) => f.id).toList()).toList(),
      sections.map((s) => s.forms.map((f) => f.id).toList()).toList(),
    );
  });

  test('no match gives no section', () => expect(filterForms(forms, 'zzzz', category, country), isEmpty));

  test('a 101-character query is cut to 100', () {
    expect(searchKey('a' * 101), 'a' * 100);
    expect(searchKey('${'a' * 99}\u{1F600}'), 'a' * 99); // half a surrogate pair is not kept
  });

  test('1,000 random strings and a 10,000-character paste never throw (NFR-8)', () {
    final r = Random(11);
    const pool = [
      0x0000,
      0x001F,
      0x0041,
      0x00E9,
      0x0301,
      0x0627,
      0x064E,
      0x0662,
      0x0915,
      0x200F,
      0x2066,
      0xD800,
      0xDC00,
      0xFFFF,
    ];
    for (var i = 0; i < 1000; i++) {
      final s = String.fromCharCodes([
        for (var j = 0; j < r.nextInt(150); j++) r.nextBool() ? pool[r.nextInt(pool.length)] : r.nextInt(0x10000),
      ]);
      expect(() => filterForms(forms, s, category, country), returnsNormally);
      expect(searchKey(s).length, lessThanOrEqualTo(100));
    }
    expect(() => filterForms(forms, 'x' * 10000, category, country), returnsNormally);
  });

  test('filter time on the fixture (informational)', () {
    final sw = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      filterForms(fixture, 'test form', category, country);
    }
    final perCall = sw.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print('filterForms per call: ${perCall.toStringAsFixed(1)} µs');
    expect(perCall, lessThan(100000));
  });
}
