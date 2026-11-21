import 'dart:isolate';

import 'package:es_codec/es_codec.dart';
import 'package:jni/jni.dart';

import '../domain/crop_types.dart';
import 'container_check.dart';
import 'fd_byte_source.dart';
import 'header_sniff.dart';
import 'heif_orientation.dart';
import 'platform_decode.dart';
import 'source_handle.dart';

/// Result of [SourceProbe.probe] (tech.md section 4).
sealed class ProbeResult {
  const ProbeResult();
}

final class ProbeOk extends ProbeResult {
  const ProbeOk(this.info);
  final SourceInfo info;
}

final class ProbeErr extends ProbeResult {
  const ProbeErr(this.reason);
  final Reason reason;
}

/// Opens the source read-only and learns what the crop step needs, without
/// decoding pixels (FR-2, FR-3, FR-6, FR-15, FR-17, ADR-004 v1.1).
///
/// Order: open `"r"` (failure: `SOURCE_UNAVAILABLE`), container check
/// (`CORRUPT_INPUT`, `UNSUPPORTED_INPUT`, `IMAGE_TOO_LARGE` above 200 MP),
/// header sniff (animation, alpha), orientation (`ExifInterface` for JPEG, PNG
/// and WebP; our own reader for HEIC), platform bounds (`UNSUPPORTED_INPUT`
/// when the device can't read the file), decode path (`full` for GIF). JPEG,
/// PNG, WebP and HEIC take the same path. Runs in a worker isolate. Platform
/// exception text is never logged: every failure maps to a [Reason].
class SourceProbe {
  const SourceProbe();

  Future<ProbeResult> probe(SourceHandle src) {
    final uri = src.uri;
    return Isolate.run(() => probeSync(uri));
  }

  /// Same as [probe] on the calling isolate (tests, or a caller already in a worker).
  static ProbeResult probeSync(String uri) {
    final ParcelFileDescriptor pfd;
    try {
      pfd = openReadOnly(uri);
    } on DecodeFailure catch (e) {
      return ProbeErr(e.reason);
    }
    try {
      final size = pfd.statSize;
      if (size <= 0) return const ProbeErr(Reason.sourceUnavailable); // not a regular file
      final src = FdByteSource(pfd.fd, size);
      final container = checkContainer(src);
      if (container is ContainerError) return ProbeErr(container.reason);
      final ok = container as ContainerOk;
      final flags = sniffHeader(src, ok.format);
      final orientation = switch (ok.format) {
        ContainerFormat.heif => heifOrientation(src),
        ContainerFormat.gif => 1, // GIF has no EXIF
        _ => _exifOrientation(src, pfd),
      };

      src.rewind();
      final opts = BitmapFactory$Options()..inJustDecodeBounds = true;
      final fdObj = pfd.fileDescriptor;
      BitmapFactory.decodeFileDescriptor$1(fdObj, null, opts);
      fdObj?.release();
      final w = opts.outWidth, h = opts.outHeight;
      final mime = opts.outMimeType?.toDartString(releaseOriginal: true) ?? '';
      opts.release();
      if (w <= 0 || h <= 0) return const ProbeErr(Reason.unsupportedInput);
      if (w * h > maxSourcePixels) return const ProbeErr(Reason.imageTooLarge);
      return ProbeOk(SourceInfo(
        rawWidth: w,
        rawHeight: h,
        mime: mime,
        exifOrientation: orientation,
        isAnimated: flags.animated,
        hasAlpha: flags.alpha,
        decodePath: ok.format == ContainerFormat.gif ? DecodePath.full : DecodePath.region,
        isProgressive: ok.progressive,
      ));
    } on Object {
      return const ProbeErr(Reason.unsupportedInput);
    } finally {
      try {
        pfd.close();
      } on Object {
        // already closed or invalid; nothing to free
      }
      pfd.release();
    }
  }

  /// `TAG_ORIENTATION` only (tech.md section 7); outside 1–8, missing, or a
  /// reader error gives 1. The `ExifInterface` object is dropped at once.
  static int _exifOrientation(FdByteSource src, ParcelFileDescriptor pfd) {
    try {
      src.rewind();
      final fdObj = pfd.fileDescriptor;
      final exif = ExifInterface.new$1(fdObj);
      final tag = ExifInterface.TAG_ORIENTATION;
      final v = exif.getAttributeInt(tag, 1);
      tag?.release();
      exif.release();
      fdObj?.release();
      return v >= 1 && v <= 8 ? v : 1;
    } on Object {
      return 1;
    }
  }
}

