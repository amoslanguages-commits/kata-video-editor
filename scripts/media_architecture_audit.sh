#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Canonical media architecture audit"
echo ""

echo "Checking render graph path contract..."
grep -R "resolvedPath" lib/domain/rendering lib/domain/media android/app/src/main/kotlin/com/nle/editor/rendergraph >/dev/null

echo "Checking canonical media docs..."
test -f docs/CANONICAL_MEDIA_ASSET_LIFECYCLE.md

echo "Checking for temporary architecture wording..."
if grep -R "Temporary Flutter-side render/export/proxy layer\|Later replace" pubspec.yaml lib docs android ios >/dev/null 2>&1; then
  echo "Temporary architecture wording found. Remove it before release."
  exit 1
fi

echo "Checking for duplicate canonical repository names..."
if find lib -name '*canonical_media_asset_repository.dart' | grep -q .; then
  echo "Duplicate canonical media repository file found. Use MediaAssetRepository only."
  exit 1
fi

echo "Media architecture audit passed."
