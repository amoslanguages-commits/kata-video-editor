#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter analyze
(cd android && ./gradlew assembleDebug)

if command -v xcodebuild >/dev/null 2>&1; then
  (cd ios && pod install)
  (cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build)
else
  echo "xcodebuild not found; skipping iOS build smoke on this machine."
fi

echo "Audio mixdown QA checklist:"
echo "1. Export two overlapping audio clips and verify both are heard in the final file."
echo "2. Export a muted audio track and verify it is not heard."
echo "3. Export a solo audio track and verify only the solo track is heard."
echo "4. Export fade-in and fade-out clips and verify the ramps are heard."
echo "5. Export different clip volume levels and verify levels change as expected."
echo "6. Export proxy-preferred and original-preferred projects and verify source policy."
echo "7. Cancel during audio processing and verify partial output cleanup."
