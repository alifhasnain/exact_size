#!/usr/bin/env bash
# FEAT-004 gate G0 / T05: proves record_use tree shaking of native code.
#  1. The main app does not call es_codec yet, so its release APK must not contain libes_codec.so.
#  2. A probe app uses only the JPEG encode path, so its libes_codec.so must export tj3Compress8
#     and must not export tj3Get (bound but unused) or tj3Decompress8 (never bound).
# Leaves the probe APK (arm, arm64, x64) at build/probe-release.apk for check_16kb_alignment.sh.
# Needs: flutter on PATH, unzip, and readelf (or set READELF, e.g. the NDK's llvm-readelf).
set -euo pipefail
READELF="${READELF:-readelf}"
apk=build/app/outputs/flutter-apk/app-release.apk
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

flutter build apk --release --target-platform android-arm64
if unzip -l "$apk" | grep -q 'libes_codec.so'; then
  echo "FAIL: main app bundles libes_codec.so although it calls no es_codec symbol"; exit 1
fi
echo "OK: main app release APK has no libes_codec.so"

flutter build apk --release --target-platform android-arm,android-arm64,android-x64 \
  -t integration_test/interop_probe_app.dart
cp "$apk" build/probe-release.apk
unzip -q -o "$apk" 'lib/arm64-v8a/libes_codec.so' -d "$tmp"
syms="$("$READELF" -W --dyn-syms "$tmp/lib/arm64-v8a/libes_codec.so")"
echo "$syms" | grep -q ' tj3Compress8$' || { echo "FAIL: tj3Compress8 missing"; exit 1; }
for unused in tj3Get tj3Decompress8; do
  if echo "$syms" | grep -q " $unused\$"; then
    echo "FAIL: $unused was not tree-shaken"; exit 1
  fi
done
echo "OK: probe libes_codec.so keeps tj3Compress8 and drops tj3Get, tj3Decompress8"
