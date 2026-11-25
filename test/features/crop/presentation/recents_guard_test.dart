import 'dart:io';

import 'package:exact_size/features/crop/presentation/recents_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeBinding implements RecentsBinding {
  FakeBinding(this.sdkInt);
  @override
  final int sdkInt;
  final calls = <bool>[];
  @override
  void setRecentsScreenshotEnabled(bool enabled) => calls.add(enabled);
}

void main() {
  Future<void> showThenRemove(WidgetTester tester, RecentsBinding b) async {
    await tester.pumpWidget(RecentsGuard(binding: b, child: const SizedBox()));
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('API 33+: off on push, back on at pop', (tester) async {
    for (final sdk in [33, 36]) {
      final b = FakeBinding(sdk);
      await tester.pumpWidget(RecentsGuard(binding: b, child: const SizedBox()));
      expect(b.calls, [false]);
      await tester.pumpWidget(const SizedBox());
      expect(b.calls, [false, true]);
    }
  });

  testWidgets('FEAT-006-T04: nested guards: outer disables once, inner adds no call, outer removal enables once', (tester) async {
    final b = FakeBinding(36);
    await tester.pumpWidget(RecentsGuard(binding: b, child: const SizedBox()));
    expect(b.calls, [false]);
    await tester.pumpWidget(RecentsGuard(binding: b, child: RecentsGuard(binding: b, child: const SizedBox())));
    expect(b.calls, [false], reason: 'inner mount makes no call');
    await tester.pumpWidget(RecentsGuard(binding: b, child: const SizedBox()));
    expect(b.calls, [false], reason: 'inner unmount keeps protection off');
    await tester.pumpWidget(const SizedBox());
    expect(b.calls, [false, true]);
  });

  testWidgets('below API 33: never called', (tester) async {
    for (final sdk in [28, 32]) {
      final b = FakeBinding(sdk);
      await showThenRemove(tester, b);
      expect(b.calls, isEmpty);
    }
  });

  test('no FLAG_SECURE anywhere in the app code (FR-26: screenshots stay allowed)', () {
    final hits = [
      for (final root in ['lib', 'android/app/src', 'packages/es_codec/lib'])
        for (final f in Directory(root).listSync(recursive: true).whereType<File>())
          if (RegExp(r'\.(dart|kt|java|xml)$').hasMatch(f.path) && !f.path.endsWith('.g.dart'))
            for (final line in f.readAsLinesSync())
              if (!line.trimLeft().startsWith('//') && line.contains('FLAG_SECURE')) '${f.path}: $line',
    ];
    expect(hits, isEmpty);
  });
}
