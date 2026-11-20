import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

/// App-wide service container (ADR-001 v1.1). Riverpod providers read
/// services from here; domain code never imports it.
final GetIt getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
