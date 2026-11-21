import 'dart:typed_data';

import 'byte_source.dart';

/// Thrown by the bounded readers when the bytes do not form a valid structure.
final class MalformedImage implements Exception {
  const MalformedImage();
}

/// One transformative property of an item, in the order the file lists them
/// (HEIF, ISO/IEC 23008-12 6.5.10/6.5.12).
sealed class HeifTransform {
  const HeifTransform();
}

/// `irot`: anticlockwise rotation by [quarterTurns] × 90°.
final class HeifRotation extends HeifTransform {
  const HeifRotation(this.quarterTurns);
  final int quarterTurns;
}

/// `imir`: [leftRight] true exchanges left and right (mode 1), false exchanges
/// top and bottom (mode 0). This is the HEIF 2nd-edition `mode` reading, which
/// libheif and Android's `ImageDecoder` (API 36) follow: our T02 fixtures with
/// mode 1 display upright as EXIF 2 in both.
final class HeifMirror extends HeifTransform {
  const HeifMirror({required this.leftRight});
  final bool leftRight;
}

/// What the parsers need from a HEIF file's `meta` box: the primary item's
/// declared size and transforms, and where the `Exif` item lives.
final class HeifMeta {
  const HeifMeta({required this.width, required this.height, required this.transforms, this.exif});

  /// From the primary item's `ispe` (stored size, before `irot`/`imir`).
  final int width;
  final int height;
  final List<HeifTransform> transforms;

  /// Absolute file range of the `Exif` item payload, if there is one.
  final ({int offset, int length})? exif;

  static const _maxBoxes = 4096;

  /// Parses the top-level boxes of [src]. Throws [MalformedImage] when the
  /// structure is broken or truncated; every size is checked against the
  /// file length, nothing is allocated from a declared size.
  static HeifMeta parse(ByteSource src) {
    final top = _boxes(src, 0, src.length);
    final ftyp = top.where((b) => b.type == 'ftyp').firstOrNull;
    if (ftyp == null || top.first.type != 'ftyp' || !_isHeifBrand(src, ftyp)) throw const MalformedImage();
    final meta = top.where((b) => b.type == 'meta').firstOrNull ?? (throw const MalformedImage());
    // meta is a FullBox: 4 bytes version/flags before its children.
    final children = _boxes(src, meta.bodyStart + 4, meta.end);
    Box child(String t) => children.where((b) => b.type == t).firstOrNull ?? (throw const MalformedImage());

    final pitm = _Bytes(src, child('pitm'));
    final primary = pitm.u8(0) == 0 ? pitm.u16(4) : pitm.u32(4);

    final iprp = child('iprp');
    final iprpKids = _boxes(src, iprp.bodyStart, iprp.end);
    final ipco = iprpKids.where((b) => b.type == 'ipco').firstOrNull ?? (throw const MalformedImage());
    final props = _boxes(src, ipco.bodyStart, ipco.end);
    final assoc = <int>[];
    for (final ipma in iprpKids.where((b) => b.type == 'ipma')) {
      assoc.addAll(_associations(_Bytes(src, ipma), primary));
    }

    int? w, h;
    final transforms = <HeifTransform>[];
    for (final index in assoc) {
      if (index < 1 || index > props.length) throw const MalformedImage();
      final p = props[index - 1];
      final b = _Bytes(src, p);
      switch (p.type) {
        case 'ispe':
          w = b.u32(4);
          h = b.u32(8);
        case 'irot':
          transforms.add(HeifRotation(b.u8(0) & 3));
        case 'imir':
          transforms.add(HeifMirror(leftRight: b.u8(0) & 1 == 1));
      }
    }
    if (w == null || h == null || w <= 0 || h <= 0) throw const MalformedImage();

    final exifId = _exifItemId(src, children.where((b) => b.type == 'iinf').firstOrNull);
    final iloc = children.where((b) => b.type == 'iloc').firstOrNull;
    final idat = children.where((b) => b.type == 'idat').firstOrNull;
    final exif = exifId == null || iloc == null ? null : _itemLocation(src, iloc, idat, exifId);
    return HeifMeta(width: w, height: h, transforms: transforms, exif: exif);
  }

  static bool _isHeifBrand(ByteSource src, Box ftyp) {
    const brands = {'heic', 'heix', 'heim', 'heis', 'hevc', 'hevx', 'mif1', 'msf1', 'mif2'};
    final b = _Bytes(src, ftyp);
    for (var o = 0; o + 4 <= b.length; o += 4) {
      if (o == 4) continue; // minor version
      if (brands.contains(b.fourCC(o))) return true;
    }
    return false;
  }

  /// Property indices (1-based) associated with [item], in file order.
  static List<int> _associations(_Bytes b, int item) {
    final version = b.u8(0);
    final flags = b.u24(1);
    final count = b.u32(4);
    var o = 8;
    final out = <int>[];
    for (var i = 0; i < count; i++) {
      final id = version < 1 ? b.u16(o) : b.u32(o);
      o += version < 1 ? 2 : 4;
      final n = b.u8(o++);
      for (var j = 0; j < n; j++) {
        final int index;
        if (flags & 1 == 1) {
          index = b.u16(o) & 0x7fff;
          o += 2;
        } else {
          index = b.u8(o) & 0x7f;
          o += 1;
        }
        if (id == item) out.add(index);
      }
    }
    return out;
  }

