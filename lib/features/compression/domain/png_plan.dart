import 'byte_window.dart';
import 'compression_result.dart';
import 'encoder.dart';
import 'jpeg_plan.dart';
import 'size_search.dart';

/// PNG pipeline (FR-9, FR-10; tech.md "PNG path"): one lossless encode, final
/// gate on the exact bytes. No padding and no lossy colour reduction in R1.
///
/// Too big → `PNG_ABOVE_MAX` plus one JPEG probe at [qFloor] with config A:
/// `jpegWouldFit` tells the UI it may offer a one-tap switch. The format is
/// never changed automatically. [prepareForJpegProbe] runs right before the
/// probe (the runner flattens alpha in place; the PNG is already done then).
PlanResult planPng(
  Encoder encoder,
  ByteWindow window, {
  required void Function() prepareForJpegProbe,
}) {
  final png = encoder.encodePng();
  if (window.contains(png.length)) {
    return ReadyToWrite(bytes: png, format: OutputFormat.png);
  }
  if (png.length < window.lo) {
    return PlanFailed(CompressionFailure(
        reason: Reason.pngBelowMin, closestBytes: png.length, direction: Direction.tooSmall));
  }
  prepareForJpegProbe();
  final probe = encoder.encodeJpeg(
    quality: qFloor,
    subsampling: JpegConfig.a.subsampling,
    optimiseHuffman: JpegConfig.a.optimiseHuffman,
  );
  return PlanFailed(CompressionFailure(
    reason: Reason.pngAboveMax,
    closestBytes: png.length,
    direction: Direction.tooBig,
    // With padding available, a probe under the ceiling means the JPEG path can succeed.
    jpegWouldFit: probe.length <= window.hi,
  ));
}
