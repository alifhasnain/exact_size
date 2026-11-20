#!/usr/bin/env bash
# FEAT-004-T02 / gate G0: proves record_use tree shaking of native code.
#  1. The main app does not call es_codec, so its release APK must not contain libes_codec.so.
#  2. A probe app calls es_probe_add only, so its libes_codec.so must export es_probe_add
#     and must not export es_probe_unused.
# Needs: flutter on PATH, unzip, and readelf (or set READELF, e.g. the NDK's llvm-readelf).
set -euo pipefail
READELF="${READELF:-readelf}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

flutter build apk --release --target-platform android-arm64
if unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -q 'libes_codec.so'; then
  echo "FAIL: main app bundles libes_codec.so although it calls no es_codec symbol"; exit 1
fi
echo "OK: main app release APK has no libes_codec.so"

flutter build apk --release --target-platform android-arm64 -t integration_test/interop_probe_app.dart
unzip -q -o build/app/outputs/flutter-apk/app-release.apk 'lib/arm64-v8a/libes_codec.so' -d "$tmp"
syms="$("$READELF" -W --dyn-syms "$tmp/lib/arm64-v8a/libes_codec.so")"
echo "$syms" | grep -q ' es_probe_add$' || { echo "FAIL: es_probe_add missing"; exit 1; }
if echo "$syms" | grep -q ' es_probe_unused$'; then
  echo "FAIL: es_probe_unused was not tree-shaken"; exit 1
fi
echo "OK: probe libes_codec.so keeps es_probe_add and drops es_probe_unused"
