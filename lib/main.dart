import 'dart:async';

import 'package:es_codec/es_codec.dart';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show PlatformException, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'di/injection.dart';
import 'features/compression/data/temp_files.dart';
import 'features/export/data/export_bridge.dart';
import 'features/export/data/share_copies.dart';
import 'features/pick/data/system_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  registerEsCodecLicenses();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Barlow Condensed'], await rootBundle.loadString('assets/fonts/BarlowCondensed-OFL.txt'));
  });
  // FR-20: remove output files left by an earlier run (crash, kill, cancel).
  unawaited(getIt<TempFiles>().sweep());
  // FEAT-001 FR-11, FR-17: remove camera files from earlier runs, except one the camera app
  // may still be writing (marker kept by the bridge across activity recreation).
  unawaited(_sweepCameraFiles());
  // FEAT-007 FR-16: share copies from earlier runs, and this app's unfinished saves in shared
  // storage (pending rows or .part files; never asks for a permission).
  unawaited(getIt<ShareCopies>().sweep());
  unawaited(getIt<ExportBridge>().sweepIncomplete());
  runApp(const ProviderScope(child: ExactSizeApp()));
}

Future<void> _sweepCameraFiles() async {
  final String? keep;
  try {
    keep = await getIt<SystemPicker>().pendingCaptureName();
  } on PlatformException {
    return; // marker unknown: keep everything rather than delete a capture in progress
  }
  await getIt<TempFiles>(instanceName: 'camera').sweep(keep: keep);
}
