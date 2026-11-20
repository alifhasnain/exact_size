// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Pinned checksums of the vendored trees, by directory relative to the
/// package root (VENDOR.md in each is ours and excluded):
/// - libjpeg-turbo 3.2.1 (ADR-002, FEAT-004-T05);
/// - stb_image_resize2 2.51 (ADR-005, FEAT-002-T01).
///
/// Update only together with a deliberate upgrade: after replacing the files,
/// any build fails and its error prints the new value. Paste it here, update
/// that directory's VENDOR.md and refresh the goldens.
const pinnedVendorChecksums = {
  'third_party/libjpeg-turbo': '0657711012ae542192c73d11a213f083fc1ab5f01eee6d9838f98994242b9db3',
  'third_party/stb': '2a3e23579d502ba7f85215b9683fbadafd3f2dee07abb5fe6e55ed80e77177d8',
};

/// SHA-256 over every vendored file: for each file in sorted path order,
/// `<relative path>\n<sha256 of content>\n`, then SHA-256 of that text.
/// Line endings are normalised to LF first, so Windows and Linux checkouts agree.
String vendoredTreeChecksum(Uri packageRoot, String dir) {
  final root = Directory.fromUri(packageRoot.resolve('$dir/'));
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

/// Throws if any vendored tree differs from [pinnedVendorChecksums].
void verifyVendoredSource(Uri packageRoot) {
  for (final MapEntry(key: dir, value: pinned) in pinnedVendorChecksums.entries) {
    final actual = vendoredTreeChecksum(packageRoot, dir);
    if (actual != pinned) {
      throw StateError(
        'Vendored source in $dir differs from the pinned version '
        '(expected $pinned, got $actual). '
        'Restore the files or follow the upgrade steps in $dir/VENDOR.md.',
      );
    }
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
