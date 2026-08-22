#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

"$ROOT/scripts/bootstrap-ubuntu.sh"
"$ROOT/scripts/install-local-skills.sh"
"$(python_cmd "$ROOT")" "$ROOT/scripts/configure-hermes.py" --apply

if command -v hermes >/dev/null 2>&1; then
  echo "Hermes must have a model provider configured before unattended jobs."
  if ask_yes_no "Run hermes setup --portal now?"; then
    hermes setup --portal
  fi
  hermes gateway install
  if command -v loginctl >/dev/null 2>&1; then
    echo "For jobs to run after logout, enable user linger: sudo loginctl enable-linger $USER"
  fi
  "$ROOT/scripts/install-hermes-cron.sh"
fi

"$ROOT/scripts/install-auto-sync-ubuntu.sh"
"$ROOT/scripts/doctor.sh"
echo
echo "Ubuntu/Hermes installation complete. Review cron jobs manually before relying on unattended writes."
