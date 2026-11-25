import 'package:flutter/foundation.dart' show debugPrint;

/// What the check found (FR-19).
enum SpecOutcome {
  meets('SPEC_MEETS'),
  mismatch('SPEC_MISMATCH'),
  unreadable('SPEC_UNREADABLE'),
  previewUnavailable('PREVIEW_UNAVAILABLE');

  const SpecOutcome(this.code);
  final String code;
}

/// A field that does not match, in display order.
enum SpecField {
  dimensions('DIMENSIONS'),
  size('SIZE'),
  format('FORMAT');

  const SpecField(this.code);
  final String code;
}

/// Where log lines go; replaceable in tests.
typedef SpecLogSink = void Function(String line);

void _debugPrintSink(String line) => debugPrint(line);

/// Spec check logging (FR-19, OQ-T6), same shape as `ExportOutcomeLog`. Enums only, so a line
/// can hold no size, dimension, path, name or exception text.
class SpecCheckLog {
  const SpecCheckLog([this._sink = _debugPrintSink]);

  final SpecLogSink _sink;

  /// [fields] is used only with [SpecOutcome.mismatch], and must then not be empty.
  void outcome(SpecOutcome o, [Set<SpecField> fields = const {}]) {
    assert((o == SpecOutcome.mismatch) == fields.isNotEmpty);
    final list = [for (final f in SpecField.values) if (fields.contains(f)) f.code].join(',');
    _sink('exactsize.preview outcome=${o.code}${o == SpecOutcome.mismatch ? ' fields=$list' : ''}');
  }
}
