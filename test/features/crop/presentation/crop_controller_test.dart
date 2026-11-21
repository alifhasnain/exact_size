import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_reducers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/presentation/crop_controller.dart';
import 'package:exact_size/features/crop/presentation/crop_messages.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const info = SourceInfo(
  rawWidth: 3000,
  rawHeight: 4000,
  mime: 'image/jpeg',
  exifOrientation: 6, // oriented 4000×3000
  isAnimated: false,
  hasAlpha: false,
  decodePath: DecodePath.region,
);
const target = Target(300, 300);

void main() {
  late ProviderContainer container;
  CropController controller() => container.read(cropControllerProvider.notifier);
  CropSession session() => container.read(cropControllerProvider)!;

  setUp(() {
    container = ProviderContainer();
    controller().start(info, target);
  });
  tearDown(() => container.dispose());

  test('each action handler gives the same cropRect as the matching reducer', () {
    controller().pinch(1.6, 1000, 1000); // off-centre and zoomed, so moves are free
    final reducers = <CropAction, CropState Function(CropState)>{
      CropAction.moveLeft: (s) => CropReducers.move(s, MoveDirection.left, info, target).state,
      CropAction.moveRight: (s) => CropReducers.move(s, MoveDirection.right, info, target).state,
      CropAction.moveUp: (s) => CropReducers.move(s, MoveDirection.up, info, target).state,
      CropAction.moveDown: (s) => CropReducers.move(s, MoveDirection.down, info, target).state,
      CropAction.zoomIn: (s) => CropReducers.zoom(s, zoomIn: true, info: info, t: target),
      CropAction.zoomOut: (s) => CropReducers.zoom(s, zoomIn: false, info: info, t: target),
      CropAction.centre: (s) => CropReducers.centre(s, info, target),
      CropAction.reset: (s) => CropReducers.reset(info, target),
      CropAction.rotateClockwise: (s) => CropReducers.rotate(s, clockwise: true, info: info, t: target),
      CropAction.rotateCounterclockwise: (s) => CropReducers.rotate(s, clockwise: false, info: info, t: target),
    };
    expect(reducers.keys.toSet(), CropAction.values.toSet());
    final before = session().crop;
    for (final MapEntry(key: action, value: reduce) in reducers.entries) {
      container.read(cropControllerProvider.notifier)
        ..end()
        ..start(info, target);
      // Restore the same starting crop through the same gesture.
      controller().pinch(1.6, 1000, 1000);
      expect(session().crop, before);
      controller().perform(action);
      expect(session().cropRect, CropMath.toCropRect(reduce(before), info, target), reason: '$action');
    }
  });

  test('a 60-update drag announces nothing; a threshold crossing announces exactly once', () {
    var announcements = 0;
    for (var i = 0; i < 60; i++) {
      controller().drag(3, 2);
      announcements += session().announcements.length;
    }
    expect(announcements, 0);

    // Small source (800×600, cover 600 px) so zooming in can go below 300 px:
    // pinch until the factor first passes 1.0, then keep dragging.
    const small = SourceInfo(
      rawWidth: 800,
      rawHeight: 600,
      mime: 'image/png',
      exifOrientation: 1,
      isAnimated: false,
      hasAlpha: false,
      decodePath: DecodePath.region,
    );
    controller()
      ..end()
      ..start(small, target);
    final seen = <CropAnnouncement>[];
    while (session().upscaleLevel == UpscaleLevel.none) {
      controller().pinch(1.02, 400, 300);
      seen.addAll(session().announcements);
    }
    for (var i = 0; i < 60; i++) {
      controller().drag(i.isEven ? 4 : -4, 0);
      seen.addAll(session().announcements);
    }
    expect(seen, hasLength(1));
    expect((seen.single as UpscaleAnnouncement).level, UpscaleLevel.enlarged);
  });

  test('an edge-reached move announces the edge', () {
    controller().perform(CropAction.moveUp); // cover height: no vertical room
    expect(session().announcements.single, isA<EdgeAnnouncement>().having((a) => a.edge, 'edge', Edge.top));
    controller().perform(CropAction.zoomIn);
    expect(session().announcements.first, isA<AreaStateAnnouncement>());
  });

  test('leaving and re-entering the screen in the same session restores crop, zoom and rotation', () {
    controller()
      ..perform(CropAction.zoomIn)
      ..perform(CropAction.rotateClockwise)
      ..drag(100, 50);
    final kept = session().crop;
    controller().start(info, target); // back on the screen
    expect(session().crop, kept);
    expect(kept.quarterTurns, 1);
  });

  test('ending the flow disposes the state', () {
    controller().perform(CropAction.zoomIn);
    controller().end();
    expect(container.read(cropControllerProvider), isNull);
    controller().start(info, target);
    expect(session().crop, CropMath.initial(info, target));
  });

  test('announcement text contains no file name, path or EXIF value', () {
    final m = CropMessages(lookupAppLocalizations(const Locale('en')));
    final texts = <String>[];
    for (final a in CropAction.values) {
      controller().perform(a);
      texts.addAll(session().announcements.map((x) => x.text(m, target)));
    }
    for (var i = 0; i < 40; i++) {
      controller().perform(CropAction.zoomIn);
      texts.addAll(session().announcements.map((x) => x.text(m, target)));
    }
    expect(texts, isNotEmpty);
    for (final t in texts) {
      expect(
        t.contains('image/') || t.contains('/') || t.toLowerCase().contains('exif') || t.contains('orientation'),
        isFalse,
        reason: t,
      );
    }
  });
}
