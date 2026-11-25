import 'package:injectable/injectable.dart';

import '../domain/measured_output.dart';
import 'file_output_measurer.dart';
import 'spec_check_log.dart';

/// FEAT-006 registrations in the get_it container (ADR-001).
@module
abstract class PreviewModule {
  @lazySingleton
  OutputMeasurer get outputMeasurer => const FileOutputMeasurer();

  @lazySingleton
  SpecCheckLog get specCheckLog => const SpecCheckLog();
}
