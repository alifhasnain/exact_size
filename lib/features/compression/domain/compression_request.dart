import 'compression_result.dart';
import 'pixel_buffer.dart';

/// One compression job (tech.md section 4). Ownership of [pixels] moves to
/// FEAT-004 with the request (ADR-003).
final class CompressionRequest {
  const CompressionRequest({
    required this.pixels,
    required this.maxKb,
    required this.format,
    this.minKb,
    this.dpi,
  });

  final PixelBuffer pixels;
  final int? minKb;
  final int maxKb;
  final OutputFormat format;

  /// From FEAT-010; written into JFIF APP0 or PNG pHYs on every pass.
  final int? dpi;
}
