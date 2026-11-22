import 'dart:io';
import 'dart:math';

import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/pick/data/pick_outcome_log.dart';
import 'package:exact_size/features/pick/data/system_picker.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/pick/presentation/pick_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test_support/fake_system_picker.dart';

/// FEAT-001-T15, gate G2: the real PickController, SourceProbe and camera
/// TempFiles on pushed fixtures. A fake bridge emits `Captured` for a fixture
/// copied into `<cache>/camera/` and opened through the app's own FileProvider
/// URI. After every case only the accepted capture may exist in app storage.
///   DEVICE=[id] LARGE_DIR=[dir, optional] flutter drive \
///     --driver test_driver/push_fixtures_driver.dart \
///     --target integration_test/pick_data_matrix.dart -d [id]
const _authority = 'content://com.exactsize.exact_size.camera';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory fixtures;
  late Directory cache;
  late Directory support;
  late TempFiles camera;
  late FakeSystemPicker picker;
  late List<String> log;
  late ProviderContainer c;
  late Set<String> baseline;

  /// Every file under cache/ and files/ except the pushed fixtures.
  Set<String> storage() => {
        for (final root in [cache, support])
          if (root.existsSync())
            for (final f in root.listSync(recursive: true).whereType<File>())
              if (!f.path.startsWith(fixtures.path)) f.path,
      };

  String randomName() {
    final r = Random.secure();
    return '${List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}.jpg';
  }

  /// Copies [fixture] into the camera folder as a capture would be written.
  String capture(String fixture) {
    final name = randomName();
    File('${fixtures.path}/$fixture').copySync('${camera.dir.path}/$name');
    return name;
  }

  PickState st() => c.read(pickControllerProvider);

  /// Delivers [r] and waits for its single outcome log line (always written last).
  Future<String> deliver(SystemPickResult r) async {
    final before = log.length;
    picker.deliver(r);
    for (var i = 0; i < 6000 && log.length == before; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(log.length, before + 1, reason: 'no outcome');
    return log.last.split('=').last;
  }

  /// Only the accepted capture (if any) is new in app storage.
  void expectNoCopies() {
    final file = st().current?.cameraFile;
    final allowed = {if (file != null) '${camera.dir.path}/$file'};
    expect(storage().difference(baseline), allowed);
  }

  setUpAll(() async {
    support = await getApplicationSupportDirectory();
    cache = await getTemporaryDirectory();
    fixtures = Directory('${support.path}/fixtures');
    for (var i = 0; i < 600 && !File('${fixtures.path}/.ready').existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(File('${fixtures.path}/.ready').existsSync(), isTrue, reason: 'fixtures were not pushed');
    camera = TempFiles(cache, folder: 'camera');
    await camera.dir.create(recursive: true);
    await camera.sweep();
    await getIt.reset();
    picker = FakeSystemPicker();
    log = [];
    getIt
      ..registerSingleton<SystemPicker>(picker)
      ..registerSingleton<TempFiles>(camera, instanceName: 'camera')
      ..registerSingleton<SourceProbe>(const SourceProbe())
      ..registerSingleton(PickOutcomeLog(log.add));
    c = ProviderContainer();
    st();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    baseline = storage();
  });

  tearDownAll(() async {
    c.dispose();
    for (final line in log) {
      expect(line, matches(RegExp(r'^exactsize\.pick outcome=[A-Z_]+$')));
    }
  });

  test('valid JPEG, PNG and WebP captures are accepted; each replaces the last (FR-10)', () async {
    String? previous;
    for (final f in ['orient_1_exif.jpg', 'size_200x200.png', 'animated.webp']) {
      final name = capture(f);
      expect(await deliver(Captured(uri: '$_authority/camera/$name', fileName: name)), 'ACCEPTED', reason: f);
      expect(st().current!.cameraFile, name);
      if (previous != null) expect(File('${camera.dir.path}/$previous').existsSync(), isFalse, reason: f);
      expectNoCopies();
      previous = name;
    }
  });

  test('AC-3.5 set is refused with the expected code; refused file gone, current kept (AC-3.1, AC-3.2)', () async {
    final kept = st().current?.cameraFile;
    expect(kept, isNotNull);
    const cases = {
      'truncated.jpg': 'CORRUPT',
      'not_an_image.jpg': 'CORRUPT',
      'corrupt.png': 'CORRUPT',
      'video_ftyp_only.mp4': 'CORRUPT', // PRD section 8: UNSUPPORTED or CORRUPT for a video
      'claims_250mp.png': 'TOO_LARGE',
      'claims_200000001px.png': 'TOO_LARGE',
      'zero_bytes.jpg': 'CAMERA_NO_PHOTO', // camera path checks length first (FR-6)
    };
    for (final MapEntry(key: f, value: code) in cases.entries) {
      final name = capture(f);
      expect(await deliver(Captured(uri: '$_authority/camera/$name', fileName: name)), code, reason: f);
      // ignore: avoid_print
      print('PICK $f $code');
      expect(File('${camera.dir.path}/$name').existsSync(), isFalse, reason: f);
      expect(st().current!.cameraFile, kept, reason: f);
      expect(st().phase, PickPhase.idle);
      expectNoCopies();
    }
  });

  test('zero-byte file picked from the gallery path gives CORRUPT_INPUT (AC-3.5)', () async {
    final uri = Uri.file('${fixtures.path}/zero_bytes.jpg').toString();
    // file:// is refused before the probe (FR-8); the probe code is checked through
    // the own FileProvider instead, which the gallery path accepts as content://.
    final name = capture('zero_bytes.jpg');
    expect(await deliver(Picked(uri: '$_authority/camera/$name', origin: PickOrigin.gallery)), 'CORRUPT');
    expect(await deliver(Picked(uri: uri, origin: PickOrigin.gallery)), 'ITEM_NOT_OPENABLE');
    await camera.delete('${camera.dir.path}/$name'); // a gallery pick owns no camera file
    expectNoCopies();
  });

  test('HEIC this API cannot decode is refused with UNSUPPORTED_INPUT, or N/A', () async {
    final name = capture('depth10.heic');
    final code = await deliver(Captured(uri: '$_authority/camera/$name', fileName: name));
    // API 28 refuses bounds; API 36 reads bounds and fails later at decode (FEAT-002-T04).
    // ignore: avoid_print
    print('PICK depth10.heic $code${code == 'ACCEPTED' ? ' (undecodable-HEIC case N/A on this API)' : ''}');
    expect(code, anyOf('UNSUPPORTED', 'ACCEPTED'));
    expectNoCopies();
  });

  test('path traversal through the FileProvider and an ungranted media URI give SOURCE_UNAVAILABLE', () async {
    final kept = st().current;
    final out = Directory('${cache.path}/exactsize_out')..createSync(recursive: true);
    final target = File('${out.path}/${randomName()}');
    File('${fixtures.path}/orient_1_exif.jpg').copySync(target.path);
    try {
      final name = capture('orient_1_exif.jpg');
      final traversal = '$_authority/camera/../exactsize_out/${target.uri.pathSegments.last}';
      expect(await deliver(Captured(uri: traversal, fileName: name)), 'SOURCE_UNAVAILABLE');
      expect(File('${camera.dir.path}/$name').existsSync(), isFalse);
    } finally {
      target.deleteSync();
    }
    expect(await deliver(const Picked(uri: 'content://media/external/images/media/1', origin: PickOrigin.gallery)),
        'SOURCE_UNAVAILABLE');
    expect(st().current, same(kept));
    expectNoCopies();
  });

  test('release() leaves no image and an empty camera folder (FR-11)', () async {
    await c.read(pickControllerProvider.notifier).release();
    expect(st().current, isNull);
    expect(camera.dir.listSync(), isEmpty);
    expectNoCopies();
  });

  test('12 MP JPEG from Captured to PickedImage, 20 runs (NFR-1, OQ-T6, informational)', () async {
    final large = fixtures.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => RegExp(r'^large_12mp_.*_baseline\.jpg$').hasMatch(n)).firstOrNull;
    if (large == null) {
      markTestSkipped('LARGE_DIR not pushed');
      return;
    }
    final ms = <int>[];
    for (var i = 0; i < 20; i++) {
      final name = capture(large);
      final sw = Stopwatch()..start();
      expect(await deliver(Captured(uri: '$_authority/camera/$name', fileName: name)), 'ACCEPTED');
      ms.add(sw.elapsedMilliseconds);
    }
    ms.sort();
    // ignore: avoid_print
    print('PICK 12MP median=${(ms[9] + ms[10]) ~/ 2} ms min=${ms.first} max=${ms.last}');
    await c.read(pickControllerProvider.notifier).release();
    expect(camera.dir.listSync(), isEmpty);
    expectNoCopies();
  });
}
