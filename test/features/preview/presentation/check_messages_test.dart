import 'dart:convert';
import 'dart:io';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/preview/domain/spec_check.dart';
import 'package:exact_size/features/preview/presentation/check_messages.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-006-T06: English check texts (FR-5 to FR-8, FR-16, AC-1.3, AC-3.2, AC-4.6, AC-8.2).
void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  final msg = CheckMessages(l);
  String plain(String s) => s.replaceAll(RegExp('[\u2066-\u2069]'), '');

  String measured(int bytes, TargetSpec t) {
    final m = MeasuredOutput(bytes: bytes, width: t.width, height: t.height, format: t.format, hasAlpha: false);
    return plain(msg.measuredSize(m, checkSpec(m, t)));
  }

  const max50 = TargetSpec(width: 300, height: 300, maxKb: 50, format: OutputFormat.jpeg);
  const min20 = TargetSpec(width: 300, height: 300, minKb: 20, maxKb: 50, format: OutputFormat.jpeg);
  const max100 = TargetSpec(width: 300, height: 300, maxKb: 100, format: OutputFormat.jpeg);

  test('AC-3.2 / FR-6: sizes outside the window round away from the target', () {
    expect(measured(50001, max50), '50.1 KB');
    expect(double.parse(measured(50020, max50).split(' ').first), greaterThan(50.0));
    expect(measured(20000, min20), '19.5 KB');
    expect(measured(48200, max50), '48.2 KB');
  });

  test('AC-1.3: target sizes', () {
    expect(plain(msg.targetSize(max100)), 'Up to 100 KB');
    expect(plain(msg.targetSize(min20)), '20–50 KB');
  });

  test('AC-4.6: alt text holds technical values only, numbers isolated', () {
    final alt = msg.previewAlt(300, 300, OutputFormat.jpeg);
    expect(plain(alt), 'Preview of your new file, 300 × 300 px, JPEG.');
    expect(alt, contains('\u20663,'.replaceAll(',', '')), reason: 'width opens an LTR isolate');
    expect(RegExp('[0-9]').hasMatch(alt.replaceAll(RegExp('\u2066[^\u2069]*\u2069'), '')), isFalse);
  });

  test('pixels, format and the 1,024 line', () {
    expect(plain(msg.pixels(1200, 300)), '1,200 × 300 px');
    expect(plain(msg.format(OutputFormat.png)), 'PNG');
    expect(plain(msg.alsoFits()), 'Also fits if your portal counts 1 KB as 1,024 bytes.');
  });

  test('AC-8.2: row sentence', () {
    final s = msg.rowSentence(l.checkLabelFileSize, msg.targetSize(min20), measured(48200, min20), true);
    expect(plain(s), 'File size: target 20–50 KB, this file 48.2 KB, Meets.');
    expect(plain(msg.rowSentence(l.checkLabelFormat, 'JPEG', 'PNG', false)), "Format: target JPEG, this file PNG, Doesn't meet.");
  });

  test('FR-7: no new English text claims acceptance', () {
    final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = arb.keys.where((k) => !k.startsWith('@') && (k.startsWith('check') || k.startsWith('preview')));
    expect(keys, hasLength(17));
    for (final k in keys) {
      expect((arb[k] as String).toLowerCase(), isNot(matches(RegExp('accept|approve|guarantee'))), reason: k);
    }
  });
}
