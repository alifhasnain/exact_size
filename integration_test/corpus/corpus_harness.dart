import 'dart:isolate';
import 'dart:typed_data';

import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/data/turbo_jpeg_encoder.dart';
import 'package:exact_size/features/compression/domain/byte_window.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/domain/flattener.dart';
import 'package:exact_size/features/compression/domain/jpeg_padder.dart' show minSegment;
import 'package:exact_size/features/compression/domain/jpeg_plan.dart';
import 'package:exact_size/features/compression/domain/size_search.dart';

import '../../test_support/synthetic_images.dart';

/// FEAT-004-T24: the 500-export corpus (FR-6, FR-8, NFR-8, NFR-1 pass cap).
enum TargetKind { normal, narrow, maxOnly, tinyMax, signature10to20 }

final class CorpusCase {
  const CorpusCase(this.id, this.signature, this.width, this.height, this.channels, this.format, this.kind,
      this.maxKb, this.minKb, this.seed);
  final int id, width, height, channels, maxKb, seed;
  final int? minKb;
  final bool signature;
  final OutputFormat format;
  final TargetKind kind;

  Uint8List pixels() => signature
      ? syntheticSignature(width, height, seed: seed, channels: channels)
      : syntheticPhoto(width, height, seed: seed, channels: channels);

  ByteWindow get window => ByteWindow.fromKb(minKb: minKb, maxKb: maxKb);

  @override
  String toString() =>
      '#$id ${signature ? 'sig' : 'photo'} ${width}x$height c$channels ${format.name} ${kind.name} ${minKb ?? '-'}-$maxKb KB';
}

const _photoSizes = [(160, 120), (320, 240), (400, 300), (300, 400), (640, 480)];
const _sigSizes = [(140, 60), (300, 100), (600, 200)];

/// [count] deterministic cases (seeded; same list on every run and device).
List<CorpusCase> buildCorpus({int count = 780}) {
  var s = 20261121;
  int next(int bound) {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return (s >> 8) % bound;
  }

  return [
    for (var id = 0; id < count; id++) _makeCase(id, next),
  ];
}

CorpusCase _makeCase(int id, int Function(int) next) {
  final signature = next(10) < 4;
  final (w, h) = signature ? _sigSizes[next(_sigSizes.length)] : _photoSizes[next(_photoSizes.length)];
  final channels = next(10) < 2 ? 4 : 3;
  final format = next(100) < 15 ? OutputFormat.png : OutputFormat.jpeg;
  final seed = 1 + next(1000);
  // Rough scale of a mid-quality JPEG of this image, to aim targets near it.
  final scaleKb = signature ? (w * h) ~/ 1500 + 4 : (w * h) ~/ 4000 + 4;
  if (signature && w == 140 && format == OutputFormat.jpeg && next(3) == 0) {
    return CorpusCase(id, signature, w, h, channels, format, TargetKind.signature10to20, 20, 10, seed);
  }
  final kind = TargetKind.values[next(4)];
  final (int? minKb, int maxKb) = switch (kind) {
    TargetKind.normal => () {
        final max = 3 + next(scaleKb * 2);
        return (1 + next(max * 3 ~/ 4 + 1), max);
      }(),
    TargetKind.narrow => () {
        final max = 3 + next(scaleKb * 2);
        return (max - 1, max);
      }(),
    TargetKind.maxOnly => (null, 2 + next(scaleKb * 2)),
    TargetKind.tinyMax => (null, 2 + next(3)),
    TargetKind.signature10to20 => (10, 20),
  };
  return CorpusCase(id, signature, w, h, channels, format, kind, maxKb, minKb, seed);
}

NativePixelBuffer nativeFrom(CorpusCase c) {
  final px = NativePixelBuffer.allocate(
      width: c.width, height: c.height, channels: c.channels, hasTransparency: c.channels == 4);
  px.bytes.setAll(0, c.pixels());
  return px;
}

/// Offline reference: is there any valid export at all? JPEG: some config
/// (A, B, C) at quality ≥ [qFloor] gives a file inside the window, or below
/// the floor with ≥ 4 bytes of room under the ceiling for padding (FR-8).
/// JPEG only; PNG is labelled in [runCase] from its one lossless size.
bool referenceFeasible(CorpusCase c) {
  final w = c.window;
  final px = nativeFrom(c);
  try {
    flattenForJpeg(px);
    for (final config in JpegConfig.values) {
      for (var q = qFloor; q <= 100; q++) { // low first: a feasible target usually exits on the first encode
        final size = const TurboJpegEncoder()
            .encodeJpeg(px.pointer,
                width: c.width,
                height: c.height,
                quality: q,
                subsampling: config.subsampling,
                optimiseHuffman: config.optimiseHuffman)
            .length;
        if (w.contains(size) || (size < w.lo && w.hi - size >= minSegment)) return true;
      }
    }
    return false;
  } finally {
    px.free();
  }
}

final class CorpusRun {
  CorpusRun(this.c, this.feasible, this.plan, this.passes, this.runMs, this.referenceMs);
  final CorpusCase c;
  final int runMs, referenceMs;
  final bool feasible;
  final PlanResult plan;
  final int passes;
  bool get exported => plan is ReadyToWrite;
  bool get padded => plan is ReadyToWrite && (plan as ReadyToWrite).paddingBytes > 0;
}

Future<CorpusRun> runCase(CorpusCase c) async {
  // The JPEG reference is exhaustive and slow, so it runs on its own isolate
  // while the runner works (both are pure functions of the case).
  final refWatch = Stopwatch()..start();
  final reference = c.format == OutputFormat.jpeg
      ? Isolate.run(() => referenceFeasible(c)).whenComplete(refWatch.stop)
      : null;
  var passes = 0;
  final sw = Stopwatch()..start();
  final plan = await const CompressionRunner().run(
      CompressionRequest(pixels: nativeFrom(c), minKb: c.minKb, maxKb: c.maxKb, format: c.format),
      onProgress: (p, _) => passes = p);
  final runMs = sw.elapsedMilliseconds;
  // PNG is one deterministic lossless encode (FR-9): feasible exactly when
  // its size, exported or reported as the closest size, is in the window.
  // Labelled from the size, not the verdict, so a wrong verdict still fails.
  final feasible = c.format == OutputFormat.png
      ? c.window.contains(switch (plan) {
          ReadyToWrite(:final bytes) => bytes.length,
          PlanFailed(:final failure) => failure.closestBytes ?? -1,
        })
      : await reference!;
  return CorpusRun(c, feasible, plan, passes, runMs, refWatch.elapsedMilliseconds);
}
