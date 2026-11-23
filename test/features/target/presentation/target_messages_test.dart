import 'dart:convert';
import 'dart:io';

import 'package:exact_size/features/compression/domain/target_validator.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/target_check.dart';
import 'package:exact_size/features/target/domain/target_hints.dart';
import 'package:exact_size/features/target/domain/target_input.dart';
import 'package:exact_size/features/target/presentation/target_messages.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// FEAT-005-T08: every TargetError and hint has text; limits and sizes come
/// from shared constants, formatted for the locale, in bidi isolates.
void main() {
  late TargetMessages m;
  setUp(() async => m = TargetMessages(await AppLocalizations.delegate.load(const Locale('en'))));

  const errors = <TargetError>[
    PixelRangeError(TargetDimensionsMessage.sideOutOfRange),
    PixelRangeError(TargetDimensionsMessage.tooManyPixels),
    PixelsNotWhole(),
    KbError(TargetMessage.maxOutOfRange),
    KbError(TargetMessage.minNotBelowMax),
    KbError(TargetMessage.wholeNumbersOnly),
    KbError(TargetMessage.invalidNumber),
    KbError(TargetMessage.chooseJpegOrPng),
  ];
  const hints = TargetHints(photoWidth: 4000, photoHeight: 3000, canUsePhotoSize: true, enlarges: true, verySmall: true);

  test('every TargetError and hint has a non-empty English string', () {
    for (final e in errors) {
      expect(m.error(e).trim(), isNotEmpty, reason: '$e');
    }
    expect(m.error(const PixelsNotWhole()), 'Use whole numbers of pixels.');
    expect(m.photoSize(hints), 'Your photo: \u20684,000×3,000\u2069 px');
    expect(m.enlarged(const Target(300, 80)), contains('\u2068300×80\u2069'));
    expect(m.verySmall, 'Very small image. Check the size on your form.');
  });

  test('messages carry the shared limits, locale-formatted and isolated (NFR-4, NFR-5)', () {
    final n = NumberFormat.decimalPattern('en');
    expect(m.error(const PixelRangeError(TargetDimensionsMessage.sideOutOfRange)), contains('\u2068${n.format(maxTargetSide)}\u2069'));
    expect(m.error(const KbError(TargetMessage.maxOutOfRange)), contains(n.format(maxKbLimit)));
    expect(m.error(const KbError(TargetMessage.maxOutOfRange)), contains('\u2068${n.format(minMaxKb)}\u2069'));
    // maxTargetPixels appears in no message text: the too-large message has no number (PRD section 8).
    expect(m.error(const PixelRangeError(TargetDimensionsMessage.tooManyPixels)), isNot(contains(n.format(maxTargetPixels))));
  });

  test('new target ARB messages carry no literal numbers and have descriptions', () {
    final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    const keys = [
      'targetPixelsNotWhole', 'targetLabelWidth', 'targetLabelHeight', 'targetLabelMin', 'targetLabelMax', 'targetOptional', //
      'targetUnitPx', 'targetUnitKb', 'targetFormatLabel', 'targetPhotoSize', 'targetUsePhotoSize', 'targetHintVerySmall',
    ];
    for (final k in keys) {
      expect(arb[k], isA<String>(), reason: k);
      expect(RegExp(r'[0-9]').hasMatch(arb[k] as String), isFalse, reason: k);
      expect(((arb['@$k'] as Map)['description'] as String).trim(), isNotEmpty, reason: k);
    }
    expect(((arb['@targetPhotoSize'] as Map)['placeholders'] as Map).keys, ['size']);
  });
}
