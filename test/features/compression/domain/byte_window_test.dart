import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-004-T09: FR-3 window and FR-4 narrow-range fallback.
void main() {
  test('20–50 KB → [20,480, 50,000]', () {
    final w = ByteWindow.fromKb(minKb: 20, maxKb: 50);
    expect((w.lo, w.hi, w.narrow), (20480, 50000, false));
  });

  test('49–50 KB is narrow → [49,000, 50,000]', () {
    final w = ByteWindow.fromKb(minKb: 49, maxKb: 50);
    expect((w.lo, w.hi, w.narrow), (49000, 50000, true));
  });

  test('min unset → lo = 0', () {
    final w = ByteWindow.fromKb(maxKb: 50);
    expect((w.lo, w.hi, w.narrow), (0, 50000, false));
  });

  test('boundary of the narrow rule (max/min = 1.024)', () {
    // 125×1024 = 128,000 = 128×1000: exactly fits, not narrow.
    expect(ByteWindow.fromKb(minKb: 125, maxKb: 128).narrow, isFalse);
    expect(ByteWindow.fromKb(minKb: 126, maxKb: 128).narrow, isTrue);
  });

  test('contains is inclusive at both ends', () {
    final w = ByteWindow.fromKb(minKb: 20, maxKb: 50);
    expect([w.contains(20479), w.contains(20480), w.contains(50000), w.contains(50001)],
        [false, true, true, false]);
  });
}
