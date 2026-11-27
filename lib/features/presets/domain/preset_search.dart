import '../../target/domain/number_text.dart';
import 'preset_types.dart';

/// Longest search text read (PRD section 8 [Assumption]); the rest is ignored.
const maxSearchLength = 100;

/// Latin letters with a diacritic, folded to the base letter.
const _fold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', 'ç': 'c', 'è': 'e', 'é': 'e', //
  'ê': 'e', 'ë': 'e', 'ē': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'ñ': 'n', 'ò': 'o',
  'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ō': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'ý': 'y', 'ÿ': 'y',
};

/// Combining marks (U+0300–U+036F), Arabic harakat (U+064B–U+065F, U+0670) and tatweel (U+0640).
final _marks = RegExp('[\u0300-\u036F\u064B-\u065F\u0670\u0640]');

/// Search form of [raw] (FEAT-011 FR-8): cut to 100 characters, FEAT-005 cleaning (spaces,
/// bidi marks, native digits), lowercase, diacritics folded. Never throws.
String searchKey(String raw) {
  var cut = raw.length <= maxSearchLength ? raw : raw.substring(0, maxSearchLength);
  // Do not end on half of a surrogate pair.
  if (cut.length == maxSearchLength && _isHigh(cut.codeUnitAt(cut.length - 1))) cut = cut.substring(0, cut.length - 1);
  return _clean(cut);
}

/// Cleaning without the cut, for data terms (names may be longer than a query).
String _clean(String text) {
  final lower = cleanNumberText(text).toLowerCase().replaceAll(_marks, '');
  final out = StringBuffer();
  for (final c in lower.split('')) {
    out.write(_fold[c] ?? c);
  }
  return out.toString();
}

bool _isHigh(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

/// One country section of the list (FR-6).
final class FormSection {
  const FormSection({required this.country, required this.name, required this.forms});

  /// ISO code.
  final String country;

  /// Localized country name (section heading).
  final String name;
  final List<PresetForm> forms;
}

/// Forms matching [query] in sections by localized country name, forms by name (FR-6, FR-8).
/// A form matches when the query is a substring of its name, issuer, an alias, its country
/// name or [localTerms] (the localized category label). An empty query returns every form.
List<FormSection> filterForms(
  List<PresetForm> forms,
  String query,
  String Function(PresetForm form) localTerms,
  String Function(String country) countryName,
) {
  final q = searchKey(query);
  final byCountry = <String, List<PresetForm>>{};
  for (final f in forms) {
    final terms = [f.name, f.issuer, ...f.aliases, countryName(f.country), localTerms(f)];
    if (q.isEmpty || terms.any((t) => _clean(t).contains(q))) {
      (byCountry[f.country] ??= []).add(f);
    }
  }
  int byText(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
  return [
    for (final MapEntry(key: code, value: list) in byCountry.entries)
      FormSection(
        country: code,
        name: countryName(code),
        forms: List.unmodifiable(list..sort((a, b) => byText(a.name, b.name) != 0 ? byText(a.name, b.name) : a.id.compareTo(b.id))),
      ),
  ]..sort((a, b) => byText(a.name, b.name) != 0 ? byText(a.name, b.name) : a.country.compareTo(b.country));
}
