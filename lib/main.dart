import 'dart:async';

import 'package:es_codec/es_codec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'di/injection.dart';
import 'features/compression/data/temp_files.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  registerEsCodecLicenses();
  // FR-20: remove output files left by an earlier run (crash, kill, cancel).
  unawaited(TempFiles.appCache().then((files) => files.sweep()));
  runApp(const ProviderScope(child: ExactSizeApp()));
}
