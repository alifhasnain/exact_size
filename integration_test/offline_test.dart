import 'dart:io';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/compression_service.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/data/crop_renderer.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_math.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/preview/data/file_output_measurer.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';

import '../test_support/compression_runner_cases.dart';

/// FEAT-004-T25 / AC-6.2: compression completes with networking off. Runs
/// only with --dart-define=OFFLINE=true, after tool/run_offline_test.sh has
/// turned networking off; the first check proves it is off.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const offline = bool.fromEnvironment('OFFLINE');

  const skip = offline ? null : 'needs --dart-define=OFFLINE=true with networking off (tool/run_offline_test.sh)';

  // Test-only probe: the lookup must fail, or the device is still online.
  Future<void> expectOffline() =>
      expectLater(InternetAddress.lookup('example.com').timeout(const Duration(seconds: 10)), throwsA(anything));

  test('JPEG and PNG compression complete with no network', () async {
    await expectOffline();

    final cache = Directory.systemTemp.createTempSync('exactsize_offline_');
    final service = CompressionService(const CompressionRunner(), TempFiles(cache));
    for (final (format, maxKb) in [(OutputFormat.jpeg, 50), (OutputFormat.png, 500)]) {
      final r = await service.compress(
          CompressionRequest(pixels: syntheticBuffer(320, 240), maxKb: maxKb, format: format));
      expect(r, isA<CompressionSuccess>(), reason: format.name);
    }
    cache.deleteSync(recursive: true);
  }, skip: offline ? false : skip);

  // FEAT-016-T10 (FR-16): the crop and check stages run with networking off too.
  testWidgets('crop to compression: a synthetic JPEG is probed, cropped and compressed with no network', (_) async {
    await expectOffline();
    final cache = Directory.systemTemp.createTempSync('exactsize_offline_crop_');
    final picture = img.Image(width: 800, height: 600);
    for (final px in picture) {
      px.setRgb(px.x * 255 ~/ 800, px.y * 255 ~/ 600, 128); // synthetic gradient
    }
    final source = File('${cache.path}/source.jpg')..writeAsBytesSync(img.encodeJpg(picture, quality: 90));
    final handle = SourceHandle(source.uri.toString());
    final probe = await const SourceProbe().probe(handle);
    expect(probe, isA<ProbeOk>());
    final info = (probe as ProbeOk).info;
    const target = Target(300, 300);
    final render = await const CropRenderer().render(RenderRequest(
        src: handle,
        info: info,
        cropRect: CropMath.toCropRect(CropMath.initial(info, target), info, target),
        quarterTurns: 0,
        target: target));
    expect(render, isA<RenderOk>());
    final service = CompressionService(const CompressionRunner(), TempFiles(cache));
    final result = await service.compress(
        CompressionRequest(pixels: (render as RenderOk).pixels, maxKb: 50, format: OutputFormat.jpeg));
    expect(result, isA<CompressionSuccess>());
    cache.deleteSync(recursive: true);
  }, skip: skip != null);

  testWidgets('preview check: the output is measured and decoded with no network', (_) async {
    await expectOffline();
    final cache = Directory.systemTemp.createTempSync('exactsize_offline_check_');
    final service = CompressionService(const CompressionRunner(), TempFiles(cache));
    final result = await service.compress(
        CompressionRequest(pixels: syntheticBuffer(320, 240), maxKb: 50, format: OutputFormat.jpeg));
    expect(result, isA<CompressionSuccess>());
    final success = result as CompressionSuccess;
    final measured = await const FileOutputMeasurer().measure(success.tempFilePath, expectedBytes: success.sizeBytes);
    expect(measured, isA<Measured>());
    final output = (measured as Measured).output;
    expect((output.width, output.height, output.bytes), (320, 240, success.sizeBytes));
    final preview = await const PreviewDecoder().decode(
        SourceHandle(Uri.file(success.tempFilePath).toString()),
        SourceInfo(
            rawWidth: output.width,
            rawHeight: output.height,
            mime: 'image/jpeg',
            exifOrientation: 1,
            isAnimated: false,
            hasAlpha: output.hasAlpha,
            decodePath: DecodePath.region),
        maxSide: 1080);
    expect(preview, isA<PreviewOk>());
    (preview as PreviewOk).image.dispose();
    cache.deleteSync(recursive: true);
  }, skip: skip != null);
}
