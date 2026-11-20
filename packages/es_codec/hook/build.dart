// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:es_codec/src/c_library.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.config.buildCodeAssets) {
      await cLibrary.build(
        input: input,
        output: output,
        // Windows host builds (flutter test): export TurboJPEG API from the DLL.
        defines: {
          if (input.config.code.targetOS == OS.windows) 'DLLDEFINE': null,
        },
      );
    }
  });
}
