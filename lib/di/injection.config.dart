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
    await gh.singletonAsync<_i630.TempFiles>(
      () => compressionModule.tempFiles,
      preResolve: true,
    );
    gh.lazySingleton<_i99.CompressionService>(
      () => compressionModule.compressionService(gh<_i630.TempFiles>()),
    );
    return this;
  }
}

class _$CompressionModule extends _i1067.CompressionModule {}
