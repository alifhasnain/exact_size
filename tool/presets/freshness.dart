// FEAT-011 FR-21, AC-7.4: release-checklist report on the bundled preset library.
// Prints the form count, then one "<id> <lastChecked>" line per form checked more than
// 90 days before today, for the Product Owner to accept or fix in the release record.
//
//   dart run tool/presets/freshness.dart [--today YYYY-MM-DD] [--file path]
import 'dart:convert';
import 'dart:io';

const maxAgeDays = 90;

/// Report lines for [json] (the presets.json text) on [today].
List<String> freshnessReport(String json, DateTime today) {
  final forms = (jsonDecode(json) as Map)['forms'] as List;
  final day = DateTime.utc(today.year, today.month, today.day);
  return [
    'forms: ${forms.length}',
    for (final f in forms.cast<Map>())
      if (DateTime.tryParse('${f['lastChecked']}') case final d?
          when day.difference(DateTime.utc(d.year, d.month, d.day)).inDays > maxAgeDays)
        '${f['id']} ${f['lastChecked']}'
      else if (DateTime.tryParse('${f['lastChecked']}') == null)
        '${f['id']} ${f['lastChecked']} (no valid date)',
  ];
}

void main(List<String> args) {
  String? arg(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final todayText = arg('--today');
  final today = todayText == null ? DateTime.now() : DateTime.parse(todayText);
  final file = File(arg('--file') ?? 'assets/presets/presets.json');
  freshnessReport(file.readAsStringSync(), today).forEach(stdout.writeln);
}
