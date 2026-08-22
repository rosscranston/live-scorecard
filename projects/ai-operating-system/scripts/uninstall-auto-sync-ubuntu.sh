#!/usr/bin/env bash
set -euo pipefail
UNIT_DIR="$HOME/.config/systemd/user"
systemctl --user disable --now ai-operating-system-sync.timer >/dev/null 2>&1 || true
rm -f "$UNIT_DIR/ai-operating-system-sync.timer" "$UNIT_DIR/ai-operating-system-sync.service"
systemctl --user daemon-reload
echo "Removed Ubuntu auto-sync user timer."
