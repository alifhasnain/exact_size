import 'dart:io';

import 'package:exact_size/features/presets/presentation/preset_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-014-T03 (FR-6, FR-7, NFR-6): the clock seam.
void main() {
  test('the default clock reads the device time on each call', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final clock = container.read(presetClockProvider);
    expect(clock().difference(DateTime.now()).inSeconds.abs(), lessThan(1));
  });

  test('an override is returned as given', () {
    final container = ProviderContainer(overrides: [presetClockProvider.overrideWithValue(() => DateTime(2026, 12, 31))]);
    addTearDown(container.dispose);
    expect(container.read(presetClockProvider)(), DateTime(2026, 12, 31));
  });

  test('the preset module reads the device clock only in presetClockProvider', () {
    final hits = [
      for (final f in Directory('lib/features/presets').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          for (final (i, line) in f.readAsLinesSync().indexed)
            if (line.contains('DateTime.now')) '${f.path.replaceAll(r'\', '/')}:${i + 1}',
    ];
    expect(hits, hasLength(1));
    expect(hits.single, startsWith('lib/features/presets/presentation/preset_providers.dart:'));
  });
}
