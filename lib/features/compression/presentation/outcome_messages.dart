import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/compression_result.dart';
import '../domain/target_validator.dart';

/// Text for a failure: the message, plus an optional hint line (FR-10, PRD
/// section 9). Kept apart so no message is joined by concatenation (NFR-4).
final class FailureText {
  const FailureText(this.message, [this.hint]);
  final String message;
  final String? hint;
}

/// Maps FEAT-004 outcomes to localised text (FR-11, NFR-4; tech.md).
///
/// Every number and "KB" goes through [AppLocalizations] and is wrapped in
/// Unicode first-strong isolates (U+2068 … U+2069), so sizes stay readable in
/// Arabic. Achieved sizes are rounded away from the target, so the shown
/// value is never inside the range when the file is not (see [achievedKb]).
class OutcomeMessages {
  OutcomeMessages(this._l10n) : _number = NumberFormat.decimalPattern(_l10n.localeName);

  final AppLocalizations _l10n;
  final NumberFormat _number;

  /// [minKb] and [maxKb] are the target the user asked for.
  FailureText failure(CompressionFailure f, {required int? minKb, required int maxKb}) {
    final l = _l10n;
    return switch (f.reason) {
      Reason.aboveMax ||
      Reason.tooDegraded ||
      Reason.noFit ||
      Reason.belowMin ||
      Reason.pngAboveMax ||
      Reason.pngBelowMin =>
        FailureText(
          _cantReach(f, minKb: minKb, maxKb: maxKb),
          switch (f.reason) {
            Reason.pngAboveMax when f.jpegWouldFit => l.outcomeHintJpegWouldFit,
            Reason.pngBelowMin => l.outcomeHintTryJpeg,
            _ => null,
          },
        ),
      // INVALID_TARGET is shown from TargetMessage (see [target]); this is
      // only reached if a caller has no message to show.
      Reason.invalidTarget => FailureText(l.targetInvalidNumber),
      Reason.unsupportedInput => FailureText(l.outcomeUnsupportedInput),
      Reason.imageTooLarge => FailureText(l.outcomeImageTooLarge),
      Reason.outOfMemoryHandled => FailureText(l.outcomeOutOfMemory),
      Reason.writeFailed => FailureText(l.outcomeWriteFailed),
      Reason.cancelled => FailureText(l.outcomeCancelled),
    };
  }

  String notice(Notice n) => switch (n) {
        Notice.narrowRange => _l10n.noticeNarrowRange,
        Notice.paddingAdded => _l10n.noticePaddingAdded,
        Notice.transparencyFlattened => _l10n.noticeTransparencyFlattened,
      };

  /// PRD section 8 validation messages (FR-16).
  String target(TargetMessage m) => switch (m) {
        TargetMessage.maxOutOfRange =>
          _l10n.targetMaxOutOfRange(_iso(_number.format(minMaxKb)), _kb(maxKbLimit)),
        TargetMessage.minNotBelowMax => _l10n.targetMinNotBelowMax,
        TargetMessage.wholeNumbersOnly => _l10n.targetWholeNumbersOnly,
        TargetMessage.invalidNumber => _l10n.targetInvalidNumber,
        TargetMessage.chooseJpegOrPng => _l10n.targetChooseJpegOrPng,
      };

  /// Screen-reader progress text for pass [pass] of [total] (NFR-5).
  String progress(int pass, int total) =>
      _l10n.announceProgress(_iso(_number.format(pass)), _iso(_number.format(total)));

  /// Screen-reader text for a file inside the window (NFR-5). Rounded to the
  /// nearest 0.1 KB of 1000 bytes, which always stays within min–max (FR-3).
  String success(CompressionSuccess s) => _l10n.announceSuccess(_kb(achievedKb(s.sizeBytes, null)));

  /// Pixels did not match the target (PRD section 8; a programming error).
  String get internalError => _l10n.outcomeInternalError;

  String _cantReach(CompressionFailure f, {required int? minKb, required int maxKb}) {
    final achieved = _kb(achievedKb(f.closestBytes ?? 0, f.direction));
    return minKb == null
        ? _l10n.outcomeCantReachMax(_kb(maxKb), achieved)
        : _l10n.outcomeCantReachRange(
            _iso(_l10n.kbRange(_number.format(minKb), _number.format(maxKb))), achieved);
  }

  String _kb(num value) => _iso(_l10n.kbAmount(_number.format(value)));

  static String _iso(String s) => '\u2068$s\u2069';
}

/// Closest size in KB with one decimal, rounded away from the target window
/// (FR-3: floor min×1024, ceiling max×1000) [Assumption, to confirm with the
/// Product Owner]: too big counts 1000 bytes per KB and rounds up, too small
/// counts 1024 and rounds down. So 50,001 B is "50.1 KB" against a 50 KB max,
/// and 20,000 B is "19.5 KB" against a 20 KB min, never a value in range.
double achievedKb(int bytes, Direction? direction) => switch (direction) {
      Direction.tooSmall => (bytes * 10 ~/ 1024) / 10,
      Direction.tooBig => ((bytes * 10 + 999) ~/ 1000) / 10,
      null => (bytes * 10 / 1000).round() / 10,
    };
