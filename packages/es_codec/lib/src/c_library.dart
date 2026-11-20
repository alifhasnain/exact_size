// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Build spec shared by hook/build.dart and hook/link.dart (ADR-001, ADR-002).
final cLibrary = CLibrary(
  name: 'es_codec',
  assetName: 'src/es_probe.g.dart',
  sources: ['src/es_probe.c'],
  includes: ['src'],
);
