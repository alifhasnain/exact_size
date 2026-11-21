import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../domain/crop_math.dart';
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
    return CropFrameLayout(Rect.fromCenter(center: c, width: w, height: math.max(h, 1)), thin: thin);
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

  /// The booth cabin behind the photo, in both themes (crop screen brief).
  static const background = Color(0xFF1F0B10);

  @override
  State<CropCanvas> createState() => _CropCanvasState();
}

enum _Mode { none, drag, pinch }

class _CropCanvasState extends State<CropCanvas> {
  var _mode = _Mode.none;
  var _lastScale = 1.0;
  Rect _frame = Rect.zero;

  double get _k => _frame.width / widget.crop.cw;

  void _start(ScaleStartDetails d) {
    _mode = d.pointerCount >= 2 ? _Mode.pinch : _Mode.drag;
    _lastScale = 1;
  }

  void _update(ScaleUpdateDetails d) {
    if (_frame.isEmpty) return;
    if (_mode == _Mode.drag && d.pointerCount == 1) {
      // The photo follows the finger, so the crop moves the other way.
      widget.onDrag(-d.focalPointDelta.dx / _k, -d.focalPointDelta.dy / _k);
    } else if (_mode == _Mode.pinch && d.pointerCount >= 2) {
      final step = d.scale / _lastScale;
      _lastScale = d.scale;
      final c = widget.crop, ch = c.cw * widget.target.height / widget.target.width;
      final fx = c.cx - c.cw / 2 + (d.localFocalPoint.dx - _frame.left) / _k;
      final fy = c.cy - ch / 2 + (d.localFocalPoint.dy - _frame.top) / _k;
      widget.onPinch(step, fx, fy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _frame = CropFrameLayout.of(box.biggest, widget.target).frame;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _start,
        onScaleUpdate: _update,
        onScaleEnd: (d) {
          if (d.pointerCount == 0) _mode = _Mode.none;
        },
        child: RepaintBoundary(
          child: ClipRect(
            child: CustomPaint(
              size: box.biggest,
              painter: _CropPainter(widget.preview, widget.info, widget.target, widget.crop, _frame),
            ),
          ),
        ),
      );
    });
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
        ..shader = ui.Gradient.radial(
            frame.center, frame.longestSide * 0.9, const [Color(0x40FFE3BD), Color(0x00FFE3BD)]),
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

  if (info.hasAlpha) _checkerboard(canvas, imageRect.intersect(Offset.zero & size));

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
  const CropPrint({super.key, required this.preview, required this.info, required this.target, required this.crop, this.longSide = 64});

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

void _checkerboard(Canvas canvas, Rect r) {
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
