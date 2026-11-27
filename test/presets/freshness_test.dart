import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/presets/freshness.dart';

/// FEAT-011-T06 (FR-21, AC-7.4): forms checked more than 90 days ago are listed with their date.
void main() {
  test('the shipped file has 0 forms', () {
    expect(freshnessReport(File('assets/presets/presets.json').readAsStringSync(), DateTime.now()), ['forms: 0']);
  });

  test('the fixture on 2027-02-01 lists Test Form A only', () {
    // Test Form A was checked 2026-10-01 (123 days), Test Form B 2026-11-20 (73 days).
    final text = File('test/presets/fixtures/test_library.json').readAsStringSync();
    expect(freshnessReport(text, DateTime(2027, 2, 1)), ['forms: 2', 'test-form-a 2026-10-01']);
  });

  test('exactly 90 days is not listed; 91 is', () {
    const one = '{"schema": 1, "forms": [{"id": "test-x", "lastChecked": "2026-11-01"}]}';
    expect(freshnessReport(one, DateTime(2027, 1, 30)), ['forms: 1']);
    expect(freshnessReport(one, DateTime(2027, 1, 31)), ['forms: 1', 'test-x 2026-11-01']);
  });
}
