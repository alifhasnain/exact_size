import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FEAT-011-T05 (FR-15, FR-17, NFR-5, AC-8.2): preset copy never sounds official, every key is
/// described, and the preset module holds no storage code. FEAT-014-T02 (FR-8, FR-9, AC-5.5): more
/// banned words in English, and no selectable, tappable or link text in the module.
const locales = ['en', 'es', 'pt', 'hi', 'id', 'ar'];
final banned = RegExp(r'official|approved|guaranteed', caseSensitive: false);

/// FEAT-014 FR-9: "last checked" must not read as a promise. English only; translations are
/// checked by the /l10n-translate reviewer brief.
final bannedEn = RegExp(r'verified|accurate|up to date|latest|current|certified|compliant', caseSensitive: false);

/// Code that could keep the user's choice or search text (AC-8.2).
const storageTokens = ['dart:io', 'path_provider', 'shared_preferences', 'restorationId', 'PageStorageKey', 'Clipboard'];

/// Code that would make source text selectable, tappable or a link (FEAT-014 FR-8).
const interactionTokens = ['SelectableText', 'SelectionArea', 'GestureRecognizer', 'launchUrl'];

Map<String, Object?> arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, Object?>;

List<String> bannedInStrings(String locale, Map<String, Object?> arb) => [
      for (final MapEntry(:key, :value) in arb.entries)
        if (key.startsWith('preset') && value is String && banned.hasMatch(value))
          '$locale $key: preset copy must not say "${banned.firstMatch(value)![0]}" (FEAT-011 FR-15).',
    ];

List<String> bannedInEnglish(Map<String, Object?> en) => [
      for (final MapEntry(:key, :value) in en.entries)
        if (key.startsWith('preset') && value is String && bannedEn.hasMatch(value))
          'en $key: preset copy must not say "${bannedEn.firstMatch(value)![0]}" (FEAT-014 FR-9).',
    ];

List<String> bannedInAliases(Object? library) => [
      for (final f in (library as Map)['forms'] as List)
        for (final a in ((f as Map)['aliases'] as List?) ?? const [])
          if (banned.hasMatch('$a')) 'Form ${f['id']} alias "$a" must not say "${banned.firstMatch('$a')![0]}" (FR-15).',
    ];

List<String> missingDescriptions(Map<String, Object?> arb) => [
      for (final key in arb.keys)
        if (key.startsWith('preset') &&
            !RegExp('^FEAT-01[14]').hasMatch(((arb['@$key'] as Map?)?['description'] as String?) ?? ''))
          '$key needs an @$key description starting "FEAT-011" or "FEAT-014".',
    ];

List<String> storageCode(Map<String, String> files) => [
      for (final MapEntry(key: path, value: text) in files.entries)
        for (final (i, line) in text.split('\n').indexed)
          for (final t in storageTokens)
            if (line.contains(t)) '$path:${i + 1}: $t is not allowed in the preset module (AC-8.2).',
    ];

List<String> interactionCode(Map<String, String> files) => [
      for (final MapEntry(key: path, value: text) in files.entries)
        for (final (i, line) in text.split('\n').indexed)
          for (final t in interactionTokens)
            if (line.contains(t)) '$path:${i + 1}: $t is not allowed in the preset module (FEAT-014 FR-8).',
    ];

Map<String, String> moduleFiles() => {
      for (final f in Directory('lib/features/presets').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart')) f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
    };

void main() {
  test('no preset string says official, approved or guaranteed (all locales)', () {
    expect([for (final l in locales) ...bannedInStrings(l, arb(l))], isEmpty);
  });

  test('no English preset string says verified, accurate, up to date, latest, current, certified or compliant', () {
    expect(bannedInEnglish(arb('en')), isEmpty);
  });

  test('no alias in the shipped file says it', () {
    expect(bannedInAliases(jsonDecode(File('assets/presets/presets.json').readAsStringSync())), isEmpty);
  });

  test('every preset key has a FEAT-011 or FEAT-014 description', () {
    final en = arb('en');
    expect(en.keys.where((k) => k.startsWith('preset')), isNotEmpty);
    expect(missingDescriptions(en), isEmpty);
  });

  test('every locale has every preset key, translated (FEAT-011-T13)', () {
    // Keys made only of placeholders and separators read the same in every language.
    const structural = {'presetApplied', 'presetSpecRange', 'presetCountry'};
    final en = arb('en');
    final keys = en.keys.where((k) => k.startsWith('preset')).toSet();
    final untranslated = jsonDecode(File('docs/l10n/untranslated_messages.json').readAsStringSync()) as Map;
    for (final l in locales.skip(1)) {
      final t = arb(l);
      expect(keys.difference(t.keys.toSet()), isEmpty, reason: '$l is missing preset keys');
      for (final k in keys.difference(structural)) {
        expect(t[k], isNot(en[k]), reason: '$l $k is still English');
      }
      expect(((untranslated[l] as List?) ?? const []).where((k) => '$k'.startsWith('preset')), isEmpty, reason: l);
    }
  });

  test('the preset module has no storage, restoration or clipboard code', () {
    final files = moduleFiles();
    expect(files, isNotEmpty);
    expect(storageCode(files), isEmpty);
  });

  test('the preset module has no selectable, tappable or link text (FEAT-014 FR-8)', () {
    expect(interactionCode(moduleFiles()), isEmpty);
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
      expect(missingDescriptions(en),
          ['presetNoMatch needs an @presetNoMatch description starting "FEAT-011" or "FEAT-014".']);
    });

    test('a planted "verified" in the English map fails naming the key (FEAT-014)', () {
      final en = {...arb('en'), 'presetListTitle': 'Verified forms'};
      expect(bannedInEnglish(en), ['en presetListTitle: preset copy must not say "Verified" (FEAT-014 FR-9).']);
    });

    test('a scratch file with SelectableText fails with file:line (FEAT-014)', () {
      expect(interactionCode({'scratch.dart': '// a\nfinal w = SelectableText(host);\n'}),
          ['scratch.dart:2: SelectableText is not allowed in the preset module (FEAT-014 FR-8).']);
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
