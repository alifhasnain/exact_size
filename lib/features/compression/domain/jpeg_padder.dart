import 'dart:math';
import 'dart:typed_data';

import 'byte_window.dart';
import 'compression_result.dart';

/// Payload byte of every padding segment: a constant (space), so the padding
/// carries no user, device or time data (AC-2.3) and is deterministic (FR-15).
const paddingByte = 0x20;

/// Smallest COM segment: FF FE + 2-byte length with an empty payload.
const minSegment = 4;

/// Largest COM segment: the length field (≤ 65,535) counts itself, so
/// 2 marker bytes + 65,535 = 65,537 bytes.
const maxSegment = 65537;

sealed class PaddingOutcome {
  const PaddingOutcome();
}

final class Padded extends PaddingOutcome {
  const Padded(this.bytes, this.paddingBytes);
  final Uint8List bytes;
  final int paddingBytes;
}

/// Not enough room under the ceiling for even one empty COM segment.
final class PaddingFailed extends PaddingOutcome {
  const PaddingFailed(this.reason, this.closestBytes);
  final Reason reason;
  final int closestBytes;
}

/// FR-8 lever 4: raises [jpeg] into [window] with neutral JPEG comment (COM)
/// segments spliced right after the JFIF APP0 segment. Pixels are untouched
/// and nothing follows the EOI marker.
///
/// Target size `min(lo + min(1024, (hi − lo) ÷ 2), hi)`, at least 4 bytes of
/// padding. Fewer than 4 bytes of room under the ceiling → `BELOW_MIN`, or
/// `NO_FIT` in the narrow-window jump case (OQ-12).
PaddingOutcome padJpeg(Uint8List jpeg, ByteWindow window, {required bool jumpCase}) {
  final room = window.hi - jpeg.length;
  if (room < minSegment) {
    return PaddingFailed(jumpCase ? Reason.noFit : Reason.belowMin, jpeg.length);
  }
  final int target = min(window.lo + min(1024, (window.hi - window.lo) ~/ 2), window.hi);
  final int amount = max(minSegment, target - jpeg.length); // ≤ room, since target ≤ hi
  final at = _insertOffset(jpeg);
  final out = Uint8List(jpeg.length + amount)
    ..setRange(0, at, jpeg)
    ..setRange(at + amount, jpeg.length + amount, jpeg, at);
  var o = at;
  for (final seg in segmentSizes(amount)) {
    final len = seg - 2; // length field counts itself, not the FF FE marker
    out
      ..[o] = 0xFF
      ..[o + 1] = 0xFE
      ..[o + 2] = len >> 8
      ..[o + 3] = len & 0xFF;
    out.fillRange(o + 4, o + seg, paddingByte);
    o += seg;
  }
  return Padded(out, amount);
}

/// Splits [amount] (≥ 4) into COM segment sizes in [4, 65,537]: full segments,
/// then the remainder; a remainder under 4 borrows from the segment before it.
List<int> segmentSizes(int amount) {
  assert(amount >= minSegment);
  final sizes = <int>[];
  var left = amount;
  while (left > maxSegment) {
    sizes.add(maxSegment);
    left -= maxSegment;
  }
  if (left < minSegment) {
    sizes[sizes.length - 1] -= minSegment - left;
    left = minSegment;
  }
  return sizes..add(left);
}

/// Just after SOI and the APP0 segment that libjpeg-turbo writes first.
int _insertOffset(Uint8List jpeg) {
  if (jpeg.length >= 6 && jpeg[2] == 0xFF && jpeg[3] == 0xE0) {
    return 4 + ((jpeg[4] << 8) | jpeg[5]);
  }
  return 2; // no APP0: straight after SOI
}
