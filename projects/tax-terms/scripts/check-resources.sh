#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
RESOURCE_FILE="$PROJECT_DIR/Sources/TaxTerms/SeedResources.json"

jq -r '.resources[].links[].url' "$RESOURCE_FILE" |
  sort -u |
  xargs -n 1 -P 8 /bin/zsh -c '
    resource_url=$1
    http_code=$(curl -L --max-time 15 --connect-timeout 5 -sS -o /dev/null -w "%{http_code}" "$resource_url" || true)
    if [[ "$http_code" == 000 || "$http_code" -ge 400 ]]; then
      print "$http_code $resource_url"
    fi
  ' resource-check
