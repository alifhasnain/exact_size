import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/common.dart';

/// FEAT-001-T25 driver (FR-20, AC-8.1–8.5). Pushes one synthetic image to the
/// shared Download folder and finds its MediaStore URI. While
/// `integration_test/pick_share_test.dart` runs (warm start), it fires each
/// share the test asks for in `files/share_request`. After the test, it checks
/// AC-8.3 with `cmd package query-activities`, a second warm share (still one
/// MainActivity), then a cold start (app stopped first). Synthetic image only;
/// nothing printed holds a URI or file name.
///
/// The shell can grant a URI only when it is the intent data (`-d`); the stream
/// extra alone carries no grant (G1 finding 2), which gives the denied-grant case.
///
/// ```
/// DEVICE=[id] flutter drive --driver test_driver/share_intent_driver.dart \
///   --target integration_test/pick_share_test.dart -d [id]
/// ```
const _package = 'com.exactsize.exact_size';
const _image = '/sdcard/Download/es_share_t25.png';
final _dev = [
  if (Platform.environment['DEVICE'] case final d?) ...['-s', d],
];

Future<String> adb(String command) async {
  final r = await Process.run('adb', [..._dev, 'shell', command]);
  return '${r.stdout}';
}

Future<void> share(String kind, String mediaUri) {
  final base = 'am start -n $_package/.ShareTargetActivity -a android.intent.action.SEND -t "image/*"';
  return adb(switch (kind) {
    'content' => '$base -d $mediaUri --eu android.intent.extra.STREAM $mediaUri --grant-read-uri-permission',
    'nogrant' => '$base --eu android.intent.extra.STREAM $mediaUri',
    'file' => '$base --eu android.intent.extra.STREAM file://$_image',
    _ => base, // nostream
  });
}

Future<String> mediaUri() async {
  await Process.run('adb', [..._dev, 'push', 'test_support/crop_fixtures/alpha_opaque.png', _image]);
  await adb('am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://$_image');
  for (var i = 0; i < 20; i++) {
    final row = await adb(
      'content query --uri content://media/external/images/media --projection _id '
      "--where \"_display_name='es_share_t25.png'\"",
    );
    final id = RegExp(r'_id=(\d+)').firstMatch(row)?.group(1);
    if (id != null) return 'content://media/external/images/media/$id';
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('synthetic image not found in MediaStore');
}

Future<int> pickLines(String outcome) async {
  final log = await Process.run('adb', [..._dev, 'logcat', '-d', '-s', 'flutter']);
  return RegExp('exactsize\\.pick outcome=$outcome').allMatches('${log.stdout}').length;
}

Future<void> main() async {
  final uri = await mediaUri();
  final failures = <String>[];

  var serving = true;
  final server = () async {
    while (serving) {
      final kind = (await adb("run-as $_package sh -c 'cat files/share_request 2>/dev/null; rm -f files/share_request'")).trim();
      if (kind.isNotEmpty) await share(kind, uri);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }();

  final driver = await FlutterDriver.connect();
  final response = Response.fromJson(await driver.requestData(null, timeout: const Duration(minutes: 10)));
  await driver.close();
  serving = false;
  await server;
  if (!response.allTestsPassed) failures.add('in-app share test:\n${response.formattedFailureDetails}');

  // AC-8.3: only single-image send is registered. The SEND query proves the command works here.
  final send = await adb('cmd package query-activities -a android.intent.action.SEND -t "image/*"');
  final multiple = await adb('cmd package query-activities -a android.intent.action.SEND_MULTIPLE -t "image/*"');
  if (!send.contains('$_package.ShareTargetActivity')) {
    failures.add('AC-8.3: SEND image/* does not list ShareTargetActivity');
  }
  if (multiple.contains(_package)) failures.add('AC-8.3: SEND_MULTIPLE image/* lists the app');

  // Warm again (onNewIntent): still exactly one MainActivity, in one task.
  await share('content', uri);
  await Future<void>.delayed(const Duration(seconds: 3));
  final activities = await adb('dumpsys activity activities');
  final instances = activities.split('\n').where((l) => l.contains('Hist') && l.contains('$_package/.MainActivity')).length;
  if (instances != 1) failures.add('warm share: $instances MainActivity records, expected 1');

  // Cold start (AC-8.1): app stopped, share starts it; the result waiting at start-up is accepted once.
  await adb('am force-stop $_package');
  await Process.run('adb', [..._dev, 'logcat', '-c']);
  await share('content', uri);
  var accepted = 0;
  for (var i = 0; i < 60 && accepted == 0; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    accepted = await pickLines('ACCEPTED');
  }
  await Future<void>.delayed(const Duration(seconds: 2));
  accepted = await pickLines('ACCEPTED');
  if (accepted != 1) failures.add('cold share: $accepted ACCEPTED lines, expected 1');
  final top = (await adb('dumpsys activity activities')).split('\n').firstWhere((l) => l.contains('topResumedActivity'), orElse: () => '');
  if (!top.contains('$_package/.MainActivity')) failures.add('cold share: MainActivity is not on top');

  await adb('am force-stop $_package');
  await adb("run-as $_package rm -f files/share_request"); // the cold-started test may have asked again
  await adb("content delete --uri $uri; rm -f $_image");

  if (failures.isEmpty) {
    stdout.writeln('All tests passed. Share driver checks: AC-8.3, warm single instance, cold start.');
    exit(0);
  }
  stdout.writeln('Failure Details:\n${failures.join('\n')}');
  exit(1);
}
