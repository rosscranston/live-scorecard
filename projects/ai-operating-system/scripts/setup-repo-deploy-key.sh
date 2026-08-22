#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
REPO="${1:-}"
MACHINE_RAW="${2:-$(hostname -s)}"
MACHINE="$(safe_machine_slug "$MACHINE_RAW")"

if [ -z "$REPO" ] || [[ "$REPO" != */* ]]; then
  echo "Usage: $0 OWNER/REPOSITORY [machine-name]" >&2
  exit 2
fi
command -v gh >/dev/null 2>&1 || { echo "gh is required to register the public key." >&2; exit 3; }
gh auth status >/dev/null

KEY="$HOME/.ssh/ai-os-$MACHINE"
ALIAS="github-ai-os-$MACHINE"
TITLE="ai-os-$MACHINE"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -e "$KEY" ] || [ -e "$KEY.pub" ]; then
  echo "Key already exists: $KEY"
else
  echo "Creating a repository-scoped SSH key without a passphrase for unattended sync."
  ssh-keygen -t ed25519 -C "$TITLE" -N "" -f "$KEY"
fi
chmod 600 "$KEY"
chmod 644 "$KEY.pub"

existing="$(gh repo deploy-key list --repo "$REPO" --json title --jq '.[].title' 2>/dev/null || true)"
if printf '%s\n' "$existing" | grep -Fx "$TITLE" >/dev/null 2>&1; then
  echo "A deploy key titled $TITLE already exists."
  echo "Verify it matches $KEY.pub. Delete/recreate it if this device was rebuilt."
else
  gh repo deploy-key add "$KEY.pub" --repo "$REPO" --title "$TITLE" --allow-write
fi

# Pin GitHub's published Ed25519 host key instead of trusting unverified ssh-keyscan output.
# Published fingerprint: SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
GITHUB_HOST_KEY='github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
touch "$HOME/.ssh/known_hosts"
if ! grep -Fqx "$GITHUB_HOST_KEY" "$HOME/.ssh/known_hosts"; then
  printf '%s\n' "$GITHUB_HOST_KEY" >> "$HOME/.ssh/known_hosts"
fi
chmod 600 "$HOME/.ssh/known_hosts"

CONFIG="$HOME/.ssh/config"
touch "$CONFIG"
chmod 600 "$CONFIG"
if ! grep -q "^Host $ALIAS$" "$CONFIG"; then
  cat >> "$CONFIG" <<EOF

Host $ALIAS
  HostName github.com
  User git
  IdentityFile $KEY
  IdentitiesOnly yes
EOF
fi

cd "$ROOT"
REMOTE="git@$ALIAS:$REPO.git"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi

echo "Testing SSH authentication (GitHub may print a normal no-shell message)..."
ssh -T "git@$ALIAS" || true
git fetch origin main

echo "Deploy key configured for only $REPO."
echo "Remote: $REMOTE"
