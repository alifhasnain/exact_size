import 'package:exact_size/features/preview/data/spec_check_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-006-T03: enum-only spec check log lines (FR-19, OQ-T6).
void main() {
  final pattern = RegExp(
      r'^exactsize\.preview outcome=(SPEC_MEETS|SPEC_MISMATCH fields=(DIMENSIONS|SIZE|FORMAT)(,(DIMENSIONS|SIZE|FORMAT))*|SPEC_UNREADABLE|PREVIEW_UNAVAILABLE)$');

  test('every line matches the FR-19 pattern; fields keep display order', () {
    final lines = <String>[];
    final log = SpecCheckLog(lines.add);
    log.outcome(SpecOutcome.meets);
    log.outcome(SpecOutcome.unreadable);
    log.outcome(SpecOutcome.previewUnavailable);
    for (var mask = 1; mask < 8; mask++) {
      log.outcome(SpecOutcome.mismatch, {for (final f in SpecField.values.reversed) if (mask & (1 << f.index) != 0) f});
    }
    expect(lines, hasLength(10));
    for (final l in lines) {
      expect(l, matches(pattern));
    }
    expect(lines.last, 'exactsize.preview outcome=SPEC_MISMATCH fields=DIMENSIONS,SIZE,FORMAT');
  });
}
