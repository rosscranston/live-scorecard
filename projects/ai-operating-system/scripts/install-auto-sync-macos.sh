#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script is for macOS." >&2
  exit 1
fi
PLIST="$HOME/Library/LaunchAgents/com.ai-operating-system.sync.plist"
LOG="$HOME/Library/Logs/ai-operating-system-sync.log"
mkdir -p "$(dirname "$PLIST")" "$(dirname "$LOG")"
PYTHON="$(command -v python3)"
ROOT_XML="$($PYTHON -c 'import html,sys; print(html.escape(sys.argv[1], quote=True))' "$ROOT")"
LOG_XML="$($PYTHON -c 'import html,sys; print(html.escape(sys.argv[1], quote=True))' "$LOG")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.ai-operating-system.sync</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${ROOT_XML}/scripts/ai-os-sync.sh</string>
  </array>
  <key>WorkingDirectory</key><string>${ROOT_XML}</string>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>300</integer>
  <key>StandardOutPath</key><string>${LOG_XML}</string>
  <key>StandardErrorPath</key><string>${LOG_XML}</string>
  <key>ProcessType</key><string>Background</string>
</dict>
</plist>
EOF
plutil -lint "$PLIST"
launchctl bootout "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl enable "gui/$(id -u)/com.ai-operating-system.sync"
echo "Installed LaunchAgent: $PLIST"
echo "Logs: $LOG"