  static int? _exifItemId(ByteSource src, Box? iinf) {
    if (iinf == null) return null;
    final b = _Bytes(src, iinf);
    final version = b.u8(0);
    final start = iinf.bodyStart + (version == 0 ? 6 : 8);
    for (final infe in _boxes(src, start, iinf.end).where((x) => x.type == 'infe')) {
      final e = _Bytes(src, infe);
      final v = e.u8(0);
      if (v < 2) continue; // v0/v1 carry no item_type
      final id = v == 2 ? e.u16(4) : e.u32(4);
      final typeAt = (v == 2 ? 6 : 8) + 2; // after item_protection_index
      if (e.fourCC(typeAt) == 'Exif') return id;
    }
    return null;
  }

  static ({int offset, int length})? _itemLocation(ByteSource src, Box iloc, Box? idat, int item) {
    final b = _Bytes(src, iloc);
    final version = b.u8(0);
    final sizes = b.u8(4), sizes2 = b.u8(5);
    final offSize = sizes >> 4, lenSize = sizes & 15, baseSize = sizes2 >> 4;
    final idxSize = version >= 1 ? sizes2 & 15 : 0;
    var o = 6;
    final count = version < 2 ? b.u16(o) : b.u32(o);
    o += version < 2 ? 2 : 4;
    for (var i = 0; i < count; i++) {
      final id = version < 2 ? b.u16(o) : b.u32(o);
      o += version < 2 ? 2 : 4;
      var method = 0;
      if (version >= 1) {
        method = b.u16(o) & 15;
        o += 2;
      }
      o += 2; // data_reference_index
      final base = b.uN(o, baseSize);
      o += baseSize;
      final extents = b.u16(o);
      o += 2;
      int? first, total = 0;
      for (var e = 0; e < extents; e++) {
        o += idxSize;
        final off = b.uN(o, offSize);
        o += offSize;
        final len = b.uN(o, lenSize);
        o += lenSize;
        first ??= base + off;
        total = total! + len;
      }
      if (id != item) continue;
      if (first == null || extents != 1) return null; // multi-extent Exif: not seen in practice
      final origin = switch (method) {
        0 => 0,
        1 => idat?.bodyStart ?? (throw const MalformedImage()),
        _ => throw const MalformedImage(),
      };
      final start = origin + first;
      if (start < 0 || total! < 0 || start + total > src.length) throw const MalformedImage();
      return (offset: start, length: total);
    }
    return null;
  }

  static List<Box> _boxes(ByteSource src, int start, int end) {
    final out = <Box>[];
    var o = start;
    while (o + 8 <= end) {
      if (out.length >= _maxBoxes) throw const MalformedImage();
      final h = src.read(o, 16);
      if (h.length < 8) throw const MalformedImage();
      final d = ByteData.sublistView(h);
      var size = d.getUint32(0);
      var header = 8;
      if (size == 1) {
        if (h.length < 16) throw const MalformedImage();
        final big = d.getUint32(8) * 4294967296 + d.getUint32(12);
        size = big;
        header = 16;
      } else if (size == 0) {
        size = end - o;
      }
      if (size < header || o + size > end) throw const MalformedImage();
      out.add(Box(String.fromCharCodes(h, 4, 8), o, o + header, o + size));
      o += size;
    }
    return out;
  }
}

/// A box: [type], absolute [start], [bodyStart] after the header, [end].
final class Box {
  const Box(this.type, this.start, this.bodyStart, this.end);
  final String type;
  final int start;
  final int bodyStart;
  final int end;
}

/// Bounds-checked big-endian reads inside one box body (bodies of the boxes
/// read here are small: at most 64 KB is loaded).
final class _Bytes {
  _Bytes(ByteSource src, Box box) : _b = src.read(box.bodyStart, (box.end - box.bodyStart).clamp(0, 65536)) {
    _d = ByteData.sublistView(_b);
  }
  final Uint8List _b;
  late final ByteData _d;

  int get length => _b.length;

  void _need(int o, int n) {
    if (o < 0 || o + n > _b.length) throw const MalformedImage();
  }

  int u8(int o) {
    _need(o, 1);
    return _d.getUint8(o);
  }

  int u16(int o) {
    _need(o, 2);
    return _d.getUint16(o);
  }

  int u24(int o) {
    _need(o, 3);
    return (_d.getUint8(o) << 16) | _d.getUint16(o + 1);
  }

  int u32(int o) {
    _need(o, 4);
    return _d.getUint32(o);
  }

  int uN(int o, int n) => switch (n) {
        0 => 0,
        4 => u32(o),
        8 => u32(o) * 4294967296 + u32(o + 4),
        _ => throw const MalformedImage(),
      };
  String fourCC(int o) {
    _need(o, 4);
    return String.fromCharCodes(_b, o, o + 4);
  }
}
