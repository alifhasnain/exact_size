import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/preset_fixture_data.dart';

/// FEAT-011-T08: the device copy of the synthetic library equals the fixture file.
void main() {
  test('integration_test/preset_fixture_data.dart equals test/presets/fixtures/test_library.json', () {
    expect(
      jsonDecode(jsonEncode(presetFixtureLibrary)),
      jsonDecode(File('test/presets/fixtures/test_library.json').readAsStringSync()),
    );
  });
}
