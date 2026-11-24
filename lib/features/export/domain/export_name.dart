import 'dart:math';

import '../../compression/domain/compression_result.dart';

/// FEAT-007 FR-4 file name: `exactsize-<W>x<H>-<TOKEN>.<ext>`. Pure; the same in
/// every language, no user, source, date or device value in it.
abstract final class ExportName {
  static final pattern = RegExp(r'^exactsize-[0-9]{1,6}x[0-9]{1,6}-[a-z0-9]{6}\.(jpg|png)$');
  static const maxLength = 40;
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  /// [secure] must be `Random.secure()` at every call site (NFR-5; grep test).
  static String generate(int w, int h, OutputFormat format, Random secure) {
    final token = String.fromCharCodes(List.generate(6, (_) => _alphabet.codeUnitAt(secure.nextInt(_alphabet.length))));
    final name = 'exactsize-${w}x$h-$token.${ext(format)}';
    if (!pattern.hasMatch(name) || name.length > maxLength) throw ArgumentError('size out of FR-4 range');
    return name;
  }

  static String ext(OutputFormat f) => switch (f) { OutputFormat.jpeg => 'jpg', OutputFormat.png => 'png' };
  static String mime(OutputFormat f) => switch (f) { OutputFormat.jpeg => 'image/jpeg', OutputFormat.png => 'image/png' };
}
