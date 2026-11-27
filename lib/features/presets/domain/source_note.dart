/// FEAT-014: pure helpers behind the source note (FR-3, FR-4, FR-6) and the CI data rules (FR-11).
/// No imports: the runtime and `test/presets/library_rules.dart` share these rules, so they cannot
/// drift apart.
library;

/// More than this many days after `lastChecked` shows the old-check prompt. Test-checked equal to
/// `maxAgeDays` in `tool/presets/freshness.dart` (FEAT-011 FR-21).
const staleAfterDays = 90;

/// C0 and C1 controls, DEL, and the bidi controls (ALM, LRM, RLM, LRE to RLO, LRI to PDI).
/// ZWNJ U+200C and ZWJ U+200D are allowed: some scripts need them.
final _controls = RegExp(r'[\u0000-\u001F\u007F-\u009F\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]');

bool hasControlChars(String s) => _controls.hasMatch(s);

/// The host of an `http` or `https` URL with no user info, as Dart parses it; null when the URL is
/// unusable (the Website line is then left out). Never returns scheme, port, path, query or fragment.
String? sourceHost(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final uri = Uri.tryParse(url);
  // Not `isAbsolute`: that also rejects a URL with a fragment, which still has a usable host.
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return null;
  if (uri.userInfo.isNotEmpty || uri.host.isEmpty) return null;
  final String host;
  try {
    host = Uri.decodeComponent(uri.host); // non-ASCII hosts come back percent-encoded
  } on ArgumentError {
    return null;
  } on FormatException {
    return null;
  }
  return host.isEmpty || hasControlChars(host) ? null : host;
}

/// `YYYY-MM-DD` from the date fields, ASCII digits, no time-zone conversion.
String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String _two(int n) => n.toString().padLeft(2, '0');

/// True only when the device's calendar date is more than [staleAfterDays] days after
/// [lastChecked]. A null date or a device date on or before it gives false (normal prompt).
bool isStale(DateTime? lastChecked, DateTime now) {
  if (lastChecked == null) return false;
  final today = DateTime.utc(now.year, now.month, now.day);
  final checked = DateTime.utc(lastChecked.year, lastChecked.month, lastChecked.day);
  return today.difference(checked).inDays > staleAfterDays;
}
