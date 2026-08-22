#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$HOME/.agents/skills"

for dest in "$TARGET"/*; do
  [ -L "$dest" ] || continue
  target="$(readlink "$dest")"
  case "$target" in
    "$ROOT"/skills/*)
      rm "$dest"
      echo "Removed $(basename "$dest")"
      ;;
  esac
done
