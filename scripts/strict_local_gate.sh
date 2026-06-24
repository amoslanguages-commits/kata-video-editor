#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

printf '\n== Strict local production gate ==\n'

flutter --version
flutter pub get

echo "\n[1/7] Dart format check"
dart format --set-exit-if-changed lib test

echo "\n[2/7] Flutter analyzer"
flutter analyze

echo "\n[3/7] Flutter tests"
flutter test

echo "\n[4/7] Android debug build"
flutter build apk --debug

echo "\n[5/7] Cache/proxy/export smoke"
bash scripts/export_production_smoke.sh

echo "\n[6/7] Edge-case checklist smoke"
bash scripts/export_edge_case_qa.sh

if [[ "${RUN_DEVICE_QA:-0}" == "1" ]]; then
  echo "\n[7/7] Device QA scripts"
  bash scripts/android_device_export_qa.sh
  if command -v xcodebuild >/dev/null 2>&1; then
    bash scripts/ios_device_export_qa.sh
  else
    echo "xcodebuild not found; skipping iOS device QA on this machine."
  fi
else
  echo "\n[7/7] Device QA skipped. Set RUN_DEVICE_QA=1 to require device checks."
fi

echo "\nStrict local production gate completed."
