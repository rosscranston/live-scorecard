#!/usr/bin/env bash
set -euo pipefail

repo_root() {
  local source="${BASH_SOURCE[0]}"
  while [ -h "$source" ]; do
    local dir
    dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
    source="$(readlink "$source")"
    [[ "$source" != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")/../.." >/dev/null 2>&1 && pwd
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-no}"
  local answer
  if [ ! -t 0 ]; then
    return 1
  fi
  if [ "$default" = "yes" ]; then
    read -r -p "$prompt [Y/n] " answer || return 1
    answer="${answer:-y}"
  else
    read -r -p "$prompt [y/N] " answer || return 1
    answer="${answer:-n}"
  fi
  [[ "$answer" =~ ^[Yy]$ ]]
}

python_cmd() {
  local root="$1"
  if [ -x "$root/.venv/bin/python" ]; then
    printf '%s\n' "$root/.venv/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  else
    return 1
  fi
}

sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  else
    shasum -a 256 "$path" | awk '{print $1}'
  fi
}

safe_machine_slug() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-' | sed 's/^-//;s/-$//'
}
