#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
failures=0
warnings=0

ok() { echo "PASS: $*"; }
warn() { echo "WARN: $*"; warnings=$((warnings + 1)); }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

for cmd in git python3 ssh; do
  command -v "$cmd" >/dev/null 2>&1 && ok "$cmd available" || fail "$cmd missing"
done
command -v gh >/dev/null 2>&1 && ok "GitHub CLI available" || warn "GitHub CLI missing; repository administration scripts will not work"
command -v codex >/dev/null 2>&1 && ok "Codex available" || warn "Codex not installed on this machine"
command -v hermes >/dev/null 2>&1 && ok "Hermes available" || warn "Hermes not installed on this machine"

PYTHON="$(python_cmd "$ROOT" 2>/dev/null || true)"
if [ -n "$PYTHON" ]; then
  "$PYTHON" "$ROOT/scripts/validate_repo.py" && ok "repository validation" || fail "repository validation"
  "$PYTHON" "$ROOT/scripts/check_sensitive_content.py" --all-files && ok "sensitive-content scan" || fail "sensitive-content scan"
else
  fail "no usable Python interpreter"
fi

if [ -d "$ROOT/.git" ]; then
  ok "Git repository initialized"
  if git -C "$ROOT" remote get-url origin >/dev/null 2>&1; then
    ok "Git remote origin: $(git -C "$ROOT" remote get-url origin)"
  else
    warn "Git remote origin is not configured"
  fi
  [ "$(git -C "$ROOT" branch --show-current)" = "main" ] && ok "on main branch" || warn "not on main branch"
else
  warn "Git repository is not initialized yet"
fi

installed=0
for skill in "$ROOT"/skills/*; do
  [ -f "$skill/SKILL.md" ] || continue
  name="$(basename "$skill")"
  dest="$HOME/.agents/skills/$name"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$skill" ]; then
    installed=$((installed + 1))
  fi
done
[ "$installed" -eq 12 ] && ok "all 12 local skill symlinks installed" || warn "$installed/12 local skill symlinks installed"

if command -v hermes >/dev/null 2>&1; then
  "$PYTHON" "$ROOT/scripts/configure-hermes.py" --check >/dev/null 2>&1 && ok "Hermes external skills and write approval configured" || warn "Hermes external skills/write approval not fully configured"
  hermes cron status >/dev/null 2>&1 && ok "Hermes cron responds" || warn "Hermes cron/gateway not ready"
fi

echo
echo "Doctor complete: $failures failure(s), $warnings warning(s)."
[ "$failures" -eq 0 ]
