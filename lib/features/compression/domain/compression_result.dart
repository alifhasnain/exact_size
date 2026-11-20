import 'subsampling.dart';

/// Output file format, chosen only by the target (FR-13).
enum OutputFormat { jpeg, png }

/// Failure reason codes, exactly the list in FEAT-004 PRD section 5.
/// [code] is the PRD spelling; only codes, never image data, may be logged (section 10).
enum Reason {
  aboveMax('ABOVE_MAX'),
  tooDegraded('TOO_DEGRADED'),
  noFit('NO_FIT'),
  belowMin('BELOW_MIN'),
  pngAboveMax('PNG_ABOVE_MAX'),
  pngBelowMin('PNG_BELOW_MIN'),
  invalidTarget('INVALID_TARGET'),
  unsupportedInput('UNSUPPORTED_INPUT'), // relayed from FEAT-002 (FR-13)
  imageTooLarge('IMAGE_TOO_LARGE'),
  outOfMemoryHandled('OUT_OF_MEMORY_HANDLED'),
  writeFailed('WRITE_FAILED'),
  cancelled('CANCELLED');

  const Reason(this.code);
  final String code;
}

/// Notices shown with a result (FR-4, FR-8, FR-12).
enum Notice { narrowRange, paddingAdded, transparencyFlattened }

/// Which way the closest achievable size misses the target (FR-11).
enum Direction { tooBig, tooSmall }

/// Outcome of one compression run (tech.md section 4).
sealed class CompressionResult {
  const CompressionResult(this.notices);
  final Set<Notice> notices;
}

/// The file is inside the window and ready for export.
final class CompressionSuccess extends CompressionResult {
  const CompressionSuccess({
    required this.tempFilePath,
    required this.sizeBytes,
    required this.format,
    this.quality,
    this.subsampling,
    this.optimisedHuffman = false,
    this.paddingBytes = 0,
    Set<Notice> notices = const {},
  }) : super(notices);

  /// App-private temp file (random name, no user data); FEAT-007 exports it.
  final String tempFilePath;
  final int sizeBytes;
  final OutputFormat format;

  /// JPEG only.
  final int? quality;
  final Subsampling? subsampling;
  final bool optimisedHuffman;
  final int paddingBytes;
}

/// No exportable file exists. Deliberately carries no file path (FR-6, FR-11).
final class CompressionFailure extends CompressionResult {
  const CompressionFailure({
    required this.reason,
    this.closestBytes,
    this.direction,
    this.jpegWouldFit = false,
    Set<Notice> notices = const {},
  }) : super(notices);

  final Reason reason;
  final int? closestBytes;
  final Direction? direction;

  /// PNG_ABOVE_MAX only: one JPEG probe fitted (FR-10).
  final bool jpegWouldFit;
}
