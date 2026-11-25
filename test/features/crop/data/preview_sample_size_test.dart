import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-006-T04: smallest power of two that brings the long side to maxSide or less.
void main() {
  test('maxSide 1080: 6000x4000 needs 8 (750), 2000x1000 needs 2 (1000)', () {
    expect(previewSampleSize(6000, 4000, 1080), 8);
    expect(previewSampleSize(4000, 6000, 1080), 8);
    expect(previewSampleSize(2000, 1000, 1080), 2);
    expect(previewSampleSize(1080, 500, 1080), 1);
  });

  test('default stays 2048 (FEAT-002)', () {
    expect(previewSampleSize(6000, 4000), 4);
    expect(previewSampleSize(2048, 100), 1);
    expect(previewSampleSize(2049, 100), 2);
  });
}
