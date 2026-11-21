import 'package:exact_size/features/pick/data/android_system_picker.dart';
import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-001-T12: channel wrapper payload mapping, error sanitising, no logging.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('exactsize/system_picker');
  const uri = 'content://[PLACEHOLDER].provider/[PLACEHOLDER]';
  const name = '0123456789abcdef0123456789abcdef.jpg';
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall) f) => messenger.setMockMethodCallHandler(channel, (c) async => f(c));
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('parse', () {
    SystemPickResult? p(Object? raw) => AndroidSystemPicker.parse(raw);

    test('every well-formed payload shape', () {
      expect(p(null), isNull);
      expect(p({'origin': 'gallery', 'outcome': 'picked', 'uri': uri}),
          isA<Picked>().having((r) => r.uri, 'uri', uri).having((r) => r.origin, 'origin', PickOrigin.gallery).having((r) => r.fromOwnApp, 'own', false));
      expect(p({'origin': 'share', 'outcome': 'picked', 'uri': uri, 'fromOwnApp': true}),
          isA<Picked>().having((r) => r.fromOwnApp, 'own', true).having((r) => r.origin, 'origin', PickOrigin.share));
      expect(p({'origin': 'files', 'outcome': 'picked', 'uri': uri}), isA<Picked>().having((r) => r.origin, 'origin', PickOrigin.files));
      expect(p({'origin': 'camera', 'outcome': 'captured', 'uri': uri, 'fileName': name}),
          isA<Captured>().having((r) => r.fileName, 'name', name).having((r) => r.uri, 'uri', uri));
      expect(p({'origin': 'camera', 'outcome': 'cancelled', 'fileName': name}), isA<Cancelled>().having((r) => r.fileName, 'name', name));
      expect(p({'origin': 'gallery', 'outcome': 'cancelled'}),
          isA<Cancelled>().having((r) => r.fileName, 'name', isNull).having((r) => r.origin, 'origin', PickOrigin.gallery));
      expect(p({'origin': 'camera', 'outcome': 'captureLost', 'fileName': name}), isA<CaptureLost>().having((r) => r.fileName, 'name', name));
      expect(p({'origin': 'files', 'outcome': 'notOpenable'}), isA<NotOpenable>().having((r) => r.origin, 'origin', PickOrigin.files));
    });

    test('malformed payloads become NotOpenable; bad camera names are dropped', () {
      for (final raw in <Object>[
        'not a map',
        42,
        <String, Object?>{},
        {'origin': 'gallery', 'outcome': 'picked'}, // no uri
        {'origin': 'gallery', 'outcome': 'picked', 'uri': ''},
        {'origin': 'gallery', 'outcome': 'picked', 'uri': 7},
        {'origin': 'camera', 'outcome': 'picked', 'uri': uri}, // camera never "picks"
        {'origin': 'nowhere', 'outcome': 'picked', 'uri': uri},
        {'origin': 'gallery', 'outcome': 'exploded'},
        {'origin': 'camera', 'outcome': 'captured', 'uri': uri}, // no name
        {'origin': 'camera', 'outcome': 'captured', 'uri': uri, 'fileName': '../../shared_prefs/x.xml'},
        {'origin': 'camera', 'outcome': 'captured', 'uri': uri, 'fileName': 'ABCDEF0123456789ABCDEF0123456789.jpg'},
      ]) {
        expect(p(raw), isA<NotOpenable>(), reason: '$raw');
      }
      expect(p({'origin': 'camera', 'outcome': 'cancelled', 'fileName': '../x'}), isA<Cancelled>().having((r) => r.fileName, 'name', isNull));
      expect(p({'origin': 'camera', 'outcome': 'captureLost', 'fileName': 5}), isA<CaptureLost>().having((r) => r.fileName, 'name', isNull));
    });
  });

  test('calls, arguments and results', () async {
    final calls = <MethodCall>[];
    answer((c) {
      calls.add(c);
      return switch (c.method) {
        'cameraAvailable' => true,
        'launch' => 'busy',
        'takeResult' => {'origin': 'gallery', 'outcome': 'picked', 'uri': uri},
        'pendingCaptureName' => name,
        _ => null,
      };
    });
    final picker = AndroidSystemPicker();
    expect(await picker.cameraAvailable(), isTrue);
    expect(await picker.launch(PickSource.camera), LaunchOutcome.busy);
    expect(await picker.takeResult(), isA<Picked>());
    expect(await picker.pendingCaptureName(), name);
    expect(calls[1].arguments, {'source': 'camera'});
  });

  test('null and unknown answers fall back safely', () async {
    answer((c) => c.method == 'launch' ? 'teleported' : (c.method == 'pendingCaptureName' ? '../escape.jpg' : null));
    final picker = AndroidSystemPicker();
    expect(await picker.cameraAvailable(), isFalse);
    expect(await picker.launch(PickSource.gallery), LaunchOutcome.unavailable);
    expect(await picker.takeResult(), isNull);
    expect(await picker.pendingCaptureName(), isNull);
  });

  test('resultReady from Kotlin reaches the stream', () async {
    final picker = AndroidSystemPicker();
    final got = picker.resultReady.first;
    await messenger.handlePlatformMessage(
        channel.name, const StandardMethodCodec().encodeMethodCall(const MethodCall('resultReady')), (_) {});
    await expectLater(got, completes);
  });

  test('PlatformException keeps the code, drops the message, logs nothing', () async {
    final logged = <String>[];
    final original = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => logged.add('$m');
    addTearDown(() => debugPrint = original);
    answer((_) => throw PlatformException(code: 'internalError', message: 'boom $uri', details: uri));
    final picker = AndroidSystemPicker();
    for (final call in <Future<Object?> Function()>[
      picker.cameraAvailable,
      () => picker.launch(PickSource.gallery),
      picker.takeResult,
      picker.pendingCaptureName,
    ]) {
      await expectLater(
          call(),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'internalError')
              .having((e) => e.message, 'message', isNull)
              .having((e) => e.details, 'details', isNull)));
    }
    expect(logged.where((l) => l.contains('PLACEHOLDER')), isEmpty);
  });
}
