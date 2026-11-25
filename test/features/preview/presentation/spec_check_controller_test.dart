import 'dart:async';
import 'dart:io';

import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart' as crop;
import 'package:exact_size/features/preview/data/spec_check_log.dart';
import 'package:exact_size/features/preview/domain/measured_output.dart';
import 'package:exact_size/features/preview/presentation/preview_providers.dart';
import 'package:exact_size/features/preview/presentation/spec_check_controller.dart';
import 'package:exact_size/features/target/domain/target_spec.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_support/fake_output_measurer.dart';

class _FakeCompression extends CompressionController {
  _FakeCompression(this.initial);
  final CompressionRunState initial;
  var cancels = 0;

  @override
  CompressionRunState build() => initial;

  void emit(CompressionRunState s) => state = s;

  @override
  Future<void> cancel() async {
    cancels++;
    if (state case CompressionDone(result: final CompressionSuccess s)) File(s.tempFilePath).deleteSync();
    state = const CompressionIdle();
  }
}

/// FEAT-006-T07: SpecCheckController sequence and states (tech 4.3 steps 1-5).
void main() {
  const spec = TargetSpec(width: 300, height: 300, maxKb: 50, format: OutputFormat.jpeg);
  late Directory tmp;
  late CompressionSuccess success;
  late FakeOutputMeasurer measurer;
  late FakePreviewDecoder decoder;
  late _FakeCompression compression;
  late List<String> logs;
  late List<SpecCheckState> states;
  late ProviderContainer container;
  var disposed = false;

  MeasuredOutput out({int w = 300, int h = 300, int bytes = 48200, OutputFormat f = OutputFormat.jpeg}) =>
      MeasuredOutput(bytes: bytes, width: w, height: h, format: f, hasAlpha: false);

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> start(WidgetTester tester,
      {CompressionRunState? initial,
      PreviewResult? preview,
      MeasureResult? measured,
      Completer<MeasureResult>? measureGate,
      Completer<PreviewResult>? decodeGate}) async {
    tmp = Directory.systemTemp.createTempSync('spec_check_test');
    final file = File('${tmp.path}/0123456789abcdef.jpg')..writeAsBytesSync(List.filled(48200, 1));
    success = CompressionSuccess(tempFilePath: file.path, sizeBytes: 48200, format: OutputFormat.jpeg);
    measurer = FakeOutputMeasurer(measured ?? Measured(out()));
    decoder = FakePreviewDecoder(preview ?? PreviewOk(await createTestImage(width: 30, height: 30), 1))..gate = decodeGate;
    measurer.gate = measureGate;
    disposed = false;
    compression = _FakeCompression(initial ?? CompressionDone(success, maxKb: 50));
    logs = [];
    states = [];
    container = ProviderContainer(overrides: [
      compressionControllerProvider.overrideWith(() => compression),
      outputMeasurerProvider.overrideWithValue(measurer),
      resultPreviewDecoderProvider.overrideWithValue(decoder),
      specCheckLogProvider.overrideWithValue(SpecCheckLog(logs.add)),
      previewMaxSideProvider.overrideWithValue(1080),
    ]);
    container.listen(specCheckControllerProvider(spec), (_, next) => states.add(next), fireImmediately: true);
    await settle();
  }

  tearDown(() {
    if (!disposed) container.dispose();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  testWidgets('idle until CompressionDone(success); then Checking and CheckMeets(image) in one transition', (tester) async {
    await tester.runAsync(() async {
      await start(tester, initial: const CompressionRunning(pass: 1, maxPasses: 9, maxKb: 50));
      expect(states, [isA<CheckIdle>()]);
      compression.emit(CompressionDone(success, maxKb: 50));
      await settle();
      expect(states.map((s) => s.runtimeType), [CheckIdle, Checking, CheckMeets]);
      final meets = states.last as CheckMeets;
      expect(meets.preview, isNotNull);
      expect(identical(meets.success, success), isTrue);
      expect(logs, ['exactsize.preview outcome=SPEC_MEETS']);
      expect(measurer.calls.single, (path: success.tempFilePath, expectedBytes: success.sizeBytes));
      final d = decoder.calls.single;
      expect((d.src.uri, d.maxSide, d.info.rawWidth, d.info.rawHeight, d.info.mime, d.info.decodePath),
          (Uri.file(success.tempFilePath).toString(), 1080, 300, 300, 'image/jpeg', crop.DecodePath.region));
    });
  });

  testWidgets('a failed compression stays idle', (tester) async {
    await tester.runAsync(() async {
      await start(tester,
          initial: const CompressionDone(CompressionFailure(reason: Reason.aboveMax), maxKb: 50));
      expect(states, [isA<CheckIdle>()]);
      expect(measurer.calls, isEmpty);
    });
  });

  for (final (name, m, field) in [
    ('width + 1', MeasuredOutput(bytes: 48200, width: 301, height: 300, format: OutputFormat.jpeg, hasAlpha: false), 'DIMENSIONS'),
    ('one byte over', MeasuredOutput(bytes: 50001, width: 300, height: 300, format: OutputFormat.jpeg, hasAlpha: false), 'SIZE'),
    ('PNG bytes', MeasuredOutput(bytes: 48200, width: 300, height: 300, format: OutputFormat.png, hasAlpha: false), 'FORMAT'),
  ]) {
    testWidgets('$name: CheckMismatch, cancel once, file gone, no decode, SPEC_MISMATCH fields=$field', (tester) async {
      await tester.runAsync(() async {
        await start(tester, measured: Measured(m));
        expect(states.last, isA<CheckMismatch>());
        expect(compression.cancels, 1);
        expect(File(success.tempFilePath).existsSync(), isFalse);
        expect(decoder.calls, isEmpty);
        expect(logs, ['exactsize.preview outcome=SPEC_MISMATCH fields=$field']);
        expect(container.read(compressionControllerProvider), isA<CompressionIdle>());
        expect(states.last, isA<CheckMismatch>(), reason: 'the Idle after cancel() resets nothing');
      });
    });
  }

  testWidgets('Unreadable: CheckUnreadable and SPEC_UNREADABLE', (tester) async {
    await tester.runAsync(() async {
      await start(tester, measured: const Unreadable());
      expect(states.last, isA<CheckUnreadable>());
      expect(logs, ['exactsize.preview outcome=SPEC_UNREADABLE']);
      expect(decoder.calls, isEmpty);
    });
  });

  testWidgets('out of memory in the preview: CheckMeets(null), SPEC_MEETS and PREVIEW_UNAVAILABLE', (tester) async {
    await tester.runAsync(() async {
      await start(tester, preview: const PreviewErr(crop.Reason.outOfMemoryHandled));
      expect((states.last as CheckMeets).preview, isNull);
      expect(logs, ['exactsize.preview outcome=SPEC_MEETS', 'exactsize.preview outcome=PREVIEW_UNAVAILABLE']);
    });
  });

  testWidgets('any other preview error: CheckUnreadable', (tester) async {
    await tester.runAsync(() async {
      await start(tester, preview: const PreviewErr(crop.Reason.corruptInput));
      expect(states.last, isA<CheckUnreadable>());
      expect(logs, ['exactsize.preview outcome=SPEC_UNREADABLE']);
    });
  });

  testWidgets('the Idle after leave() does not reset CheckMeets', (tester) async {
    await tester.runAsync(() async {
      await start(tester);
      final meets = states.last as CheckMeets;
      compression.emit(const CompressionIdle());
      await settle();
      expect(identical(container.read(specCheckControllerProvider(spec)), meets), isTrue);
      expect(measurer.calls, hasLength(1));
      expect(meets.preview!.debugDisposed, isFalse);
    });
  });

  // FEAT-006-T08: resume (FR-12), leave while measuring, image disposal (FR-19, AC-6.2).
  void resume(WidgetTester tester) {
    for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused,
        AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
  }

  testWidgets('resume after the file was deleted: CheckUnreadable, image disposed', (tester) async {
    await tester.runAsync(() async {
      await start(tester);
      final image = (states.last as CheckMeets).preview!;
      measurer.result = const Unreadable();
      resume(tester);
      await settle();
      expect(states.last, isA<CheckUnreadable>());
      expect(image.debugDisposed, isTrue);
      expect(logs.last, 'exactsize.preview outcome=SPEC_UNREADABLE');
    });
  });

  testWidgets('resume after an off-by-one replacement: CheckMismatch, image disposed', (tester) async {
    await tester.runAsync(() async {
      await start(tester);
      final image = (states.last as CheckMeets).preview!;
      measurer.result = Measured(out(w: 301));
      resume(tester);
      await settle();
      expect(states.last, isA<CheckMismatch>());
      expect(image.debugDisposed, isTrue);
      expect(compression.cancels, 1);
    });
  });

  testWidgets('resume with the file unchanged: measured once more, same state instance', (tester) async {
    await tester.runAsync(() async {
      await start(tester);
      final meets = states.last;
      final count = states.length;
      resume(tester);
      await settle();
      expect(measurer.calls, hasLength(2));
      expect(states, hasLength(count), reason: 'no redraw');
      expect(identical(container.read(specCheckControllerProvider(spec)), meets), isTrue);
      expect((meets as CheckMeets).preview!.debugDisposed, isFalse);
    });
  });

  testWidgets('resume in Checking, CheckMismatch or CheckUnreadable does nothing', (tester) async {
    await tester.runAsync(() async {
      final gate = Completer<MeasureResult>();
      await start(tester, measureGate: gate);
      expect(states.last, isA<Checking>());
      resume(tester);
      await settle();
      expect(measurer.calls, hasLength(1));
      gate.complete(Measured(out(w: 301)));
      await settle();
      expect(states.last, isA<CheckMismatch>());
      resume(tester);
      await settle();
      expect(measurer.calls, hasLength(1));
    });
    container.dispose();
    disposed = true;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    await tester.runAsync(() async {
      await start(tester, measured: const Unreadable());
      resume(tester);
      await settle();
      expect(measurer.calls, hasLength(1));
    });
  });

  testWidgets('leaving while measuring: nothing is set afterwards', (tester) async {
    await tester.runAsync(() async {
      final gate = Completer<MeasureResult>();
      await start(tester, measureGate: gate);
      final count = states.length;
      container.dispose();
      disposed = true;
      gate.complete(Measured(out()));
      await settle();
      expect(states, hasLength(count));
      expect(decoder.calls, isEmpty);
      expect(logs, isEmpty);
    });
  });

  testWidgets('leaving while decoding: the late image is disposed', (tester) async {
    await tester.runAsync(() async {
      final gate = Completer<PreviewResult>();
      await start(tester, decodeGate: gate);
      expect(states.last, isA<Checking>());
      container.dispose();
      disposed = true;
      final late = await createTestImage(width: 20, height: 20);
      gate.complete(PreviewOk(late, 1));
      await settle();
      expect(late.debugDisposed, isTrue);
      expect(states.last, isA<Checking>());
    });
  });

  testWidgets('disposing in CheckMeets disposes the image', (tester) async {
    await tester.runAsync(() async {
      await start(tester);
      final image = (states.last as CheckMeets).preview!;
      container.dispose();
      disposed = true;
      expect(image.debugDisposed, isTrue);
    });
  });
}
