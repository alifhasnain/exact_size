import '../domain/compression_request.dart';
import '../domain/compression_result.dart';
import '../domain/jpeg_plan.dart';
import 'compression_runner.dart';
import 'temp_files.dart';

/// Entry point of FEAT-004 (tech.md section 4): runs the search on the worker
/// isolate, then writes only the final file. Ownership of the request's pixels
/// moves here (ADR-003). A cancel that lands while the file is written still
/// wins: the file is deleted and the result is `CANCELLED`.
class CompressionService {
  const CompressionService(this._runner, this._files);

  final CompressionRunner _runner;
  final TempFiles _files;

  Future<CompressionResult> compress(
    CompressionRequest request, {
    CancelSignal? cancel,
    void Function(int pass, int maxPasses)? onProgress,
  }) async {
    final plan = await _runner.run(request, cancel: cancel, onProgress: onProgress);
    switch (plan) {
      case PlanFailed(:final failure):
        return failure;
      case ReadyToWrite r:
        final String path;
        try {
          path = await _files.write(r.bytes, r.format);
        } on TempWriteException {
          return CompressionFailure(
              reason: Reason.writeFailed, closestBytes: r.bytes.length, notices: r.notices);
        }
        if (cancel?.isCancelled ?? false) {
          await _files.delete(path);
          return const CompressionFailure(reason: Reason.cancelled);
        }
        return CompressionSuccess(
          tempFilePath: path,
          sizeBytes: r.bytes.length,
          format: r.format,
          quality: r.quality,
          subsampling: r.subsampling,
          optimisedHuffman: r.optimisedHuffman,
          paddingBytes: r.paddingBytes,
          notices: r.notices,
        );
    }
  }
}
