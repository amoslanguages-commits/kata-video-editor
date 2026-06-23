#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/build/qa_logs/android_export"
mkdir -p "$LOG_DIR"
cd "$ROOT_DIR"

flutter analyze
(cd android && ./gradlew assembleDebug)

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Install Android platform tools to run device QA."
  exit 1
fi

adb devices | tee "$LOG_DIR/adb_devices.txt"
DEVICE_COUNT="$(adb devices | awk 'NR>1 && $2=="device" {count++} END {print count+0}')"
if [ "$DEVICE_COUNT" -lt 1 ]; then
  echo "No Android device is connected and authorized."
  exit 1
fi

adb logcat -c || true

echo "Install and open the debug build, then run the checklist in the app."
echo "Optional manual command: flutter install"
echo "Log capture command after export: adb logcat -d | grep -Ei 'nle|export|proxy|muxer|codec|MediaCodec|MediaMuxer' > $LOG_DIR/export_logcat.txt"
echo ""
echo "Android device export QA cases:"
echo "1. Single clip export, original media mode."
echo "2. Single clip export, proxy media mode."
echo "3. Multiple video clips with one audio track."
echo "4. Overlapping audio clips with volume and fades."
echo "5. Text or image overlay export."
echo "6. Missing media preflight."
echo "7. Empty output verification."
echo "8. Cancel and retry export."
echo "9. App restart with a stale running export job."
