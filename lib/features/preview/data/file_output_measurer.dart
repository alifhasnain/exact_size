import 'dart:io';
import 'dart:isolate';

import '../../compression/domain/compression_result.dart';
import '../../crop/data/byte_source.dart';
import '../../crop/data/container_check.dart';
import '../../crop/data/header_sniff.dart';
import '../domain/measured_output.dart';

/// Reads the output file itself (FR-2, FR-11, tech section 3), off the UI thread (NFR-1).
/// Values come only from the bytes; [expectedBytes] is only the FR-11 consistency check.
/// Every failure is [Unreadable] and keeps no exception text (NFR-6).
class FileOutputMeasurer implements OutputMeasurer {
  const FileOutputMeasurer();

  @override
  Future<MeasureResult> measure(String path, {required int expectedBytes}) =>
      Isolate.run(() => _measure(path, expectedBytes));
}

MeasureResult _measure(String path, int expectedBytes) {
  RandomAccessFile? raf;
  try {
    raf = File(path).openSync();
    final src = FileByteSource(raf);
    if (src.length == 0 || src.length != expectedBytes) return const Unreadable();
    final r = checkContainer(src);
    final format = switch (r) {
      ContainerOk(format: ContainerFormat.jpeg) => OutputFormat.jpeg,
      ContainerOk(format: ContainerFormat.png) => OutputFormat.png,
      _ => null, // WebP, GIF, HEIF, unknown or damaged (OQ-T2)
    };
    if (format == null || r is! ContainerOk) return const Unreadable();
    return Measured(MeasuredOutput(
      bytes: src.length,
      width: r.width,
      height: r.height,
      format: format,
      hasAlpha: sniffHeader(src, r.format).alpha,
    ));
  } on Object {
    return const Unreadable();
  } finally {
    try {
      raf?.closeSync();
    } on Object {
      // already closed
    }
  }
}
