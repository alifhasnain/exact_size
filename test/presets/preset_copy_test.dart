import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FEAT-011-T05 (FR-15, FR-17, NFR-5, AC-8.2): preset copy never sounds official, every key is
/// described, and the preset module holds no storage code.
const locales = ['en', 'es', 'pt', 'hi', 'id', 'ar'];
final banned = RegExp(r'official|approved|guaranteed', caseSensitive: false);

/// Code that could keep the user's choice or search text (AC-8.2).
const storageTokens = ['dart:io', 'path_provider', 'shared_preferences', 'restorationId', 'PageStorageKey', 'Clipboard'];

Map<String, Object?> arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, Object?>;

List<String> bannedInStrings(String locale, Map<String, Object?> arb) => [
      for (final MapEntry(:key, :value) in arb.entries)
        if (key.startsWith('preset') && value is String && banned.hasMatch(value))
          '$locale $key: preset copy must not say "${banned.firstMatch(value)![0]}" (FEAT-011 FR-15).',
    ];

List<String> bannedInAliases(Object? library) => [
      for (final f in (library as Map)['forms'] as List)
        for (final a in ((f as Map)['aliases'] as List?) ?? const [])
          if (banned.hasMatch('$a')) 'Form ${f['id']} alias "$a" must not say "${banned.firstMatch('$a')![0]}" (FR-15).',
    ];

List<String> missingDescriptions(Map<String, Object?> arb) => [
      for (final key in arb.keys)
        if (key.startsWith('preset') &&
            !(((arb['@$key'] as Map?)?['description'] as String?) ?? '').startsWith('FEAT-011'))
          '$key needs an @$key description starting "FEAT-011".',
    ];

List<String> storageCode(Map<String, String> files) => [
      for (final MapEntry(key: path, value: text) in files.entries)
        for (final (i, line) in text.split('\n').indexed)
          for (final t in storageTokens)
            if (line.contains(t)) '$path:${i + 1}: $t is not allowed in the preset module (AC-8.2).',
    ];

void main() {
  test('no preset string says official, approved or guaranteed (all locales)', () {
    expect([for (final l in locales) ...bannedInStrings(l, arb(l))], isEmpty);
  });

  test('no alias in the shipped file says it', () {
    expect(bannedInAliases(jsonDecode(File('assets/presets/presets.json').readAsStringSync())), isEmpty);
  });

  test('every preset key has a FEAT-011 description', () {
    final en = arb('en');
    expect(en.keys.where((k) => k.startsWith('preset')), isNotEmpty);
    expect(missingDescriptions(en), isEmpty);
  });

  test('the preset module has no storage, restoration or clipboard code', () {
    final files = {
      for (final f in Directory('lib/features/presets').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart')) f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
    };
    expect(files, isNotEmpty);
    expect(storageCode(files), isEmpty);
  });

  group('self-tests', () {
    test('a planted "official" in the English map fails naming the key', () {
      final en = {...arb('en'), 'presetListTitle': 'Official forms'};
      expect(bannedInStrings('en', en), ['en presetListTitle: preset copy must not say "Official" (FEAT-011 FR-15).']);
    });

    test('a planted alias fails naming the form', () {
      final lib = {
        'schema': 1,
        'forms': [
          {
            'id': 'test-form-a',
            'aliases': ['Approved list'],
          },
        ],
      };
      expect(bannedInAliases(lib), ['Form test-form-a alias "Approved list" must not say "Approved" (FR-15).']);
    });

    test('a missing description fails naming the key', () {
      final en = {...arb('en')}..remove('@presetNoMatch');
      expect(missingDescriptions(en), ['presetNoMatch needs an @presetNoMatch description starting "FEAT-011".']);
    });

    test('a scratch file with PageStorageKey fails with file:line', () {
      final dir = Directory.systemTemp.createTempSync('preset_copy');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = File('${dir.path}/scratch.dart')..writeAsStringSync('// a\nfinal k = PageStorageKey("search");\n');
      expect(storageCode({'scratch.dart': f.readAsStringSync()}),
          ['scratch.dart:2: PageStorageKey is not allowed in the preset module (AC-8.2).']);
    });
  });
}
