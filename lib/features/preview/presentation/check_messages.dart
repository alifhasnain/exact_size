import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../compression/domain/byte_window.dart';
import '../../compression/domain/compression_result.dart';
import '../../compression/presentation/outcome_messages.dart' show achievedKb;
import '../../target/domain/target_spec.dart';
import '../domain/measured_output.dart';
import '../domain/spec_check.dart';

/// FEAT-006 check texts (PRD section 8, tech 4.5). Numbers are formatted for the locale with
/// Western digits and wrapped in bidi isolates here, never in the ARB; sizes reuse `kbAmount`,
/// `kbRange` and `achievedKb` exactly as FEAT-004 and FEAT-007 do.
class CheckMessages {
  CheckMessages(this._l10n) : _number = NumberFormat.decimalPattern(_l10n.localeName);

  final AppLocalizations _l10n;
  final NumberFormat _number;

  /// "W × H px". One LTR isolate opens in the width and closes in the height, so "W × H" keeps
  /// that order in RTL languages (as FEAT-007's ready line did).
  /// shortcut: relies on every ARB keeping {width} before {height}; T13 adds the all-locales test.
  String pixels(int width, int height) => _l10n.checkPixels(_open(width), _close(height));

  String format(OutputFormat f) => _ltr(f == OutputFormat.jpeg ? 'JPEG' : 'PNG');

  /// Target file size: "20–50 KB", or "Up to 100 KB" for a max-only target (AC-1.3).
  String targetSize(TargetSpec t) => switch (t.minKb) {
        final min? => _iso(_l10n.kbRange(_number.format(min), _number.format(t.maxKb))),
        null => _l10n.checkUpToKb(_kb(t.maxKb)),
      };

  /// Measured file size, rounded away from the target when outside it (FR-6).
  String measuredSize(MeasuredOutput m, SpecCheck c) => _kb(achievedKb(m.bytes, c.sizeDirection));

  /// FR-8 line; 1 KB counted as the window floor counts it, so the number has one definition.
  String alsoFits() => _l10n.checkAlsoFits1024(_kb(1), _iso(_number.format(ByteWindow.fromKb(minKb: 1, maxKb: 2).lo)));

  String status(bool meets) => meets ? _l10n.checkMeets : _l10n.checkDoesntMeet;

  /// AC-4.6 / FR-16: technical values only.
  String previewAlt(int width, int height, OutputFormat f) => _l10n.previewAlt(_open(width), _close(height), format(f));

  /// AC-8.2: one row as a sentence.
  String rowSentence(String label, String target, String measured, bool meets) =>
      _l10n.checkRowSentence(label, target, measured, status(meets));

  String _kb(num value) => _iso(_l10n.kbAmount(_number.format(value)));
  String _open(int n) => '\u2066${_number.format(n)}';
  String _close(int n) => '${_number.format(n)}\u2069';
  static String _iso(String s) => '\u2068$s\u2069';
  static String _ltr(String s) => '\u2066$s\u2069';
}
