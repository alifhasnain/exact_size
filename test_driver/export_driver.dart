import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/common.dart';

/// FEAT-007-T11 driver for `integration_test/export_bridge_test.dart`. While the test runs it
/// answers requests the test writes to `files/export_request` (debuggable build, run-as):
///   grant          API 28: pm grant WRITE and READ (the dialog grants the storage group; T01)
///   ownshare:NAME  sends ExactSize's own share URI for NAME to ShareTargetActivity (FR-18)
///   plant          writes a synthetic .part file in Pictures/ExactSize as the shell user
///   checkpart      answers present or absent for that .part file
///   deny           API 28: waits for the permission dialog and denies it (Back)
///   denyforever    API 28: waits for the dialog, ticks "Don't ask again" and denies
///   nodialog       answers none when no permission dialog is in front
/// The dialog is the emulator's system UI (no personal data); buttons are found by resource id.
/// It deletes the .part afterwards. Synthetic data only; nothing printed holds a URI or name.
///
/// ```
/// DEVICE=[id] flutter drive --driver test_driver/export_driver.dart \
///   --target integration_test/export_bridge_test.dart --dart-define=EXPORT_DRIVER=true -d [id]
/// ```
const _package = 'com.exactsize.exact_size';
const _part = '/sdcard/Pictures/ExactSize/.exactsize-1x1-drvprt.jpg.part';
final _dev = [
  if (Platform.environment['DEVICE'] case final d?) ...['-s', d],
];

Future<String> adb(String command) async => '${(await Process.run('adb', [..._dev, 'shell', command])).stdout}';

Future<bool> dialogInFront() async => (await adb('dumpsys window | grep mCurrentFocus')).contains('GrantPermissionsActivity');

/// Centre of the element with [id] in a fresh UI dump, or null.
Future<String?> centre(String id) async {
  await adb('uiautomator dump /sdcard/es_export_dump.xml');
  final xml = await adb('cat /sdcard/es_export_dump.xml');
  await adb('rm -f /sdcard/es_export_dump.xml');
  final m = RegExp('resource-id="[^"]*:id/$id"' r'[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"').firstMatch(xml);
  if (m == null) return null;
  final v = [for (var i = 1; i <= 4; i++) int.parse(m[i]!)];
  return '${(v[0] + v[2]) ~/ 2} ${(v[1] + v[3]) ~/ 2}';
}

Future<String> denyDialog({required bool forever}) async {
  for (var i = 0; i < 50 && !await dialogInFront(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  if (!await dialogInFront()) return 'nodialog';
  if (forever) {
    final box = await centre('do_not_ask_checkbox');
    if (box == null) return 'nocheckbox';
    await adb('input tap $box');
  }
  final deny = await centre('permission_deny_button');
  await adb(deny == null ? 'input keyevent KEYCODE_BACK' : 'input tap $deny');
  return 'done';
}

Future<String> handle(String request) async {
  if (request == 'deny') return denyDialog(forever: false);
  if (request == 'denyforever') return denyDialog(forever: true);
  if (request == 'nodialog') return await dialogInFront() ? 'dialog' : 'none';
  if (request == 'grant') {
    await adb('pm grant $_package android.permission.WRITE_EXTERNAL_STORAGE');
    await adb('pm grant $_package android.permission.READ_EXTERNAL_STORAGE');
    return 'done';
  }
  if (request.startsWith('ownshare:')) {
    final uri = 'content://$_package.share/share/${request.substring(9)}';
    await adb('am start -n $_package/.ShareTargetActivity -a android.intent.action.SEND -t "image/*" --eu android.intent.extra.STREAM $uri');
    return 'done';
  }
  if (request == 'plant') {
    await adb('mkdir -p /sdcard/Pictures/ExactSize && echo synthetic > $_part');
    return 'done';
  }
  if (request == 'checkpart') return (await adb('[ -f $_part ] && echo present || echo absent')).trim();
  return 'unknown';
}

Future<void> main() async {
  var serving = true;
  final server = () async {
    while (serving) {
      final request = (await adb("run-as $_package sh -c 'cat files/export_request 2>/dev/null; rm -f files/export_request'")).trim();
      if (request.isNotEmpty) {
        final reply = await handle(request);
        await adb("run-as $_package sh -c 'echo $reply > files/export_reply'");
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }();

  final driver = await FlutterDriver.connect();
  final response = Response.fromJson(await driver.requestData(null, timeout: const Duration(minutes: 15)));
  await driver.close();
  serving = false;
  await server;
  await adb('rm -f $_part');
  await adb("run-as $_package rm -f files/export_request files/export_reply");

  if (response.allTestsPassed) {
    stdout.writeln('All tests passed.');
    exit(0);
  }
  stdout.writeln('Failure Details:\n${response.formattedFailureDetails}');
  exit(1);
}
