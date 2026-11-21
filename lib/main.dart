import 'dart:async';

import 'package:es_codec/es_codec.dart';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'di/injection.dart';
import 'features/compression/data/temp_files.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  registerEsCodecLicenses();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Barlow Condensed'], await rootBundle.loadString('assets/fonts/BarlowCondensed-OFL.txt'));
  });
  // FR-20: remove output files left by an earlier run (crash, kill, cancel).
  unawaited(getIt<TempFiles>().sweep());
  runApp(const ProviderScope(child: ExactSizeApp()));
}
