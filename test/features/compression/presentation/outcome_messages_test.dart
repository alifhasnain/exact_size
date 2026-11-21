import 'dart:convert';
import 'dart:io';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/target_validator.dart';
import 'package:exact_size/features/compression/presentation/outcome_messages.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-004-T19: OutcomeMessages and English ARB strings (FR-11, NFR-4).
void main() {
  OutcomeMessages messages(String locale) => OutcomeMessages(lookupAppLocalizations(Locale(locale)));
  String plain(String s) => s.replaceAll(RegExp('[\u2068\u2069]'), '');

  const sizeReasons = {
    Reason.aboveMax,
    Reason.tooDegraded,
    Reason.noFit,
    Reason.belowMin,
    Reason.pngAboveMax,
    Reason.pngBelowMin,
  };
  CompressionFailure failureFor(Reason r) => CompressionFailure(
      reason: r,
      closestBytes: sizeReasons.contains(r) ? 61300 : null,
      direction: sizeReasons.contains(r) ? Direction.tooBig : null);

  /// Every message the mapping can produce for [m], with sizes filled in.
  List<String> allTexts(OutcomeMessages m) => [
        for (final r in Reason.values) ...[
          m.failure(failureFor(r), minKb: 20, maxKb: 50).message,
          m.failure(failureFor(r), minKb: null, maxKb: 10240).message,
        ],
        for (final n in Notice.values) m.notice(n),
        for (final t in TargetMessage.values) m.target(t),
        m.internalError,
      ];

  test('every Reason, Notice and TargetMessage has a non-empty English text', () {
    expect(allTexts(messages('en')), everyElement(isNotEmpty));
  });

  test('English matches PRD section 8, with formatted sizes', () {
    final en = messages('en');
    expect(plain(en.failure(failureFor(Reason.aboveMax), minKb: 20, maxKb: 50).message),
        "We can't reach 20–50 KB for this image at this size. Closest: 61.3 KB.");
    expect(plain(en.target(TargetMessage.maxOutOfRange)),
        'Enter a maximum size between 2 and 10,240 KB.');
    expect(en.target(TargetMessage.minNotBelowMax), 'Minimum must be smaller than maximum.');
    expect(en.target(TargetMessage.wholeNumbersOnly), 'Use whole numbers of KB.');
    expect(en.target(TargetMessage.invalidNumber), 'Enter a valid size in KB.');
    expect(en.target(TargetMessage.chooseJpegOrPng), 'Choose JPEG or PNG.');
    expect(en.internalError, 'Something went wrong preparing your image. Please try again.');
    expect(en.notice(Notice.narrowRange),
        'This range is very narrow. Some portals count KB differently, so the file may still be rejected.');
  });

  test('max-only target and large numbers are formatted', () {
    final f = CompressionFailure(reason: Reason.aboveMax, closestBytes: 10500000, direction: Direction.tooBig);
    expect(plain(messages('en').failure(f, minKb: null, maxKb: 10240).message),
        "We can't get this image down to 10,240 KB at this size. Closest: 10,500 KB.");
  });

  test('PNG hints: JPEG switch only when a JPEG would fit; try JPEG below the minimum', () {
    final en = messages('en');
    FailureText png(Reason r, {bool fits = false}) => en.failure(
        CompressionFailure(reason: r, closestBytes: 9000, direction: Direction.tooSmall, jpegWouldFit: fits),
        minKb: 20,
        maxKb: 50);
    expect(png(Reason.pngAboveMax, fits: true).hint, 'A JPEG of this image would fit.');
    expect(png(Reason.pngAboveMax).hint, isNull);
    expect(png(Reason.pngBelowMin).hint, contains('try JPEG'));
    expect(png(Reason.aboveMax).hint, isNull);
  });

  test('achieved size is rounded away from the window, never into it', () {
    expect(achievedKb(50001, Direction.tooBig), 50.1); // max 50 KB = 50,000 B
    expect(achievedKb(61300, Direction.tooBig), 61.3);
    expect(achievedKb(20479, Direction.tooSmall), 19.9); // min 20 KB = 20,480 B
    expect(achievedKb(20000, Direction.tooSmall), 19.5);
    expect(achievedKb(1234, null), 1.2);
  });

  // A number's "KB" is inside the same isolate, so checking digits covers it.
  // "KB" in a sentence without a number ("Use whole numbers of KB.") is a
  // word for translators, not a size, and needs no isolate.
  test('in Arabic every number and its "KB" is inside bidi isolates', () {
    final ar = messages('ar');
    final texts = [
      ...allTexts(ar),
      ar.failure(
          const CompressionFailure(reason: Reason.belowMin, closestBytes: 20000, direction: Direction.tooSmall),
          minKb: 20,
          maxKb: 50).message,
    ];
    for (final text in texts) {
      expect(_outsideIsolates(text), isNot(matches(RegExp(r'[0-9٠-٩]|[0-9٠-٩]\s*KB'))), reason: text);
    }
    // The checked texts do contain sizes.
    expect(texts.where((t) => t.contains('\u2068')).length, greaterThan(6));
  });

  test('ARB: values come from placeholders, never hard-coded numbers', () {
    final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final messages = {
      for (final e in arb.entries)
        if (!e.key.startsWith('@')) e.key: e.value as String,
    };
    for (final key in ['kbAmount', 'kbRange', 'outcomeCantReachRange', 'outcomeCantReachMax', 'targetMaxOutOfRange']) {
      final placeholders = (arb['@$key'] as Map)['placeholders'] as Map;
      expect(placeholders, isNotEmpty, reason: key);
      for (final name in placeholders.keys) {
        expect(messages[key], contains('{$name}'), reason: key);
      }
    }
    for (final e in messages.entries) {
      expect(e.value, isNot(matches(RegExp('[0-9]'))), reason: '${e.key} has a hard-coded number');
    }
  });

  test('new keys are translated or listed as untranslated in the other locales (for FEAT-019)', () {
    final untranslated = jsonDecode(File('docs/l10n/untranslated_messages.json').readAsStringSync()) as Map<String, dynamic>;
    // Each key is either translated in app_<locale>.arb or still listed as untranslated.
    for (final locale in ['ar', 'es', 'hi', 'id', 'pt', 'pt_BR']) {
      final arb = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
      final pending = (untranslated[locale] as List?) ?? const [];
      for (final key in ['outcomeCantReachRange', 'noticePaddingAdded', 'targetChooseJpegOrPng']) {
        expect(arb.containsKey(key) || pending.contains(key), isTrue, reason: '$locale $key');
      }
    }
  });
}

/// [text] with every isolated run (U+2068 … U+2069, nested) removed.
String _outsideIsolates(String text) {
  final out = StringBuffer();
  var depth = 0;
  for (final ch in text.runes) {
    if (ch == 0x2068) {
      depth++;
    } else if (ch == 0x2069) {
      depth--;
    } else if (depth == 0) {
      out.writeCharCode(ch);
    }
  }
  return out.toString();
}
