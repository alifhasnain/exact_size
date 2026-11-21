import '../../compression/domain/pixel_buffer.dart';

/// Failure reasons of the crop and resize step, exactly FEAT-002 FR-16 /
/// tech.md section 4. [code] is the PRD spelling; only codes may be logged.
enum Reason {
  invalidTargetDimensions('INVALID_TARGET_DIMENSIONS'),
  unsupportedInput('UNSUPPORTED_INPUT'),
  corruptInput('CORRUPT_INPUT'),
  sourceUnavailable('SOURCE_UNAVAILABLE'),
  imageTooLarge('IMAGE_TOO_LARGE'),
  outOfMemoryHandled('OUT_OF_MEMORY_HANDLED'),
  cancelled('CANCELLED'),
  internalError('INTERNAL_ERROR');

  const Reason(this.code);
  final String code;
}

/// Output size in pixels, from FEAT-005 or a FEAT-011 preset.
final class Target {
  const Target(this.width, this.height);
  final int width;
  final int height;

  @override
  bool operator ==(Object other) => other is Target && other.width == width && other.height == height;
  @override
  int get hashCode => Object.hash(width, height);
  @override
  String toString() => 'Target(${width}x$height)';
}

/// Integer crop rectangle in oriented source space (after EXIF and manual
/// rotation), tech.md FR-8 rule.
final class CropRect {
  const CropRect(this.x, this.y, this.w, this.h);
  final int x;
  final int y;
  final int w;
  final int h;

  @override
  bool operator ==(Object other) =>
      other is CropRect && other.x == x && other.y == y && other.w == w && other.h == h;
  @override
  int get hashCode => Object.hash(x, y, w, h);
  @override
  String toString() => 'CropRect($x, $y, $w, $h)';
}

/// How the source is decoded (gate G1 decision table, FEAT-002-T04).
enum DecodePath { region, full }

/// What the probe learned about the source; no pixels, no file name.
final class SourceInfo {
  const SourceInfo({
    required this.rawWidth,
    required this.rawHeight,
    required this.mime,
    required this.exifOrientation,
    required this.isAnimated,
    required this.hasAlpha,
    required this.decodePath,
  });

  /// Size as stored, before orientation.
  final int rawWidth;
  final int rawHeight;
  final String mime;

  /// 1..8; invalid or missing values are already mapped to 1.
  final int exifOrientation;
  final bool isAnimated;
  final bool hasAlpha;
  final DecodePath decodePath;
}

/// Result of a render: pixels for FEAT-004 (ADR-003, ownership passes to the
/// caller) or a reason, with no buffer and nothing on disk.
sealed class RenderResult {
  const RenderResult();
}

final class RenderOk extends RenderResult {
  const RenderOk(this.pixels);
  final PixelBuffer pixels;
}

final class RenderErr extends RenderResult {
  const RenderErr(this.reason);
  final Reason reason;
}
