import 'dart:io';
import 'dart:math';

import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/preview/domain/spec_check.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-006-T02: verdict of the measured output against the target (FR-3, FR-4, FR-6, FR-8, NFR-5, NFR-6).
void main() {
  MeasuredOutput out(int bytes, {int w = 300, int h = 400, OutputFormat f = OutputFormat.jpeg}) =>
      MeasuredOutput(bytes: bytes, width: w, height: h, format: f, hasAlpha: false);
  const t = TargetSpec(width: 300, height: 400, minKb: 20, maxKb: 50, format: OutputFormat.jpeg);
  const lo = 20 * 1024, hi = 50 * 1000;

  test('AC-2.2: floor and ceiling meet; one byte outside fails with the direction', () {
    expect(checkSpec(out(lo), t).meets, isTrue);
    expect(checkSpec(out(hi), t).meets, isTrue);
    expect(checkSpec(out(lo), t).sizeDirection, isNull);
    final below = checkSpec(out(lo - 1), t);
    expect((below.size, below.meets, below.sizeDirection), (false, false, Direction.tooSmall));
    final above = checkSpec(out(hi + 1), t);
    expect((above.size, above.meets, above.sizeDirection), (false, false, Direction.tooBig));
  });

  test('width or height off by one fails pixels only; format swap fails format only', () {
    for (final (w, h) in [(299, 400), (301, 400), (300, 399), (300, 401)]) {
      final c = checkSpec(out(30000, w: w, h: h), t);
      expect((c.pixels, c.size, c.format, c.meets), (false, true, true, false), reason: '$w x $h');
    }
    final c = checkSpec(out(30000, f: OutputFormat.png), t);
    expect((c.pixels, c.size, c.format, c.meets), (true, true, false, false));
  });

  test('AC-2.3: 49-50 KB at 49,500 B meets with a narrow window', () {
    final c = checkSpec(out(49500), const TargetSpec(width: 300, height: 400, minKb: 49, maxKb: 50, format: OutputFormat.jpeg));
    expect(c.meets, isTrue);
    expect(c.window.narrow, isTrue);
  });

  test('max-only target has floor 0', () {
    final c = checkSpec(out(1), const TargetSpec(width: 300, height: 400, maxKb: 50, format: OutputFormat.jpeg));
    expect((c.window.lo, c.window.narrow, c.meets), (0, false, true));
  });

  test('NFR-5: 10,000+ generated cases agree with ByteWindow.contains and exact pixel and format equality', () {
    final rnd = Random(6);
    var n = 0;
    for (var i = 0; i < 3000; i++) {
      final maxKb = 1 + rnd.nextInt(10240);
      final minKb = switch (rnd.nextInt(3)) {
        0 => null,
        1 => max(1, (maxKb * (0.976 + rnd.nextDouble() * 0.024)).floor()), // narrow region
        _ => rnd.nextInt(maxKb) + 1,
      };
      final f = OutputFormat.values[rnd.nextInt(2)];
      final spec = TargetSpec(width: 1 + rnd.nextInt(8000), height: 1 + rnd.nextInt(8000), minKb: minKb, maxKb: maxKb, format: f);
      final w = ByteWindow.fromKb(minKb: minKb, maxKb: maxKb);
      for (final bytes in [w.lo - 1, w.lo, w.hi, w.hi + 1]) {
        if (bytes < 0) continue;
        final mw = spec.width + rnd.nextInt(3) - 1, mh = spec.height + rnd.nextInt(3) - 1;
        final mf = rnd.nextInt(4) == 0 ? OutputFormat.values[1 - f.index] : f;
        final c = checkSpec(MeasuredOutput(bytes: bytes, width: mw, height: mh, format: mf, hasAlpha: false), spec);
        final size = w.contains(bytes);
        expect(c.size, size);
        expect(c.pixels, mw == spec.width && mh == spec.height);
        expect(c.format, mf == f);
        expect(c.meets, size && c.pixels && c.format);
        expect(c.sizeDirection, size ? null : (bytes > w.hi ? Direction.tooBig : Direction.tooSmall));
        n++;
      }
    }
    expect(n, greaterThanOrEqualTo(10000));
  });

  test('NFR-6: toString of both types holds no input number', () {
    final m = MeasuredOutput(bytes: 48213, width: 1234, height: 5678, format: OutputFormat.png, hasAlpha: true);
    final c = checkSpec(m, const TargetSpec(width: 4321, height: 8765, minKb: 37, maxKb: 91, format: OutputFormat.jpeg));
    for (final s in [m.toString(), c.toString()]) {
      expect(RegExp(r'\d').hasMatch(s), isFalse, reason: s);
    }
  });

  test('FR-4: one window definition (no 1024 or 1000 literal in preview code); domain imports stay pure', () {
    final files = Directory('lib/features/preview').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final f in files) {
      final src = f.readAsStringSync();
      expect(RegExp(r'(?<![\w.])(1024|1000)(?![\w.])').hasMatch(src), isFalse, reason: f.path);
    }
    for (final f in files.where((f) => f.path.replaceAll(r'\', '/').contains('/domain/'))) {
      for (final line in f.readAsLinesSync().where((l) => l.startsWith('import '))) {
        expect(line, isNot(matches(RegExp(r"package:(flutter|flutter_riverpod|riverpod|get_it|injectable)/|'dart:io'"))), reason: f.path);
      }
    }
  });
}
