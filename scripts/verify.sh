#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
BUNDLE_DIR="${SCRIPT_DIR:h}"
FAILED=0

required=(
  "projects/live-call-scorecard/Package.swift"
  "projects/private-call-notepad/Package.swift"
  "projects/tax-terms/Package.swift"
  "products/macos-apps/Live Scorecard.app/Contents/Info.plist"
  "products/macos-apps/Private Call Notepad.app/Contents/Info.plist"
  "products/macos-apps/Tax Terms.app/Contents/Info.plist"
  "codex-portable/automations/daily-brief/automation.toml"
  "codex-portable/automations/daily-circleback-external-call-sharing-and-access-cleanup/automation.toml"
  "codex-portable/automations/daily-sales-coach/automation.toml"
)

for relative_path in "${required[@]}"
do
  if [[ ! -e "$BUNDLE_DIR/$relative_path" ]]; then
    print -u2 "Missing required item: $relative_path"
    FAILED=1
  fi
done

if find "$BUNDLE_DIR" -path "$BUNDLE_DIR/private-state-plaintext" -prune -o -type f \( -name auth.json -o -name '*.sqlite' -o -name '*.sqlite-wal' -o -name '*.sqlite-shm' -o -name '*.pem' -o -name '*.p12' \) -print | grep -q .; then
  print -u2 "Prohibited credential/database filenames exist outside private staging."
  FAILED=1
fi

if find "$BUNDLE_DIR" -path "$BUNDLE_DIR/private-state-plaintext" -prune -o -type f -size +95M -print | grep -q .; then
  print -u2 "A GitHub-bound file exceeds 95 MB."
  find "$BUNDLE_DIR" -path "$BUNDLE_DIR/private-state-plaintext" -prune -o -type f -size +95M -print
  FAILED=1
fi

SECRET_MATCHES="$(rg -l --hidden --glob '!private-state-plaintext/**' --glob '!encrypted/**' --glob '!.git/**' '(BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|(api[_-]?key|client[_-]?secret|access[_-]?token|password)[[:space:]]*[:=][[:space:]]*["'\'' ]?[A-Za-z0-9_./+=-]{16,})' "$BUNDLE_DIR" || true)"
if [[ -n "$SECRET_MATCHES" ]]; then
  print -u2 "Potential secret patterns require review:"
  print -u2 "$SECRET_MATCHES"
  FAILED=1
fi

if [[ ! -f "$BUNDLE_DIR/encrypted/codex-private-state-2026-08-11-to-2026-08-22.tar.gz.enc" ]]; then
  print "Warning: encrypted private-state archive has not been created yet."
fi

if [[ "$FAILED" -ne 0 ]]; then
  print -u2 "Verification failed. Do not push yet."
  exit 1
fi

print "Verification passed for the GitHub-bound bundle."
print "Raw private state remains ignored unless encrypted."

