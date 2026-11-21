import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/crop_math.dart';
import '../domain/crop_reducers.dart';
import '../domain/crop_types.dart';
import 'crop_messages.dart';

/// Non-gesture crop actions: TalkBack custom actions (FR-5) and the visible
/// buttons (FR-5, FR-21, FR-27). Each calls the same reducer as the gesture.
enum CropAction {
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  zoomIn,
  zoomOut,
  centre,
  reset,
  rotateClockwise,
  rotateCounterclockwise,
}

/// Something to announce politely (AC-9.1, AC-9.3, AC-9.4). Typed, so the
/// controller needs no localisation; [CropAnnouncement.text] renders it.
/// Carries no file name, path or EXIF value.
sealed class CropAnnouncement {
  const CropAnnouncement();

  String text(CropMessages m, Target t) => switch (this) {
        AreaStateAnnouncement(:final zoom, :final position) => m.areaState(zoom, position),
        EdgeAnnouncement(:final edge) => m.edgeReached(edge)!,
        UpscaleAnnouncement(:final level, :final factor) => m.upscaleAnnouncement(level, factor, t),
      };
}

/// Crop area state after an action: zoom relative to cover, part of the photo shown.
final class AreaStateAnnouncement extends CropAnnouncement {
  const AreaStateAnnouncement(this.zoom, this.position);
  final double zoom;
  final CropPosition position;
}

final class EdgeAnnouncement extends CropAnnouncement {
  const EdgeAnnouncement(this.edge);
  final Edge edge;
}

/// The upscale level crossed 1.0 or 2.0 (FR-11).
final class UpscaleAnnouncement extends CropAnnouncement {
  const UpscaleAnnouncement(this.level, this.factor);
  final UpscaleLevel level;
  final double factor;
}

/// Crop state of the current flow session; nothing is persisted (FR-13, FR-20).
final class CropSession {
  const CropSession({required this.info, required this.target, required this.crop, this.announcements = const []});

  final SourceInfo info;
  final Target target;
  final CropState crop;

  /// Announcements produced by the last update, in order; empty for most
  /// gesture updates.
  final List<CropAnnouncement> announcements;

  CropRect get cropRect => CropMath.toCropRect(crop, info, target);
  double get upscaleFactor => CropMath.upscaleFactor(cropRect, target);
  UpscaleLevel get upscaleLevel => UpscaleLevel.of(upscaleFactor);
}

/// Kept alive for the flow session (Riverpod 3 providers are not auto-disposed);
/// the flow calls [CropController.end] when it finishes.
final cropControllerProvider = NotifierProvider<CropController, CropSession?>(CropController.new);

/// Holds [CropState] for one flow session and turns gestures and actions into
/// reducer calls and announcements. No widgets.
class CropController extends Notifier<CropSession?> {
  @override
  CropSession? build() => null;

  /// Opens the crop screen for [info] and [target]. Returning to the screen in
  /// the same session with the same source and target keeps the crop, zoom and
  /// rotation (AC-8.4).
  void start(SourceInfo info, Target target) {
    final s = state;
    if (s != null && identical(s.info, info) && s.target == target) {
      state = CropSession(info: s.info, target: s.target, crop: s.crop);
      return;
    }
    state = CropSession(info: info, target: target, crop: CropMath.initial(info, target));
  }

  /// Flow finished or abandoned: drop all state.
  void end() => state = null;

  // Gestures: only an upscale threshold crossing is announced, never each update.

  void drag(double dx, double dy) => _gesture((s, i, t) => CropReducers.drag(s, dx, dy, i, t));

  void pinch(double scale, double fx, double fy) => _gesture((s, i, t) => CropReducers.pinch(s, scale, fx, fy, i, t));

  void handle(Corner corner, double dx, double dy) =>
      _gesture((s, i, t) => CropReducers.handle(s, corner, dx, dy, i, t));

  /// Runs [action] through the same reducers as the gestures and announces the
  /// new state, or the edge reached, plus any upscale threshold crossing.
  void perform(CropAction action) {
    final s = state;
    if (s == null) return;
    final (info, t, c) = (s.info, s.target, s.crop);
    Edge edge = Edge.none;
    CropState move(MoveDirection d) {
      final r = CropReducers.move(c, d, info, t);
      edge = r.edgeReached;
      return r.state;
    }

    final next = switch (action) {
      CropAction.moveLeft => move(MoveDirection.left),
      CropAction.moveRight => move(MoveDirection.right),
      CropAction.moveUp => move(MoveDirection.up),
      CropAction.moveDown => move(MoveDirection.down),
      CropAction.zoomIn => CropReducers.zoom(c, zoomIn: true, info: info, t: t),
      CropAction.zoomOut => CropReducers.zoom(c, zoomIn: false, info: info, t: t),
      CropAction.centre => CropReducers.centre(c, info, t),
      CropAction.reset => CropReducers.reset(info, t),
      CropAction.rotateClockwise => CropReducers.rotate(c, clockwise: true, info: info, t: t),
      CropAction.rotateCounterclockwise => CropReducers.rotate(c, clockwise: false, info: info, t: t),
    };
    final updated = CropSession(info: info, target: t, crop: next);
    state = CropSession(
      info: info,
      target: t,
      crop: next,
      announcements: [
        if (edge != Edge.none) EdgeAnnouncement(edge) else areaState(updated),
        ?_upscaleChange(s, updated),
      ],
    );
  }

  void _gesture(CropState Function(CropState, SourceInfo, Target) reduce) {
    final s = state;
    if (s == null) return;
    final next = CropSession(info: s.info, target: s.target, crop: reduce(s.crop, s.info, s.target));
    state = CropSession(
      info: s.info,
      target: s.target,
      crop: next.crop,
      announcements: [?_upscaleChange(s, next)],
    );
  }

  static UpscaleAnnouncement? _upscaleChange(CropSession before, CropSession after) {
    final level = after.upscaleLevel;
    return level == before.upscaleLevel ? null : UpscaleAnnouncement(level, after.upscaleFactor);
  }

  /// Zoom and position of the crop area, for its label and announcements.
  static AreaStateAnnouncement areaState(CropSession s) {
    final (sw, sh) = CropMath.orientedSize(s.info, s.crop.quarterTurns);
    final c = s.crop;
    final ch = c.cw * s.target.height / s.target.width;
    // Where the crop sits inside the room it can move in, by thirds.
    int third(double centre, double size, double extent) {
      final room = extent - size;
      if (room <= 1e-9) return 1;
      final f = (centre - size / 2) / room;
      return f < 1 / 3 ? 0 : (f > 2 / 3 ? 2 : 1);
    }

    final position = switch ((third(c.cx, c.cw, sw.toDouble()), third(c.cy, ch, sh.toDouble()))) {
      (0, 0) => CropPosition.topLeft,
      (1, 0) => CropPosition.top,
      (2, 0) => CropPosition.topRight,
      (0, 1) => CropPosition.left,
      (2, 1) => CropPosition.right,
      (0, 2) => CropPosition.bottomLeft,
      (1, 2) => CropPosition.bottom,
      (2, 2) => CropPosition.bottomRight,
      _ => CropPosition.centre,
    };
    return AreaStateAnnouncement(CropMath.coverWidth(sw, sh, s.target) / c.cw, position);
  }
}
