import 'dart:math';
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

/// No setting reached the floor, so [candidate] goes to padding (FR-8 lever 4,
/// T12). [jumpCase] (OQ-12): the size jumped over a narrow window, so a
/// failure to pad is `NO_FIT` rather than `BELOW_MIN`.
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

/// Encoder settings tried in order (tech.md): A is the base; B and C are FR-8
/// levers 2 and 3. Baseline only: progressive is never requested.
enum JpegConfig {
  a(Subsampling.yuv420, true),
  b(Subsampling.yuv444, true),
  c(Subsampling.yuv444, false);

  const JpegConfig(this.subsampling, this.optimiseHuffman);
  final Subsampling subsampling;
  final bool optimiseHuffman;
}

/// JPEG size search (tech.md "Search algorithm" steps 1–4; FR-5, FR-7, FR-8
/// levers 1–3, OQ-12). Deterministic; at most [maxPasses] encodes.
///
/// Main path (A): A@100; if too big, binary search the largest quality in
/// [qFloor, 99] that fits under the ceiling, check q+1 and q+2 (size is not
/// always monotonic), keep the highest fit. Nothing ≥ [qFloor] fits → A@1
/// decides `ABOVE_MAX` or `TOO_DEGRADED`.
/// Floor path (A@100 below the floor): B@100, then a quality search in B or
/// C@100; whatever is still below the floor goes to padding.
/// Jump case (best A file under the ceiling is below a narrow floor): B and C
/// at the same quality, then padding.
SearchOutcome searchJpeg(Encoder encoder, ByteWindow window) =>
    _Search(encoder, window).run();

class _Search {
  _Search(this.encoder, this.window);

  final Encoder encoder;
  final ByteWindow window;
  final _sizes = <(JpegConfig, int), int>{};
  var _passes = 0;

  /// Per config, the highest-quality file seen with size ≤ hi (bytes kept).
  final _bestUnderHi = <JpegConfig, JpegCandidate>{};

  /// Largest file seen with size ≤ hi, any config: what padding starts from.
  JpegCandidate? _largestUnderHi;

  /// Size of config@q, or null when the pass budget is spent.
  int? _size(JpegConfig config, int q) {
    final cached = _sizes[(config, q)];
    if (cached != null) return cached;
    if (_passes >= maxPasses) return null;
    _passes++;
    final bytes = encoder.encodeJpeg(
        quality: q, subsampling: config.subsampling, optimiseHuffman: config.optimiseHuffman);
    _sizes[(config, q)] = bytes.length;
    if (bytes.length <= window.hi) {
      final c = JpegCandidate(q, config.subsampling, config.optimiseHuffman, bytes);
      final best = _bestUnderHi[config];
      if (best == null || q > best.quality) _bestUnderHi[config] = c;
      final largest = _largestUnderHi;
      if (largest == null || c.size > largest.size) _largestUnderHi = c;
    }
    return bytes.length;
  }

  /// Largest quality in [qFloor, 99] whose size ≤ hi, as tracked in
  /// [_bestUnderHi]. Returns false when the budget ran out.
  bool _binarySearch(JpegConfig config) {
    var l = qFloor, r = 99;
    while (l <= r) {
      final mid = (l + r) ~/ 2;
      final size = _size(config, mid);
      if (size == null) return false;
      if (size <= window.hi) {
        l = mid + 1;
      } else {
        r = mid - 1;
      }
    }
    return true;
  }

  JpegCandidate? _fitAtFloor(JpegConfig config) {
    final best = _bestUnderHi[config];
    return best != null && best.quality >= qFloor ? best : null;
  }

  SearchOutcome run() {
    final top = _size(JpegConfig.a, 100)!;
    if (window.contains(top)) return SearchFit(_bestUnderHi[JpegConfig.a]!);
    if (top < window.lo) return _floorPath();

    if (!_binarySearch(JpegConfig.a)) return _capped();
    final found = _fitAtFloor(JpegConfig.a);
    if (found == null) return _nothingAtFloor();
    for (final q in [found.quality + 1, found.quality + 2]) {
      if (q > 99 || _size(JpegConfig.a, q) == null) break;
    }
    final chosen = _bestUnderHi[JpegConfig.a]!;
    return chosen.size >= window.lo ? SearchFit(chosen) : _jumpCase(chosen.quality);
  }

  /// Step 4: A@100 is below the floor.
  SearchOutcome _floorPath() {
    final b100 = _size(JpegConfig.b, 100);
    if (b100 == null) return _pad(jumpCase: false);
    if (window.contains(b100)) return SearchFit(_bestUnderHi[JpegConfig.b]!);
    if (b100 > window.hi) {
      if (!_binarySearch(JpegConfig.b)) return _pad(jumpCase: false);
      final inB = _fitAtFloor(JpegConfig.b);
      if (inB != null && inB.size >= window.lo) return SearchFit(inB);
      return SearchBelowWindow(inB ?? _largestUnderHi!, jumpCase: false);
    }
    final c100 = _size(JpegConfig.c, 100);
    if (c100 == null) return _pad(jumpCase: false);
    if (window.contains(c100)) return SearchFit(_bestUnderHi[JpegConfig.c]!);
    if (c100 < window.lo) {
      return SearchBelowWindow(_bestUnderHi[JpegConfig.c]!, jumpCase: false);
    }
    return SearchBelowWindow(_bestUnderHi[JpegConfig.b]!, jumpCase: false); // C too big: pad B@100
  }

  /// Step 3 (OQ-12): best A file under the ceiling is below the narrow floor.
  SearchOutcome _jumpCase(int q) {
    for (final config in [JpegConfig.b, JpegConfig.c]) {
      final size = _size(config, q);
      if (size == null) break; // budget spent: pad what we have
      if (window.contains(size)) return SearchFit(_bestUnderHi[config]!);
    }
    return _pad(jumpCase: true);
  }

  SearchOutcome _pad({required bool jumpCase}) =>
      SearchBelowWindow(_largestUnderHi!, jumpCase: jumpCase);

  SearchOutcome _nothingAtFloor() {
    final atOne = _size(JpegConfig.a, 1);
    if (atOne == null) return _capped();
    if (atOne > window.hi) {
      return SearchFailure(Reason.aboveMax, closestBytes: atOne, direction: Direction.tooBig);
    }
    // Closest size at or above the floor: A@qFloor (always encoded by the
    // binary search; the smallest size seen is a fallback, never null).
    return SearchFailure(Reason.tooDegraded,
        closestBytes: _sizes[(JpegConfig.a, qFloor)] ?? _sizes.values.reduce(min),
        direction: Direction.tooBig);
  }

  /// Pass cap reached (NFR-1): best in-window candidate, else closest failure.
  SearchOutcome _capped() {
    for (final c in _bestUnderHi.values) {
      if (window.contains(c.size) && c.quality >= qFloor) return SearchFit(c);
    }
    final closest = _sizes.values.reduce((a, b) =>
        (a - window.hi).abs() <= (b - window.hi).abs() ? a : b);
    final tooBig = closest > window.hi;
    return SearchFailure(tooBig ? Reason.aboveMax : Reason.belowMin,
        closestBytes: closest,
        direction: tooBig ? Direction.tooBig : Direction.tooSmall);
  }
}
