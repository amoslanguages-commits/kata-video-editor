#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

printf '\n== Flutter analyze ==\n'
flutter analyze

printf '\n== Android debug build ==\n'
(cd android && ./gradlew assembleDebug)

printf '\n== Android instrumentation readiness ==\n'
if command -v adb >/dev/null 2>&1; then
  adb devices
else
  echo "adb is not installed; skipping device listing."
fi

cat <<'MSG'

Android export smoke checklist:
1. Install the debug APK on a real device.
2. Import one video with audio.
3. Export a simple single-clip timeline; verify MP4 has video + audio.
4. Add a text/image/overlay/transform clip; export again.
5. Verify output is not silent and progress reaches export_completed.
6. Check logcat for export_failed, MediaCodec, EGL, or MediaMuxer errors.

Useful logcat filter:
adb logcat | grep -Ei "nle|export|MediaCodec|MediaMuxer|EGL"
MSG
