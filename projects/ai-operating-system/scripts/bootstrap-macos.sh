#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

echo "AI Operating System — macOS bootstrap"
echo "Repository: $ROOT"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script is for macOS." >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Apple Command Line Tools are required."
  if ask_yes_no "Open the Apple Command Line Tools installer now?" yes; then
    xcode-select --install || true
  fi
  echo "Complete the installer, then run this script again."
  exit 2
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Proposed official installer:"
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  if ask_yes_no "Run the Homebrew installer?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  else
    echo "Install Homebrew manually, then rerun." >&2
    exit 3
  fi
fi

ensure_brew_command() {
  local command_name="$1"
  local package_name="$2"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Installing $package_name with Homebrew..."
    brew install "$package_name"
  fi
}

ensure_brew_command git git
ensure_brew_command python3 python
ensure_brew_command gh gh
ensure_brew_command jq jq

if ! command -v codex >/dev/null 2>&1; then
  echo "Codex is not installed. Proposed official installer:"
  echo 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  if ask_yes_no "Install Codex now?"; then
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
  else
    echo "Codex installation skipped. You can install it later."
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
echo "Bootstrap complete. Next: gh auth login"
echo "Then run: ./scripts/create-private-github-repo.sh OWNER/ai-operating-system"
