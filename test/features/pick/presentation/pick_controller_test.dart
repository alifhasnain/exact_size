import 'dart:io';
import 'dart:math';

import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/pick/data/pick_outcome_log.dart';
import 'package:exact_size/features/pick/data/system_picker.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/pick/presentation/pick_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_support/fake_system_picker.dart';

const _info = SourceInfo(
    rawWidth: 40, rawHeight: 30, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region);
const _uri = 'content://media/external/images/media/[PLACEHOLDER]';
const _camUri = 'content://com.exactsize.exact_size.camera/camera/[PLACEHOLDER]';

class _Probe extends SourceProbe {
  ProbeResult next = const ProbeOk(_info);
  int calls = 0;
  @override
  Future<ProbeResult> probe(SourceHandle src) async {
    calls++;
    return next;
  }
}

/// FEAT-001-T13: PickController launch, result handling, one image, release().
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeSystemPicker picker;
  late TempFiles files;
  late _Probe probe;
  late List<String> log;
  late Directory tmp;
  late ProviderContainer c;

  setUp(() async {
    await getIt.reset();
    picker = FakeSystemPicker();
    tmp = await Directory.systemTemp.createTemp('pick_ctl');
    files = TempFiles(tmp, folder: 'camera');
    await files.dir.create();
    probe = _Probe();
    log = [];
    getIt
      ..registerSingleton<SystemPicker>(picker)
      ..registerSingleton<TempFiles>(files, instanceName: 'camera')
      ..registerSingleton<SourceProbe>(probe)
      ..registerSingleton(PickOutcomeLog(log.add));
    c = ProviderContainer();
  });

  tearDown(() async {
    c.dispose();
    // T14 log audit, across the whole suite: enum codes only.
    for (final line in log) {
      expect(line, matches(RegExp(r'^exactsize\.pick outcome=[A-Z_]+$')));
    }
    await tmp.delete(recursive: true);
  });

  PickController ctl() => c.read(pickControllerProvider.notifier);
  PickState st() => c.read(pickControllerProvider);
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  String cam([int bytes = 10]) {
    final r = Random.secure();
    final name = '${List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}.jpg';
    File('${files.dir.path}/$name').writeAsBytesSync(List.filled(bytes, 1));
    return name;
  }

  bool exists(String name) => File('${files.dir.path}/$name').existsSync();

  Future<void> start() async {
    st();
    await settle();
  }

  test('fresh controller: no image, camera availability read (FR-16, FR-5)', () async {
    await start();
    expect(st().current, isNull);
    expect(st().cameraAvailable, isTrue);
    expect(st().phase, PickPhase.idle);
  });

  test('a result waiting before Dart ran is handled once at build (FR-15)', () async {
    picker.slot = const Picked(uri: _uri, origin: PickOrigin.gallery);
    await start();
    expect(st().current?.origin, PickOrigin.gallery);
    expect(probe.calls, 1);
  });

  test('Picked gallery image becomes current', () async {
    await start();
    await ctl().launch(PickSource.gallery);
    expect(st().phase, PickPhase.awaitingSystemUi);
    picker.deliver(const Picked(uri: _uri, origin: PickOrigin.gallery));
    await settle();
    expect(st().current!.handle.uri, _uri);
    expect(st().current!.cameraFile, isNull);
    expect(st().phase, PickPhase.idle);
    expect(log, ['exactsize.pick outcome=ACCEPTED']);
  });

  test('resultReady twice gives one probe', () async {
    await start();
    picker.slot = const Picked(uri: _uri, origin: PickOrigin.gallery);
    picker
      ..signal()
      ..signal();
    await settle();
    expect(probe.calls, 1);
  });

  test('double launch calls the system picker once (AC-5.4)', () async {
    await start();
    final a = ctl().launch(PickSource.gallery);
    final b = ctl().launch(PickSource.camera);
    await Future.wait([a, b]);
    expect(picker.launches, [PickSource.gallery]);
  });

  test('Cancelled deletes its camera file, idle, no message (FR-9)', () async {
    await start();
    final name = cam(0);
    picker.deliver(Cancelled(origin: PickOrigin.camera, fileName: name));
    await settle();
    expect(exists(name), isFalse);
    expect(st().message, isNull);
    expect(st().phase, PickPhase.idle);
    expect(log, ['exactsize.pick outcome=CANCELLED']);
  });

  test('CaptureLost deletes the file and says so; NotOpenable refuses', () async {
    await start();
    final name = cam();
    picker.deliver(CaptureLost(fileName: name));
    await settle();
    expect(exists(name), isFalse);
    expect(st().message, PickMessage.captureLost);
    picker.deliver(const NotOpenable(origin: PickOrigin.files));
    await settle();
    expect(st().message, PickMessage.itemNotOpenable);
  });

  test('file:// and own-app share are refused without probing (FR-8, FR-20)', () async {
    await start();
    picker.deliver(const Picked(uri: 'file:///sdcard/[PLACEHOLDER].jpg', origin: PickOrigin.gallery));
    await settle();
    expect(st().message, PickMessage.itemNotOpenable);
    picker.deliver(const Picked(uri: _uri, origin: PickOrigin.share, fromOwnApp: true));
    await settle();
    expect(st().message, PickMessage.itemNotOpenable);
    expect(probe.calls, 0);
  });

  test('camera file missing or zero bytes gives cameraNoPhoto (FR-6)', () async {
    await start();
    picker.deliver(const Captured(uri: _camUri, fileName: '0123456789abcdef0123456789abcdef.jpg'));
    await settle();
    expect(st().message, PickMessage.cameraNoPhoto);
    final empty = cam(0);
    picker.deliver(Captured(uri: _camUri, fileName: empty));
    await settle();
    expect(st().message, PickMessage.cameraNoPhoto);
    expect(exists(empty), isFalse);
    expect(probe.calls, 0);
  });

  test('accepting a new camera image deletes the previous file (FR-10, FR-11)', () async {
    await start();
    final a = cam();
    picker.deliver(Captured(uri: _camUri, fileName: a));
    await settle();
    expect(st().current!.cameraFile, a);
    final b = cam();
    picker.deliver(Captured(uri: _camUri, fileName: b));
    await settle();
    expect(st().current!.cameraFile, b);
    expect(exists(a), isFalse);
    expect(exists(b), isTrue);
  });

  test('a refusal keeps current and its file; the refused camera file is deleted (AC-3.3, AC-3.2)', () async {
    await start();
    final a = cam();
    picker.deliver(Captured(uri: _camUri, fileName: a));
    await settle();
    probe.next = const ProbeErr(Reason.corruptInput);
    final b = cam();
    picker.deliver(Captured(uri: _camUri, fileName: b));
    await settle();
    expect(st().message, PickMessage.corrupt);
    expect(st().current!.cameraFile, a);
    expect(exists(a), isTrue);
    expect(exists(b), isFalse);
  });

  test('picker unavailable keeps cameraAvailable; camera unavailable clears it; low space', () async {
    await start();
    picker.nextLaunch = LaunchOutcome.unavailable;
    await ctl().launch(PickSource.gallery);
    expect(st().message, PickMessage.pickerUnavailable);
    expect(st().cameraAvailable, isTrue);
    await ctl().launch(PickSource.camera);
    expect(st().cameraAvailable, isFalse);
    expect(st().phase, PickPhase.idle);
    picker.nextLaunch = LaunchOutcome.lowSpace;
    await ctl().launch(PickSource.camera);
    expect(st().message, PickMessage.lowSpace);
  });

  test('the next launch clears the last message', () async {
    await start();
    picker.nextLaunch = LaunchOutcome.lowSpace;
    await ctl().launch(PickSource.camera);
    picker.nextLaunch = LaunchOutcome.launched;
    await ctl().launch(PickSource.gallery);
    expect(st().message, isNull);
  });

  test('release() empties state and the camera folder', () async {
    await start();
    final a = cam();
    picker.deliver(Captured(uri: _camUri, fileName: a));
    await settle();
    cam(); // a stray file
    await ctl().release();
    expect(st().current, isNull);
    expect(st().cameraAvailable, isTrue);
    expect(files.dir.listSync(), isEmpty);
  });
}
