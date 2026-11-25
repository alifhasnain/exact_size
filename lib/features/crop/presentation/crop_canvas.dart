import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../domain/crop_math.dart';
import '../domain/crop_reducers.dart' show Corner;
import '../domain/crop_types.dart';

/// Where the fixed crop frame sits inside the canvas (FR-4, OQ-14).
final class CropFrameLayout {
  const CropFrameLayout(this.frame, {required this.thin});

  /// Side margin around the frame.
  static const margin = 24.0;

  /// Below this short side the frame is "thin": full width at its true ratio,
  /// with the limited-precision hint.
  static const minShortSide = 48.0;

  final Rect frame;
  final bool thin;

  static CropFrameLayout of(Size canvas, Target t) {
    final r = t.width / t.height;
    final availW = math.max(1.0, canvas.width - 2 * margin), availH = math.max(1.0, canvas.height - 2 * margin);
    var w = math.min(availW, availH * r);
    var h = w / r;
    final thin = math.min(w, h) < minShortSide;
    if (thin && r >= 1) {
      w = availW;
      h = w / r;
    }
    final c = canvas.center(Offset.zero);
    return CropFrameLayout(
      Rect.fromCenter(center: c, width: w, height: math.max(h, 1)),
      thin: thin,
    );
  }
}

/// The crop canvas (FR-4, FR-14, FR-25, NFR-4): the preview painted upright
/// under one matrix (orientation × zoom/pan), a fixed frame at the W:H ratio,
/// dimmed outside, two-tone outline, corner marks and a checkerboard under
/// transparent sources. One finger drags, two fingers pinch; the first
/// gesture holds until every finger lifts. Physical coordinates only: never
/// mirrored in RTL (FR-23).
class CropCanvas extends StatefulWidget {
  const CropCanvas({
    super.key,
    required this.preview,
    required this.info,
    required this.target,
    required this.crop,
    required this.onDrag,
    required this.onPinch,
    required this.onHandle,
    required this.handleLabel,
  });

  /// Display-only decode in raw orientation (FR-25).
  final ui.Image preview;
  final SourceInfo info;
  final Target target;
  final CropState crop;

  /// Crop moves by (dx, dy) oriented source pixels.
  final void Function(double dx, double dy) onDrag;

  /// Zoom by [scale] about (fx, fy) in oriented source pixels.
  final void Function(double scale, double fx, double fy) onPinch;

  /// Corner handle moved by (dx, dy) oriented source pixels (FR-28).
  final void Function(Corner corner, double dx, double dy) onHandle;

  /// TalkBack label per handle ("Resize crop, top-left corner").
  final String Function(Corner corner) handleLabel;

  /// The booth cabin behind the photo, in both themes (crop screen brief).
  static const background = Color(0xFF1F0B10);

  /// Handle touch target side (FR-28, NFR-4).
  static const handleTarget = 48.0;

  /// Touch areas of the four handles, at the physical corners of [frame].
  /// When the frame is under 96 dp in a dimension, the areas are pushed
  /// outward so they never overlap (AC-13.6).
  static Map<Corner, Rect> handleRects(Rect frame) {
    final sx = math.max(0.0, (2 * handleTarget - frame.width) / 2);
    final sy = math.max(0.0, (2 * handleTarget - frame.height) / 2);
    Rect at(double x, double y) => Rect.fromCenter(center: Offset(x, y), width: handleTarget, height: handleTarget);
    return {
      Corner.topLeft: at(frame.left - sx, frame.top - sy),
      Corner.topRight: at(frame.right + sx, frame.top - sy),
      Corner.bottomLeft: at(frame.left - sx, frame.bottom + sy),
      Corner.bottomRight: at(frame.right + sx, frame.bottom + sy),
    };
  }

  @override
  State<CropCanvas> createState() => _CropCanvasState();
}

enum _Mode { none, drag, pinch, handle }

class _CropCanvasState extends State<CropCanvas> {
  var _mode = _Mode.none;
  var _lastScale = 1.0;
  Corner? _corner;

  /// The fitted frame: the crop always fills it at rest.
  Rect _frame = Rect.zero;

  /// While a handle is dragged the photo stays put and the frame follows the
  /// crop: screen = (source − origin) × k + offset. Null at rest; on release
  /// the view re-fits without touching the crop (FR-28).
  ({double k, Offset origin, Offset offset})? _locked;

