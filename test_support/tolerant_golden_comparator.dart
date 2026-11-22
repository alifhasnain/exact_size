import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter_test/flutter_test.dart';

/// Golden comparator that accepts a small share of differing pixels. Goldens
/// are made on Windows and checked on Linux CI; anti-aliasing and gradient
/// rasterising differ by about 1% of pixels (FEAT-001-T17: 0.4–1.0%). A moved
/// or missing control changes far more than [tolerance].
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.tolerance = 0.015});

  /// Largest accepted share of differing pixels (0.015 = 1.5%).
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Uses [TolerantGoldenComparator] for the rest of the current test file,
/// with the same golden folder as the default comparator. Call from `setUpAll`.
void useTolerantGoldens() {
  final previous = goldenFileComparator;
  final basedir = (previous as LocalFileComparator).basedir;
  goldenFileComparator = TolerantGoldenComparator(basedir.resolve('golden_test.dart'));
  addTearDown(() => goldenFileComparator = previous);
}
