import 'dart:convert';
import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _info = SourceInfo(
    rawWidth: 4000, rawHeight: 3000, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);

/// FEAT-005-T16: every FEAT-005 key is translated in the 5 other languages,
/// and the target screen renders in all 6 without a missing-key fallback.
void main() {
  const keys = [
    'targetPixelsNotWhole', 'targetLabelWidth', 'targetLabelHeight', 'targetLabelMin', 'targetLabelMax', 'targetOptional', //
    'targetUnitPx', 'targetUnitKb', 'targetFormatLabel', 'targetPhotoSize', 'targetUsePhotoSize', 'targetHintVerySmall',
  ];
  // Same as English on purpose: units, and words that are spelled the same.
  const sameAsEnglish = {
    'targetUnitKb': {'es', 'pt', 'hi', 'id', 'ar'},
    'targetUnitPx': {'es', 'pt'},
    'targetFormatLabel': {'id'},
  };
  Map<String, dynamic> arb(String l) => jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync()) as Map<String, dynamic>;

  test('every FEAT-005 key is in each translated ARB and none is still listed as untranslated', () {
    final en = arb('en');
    final untranslated = jsonDecode(File('docs/l10n/untranslated_messages.json').readAsStringSync()) as Map<String, dynamic>;
    for (final l in ['es', 'pt', 'hi', 'id', 'ar']) {
      final t = arb(l);
      for (final k in keys) {
        expect(t[k], isA<String>(), reason: '$l $k');
        if (!(sameAsEnglish[k]?.contains(l) ?? false)) expect(t[k], isNot(en[k]), reason: '$l $k still English');
        // Same placeholders as English.
        final ph = RegExp(r'\{(\w+)\}');
        expect(ph.allMatches(t[k] as String).map((m) => m[1]).toList(), ph.allMatches(en[k] as String).map((m) => m[1]).toList(),
            reason: '$l $k');
      }
      for (final l2 in [l, if (l == 'pt') 'pt_BR']) {
        expect(((untranslated[l2] as List?) ?? const []).where(keys.contains), isEmpty, reason: l2);
      }
    }
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('target screen renders in $locale', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: ExactSizeApp(locale: locale, home: TargetScreen(info: _info, onContinue: (_) {})),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final l = await AppLocalizations.delegate.load(locale);
      expect(find.text(l.targetUsePhotoSize), findsOneWidget);
      expect(find.text(l.targetFormatLabel), findsOneWidget);
    });
  }
}
