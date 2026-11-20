// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'package:code_assets/code_assets.dart';
import 'package:es_codec/src/c_library.dart';
import 'package:es_codec/src/vendor_checksum.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    // Fail the build if the vendored libjpeg-turbo was changed (ADR-002 pinning).
    verifyVendoredSource(input.packageRoot);
    await codecLibrary(input.config.code.targetOS).build(
      input: input,
      output: output,
    );
  });
}
