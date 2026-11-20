import 'dart:typed_data';

import 'byte_window.dart';
import 'compression_result.dart';
import 'encoder.dart';
import 'subsampling.dart';

/// Lowest JPEG quality the app will export (FR-7, OQ-8: one floor, tuned in T26).
const qFloor = 40;

/// Hard limit on encode passes per search (NFR-1).
const maxPasses = 10;

/// One encoded JPEG and the settings that made it.
final class JpegCandidate {
  const JpegCandidate(this.quality, this.subsampling, this.optimiseHuffman, this.bytes);
  final int quality;
  final Subsampling subsampling;
  final bool optimiseHuffman;
  final Uint8List bytes;
  int get size => bytes.length;
}

/// What the search found. The service turns it into a [CompressionResult].
sealed class SearchOutcome {
  const SearchOutcome();
}

/// [candidate] is inside the window.
final class SearchFit extends SearchOutcome {
  const SearchFit(this.candidate);
  final JpegCandidate candidate;
}

/// Nothing reached the floor: A@100 is below it, or (jump case, OQ-12) the
/// best file under the ceiling is below it. The FR-8 levers (T11) and padding
/// (T12) continue from here. [candidate] is the largest file under the ceiling.
final class SearchBelowWindow extends SearchOutcome {
  const SearchBelowWindow(this.candidate, {required this.jumpCase});
  final JpegCandidate candidate;
  final bool jumpCase;
}

final class SearchFailure extends SearchOutcome {
  const SearchFailure(this.reason, {this.closestBytes, this.direction});
  final Reason reason;
  final int? closestBytes;
  final Direction? direction;
}

/// JPEG size search, main path (tech.md "Search algorithm" steps 1–2; FR-5, FR-7).
///
/// Config A (4:2:0, optimised Huffman). Encodes A@100; if too big, binary
/// searches the largest quality in [qFloor, 99] with size ≤ hi, then checks
/// q+1 and q+2 because size is not always monotonic, and keeps the highest
/// fitting quality. If nothing at or above [qFloor] fits, A@1 decides between
/// `ABOVE_MAX` and `TOO_DEGRADED`. Deterministic; at most [maxPasses] encodes.
SearchOutcome searchJpeg(Encoder encoder, ByteWindow window) {
  final s = _Search(encoder, window);
  return s.run();
}

class _Search {
  _Search(this.encoder, this.window);

  final Encoder encoder;
  final ByteWindow window;
  final _sizes = <int, int>{}; // quality → size, config A
  var _passes = 0;

  /// Highest quality seen so far with size ≤ hi (bytes kept only for this one).
  JpegCandidate? _best;

  /// Size of A@q, or null when the pass budget is spent.
  int? _size(int q) {
    final cached = _sizes[q];
    if (cached != null) return cached;
    if (_passes >= maxPasses) return null;
    _passes++;
    final bytes = encoder.encodeJpeg(
        quality: q, subsampling: Subsampling.yuv420, optimiseHuffman: true);
    _sizes[q] = bytes.length;
    if (bytes.length <= window.hi && (_best == null || q > _best!.quality)) {
      _best = JpegCandidate(q, Subsampling.yuv420, true, bytes);
    }
    return bytes.length;
  }

  SearchOutcome run() {
    final top = _size(100)!;
    if (window.contains(top)) return SearchFit(_best!);
    if (top < window.lo) return SearchBelowWindow(_best!, jumpCase: false);

    // Largest q in [qFloor, 99] with size ≤ hi.
    var l = qFloor, r = 99;
    while (l <= r) {
      final mid = (l + r) ~/ 2;
      final size = _size(mid);
      if (size == null) return _capped();
      if (size <= window.hi) {
        l = mid + 1;
      } else {
        r = mid - 1;
      }
    }
    final found = _best;
    if (found != null && found.quality >= qFloor) {
      for (final q in [found.quality + 1, found.quality + 2]) {
        if (q > 99) break;
        if (_size(q) == null) break; // budget spent: keep what we have
      }
      final chosen = _best!;
      return chosen.size >= window.lo
          ? SearchFit(chosen)
          : SearchBelowWindow(chosen, jumpCase: true);
    }
    // Nothing at or above the floor fits.
    final atOne = _size(1);
    if (atOne == null) return _capped();
    if (atOne > window.hi) {
      return SearchFailure(Reason.aboveMax, closestBytes: atOne, direction: Direction.tooBig);
    }
    return SearchFailure(Reason.tooDegraded,
        closestBytes: _sizes[qFloor], direction: Direction.tooBig);
  }

  /// Pass cap reached (NFR-1): best in-window candidate, else closest failure.
  SearchOutcome _capped() {
    final best = _best;
    if (best != null && window.contains(best.size) && best.quality >= qFloor) {
      return SearchFit(best);
    }
    final closest = _sizes.values.reduce((a, b) =>
        (a - window.hi).abs() <= (b - window.hi).abs() ? a : b);
    final tooBig = closest > window.hi;
    return SearchFailure(tooBig ? Reason.aboveMax : Reason.belowMin,
        closestBytes: closest,
        direction: tooBig ? Direction.tooBig : Direction.tooSmall);
  }
}