  double get _k => _frame.width / widget.crop.cw;
  double get _ch => widget.crop.cw * widget.target.height / widget.target.width;
  Offset get _cropTopLeft => Offset(widget.crop.cx - widget.crop.cw / 2, widget.crop.cy - _ch / 2);

  /// Where the crop is drawn now.
  Rect get _shown {
    final v = _locked;
    if (v == null) return _frame;
    final tl = (_cropTopLeft - v.origin) * v.k + v.offset;
    return Rect.fromLTWH(tl.dx, tl.dy, widget.crop.cw * v.k, _ch * v.k);
  }

  void _start(ScaleStartDetails d) {
    _lastScale = 1; // the recognizer restarts its scale when a finger joins
    // The first gesture holds until every finger lifts, except that a drag
    // turns into a pinch when a second finger joins before any movement.
    if (_mode == _Mode.handle || _mode == _Mode.pinch) return;
    if (d.pointerCount >= 2) {
      _mode = _Mode.pinch;
      return;
    }
    final hit = CropCanvas.handleRects(_frame).entries.where((e) => e.value.contains(d.localFocalPoint)).firstOrNull;
    if (hit == null) {
      _mode = _Mode.drag;
      return;
    }
    _mode = _Mode.handle;
    _corner = hit.key;
    setState(() => _locked = (k: _k, origin: _cropTopLeft, offset: _frame.topLeft));
  }

  void _update(ScaleUpdateDetails d) {
    if (_frame.isEmpty) return;
    switch (_mode) {
      case _Mode.drag when d.pointerCount == 1:
        // The photo follows the finger, so the crop moves the other way.
        widget.onDrag(-d.focalPointDelta.dx / _k, -d.focalPointDelta.dy / _k);
      case _Mode.pinch when d.pointerCount >= 2:
        final step = d.scale / _lastScale;
        _lastScale = d.scale;
        final fx = _cropTopLeft.dx + (d.localFocalPoint.dx - _frame.left) / _k;
        final fy = _cropTopLeft.dy + (d.localFocalPoint.dy - _frame.top) / _k;
        widget.onPinch(step, fx, fy);
      case _Mode.handle when d.pointerCount == 1:
        final k = _locked!.k;
        widget.onHandle(_corner!, d.focalPointDelta.dx / k, d.focalPointDelta.dy / k);
      default: // a second finger during a handle drag or a drag is ignored
    }
  }

  /// Fingers on the canvas; the scale recognizer does not always report the
  /// last lift (it restarts when a finger joins or leaves).
  var _pointers = 0;

  void _up(PointerEvent _) {
    if (--_pointers > 0) return;
    _pointers = 0;
    _mode = _Mode.none;
    _corner = null;
    if (_locked != null) setState(() => _locked = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _frame = CropFrameLayout.of(box.biggest, widget.target).frame;
        final shown = _shown;
        return Listener(
          onPointerDown: (_) => _pointers++,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _start,
            onScaleUpdate: _update,
            child: Stack(
              children: [
                RepaintBoundary(
                  child: ClipRect(
                    child: CustomPaint(
                      size: box.biggest,
                      painter: _CropPainter(widget.preview, widget.info, widget.target, widget.crop, shown),
                    ),
                  ),
                ),
                // Handle labels for TalkBack at the physical corners (AC-13.7).
                for (final MapEntry(key: corner, value: r) in CropCanvas.handleRects(shown).entries)
                  Positioned.fromRect(
                    rect: r,
                    child: Semantics(
                      container: true,
                      label: widget.handleLabel(corner),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.image, this.info, this.target, this.crop, this.frame);

  final ui.Image image;
  final SourceInfo info;
  final Target target;
  final CropState crop;
  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = CropCanvas.background);
    if (frame.isEmpty) return;
    // Booth light: a warm glow around the frame.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(frame.center, frame.longestSide * 0.9, const [
          Color(0x40FFE3BD),
          Color(0x00FFE3BD),
        ]),
    );
    paintPhoto(canvas, size, image, info, target, crop, frame);

    // Dim outside the frame.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(frame),
      Paint()..color = const Color(0x99000000),
    );

    // Two-tone outline: readable on any photo (NFR-4).
    canvas
      ..drawRect(frame.inflate(2.5), _stroke(const Color(0xFF000000), 1))
      ..drawRect(frame.inflate(1), _stroke(const Color(0xFFFFFFFF), 2));

    // Corner marks (handles, FR-28).
    final len = math.min(20.0, math.max(8.0, frame.shortestSide / 3));
    final marks = Path();
    for (final (cx, cy, sx, sy) in [
      (frame.left, frame.top, 1.0, 1.0),
      (frame.right, frame.top, -1.0, 1.0),
      (frame.left, frame.bottom, 1.0, -1.0),
      (frame.right, frame.bottom, -1.0, -1.0),
    ]) {
      final x = cx - sx * 2, y = cy - sy * 2;
      marks
        ..moveTo(x + sx * len, y)
        ..lineTo(x, y)
        ..lineTo(x, y + sy * len);
    }
    canvas
      ..drawPath(marks, _stroke(const Color(0xFF000000), 6)..strokeCap = StrokeCap.square)
      ..drawPath(marks, _stroke(const Color(0xFFFFFFFF), 4)..strokeCap = StrokeCap.square);
  }

