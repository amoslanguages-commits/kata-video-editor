#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter analyze
flutter test test/domain/timeline

echo "Cache index smoke checklist:"
echo "1. Import a video and generate a proxy."
echo "2. Verify project cache_index.json contains a proxy entry."
echo "3. Delete proxy via cleanup policy and verify asset.proxyPath clears."
echo "4. Verify original media paths are never deleted."
