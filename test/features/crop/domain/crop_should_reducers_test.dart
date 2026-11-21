import 'dart:math';

import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_reducers.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'crop_reducers_test.dart' show expectInvariants, src;

/// (x0, y0, x1, y1) of the crop region.
(double, double, double, double) box(CropState s, Target t) {
  final ch = s.cw * t.height / t.width;
  return (s.cx - s.cw / 2, s.cy - ch / 2, s.cx + s.cw / 2, s.cy + ch / 2);
}

void main() {
  final info = src(4000, 3000);
  const t = Target(300, 300);
  final start = CropMath.initial(info, t);
  final zoomed = CropReducers.pinch(start, 2, 2000, 1500, info, t); // 1500 wide, centred

  group('corner handle (FR-28, AC-13.1–13.3)', () {
    test('keeps the opposite corner fixed and the ratio exact', () {
      for (final c in Corner.values) {
        final s = CropReducers.handle(zoomed, c, -200, -150, info, t);
        final (ox0, oy0, ox1, oy1) = box(zoomed, t);
        final (x0, y0, x1, y1) = box(s, t);
        final fixed = switch (c) {
          Corner.topLeft => (x1, y1, ox1, oy1),
          Corner.topRight => (x0, y1, ox0, oy1),
          Corner.bottomLeft => (x1, y0, ox1, oy0),
          Corner.bottomRight => (x0, y0, ox0, oy0),
        };
        expect(fixed.$1, closeTo(fixed.$3, 1e-9), reason: '$c');
        expect(fixed.$2, closeTo(fixed.$4, 1e-9), reason: '$c');
        expect(s.cw, isNot(zoomed.cw), reason: '$c');
        expectInvariants(s, info, t, '$c');
      }
    });

    test('dragging outward stops at the image edge', () {
      final s = CropReducers.handle(zoomed, Corner.bottomRight, 5000, 5000, info, t);
      final (x0, y0, _, y1) = box(s, t);
      expect((x0, y0), (1250.0, 750.0)); // anchor unchanged
      expect(y1, closeTo(3000, 1e-9)); // bottom edge reached first
      expectInvariants(s, info, t);
    });

    test('dragging inward stops at the minimum', () {
      final s = CropReducers.handle(zoomed, Corner.topLeft, 5000, 5000, info, t);
      expect(s.cw, CropMath.minWidth(4000, 3000, t));
      expectInvariants(s, info, t);
    });

    test('a zoom action and a handle shrink to the same width give the same crop size (AC-13.7)', () {
      final z = CropReducers.zoom(zoomed, zoomIn: true, info: info, t: t); // 1200 wide
      // Shrink 300 px along the diagonal of a square target: (-150, -150) on the bottom-right handle.
      final h = CropReducers.handle(zoomed, Corner.bottomRight, -300, -300, info, t);
      expect(h.cw, closeTo(z.cw, 1e-9));
      final rz = CropMath.toCropRect(z, info, t), rh = CropMath.toCropRect(h, info, t);
      expect((rh.w, rh.h), (rz.w, rz.h));
    });
  });

  group('90° rotate (FR-21, AC-12.1, AC-12.2)', () {
    test('four rotations in one direction return the original state', () {
      for (final s0 in [start, zoomed, CropReducers.drag(zoomed, 300, 200, info, t)]) {
        for (final cw in [true, false]) {
          var s = s0;
          for (var i = 0; i < 4; i++) {
            s = CropReducers.rotate(s, clockwise: cw, info: info, t: t);
          }
          expect(s.quarterTurns, s0.quarterTurns);
          expect(s.cx, closeTo(s0.cx, 1e-9));
          expect(s.cy, closeTo(s0.cy, 1e-9));
          expect(s.cw, closeTo(s0.cw, 1e-9));
        }
      }
    });

    test('initial crop of a wide target re-fits to full cover after each turn', () {
      const strip = Target(300, 80);
      var s = CropMath.initial(info, strip);
      s = CropReducers.rotate(s, clockwise: true, info: info, t: strip);
      expect(s.cw, 3000); // 3000×4000 oriented: cover = full width
      s = CropReducers.rotate(s, clockwise: false, info: info, t: strip);
      expect(s, CropMath.initial(info, strip));
    });

    test('after any rotation no empty area is inside the frame', () {
      final rng = Random(5);
      for (var i = 0; i < 2000; i++) {
        final si = src(1 + rng.nextInt(6000), 1 + rng.nextInt(6000), exif: 1 + rng.nextInt(8));
        final tt = Target(1 + rng.nextInt(2000), 1 + rng.nextInt(2000));
        var s = CropMath.initial(si, tt);
        final (sw, sh) = CropMath.orientedSize(si, 0);
        s = CropReducers.pinch(s, 1 + rng.nextDouble() * 6, rng.nextDouble() * sw, rng.nextDouble() * sh, si, tt);
        s = CropReducers.rotate(s, clockwise: rng.nextBool(), info: si, t: tt);
        expectInvariants(s, si, tt, '$si $tt $s');
        s = CropReducers.handle(s, Corner.values[rng.nextInt(4)], (rng.nextDouble() - .5) * sw, (rng.nextDouble() - .5) * sh, si, tt);
        expectInvariants(s, si, tt, 'handle $s');
      }
    });
  });
}
