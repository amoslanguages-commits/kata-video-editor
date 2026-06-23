#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/build/qa_logs/ios_export"
mkdir -p "$LOG_DIR"
cd "$ROOT_DIR"

flutter analyze

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Run this script on macOS with Xcode installed."
  exit 1
fi

(cd ios && pod install)
(cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build | tee "$LOG_DIR/xcodebuild_simulator.log")

echo "For real device QA, open ios/Runner.xcworkspace in Xcode, select a connected iPhone, and run."
echo "Save Xcode device logs to: $LOG_DIR/device_console.log"
echo ""
echo "iOS device export QA cases:"
echo "1. Single clip export, original media mode."
echo "2. Single clip export, proxy media mode."
echo "3. Multiple video clips with audio mix."
echo "4. Text and image overlay export."
echo "5. Volume and fade export through AVAudioMix."
echo "6. Missing media preflight."
echo "7. Empty output verification."
echo "8. Cancel and retry export."
echo "9. App restart with a stale running export job."
