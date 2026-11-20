// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'package:es_codec/src/c_library.dart';
import 'package:es_codec/src/es_probe.record_use_mapping.g.dart' as probe;
import 'package:es_codec/src/turbojpeg.record_use_mapping.g.dart' as tj;
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:record_use/record_use.dart';

/// Keeps only the C symbols the app calls (record_use); drops the rest.
void main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    await cLibrary.link(
      input: input,
      output: output,
      linkerOptions: LinkerOptions.treeshake(
        symbolsToKeep: input.recordedUses?.calls.keys.cast<Method>().map(
          (e) => _mapping[e.name]!,
        ),
      ),
    );
  });
}

const _mapping = {...probe.recordUseMapping, ...tj.recordUseMapping};
