#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$(uname -s)" != "Linux" ]; then
  echo "This script is for Linux." >&2
  exit 1
fi
UNIT_DIR="$HOME/.config/systemd/user"
mkdir -p "$UNIT_DIR"
cat > "$UNIT_DIR/ai-operating-system-sync.service" <<EOF
[Unit]
Description=Safely synchronize the AI Operating System Git repository
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=$ROOT
ExecStart=/bin/bash $ROOT/scripts/ai-os-sync.sh
Nice=10
EOF

cat > "$UNIT_DIR/ai-operating-system-sync.timer" <<'EOF'
[Unit]
Description=Run AI Operating System Git sync every five minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
AccuracySec=30s
Persistent=true
Unit=ai-operating-system-sync.service

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now ai-operating-system-sync.timer
systemctl --user start ai-operating-system-sync.service || true
echo "Installed systemd user timer."
echo "Enable linger for unattended operation after logout: sudo loginctl enable-linger $USER"
