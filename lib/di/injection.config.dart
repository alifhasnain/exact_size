// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:exact_size/features/compression/data/compression_module.dart'
    as _i1067;
import 'package:exact_size/features/compression/data/compression_service.dart'
    as _i99;
import 'package:exact_size/features/compression/data/temp_files.dart' as _i630;
import 'package:exact_size/features/crop/data/source_probe.dart' as _i54;
import 'package:exact_size/features/export/data/export_bridge.dart' as _i527;
import 'package:exact_size/features/export/data/export_module.dart' as _i750;
import 'package:exact_size/features/export/data/export_outcome_log.dart'
    as _i396;
import 'package:exact_size/features/export/data/share_copies.dart' as _i277;
import 'package:exact_size/features/pick/data/pick_module.dart' as _i408;
import 'package:exact_size/features/pick/data/pick_outcome_log.dart' as _i940;
import 'package:exact_size/features/pick/data/system_picker.dart' as _i727;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final compressionModule = _$CompressionModule();
    final exportModule = _$ExportModule();
    final pickModule = _$PickModule();
    await gh.singletonAsync<_i630.TempFiles>(
      () => compressionModule.tempFiles,
      preResolve: true,
    );
    gh.lazySingleton<_i527.ExportBridge>(() => exportModule.exportBridge);
    gh.lazySingleton<_i396.ExportOutcomeLog>(
      () => exportModule.exportOutcomeLog,
    );
    gh.lazySingleton<_i727.SystemPicker>(() => pickModule.systemPicker);
    gh.lazySingleton<_i54.SourceProbe>(() => pickModule.sourceProbe);
    gh.lazySingleton<_i940.PickOutcomeLog>(() => pickModule.pickOutcomeLog);
    await gh.singletonAsync<_i630.TempFiles>(
      () => exportModule.shareFiles,
      instanceName: 'share',
      preResolve: true,
    );
    gh.lazySingleton<_i99.CompressionService>(
      () => compressionModule.compressionService(gh<_i630.TempFiles>()),
    );
    await gh.singletonAsync<_i630.TempFiles>(
      () => pickModule.cameraFiles,
      instanceName: 'camera',
      preResolve: true,
    );
    gh.lazySingleton<_i277.ShareCopies>(
      () =>
          exportModule.shareCopies(gh<_i630.TempFiles>(instanceName: 'share')),
    );
    return this;
  }
}

class _$CompressionModule extends _i1067.CompressionModule {}

class _$ExportModule extends _i750.ExportModule {}

class _$PickModule extends _i408.PickModule {}
