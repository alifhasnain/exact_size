import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FEAT-016-T08 (FR-3, FR-5, FR-6, FR-7, FR-15, NFR-7): privacy copy never overclaims, every
/// explainer part names its register IDs, and no other string talks about the network.
const locales = ['en', 'es', 'pt', 'hi', 'id', 'ar'];

/// FR-5: phrases that would overclaim (checked case-insensitively in the English privacy strings).
const bannedPhrases = [
  'never leaves', 'no data collected', '100%', 'secure', 'encrypted', 'anonymous', 'GPS', 'location removed',
  'compliant', 'certified', 'GDPR', 'PCI', 'Bangladesh Bank',
];

/// Latin tokens that survive translation, checked in every locale.
const latinTokens = ['100%', 'GPS', 'GDPR', 'PCI'];

/// FR-15: the only keys that may talk about the network.
const connectivityKeys = {'pickSourceUnavailable', 'privacyOffline', 'privacyOfflineTitle'};
final connectivityWords = RegExp(r'internet|connect|network|offline|online', caseSensitive: false);

bool isPrivacyKey(String key) => key.startsWith('privacy') || key == 'pickPrivacyNote' || key == 'exportPrivacy';

/// Explainer body keys: the six parts (FR-3).
bool isPartBody(String key) => key.startsWith('privacy') && !key.endsWith('Title') && key != 'privacyEntry';

Map<String, Object?> arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, Object?>;

Map<String, String> values(Map<String, Object?> arb) => {
      for (final MapEntry(:key, :value) in arb.entries)
        if (!key.startsWith('@') && value is String) key: value,
    };

List<String> bannedClaims(Map<String, String> strings) => [
      for (final MapEntry(:key, :value) in strings.entries)
        if (isPrivacyKey(key))
          for (final phrase in bannedPhrases)
            if (value.toLowerCase().contains(phrase.toLowerCase()))
              '$key: Privacy copy contains a banned claim: $phrase. Scope it to ExactSize or remove it (FEAT-016 FR-5).',
    ];

List<String> keyRuleProblems(Map<String, Object?> arb) {
  final problems = <String>[];
  for (final MapEntry(:key, :value) in values(arb).entries) {
    if (!key.startsWith('privacy')) continue;
    final description = ((arb['@$key'] as Map?)?['description'] as String?) ?? '';
    final needsId = key != 'privacyEntry' && key != 'privacyTitle';
    if ((needsId && !RegExp(r'\bC\d+\b').hasMatch(description)) || value.contains('{')) {
      problems.add('Privacy key $key is missing an ID, has a placeholder, or lacks a translation.');
    }
  }
  return problems;
}

List<String> connectivityTalk(Map<String, String> strings) => [
      for (final MapEntry(:key, :value) in strings.entries)
        if (!connectivityKeys.contains(key) && connectivityWords.hasMatch(value))
          '$key talks about the network ("$value"); ExactSize never needs a connection (FEAT-016 FR-15).',
    ];

List<String> sentences(String text) =>
    text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().isNotEmpty).toList();

int words(String text) => text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

void main() {
  final en = arb('en');
  final english = values(en);

  test('English privacy strings contain no banned claim (FR-5, FR-7)', () {
    expect(english.keys, containsAll(['pickPrivacyNote', 'exportPrivacy', 'privacyOnPhone']));
    expect(bannedClaims(english), isEmpty);
  });

  test('Latin tokens of the banned list appear in no locale\'s privacy strings (FR-5)', () {
    for (final locale in locales) {
      final hits = [
        for (final MapEntry(:key, :value) in values(arb(locale)).entries)
          if (isPrivacyKey(key))
            for (final t in latinTokens)
              if (value.contains(t)) '$locale $key: $t',
      ];
      expect(hits, isEmpty, reason: locale);
    }
  });

  test('every explainer key names its register IDs and has no placeholder (FR-6, NFR-7)', () {
    expect(keyRuleProblems(en), isEmpty);
  });

  test('every locale has every privacy key, translated (FR-6, FEAT-016-T16)', () {
    final keys = [for (final k in english.keys) if (k.startsWith('privacy') || k == 'pickPrivacyNote') k];
    expect(keys, hasLength(15));
    for (final locale in locales.where((l) => l != 'en')) {
      final strings = values(arb(locale));
      for (final k in keys) {
        expect(strings[k], isNotNull, reason: '$locale $k');
        expect(strings[k], isNot(english[k]), reason: '$locale $k is still English');
        expect(strings[k]!.contains('{'), isFalse, reason: '$locale $k');
      }
    }
  });

  test('only the allowed keys talk about the network (FR-15)', () {
    expect(connectivityTalk(english), isEmpty);
  });

  test('explainer bodies: at most 150 words, no sentence over 20 words (FR-3)', () {
    final bodies = [for (final MapEntry(:key, :value) in english.entries) if (isPartBody(key)) value];
    expect(bodies, hasLength(6));
    expect(bodies.map(words).reduce((a, b) => a + b), lessThanOrEqualTo(150));
    for (final s in bodies.expand(sentences)) {
      expect(words(s), lessThanOrEqualTo(20), reason: s);
    }
  });

  group('self-tests', () {
    test('a planted banned phrase fails with the PRD message', () {
      final scratch = {...english, 'privacyOnPhone': 'Your photo never leaves your phone.'};
      expect(bannedClaims(scratch), [
        'privacyOnPhone: Privacy copy contains a banned claim: never leaves. Scope it to ExactSize or remove it (FEAT-016 FR-5).',
      ]);
    });

    test('a missing register ID and a placeholder each fail', () {
      final scratch = {
        ...en,
        'privacyOnPhone': 'Text',
        '@privacyOnPhone': {'description': 'no id'},
        'privacyReads': 'Opens {name}.',
      };
      expect(keyRuleProblems(scratch), hasLength(2));
    });

    test('network talk in a key outside the allow-list fails', () {
      expect(connectivityTalk({...english, 'privacyKept': 'Works with no internet needed.'}), hasLength(1));
    });
  });
}
