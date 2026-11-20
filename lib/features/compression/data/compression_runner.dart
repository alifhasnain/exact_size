import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../domain/byte_window.dart';
import '../domain/compression_request.dart';
import '../domain/compression_result.dart';
import '../domain/encoder.dart';
import '../domain/flattener.dart';
import '../domain/jpeg_plan.dart';
import '../domain/png_plan.dart';
import '../domain/size_search.dart';
import '../domain/subsampling.dart';
import 'dart_png_encoder.dart';
import 'native_pixel_buffer.dart';
import 'turbo_jpeg_encoder.dart';

/// Cancels a running compression (FR-17). The flag lives in native memory so
/// the worker isolate can read it between passes without a message round trip.
final class CancelSignal {
  CancelSignal() : _flag = calloc<Int32>();
  final Pointer<Int32> _flag;
  bool _disposed = false;

  void cancel() {
    if (!_disposed) _flag.value = 1;
  }

  bool get isCancelled => !_disposed && _flag.value != 0;

  /// Frees the flag; call once the run that used it has finished.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    calloc.free(_flag);
  }
}

/// Runs one compression on a worker isolate (ADR-001, ADR-003; FR-1, FR-17).
///
/// The worker gets the pixel buffer's address, not a copy. Progress is
/// reported per encode pass as `(pass, maxPasses)`; cancel is checked before
/// every pass, so it takes effect within one pass. The request's
/// [NativePixelBuffer] is freed when the run ends, whatever the outcome.
/// Writing the result to a temp file is the next step (FEAT-004-T17).
class CompressionRunner {
  const CompressionRunner();

  Future<PlanResult> run(
    CompressionRequest request, {
    CancelSignal? cancel,
    void Function(int pass, int maxPasses)? onProgress,
  }) async {
    final px = request.pixels;
    try {
      if (px is! NativePixelBuffer) {
        throw ArgumentError('pixels must be a NativePixelBuffer (ADR-003)');
      }
      _checkLayout(px); // FR-1: reject before any encode
      final ownCancel = cancel == null ? CancelSignal() : null;
      final signal = cancel ?? ownCancel!;
      // One port for progress and the result, so progress can't arrive late.
      final port = ReceivePort();
      final result = Completer<Object?>();
      port.listen((m) {
        if (m is int) {
          onProgress?.call(m, maxPasses);
        } else if (!result.isCompleted) {
          result.complete(m);
        }
      });
      try {
        await Isolate.spawn(
          _workerMain,
          _Job(
            address: px.address,
            width: px.width,
            height: px.height,
            channels: px.channels,
            hasTransparency: px.hasTransparency,
            byteLength: px.byteLength,
            minKb: request.minKb,
            maxKb: request.maxKb,
            format: request.format,
            dpi: request.dpi,
            cancelAddress: signal._flag.address,
            port: port.sendPort,
          ),
          onExit: port.sendPort, // null if the worker dies without a result
        );
        final message = await result.future;
        if (message is PlanResult) return message;
        throw StateError('compression worker failed: $message');
      } finally {
        port.close();
        ownCancel?.dispose();
      }
    } finally {
      if (px is NativePixelBuffer) px.free(); // ownership moved with the request
    }
  }

  static void _checkLayout(NativePixelBuffer px) {
    final ok = px.width > 0 &&
        px.height > 0 &&
        (px.channels == 3 || px.channels == 4) &&
        px.stride == px.width * px.channels &&
        px.byteLength >= px.height * px.stride;
    if (!ok) {
      throw ArgumentError(
          'pixel layout mismatch: ${px.width}x${px.height}x${px.channels}, '
          'stride ${px.stride}, ${px.byteLength} bytes');
    }
  }
}

final class _Job {
  const _Job({
    required this.address,
    required this.width,
    required this.height,
    required this.channels,
    required this.hasTransparency,
    required this.byteLength,
    required this.minKb,
    required this.maxKb,
    required this.format,
    required this.dpi,
    required this.cancelAddress,
    required this.port,
  });
  final int address, width, height, channels, byteLength, maxKb, cancelAddress;
  final bool hasTransparency;
  final int? minKb, dpi;
  final OutputFormat format;
  final SendPort port; // progress ints, then the PlanResult (or an error text)
}

final class _Cancelled implements Exception {
  const _Cancelled();
}

void _workerMain(_Job job) {
  PlanResult result;
  try {
    result = _compress(job);
  } on _Cancelled {
    result = const PlanFailed(CompressionFailure(reason: Reason.cancelled));
  } on JpegEncodeException catch (e) {
    if (e.kind != JpegEncodeErrorKind.initFailed) rethrow;
    result = const PlanFailed(CompressionFailure(reason: Reason.outOfMemoryHandled));
  } catch (e) {
    Isolate.exit(job.port, '$e'); // reported as a StateError on the main isolate
  }
  Isolate.exit(job.port, result); // hands the bytes over without a copy
}

PlanResult _compress(_Job job) {
  final px = NativePixelBuffer.view(
    address: job.address,
    width: job.width,
    height: job.height,
    channels: job.channels,
    hasTransparency: job.hasTransparency,
    byteLength: job.byteLength,
  );
  final encoder =
      _BoundEncoder(px, job.dpi, Pointer<Int32>.fromAddress(job.cancelAddress), job.port);
  final window = ByteWindow.fromKb(minKb: job.minKb, maxKb: job.maxKb);
  if (job.format == OutputFormat.png) {
    return planPng(encoder, window, prepareForJpegProbe: () => flattenForJpeg(px));
  }
  final flattened = flattenForJpeg(px);
  final plan = planJpeg(encoder, window);
  return flattened.isEmpty ? plan : _withNotices(plan, flattened);
}

PlanResult _withNotices(PlanResult plan, Set<Notice> extra) => switch (plan) {
      ReadyToWrite r => ReadyToWrite(
          bytes: r.bytes,
          format: r.format,
          quality: r.quality,
          subsampling: r.subsampling,
          optimisedHuffman: r.optimisedHuffman,
          paddingBytes: r.paddingBytes,
          notices: {...r.notices, ...extra}),
      PlanFailed(:final failure) => PlanFailed(CompressionFailure(
          reason: failure.reason,
          closestBytes: failure.closestBytes,
          direction: failure.direction,
          jpegWouldFit: failure.jpegWouldFit,
          notices: {...failure.notices, ...extra})),
    };

/// [Encoder] bound to one buffer and DPI; each encode is one progress pass and
/// is preceded by a cancel check.
final class _BoundEncoder implements Encoder {
  _BoundEncoder(this.px, this.dpi, this.cancelFlag, this.progress);
  final NativePixelBuffer px;
  final int? dpi;
  final Pointer<Int32> cancelFlag;
  final SendPort progress;
  var _pass = 0;

  void _beginPass() {
    if (cancelFlag.value != 0) throw const _Cancelled();
    progress.send(++_pass);
  }

  @override
  Uint8List encodeJpeg({
    required int quality,
    required Subsampling subsampling,
    required bool optimiseHuffman,
  }) {
    _beginPass();
    return const TurboJpegEncoder().encodeJpeg(px.pointer,
        width: px.width,
        height: px.height,
        quality: quality,
        subsampling: subsampling,
        optimiseHuffman: optimiseHuffman,
        dpi: dpi);
  }

  @override
  Uint8List encodePng() {
    _beginPass();
    return const DartPngEncoder().encodePng(px, dpi: dpi);
  }
}
