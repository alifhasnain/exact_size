import 'dart:convert';
import 'dart:io';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/presets/domain/parse_library.dart';
import 'package:exact_size/features/presets/domain/source_note.dart';
import 'package:exact_size/features/presets/domain/preset_types.dart';
import 'package:exact_size/features/presets/presentation/preset_strings.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-011-T03: English preset strings, isolates and code mapping (FR-6, FR-13, FR-14, NFR-4).
/// FEAT-014-T04: source note lines, prompt choice, missing parts and FR-10 over the shipped forms.
void main() {
  const lri = '\u2066', fsi = '\u2068', pdi = '\u2069';
  final s = PresetStrings(lookupAppLocalizations(const Locale('en')));
  String plain(String t) => t.replaceAll(RegExp('[\u2066-\u2069]'), '');

  const form = PresetForm(
    id: 'test-form-a',
    name: 'Test Form A',
    issuer: 'Test Issuer',
    country: 'ZZ',
    category: FormCategory.examAdmission,
    source: PresetSource(title: 'Test notice 1'),
    specs: [],
  );
  const photo = PresetSpec(
    kind: SpecKind.photo,
    width: 200,
    height: 230,
    minKb: 20,
    maxKb: 50,
    format: OutputFormat.jpeg,
  );
  const sig = PresetSpec(kind: SpecKind.signature, width: 1400, height: 600, maxKb: 2048, format: OutputFormat.png);

  test('summary with a minimum', () {
    final t = s.summary(photo);
    expect(plain(t), '200 × 230 px · 20–50 KB · JPEG');
    expect(t, contains('${lri}200 × 230$pdi'));
    expect(t, contains('${lri}20–50 KB$pdi'));
    expect(t, contains('${lri}JPEG$pdi'));
  });

  test('summary without a minimum, numbers grouped', () {
    final t = s.summary(sig);
    expect(plain(t), '1,400 × 600 px · up to 2,048 KB · PNG');
    expect(t, contains('${lri}2,048 KB$pdi'));
  });

  test('KB-only summary shows "Pixel size not stated" with the KB part isolated (FR-6, 2.0)', () {
    const range = PresetSpec(kind: SpecKind.photo, minKb: 10, maxKb: 200, format: OutputFormat.jpeg);
    const upTo = PresetSpec(kind: SpecKind.photo, maxKb: 200, format: OutputFormat.jpeg);
    expect(plain(s.summary(range)), 'Pixel size not stated · 10–200 KB · JPEG');
    expect(plain(s.summary(upTo)), 'Pixel size not stated · up to 200 KB · JPEG');
    expect(s.summary(range), contains('${lri}10–200 KB$pdi'));
  });

  test('DPI note with 200, fixed notes', () {
    expect(s.note(const DpiNote(200)), 'This form also asks for ${lri}200$pdi DPI. ExactSize does not set DPI.');
    expect(s.note(const BackgroundNote()), contains('does not change backgrounds'));
    expect(s.note(const ContentNote()), contains('does not check them'));
  });

  test('form name in a first-strong isolate on the applied row', () {
    expect(s.applied(form, SpecKind.photo), '${fsi}Test Form A$pdi · Photo');
    expect(s.applied(form, SpecKind.signature), endsWith('· Signature'));
  });

  test('four category labels', () {
    expect(FormCategory.values.map(s.category), ['Jobs', 'Exams and admissions', 'Visa and passport', 'Other']);
  });

  test('an unknown country shows its code', () {
    expect(s.country('ZZ'), 'ZZ');
  });

  test('digits are 0-9 in every locale', () {
    for (final l in AppLocalizations.supportedLocales) {
      final t =
          PresetStrings(lookupAppLocalizations(l)).summary(photo) +
          PresetStrings(lookupAppLocalizations(l)).note(const DpiNote(200));
      expect(RegExp('[٠-٩۰-۹०-९]').hasMatch(t), isFalse, reason: '$l');
    }
  });

  group('FEAT-014 source note', () {
    // Test Form A of the fixture: checked 2026-10-01, so 2026-12-30 is 90 days and 2026-12-31 is 91.
    final a = PresetForm(
      id: 'test-form-a',
      name: 'Test Form A',
      issuer: 'Test Issuer',
      country: 'ZZ',
      category: FormCategory.examAdmission,
      source: const PresetSource(title: 'Test notice 1', url: 'https://notice.example.test/page'),
      lastChecked: DateTime.utc(2026, 10, 1),
      specs: const [],
    );
    PresetForm copy({String? title, String? url, String? issuer, bool noDate = false}) => PresetForm(
      id: a.id,
      name: a.name,
      issuer: issuer ?? a.issuer,
      country: a.country,
      category: a.category,
      source: PresetSource(title: title ?? a.source.title, url: url),
      lastChecked: noDate ? null : a.lastChecked,
      specs: const [],
    );
    const normal = "Check these sizes against your form's notice or instructions before you upload. They can change.";
    final fresh = DateTime(2026, 10, 16);

    test('Test Form A lines with data isolates (AC-1.1, AC-5.1)', () {
      expect(s.sourceLine(a), 'Source: ${fsi}Test notice 1$pdi (${fsi}Test Issuer$pdi)');
      expect(s.websiteLine(a), 'Website: ${lri}notice.example.test$pdi');
      expect(s.checkedLine(a), 'Last checked: ${lri}2026-10-01$pdi');
      expect(s.block(a, fresh), [s.sourceLine(a), s.websiteLine(a), s.checkedLine(a), normal].join('\n'));
      expect(s.cardSource(a), [s.sourceLine(a), s.websiteLine(a), s.checkedLine(a)].join('\n'));
    });

    test('no URL leaves out only the Website line (AC-1.2)', () {
      final c = copy();
      expect(s.websiteLine(c), isNull);
      expect(plain(s.cardSource(c)), 'Source: Test notice 1 (Test Issuer)\nLast checked: 2026-10-01');
    });

    test('prompt switches after 90 days (AC-3.1 to AC-3.3, fixture offsets)', () {
      expect(s.prompt(a, DateTime(2026, 12, 30)), normal);
      expect(plain(s.prompt(a, DateTime(2026, 12, 31))),
          "These sizes were last checked more than 90 days ago. Check your form's notice or instructions before you upload.");
      expect(s.prompt(a, DateTime(2026, 12, 31)), contains('${lri}90$pdi'));
      expect(s.prompt(a, DateTime(2026, 9, 27)), normal);
    });

    test('a missing title, issuer or date leaves out only its line (AC-6.3)', () {
      for (final (f, missing) in [
        (copy(title: ' ', url: a.source.url), s.sourceLine),
        (copy(issuer: '', url: a.source.url), s.sourceLine),
        (copy(noDate: true, url: a.source.url), s.checkedLine),
      ]) {
        expect(missing(f), isNull);
        final lines = s.block(f, fresh).split('\n');
        expect(lines, hasLength(3));
        expect(lines.last, normal);
        expect(s.block(f, fresh), isNot(contains('()')));
      }
      expect(s.prompt(copy(noDate: true), DateTime(2099)), normal);
    });

    test('nothing left gives an empty card text and a block of the prompt only', () {
      final bare = copy(title: '', noDate: true);
      expect(s.cardSource(bare), isEmpty);
      expect(s.block(bare, fresh), normal);
    });

    test('FR-10: every shipped form has its lines in all 6 locales (AC-6.1)', () {
      final raw = jsonDecode(File('assets/presets/presets.json').readAsStringSync()) as Map<String, Object?>;
      final library = parseLibrary(raw);
      expect(library.forms, hasLength((raw['forms']! as List).length), reason: 'a shipped form was dropped');
      expect(library.skipped, 0);
      for (final locale in AppLocalizations.supportedLocales) {
        final t = PresetStrings(lookupAppLocalizations(locale));
        for (final f in library.forms) {
          final date = isoDate(f.lastChecked!);
          final at = '$locale ${f.id}';
          for (final line in [t.sourceLine(f), t.checkedLine(f), t.block(f, fresh), t.cardSource(f)]) {
            expect(line, isNotNull, reason: at);
            expect(line, isNotEmpty, reason: at);
          }
          expect(t.sourceLine(f), contains(f.source.title), reason: at);
          expect(t.checkedLine(f), contains(date), reason: at);
          for (final text in [t.block(f, fresh), t.cardSource(f)]) {
            expect(text, contains(f.source.title), reason: at);
            expect(text, contains(date), reason: at);
          }
        }
      }
    });
  });
}
