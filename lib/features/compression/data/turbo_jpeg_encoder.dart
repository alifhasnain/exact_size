import 'dart:ffi';
import 'dart:typed_data';

import 'package:es_codec/es_codec.dart' as codec;

import '../domain/subsampling.dart';

/// Why a JPEG encode failed (mapped from TurboJPEG errors, FEAT-004-T06).
enum JpegEncodeErrorKind {
  /// A value was rejected before or by libjpeg-turbo (quality, size, DPI...).
  invalidParameter,

  /// libjpeg-turbo could not create a compressor (usually out of memory).
  initFailed,

  /// libjpeg-turbo ran out of memory while compressing (FR-18).
  outOfMemory,

  /// Compression itself failed.
  encodeFailed,
}

/// Typed encode error. [detail] is library text only: no pixels, no paths.
class JpegEncodeException implements Exception {
  const JpegEncodeException(this.kind, this.detail);

  final JpegEncodeErrorKind kind;
  final String detail;

  @override
  String toString() => 'JpegEncodeException(${kind.name}): $detail';
}

/// JPEG encoder adapter over the bundled libjpeg-turbo (ADR-002).
///
/// Reads pixels straight from the native buffer handed over by FEAT-002
/// (ADR-003: tightly packed, 3 channels after flattening), so nothing is
/// copied per pass. Output is baseline JPEG with JFIF APP0 density from [dpi]
/// (FR-14, FEAT-010) and never EXIF or ICC (FR-2, FEAT-018 policy).
/// Same input and settings give byte-identical output (FR-15).
///
/// Implements the domain `Encoder` interface once it lands (FEAT-004-T08).
class TurboJpegEncoder {
  const TurboJpegEncoder();

  /// Largest density JFIF can store (16-bit field).
  static const maxDpi = 65535;

  Uint8List encodeJpeg(
    Pointer<Uint8> pixels, {
    required int width,
    required int height,
    required int quality,
    required Subsampling subsampling,
    required bool optimiseHuffman,
    int? dpi,
  }) {
    if (width <= 0 || height <= 0 || pixels == nullptr) {
      throw const JpegEncodeException(
          JpegEncodeErrorKind.invalidParameter, 'empty image');
    }
    if (quality < 1 || quality > 100) {
      throw JpegEncodeException(
          JpegEncodeErrorKind.invalidParameter, 'quality $quality not in 1..100');
    }
    if (dpi != null && (dpi < 1 || dpi > maxDpi)) {
      throw JpegEncodeException(
          JpegEncodeErrorKind.invalidParameter, 'dpi $dpi not in 1..$maxDpi');
    }
    try {
      return codec.encodeJpeg(
        pixels,
        width,
        height,
        3,
        quality: quality,
        subsampling: switch (subsampling) {
          Subsampling.yuv420 => codec.TJSAMP.TJSAMP_420,
          Subsampling.yuv444 => codec.TJSAMP.TJSAMP_444,
        },
        optimizeHuffman: optimiseHuffman,
        dpi: dpi,
      );
    } on codec.TurboJpegException catch (e) {
      throw JpegEncodeException(
        switch (e.stage) {
          'init' => JpegEncodeErrorKind.initFailed,
          'set' => JpegEncodeErrorKind.invalidParameter,
          // shortcut: matched on libjpeg-turbo's text ("Memory allocation failure",
          // "Insufficient memory"); switch to a code if TurboJPEG ever exposes one.
          _ when e.message.toLowerCase().contains('memory') => JpegEncodeErrorKind.outOfMemory,
          _ => JpegEncodeErrorKind.encodeFailed,
        },
        e.message,
      );
    }
  }
}
