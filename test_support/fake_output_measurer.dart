import 'dart:async';

import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';

/// FEAT-006 seam fakes (NFR-6): no file is read and no image is decoded.
class FakeOutputMeasurer implements OutputMeasurer {
  FakeOutputMeasurer(this.result);

  /// What the next call returns, unless [gate] is set.
  MeasureResult result;
  Completer<MeasureResult>? gate;
  final calls = <({String path, int expectedBytes})>[];

  @override
  Future<MeasureResult> measure(String path, {required int expectedBytes}) async {
    calls.add((path: path, expectedBytes: expectedBytes));
    return gate?.future ?? result;
  }
}

class FakePreviewDecoder implements PreviewDecoder {
  FakePreviewDecoder(this.result);

  PreviewResult result;
  Completer<PreviewResult>? gate;
  final calls = <({SourceHandle src, SourceInfo info, int maxSide})>[];

  @override
  bool get debugForceOutOfMemory => false;

  @override
  Future<PreviewResult> decode(SourceHandle src, SourceInfo info, {int maxSide = maxSide}) async {
    calls.add((src: src, info: info, maxSide: maxSide));
    return gate?.future ?? result;
  }
}
