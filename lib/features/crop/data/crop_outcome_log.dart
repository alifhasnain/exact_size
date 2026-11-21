import 'package:flutter/foundation.dart' show debugPrint;

import '../domain/crop_types.dart';

/// Where log lines go; replaceable in tests.
typedef CropLogSink = void Function(String line);

void _debugPrintSink(String line) => debugPrint(line);

/// Crop outcome logging (FR-24, NFR-7, PRD section 10). Every input is an
/// enum, so a line can only hold enum names: no paths, URIs, file names,
/// sizes, crop coordinates, EXIF values or pixel data.
class CropOutcomeLog {
  const CropOutcomeLog([this._sink = _debugPrintSink]);

  final CropLogSink _sink;

  void success() => _sink('exactsize.crop outcome=SUCCESS');

  void failure(Reason reason) => _sink('exactsize.crop outcome=${reason.code}');
}
