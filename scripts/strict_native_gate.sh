#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

printf '\n== Strict native gate ==\n'

flutter pub get

echo "\n[1/4] Android debug build"
flutter build apk --debug

echo "\n[2/4] Android Gradle assembleDebug"
(cd android && ./gradlew assembleDebug)

if command -v xcodebuild >/dev/null 2>&1; then
  echo "\n[3/4] iOS pods"
  (cd ios && pod install)

  echo "\n[4/4] iOS simulator build"
  flutter build ios --simulator --debug --no-codesign
else
  echo "\n[3/4] xcodebuild not found; skipping iOS native gate."
  echo "[4/4] Run this script on macOS with Xcode before iOS release."
fi

echo "\nStrict native gate completed."
