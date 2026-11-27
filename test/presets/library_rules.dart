import 'package:exact_size/features/compression/domain/target_validator.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/target_check.dart';

/// FEAT-011 FR-19 CI rules (tech section 5), stricter than the runtime parser and never
/// shipped. Messages are the PRD section 8 texts with id and kind filled in.
/// [countries] and [categories] are the `select` cases of `presetCountry` and
/// `presetCategory`; self-tests pass their own sets, so `ZZ` never needs an ARB case.
List<String> libraryProblems(
  Object? json, {
  required DateTime today,
  required Set<String> countries,
  required Set<String> categories,
  bool shipped = false,
}) {
  final p = <String>[];
  if (json is! Map || json['schema'] != 1 || json['forms'] is! List) return ['Root must be {"schema": 1, "forms": [...]}.'];
  _unknown(p, 'Root', json, const {'schema', 'forms'});
  final ids = <String>{};
  final day = DateTime.utc(today.year, today.month, today.day);
  for (final f in json['forms'] as List) {
    if (f is! Map) {
      p.add('Every form must be an object.');
      continue;
    }
    final id = '${f['id']}';
    if (f['id'] is! String || !RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(id) || !ids.add(id)) {
      p.add('Form id $id is duplicated or not a valid slug.');
    }
    _unknown(p, 'Form $id', f, const {'id', 'name', 'issuer', 'country', 'category', 'aliases', 'source', 'lastChecked', 'specs'});
    _missing(p, 'Form $id', f, const ['id', 'name', 'issuer', 'country', 'category', 'aliases', 'source', 'lastChecked', 'specs']);
    if (!_text(f['name']) || !_text(f['issuer'])) p.add('Form $id: name and issuer are required.');
    if (f['country'] is! String || f['country'] == 'other' || !countries.contains(f['country'])) {
      p.add('Form $id: country ${f['country']} has no string key.');
    }
    if (!categories.contains(f['category'])) {
      p.add('Form $id: unknown category.');
    }
    if (f['aliases'] case final a? when a is! List || a.any((x) => !_text(x))) p.add('Form $id: aliases must be a list of names.');
    final source = f['source'];
    if (source is Map) _unknown(p, 'Form $id source', source, const {'title', 'url'});
    final date = _date(f['lastChecked']);
    if (source is! Map || !_text(source['title']) || date == null || date.isAfter(day)) {
      p.add('Form $id: source title and a valid last-checked date are required.');
    }
    if (shipped && (id.startsWith('test-') || '${f['name']}'.contains('Test Form'))) {
      p.add('Form $id: test entries must not ship (FR-1).');
    }
    final specs = f['specs'] is List ? f['specs'] as List : const [];
    final kinds = [for (final s in specs) s is Map ? s['kind'] : null];
    if (specs.isEmpty ||
        specs.length > 2 ||
        kinds.toSet().length != kinds.length ||
        kinds.any((k) => k != 'photo' && k != 'signature')) {
      p.add('Form $id: 1–2 specs, one per kind.');
    }
    for (final s in specs) {
      if (s is Map) _spec(p, id, s);
    }
  }
  return p;
}

void _spec(List<String> p, String id, Map s) {
  final at = 'Form $id ${s['kind']}';
  _unknown(p, at, s, const {'kind', 'width', 'height', 'minKb', 'maxKb', 'format', 'notCovered', 'engineReview'});
  _missing(p, at, s, const ['kind', 'width', 'height', 'minKb', 'maxKb', 'format']);
  final w = s['width'], h = s['height'];
  // 2.0: both null is a KB-only spec (no size check); exactly one null is an error; both present: 1.0 rule.
  if ((w == null) != (h == null)) {
    p.add('$at: give both width and height, or neither.');
  } else if (w != null && (w is! int || h is! int || w < 16 || h < 16 || checkTarget(Target(w, h)) != null)) {
    p.add('$at: size outside engine limits.');
  }
  final min = s['minKb'], max = s['maxKb'];
  final format = s['format'];
  if (max is! int ||
      (min != null && min is! int) ||
      validateTarget(maxText: '$max', minText: min == null ? '' : '$min', format: 'jpeg') is! ValidTarget) {
    p.add('$at: KB range invalid.');
  }
  if (format != 'jpeg' && format != 'png') p.add('$at: format must be jpeg or png.');
  final notes = s['notCovered'] ?? const [];
  final codes = <Object?>[];
  var bad = notes is! List;
  for (final n in notes is List ? notes : const []) {
    final ok = switch (n) {
      {'code': 'dpi', 'dpi': final int dpi} when n.length == 2 => dpi >= 1 && dpi <= 1200,
      {'code': 'background' || 'content'} when n.length == 1 => true,
      _ => false,
    };
    codes.add(n is Map ? n['code'] : n);
    bad = bad || !ok;
  }
  if (bad || codes.toSet().length != codes.length) p.add('$at: unknown or repeated note.');
  if (s['engineReview'] case final r? when !_text(r)) p.add('$at: engineReview must be a non-empty reason.');
}

void _unknown(List<String> p, String at, Map m, Set<String> known) {
  for (final k in m.keys) {
    if (!known.contains(k)) p.add('$at: unknown field $k.');
  }
}

void _missing(List<String> p, String at, Map m, List<String> required) {
  for (final k in required) {
    if (!m.containsKey(k)) p.add('$at: missing field $k.');
  }
}

bool _text(Object? v) => v is String && v.trim().isNotEmpty;

DateTime? _date(Object? v) {
  if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return null;
  final d = DateTime.tryParse(v);
  // tryParse accepts 2026-02-30 by rolling over; a real date prints back the same.
  if (d == null || d.toIso8601String().substring(0, 10) != v) return null;
  return DateTime.utc(d.year, d.month, d.day);
}

/// Top-level `select` cases of an ICU message such as `{code, select, IN{India} other{{code}}}`.
Set<String> selectCases(String message) {
  final body = message.substring(message.indexOf(',', message.indexOf(',') + 1) + 1);
  final cases = <String>{};
  var depth = 0;
  final name = StringBuffer();
  for (final ch in body.split('')) {
    if (ch == '{') {
      if (depth == 0) cases.add(name.toString().trim());
      depth++;
      name.clear();
    } else if (ch == '}') {
      depth--;
    } else if (depth == 0) {
      name.write(ch);
    }
  }
  return cases..remove('');
}
