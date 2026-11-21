import '../../compression/data/memory_preflight.dart' show MeminfoReader, parseMemAvailable, readProcMeminfo;
import '../domain/crop_types.dart';

/// Memory pre-flight before a crop render (FR-6, NFR-2, ADR-004 v1.1).
///
/// Estimate = (decoded region + output + transform buffer + decoder working
/// memory) × 2 headroom, against `MemAvailable`. Above it: `IMAGE_TOO_LARGE`
/// instead of risking a low-memory kill. Unreadable meminfo: check skipped
/// (allocation failures are still caught later).
class CropMemoryPreflight {
  const CropMemoryPreflight({this.readMeminfo = readProcMeminfo});

  final MeminfoReader readMeminfo;

  static const headroom = 2;

  /// Decoder working memory per source pixel, T04 decision record:
  /// progressive JPEG 3.5 B (S23 RSS 685 MB at 200 MP), baseline JPEG 0.7 B,
  /// PNG, WebP and HEIC about 0 beyond the region output.
  static double workingBytesPerSourcePixel(SourceInfo info) => switch (info.mime) {
        'image/jpeg' => info.isProgressive ? 3.5 : 0.7,
        _ => 0,
      };

  /// Bytes the render needs at its peak, before headroom.
  static int estimate({required SourceInfo info, required CropRect raw, required int sample, required Target target, required bool reorient}) {
    final region = (raw.w ~/ sample) * (raw.h ~/ sample) * 4;
    final out = target.width * target.height * 4;
    final working = (info.rawWidth * info.rawHeight * workingBytesPerSourcePixel(info)).ceil();
    return region + out + (reorient ? out : 0) + working;
  }

  /// Null when the render may start, else `IMAGE_TOO_LARGE`.
  Future<Reason?> check(
      {required SourceInfo info, required CropRect raw, required int sample, required Target target, required bool reorient}) async {
    final String? text;
    try {
      text = await readMeminfo();
    } on Object {
      return null;
    }
    final available = text == null ? null : parseMemAvailable(text);
    if (available == null) return null;
    final need = estimate(info: info, raw: raw, sample: sample, target: target, reorient: reorient) * headroom;
    return need > available ? Reason.imageTooLarge : null;
  }
}
