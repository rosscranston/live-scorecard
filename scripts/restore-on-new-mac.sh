#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
BUNDLE_DIR="${SCRIPT_DIR:h}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
RESTORE_DIR="$BUNDLE_DIR/restore-staging"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/codex-migration-backups/$STAMP"

if pgrep -x Codex >/dev/null 2>&1; then
  print -u2 "Quit Codex completely before restoring files."
  exit 1
fi

"$SCRIPT_DIR/decrypt-private-state.sh" "$RESTORE_DIR"

mkdir -p "$CODEX_DIR" "$BACKUP_DIR"
for item in sessions archived_sessions memories automations rules skills session_index.jsonl
do
  if [[ -e "$CODEX_DIR/$item" ]]; then
    cp -R "$CODEX_DIR/$item" "$BACKUP_DIR/"
  fi
done

mkdir -p "$CODEX_DIR/sessions" "$CODEX_DIR/archived_sessions" "$CODEX_DIR/memories" "$CODEX_DIR/automations" "$CODEX_DIR/rules" "$CODEX_DIR/skills"
rsync -a "$BUNDLE_DIR/codex-portable/skills/" "$CODEX_DIR/skills/"
rsync -a "$BUNDLE_DIR/codex-portable/automations/" "$CODEX_DIR/automations/"
cp "$BUNDLE_DIR/codex-portable/config/default.rules" "$CODEX_DIR/rules/default.rules"
rsync -a "$RESTORE_DIR/codex/sessions/" "$CODEX_DIR/sessions/"
rsync -a "$RESTORE_DIR/codex/archived_sessions/" "$CODEX_DIR/archived_sessions/"
rsync -a "$RESTORE_DIR/codex/memories/" "$CODEX_DIR/memories/"

if [[ -d "$RESTORE_DIR/codex/automation-memory" ]]; then
  for memory_dir in "$RESTORE_DIR/codex/automation-memory"/*
  do
    [[ -d "$memory_dir" ]] || continue
    task_id="${memory_dir:t}"
    mkdir -p "$CODEX_DIR/automations/$task_id"
    cp "$memory_dir/memory.md" "$CODEX_DIR/automations/$task_id/memory.md"
  done
fi

if command -v jq >/dev/null 2>&1 && [[ -f "$RESTORE_DIR/codex/session_index.jsonl" ]]; then
  INDEX_TMP="$CODEX_DIR/session_index.jsonl.migration-tmp"
  if [[ -f "$CODEX_DIR/session_index.jsonl" ]]; then
    jq -c -s 'group_by(.id) | map(max_by(.updated_at))[]' "$CODEX_DIR/session_index.jsonl" "$RESTORE_DIR/codex/session_index.jsonl" > "$INDEX_TMP"
  else
    cp "$RESTORE_DIR/codex/session_index.jsonl" "$INDEX_TMP"
  fi
  mv "$INDEX_TMP" "$CODEX_DIR/session_index.jsonl"
else
  print "jq is unavailable; the task index was not merged. The JSONL task files were restored."
fi

print "Portable Codex files restored."
print "Backup: $BACKUP_DIR"
print "Now reopen Codex, reauthenticate connectors, and verify/recreate each automation."

