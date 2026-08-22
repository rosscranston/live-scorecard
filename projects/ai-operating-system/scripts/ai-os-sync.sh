#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
PYTHON="$(python_cmd "$ROOT")"
DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

if [ "$(uname -s)" = "Darwin" ]; then
  LOG_DIR="$HOME/Library/Logs"
else
  LOG_DIR="$HOME/.local/state/ai-os"
fi
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/ai-operating-system-sync.log"
LOCK_DIR="$HOME/.local/state/ai-os/sync.lock"
mkdir -p "$(dirname "$LOCK_DIR")"

log() {
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG"
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "Another sync is active; exiting."
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

cd "$ROOT"
if [ ! -d .git ]; then
  log "Not a Git repository. Run create/clone setup first."
  exit 2
fi
if [ "$(git branch --show-current)" != "main" ]; then
  log "Automatic sync only runs on main."
  exit 3
fi
if ! git remote get-url origin >/dev/null 2>&1; then
  log "Remote origin is not configured."
  exit 4
fi
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ] || [ -f .git/MERGE_HEAD ]; then
  log "A merge or rebase is in progress; human resolution required."
  exit 5
fi

if $DRY_RUN; then
  echo "Repository: $ROOT"
  echo "Remote: $(git remote get-url origin)"
  echo "Branch: $(git branch --show-current)"
  echo "Working-tree classification:"
  policy_rc=0
  "$PYTHON" scripts/sync_policy.py || policy_rc=$?
  if [ "$policy_rc" -ne 0 ]; then
    echo "Dry run stopped by policy (code $policy_rc)."
    exit "$policy_rc"
  fi
  "$PYTHON" scripts/check_sensitive_content.py --all-files
  "$PYTHON" scripts/validate_repo.py
  echo "Dry run passed. No fetch, commit, rebase, or push was performed."
  exit 0
fi

# Validate the current local tree before any automatic commit.
"$PYTHON" scripts/check_sensitive_content.py --all-files >>"$LOG" 2>&1 || { log "Sensitive-content scan failed; sync stopped."; exit 30; }
"$PYTHON" scripts/validate_repo.py >>"$LOG" 2>&1 || { log "Repository validation failed; sync stopped."; exit 31; }

if [ -n "$(git status --porcelain=v1 --untracked-files=all)" ]; then
  policy_rc=0
  "$PYTHON" scripts/sync_policy.py >>"$LOG" 2>&1 || policy_rc=$?
  case "$policy_rc" in
    0) ;;
    10) log "Unclassified changes require manual review; sync stopped."; exit 10 ;;
    20) log "Protected production changes require approve-and-sync.sh; sync stopped."; exit 20 ;;
    30) log "Forbidden files detected; sync stopped."; exit 30 ;;
    *) log "Sync policy failed with code $policy_rc."; exit "$policy_rc" ;;
  esac
  git add -A
  "$PYTHON" scripts/check_sensitive_content.py --staged >>"$LOG" 2>&1 || { git reset >/dev/null; log "Staged scan failed; sync stopped."; exit 32; }
  if ! git diff --cached --quiet; then
    machine="$(hostname -s 2>/dev/null || hostname)"
    git commit -m "auto(sync): sanitized learning updates from $machine" >>"$LOG" 2>&1
    log "Committed allowed local learning changes."
  fi
fi

if ! git fetch origin main >>"$LOG" 2>&1; then
  log "Git fetch failed. Check network and deploy-key access."
  exit 40
fi

read -r ahead behind <<<"$(git rev-list --left-right --count HEAD...origin/main)"
if [ "$behind" -gt 0 ]; then
  if [ "$ahead" -eq 0 ]; then
    git merge --ff-only origin/main >>"$LOG" 2>&1 || { log "Fast-forward failed; human review required."; exit 41; }
    log "Fast-forwarded to origin/main."
  else
    if git rebase origin/main >>"$LOG" 2>&1; then
      log "Rebased local commits onto origin/main."
    else
      git rebase --abort >>"$LOG" 2>&1 || true
      log "Rebase conflict detected and aborted; human resolution required."
      exit 42
    fi
  fi
fi

if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
  if git push origin main >>"$LOG" 2>&1; then
    log "Pushed main successfully."
  else
    log "Push failed without force. Another machine may have updated the branch; next run will retry safely."
    exit 43
  fi
else
  log "Already synchronized."
fi
