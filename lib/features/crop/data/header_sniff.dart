import 'dart:typed_data';

import 'byte_source.dart';
import 'container_check.dart';
import 'heif_meta.dart';

/// Animation and alpha flags read from the container header (tech.md
/// `SourceProbe`). Never throws: a damaged header gives `false`.
({bool animated, bool alpha}) sniffHeader(ByteSource src, ContainerFormat format) {
  try {
    return switch (format) {
      ContainerFormat.jpeg => (animated: false, alpha: false),
      ContainerFormat.png => _png(src),
      ContainerFormat.webp => _webp(src),
      ContainerFormat.gif => _gif(src),
      ContainerFormat.heif => (animated: false, alpha: HeifMeta.parse(src).hasAlpha),
    };
  } on Object {
    return (animated: false, alpha: false);
  }
}

// IHDR colour type 4/6 or a tRNS chunk: alpha; acTL before IDAT: animated (APNG).
({bool animated, bool alpha}) _png(ByteSource src) {
  var o = 8;
  var animated = false, alpha = false;
  for (var i = 0; i < 10000; i++) {
    final h = src.read(o, 8);
    if (h.length < 8) break;
    final len = ByteData.sublistView(h).getUint32(0);
    final type = String.fromCharCodes(h, 4, 8);
    if (type == 'IHDR') {
      final ct = src.read(o + 8 + 9, 1);
      alpha = ct.isNotEmpty && (ct[0] == 4 || ct[0] == 6);
    }
    if (type == 'tRNS') alpha = true;
    if (type == 'acTL') animated = true;
    if (type == 'IDAT' || type == 'IEND') break;
    o += 12 + len;
  }
  return (animated: animated, alpha: alpha);
}

// VP8X flags (alpha 0x10, animation 0x02); VP8L header alpha bit; VP8: neither.
({bool animated, bool alpha}) _webp(ByteSource src) {
  final c = src.read(12, 25);
  if (c.length < 25) return (animated: false, alpha: false);
  return switch (String.fromCharCodes(c, 0, 4)) {
    'VP8X' => (animated: c[8] & 0x02 != 0, alpha: c[8] & 0x10 != 0),
    'VP8L' => (animated: false, alpha: (ByteData.sublistView(c).getUint32(9, Endian.little) >> 28) & 1 == 1),
    _ => (animated: false, alpha: false),
  };
}

// Block walk: two or more image descriptors = animated; a graphic control
// extension with the transparency flag = alpha.
({bool animated, bool alpha}) _gif(ByteSource src) {
  final lsd = src.read(10, 1);
  var o = 13;
  if (lsd.isNotEmpty && lsd[0] & 0x80 != 0) o += 3 * (2 << (lsd[0] & 7));
  var images = 0;
  var alpha = false;
  int skipSubBlocks(int at) {
    for (var i = 0; i < 1 << 20; i++) {
      final n = src.read(at, 1);
      if (n.isEmpty) return src.length;
      at += 1 + n[0];
      if (n[0] == 0) return at;
    }
    return src.length;
  }

  for (var i = 0; i < 100000 && o < src.length; i++) {
    final b = src.read(o, 1)[0];
    if (b == 0x3b) break;
    if (b == 0x21) {
      final ext = src.read(o + 1, 3);
      if (ext.length == 3 && ext[0] == 0xf9 && ext[2] & 1 == 1) alpha = true;
      o = skipSubBlocks(o + 2);
    } else if (b == 0x2c) {
      if (++images >= 2) break;
      final d = src.read(o + 9, 1);
      o += 10;
      if (d.isNotEmpty && d[0] & 0x80 != 0) o += 3 * (2 << (d[0] & 7));
      o = skipSubBlocks(o + 1); // LZW minimum code size, then data
    } else {
      break;
    }
  }
  return (animated: images >= 2, alpha: alpha);
}
