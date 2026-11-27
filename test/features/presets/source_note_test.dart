import 'package:exact_size/features/presets/domain/source_note.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-014-T01: host, date, age and control-character rules (FR-3, FR-4, FR-6, FR-11, NFR-7).
/// Synthetic URLs only, except the two shipped examples named in tech section 4.
void main() {
  group('sourceHost', () {
    const cases = <String?, String?>{
      'http://dept.bpsc.gov.bd/node/photo': 'dept.bpsc.gov.bd', // shipped, http kept as is
      'https://www.ibps.in': 'www.ibps.in', // shipped
      'https://notice.example.test/page': 'notice.example.test',
      'http://notice.example.test/b': 'notice.example.test',
      'https://notice.example.test:8443/page?x=1#part': 'notice.example.test', // port, query, fragment dropped
      'https://192.0.2.10/notice': '192.0.2.10', // IP (documentation range)
      'https://NOTICE.Example.TEST/Page': 'notice.example.test', // Dart lowercases the host (OQ-T3)
      'https://bücher.example.test/': 'bücher.example.test', // IDN shown as written
      'https://[PLACEHOLDER]@notice.example.test': null, // user info or parse failure
      'https://user@notice.example.test/': null, // user info
      'ftp://notice.example.test/x': null,
      'notice.example.test/page': null, // relative
      '[PLACEHOLDER]': null,
      '': null,
      '   ': null,
      'https:///path': null, // no host
      'https://a\u202Eb.example.test/': null, // control character in host
      null: null,
    };
    for (final MapEntry(key: url, value: host) in cases.entries) {
      test('${url == null ? 'null' : '"$url"'} -> $host', () {
        expect(() => sourceHost(url), returnsNormally);
        expect(sourceHost(url), host);
      });
    }

    test('a 300-character URL does not throw', () {
      final url = 'https://notice.example.test/${'a' * 270}';
      expect(sourceHost(url), 'notice.example.test');
    });
  });

  group('isoDate', () {
    test('pads month and day', () => expect(isoDate(DateTime.utc(2026, 3, 5)), '2026-03-05'));
    test('pads year 1', () => expect(isoDate(DateTime.utc(1, 1, 1)), '0001-01-01'));
    test('ASCII digits only', () {
      expect(isoDate(DateTime.utc(2026, 11, 27)), matches(RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$')));
    });
    test('uses the date fields, no time-zone change', () {
      expect(isoDate(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
    });
  });

  group('isStale (PRD section 8 table, lastChecked 2026-03-05)', () {
    final checked = DateTime.utc(2026, 3, 5);
    final cases = <DateTime, bool>{
      DateTime(2026, 3, 1): false, // before
      DateTime(2026, 3, 5): false, // 0 days
      DateTime(2026, 6, 3): false, // 90 days
      DateTime(2026, 6, 4): true, // 91 days
      DateTime(2099, 1, 1): true, // very large
      DateTime(1970, 1, 1): false, // before
    };
    for (final MapEntry(key: now, value: stale) in cases.entries) {
      test('${isoDate(now)} -> ${stale ? 'old-check' : 'normal'}', () {
        expect(isStale(checked, now), stale);
      });
    }
    test('late evening local time still counts by calendar day', () {
      expect(isStale(checked, DateTime(2026, 6, 3, 23, 59)), isFalse);
    });
    test('null date gives the normal prompt', () => expect(isStale(null, DateTime(2099)), isFalse));
  });

  group('hasControlChars', () {
    const bidi = ['\u061C', '\u200E', '\u200F', '\u202A', '\u202B', '\u202C', '\u202D', '\u202E', '\u2066', '\u2067', '\u2068', '\u2069'];
    for (final c in bidi) {
      test('bidi control U+${c.codeUnitAt(0).toRadixString(16).toUpperCase()} matches', () {
        expect(hasControlChars('Test${c}Notice'), isTrue);
      });
    }
    test('C0, DEL and C1 samples match', () {
      for (final c in ['\u0000', '\t', '\n', '\u001F', '\u007F', '\u0085', '\u009F']) {
        expect(hasControlChars('a${c}b'), isTrue, reason: 'U+${c.codeUnitAt(0).toRadixString(16)}');
      }
    });
    test('ZWNJ and ZWJ are allowed', () {
      expect(hasControlChars('a\u200Cb'), isFalse);
      expect(hasControlChars('a\u200Db'), isFalse);
    });
    test('plain text in several scripts passes', () {
      expect(hasControlChars('Test Notice A (Test Issuer) बांग्लादेश الهند'), isFalse);
    });
  });
}
