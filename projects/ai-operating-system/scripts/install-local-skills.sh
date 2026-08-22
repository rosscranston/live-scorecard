#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$HOME/.agents/skills"
BACKUP="$HOME/.agents/skills-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$TARGET"

for source in "$ROOT"/skills/*; do
  [ -d "$source" ] || continue
  [ -f "$source/SKILL.md" ] || continue
  name="$(basename "$source")"
  dest="$TARGET/$name"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$source" ]; then
    echo "Already installed: $name"
    continue
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP"
    mv "$dest" "$BACKUP/$name"
    echo "Backed up existing $dest to $BACKUP/$name"
  fi
  ln -s "$source" "$dest"
  echo "Installed: $name -> $source"
done

echo "Skills are installed under $TARGET. Restart Codex if needed."
