import 'dart:typed_data';

import '../domain/orientation.dart';
import 'byte_source.dart';
import 'heif_meta.dart';

/// HEIC/HEIF orientation as an EXIF value 1–8 (ADR-004 v1.1).
///
/// Android's decoders never apply `irot`/`imir`, and `ExifInterface` answers
/// differently per API level, so we read it ourselves: the primary item's
/// `irot`/`imir` in file order; if it has neither, `TAG_ORIENTATION` from the
/// file's `Exif` item; else 1. A damaged structure also gives 1 here (the
/// container check reports damage).
int heifOrientation(ByteSource src) {
  final HeifMeta meta;
  try {
    meta = HeifMeta.parse(src);
  } on MalformedImage {
    return 1;
  }
  if (meta.transforms.isNotEmpty) {
    var o = Orientation.identity;
    for (final t in meta.transforms) {
      o = o.then(switch (t) {
        HeifRotation(:final quarterTurns) => Orientation.rotation(-quarterTurns), // irot is anticlockwise
        HeifMirror(leftRight: true) => Orientation.fromExif(2),
        HeifMirror(leftRight: false) => Orientation.fromExif(4),
      });
    }
    return exifValueOf(o);
  }
  final exif = meta.exif;
  if (exif == null || exif.length < 8 || exif.length > 1 << 20) return 1;
  final payload = src.read(exif.offset, exif.length);
  final d = ByteData.sublistView(payload);
  if (payload.length < 4) return 1;
  final tiff = 4 + d.getUint32(0); // exif_tiff_header_offset (HEIF Annex A)
  return tiffOrientation(payload, tiff) ?? 1;
}

/// The EXIF value whose transform equals [o].
int exifValueOf(Orientation o) {
  for (var v = 1; v <= 8; v++) {
    if (Orientation.fromExif(v) == o) return v;
  }
  return 1; // unreachable: the 8 values cover D4
}

/// `TAG_ORIENTATION` (0x0112) from IFD0 of a TIFF structure starting at
/// [start] in [b]; null when absent, outside 1–8, or the structure is broken.
int? tiffOrientation(Uint8List b, int start) {
  if (start < 0 || start + 8 > b.length) return null;
  final d = ByteData.sublistView(b);
  final Endian e;
  if (b[start] == 0x49 && b[start + 1] == 0x49) {
    e = Endian.little;
  } else if (b[start] == 0x4d && b[start + 1] == 0x4d) {
    e = Endian.big;
  } else {
    return null;
  }
  if (d.getUint16(start + 2, e) != 42) return null;
  final ifd = start + d.getUint32(start + 4, e);
  if (ifd < start || ifd + 2 > b.length) return null;
  final count = d.getUint16(ifd, e);
  for (var i = 0; i < count; i++) {
    final entry = ifd + 2 + i * 12;
    if (entry + 12 > b.length) return null;
    if (d.getUint16(entry, e) != 0x0112) continue;
    if (d.getUint16(entry + 2, e) != 3) return null; // SHORT
    final v = d.getUint16(entry + 8, e);
    return v >= 1 && v <= 8 ? v : null;
  }
  return null;
}
