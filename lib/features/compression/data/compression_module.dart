import 'package:injectable/injectable.dart';

import 'compression_runner.dart';
import 'compression_service.dart';
import 'temp_files.dart';

/// FEAT-004 registrations in the get_it container (ADR-001 v1.1).
@module
abstract class CompressionModule {
  /// Resolved before the app starts: the cache folder is needed for the
  /// start-up sweep (FR-20) and for every result.
  @preResolve
  @singleton
  Future<TempFiles> get tempFiles => TempFiles.appCache();

  @lazySingleton
  CompressionService compressionService(TempFiles files) =>
      CompressionService(const CompressionRunner(), files);
}
