#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter analyze
flutter test test/domain/timeline

bash scripts/cache_index_smoke.sh
bash scripts/proxy_smoke_android.sh
bash scripts/export_smoke_android.sh

if command -v xcodebuild >/dev/null 2>&1; then
  bash scripts/proxy_smoke_ios.sh
  bash scripts/export_smoke_ios.sh
else
  echo "xcodebuild not found; skipping iOS smoke scripts on this machine."
fi

echo "Production export smoke checklist:"
echo "1. Start export with a valid timeline and verify preflight is stored in ExportJobs.settings."
echo "2. Start export with missing media and verify job status becomes failed before native render starts."
echo "3. Complete native export and verify output file exists and is non-empty before status=completed."
echo "4. Force native completed event with missing output and verify status=failed."
echo "5. Run the same export on iOS real device with single clip, overlays, proxy path, and original path modes."
