import 'dart:convert';
import 'dart:io';

import 'package:exact_size/features/presets/data/preset_asset_source.dart';
import 'package:exact_size/features/presets/domain/preset_types.dart';
import 'package:exact_size/features/presets/presentation/preset_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves one string as the preset asset.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(utf8.encode(text));
}

/// FEAT-011-T02: loader, enum-only log lines (FR-16, FR-17), session-only state (AC-8.1).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = File('test/presets/fixtures/test_library.json').readAsStringSync();

  Future<(Object?, List<String>)> load(String text) async {
    final lines = <String>[];
    final c = ProviderContainer(
      overrides: [presetSourceProvider.overrideWithValue(PresetAssetSource(bundle: _Bundle(text), sink: lines.add))],
    );
    addTearDown(c.dispose);
    Object? result;
    try {
      result = await c.read(presetLibraryProvider.future);
    } catch (e) {
      result = c.read(presetLibraryProvider);
    }
    return (result, lines);
  }

  void expectNoData(List<String> lines) {
    for (final l in lines) {
      expect(l, matches(RegExp(r'^exactsize\.presets outcome=[A-Z_]+$')));
    }
  }

  test('corrupt JSON gives an AsyncError and exactly one LOAD_FAILED line', () async {
    final (state, lines) = await load('{"schema": 1, "forms": [');
    expect(state, isA<AsyncError>());
    expect(lines, ['exactsize.presets outcome=LOAD_FAILED']);
    expectNoData(lines);
  });

  test('a wrong root also fails with one line', () async {
    final (state, lines) = await load('{"schema": 2, "forms": []}');
    expect(state, isA<AsyncError>());
    expect(lines, ['exactsize.presets outcome=LOAD_FAILED']);
  });

  test('the fixture loads with no line; one bad spec gives exactly one SPEC_SKIPPED line', () async {
    final (ok, quiet) = await load(fixture);
    expect((ok! as PresetLibrary).forms, hasLength(2));
    expect(quiet, isEmpty);

    final json = jsonDecode(fixture) as Map<String, dynamic>;
    ((json['forms'] as List).first['specs'] as List).add({'kind': 'photo', 'width': 0});
    final (lib, lines) = await load(jsonEncode(json));
    expect((lib! as PresetLibrary).skipped, 1);
    expect(lines, ['exactsize.presets outcome=SPEC_SKIPPED']);
    expectNoData(lines);
    for (final word in ['test-form', 'Test Form', '1', 'Exception']) {
      expect(lines.single.contains(word), isFalse, reason: word);
    }
  });

  test('the shipped asset loads with 0 forms', () async {
    final (lib, lines) = await load(File(PresetAssetSource.path).readAsStringSync());
    expect((lib! as PresetLibrary).forms, isEmpty);
    expect(lines, isEmpty);
  });

  test('a fresh container has no applied preset (AC-8.1)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(appliedPresetProvider), isNull);
  });
}
