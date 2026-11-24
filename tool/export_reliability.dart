// FEAT-007-T22 (NFR-6, FR-14, FR-16, NFR-1): kill test, low space and save timing on one device.
//
// Builds and installs integration_test/export_reliability_app.dart (debug), then:
//   kill      1 measured save, then [kills] runs killed at a random moment during the ~50 MB copy;
//             after every restart the app sweeps and checks that no unfinished save stays and every
//             visible ExactSize file has the blob's hash
//   lowspace  emulators only (ro.kernel.qemu=1), never a real phone: fills /data, expects NO_SPACE
//             and nothing written, frees the space, expects SAVED
//   timing    median of 20 saves of a 1 MB file (informational)
// Synthetic bytes only; nothing printed holds a file name, URI or path of the user's files.
//
//   dart run tool/export_reliability.dart [device-id] [kills]
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _pkg = 'com.exactsize.exact_size';
late List<String> _dev;

Future<String> adb(String command) async => '${(await Process.run('adb', [..._dev, 'shell', command])).stdout}'.trim();

Future<List<Map<String, dynamic>>> events() async => [
      for (final l in (await adb('run-as $_pkg cat files/rel_report 2>/dev/null')).split('\n'))
        if (l.trim().startsWith('{')) jsonDecode(l) as Map<String, dynamic>,
    ];

/// Waits until the report holds [count] events named [name]; returns all events.
Future<List<Map<String, dynamic>>> waitFor(String name, int count, {int seconds = 180}) async {
  for (var i = 0; i < seconds * 5; i++) {
    final e = await events();
    if (e.where((x) => x['event'] == name).length >= count) return e;
    if (e.any((x) => x['event'] == 'error')) throw StateError('app reported an error: ${e.last}');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  throw StateError('timed out waiting for $name #$count');
}

Future<void> launch() async => adb('am start -n $_pkg/.MainActivity');

Future<void> stop() async => adb('am force-stop $_pkg');

Future<void> setMode(String mode) async {
  await stop();
  await adb("run-as $_pkg sh -c 'mkdir -p files && echo $mode > files/rel_mode && rm -f files/rel_report'");
}

Future<void> main(List<String> args) async {
  _dev = [if (args.isNotEmpty) ...['-s', args[0]]];
  final kills = args.length > 1 ? int.parse(args[1]) : 20;
  final failures = <String>[];

  final build = await Process.run('flutter', ['build', 'apk', '--debug', '-t', 'integration_test/export_reliability_app.dart'], runInShell: true);
  if (build.exitCode != 0) throw StateError('build failed:\n${build.stdout}\n${build.stderr}');
  final install = await Process.run('adb', [..._dev, 'install', '-r', 'build/app/outputs/flutter-apk/app-debug.apk']);
  if (install.exitCode != 0) throw StateError('install failed: ${install.stdout}');
  final api = int.parse(await adb('getprop ro.build.version.sdk'));
  final emulator = await adb('getprop ro.kernel.qemu') == '1';
  if (api <= 28) {
    await adb('pm grant $_pkg android.permission.WRITE_EXTERNAL_STORAGE');
    await adb('pm grant $_pkg android.permission.READ_EXTERNAL_STORAGE');
  }

  // Kill test.
  await setMode('kill');
  await launch();
  final first = await waitFor('saved', 1);
  final copyMs = (first.lastWhere((e) => e['event'] == 'saved')['ms'] as num).toInt();
  final rnd = Random();
  var hits = 0;
  for (var i = 1; i <= kills; i++) {
    await stop();
    await launch();
    await waitFor('saving', i + 1);
    await Future<void>.delayed(Duration(milliseconds: rnd.nextInt(max(1, copyMs * 9 ~/ 10))));
    final pid = await adb('pidof $_pkg');
    if (pid.isNotEmpty) await adb('run-as $_pkg kill -9 $pid');
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  await stop();
  await launch();
  await waitFor('start', kills + 2, seconds: 300); // the final restart checks the last kill
  var all = await events();
  for (var i = 0; i < 900 && all.last['event'] != 'saved'; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 200)); // and completes its own save
    all = await events();
  }
  for (final s in all.where((e) => e['event'] == 'start')) {
    if (s['after'] != 0) failures.add('unfinished save left after the sweep: $s');
    if (s['badHash'] != 0) failures.add('visible file with a wrong hash: $s');
    if ((s['before'] as num? ?? 0) > 0) hits++;
  }
  final starts = all.where((e) => e['event'] == 'start').length;
  stdout.writeln('kill: api=$api copy=${copyMs}ms kills=$kills restarts=$starts killsInsideCopy=$hits');
  if (starts < kills + 2) failures.add('only $starts starts for $kills kills');
  if (hits == 0) failures.add('no kill landed inside the copy (R10): ask the Product Owner about the OQ-T5 debug delay');

  // Low space, emulators only.
  if (emulator) {
    final avail = int.parse(RegExp(r'\s(\d+)\s+\d+%').firstMatch(await adb('df -k /data | tail -1'))![1]!);
    final fillKb = avail - 20 * 1024; // leave 20 MB: less than the 50 MB blob
    await adb('fallocate -l ${fillKb}k /data/local/tmp/es_fill || dd if=/dev/zero of=/data/local/tmp/es_fill bs=1m count=${fillKb ~/ 1024}');
    await setMode('lowspace');
    await launch();
    final low = (await waitFor('lowspace', 1)).lastWhere((e) => e['event'] == 'lowspace')['result'];
    final leftovers = await adb('ls -A /sdcard/Pictures/ExactSize 2>/dev/null | wc -l');
    await adb('rm -f /data/local/tmp/es_fill');
    await setMode('lowspace');
    await launch();
    final freed = (await waitFor('lowspace', 1)).lastWhere((e) => e['event'] == 'lowspace')['result'];
    stdout.writeln('lowspace: full=$low leftovers=$leftovers afterFreeing=$freed');
    if (low != 'NO_SPACE') failures.add('low space gave $low, expected NO_SPACE');
    if (leftovers != '0') failures.add('low space left $leftovers entries');
    if (freed != 'SAVED') failures.add('after freeing space: $freed');
  } else {
    stdout.writeln('lowspace: skipped (real device)');
  }

  // Timing.
  await setMode('timing');
  await launch();
  final timing = (await waitFor('timing', 1)).lastWhere((e) => e['event'] == 'timing');
  stdout.writeln('timing: api=$api median=${timing['medianMs']}ms min=${timing['minMs']}ms max=${timing['maxMs']}ms (20 saves of 1 MB)');

  await stop();
  await adb("run-as $_pkg rm -f files/rel_mode files/rel_report");
  await adb('rm -f /sdcard/Pictures/ExactSize/exactsize-1x1-* /data/local/tmp/es_fill');
  if (failures.isEmpty) {
    stdout.writeln('All reliability checks passed.');
    exit(0);
  }
  stdout.writeln('Failures:\n- ${failures.join('\n- ')}');
  exit(1);
}
