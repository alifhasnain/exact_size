/// Accepted file-size window in bytes (FR-3, FR-4).
///
/// `lo = min×1024`, `hi = max×1000`, so the file passes whether a portal
/// counts 1 KB as 1000 or 1024 bytes. When that is impossible (max/min below
/// 1.024, for example 49–50 KB), the floor drops to `min×1000` and [narrow] is
/// set so the result carries the narrow-range notice. No min → `lo = 0`.
final class ByteWindow {
  const ByteWindow._(this.lo, this.hi, this.narrow);

  factory ByteWindow.fromKb({int? minKb, required int maxKb}) {
    final hi = maxKb * 1000;
    if (minKb == null) return ByteWindow._(0, hi, false);
    final lo = minKb * 1024;
    return lo > hi ? ByteWindow._(minKb * 1000, hi, true) : ByteWindow._(lo, hi, false);
  }

  final int lo;
  final int hi;
  final bool narrow;

  bool contains(int sizeBytes) => sizeBytes >= lo && sizeBytes <= hi;

  @override
  String toString() => 'ByteWindow[$lo, $hi${narrow ? ', narrow' : ''}]';
}
