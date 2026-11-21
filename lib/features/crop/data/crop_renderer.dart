import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:es_codec/es_codec.dart';
import 'package:ffi/ffi.dart';

import '../../compression/data/compression_runner.dart' show CancelSignal;
import '../../compression/data/native_pixel_buffer.dart';
import '../domain/crop_math.dart';
import '../domain/crop_types.dart';
import '../domain/orientation.dart';
import '../domain/target_check.dart';
import 'crop_memory_preflight.dart';
import 'crop_outcome_log.dart';
import 'platform_decode.dart';
import 'source_handle.dart';

/// One render (tech.md section 4). Takes the source handle, never the preview
/// image: the render always re-decodes from the original (FR-7).
final class RenderRequest {
  const RenderRequest({
    required this.src,
    required this.info,
    required this.cropRect,
    required this.quarterTurns,
    required this.target,
  });
  final SourceHandle src;
  final SourceInfo info;

  /// Oriented space (after EXIF and [quarterTurns]), from `CropMath.toCropRect`.
  final CropRect cropRect;
  final int quarterTurns;
  final Target target;
}

/// Render progress, reported after each step finishes (FR-18).
enum RenderStep { opened, decoded, resampled, oriented, finished }

/// Renders the crop to exactly W×H in a worker isolate (tech.md section 3,
/// steps 1–9; FR-1, FR-6–FR-10, FR-13, FR-14, FR-16–FR-19, FR-21).
///
/// Re-opens the source read-only, region-decodes at the largest power-of-two
/// sample that keeps the crop ≥ W×H, resamples once (Catmull-Rom) straight
/// from the locked bitmap into native memory, applies the D4 transform only
/// when needed, compacts to 3 channels when opaque, asserts the shape and
/// hands an ADR-003 [NativePixelBuffer] to the caller: ownership moves, the
/// renderer keeps no reference. Cancel is checked between steps; the bitmap
/// and every native block are freed on every path.
class CropRenderer {
  const CropRenderer({
    this.preflight = const CropMemoryPreflight(),
    this.debugShapeMismatch = false,
    this.debugFailAllocation = false,
    this.debugCancelAfter,
    this.log = const CropOutcomeLog(),
  });

  final CropMemoryPreflight preflight;

  /// Enum-only outcome log (FR-24).
  final CropOutcomeLog log;

  /// Test hook: report a wrong output width so the shape assert fires.
  final bool debugShapeMismatch;

  /// Test hook: native allocations fail (as `malloc` returning null).
  final bool debugFailAllocation;

  /// Test hook: behave as if cancel arrived right after this step.
  final RenderStep? debugCancelAfter;

  /// Debug leak counter: native blocks the renderer allocated that are
  /// neither freed nor handed over (all isolates of this process).
  static int get liveNativeBlocks => _live.value;
  static final Pointer<Int64> _live = calloc<Int64>();

  Future<RenderResult> render(RenderRequest req, {CancelSignal? cancel, void Function(RenderStep)? onProgress}) async {
    final ownCancel = cancel == null ? CancelSignal() : null;
    final signal = cancel ?? ownCancel!;
    final port = ReceivePort();
    final done = Completer<Object?>();
    port.listen((m) {
      if (m is int) {
        onProgress?.call(RenderStep.values[m]);
      } else if (!done.isCompleted) {
        done.complete(m);
      }
    });
    final rect = req.cropRect, target = req.target, turns = req.quarterTurns;
    try {
      await Isolate.spawn(
        _workerMain,
        _Job(
          uri: req.src.uri,
          info: req.info,
          rect: rect,
          turns: turns,
          target: target,
          readMeminfo: preflight.readMeminfo,
          cancelAddress: signal.flagAddress,
          liveAddress: _live.address,
          mismatch: debugShapeMismatch,
          failAllocation: debugFailAllocation,
          cancelAfter: debugCancelAfter?.index,
          port: port.sendPort,
        ),
        onExit: port.sendPort, // null if the worker dies without a result
      );
      final r = await done.future;
      if (r case (final int address, final int w, final int h, final int channels, final bool alpha, final int length)) {
        _live.value--; // handed over: from now on NativePixelBuffer.live counts it
        log.success();
        return RenderOk(NativePixelBuffer.adopt(
            address: address, width: w, height: h, channels: channels, hasTransparency: alpha, byteLength: length)
          ..upscaleFactor = CropMath.upscaleFactor(rect, target)
          ..cropRect = (x: rect.x, y: rect.y, w: rect.w, h: rect.h)
          ..rotationApplied = (turns % 4) * 90);
      }
      final reason = r is Reason ? r : Reason.internalError;
      log.failure(reason);
      return RenderErr(reason);
    } finally {
      port.close();
      ownCancel?.dispose();
    }
  }

  static void _workerMain(_Job job) {
    final live = Pointer<Int64>.fromAddress(job.liveAddress);
    final cancel = Pointer<Int32>.fromAddress(job.cancelAddress);
    void step(RenderStep s) {
      job.port.send(s.index);
      if (job.cancelAfter == s.index) cancel.value = 1;
      if (cancel.value != 0) throw const _Cancelled();
    }

    Pointer<Uint8> alloc(int n) {
      if (job.failAllocation) throw const _AllocationFailed();
      final Pointer<Uint8> p;
      try {
        p = malloc<Uint8>(n);
      } on ArgumentError {
        throw const _AllocationFailed();
      }
      live.value++;
      return p;
    }

    void free(Pointer<Uint8> p) {
      malloc.free(p);
      live.value--;
    }

    unawaited(_render(job, cancel, step, alloc, free).then((r) => Isolate.exit(job.port, r)));
  }

