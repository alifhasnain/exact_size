import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'crop_orientation_determinism.dart' as crop_orientation;
import 'crop_renderer_matrix.dart' as crop_renderer;
import 'crop_screen_flow.dart' as crop_screen;
import 'preview_decoder_matrix.dart' as preview_decoder;
import 'source_probe_matrix.dart' as source_probe;

/// FEAT-002 data-layer checks that need pushed fixtures, in one app build:
///   DEVICE=[id] LARGE_DIR=[dir, optional] flutter drive \
///     --driver test_driver/push_fixtures_driver.dart \
///     --target integration_test/crop_data_matrix.dart -d [id]
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('source_probe', source_probe.main);
  group('preview_decoder', preview_decoder.main);
  group('crop_renderer', crop_renderer.main);
  group('crop_orientation', crop_orientation.main);
  group('crop_screen', crop_screen.main);
}
