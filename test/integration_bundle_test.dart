import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI runs integration tests through integration_test/bundle.dart, so a test
/// file missing from it would silently never run on the emulator.
void main() {
  test('integration_test/bundle.dart imports every *_test.dart file', () {
    const runOnTheirOwn = {'offline_test.dart', 'memory_profile_test.dart'};
    final bundle = File('integration_test/bundle.dart').readAsStringSync();
    final missing = Directory('integration_test')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll(r'\', '/').replaceFirst('integration_test/', ''))
        .where((p) => p.endsWith('_test.dart') && !runOnTheirOwn.contains(p))
        .where((p) => !bundle.contains("import '$p'"))
        .toList();
    expect(missing, isEmpty, reason: 'add these to integration_test/bundle.dart');
  });
}
