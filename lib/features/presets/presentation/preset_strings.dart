import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../compression/domain/compression_result.dart';
import '../domain/preset_types.dart';

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

  /// "200 × 230 px · 20–50 KB · JPEG", or "… · up to 20 KB · …" without a minimum (FR-6).
  String summary(PresetSpec s) {
    // One LTR isolate opens in the width and closes in the height (as CheckMessages.pixels).
    final pixels = _l10n.checkPixels('\u2066${_number.format(s.width)}', '${_number.format(s.height)}\u2069');
    final format = _lri(s.format == OutputFormat.jpeg ? 'JPEG' : 'PNG');
    return switch (s.minKb) {
      final min? => _l10n.presetSpecRange(pixels, _lri(_l10n.kbRange(_number.format(min), _number.format(s.maxKb))), format),
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

  static String _fsi(String s) => '\u2068$s\u2069';
  static String _lri(String s) => '\u2066$s\u2069';
}
