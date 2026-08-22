#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
PYTHON="$(python_cmd "$ROOT")"
REPO="${1:-}"

if [ -z "$REPO" ] || [[ "$REPO" != */* ]]; then
  echo "Usage: $0 OWNER/REPOSITORY" >&2
  exit 2
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required." >&2
  exit 3
fi
gh auth status >/dev/null

cd "$ROOT"
if [ ! -d .git ]; then
  if git init -b main >/dev/null 2>&1; then :; else git init >/dev/null; git branch -M main; fi
fi

git config user.name >/dev/null 2>&1 || git config user.name "Ross Gates"
if ! git config user.email >/dev/null 2>&1; then
  echo "Git user.email is not configured."
  read -r -p "Git email for this repository: " git_email
  git config user.email "$git_email"
fi

"$PYTHON" scripts/check_sensitive_content.py --all-files
"$PYTHON" scripts/validate_repo.py

git add -A
"$PYTHON" scripts/check_sensitive_content.py --staged

if ! git diff --cached --quiet; then
  git commit -m "release: AI operating system v1.0.0"
fi

echo
echo "A PRIVATE GitHub repository will be created or connected: $REPO"
echo "Local source: $ROOT"
if ! ask_yes_no "Continue?"; then
  echo "Cancelled."
  exit 0
fi

if gh repo view "$REPO" >/dev/null 2>&1; then
  echo "Repository already exists."
  visibility="$(gh repo view "$REPO" --json visibility --jq .visibility)"
  if [ "$visibility" != "PRIVATE" ]; then
    echo "Refusing to push: existing repository is not private." >&2
    exit 4
  fi
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "https://github.com/$REPO.git"
  else
    git remote add origin "https://github.com/$REPO.git"
  fi
  git push -u origin main
else
  gh repo create "$REPO" --private --source=. --remote=origin --push
fi

echo "Private repository is ready. Next:"
echo "  ./scripts/setup-repo-deploy-key.sh $REPO macbook-pro"
