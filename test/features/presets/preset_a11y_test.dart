import 'dart:convert';
import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/presets/data/preset_asset_source.dart';
import 'package:exact_size/features/presets/domain/parse_library.dart';
import 'package:exact_size/features/presets/presentation/preset_list_screen.dart';
import 'package:exact_size/features/presets/presentation/preset_providers.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Serves one string as the preset asset.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(utf8.encode(text));
}

const _info = SourceInfo(
  rawWidth: 4000,
  rawHeight: 3000,
  mime: 'image/jpeg',
  exifOrientation: 1,
  isAnimated: false,
  hasAlpha: false,
  decodePath: DecodePath.region,
);

/// FEAT-011-T12 (FR-24, NFR-2, NFR-7, NFR-8, AC-9.1..9.4): guidelines, 200% font, RTL, semantics.
void main() {
  final fixture = File('test/presets/fixtures/test_library.json').readAsStringSync();
  final forms = parseLibrary(jsonDecode(fixture)).forms;
  final isolates = RegExp('[\u2066-\u2069]');

  /// [home] at 360×640 dp with [scale] text, in [locale] (a notifier, so tests can switch it).
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    ValueNotifier<Locale>? locale,
    ValueNotifier<double>? scale,
  }) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final l = locale ?? ValueNotifier(const Locale('en'));
    final s = scale ?? ValueNotifier(1.0);
    final c = ProviderContainer(
      overrides: [presetSourceProvider.overrideWithValue(PresetAssetSource(bundle: _Bundle(fixture), sink: (_) {}))],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: ListenableBuilder(
          listenable: Listenable.merge([l, s]),
          builder: (_, _) => ExactSizeApp(
            locale: l.value,
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(s.value)),
                child: home,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget target() => TargetScreen(info: _info, onContinue: (_) {});
  Widget list() => PresetListScreen(forms: forms);
  Finder specKeys() => find.descendant(of: find.byType(PresetListScreen), matching: find.byType(InkWell));

  for (final (name, home) in [('target row', target), ('form list', list)]) {
    testWidgets('$name: tap targets, labels and text contrast meet the guidelines (NFR-2)', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, home());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  // Every supported locale (T13); en, ar and hi were the G2 set.
  for (final locale in AppLocalizations.supportedLocales) {
    final code = locale.toLanguageTag();
    final l = lookupAppLocalizations(locale);
    testWidgets('$code at 200% on 360×640: no overflow, every spec row reachable, at least 48 dp (AC-9.2, AC-9.4)', (
      tester,
    ) async {
      await pump(tester, list(), locale: ValueNotifier(locale), scale: ValueNotifier(2));
      expect(tester.takeException(), isNull);
      final scrollable = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
      expect(tester.widget<Scrollable>(scrollable).axisDirection, anyOf(AxisDirection.down, AxisDirection.up));
      // One unique text per spec row, so lazily built rows are found once scrolled to.
      for (final unique in [
        find.textContaining('DPI'),
        find.text(l.presetKindSignature),
        find.text(l.presetNoteContent),
      ]) {
        final key = find.ancestor(of: unique, matching: find.byType(InkWell));
        await tester.scrollUntilVisible(key, 80, scrollable: scrollable);
        final r = tester.getRect(key);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(360));
        expect(r.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);

      await pump(tester, target(), locale: ValueNotifier(locale), scale: ValueNotifier(2));
      expect(tester.takeException(), isNull);
      final row = find.ancestor(of: find.byIcon(Icons.list_alt), matching: find.byType(InkWell));
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      expect(tester.getRect(row).right, lessThanOrEqualTo(360));
    });
  }

  testWidgets('ar: mirrored, data names isolated, digits 0-9 only (AC-9.1)', (tester) async {
    await pump(tester, list(), locale: ValueNotifier(const Locale('ar')));
    expect(Directionality.of(tester.element(find.byType(PresetListScreen))), TextDirection.rtl);
    final name = tester.widget<Text>(find.textContaining('Test Form A')).data!;
    expect(name, startsWith('\u2068'));
    expect(name, endsWith('\u2069'));
    final heading = find.textContaining('Test Form A');
    // Start-aligned in RTL: the name sits at the right of its card.
    expect(tester.getRect(heading).right, greaterThan(300));
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      expect(RegExp('[٠-٩۰-۹]').hasMatch(t.data ?? ''), isFalse, reason: t.data);
    }
  });

  testWidgets(
    'one merged node per spec row with name, kind, size, KB, format and note; headings are headers (AC-9.3)',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, list());
      final node = tester.getSemantics(specKeys().first);
      final label = node.label.replaceAll(isolates, '');
      for (final part in ['Test Form A', 'Photo', '200 × 230 px', '20–50 KB', 'JPEG', '200 DPI', 'background']) {
        expect(label, contains(part));
      }
      expect(node.flagsCollection.isButton, isTrue);
      expect(tester.getSemantics(find.text('ZZ')).flagsCollection.isHeader, isTrue);
      expect(tester.getSemantics(find.textContaining('Test Form A')).flagsCollection.isHeader, isTrue);
      handle.dispose();
    },
  );

  testWidgets('a locale or font-scale change with the list open keeps the search text and scroll (NFR-8)', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('en'));
    final scale = ValueNotifier(2.0);
    await pump(tester, list(), locale: locale, scale: scale);
    final scrollable = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pumpAndSettle();
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset, greaterThan(0));

    scale.value = 1.5;
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels, greaterThan(0));

    await tester.enterText(find.byType(TextField), 'test');
    locale.value = const Locale('hi');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'test');
    expect(tester.takeException(), isNull);
  });
}
