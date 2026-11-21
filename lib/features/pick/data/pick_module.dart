import 'package:injectable/injectable.dart';

import '../../compression/data/temp_files.dart';
import 'android_system_picker.dart';
import 'system_picker.dart';

/// FEAT-001 registrations in the get_it container (ADR-001 v1.1).
@module
abstract class PickModule {
  /// Camera captures live in `<cache>/camera/`, the only folder the
  /// FileProvider exposes (FR-4, FR-11). Resolved before start for the sweep.
  @preResolve
  @singleton
  @Named('camera')
  Future<TempFiles> get cameraFiles => TempFiles.appCache(folder: 'camera');

  /// The Kotlin bridge in MainActivity (ADR-006).
  @lazySingleton
  SystemPicker get systemPicker => AndroidSystemPicker();
}
