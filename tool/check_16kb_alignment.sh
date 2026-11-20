#!/usr/bin/env bash
# FEAT-004-T05: Google Play 16 KB page-size check, as in
# https://developer.android.com/guide/practices/page-sizes
#  - `zipalign -c -P 16 -v 4` must pass for the APK;
#  - every .so for the 64-bit ABIs (arm64-v8a, x86_64) must have ELF LOAD alignment >= 2**14.
#  32-bit armeabi-v7a libraries are listed for information (the requirement covers 64-bit only).
# Usage: check_16kb_alignment.sh APK...   Needs unzip, readelf (or READELF) and zipalign (or ZIPALIGN).
set -euo pipefail
READELF="${READELF:-readelf}"
if [ -z "${ZIPALIGN:-}" ]; then
  sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
  ZIPALIGN="$(ls -d "$sdk"/build-tools/*/zipalign* 2>/dev/null | sort -V | tail -1)"
fi
fail=0
for apk in "$@"; do
  echo "== $apk"
  if "$ZIPALIGN" -c -P 16 -v 4 "$apk" > /dev/null; then echo "OK: zipalign -P 16"; else echo "FAIL: zipalign -P 16"; fail=1; fi
  tmp="$(mktemp -d)"
  unzip -q -o "$apk" -d "$tmp" # whole APK: wildcard lists fail in Git Bash unzip
  for so in "$tmp"/lib/*/*.so; do
    abi="$(basename "$(dirname "$so")")"
    min_align=""
    for a in $("$READELF" -lW "$so" | awk '$1=="LOAD"{print $NF}'); do
      if [ -z "$min_align" ] || [ $((a)) -lt $((min_align)) ]; then min_align="$a"; fi
    done
    name="$abi/$(basename "$so")"
    if [ $((min_align)) -ge 16384 ]; then
      echo "OK:   $name LOAD align $min_align"
    elif [ "$abi" = "armeabi-v7a" ]; then
      echo "INFO: $name LOAD align $min_align (32-bit, not required)"
    else
      echo "FAIL: $name LOAD align $min_align < 0x4000"; fail=1
    fi
  done
  rm -rf "$tmp"
done
exit $fail
