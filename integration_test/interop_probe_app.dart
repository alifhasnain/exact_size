import 'package:es_codec/es_codec.dart';
import 'package:flutter/widgets.dart';

/// Release-build entry point for the record_use check (tool/check_tree_shaking.sh).
/// Calls es_probe_add only, so es_probe_unused must be stripped from the .so.
void main() {
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('${esProbeAdd(2, 3)} / ${androidSdkInt()}')),
    ),
  );
}
