import 'package:exact_size/app.dart';
import 'package:exact_size/features/pick/presentation/pick_controller.dart';
import 'package:exact_size/features/pick/presentation/pick_view.dart';
import 'package:exact_size/features/privacy/presentation/privacy_screen.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-016-T15 (NFR-2, NFR-4): the pick-screen entry and the explainer meet the Android
/// accessibility guidelines, survive 200% text at 360x640 and mirror in Arabic.
void main() {
  Future<void> pump(WidgetTester tester, Widget home, {Locale locale = const Locale('en'), double scale = 1}) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ExactSizeApp(
      locale: locale,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: home,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Widget pick() => PickView(
        state: const PickState(cameraAvailable: true),
        onLaunch: (_) {},
        onCancel: () {},
        onPrivacy: () {},
      );

  for (final (name, home) in [('pick screen with entry', pick), ('explainer', () => const PrivacyScreen())]) {
    testWidgets('$name: tap targets, labels and text contrast meet the guidelines (NFR-2)', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, home());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('$locale at 200% on 360x640: no overflow, every part reachable by scrolling, entry reachable', (tester) async {
      final l = lookupAppLocalizations(locale);
      await pump(tester, const PrivacyScreen(), locale: locale, scale: 2);
      expect(tester.takeException(), isNull);
      for (final text in [l.privacyTitle, l.privacyOnPhone, l.privacyReadsTitle, l.privacyReads]) {
        await tester.scrollUntilVisible(find.text(text), 80, scrollable: find.byType(Scrollable).first);
        expect(tester.getRect(find.text(text)).right, lessThanOrEqualTo(360));
      }
      expect(tester.takeException(), isNull);

      await pump(tester, pick(), locale: locale, scale: 2);
      expect(tester.takeException(), isNull);
      final entry = find.widgetWithText(TextButton, l.privacyEntry);
      await tester.scrollUntilVisible(entry, 80, scrollable: find.byType(Scrollable).first);
      expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ar: right to left, headings start at the right edge, Western digits only (NFR-4)', (tester) async {
    await pump(tester, const PrivacyScreen(), locale: const Locale('ar'));
    expect(Directionality.of(tester.element(find.byType(PrivacyScreen))), TextDirection.rtl);
    final l = lookupAppLocalizations(const Locale('ar'));
    // Start-aligned in RTL: the title's right edge sits at the page padding (360 - 24).
    expect(tester.getRect(find.text(l.privacyTitle)).right, closeTo(360 - 24, 0.5));
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      expect(RegExp('[٠-٩۰-۹]').hasMatch(t.data ?? ''), isFalse, reason: t.data);
    }
  });
}
