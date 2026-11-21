import 'dart:ffi';
import 'dart:isolate';

import 'package:es_codec/es_codec.dart';
import 'package:ffi/ffi.dart';

import '../../compression/data/native_pixel_buffer.dart';
import '../domain/crop_math.dart';
import '../domain/crop_types.dart';
import '../domain/orientation.dart';
import '../domain/target_check.dart';
import 'crop_memory_preflight.dart';
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

/// Renders the crop to exactly W×H in a worker isolate (tech.md section 3,
/// steps 1–9; FR-1, FR-7–FR-10, FR-13, FR-14, FR-16, FR-17, FR-19, FR-21).
///
/// Re-opens the source read-only, region-decodes at the largest power-of-two
/// sample that keeps the crop ≥ W×H, resamples once (Catmull-Rom) straight
/// from the locked bitmap into native memory, applies the D4 transform only
/// when needed, compacts to 3 channels when opaque, asserts the shape and
/// hands an ADR-003 [NativePixelBuffer] to the caller (ownership moves).
class CropRenderer {
  const CropRenderer({this.preflight = const CropMemoryPreflight(), this.debugShapeMismatch = false});

  final CropMemoryPreflight preflight;

  /// Test hook: report a wrong output width so the shape assert fires.
  final bool debugShapeMismatch;

  Future<RenderResult> render(RenderRequest req) async {
    final reader = preflight.readMeminfo;
    final mismatch = debugShapeMismatch;
    final (uri, info, rect, turns, target) = (req.src.uri, req.info, req.cropRect, req.quarterTurns, req.target);
    final r = await Isolate.run(() => _renderInWorker(uri, info, rect, turns, target, reader, mismatch));
    if (r case (final int address, final int w, final int h, final int channels, final bool alpha, final int length)) {
      return RenderOk(NativePixelBuffer.adopt(
          address: address, width: w, height: h, channels: channels, hasTransparency: alpha, byteLength: length)
        ..upscaleFactor = CropMath.upscaleFactor(rect, target)
        ..cropRect = (x: rect.x, y: rect.y, w: rect.w, h: rect.h)
        ..rotationApplied = (turns % 4) * 90);
    }
    return RenderErr(r as Reason);
  }

  /// (address, width, height, channels, hasTransparency, byteLength) of a
  /// `malloc` block the caller adopts, or a [Reason] with nothing allocated.
  static Future<Object> _renderInWorker(String uri, SourceInfo info, CropRect rect, int turns, Target target,
      Future<String?> Function() readMeminfo, bool mismatch) async {
    // 1. Target, then the source again (read-only), same size as probed.
    if (checkTarget(target) != null) return Reason.invalidTargetDimensions;
    final ParcelFileDescriptor pfd;
    try {
      pfd = openReadOnly(uri);
    } on DecodeFailure catch (e) {
      return e.reason;
    }
    Bitmap? bmp;
    var first = nullptr.cast<Uint8>(), second = nullptr.cast<Uint8>();
    try {
      if (!_sameBounds(pfd, info)) return Reason.sourceUnavailable;

      // 2. One transform for EXIF and manual turns; crop rect back to raw space.
      final d4 = Orientation.fromExif(info.exifOrientation).then(Orientation.rotation(turns));
      final raw = d4.mapRectToRaw(rect, info.rawWidth, info.rawHeight);
      // Output size before orienting: the raw axes.
      final (rw, rh) = d4.quarterTurns.isOdd ? (target.height, target.width) : (target.width, target.height);

      // 3–4. Sample size (FR-7) and memory pre-flight (FR-6).
      final sample = CropMath.sampleSize(rect, target);
      final tooBig = await CropMemoryPreflight(readMeminfo: readMeminfo)
          .check(info: info, raw: raw, sample: sample, target: target, reorient: !d4.isIdentity);
      if (tooBig != null) return tooBig;

      // 5. Region decode, ARGB_8888 sRGB unpremultiplied.
      final d = decodeSampled(pfd, info, sample: sample, rect: (x: raw.x, y: raw.y, w: raw.w, h: raw.h), premultiplied: false);
      bmp = d.bitmap;

      // 6. Resample straight from the locked bitmap (the requested part of it)
      //    into native memory.
      first = _alloc(rw * rh * 4);
      final out1 = first;
      withBitmapPixels(bmp, (p, bw, bh, stride) {
        final w = d.w.clamp(1, bw - d.dx), h = d.h.clamp(1, bh - d.dy);
        resample(p + d.dy * stride + d.dx * 4, w, h, stride, out1, rw, rh, alpha: info.hasAlpha);
      });
      bmp.recycle();
      bmp.release();
      bmp = null;

      // 7. Orient only when needed; free the first buffer.
      var (w, h) = (rw, rh);
      if (!d4.isIdentity) {
        second = _alloc(rw * rh * 4);
        orient(first, rw, rh, 4, second, mirrored: d4.mirrored, quarterTurns: d4.quarterTurns);
        malloc.free(first);
        (first, second) = (second, nullptr.cast<Uint8>());
        (w, h) = d4.orientedSize(rw, rh);
      }

      // 8. Alpha scan; opaque output is compacted in place to RGB.
      final alpha = finishAlpha(first, w, h);
      final channels = alpha ? 4 : 3;

      // 9. FR-16: exactly W×H, 3 or 4 channels, tight stride, else nothing is handed off.
      if (mismatch) w += 1;
      if (w != target.width || h != target.height) return Reason.internalError;
      final out = first;
      first = nullptr.cast<Uint8>(); // ownership to the caller
      return (out.address, w, h, channels, alpha, rw * rh * 4);
    } on DecodeFailure catch (e) {
      return e.reason;
    } on _AllocationFailed {
      return Reason.outOfMemoryHandled;
    } on Object {
      return Reason.internalError;
    } finally {
      if (first != nullptr) malloc.free(first);
      if (second != nullptr) malloc.free(second);
      bmp?.recycle();
      bmp?.release();
      try {
        pfd.close();
      } on Object {
        // already closed
      }
      pfd.release();
    }
  }

  static Pointer<Uint8> _alloc(int n) {
    try {
      return malloc<Uint8>(n);
    } on ArgumentError {
      throw const _AllocationFailed();
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
