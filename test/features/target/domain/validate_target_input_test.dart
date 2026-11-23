import 'dart:io';
import 'dart:math';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/target_validator.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/target_check.dart';
import 'package:exact_size/features/target/domain/target_input.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:exact_size/features/target/domain/validate_target_input.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-005-T04: per-field validation (tech section 3), PRD section 9 rows,
/// fuzz and timing. Every message is pinned to its field.
void main() {
  const side = PixelRangeError(TargetDimensionsMessage.sideOutOfRange);
  const tooMany = PixelRangeError(TargetDimensionsMessage.tooManyPixels);
  const notWhole = PixelsNotWhole();
  const invalid = KbError(TargetMessage.invalidNumber);
  const wholeKb = KbError(TargetMessage.wholeNumbersOnly);
  const maxRange = KbError(TargetMessage.maxOutOfRange);
  const minMax = KbError(TargetMessage.minNotBelowMax);

  Map<TargetField, TargetError> errors(TargetInput i) => switch (validateTargetInput(i)) {
        TargetInputInvalid(:final errors) => errors,
        TargetInputValid() => const {},
      };

  TargetSpec spec(TargetInput i) => (validateTargetInput(i) as TargetInputValid).spec;

  const ok = TargetInput(width: '300', height: '300', maxKb: '50');

  test('all fields empty: W, H and Max errors, focus on width (section 9)', () {
    final r = validateTargetInput(const TargetInput()) as TargetInputInvalid;
    expect(r.errors, {TargetField.width: side, TargetField.height: side, TargetField.maxKb: invalid});
    expect(r.firstField, TargetField.width);
  });

  test('a valid input gives a spec with every field', () {
    expect(spec(ok), const TargetSpec(width: 300, height: 300, maxKb: 50, format: OutputFormat.jpeg));
    expect(spec(ok.copyWith(minKb: '20', format: OutputFormat.png)),
        const TargetSpec(width: 300, height: 300, minKb: 20, maxKb: 50, format: OutputFormat.png));
    expect(spec(const TargetInput(width: '٣٠٠', height: ' 0300 ', maxKb: '۵۰')).dimensions, const Target(300, 300));
  });

  test('pixel sides: 0, "0 px", negative, too large, not whole (section 9)', () {
    for (final w in ['0', '0 px', '-5', '+5', '10001', '300x300', 'KB', '9' * 40]) {
      expect(errors(ok.copyWith(width: w)), {TargetField.width: side}, reason: w);
    }
    for (final w in ['300.5', '7,5', '1,000', '1.000']) {
      expect(errors(ok.copyWith(width: w)), {TargetField.width: notWhole}, reason: w);
    }
    expect(errors(ok.copyWith(height: '10001')), {TargetField.height: side});
    expect(errors(ok.copyWith(width: '10000', height: '1')), isEmpty);
    expect(errors(ok.copyWith(width: '10001', height: '10000')), {TargetField.width: side});
  });

  test('24 MP: 6000x4000 accepted; 6001x4000 and 10,000x2,401 refused on Width', () {
    expect(errors(ok.copyWith(width: '6000', height: '4000')), isEmpty);
    expect(errors(ok.copyWith(width: '6001', height: '4000')), {TargetField.width: tooMany});
    expect(errors(ok.copyWith(width: '10000', height: '2401')), {TargetField.width: tooMany});
  });

  test('Max: 1 and 10,241 out of range; 2 and 10,240 accepted; 0, text and decimals', () {
    for (final m in ['1', '10241', '9' * 20]) {
      expect(errors(ok.copyWith(maxKb: m)), {TargetField.maxKb: maxRange}, reason: m);
    }
    expect(spec(ok.copyWith(maxKb: '2')).maxKb, 2);
    expect(spec(ok.copyWith(maxKb: '10240')).maxKb, 10240);
    for (final m in ['0', '', 'KB', '-5', '1e3']) {
      expect(errors(ok.copyWith(maxKb: m)), {TargetField.maxKb: invalid}, reason: m);
    }
    for (final m in ['7.5', '7,5', '1,000', '1.000', '1.000.000', '٧٫٥', '١٬٠٠٠']) {
      expect(errors(ok.copyWith(maxKb: m)), {TargetField.maxKb: wholeKb}, reason: m);
    }
  });

  test('Min: alone is not an error; 0 invalid; equal or above Max; 49/50 accepted', () {
    expect(errors(ok.copyWith(minKb: '20', maxKb: '')), {TargetField.maxKb: invalid});
    expect(errors(ok.copyWith(minKb: '20000', maxKb: '')), {TargetField.maxKb: invalid});
    expect(errors(ok.copyWith(minKb: '20', maxKb: '1')), {TargetField.maxKb: maxRange});
    expect(errors(ok.copyWith(minKb: '0')), {TargetField.minKb: invalid});
    expect(errors(ok.copyWith(minKb: '50')), {TargetField.minKb: minMax});
    expect(errors(ok.copyWith(minKb: '51')), {TargetField.minKb: minMax});
    expect(errors(ok.copyWith(minKb: '7.5')), {TargetField.minKb: wholeKb});
    expect(errors(ok.copyWith(minKb: 'x')), {TargetField.minKb: invalid});
    expect(spec(ok.copyWith(minKb: '49')).minKb, 49);
    expect(spec(ok.copyWith(minKb: '  ')).minKb, isNull);
  });

  test('all errors are returned together (AC-3.5)', () {
    final r = validateTargetInput(const TargetInput(width: '1.5', height: '0', minKb: 'x', maxKb: '1')) as TargetInputInvalid;
    expect(r.errors, {TargetField.width: notWhole, TargetField.height: side, TargetField.minKb: invalid, TargetField.maxKb: maxRange});
    expect(r.firstField, TargetField.width);
    expect((validateTargetInput(ok.copyWith(minKb: '60', maxKb: '')) as TargetInputInvalid).firstField, TargetField.maxKb);
  });

  test('seeded fuzz: never throws; every valid result passes checkTarget and validateTarget', () {
    final r = Random(5005);
    const alphabet = ['0', '1', '2', '5', '9', '٣', '۵', '३', '৩', '.', ',', '٫', '٬', ' ', '\u00A0', '\u2066', '\u2069', '-', '+', 'x', 'e', 'K', ''];
    String text() => List.generate(r.nextInt(12), (_) => alphabet[r.nextInt(alphabet.length)]).join();
    var valid = 0;
    for (var i = 0; i < 1000; i++) {
      final input = TargetInput(
          width: text(), height: text(), minKb: text(), maxKb: text(), format: OutputFormat.values[r.nextInt(2)]);
      final result = validateTargetInput(input);
      if (result case TargetInputValid(:final spec)) {
        valid++;
        expect(checkTarget(spec.dimensions), isNull);
        expect(
            validateTarget(maxText: '${spec.maxKb}', minText: spec.minKb == null ? '' : '${spec.minKb}', format: spec.format.name),
            isA<ValidTarget>());
      }
    }
    // Plus a pass over plausible inputs so the valid branch is really exercised.
    for (var i = 0; i < 200; i++) {
      final w = 1 + r.nextInt(12000), h = 1 + r.nextInt(12000), max = r.nextInt(11000), min = r.nextInt(200);
      final result = validateTargetInput(TargetInput(width: '$w', height: '$h', minKb: '$min', maxKb: '$max'));
      if (result case TargetInputValid(:final spec)) {
        valid++;
        expect(checkTarget(spec.dimensions), isNull);
        expect(spec.minKb == null || spec.minKb! < spec.maxKb, isTrue);
      }
    }
    expect(valid, greaterThan(0));
  });

  test('10,000 validations take at most 5 ms each (NFR-1, informational on CI)', () {
    final sw = Stopwatch()..start();
    for (var i = 0; i < 10000; i++) {
      validateTargetInput(TargetInput(width: '${1 + i % 9000}', height: '٣٠٠', minKb: '1,5', maxKb: '${i % 12000}'));
    }
    expect(sw.elapsed, lessThan(const Duration(seconds: 50)));
  });

  test('limits in messages come from the shared constants (NFR-5); none is written in lib/features/target/', () {
    // The KB and pixel range checks are FEAT-002's and FEAT-004's: the edges move with their constants.
    expect(errors(ok.copyWith(width: '$maxTargetSide', height: '1')), isEmpty);
    expect(errors(ok.copyWith(width: '${maxTargetSide + 1}')), {TargetField.width: side});
    expect(errors(ok.copyWith(maxKb: '$maxKbLimit')), isEmpty);
    expect(errors(ok.copyWith(maxKb: '${maxKbLimit + 1}')), {TargetField.maxKb: maxRange});
    expect(errors(ok.copyWith(width: '$maxTargetPixels', height: '1')), {TargetField.width: side});
    for (final f in Directory('lib/features/target').listSync(recursive: true).whereType<File>()) {
      final src = f.readAsStringSync();
      for (final literal in ['10000', '24000000', '10240', '10_000', '24_000_000', '10_240']) {
        expect(src.contains(literal), isFalse, reason: '${f.path} holds $literal');
      }
    }
  });
}
