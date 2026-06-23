#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter analyze
(cd android && ./gradlew assembleDebug)

echo "Android proxy smoke: import a video, request proxy, verify proxy_started/proxy_progress/proxy_completed and asset.proxyStatus=ready."
echo "Log filter: adb logcat | grep -Ei 'nle|proxy|MediaCodec|MediaMuxer'"
