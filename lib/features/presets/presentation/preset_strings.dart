import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../compression/domain/compression_result.dart';
import '../domain/preset_types.dart';
import '../domain/source_note.dart';

/// FEAT-011 texts (FR-6, FR-13, FR-14, tech section 6). Codes map to ARB getters here.
/// Form names are data: wrapped in a first-strong isolate, never translated. Numbers use
/// the locale's grouping with Western digits and sit in left-to-right isolates; sizes reuse
/// `checkPixels`, `kbRange` and `kbAmount` as FEAT-006 does.
class PresetStrings {
  PresetStrings(this._l10n) : _number = NumberFormat.decimalPattern(_l10n.localeName);

  final AppLocalizations _l10n;
  final NumberFormat _number;

  String kind(SpecKind k) => switch (k) {
    SpecKind.photo => _l10n.presetKindPhoto,
    SpecKind.signature => _l10n.presetKindSignature,
  };

  /// "form · kind" for the target-step row (FR-13).
  String applied(PresetForm form, SpecKind k) => _l10n.presetApplied(name(form), kind(k));

  /// A data name (form, issuer) in a first-strong isolate.
  String name(PresetForm form) => _fsi(form.name);

  /// "issuer · category" under the form name in the list (FR-6).
  String issuerLine(PresetForm form) => '${_fsi(form.issuer)} · ${category(form.category)}';

  /// "200 × 230 px · 20–50 KB · JPEG", or "… · up to 20 KB · …" without a minimum (FR-6);
  /// a KB-only spec shows "Pixel size not stated" in place of the pixel size.
  String summary(PresetSpec s) {
    // One LTR isolate opens in the width and closes in the height (as CheckMessages.pixels).
    final pixels = switch ((s.width, s.height)) {
      (final w?, final h?) => _l10n.checkPixels('\u2066${_number.format(w)}', '${_number.format(h)}\u2069'),
      _ => _l10n.presetAnyPixelSize, // KB-only spec (FR-6, 2.0)
    };
    final format = _lri(s.format == OutputFormat.jpeg ? 'JPEG' : 'PNG');
    return switch (s.minKb) {
      final min? => _l10n.presetSpecRange(
        pixels,
        _lri(_l10n.kbRange(_number.format(min), _number.format(s.maxKb))),
        format,
      ),
      null => _l10n.presetSpecUpTo(pixels, _lri(_l10n.kbAmount(_number.format(s.maxKb))), format),
    };
  }

  /// The fixed note for a rule ExactSize does not cover (FR-14).
  String note(NotCovered n) => switch (n) {
    DpiNote(:final dpi) => _l10n.presetNoteDpi(_lri(_number.format(dpi))),
    BackgroundNote() => _l10n.presetNoteBackground,
    ContentNote() => _l10n.presetNoteContent,
  };

  /// Country section heading; an unknown code shows the code itself.
  String country(String code) => _l10n.presetCountry(code);

  String category(FormCategory c) => _l10n.presetCategory(c.json);

  /// FEAT-014 source note (FR-3 to FR-6, tech section 4). Title and issuer are data in
  /// first-strong isolates; host, date and the number in left-to-right isolates. A missing part
  /// leaves its line out, never an empty "()" (AC-6.3).
  String? sourceLine(PresetForm f) => f.source.title.trim().isEmpty || f.issuer.trim().isEmpty
      ? null
      : _l10n.presetSourceLine(_fsi(f.source.title), _fsi(f.issuer));

  String? websiteLine(PresetForm f) => switch (sourceHost(f.source.url)) {
    final host? => _l10n.presetWebsiteLine(_lri(host)),
    null => null,
  };

  String? checkedLine(PresetForm f) => switch (f.lastChecked) {
    final d? => _l10n.presetLastChecked(_lri(isoDate(d))),
    null => null,
  };

  /// The fixed prompt; the old-check wording after [staleAfterDays] days (FR-5, FR-6).
  String prompt(PresetForm f, DateTime now) => isStale(f.lastChecked, now)
      ? _l10n.presetCheckNoticeOld(_lri(_number.format(staleAfterDays)))
      : _l10n.presetCheckNotice;

  /// The list card lines: no prompt there (FR-2). Empty when every part is missing.
  String cardSource(PresetForm f) => [sourceLine(f), websiteLine(f), checkedLine(f)].nonNulls.join('\n');

  /// The target-step block: the card lines, then the prompt (FR-1).
  String block(PresetForm f, DateTime now) =>
      [sourceLine(f), websiteLine(f), checkedLine(f), prompt(f, now)].nonNulls.join('\n');

  static String _fsi(String s) => '\u2068$s\u2069';
  static String _lri(String s) => '\u2066$s\u2069';
}
