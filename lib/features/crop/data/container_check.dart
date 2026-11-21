import 'dart:typed_data';

import '../domain/crop_types.dart';
import 'byte_source.dart';
import 'heif_meta.dart';

/// Source formats the container check recognises.
enum ContainerFormat { jpeg, png, webp, gif, heif }

sealed class ContainerResult {
  const ContainerResult();
}

final class ContainerOk extends ContainerResult {
  const ContainerOk(this.format, this.width, this.height);
  final ContainerFormat format;

  /// Declared size as stored (before any orientation).
  final int width;
  final int height;
}

final class ContainerError extends ContainerResult {
  const ContainerError(this.reason);
  final Reason reason;
}

/// Source pixel ceiling (FR-6, Product Owner decision 2026-11-20).
const maxSourcePixels = 200000000;

/// Checks a source's container structure before any decode (ADR-004 v1.1).
///
/// Android's decoders accept a truncated JPEG silently and some corrupt PNGs
/// partially, so a missing or inconsistent header, truncated data or a bad
/// chunk checksum gives `CORRUPT_INPUT`; a declared size above 200 MP gives
/// `IMAGE_TOO_LARGE` without decoding pixels. Reads untrusted bytes: every
/// read is bounded by the file length and nothing is allocated from a
/// declared size.
ContainerResult checkContainer(ByteSource src) {
  try {
    final head = src.read(0, 32);
    final ContainerOk ok;
    if (_starts(head, const [0xff, 0xd8])) {
      ok = _jpeg(src);
    } else if (_starts(head, const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
      ok = _png(src);
    } else if (_ascii(head, 0, 'RIFF') && _ascii(head, 8, 'WEBP')) {
      ok = _webp(src);
    } else if (_ascii(head, 0, 'GIF87a') || _ascii(head, 0, 'GIF89a')) {
      ok = _gif(src);
    } else if (_ascii(head, 4, 'ftyp')) {
      final meta = HeifMeta.parse(src);
      ok = ContainerOk(ContainerFormat.heif, meta.width, meta.height);
    } else if (_ascii(head, 0, 'BM') || _starts(head, const [0x49, 0x49, 0x2a, 0]) || _starts(head, const [0x4d, 0x4d, 0, 0x2a])) {
      return const ContainerError(Reason.unsupportedInput); // BMP, TIFF: real images, not supported
    } else {
      return const ContainerError(Reason.corruptInput);
    }
    return ok;
  } on _TooLarge {
    return const ContainerError(Reason.imageTooLarge);
  } on MalformedImage {
    return const ContainerError(Reason.corruptInput);
  }
}

final class _TooLarge implements Exception {
  const _TooLarge();
}

void _checkSize(int w, int h) {
  if (w <= 0 || h <= 0) throw const MalformedImage();
  if (w * h > maxSourcePixels) throw const _TooLarge();
}

bool _starts(Uint8List b, List<int> sig) {
  if (b.length < sig.length) return false;
  for (var i = 0; i < sig.length; i++) {
    if (b[i] != sig[i]) return false;
  }
  return true;
}

bool _ascii(Uint8List b, int at, String s) =>
    b.length >= at + s.length && String.fromCharCodes(b, at, at + s.length) == s;

/// Exactly [n] bytes at [o], or [MalformedImage] (truncated).
Uint8List _need(ByteSource src, int o, int n) {
  final b = src.read(o, n);
  if (b.length != n) throw const MalformedImage();
  return b;
}

// JPEG: marker walk from SOI; the entropy-coded data after each SOS is scanned
// for the next marker, so the file must reach EOI. Bytes after EOI (camera
// trailers) are allowed.
ContainerOk _jpeg(ByteSource src) {
  var o = 2;
  int? w, h;
  var scans = 0;
  for (var guard = 0; guard < 100000; guard++) {
    var b = _need(src, o, 2);
    while (b[0] == 0xff && b[1] == 0xff) {
      o++; // fill bytes
      b = _need(src, o, 2);
    }
    if (b[0] != 0xff) throw const MalformedImage();
    final m = b[1];
    o += 2;
    if (m == 0xd9) {
      if (w == null || h == null || scans == 0) throw const MalformedImage();
      return ContainerOk(ContainerFormat.jpeg, w, h);
    }
    if (m == 0x01 || (m >= 0xd0 && m <= 0xd7)) continue; // no length
    if (m == 0xd8 || m == 0x00) throw const MalformedImage();
    final len = ByteData.sublistView(_need(src, o, 2)).getUint16(0);
    if (len < 2) throw const MalformedImage();
    final isSof = m >= 0xc0 && m <= 0xcf && m != 0xc4 && m != 0xc8 && m != 0xcc;
    if (isSof) {
      final f = ByteData.sublistView(_need(src, o, 7));
      h = f.getUint16(3);
      w = f.getUint16(5);
      _checkSize(w, h);
    }
    o += len;
    if (m == 0xda) {
      if (w == null) throw const MalformedImage();
      scans++;
      o = _nextMarker(src, o);
    }
  }
  throw const MalformedImage();
}

/// Position of the first marker (0xFF not followed by 0x00 or RST) at or after [o].
int _nextMarker(ByteSource src, int o) {
  const chunk = 1 << 16;
  while (true) {
    final b = src.read(o, chunk + 1);
    if (b.length < 2) throw const MalformedImage(); // ran out before EOI: truncated
    for (var i = 0; i + 1 < b.length; i++) {
      if (b[i] != 0xff) continue;
      final n = b[i + 1];
      if (n == 0x00 || (n >= 0xd0 && n <= 0xd7) || n == 0xff) continue;
      return o + i;
    }
    o += b.length - 1;
  }
}

// PNG: chunk walk; IHDR first, at least one IDAT, IEND last. CRCs are checked
// for files up to 64 MB.
// shortcut: CRCs skipped above 64 MB to keep the probe fast; upgrade if large corrupt PNGs show up.
ContainerOk _png(ByteSource src) {
  final checkCrc = src.length <= 64 << 20;
  var o = 8;
  int? w, h;
  var idat = false;
  for (var guard = 0; guard < 1000000; guard++) {
    final head = ByteData.sublistView(_need(src, o, 8));
    final len = head.getUint32(0);
    final type = String.fromCharCodes(Uint8List.sublistView(head.buffer.asUint8List(head.offsetInBytes, 8), 4));
    if (len > 0x7fffffff || o + 12 + len > src.length) throw const MalformedImage();
    if (w == null && type != 'IHDR') throw const MalformedImage();
    if (type == 'IHDR') {
      if (w != null || len != 13) throw const MalformedImage();
      final d = ByteData.sublistView(_need(src, o + 8, 8));
      w = d.getUint32(0);
      h = d.getUint32(4);
      _checkSize(w, h);
    }
    if (checkCrc) {
      final crc = ByteData.sublistView(_need(src, o + 8 + len, 4)).getUint32(0);
      if (_crc32(src, o + 4, len + 4) != crc) throw const MalformedImage();
    }
    if (type == 'IDAT') idat = true;
    o += 12 + len;
    if (type == 'IEND') {
      if (!idat) throw const MalformedImage();
      return ContainerOk(ContainerFormat.png, w!, h!);
    }
  }
  throw const MalformedImage();
}

// WebP: RIFF length must fit the file; size from the first VP8, VP8L or VP8X chunk.
ContainerOk _webp(ByteSource src) {
  final riff = ByteData.sublistView(_need(src, 4, 4)).getUint32(0, Endian.little);
  if (riff < 4 || riff + 8 > src.length) throw const MalformedImage();
  final c = _need(src, 12, 8);
  final kind = String.fromCharCodes(c, 0, 4);
  final d = ByteData.sublistView(_need(src, 20, 10));
  final int w, h;
  switch (kind) {
    case 'VP8 ':
      if (d.getUint8(3) != 0x9d || d.getUint8(4) != 0x01 || d.getUint8(5) != 0x2a) throw const MalformedImage();
      w = d.getUint16(6, Endian.little) & 0x3fff;
      h = d.getUint16(8, Endian.little) & 0x3fff;
    case 'VP8L':
      if (d.getUint8(0) != 0x2f) throw const MalformedImage();
      final bits = d.getUint32(1, Endian.little);
      w = (bits & 0x3fff) + 1;
      h = ((bits >> 14) & 0x3fff) + 1;
    case 'VP8X':
      w = (d.getUint8(4) | d.getUint8(5) << 8 | d.getUint8(6) << 16) + 1;
      h = (d.getUint8(7) | d.getUint8(8) << 8 | d.getUint8(9) << 16) + 1;
    default:
      throw const MalformedImage();
  }
  _checkSize(w, h);
  return ContainerOk(ContainerFormat.webp, w, h);
}

// GIF: logical screen size; the file must end with the trailer byte.
ContainerOk _gif(ByteSource src) {
  final d = ByteData.sublistView(_need(src, 6, 4));
  final w = d.getUint16(0, Endian.little), h = d.getUint16(2, Endian.little);
  _checkSize(w, h);
  if (src.length < 14 || _need(src, src.length - 1, 1)[0] != 0x3b) throw const MalformedImage();
  return ContainerOk(ContainerFormat.gif, w, h);
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});

int _crc32(ByteSource src, int o, int n) {
  var c = 0xffffffff;
  const chunk = 1 << 16;
  for (var at = o; at < o + n; at += chunk) {
    final b = _need(src, at, (o + n - at).clamp(0, chunk));
    for (final x in b) {
      c = _crcTable[(c ^ x) & 0xff] ^ (c >>> 8);
    }
  }
  return c ^ 0xffffffff;
}
