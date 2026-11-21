// CI entry point: runs every integration test file in one app build and one
// install instead of one per file (each build plus install took about 30 s).
// Not named `_test` so `flutter test integration_test` does not run it twice.
//
// Kept out on purpose (they run on their own in CI):
//  - offline_test.dart needs --dart-define=OFFLINE=true and networking off;
//  - memory_profile_test.dart measures RSS, which earlier tests would inflate.
//
// test/integration_bundle_test.dart fails when a new *_test.dart file is not
// listed here.
//
// flutter test integration_test/bundle.dart --dart-define=EXPECTED_SDK_INT=28
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_start_test.dart' as app_start;
import 'compression_runner_test.dart' as compression_runner;
import 'corpus/corpus_test.dart' as corpus;
import 'crop_spike_test.dart' as crop_spike;
import 'golden_determinism_test.dart' as golden_determinism;
import 'interop_test.dart' as interop;
import 'jpeg_spike_test.dart' as jpeg_spike;
import 'memory_preflight_test.dart' as memory_preflight;
import 'temp_files_test.dart' as temp_files;
import 'turbo_jpeg_encoder_test.dart' as turbo_jpeg_encoder;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('app_start', app_start.main);
  group('compression_runner', compression_runner.main);
  group('crop_spike', crop_spike.main);
  group('golden_determinism', golden_determinism.main);
  group('interop', interop.main);
  group('jpeg_spike', jpeg_spike.main);
  group('memory_preflight', memory_preflight.main);
  group('temp_files', temp_files.main);
  group('turbo_jpeg_encoder', turbo_jpeg_encoder.main);
  group('corpus', corpus.main); // slowest, last
}
