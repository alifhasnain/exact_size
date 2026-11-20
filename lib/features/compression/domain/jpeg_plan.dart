import 'dart:typed_data';

import 'byte_window.dart';
import 'compression_result.dart';
import 'encoder.dart';
import 'jpeg_padder.dart';
import 'size_search.dart';
import 'subsampling.dart';

/// Outcome of a plan: bytes ready to write, or a failure. Never both.
sealed class PlanResult {
  const PlanResult();
}

/// Bytes that passed the final gate, ready for the data layer to write to a
/// temp file and turn into a [CompressionSuccess].
final class ReadyToWrite extends PlanResult {
  const ReadyToWrite({
    required this.bytes,
    required this.format,
    this.quality,
    this.subsampling,
    this.optimisedHuffman = false,
    this.paddingBytes = 0,
    this.notices = const {},
  });

  final Uint8List bytes;
  final OutputFormat format;
  final int? quality;
  final Subsampling? subsampling;
  final bool optimisedHuffman;
  final int paddingBytes;
  final Set<Notice> notices;
}

/// No file: [failure] carries the reason, closest size and direction.
final class PlanFailed extends PlanResult {
  const PlanFailed(this.failure);
  final CompressionFailure failure;
}

/// JPEG pipeline in the domain: size search (T10/T11), padding (T12), then the
/// final gate (FR-6) on the exact bytes that will be written.
///
/// Success only when `lo ≤ bytes.length ≤ hi`. Notices: `narrowRange` when the
/// FR-4 fallback window is in use, `paddingAdded` when padding was spliced in
/// (FR-8 disclosure). Every failure carries `closestBytes` and `direction`.
PlanResult planJpeg(Encoder encoder, ByteWindow window) {
  final narrow = {if (window.narrow) Notice.narrowRange};
  switch (searchJpeg(encoder, window)) {
    case SearchFit(:final candidate):
      return _gate(candidate, candidate.bytes, 0, window, narrow);
    case SearchBelowWindow(:final candidate, :final jumpCase):
      return switch (padJpeg(candidate.bytes, window, jumpCase: jumpCase)) {
        Padded(:final bytes, :final paddingBytes) =>
          _gate(candidate, bytes, paddingBytes, window, {...narrow, Notice.paddingAdded}),
        PaddingFailed(:final reason, :final closestBytes) => PlanFailed(CompressionFailure(
            reason: reason,
            closestBytes: closestBytes,
            direction: Direction.tooSmall,
            notices: narrow)),
      };
    case SearchFailure(:final reason, :final closestBytes, :final direction):
      return PlanFailed(CompressionFailure(
          reason: reason, closestBytes: closestBytes, direction: direction, notices: narrow));
  }
}

/// FR-6: measured on the final bytes, not on an estimate.
PlanResult _gate(JpegCandidate c, Uint8List bytes, int padding, ByteWindow window,
    Set<Notice> notices) {
  if (window.contains(bytes.length)) {
    return ReadyToWrite(
      bytes: bytes,
      format: OutputFormat.jpeg,
      quality: c.quality,
      subsampling: c.subsampling,
      optimisedHuffman: c.optimiseHuffman,
      paddingBytes: padding,
      notices: notices,
    );
  }
  final tooBig = bytes.length > window.hi;
  return PlanFailed(CompressionFailure(
    reason: tooBig ? Reason.aboveMax : Reason.belowMin,
    closestBytes: bytes.length,
    direction: tooBig ? Direction.tooBig : Direction.tooSmall,
    notices: notices,
  ));
}
