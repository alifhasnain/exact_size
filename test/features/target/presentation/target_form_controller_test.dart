import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/domain/target_check.dart';
import 'package:exact_size/features/target/domain/target_input.dart';
import 'package:exact_size/features/target/presentation/target_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-005-T06: session memory and reveal rules of the target form.
void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  TargetFormController ctl() => c.read(targetFormProvider.notifier);
  TargetFormState st() => c.read(targetFormProvider);
  SourceInfo src(int w, int h, {int exif = 1}) => SourceInfo(
      rawWidth: w, rawHeight: h, mime: 'image/jpeg', exifOrientation: exif, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);

  test('a fresh container is empty with JPEG and shows no errors', () {
    expect(st().input, const TargetInput());
    expect(st().input.format, OutputFormat.jpeg);
    expect(st().revealed, isEmpty);
    expect(st().visibleErrors, isEmpty);
    expect(st().result, isA<TargetInputInvalid>());
  });

  test('an error is hidden until reveal, follows every setText, and goes when fixed', () {
    ctl().setText(TargetField.width, '0');
    expect(st().visibleErrors, isEmpty);
    ctl().reveal(TargetField.width);
    expect(st().visibleErrors, {TargetField.width: const PixelRangeError(TargetDimensionsMessage.sideOutOfRange)});
    ctl().setText(TargetField.width, '1.5');
    expect(st().visibleErrors, {TargetField.width: const PixelsNotWhole()});
    ctl().setText(TargetField.width, '300');
    expect(st().visibleErrors, isEmpty);
    expect(st().revealed, {TargetField.width});
  });

  test('revealAll shows every current error', () {
    ctl().revealAll();
    expect(st().visibleErrors.keys, {TargetField.width, TargetField.height, TargetField.maxKb});
  });

  test('startForPhoto keeps the texts and format, clears revealed', () {
    ctl()
      ..setText(TargetField.width, '300')
      ..setText(TargetField.maxKb, '0')
      ..setFormat(OutputFormat.png)
      ..revealAll();
    ctl().startForPhoto();
    expect(st().input, const TargetInput(width: '300', maxKb: '0', format: OutputFormat.png));
    expect(st().revealed, isEmpty);
    expect(st().visibleErrors, isEmpty);
  });

  test('fill replaces all fields', () {
    ctl().setText(TargetField.minKb, '9');
    const preset = TargetInput(width: '600', height: '800', maxKb: '100', format: OutputFormat.png);
    ctl().fill(preset);
    expect(st().input, preset);
    expect(st().result, isA<TargetInputValid>());
  });

  test('usePhotoSize writes the oriented size; nothing when the photo is too large', () {
    ctl().setText(TargetField.maxKb, '50');
    ctl().usePhotoSize(src(4000, 3000, exif: 6));
    expect((st().input.width, st().input.height), ('3000', '4000'));
    expect(st().input.maxKb, '50');
    ctl().usePhotoSize(src(12000, 1000));
    expect((st().input.width, st().input.height), ('3000', '4000'));
  });

  test('a new container (process death) starts empty', () {
    ctl().setText(TargetField.width, '300');
    final fresh = ProviderContainer();
    addTearDown(fresh.dispose);
    expect(fresh.read(targetFormProvider).input, const TargetInput());
  });
}
