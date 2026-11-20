import 'compression_result.dart';

/// Message for an invalid target (PRD section 8). The UI maps each key to an
/// ARB string (FEAT-004-T19); the domain only names it.
enum TargetMessage {
  /// "Enter a maximum size between 2 and 10,240 KB."
  maxOutOfRange,

  /// "Minimum must be smaller than maximum."
  minNotBelowMax,

  /// "Use whole numbers of KB."
  wholeNumbersOnly,

  /// "Enter a valid size in KB."
  invalidNumber,

  /// "Choose JPEG or PNG."
  chooseJpegOrPng,
}

/// Result of [validateTarget]: a typed target, or the first problem found.
sealed class TargetValidation {
  const TargetValidation();
}

final class ValidTarget extends TargetValidation {
  const ValidTarget({required this.maxKb, required this.format, this.minKb});
  final int? minKb;
  final int maxKb;
  final OutputFormat format;
}

/// Maps to `INVALID_TARGET` (FR-16) with [message]; nothing is encoded.
final class InvalidTarget extends TargetValidation {
  const InvalidTarget(this.message);
  final TargetMessage message;
  Reason get reason => Reason.invalidTarget;

  /// No size exists yet, so no closest size or direction (FR-11).
  CompressionFailure get failure => const CompressionFailure(reason: Reason.invalidTarget);
}

/// Largest maximum in R1: 10,240 KB = 10 MB (PRD section 8 [Assumption]).
const maxKbLimit = 10240;

/// Smallest maximum: 2 KB.
const minMaxKb = 2;

/// Validates the raw target the user typed (FR-16, PRD section 8) before any
/// encoding. [maxText] / [minText] are text-field contents (min may be empty =
/// unset); [format] is `jpeg` or `png`.
TargetValidation validateTarget({
  required String? maxText,
  String? minText,
  required String? format,
}) {
  final max = _parseKb(maxText, isRequired: true);
  final min = _parseKb(minText, isRequired: false);
  for (final p in [max, min]) {
    if (p case _Bad(:final message)) return InvalidTarget(message);
  }
  final maxKb = (max as _Ok).value!;
  final minKb = (min as _Ok).value;
  if (maxKb < minMaxKb || maxKb > maxKbLimit) {
    return const InvalidTarget(TargetMessage.maxOutOfRange);
  }
  if (minKb != null && minKb >= maxKb) {
    return const InvalidTarget(TargetMessage.minNotBelowMax);
  }
  final fmt = switch (format?.trim().toLowerCase()) {
    'jpeg' => OutputFormat.jpeg,
    'png' => OutputFormat.png,
    _ => null,
  };
  if (fmt == null) return const InvalidTarget(TargetMessage.chooseJpegOrPng);
  return ValidTarget(minKb: minKb, maxKb: maxKb, format: fmt);
}

sealed class _Parsed {}

final class _Ok extends _Parsed {
  _Ok(this.value);
  final int? value;
}

final class _Bad extends _Parsed {
  _Bad(this.message);
  final TargetMessage message;
}

_Parsed _parseKb(String? text, {required bool isRequired}) {
  final t = text?.trim() ?? '';
  if (t.isEmpty) return isRequired ? _Bad(TargetMessage.invalidNumber) : _Ok(null);
  final whole = int.tryParse(t);
  if (whole != null) {
    // Max must be > 0; a set min must be >= 1 (0 or negative is not a size).
    return whole < 1 ? _Bad(TargetMessage.invalidNumber) : _Ok(whole);
  }
  final d = double.tryParse(t);
  if (d == null || d.isNaN || d.isInfinite || d <= 0) return _Bad(TargetMessage.invalidNumber);
  return _Bad(TargetMessage.wholeNumbersOnly); // decimals are OQ-5: not in R1
}
