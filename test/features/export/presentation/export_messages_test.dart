import 'dart:convert';
import 'dart:io';

import 'package:exact_size/features/export/domain/export_outcome.dart';
import 'package:exact_size/features/export/domain/export_types.dart';
import 'package:exact_size/features/export/presentation/export_messages.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-007-T16: English texts, LTR isolates around names, no literal numbers in the ARB.
void main() {
  final m = ExportMessages(lookupAppLocalizations(const Locale('en')));
  const name = 'exactsize-300x300-[TOKEN].jpg';
  const saved = SavedItem(ref: 'content://[PLACEHOLDER]', displayName: name);
  const lri = '\u2066', pdi = '\u2069';

  test('every outcome that shows a message has a non-empty English text; share and cancel show none', () {
    for (final o in ExportOutcome.values) {
      final text = m.message(o, saved);
      if (o == ExportOutcome.shareOpened || o == ExportOutcome.saveCancelled) {
        expect(text, isNull, reason: o.code);
      } else {
        expect(text?.trim(), isNotEmpty, reason: o.code);
      }
    }
  });

  test('SAVED names folder and file, each as one LTR isolate (FR-11, FR-30)', () {
    expect(m.message(ExportOutcome.saved, saved), 'Saved to ${lri}Pictures/ExactSize$pdi as $lri$name$pdi.');
    expect(m.message(ExportOutcome.alreadySaved, saved), 'Already saved as $lri$name$pdi in ${lri}Pictures/ExactSize$pdi.');
  });

  test('after save-as only the name is shown', () {
    const viaSaveAs = SavedItem(ref: 'content://doc/1', displayName: name, viaSaveAs: true);
    expect(m.message(ExportOutcome.saved, viaSaveAs), 'Saved as $lri$name$pdi.');
    expect(m.message(ExportOutcome.alreadySaved, viaSaveAs), 'Already saved as $lri$name$pdi.');
  });

  test('new export ARB messages carry no literal numbers and have descriptions', () {
    final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = arb.keys.where((k) => k.startsWith('export')).toList();
    expect(keys, hasLength(22)); // FEAT-006-T13 removed the "Ready:" line
    for (final k in keys) {
      expect(RegExp(r'[0-9]').hasMatch(arb[k] as String), isFalse, reason: k);
      expect(((arb['@$k'] as Map)['description'] as String).trim(), isNotEmpty, reason: k);
      expect(arb[k] as String, isNot(contains('\u2066')), reason: '$k: isolates belong in code');
    }
  });
}
