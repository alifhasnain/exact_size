import 'dart:math';

import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_reducers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';

SourceInfo src(int w, int h, {int exif = 1}) => SourceInfo(
      rawWidth: w,
      rawHeight: h,
      mime: 'image/jpeg',
      exifOrientation: exif,
      isAnimated: false,
      hasAlpha: false,
      decodePath: DecodePath.region,
    );

/// Inside the image and `min ≤ cw ≤ cover` (ratio is exact by construction:
/// the state stores only cw).
void expectInvariants(CropState s, SourceInfo info, Target t, [String? reason]) {
  final (sw, sh) = CropMath.orientedSize(info, s.quarterTurns);
  final ch = s.cw * t.height / t.width;
  const eps = 1e-6;
  expect(s.cw, greaterThanOrEqualTo(CropMath.minWidth(sw, sh, t) - eps), reason: reason);
  expect(s.cw, lessThanOrEqualTo(CropMath.coverWidth(sw, sh, t) + eps), reason: reason);
  expect(s.cx - s.cw / 2, greaterThanOrEqualTo(-eps), reason: reason);
  expect(s.cx + s.cw / 2, lessThanOrEqualTo(sw + eps), reason: reason);
  expect(s.cy - ch / 2, greaterThanOrEqualTo(-eps), reason: reason);
  expect(s.cy + ch / 2, lessThanOrEqualTo(sh + eps), reason: reason);
}

void main() {
  final info = src(4000, 3000);
  const t = Target(300, 300);
  final start = CropMath.initial(info, t); // cx 2000, cy 1500, cw 3000

  test('drag never leaves the image', () {
    final s = CropReducers.drag(start, 5000, -5000, info, t);
    expect(s.cx, 2500); // right edge: 4000 - 1500
    expect(s.cy, 1500); // cover height = image height
    expectInvariants(s, info, t);
  });

  test('pinch never goes below minimum or above cover', () {
    expect(CropReducers.pinch(start, 100, 2000, 1500, info, t).cw, CropMath.minWidth(4000, 3000, t));
    expect(CropReducers.pinch(start, 0.01, 2000, 1500, info, t).cw, 3000);
  });

  test('pinch keeps the focal point where the clamps allow', () {
    final s = CropReducers.pinch(start, 2, 2000, 1500, info, t); // cw 1500
    expect(s.cw, 1500);
    expect((s.cx, s.cy), (2000.0, 1500.0));
    final off = CropReducers.pinch(start, 2, 1000, 1000, info, t);
    // Focal point (1000, 1000) maps to the same place: cx = 1000 + (2000-1000)·0.5.
    expect((off.cx, off.cy), (1500.0, 1250.0));
  });

  test('a move that hits an edge stops there and reports it', () {
    var r = CropReducers.move(start, MoveDirection.up, info, t);
    expect(r.edgeReached, Edge.top); // cover height: no room vertically
    expect(r.state, start);

    var s = CropReducers.zoom(start, zoomIn: true, info: info, t: t); // cw 2400
    r = CropReducers.move(s, MoveDirection.left, info, t);
    expect(r.edgeReached, Edge.none);
    expect(r.state.cx, s.cx - 2400 * 0.05);

    s = CropReducers.drag(s, -10000, 0, info, t);
    r = CropReducers.move(s, MoveDirection.left, info, t);
    expect(r.edgeReached, Edge.left);
    expect(r.state.cx, 1200);
    r = CropReducers.move(s, MoveDirection.right, info, t);
    expect(r.edgeReached, Edge.none);
    r = CropReducers.move(CropReducers.drag(s, 0, 10000, info, t), MoveDirection.down, info, t);
    expect(r.edgeReached, Edge.bottom);
  });

  test('zoom actions equal pinch with the focal point at the frame centre', () {
    final s = CropReducers.drag(CropReducers.pinch(start, 2, 2000, 1500, info, t), 300, 200, info, t);
    expect(CropReducers.zoom(s, zoomIn: true, info: info, t: t),
        CropReducers.pinch(s, CropReducers.zoomStep, s.cx, s.cy, info, t));
    expect(CropReducers.zoom(s, zoomIn: false, info: info, t: t),
        CropReducers.pinch(s, 1 / CropReducers.zoomStep, s.cx, s.cy, info, t));
  });

  test('centre and reset give the initial state', () {
    final moved = CropReducers.drag(start, 400, 0, info, t);
    expect(CropReducers.centre(moved, info, t), start);
    final zoomed = CropReducers.drag(CropReducers.pinch(start, 3, 100, 100, info, t), 50, 50, info, t);
    expect(CropReducers.reset(info, t), start);
    final c = CropReducers.centre(zoomed, info, t);
    expect((c.cx, c.cy, c.cw), (2000.0, 1500.0, zoomed.cw));
  });

  test('10,000 random reducer sequences keep every invariant', () {
    final rng = Random(11);
    for (var run = 0; run < 100; run++) {
      final si = src(1 + rng.nextInt(9000), 1 + rng.nextInt(9000), exif: 1 + rng.nextInt(8));
      final tt = Target(1 + rng.nextInt(3000), 1 + rng.nextInt(3000));
      var s = CropMath.initial(si, tt);
      final (sw, sh) = CropMath.orientedSize(si, 0);
      for (var step = 0; step < 100; step++) {
        s = switch (rng.nextInt(6)) {
          0 => CropReducers.drag(s, (rng.nextDouble() - 0.5) * sw, (rng.nextDouble() - 0.5) * sh, si, tt),
          1 => CropReducers.pinch(s, 0.2 + rng.nextDouble() * 4, rng.nextDouble() * sw, rng.nextDouble() * sh, si, tt),
          2 => CropReducers.move(s, MoveDirection.values[rng.nextInt(4)], si, tt).state,
          3 => CropReducers.zoom(s, zoomIn: rng.nextBool(), info: si, t: tt),
          4 => CropReducers.centre(s, si, tt),
          _ => CropReducers.reset(si, tt),
        };
        expectInvariants(s, si, tt, 'run $run step $step $s');
      }
    }
  });
}
