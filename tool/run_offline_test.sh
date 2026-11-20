#!/usr/bin/env bash
# FEAT-004-T25 / AC-6.2: turn the emulator's networking off, run the offline
# test, then turn it back on. Usage: bash tool/run_offline_test.sh [device-id]
set -u
dev=${1:-}
adbs() { if [ -n "$dev" ]; then adb -s "$dev" shell "$@"; else adb shell "$@"; fi; }
network() {
  adbs svc wifi "$1" || true
  adbs svc data "$1" || true
}
network disable
adbs cmd connectivity airplane-mode enable 2>/dev/null || adbs settings put global airplane_mode_on 1 || true
sleep 5
flutter test integration_test/offline_test.dart --dart-define=OFFLINE=true ${dev:+-d "$dev"}
status=$?
adbs cmd connectivity airplane-mode disable 2>/dev/null || adbs settings put global airplane_mode_on 0 || true
network enable
exit $status
