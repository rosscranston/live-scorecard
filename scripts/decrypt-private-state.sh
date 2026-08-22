#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
BUNDLE_DIR="${SCRIPT_DIR:h}"
INPUT_FILE="$BUNDLE_DIR/encrypted/codex-private-state-2026-08-11-to-2026-08-22.tar.gz.enc"
DEST_DIR="${1:-$BUNDLE_DIR/restore-staging}"

if [[ ! -f "$INPUT_FILE" ]]; then
  print -u2 "Encrypted archive not found: $INPUT_FILE"
  exit 1
fi

mkdir -p "$DEST_DIR"
openssl enc -d -aes-256-cbc -pbkdf2 -iter 250000 -in "$INPUT_FILE" | tar -C "$DEST_DIR" -xzf -
print "Decrypted private state into: $DEST_DIR"

