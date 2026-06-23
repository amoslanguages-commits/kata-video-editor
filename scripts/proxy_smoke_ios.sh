#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter analyze
(cd ios && pod install)
(cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build)

echo "iOS proxy smoke: run on real device, import a video, request proxy, verify proxy_completed and asset.proxyPath is set."
