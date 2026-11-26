import 'package:exact_size/app.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/pick/presentation/pick_controller.dart';
import 'package:exact_size/features/pick/presentation/pick_messages.dart';
import 'package:exact_size/features/pick/presentation/pick_view.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-001-T18: TalkBack order, focus back on the used button, 200% text,
/// Arabic RTL with unmirrored icons, and every pick string in all 6 languages
/// (NFR-4, NFR-5, AC-7.1, AC-7.2, AC-7.4, AC-3.4).
void main() {
  const en = 'Take a photo';
  const privacy = 'Your photos are resized on your phone. ExactSize never uploads them.'; // FEAT-016 FR-1

  Future<void> pump(WidgetTester tester, PickState state,
      {Locale locale = const Locale('en'), double scale = 1, Size size = const Size(360, 800)}) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ExactSizeApp(
      locale: locale,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: PickView(state: state, onLaunch: (_) {}, onCancel: () {}),
        ),
      ),
    ));
    await tester.pump();
  }

  // Button.icon constructors build private subclasses, so match by subtype.
  Finder button(String label) => find.ancestor(of: find.text(label), matching: find.bySubtype<ButtonStyleButton>()).first;
  Iterable<ButtonStyleButton> buttons(WidgetTester tester) => tester.widgetList<ButtonStyleButton>(find.bySubtype<ButtonStyleButton>());

  testWidgets('TalkBack order: Take a photo, Choose from gallery, Choose from files, privacy line (AC-7.1)', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const PickState(cameraAvailable: true));
    final labels = [for (final n in tester.semantics.simulatedAccessibilityTraversal()) n.label].where((l) => l.isNotEmpty).toList();
    final order = [en, 'Choose from gallery', 'Choose from files', privacy].map(labels.indexOf).toList();
    expect(order, everyElement(isNonNegative), reason: '$labels');
    expect(order, orderedEquals([...order]..sort()), reason: '$labels');
    for (final label in [en, 'Choose from gallery', 'Choose from files']) {
      expect(tester.getSemantics(button(label)), isSemantics(isButton: true, label: label));
    }
    handle.dispose();
  });

  testWidgets('focus returns to the used button after a system screen or Cancel (AC-7.1)', (tester) async {
    bool focused(String label) => tester.widget<ButtonStyleButton>(button(label)).focusNode!.hasFocus;

    await pump(tester, const PickState(cameraAvailable: true, phase: PickPhase.awaitingSystemUi, lastSource: PickSource.gallery));
    await pump(tester, const PickState(cameraAvailable: true, lastSource: PickSource.gallery));
    await tester.pump();
    expect(focused('Choose from gallery'), isTrue);

    // Opening hides the keys; they come back focused on the source used.
    await pump(tester, const PickState(cameraAvailable: true, phase: PickPhase.opening, showProgress: true, lastSource: PickSource.camera));
    expect(find.text(en), findsNothing);
    await pump(tester, const PickState(cameraAvailable: true, lastSource: PickSource.camera));
    await tester.pump();
    expect(focused(en), isTrue);
  });

  for (final (name, size) in [('portrait 360x640', const Size(360, 640)), ('landscape 640x360', const Size(640, 360))]) {
    testWidgets('200% text, $name: no overflow, buttons at least 48 dp, privacy line reachable by scrolling (AC-7.2)', (tester) async {
      for (final state in const [
        PickState(message: PickMessage.lowSpace), // longest message plus the no-camera reason
        PickState(cameraAvailable: true, phase: PickPhase.opening, showProgress: true),
      ]) {
        await pump(tester, state, scale: 2, size: size);
        expect(tester.takeException(), isNull);
        for (final b in buttons(tester)) {
          final box = tester.getSize(find.byWidget(b));
          expect(box.height, greaterThanOrEqualTo(48));
          expect(box.width, greaterThanOrEqualTo(48));
        }
        await tester.scrollUntilVisible(find.text(privacy), 100);
        expect(find.text(privacy).hitTestable(), findsOneWidget);
      }
    });
  }

  testWidgets('Arabic: layout mirrors, camera and gallery icons do not (AC-7.4)', (tester) async {
    await pump(tester, const PickState(cameraAvailable: true), locale: const Locale('ar'));
    final l = lookupAppLocalizations(const Locale('ar'));
    expect(Directionality.of(tester.element(find.byType(PickView))), TextDirection.rtl);
    for (final (icon, label) in [(Icons.photo_camera_outlined, l.pickTakePhoto), (Icons.photo_library_outlined, l.pickChooseGallery)]) {
      expect(icon.matchTextDirection, isFalse);
      final key = button(label);
      final iconX = tester.getCenter(find.descendant(of: key, matching: find.byIcon(icon))).dx;
      final textX = tester.getCenter(find.descendant(of: key, matching: find.text(label))).dx;
      expect(iconX, greaterThan(textX), reason: 'icon leads on the right in RTL');
    }
    // The brand cell sits at the start edge, which is the right in RTL.
    expect(tester.getCenter(find.text(l.appTitle)).dx, greaterThan(180));
  });

  group('privacy line (FR-22, T23)', () {
    for (final locale in const [Locale('en'), Locale('es'), Locale('pt', 'BR'), Locale('hi'), Locale('id'), Locale('ar')]) {
      testWidgets('$locale: last in TalkBack order, unclipped at 200% text', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, const PickState(cameraAvailable: true), locale: locale, scale: 2, size: const Size(360, 640));
        final line = lookupAppLocalizations(locale).pickPrivacyNote;
        expect(tester.takeException(), isNull);
        final labels = [for (final n in tester.semantics.simulatedAccessibilityTraversal()) n.label].where((l) => l.isNotEmpty).toList();
        expect(labels.last, line, reason: '$labels');
        await tester.scrollUntilVisible(find.text(line), 100);
        final text = tester.renderObject<RenderParagraph>(find.text(line));
        expect(text.didExceedMaxLines, isFalse);
        final box = tester.getRect(find.text(line));
        expect(box.left, greaterThanOrEqualTo(0));
        expect(box.right, lessThanOrEqualTo(360));
        handle.dispose();
      });
    }
  });

  group('every pick string in all 6 languages (AC-3.4, NFR-5)', () {
    const locales = [Locale('es'), Locale('pt'), Locale('pt', 'BR'), Locale('hi'), Locale('id'), Locale('ar')];
    List<String> strings(AppLocalizations l) => [
          l.pickTakePhoto,
          l.pickChooseGallery,
          l.pickChooseFiles,
          l.pickPrivacyNote,
          l.pickOpening,
          l.pickNoCamera,
          for (final m in PickMessage.values) m.text(l),
        ];

    test('no translation falls back to English', () {
      final english = strings(lookupAppLocalizations(const Locale('en')));
      for (final locale in locales) {
        final local = strings(lookupAppLocalizations(locale));
        for (var i = 0; i < english.length; i++) {
          expect(local[i], isNot(english[i]), reason: '$locale: ${english[i]}');
        }
      }
    });

    for (final locale in locales) {
      testWidgets('$locale renders each message state without overflow', (tester) async {
        for (final m in PickMessage.values) {
          await pump(tester, PickState(message: m), locale: locale, size: const Size(360, 640));
          expect(tester.takeException(), isNull, reason: '$locale $m');
          expect(find.text(m.text(lookupAppLocalizations(locale))), findsOneWidget);
        }
      });
    }
  });
}
