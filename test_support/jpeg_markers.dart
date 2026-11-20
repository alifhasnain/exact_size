import 'dart:typed_data';

/// Minimal JPEG marker parser for tests: walks segments up to SOS.
class JpegInfo {
  JpegInfo(this.markers, this.jfif, this.sof);

  /// Marker bytes in order (0xD8 for SOI, 0xE0 for APP0, ...), up to SOS.
  final List<int> markers;

  /// JFIF APP0 fields, or null when absent.
  final ({int units, int xDensity, int yDensity})? jfif;

  /// Frame header: marker (0xC0 baseline) and H/V sampling byte per component.
  final ({int marker, List<int> sampling})? sof;
}

JpegInfo parseJpeg(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) throw const FormatException('no SOI');
  final markers = <int>[0xD8];
  ({int units, int xDensity, int yDensity})? jfif;
  ({int marker, List<int> sampling})? sof;
  var i = 2;
  while (i + 4 <= b.length) {
    if (b[i] != 0xFF) throw FormatException('bad marker at $i');
    final m = b[i + 1];
    markers.add(m);
    final len = (b[i + 2] << 8) | b[i + 3];
    final seg = b.sublist(i + 4, i + 2 + len);
    if (m == 0xE0 && String.fromCharCodes(seg.sublist(0, 4)) == 'JFIF') {
      jfif = (
        units: seg[7],
        xDensity: (seg[8] << 8) | seg[9],
        yDensity: (seg[10] << 8) | seg[11],
      );
    } else if (m >= 0xC0 && m <= 0xCF && m != 0xC4 && m != 0xC8 && m != 0xCC) {
      final n = seg[5];
      sof = (marker: m, sampling: [for (var c = 0; c < n; c++) seg[6 + c * 3 + 1]]);
    }
    if (m == 0xDA) break; // SOS: entropy-coded data follows
    i += 2 + len;
  }
  return JpegInfo(markers, jfif, sof);
}
