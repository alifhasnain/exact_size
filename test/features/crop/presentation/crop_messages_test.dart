import 'dart:convert';
import 'dart:io';

import 'package:exact_size/features/crop/domain/crop_reducers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/target_check.dart';
import 'package:exact_size/features/crop/presentation/crop_messages.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-002-T10: crop strings and CropMessages (FR-22, NFR-6, AC-10.1, AC-10.3).
void main() {
  CropMessages messages(String locale) => CropMessages(lookupAppLocalizations(Locale(locale)));
  final iso = RegExp('\u2068([^\u2069]*)\u2069');
  String plain(String s) => s.replaceAll(RegExp('[\u2068\u2069]'), '');
  const strip = Target(300, 80);

  /// Every text the mapping can produce.
  List<String> allTexts(CropMessages m) => [
        for (final r in Reason.values) m.reason(r),
        for (final t in TargetDimensionsMessage.values) m.target(t),
        m.upscaleNotice(1.5, strip)!,
        m.confirmEnlarge(2.5),
        m.animatedNotice,
        m.limitedPrecisionHint,
        for (final l in UpscaleLevel.values) m.upscaleAnnouncement(l, 2.5, strip),
        for (final p in CropPosition.values) m.areaState(1.5, p),
        for (final e in Edge.values.where((e) => e != Edge.none)) m.edgeReached(e)!,
        for (final c in Corner.values) m.handleLabel(c),
      ];

  test('every Reason and notice has a non-empty English text', () {
    for (final t in allTexts(messages('en'))) {
      expect(plain(t).trim(), isNotEmpty);
    }
    expect(messages('en').upscaleNotice(1.0, strip), isNull);
    expect(messages('en').edgeReached(Edge.none), isNull);
  });

  test('English text matches PRD section 8', () {
    final m = messages('en');
    expect(plain(m.reason(Reason.invalidTargetDimensions)), 'Enter a width and height between 1 and 10,000 pixels.');
    expect(plain(m.reason(Reason.invalidTargetDimensions, targetMessage: TargetDimensionsMessage.tooManyPixels)),
        'That size is too large for this app. Choose a smaller size.');
    expect(m.reason(Reason.imageTooLarge), 'This photo is too large to open on this device. Choose another photo.');
    expect(m.reason(Reason.unsupportedInput), "This file type isn't supported on this device. Choose a JPEG or PNG photo.");
    expect(m.reason(Reason.corruptInput), "We can't read this file. Choose another photo.");
    expect(m.reason(Reason.sourceUnavailable), "We can't find this photo anymore. Please choose it again.");
    expect(m.reason(Reason.outOfMemoryHandled), 'This photo is too large for this device. Try a smaller photo.');
    expect(m.reason(Reason.internalError), 'Something went wrong preparing your image. Please try again.');
    expect(plain(m.upscaleNotice(1.2, strip)!),
        'This photo is smaller than 300×80 px, so it will be enlarged and may look soft.');
    expect(plain(m.confirmEnlarge(2.5)),
        'This photo is much smaller than needed (2.5× enlargement) and may look blurry. Continue anyway?');
    expect(plain(m.confirmEnlarge(3)), contains('(3× enlargement)'));
    expect(m.animatedNotice, 'This image is animated. Only the first frame is used.');
    expect(plain(m.areaState(1, CropPosition.centre)), 'Crop area, zoom 100%, showing the centre of the photo');
    expect(m.edgeReached(Edge.left), 'Reached the left edge.');
    expect(m.handleLabel(Corner.topLeft), 'Resize crop, top-left corner');
  });

  test('upscale levels follow FR-11 thresholds', () {
    expect(UpscaleLevel.of(1.0), UpscaleLevel.none);
    expect(UpscaleLevel.of(1.01), UpscaleLevel.enlarged);
    expect(UpscaleLevel.of(2.0), UpscaleLevel.enlarged);
    expect(UpscaleLevel.of(2.01), UpscaleLevel.strong);
  });

  test('in Arabic every number and "300×80" is inside bidi isolates and in reading order', () {
    final l = lookupAppLocalizations(const Locale('ar'));
    final m = CropMessages(l);
    for (final t in allTexts(m)) {
      final outside = t.replaceAll(iso, '');
      expect(RegExp(r'[0-9٠-٩]').hasMatch(outside), isFalse, reason: t);
    }
    final notice = m.upscaleNotice(1.5, strip)!;
    final sizeText = iso.firstMatch(notice)!.group(1)!;
    expect(sizeText, l.pixelSize('300', '80')); // width first, not reversed
    expect(iso.firstMatch(m.confirmEnlarge(2.5))!.group(1), '2.5');
  });

  test('crop ARB messages carry no literal numbers (values come from placeholders)', () {
    final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final crop = arb.entries.where((e) => (e.key.startsWith('crop') || e.key == 'pixelSize') && !e.key.startsWith('@'));
    expect(crop, isNotEmpty);
    for (final e in crop) {
      expect(RegExp(r'[0-9]').hasMatch(e.value as String), isFalse, reason: e.key);
    }
  });

  test('gen-l10n lists the crop strings as untranslated for the 5 other languages (FEAT-019)', () {
    final untranslated = jsonDecode(File('docs/l10n/untranslated_messages.json').readAsStringSync()) as Map<String, dynamic>;
    expect(untranslated.keys.toSet(), {'ar', 'es', 'hi', 'id', 'pt', 'pt_BR'});
    for (final keys in untranslated.values) {
      expect(keys as List, containsAll(['cropSourceTooLarge', 'cropNoticeEnlarged', 'cropAreaState', 'pixelSize']));
    }
  });
}