  static Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w;

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.crop != crop || old.frame != frame || old.target != target || old.info != info;
}

/// Paints the preview so the crop region lands exactly on [frame]
/// (raw orientation, sampled → oriented source pixels → screen), with a
/// checkerboard under transparent sources.
void paintPhoto(Canvas canvas, Size size, ui.Image image, SourceInfo info, Target target, CropState crop, Rect frame) {
  final k = frame.width / crop.cw;
  final ch = crop.cw * target.height / target.width;
  final (left, top) = (crop.cx - crop.cw / 2, crop.cy - ch / 2);
  final (sw, sh) = CropMath.orientedSize(info, crop.quarterTurns);
  final imageRect = Rect.fromLTWH(frame.left - left * k, frame.top - top * k, sw * k, sh * k);

  if (info.hasAlpha) paintCheckerboard(canvas, imageRect.intersect(Offset.zero & size));

  final o = CropMath.orientation(info, crop.quarterTurns);
  final (pw, ph) = (image.width, image.height);
  final (ow, oh) = o.orientedSize(pw, ph);
  final (a, b, c, d, tx, ty) = o.matrix(pw, ph);
  canvas
    ..save()
    ..translate(imageRect.left, imageRect.top)
    ..scale(imageRect.width / ow, imageRect.height / oh)
    ..transform(Float64List.fromList([a, c, 0, 0, b, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1]))
    ..drawImage(image, Offset.zero, Paint()..filterQuality = FilterQuality.medium)
    ..restore();
}

/// The print slot (crop screen brief, signature move): the live crop at the
/// output's aspect on photo-paper white, so the applicant sees the exact
/// result while framing.
class CropPrint extends StatelessWidget {
  const CropPrint({
    super.key,
    required this.preview,
    required this.info,
    required this.target,
    required this.crop,
    this.longSide = 64,
  });

  final ui.Image preview;
  final SourceInfo info;
  final Target target;
  final CropState crop;
  final double longSide;

  @override
  Widget build(BuildContext context) {
    final r = target.width / target.height;
    // Very thin targets keep at least a 6 dp short side so the print reads.
    final w = r >= 1 ? longSide : math.max(6.0, longSide * r);
    final h = r >= 1 ? math.max(6.0, longSide / r) : longSide;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF8),
        boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipRect(
          child: CustomPaint(size: Size(w, h), painter: _PrintPainter(preview, info, target, crop)),
        ),
      ),
    );
  }
}

class _PrintPainter extends CustomPainter {
  _PrintPainter(this.image, this.info, this.target, this.crop);
  final ui.Image image;
  final SourceInfo info;
  final Target target;
  final CropState crop;

  @override
  void paint(Canvas canvas, Size size) => paintPhoto(canvas, size, image, info, target, crop, Offset.zero & size);

  @override
  bool shouldRepaint(_PrintPainter old) => old.crop != crop || old.image != image || old.target != target;
}

/// White and light-grey 8 px checks behind transparent pixels (also FEAT-006 FR-15).
void paintCheckerboard(Canvas canvas, Rect r) {
  if (r.isEmpty) return;
  const cell = 8.0;
  canvas
    ..save()
    ..clipRect(r)
    ..drawRect(r, Paint()..color = const Color(0xFFFFFFFF));
  final grey = Paint()..color = const Color(0xFFD0D0D0);
  final x0 = (r.left / cell).floor(), y0 = (r.top / cell).floor();
  for (var y = y0; y * cell < r.bottom; y++) {
    for (var x = x0 + ((y + x0).isOdd ? 1 : 0); x * cell < r.right; x += 2) {
      canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), grey);
    }
  }
  canvas.restore();
}
