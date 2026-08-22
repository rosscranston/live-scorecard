#!/usr/bin/env bash
set -euo pipefail
command -v hermes >/dev/null 2>&1 || { echo "Hermes is not installed." >&2; exit 2; }
for name in \
  "AI OS Daily Work Audit" \
  "AI OS Weekly Work Audit" \
  "AI OS Morning Brief" \
  "AI OS End-of-Day Review"; do
  if hermes cron list 2>/dev/null | grep -F "$name" >/dev/null 2>&1; then
    hermes cron remove "$name"
    echo "Removed: $name"
  fi
done
