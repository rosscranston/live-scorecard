#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
BUNDLE_DIR="${SCRIPT_DIR:h}"
PRIVATE_DIR="$BUNDLE_DIR/private-state-plaintext"
OUTPUT_DIR="$BUNDLE_DIR/encrypted"
OUTPUT_FILE="$OUTPUT_DIR/codex-private-state-2026-08-11-to-2026-08-22.tar.gz.enc"
CHECKSUM_FILE="$OUTPUT_FILE.sha256"

if [[ ! -d "$PRIVATE_DIR/codex" ]]; then
  print -u2 "Missing private-state-plaintext/codex. Nothing was encrypted."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
print "Encrypting raw Codex history and memories."
print "Use a strong passphrase and save it in your password manager."

tar -C "$PRIVATE_DIR" -czf - codex | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 250000 -out "$OUTPUT_FILE.tmp"
mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
shasum -a 256 "$OUTPUT_FILE" > "$CHECKSUM_FILE"

print "Created: $OUTPUT_FILE"
print "Created: $CHECKSUM_FILE"
print "The plaintext staging directory remains local and is ignored by Git."

