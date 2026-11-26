import 'dart:ui' as ui;

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/preview/data/spec_check_log.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/preview/presentation/preview_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fake_output_measurer.dart';

/// The 300×300 JPEG of 48,200 bytes that the FEAT-007 result-screen fixtures describe.
const fakeMeasured = MeasuredOutput(bytes: 48200, width: 300, height: 300, format: OutputFormat.jpeg, hasAlpha: false);

/// FEAT-006 seams for result-screen tests (OQ-T1 edit 2): the check measures [measured] (or
/// returns [result]) and the preview decodes to [image] (or [preview]); log lines go to [log].
List<Override> fakeCheckOverrides({
  ui.Image? image,
  MeasureResult? result,
  PreviewResult? preview,
  FakeOutputMeasurer? measurer,
  FakePreviewDecoder? decoder,
  void Function(String)? log,
}) =>
    [
      outputMeasurerProvider.overrideWithValue(measurer ?? FakeOutputMeasurer(result ?? const Measured(fakeMeasured))),
      resultPreviewDecoderProvider.overrideWithValue(decoder ?? FakePreviewDecoder(preview ?? PreviewOk(image!, 1))),
      specCheckLogProvider.overrideWithValue(SpecCheckLog(log ?? (_) {})),
      previewMaxSideProvider.overrideWithValue(1080),
    ];
