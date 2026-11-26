import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FEAT-016-T05 (FR-10 Dart half, FR-11, NFR-5, NFR-10): every Dart package the app can load at
/// runtime must be on a reviewed list with a network, data and permissions note. The runtime set is
/// the closure from the root's direct (non-dev) dependencies in `dart pub deps --json`, so packages
/// that only dev tools pull in (code generators, the analyzer) are not in it. Versions are not
/// listed, so a version bump passes.
const reviewedPath = 'tool/privacy/reviewed_packages.txt';
const followFr12 = 'Follow FEAT-016 FR-12 (docs/features/FEAT-016-on-device-privacy/claims.md).';

/// Package names reachable from the root's `directDependencies` through `dependencies`.
Set<String> runtimePackages(Map<String, Object?> pubDeps) {
  final packages = {
    for (final p in (pubDeps['packages']! as List).cast<Map<String, Object?>>()) p['name']! as String: p,
  };
  final root = packages[pubDeps['root']]!;
  final seen = <String>{};
  final todo = [...(root['directDependencies']! as List).cast<String>()];
  while (todo.isNotEmpty) {
    final name = todo.removeLast();
    final p = packages[name];
    if (p == null || !seen.add(name)) continue;
    todo.addAll((p['dependencies']! as List).cast<String>());
  }
  return seen;
}

/// `name  # note` lines; blank lines and lines starting with # are skipped. Problems for entries
/// without a note are added to [problems].
Set<String> reviewedNames(List<String> lines, List<String> problems) {
  final names = <String>{};
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final hash = line.indexOf('#');
    final name = (hash < 0 ? line : line.substring(0, hash)).trim();
    final note = hash < 0 ? '' : line.substring(hash + 1).trim();
    if (note.isEmpty) {
      problems.add('Reviewed package "$name" has no note. Write "# network: ...; data: ...; permissions: ...". $followFr12');
    } else {
      names.add(name);
    }
  }
  return names;
}

List<String> unlisted(Set<String> runtime, Set<String> reviewed) => [
      for (final name in runtime.difference(reviewed).toList()..sort())
        'New dependency $name. Review network, data and permissions, then add it with a note. $followFr12',
    ];

Map<String, Object?> _graph({String rootVersion = '1.0.0', String extraVersion = '1.0.0'}) => {
      'root': 'app',
      'packages': [
        {'name': 'app', 'version': rootVersion, 'kind': 'root', 'dependencies': ['a', 'gen'], 'directDependencies': ['a'], 'devDependencies': ['gen']},
        {'name': 'a', 'version': extraVersion, 'kind': 'direct', 'dependencies': ['b'], 'directDependencies': ['b'], 'devDependencies': <String>[]},
        {'name': 'b', 'version': '2.0.0', 'kind': 'transitive', 'dependencies': <String>[], 'directDependencies': <String>[], 'devDependencies': <String>[]},
        {'name': 'gen', 'version': '1.0.0', 'kind': 'dev', 'dependencies': ['devonly'], 'directDependencies': ['devonly'], 'devDependencies': <String>[]},
        {'name': 'devonly', 'version': '1.0.0', 'kind': 'transitive', 'dependencies': <String>[], 'directDependencies': <String>[], 'devDependencies': <String>[]},
      ],
    };

void main() {
  test('every runtime Dart package is on the reviewed list with a note (FR-10)', () async {
    final r = await Process.run('dart', ['pub', 'deps', '--json'], runInShell: true);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final deps = jsonDecode(r.stdout as String) as Map<String, Object?>;
    final runtime = runtimePackages(deps);
    expect(runtime.length, greaterThan(20), reason: 'the closure must not be empty (fail closed)');
    expect(runtime, contains('flutter'));

    final problems = <String>[];
    final reviewed = reviewedNames(File(reviewedPath).readAsLinesSync(), problems);
    problems.addAll(unlisted(runtime, reviewed));
    expect(problems, isEmpty, reason: problems.join('\n'));

    // Packages only dev tools pull in stay out of the runtime closure.
    final all = {for (final p in (deps['packages']! as List).cast<Map<String, Object?>>()) p['name']};
    expect(all, contains('analyzer'));
    expect(runtime, isNot(contains('analyzer')));
    expect(runtime, isNot(contains('build_runner')));
  });

  test('self-test: an unlisted runtime package fails with its name and the FR-12 pointer (AC-4.3, AC-4.4)', () {
    final runtime = runtimePackages(_graph());
    expect(runtime, {'a', 'b'});
    final problems = unlisted(runtime, {'a'});
    expect(problems, [
      'New dependency b. Review network, data and permissions, then add it with a note. $followFr12',
    ]);
    expect(unlisted(runtime, {'a', 'b'}), isEmpty);
  });

  test('self-test: dev-only packages are not in the closure; a version bump changes nothing', () {
    expect(runtimePackages(_graph()), isNot(contains('devonly')));
    expect(runtimePackages(_graph(extraVersion: '9.9.9', rootVersion: '2.0.0')), runtimePackages(_graph()));
  });

  test('self-test: an entry without a note is refused', () {
    final problems = <String>[];
    final names = reviewedNames(['# header', '', 'a  # network: none; data: none; permissions: none', 'b  #', 'c'], problems);
    expect(names, {'a'});
    expect(problems, hasLength(2));
    expect(problems.first, contains('"b" has no note'));
    expect(problems.first, contains(followFr12));
  });
}
