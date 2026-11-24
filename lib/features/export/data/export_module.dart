import 'package:injectable/injectable.dart';

import '../../compression/data/temp_files.dart';
import 'android_export_bridge.dart';
import 'export_bridge.dart';
import 'export_outcome_log.dart';
import 'share_copies.dart';

/// FEAT-007 registrations in the get_it container (ADR-001, ADR-007).
@module
abstract class ExportModule {
  /// Share copies live in `<cache>/exactsize_share/`, the only folder the share FileProvider
  /// exposes (FR-18). Resolved before start for the sweep.
  @preResolve
  @singleton
  @Named('share')
  Future<TempFiles> get shareFiles => TempFiles.appCache(folder: 'exactsize_share');

  /// The Kotlin bridge (ADR-007).
  @lazySingleton
  ExportBridge get exportBridge => AndroidExportBridge();

  @lazySingleton
  ShareCopies shareCopies(@Named('share') TempFiles files) => ShareCopies(files);

  @lazySingleton
  ExportOutcomeLog get exportOutcomeLog => const ExportOutcomeLog();
}
