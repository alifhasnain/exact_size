import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/presets/domain/preset_types.dart';
import 'package:exact_size/features/presets/presentation/preset_strings.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-011-T03: English preset strings, isolates and code mapping (FR-6, FR-13, FR-14, NFR-4).
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
  const photo = PresetSpec(kind: SpecKind.photo, width: 200, height: 230, minKb: 20, maxKb: 50, format: OutputFormat.jpeg);
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
      final t = PresetStrings(lookupAppLocalizations(l)).summary(photo) + PresetStrings(lookupAppLocalizations(l)).note(const DpiNote(200));
      expect(RegExp('[٠-٩۰-۹०-९]').hasMatch(t), isFalse, reason: '$l');
    }
  });
}
