#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter analyze
flutter test test/domain/timeline

bash scripts/cache_index_smoke.sh
bash scripts/proxy_smoke_android.sh
bash scripts/export_smoke_android.sh
bash scripts/audio_mixdown_export_smoke.sh
bash scripts/export_edge_case_qa.sh

if command -v xcodebuild >/dev/null 2>&1; then
  bash scripts/proxy_smoke_ios.sh
  bash scripts/export_smoke_ios.sh
else
  echo "xcodebuild not found; skipping iOS smoke scripts on this machine."
fi

echo "Production export smoke checklist:"
echo "1. Verify preflight data is stored in ExportJobs.settings."
echo "2. Verify missing media fails before native rendering."
echo "3. Verify completed exports have a real non-empty output file."
echo "4. Verify invalid native completion becomes failed."
echo "5. Verify audio mix, proxy mode, original mode, and retry cases."
