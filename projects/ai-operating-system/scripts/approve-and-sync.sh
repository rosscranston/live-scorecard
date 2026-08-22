#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
PYTHON="$(python_cmd "$ROOT")"
APPROVAL_FILE="${1:-}"

if [ -z "$APPROVAL_FILE" ] || [ ! -f "$APPROVAL_FILE" ]; then
  echo "Usage: $0 path/to/approved-proposal.md" >&2
  exit 2
fi
if ! grep -Eiq '(status|decision)[[:space:]]*:[[:space:]]*approved|\[[xX]\][[:space:]]*approved' "$APPROVAL_FILE"; then
  echo "The supplied file does not contain an explicit Approved status/decision." >&2
  exit 3
fi

cd "$ROOT"
"$PYTHON" scripts/check_sensitive_content.py --all-files
"$PYTHON" scripts/validate_repo.py

echo "Approval record: $APPROVAL_FILE"
echo "Approval SHA-256: $(sha256_file "$APPROVAL_FILE")"
echo
git status --short
git diff -- "$APPROVAL_FILE" || true
echo
if ! ask_yes_no "Commit all current reviewed changes and synchronize them?"; then
  echo "Cancelled."
  exit 0
fi

mkdir -p decisions/approvals
stamp="$(date +%Y%m%d-%H%M%S)"
base="$(basename "$APPROVAL_FILE" .md | tr ' ' '-' | tr -cd '[:alnum:]_.-')"
record="decisions/approvals/${stamp}-${base}.md"
{
  echo "# Applied Approval Record"
  echo
  echo "- **Applied at:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- **Source:** $APPROVAL_FILE"
  echo "- **Source SHA-256:** $(sha256_file "$APPROVAL_FILE")"
  echo "- **Applied by:** ${USER:-unknown} on $(hostname -s 2>/dev/null || hostname)"
  echo
  cat "$APPROVAL_FILE"
} > "$record"

git add -A
"$PYTHON" scripts/check_sensitive_content.py --staged
"$PYTHON" scripts/validate_repo.py
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "approved: apply ${base}"
fi
exec "$ROOT/scripts/ai-os-sync.sh"
