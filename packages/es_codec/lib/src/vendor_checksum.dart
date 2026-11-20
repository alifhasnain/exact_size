// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Pinned checksum of the vendored libjpeg-turbo 3.2.1 tree (ADR-002, FEAT-004-T05).
///
/// Update only together with a deliberate libjpeg-turbo upgrade: after
/// replacing the files, any build fails and its error prints the new value.
/// Paste it here, update VENDOR.md and refresh the goldens.
const pinnedLibjpegTurboChecksum =
    '0657711012ae542192c73d11a213f083fc1ab5f01eee6d9838f98994242b9db3';

/// Directory checked, relative to the package root. VENDOR.md is ours and excluded.
const vendoredLibjpegTurboDir = 'third_party/libjpeg-turbo';

/// SHA-256 over every vendored file: for each file in sorted path order,
/// `<relative path>\n<sha256 of content>\n`, then SHA-256 of that text.
/// Line endings are normalised to LF first, so Windows and Linux checkouts agree.
String vendoredTreeChecksum(Uri packageRoot) {
  final root = Directory.fromUri(packageRoot.resolve('$vendoredLibjpegTurboDir/'));
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => (
            rel: f.uri.path.substring(root.uri.path.length),
            file: f,
          ))
      .where((e) => e.rel != 'VENDOR.md')
      .toList()
    ..sort((a, b) => a.rel.compareTo(b.rel));
  final manifest = StringBuffer();
  for (final e in files) {
    final bytes = _normaliseLineEndings(e.file.readAsBytesSync());
    manifest
      ..write(e.rel)
      ..write('\n')
      ..write(sha256.convert(bytes))
      ..write('\n');
  }
  return sha256.convert(utf8.encode(manifest.toString())).toString();
}

/// Throws if the vendored tree differs from [pinnedLibjpegTurboChecksum].
void verifyVendoredSource(Uri packageRoot) {
  final actual = vendoredTreeChecksum(packageRoot);
  if (actual != pinnedLibjpegTurboChecksum) {
    throw StateError(
      'Vendored libjpeg-turbo differs from the pinned version '
      '(expected $pinnedLibjpegTurboChecksum, got $actual). '
      'Restore the files or follow the upgrade steps in '
      '$vendoredLibjpegTurboDir/VENDOR.md.',
    );
  }
}

List<int> _normaliseLineEndings(List<int> bytes) {
  final out = <int>[];
  for (var i = 0; i < bytes.length; i++) {
    if (bytes[i] == 0x0D && i + 1 < bytes.length && bytes[i + 1] == 0x0A) {
      continue; // CRLF -> LF
    }
    out.add(bytes[i]);
  }
  return out;
}
