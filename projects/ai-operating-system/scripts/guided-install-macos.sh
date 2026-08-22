#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

"$ROOT/scripts/bootstrap-macos.sh"
echo
read -r -p "Private GitHub repository as OWNER/REPO [example: ross/ai-operating-system]: " repo
[ -n "$repo" ] || { echo "Repository is required." >&2; exit 2; }
"$ROOT/scripts/create-private-github-repo.sh" "$repo"
"$ROOT/scripts/setup-repo-deploy-key.sh" "$repo" "macbook-pro"
"$ROOT/scripts/install-local-skills.sh"
"$ROOT/scripts/install-auto-sync-macos.sh"
"$(python_cmd "$ROOT")" "$ROOT/scripts/package_skills.py"
"$ROOT/scripts/doctor.sh"
echo
echo "Mac installation complete. Follow CHATGPT_WEB_INSTALL.md, then configure Ubuntu."
