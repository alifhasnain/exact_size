import 'dart:typed_data';

import 'package:es_codec/es_codec.dart';
import 'package:flutter/widgets.dart';

/// Release-build entry point for tool/check_tree_shaking.sh and the 16 KB
/// alignment check. Uses only the encode path, so unused TurboJPEG functions
/// (for example tj3Get) must be stripped from libes_codec.so.
void main() {
  final jpeg = encodeRgba8ToJpeg(Uint8List(2 * 2 * 4), 2, 2, quality: 85);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('${jpeg.length} / ${androidSdkInt()}')),
    ),
  );
}