  static Future<Object> _render(_Job job, Pointer<Int32> cancel, void Function(RenderStep) step,
      Pointer<Uint8> Function(int) alloc, void Function(Pointer<Uint8>) free) async {
    final (info, rect, turns, target) = (job.info, job.rect, job.turns, job.target);
    // 1. Target, then the source again (read-only), same size as probed.
    if (checkTarget(target) != null) return Reason.invalidTargetDimensions;
    if (cancel.value != 0) return Reason.cancelled;
    ParcelFileDescriptor? pfd;
    Bitmap? bmp;
    var first = nullptr.cast<Uint8>(), second = nullptr.cast<Uint8>();
    try {
      pfd = openReadOnly(job.uri);
      if (!_sameBounds(pfd, info)) return Reason.sourceUnavailable;

      // 2. One transform for EXIF and manual turns; crop rect back to raw space.
      final d4 = Orientation.fromExif(info.exifOrientation).then(Orientation.rotation(turns));
      final raw = d4.mapRectToRaw(rect, info.rawWidth, info.rawHeight);
      // Output size before orienting: the raw axes.
      final (rw, rh) = d4.quarterTurns.isOdd ? (target.height, target.width) : (target.width, target.height);

      // 3–4. Sample size (FR-7) and memory pre-flight (FR-6).
      final sample = CropMath.sampleSize(rect, target);
      final tooBig = await CropMemoryPreflight(readMeminfo: job.readMeminfo)
          .check(info: info, raw: raw, sample: sample, target: target, reorient: !d4.isIdentity);
      if (tooBig != null) return tooBig;
      step(RenderStep.opened);

      // 5. Region decode, ARGB_8888 sRGB unpremultiplied.
      final d = decodeSampled(pfd, info, sample: sample, rect: (x: raw.x, y: raw.y, w: raw.w, h: raw.h), premultiplied: false);
      bmp = d.bitmap;
      step(RenderStep.decoded);

      // 6. Resample straight from the locked bitmap (the requested part of it)
      //    into native memory; the bitmap is freed right after.
      first = alloc(rw * rh * 4);
      final out1 = first;
      withBitmapPixels(bmp, (p, bw, bh, stride) {
        final w = d.w.clamp(1, bw - d.dx), h = d.h.clamp(1, bh - d.dy);
        resample(p + d.dy * stride + d.dx * 4, w, h, stride, out1, rw, rh, alpha: info.hasAlpha);
      });
      bmp.recycle();
      bmp.release();
      bmp = null;
      step(RenderStep.resampled);

      // 7. Orient only when needed; free the first buffer.
      var (w, h) = (rw, rh);
      if (!d4.isIdentity) {
        second = alloc(rw * rh * 4);
        orient(first, rw, rh, 4, second, mirrored: d4.mirrored, quarterTurns: d4.quarterTurns);
        free(first);
        (first, second) = (second, nullptr.cast<Uint8>());
        (w, h) = d4.orientedSize(rw, rh);
      }
      step(RenderStep.oriented);

      // 8. Alpha scan; opaque output is compacted in place to RGB.
      final alpha = finishAlpha(first, w, h);
      final channels = alpha ? 4 : 3;

      // 9. FR-16: exactly W×H, 3 or 4 channels, tight stride, else nothing is handed off.
      if (job.mismatch) w += 1;
      if (w != target.width || h != target.height) return Reason.internalError;
      step(RenderStep.finished);
      final out = first;
      first = nullptr.cast<Uint8>(); // ownership to the caller (counted until adopted)
      return (out.address, w, h, channels, alpha, rw * rh * 4);
    } on _Cancelled {
      return Reason.cancelled;
    } on DecodeFailure catch (e) {
      return e.reason;
    } on _AllocationFailed {
      return Reason.outOfMemoryHandled;
    } on Object {
      return Reason.internalError;
    } finally {
      if (first != nullptr) free(first);
      if (second != nullptr) free(second);
      bmp?.recycle();
      bmp?.release();
      try {
        pfd?.close();
      } on Object {
        // already closed
      }
      pfd?.release();
    }
  }

  /// Bounds-only decode of the re-opened source equal to the probe (else the
  /// file changed or was replaced: `SOURCE_UNAVAILABLE`).
  static bool _sameBounds(ParcelFileDescriptor pfd, SourceInfo info) {
    final opts = BitmapFactory$Options()..inJustDecodeBounds = true;
    final fdObj = pfd.fileDescriptor;
    try {
      BitmapFactory.decodeFileDescriptor$1(fdObj, null, opts);
      return opts.outWidth == info.rawWidth && opts.outHeight == info.rawHeight;
    } finally {
      fdObj?.release();
      opts.release();
    }
  }
}

final class _AllocationFailed implements Exception {
  const _AllocationFailed();
}

final class _Cancelled implements Exception {
  const _Cancelled();
}

final class _Job {
  const _Job({
    required this.uri,
    required this.info,
    required this.rect,
    required this.turns,
    required this.target,
    required this.readMeminfo,
    required this.cancelAddress,
    required this.liveAddress,
    required this.mismatch,
    required this.failAllocation,
    required this.cancelAfter,
    required this.port,
  });
  final String uri;
  final SourceInfo info;
  final CropRect rect;
  final int turns;
  final Target target;
  final Future<String?> Function() readMeminfo;
  final int cancelAddress, liveAddress;
  final bool mismatch, failAllocation;
  final int? cancelAfter;
  final SendPort port; // RenderStep indexes, then the result
}
