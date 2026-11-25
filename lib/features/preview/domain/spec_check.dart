import '../../compression/domain/byte_window.dart';
import '../../compression/domain/compression_result.dart';
import '../../target/domain/target_spec.dart';
import 'measured_output.dart';

/// Verdict of the measured output against the target (FR-3, FR-4, tech 4.2).
final class SpecCheck {
  const SpecCheck({required this.pixels, required this.size, required this.format, required this.window, required this.sizeDirection});

  final bool pixels;
  final bool size;
  final bool format;

  /// The one KB window definition (FR-4); `!window.narrow` shows the FR-8 line.
  final ByteWindow window;

  /// Null inside the window; otherwise which way the size misses (FR-6).
  final Direction? sizeDirection;

  bool get meets => pixels && size && format;

  @override
  String toString() => 'SpecCheck(<redacted>)';
}

/// Uses only width, height, minKb, maxKb and format of [t] (FR-3).
SpecCheck checkSpec(MeasuredOutput m, TargetSpec t) {
  final window = ByteWindow.fromKb(minKb: t.minKb, maxKb: t.maxKb);
  return SpecCheck(
    pixels: m.width == t.width && m.height == t.height,
    size: window.contains(m.bytes),
    format: m.format == t.format,
    window: window,
    sizeDirection: m.bytes > window.hi ? Direction.tooBig : (m.bytes < window.lo ? Direction.tooSmall : null),
  );
}
