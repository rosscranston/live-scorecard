#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

command -v hermes >/dev/null 2>&1 || { echo "Hermes is not installed or not on PATH." >&2; exit 2; }

current_tz=""
if command -v timedatectl >/dev/null 2>&1; then
  current_tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
fi
if [ -n "$current_tz" ] && [ "$current_tz" != "America/Los_Angeles" ]; then
  echo "WARNING: Hermes cron expressions use the machine's local scheduling time."
  echo "Current timezone: $current_tz; required business timezone: America/Los_Angeles"
  echo "Recommended: sudo timedatectl set-timezone America/Los_Angeles"
  if ! ask_yes_no "Continue despite the timezone mismatch?"; then
    exit 3
  fi
fi

model_args=()
if [ -n "${HERMES_CRON_MODEL:-}" ] && [ -n "${HERMES_CRON_PROVIDER:-}" ]; then
  model_args=(--provider "$HERMES_CRON_PROVIDER" --model "$HERMES_CRON_MODEL")
else
  echo "NOTE: No HERMES_CRON_PROVIDER/HERMES_CRON_MODEL is set."
  echo "For stable unattended model routing, set cron.model in Hermes config or export both variables before running this installer."
fi

list_output="$(hermes cron list 2>/dev/null || true)"

upsert_job() {
  local name="$1" schedule="$2" skill="$3" prompt_file="$4"
  local prompt
  prompt="$(cat "$prompt_file")"
  if printf '%s\n' "$list_output" | grep -F "$name" >/dev/null 2>&1; then
    echo "Updating: $name"
    hermes cron edit "$name" \
      --schedule "$schedule" \
      --prompt "$prompt" \
      --skill "$skill" \
      --workdir "$ROOT" \
      --deliver local \
      "${model_args[@]}"
  else
    echo "Creating: $name"
    hermes cron create "$schedule" "$prompt" \
      --skill "$skill" \
      --name "$name" \
      --workdir "$ROOT" \
      --deliver local \
      "${model_args[@]}"
  fi
}

upsert_job "AI OS Daily Work Audit" "0 0 * * *" "work-auditor" "$ROOT/hermes/prompts/daily-work-audit.md"
upsert_job "AI OS Weekly Work Audit" "0 0 * * 5" "work-auditor" "$ROOT/hermes/prompts/weekly-work-audit.md"
upsert_job "AI OS Morning Brief" "0 6 * * *" "day-operator" "$ROOT/hermes/prompts/morning-brief.md"
upsert_job "AI OS End-of-Day Review" "0 18 * * *" "day-operator" "$ROOT/hermes/prompts/end-of-day-review.md"

echo
hermes cron list
echo
echo "Install/start the scheduler gateway if needed: hermes gateway install"
echo "Then verify: hermes cron status"
