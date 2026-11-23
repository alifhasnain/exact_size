/// Text cleaning and number reading for the target fields (FEAT-005 FR-4).
library;

/// Whitespace (Dart's `\s`, ECMAScript: includes U+00A0, U+202F, U+FEFF) and
/// the bidi controls U+200E, U+200F, U+061C, U+202A–U+202E, U+2066–U+2069.
final _dropped = RegExp('[\\s\u200E\u200F\u061C\u202A-\u202E\u2066-\u2069]');

/// First code unit of each native digit range mapped to 0–9 (FR-4 b).
const _digitZeros = [
  0x0660, // Arabic-Indic
  0x06F0, // Extended Arabic-Indic
  0x0966, // Devanagari
  0x09E6, // Bengali (PRD OQ-11)
];

/// FR-4 (a)–(c): drops whitespace and bidi controls, maps native digits to
/// 0–9 and `,` `٫` `٬` to `.`. Leading zeros and long digit strings stay as
/// typed (OQ-T2); this is what the field shows after it is left.
String cleanNumberText(String raw) {
  final out = StringBuffer();
  for (final c in raw.replaceAll(_dropped, '').runes) {
    final zero = _digitZeros.where((z) => c >= z && c <= z + 9).firstOrNull;
    if (zero != null) {
      out.writeCharCode(0x30 + c - zero);
    } else if (c == 0x2C || c == 0x066B || c == 0x066C) {
      out.write('.');
    } else {
      out.writeCharCode(c);
    }
  }
  return out.toString();
}

/// What a cleaned field holds.
sealed class NumberRead {
  const NumberRead();
}

final class Empty extends NumberRead {
  const Empty();
}

/// Digits only. More than [maxDigits] significant digits read as 999,999,999
/// (FR-4 d), so W×H stays inside int64 and nothing overflows.
final class Whole extends NumberRead {
  const Whole(this.value);
  final int value;
  @override
  bool operator ==(Object other) => other is Whole && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'Whole(<redacted>)';
}

/// Digits with at least one `.`, such as `7.5` or `1.000.000`.
final class NotWhole extends NumberRead {
  const NotWhole();
}

/// Anything else: signs, letters, units, hex, exponents.
final class NotNumber extends NumberRead {
  const NotNumber();
}

const maxDigits = 9;
final _whole = RegExp(r'^[0-9]+$');
final _notWhole = RegExp(r'^[0-9.]*[0-9][0-9.]*$');

/// Reads a [cleanNumberText] result.
NumberRead readNumber(String cleaned) {
  if (cleaned.isEmpty) return const Empty();
  if (_whole.hasMatch(cleaned)) {
    final significant = cleaned.replaceFirst(RegExp('^0+'), '');
    if (significant.length > maxDigits) return const Whole(999999999);
    return Whole(significant.isEmpty ? 0 : int.parse(significant));
  }
  if (_notWhole.hasMatch(cleaned)) return const NotWhole();
  return const NotNumber();
}
