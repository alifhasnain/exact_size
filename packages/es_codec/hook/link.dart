// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'package:code_assets/code_assets.dart';
import 'package:es_codec/src/c_library.dart';
import 'package:es_codec/src/turbojpeg.record_use_mapping.g.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:record_use/record_use.dart';

/// Keeps only the C symbols the app calls (record_use); drops the rest.
void main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    final targetOS = input.config.code.targetOS;
    await codecLibrary(targetOS).link(
      input: input,
      output: output,
      linkerOptions: LinkerOptions.treeshake(
        flags: linkFlags(targetOS),
        symbolsToKeep: input.recordedUses?.calls.keys.cast<Method>().map(
          (e) => recordUseMapping[e.name]!,
        ),
      ),
    );
  });
}
