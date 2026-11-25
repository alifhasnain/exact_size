import '../../compression/domain/compression_result.dart';

/// What the output file really is, read from its bytes (FR-2, tech 4.1).
final class MeasuredOutput {
  const MeasuredOutput({required this.bytes, required this.width, required this.height, required this.format, required this.hasAlpha});

  final int bytes;
  final int width;
  final int height;
  final OutputFormat format;
  final bool hasAlpha;

  /// Image-derived values stay out of logs and crash reports (NFR-6).
  @override
  String toString() => 'MeasuredOutput(<redacted>)';
}

/// Result of [OutputMeasurer.measure].
sealed class MeasureResult {
  const MeasureResult();
}

final class Measured extends MeasureResult {
  const Measured(this.output);
  final MeasuredOutput output;
}

/// Missing, empty, unopenable, wrong length, or not a JPEG/PNG container (FR-11).
final class Unreadable extends MeasureResult {
  const Unreadable();
}

/// Measures the output file (NFR-6 seam). [expectedBytes] feeds only the FR-11 consistency check.
abstract interface class OutputMeasurer {
  Future<MeasureResult> measure(String path, {required int expectedBytes});
}
