// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:io';

import 'package:jnigen/jnigen.dart';

/// FEAT-004-T02 JNIgen proof: binding for android.os.Build (VERSION.SDK_INT).
/// Regenerate with: dart run tool/jnigen.dart (needs a JDK 17-21).
Future<void> main() async {
  final root = Platform.script.resolve('../');
  await JniGenerator(
    input: Input(
      classes: ['android.os.Build'],
      androidSdk: AndroidSdk(versions: [36], sdkRoot: _androidSdkRoot()),
    ),
    output: Output(
      dart: DartOutput(
        path: root.resolve('lib/src/android/android_build.g.dart'),
        structure: OutputStructure.singleFile,
      ),
    ),
  ).generate();
}

/// ANDROID_SDK_ROOT / ANDROID_HOME, else the default Windows install location.
Uri _androidSdkRoot() {
  final env = Platform.environment;
  final local = env['LOCALAPPDATA'];
  final root = env['ANDROID_SDK_ROOT'] ??
      env['ANDROID_HOME'] ??
      (local != null ? '$local/Android/Sdk' : null);
  if (root == null) {
    throw StateError('Set ANDROID_SDK_ROOT to the Android SDK path.');
  }
  return Directory(root).uri;
}
