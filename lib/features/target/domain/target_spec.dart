import '../../compression/domain/compression_request.dart';
import '../../compression/domain/compression_result.dart';
import '../../compression/domain/pixel_buffer.dart';
import '../../crop/domain/crop_types.dart';

/// A validated target (FEAT-005 tech section 4): output size for crop
/// (FEAT-002) and the KB range and format for compression (FEAT-004).
/// Only `validateTargetInput` builds one from user text.
final class TargetSpec {
  const TargetSpec({required this.width, required this.height, this.minKb, required this.maxKb, required this.format});

  final int width;
  final int height;
  final int? minKb;
  final int maxKb;
  final OutputFormat format;

  /// FEAT-002 output size.
  Target get dimensions => Target(width, height);

  /// FEAT-004 job; ownership of [pixels] moves with the request (ADR-003).
  CompressionRequest request(PixelBuffer pixels) =>
      CompressionRequest(pixels: pixels, minKb: minKb, maxKb: maxKb, format: format);

  @override
  bool operator ==(Object other) =>
      other is TargetSpec &&
      other.width == width &&
      other.height == height &&
      other.minKb == minKb &&
      other.maxKb == maxKb &&
      other.format == format;

  @override
  int get hashCode => Object.hash(width, height, minKb, maxKb, format);

  /// The user's numbers stay out of logs and crash reports (FR-14).
  @override
  String toString() => 'TargetSpec(<redacted>)';
}
