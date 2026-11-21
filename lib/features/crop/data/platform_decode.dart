import 'package:es_codec/es_codec.dart';
import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';

import '../domain/crop_types.dart';
import 'fd_byte_source.dart';

/// A decode step failed with [reason]; the platform's message is never kept
/// (tech.md section 7: it can contain a URI or path).
final class DecodeFailure implements Exception {
  const DecodeFailure(this.reason);
  final Reason reason;
}

/// Opens [uri] read-only (`"r"`, FR-17) through `ContentResolver`, so
/// `content://` and `file://` take one path. Throws `SOURCE_UNAVAILABLE`.
ParcelFileDescriptor openReadOnly(String uri) {
  try {
    final resolver = androidApplicationContext.as(Context.type).contentResolver!;
    final juri = Uri.parse(uri.toJString())!;
    final mode = 'r'.toJString();
    final pfd = resolver.openFileDescriptor(juri, mode);
    juri.release();
    mode.release();
    resolver.release();
    if (pfd == null) throw const DecodeFailure(Reason.sourceUnavailable);
    return pfd;
  } on DecodeFailure {
    rethrow;
  } on Object {
    throw const DecodeFailure(Reason.sourceUnavailable);
  }
}

/// Decodes [rect] (raw coordinates; null = whole image) of the open source at
/// power-of-two [sample] on the path the probe chose (ADR-004 v1.1): `region`
/// via `BitmapRegionDecoder`, `full` via `BitmapFactory` and an in-memory
/// crop. Always asks for ARGB_8888 in sRGB; any other result is
/// `UNSUPPORTED_INPUT` (FR-10). Java `OutOfMemoryError` is
/// `OUT_OF_MEMORY_HANDLED`. The caller recycles and releases the bitmap.
Bitmap decodeSampled(ParcelFileDescriptor pfd, SourceInfo info,
    {required int sample, ({int x, int y, int w, int h})? rect, required bool premultiplied}) {
  final r = rect ?? (x: 0, y: 0, w: info.rawWidth, h: info.rawHeight);
  final srgb = ColorSpace.get(ColorSpace$Named.SRGB);
  final opts = BitmapFactory$Options()
    ..inSampleSize = sample
    ..inPreferredConfig = Bitmap$Config.ARGB_8888
    ..inPreferredColorSpace = srgb
    ..inPremultiplied = premultiplied;
  final fdObj = pfd.fileDescriptor;
  Bitmap? bmp;
  try {
    FdByteSource(pfd.fd, 0).rewind(); // Java readers start at the shared offset
    if (info.decodePath == DecodePath.region) {
      // newInstance(ParcelFileDescriptor) is API 31+; this overload works on API 28.
      // ignore: deprecated_member_use
      final region = BitmapRegionDecoder.newInstance$3(fdObj, false);
      if (region == null) throw const DecodeFailure(Reason.unsupportedInput);
      final jr = Rect.new$2(r.x, r.y, r.x + r.w, r.y + r.h);
      try {
        bmp = region.decodeRegion(jr, opts);
      } finally {
        jr.release();
        region.recycle();
        region.release();
      }
    } else {
      final whole = BitmapFactory.decodeFileDescriptor$1(fdObj, null, opts);
      if (whole != null && rect != null) {
        final (x, y) = (r.x ~/ sample, r.y ~/ sample);
        final w = (r.w ~/ sample).clamp(1, whole.width - x);
        final h = (r.h ~/ sample).clamp(1, whole.height - y);
        bmp = Bitmap.createBitmap$1(whole, x, y, w, h);
        if (!identical(bmp, whole)) {
          whole.recycle();
          whole.release();
        }
      } else {
        bmp = whole;
      }
    }
    if (bmp == null) throw const DecodeFailure(Reason.unsupportedInput);
    final cfg = bmp.config, cs = bmp.colorSpace;
    final ok = cfg != null && cfg == Bitmap$Config.ARGB_8888 && cs != null && cs.id == srgb!.id;
    cfg?.release();
    cs?.release();
    if (!ok) throw const DecodeFailure(Reason.unsupportedInput);
    final out = bmp;
    bmp = null; // ownership to the caller
    return out;
  } on DecodeFailure {
    rethrow;
  } on Object catch (e) {
    // Only the exception class name is inspected, never logged.
    throw DecodeFailure('$e'.contains('OutOfMemoryError') ? Reason.outOfMemoryHandled : Reason.unsupportedInput);
  } finally {
    bmp?.recycle();
    bmp?.release();
    fdObj?.release();
    opts.release();
    srgb?.release();
  }
}
