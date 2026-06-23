#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter analyze

echo "Export edge-case QA checklist:"
echo "1. Missing original and missing proxy: preflight fails before native export."
echo "2. Missing proxy but original exists: export falls back to original or reports policy clearly."
echo "3. Missing original but proxy exists: proxy-preferred export succeeds when policy allows."
echo "4. Empty native output: job becomes failed, not completed."
echo "5. Native failure after partial output: partial output is deleted."
echo "6. Cancelled export: partial output is deleted and status is cancelled."
echo "7. Retry failed export: creates a new job with fresh output path and stored settings."
echo "8. Retry cancelled export: creates a new job with fresh output path and stored settings."
echo "9. Stale active export recovery: old running or paused job becomes failed."
echo "10. Completed export remains untouched by cleanup and recovery."
