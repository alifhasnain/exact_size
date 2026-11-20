// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:io';

import 'package:jnigen/jnigen.dart';

/// JNIgen bindings. Regenerate with: dart run tool/jnigen.dart (needs a JDK 17-21).
/// - android.os.Build (VERSION.SDK_INT), FEAT-004-T02 proof;
/// - android.graphics.Bitmap and BitmapFactory (with Options), FEAT-002-T03
///   spike, kept for the decoder (FEAT-002-T12); BitmapRegionDecoder,
///   ColorSpace, Rect, ImageDecoder and media.ExifInterface for the T04 matrix.
Future<void> main() async {
  final root = Platform.script.resolve('../');
  await JniGenerator(
    input: Input(
      classes: [
        'android.graphics.Bitmap',
        'android.graphics.BitmapFactory',
        // FEAT-002-T04 decode matrix (ADR-004).
        'android.graphics.BitmapRegionDecoder',
        'android.graphics.ColorSpace',
        'android.graphics.Rect',
        'android.graphics.ImageDecoder',
        'android.media.ExifInterface',
      ],
      androidSdk: AndroidSdk(versions: [36], sdkRoot: _androidSdkRoot()),
    ),
    output: Output(
      dart: DartOutput(
        path: root.resolve('lib/src/android/android_graphics.g.dart'),
        structure: OutputStructure.singleFile,
      ),
    ),
  ).generate();
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
