import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:exact_size/di/injection.dart';
import 'package:exact_size/features/compression/data/compression_runner.dart';
import 'package:exact_size/features/compression/data/compression_service.dart';
import 'package:exact_size/features/compression/data/temp_files.dart';
import 'package:exact_size/features/compression/domain/compression_request.dart';
import 'package:exact_size/features/compression/domain/compression_result.dart';
import 'package:exact_size/features/compression/presentation/compression_providers.dart';
import 'package:exact_size/features/compression/presentation/outcome_messages.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_support/test_pixels.dart';

/// Scripted stand-in for the service: each run waits for [release], reports
/// progress through [progress], then writes a real temp file (success) or
/// returns [failWith]. A cancel seen at the end gives CANCELLED, like the
/// real service.
final class FakeCompressionService implements CompressionService {
  FakeCompressionService(this.files);
  final TempFiles files;
  int calls = 0;
  Reason? failWith;
  Completer<void> release = Completer();
  void Function(int pass, int max)? progress;

  @override
  Future<CompressionResult> compress(CompressionRequest request,
      {CancelSignal? cancel, void Function(int pass, int maxPasses)? onProgress}) async {
    calls++;
    progress = onProgress;
    await release.future;
    if (cancel?.isCancelled ?? false) return const CompressionFailure(reason: Reason.cancelled);
    final reason = failWith;
    if (reason != null) {
      return CompressionFailure(reason: reason, closestBytes: 61300, direction: Direction.tooBig);
    }
    final path = await files.write(Uint8List.fromList(List.filled(100, 7)), OutputFormat.jpeg);
    return CompressionSuccess(tempFilePath: path, sizeBytes: 48200, format: OutputFormat.jpeg, quality: 80);
  }
}

CompressionRequest request() => CompressionRequest(
    pixels: TestPixels(2, 2, 3, Uint8List(12), hasTransparency: false), minKb: 20, maxKb: 50, format: OutputFormat.jpeg);

void main() {
  late Directory cache;
  late TempFiles files;
  late FakeCompressionService service;
  final messages = OutcomeMessages(lookupAppLocalizations(const Locale('en')));

  setUp(() {
    cache = Directory.systemTemp.createTempSync('exactsize_t20_');
    files = TempFiles(cache);
    service = FakeCompressionService(files);
    getIt
      ..registerSingleton<TempFiles>(files)
      ..registerSingleton<CompressionService>(service);
  });

  tearDown(() async {
    await getIt.reset();
    cache.deleteSync(recursive: true);
  });

  List<FileSystemEntity> outputs() => files.dir.existsSync() ? files.dir.listSync() : [];

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('progress and success have non-empty announcements', () async {
    final c = container();
    final run = c.read(compressionControllerProvider.notifier).start(request());
    await pumpEventQueue();
    expect(announcementFor(c.read(compressionControllerProvider), messages), 'Compressing, step \u20681\u2069 of \u206810\u2069.');
    service.progress!(3, 10);
    expect((c.read(compressionControllerProvider) as CompressionRunning).pass, 3);
    expect(announcementFor(c.read(compressionControllerProvider), messages), contains('\u20683\u2069'));
    service.release.complete();
    await run;
    final done = c.read(compressionControllerProvider) as CompressionDone;
    expect(done.result, isA<CompressionSuccess>());
    expect(announcementFor(done, messages), 'Done. File size: \u2068${'48.2 KB'}\u2069.');
    expect(announcementFor(const CompressionIdle(), messages), isNull);
  });

  test('every failure has a non-empty localised announcement', () async {
    for (final locale in ['en', 'ar']) {
      final m = OutcomeMessages(lookupAppLocalizations(Locale(locale)));
      for (final reason in Reason.values) {
        final c = container();
        service
          ..failWith = reason
          ..release = (Completer()..complete());
        await c.read(compressionControllerProvider.notifier).start(request());
        final state = c.read(compressionControllerProvider) as CompressionDone;
        expect((state.result as CompressionFailure).reason, reason);
        expect(announcementFor(state, m), isNotEmpty, reason: '$locale $reason');
      }
    }
    expect(outputs(), isEmpty);
  });

  testWidgets('rebuilding the screen (rotation) does not start a second run', (tester) async {
    final c = ProviderContainer();
    final req = request();
    service.failWith = Reason.aboveMax; // no file I/O inside fake async
    Widget screen(Key key) => UncontrolledProviderScope(container: c, child: _StartsOnMount(req, key: key));
    await tester.pumpWidget(screen(const ValueKey('portrait')));
    await tester.pump();
    await tester.pumpWidget(screen(const ValueKey('landscape'))); // new State, same request
    await tester.pump();
    expect(service.calls, 1);
    service.release.complete();
    await tester.runAsync(pumpEventQueue); // setUp's Completer lives outside fake async
    expect(c.read(compressionControllerProvider), isA<CompressionDone>());
    // Mounting again after the run still does not reuse the request.
    await tester.pumpWidget(screen(const ValueKey('again')));
    await tester.pump();
    expect(service.calls, 1);
    c.dispose();
  });

  test('cancel during a run gives CANCELLED and leaves no file', () async {
    final c = container();
    final run = c.read(compressionControllerProvider.notifier).start(request());
    await pumpEventQueue();
    await c.read(compressionControllerProvider.notifier).cancel();
    service.release.complete();
    await run;
    final done = c.read(compressionControllerProvider) as CompressionDone;
    expect((done.result as CompressionFailure).reason, Reason.cancelled);
    expect(outputs(), isEmpty);
  });

  test('cancel after success deletes the temp file and returns to idle', () async {
    final c = container();
    service.release.complete();
    await c.read(compressionControllerProvider.notifier).start(request());
    final path = ((c.read(compressionControllerProvider) as CompressionDone).result as CompressionSuccess).tempFilePath;
    expect(File(path).existsSync(), isTrue);
    await c.read(compressionControllerProvider.notifier).cancel();
    expect(File(path).existsSync(), isFalse);
    expect(c.read(compressionControllerProvider), isA<CompressionIdle>());
  });

  test('a new run deletes the previous unexported file', () async {
    final c = container();
    service.release.complete();
    await c.read(compressionControllerProvider.notifier).start(request());
    final first = ((c.read(compressionControllerProvider) as CompressionDone).result as CompressionSuccess).tempFilePath;
    await c.read(compressionControllerProvider.notifier).start(request());
    expect(File(first).existsSync(), isFalse);
    expect(outputs(), hasLength(1));
  });
}

/// Screen that starts its request when mounted, as FEAT-006 might.
class _StartsOnMount extends ConsumerStatefulWidget {
  const _StartsOnMount(this.request, {super.key});
  final CompressionRequest request;
  @override
  ConsumerState<_StartsOnMount> createState() => _StartsOnMountState();
}

class _StartsOnMountState extends ConsumerState<_StartsOnMount> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(compressionControllerProvider.notifier).start(widget.request));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
