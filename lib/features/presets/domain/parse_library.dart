import '../../compression/domain/compression_result.dart';
import '../../compression/domain/target_validator.dart';
import '../../crop/domain/crop_types.dart';
import '../../crop/domain/target_check.dart';
import 'preset_types.dart';

/// Runtime read of `presets.json` (FEAT-011 tech section 5). Never throws on
/// bad content: a bad spec is skipped and counted, a form with no valid spec
/// or no id/name is dropped and counted. Unknown fields are ignored.
/// Throws [FormatException] only when the root is not `{schema: 1, forms: [...]}`.
/// The stricter CI rules live in `test/presets/library_rules.dart`.
PresetLibrary parseLibrary(Object? json) {
  if (json is! Map || json['schema'] != 1 || json['forms'] is! List) {
    throw const FormatException('presets: unsupported root');
  }
  var skipped = 0;
  final forms = <PresetForm>[];
  for (final raw in json['forms'] as List) {
    if (raw is! Map) {
      skipped++;
      continue;
    }
    final id = _text(raw['id']);
    final name = _text(raw['name']);
    final specs = <PresetSpec>[];
    final kinds = <SpecKind>{};
    for (final s in raw['specs'] is List ? raw['specs'] as List : const []) {
      final spec = _spec(s);
      if (spec == null || !kinds.add(spec.kind)) {
        skipped++;
      } else {
        specs.add(spec);
      }
    }
    if (id == null || name == null || specs.isEmpty) {
      skipped++;
      continue;
    }
    final source = raw['source'];
    forms.add(PresetForm(
      id: id,
      name: name,
      issuer: _text(raw['issuer']) ?? '',
      country: _text(raw['country']) ?? '',
      category: FormCategory.values.where((c) => c.json == raw['category']).firstOrNull ?? FormCategory.other,
      aliases: List.unmodifiable([
        for (final a in raw['aliases'] is List ? raw['aliases'] as List : const [])
          ?_text(a),
      ]),
      source: PresetSource(
        title: source is Map ? _text(source['title']) ?? '' : '',
        url: source is Map ? _text(source['url']) : null,
      ),
      lastChecked: _date(raw['lastChecked']),
      specs: List.unmodifiable(specs),
    ));
  }
  return PresetLibrary(forms: List.unmodifiable(forms), skipped: skipped);
}

String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

DateTime? _date(Object? v) {
  if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return null;
  final d = DateTime.tryParse(v);
  return d == null ? null : DateTime.utc(d.year, d.month, d.day);
}

PresetSpec? _spec(Object? s) {
  if (s is! Map) return null;
  final kind = SpecKind.values.asNameMap()[s['kind']];
  final format = OutputFormat.values.asNameMap()[s['format']];
  final w = s['width'], h = s['height'], min = s['minKb'], max = s['maxKb'];
  if (kind == null || format == null || w is! int || h is! int || max is! int) return null;
  if (min != null && min is! int) return null;
  if (checkTarget(Target(w, h)) != null) return null;
  if (validateTarget(maxText: '$max', minText: min == null ? '' : '$min', format: format.name) is! ValidTarget) return null;
  final notes = <NotCovered>[];
  for (final n in s['notCovered'] is List ? s['notCovered'] as List : const []) {
    final note = switch (n) {
      {'code': 'dpi', 'dpi': final int dpi} => DpiNote(dpi),
      {'code': 'background'} => const BackgroundNote(),
      {'code': 'content'} => const ContentNote(),
      _ => null,
    };
    if (note == null) return null;
    notes.add(note);
  }
  if (s['notCovered'] != null && s['notCovered'] is! List) return null;
  final review = s['engineReview'];
  return PresetSpec(
    kind: kind,
    width: w,
    height: h,
    minKb: min as int?,
    maxKb: max,
    format: format,
    notCovered: List.unmodifiable(notes),
    engineReview: review is String ? review : null,
  );
}
