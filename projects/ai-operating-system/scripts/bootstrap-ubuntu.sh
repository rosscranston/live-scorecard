#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

echo "AI Operating System — Ubuntu/Hermes bootstrap"
echo "Repository: $ROOT"

if [ "$(uname -s)" != "Linux" ]; then
  echo "This script is for Linux/Ubuntu." >&2
  exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
  missing=()
  for cmd in git curl xz python3 jq ssh; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing base tools: ${missing[*]}"
    if ask_yes_no "Install Ubuntu prerequisites with sudo apt?" yes; then
      sudo apt-get update
      sudo apt-get install -y git curl xz-utils ca-certificates openssh-client python3 python3-venv python3-pip jq
    else
      echo "Install the missing tools and rerun." >&2
      exit 2
    fi
  fi
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is not installed. It is optional after deploy-key registration."
  if command -v apt-get >/dev/null 2>&1 && ask_yes_no "Try installing gh with apt?"; then
    sudo apt-get update
    sudo apt-get install -y gh || true
  fi
fi

if ! command -v hermes >/dev/null 2>&1; then
  echo "Hermes is not installed. Proposed official installer:"
  echo 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash'
  if ask_yes_no "Install Hermes now?"; then
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    export PATH="$HOME/.local/bin:$PATH"
  else
    echo "Hermes installation skipped."
  fi
fi

python3 -m venv "$ROOT/.venv"
"$ROOT/.venv/bin/python" -m pip install --upgrade pip
"$ROOT/.venv/bin/python" -m pip install -r "$ROOT/requirements.txt"

mkdir -p "$HOME/.config/ai-operating-system" "$HOME/.local/state/ai-os" "$HOME/.agents/skills"
if [ ! -f "$HOME/.config/ai-operating-system/connectors.yaml" ]; then
  cp "$ROOT/config/connectors.example.yaml" "$HOME/.config/ai-operating-system/connectors.yaml"
  chmod 600 "$HOME/.config/ai-operating-system/connectors.yaml"
fi

"$ROOT/.venv/bin/python" "$ROOT/scripts/validate_repo.py"
echo
echo "Bootstrap complete. Next steps:"
echo "  hermes setup --portal   # or configure another provider"
echo "  ./scripts/install-local-skills.sh"
echo "  python3 scripts/configure-hermes.py --apply"
