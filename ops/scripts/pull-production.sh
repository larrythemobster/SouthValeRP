#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

echo "Pulling editable server-data from ovh:/opt/fivem/server-data/ to ./server-data..."

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would fetch server configs and resources over SSH excluding runtime caches and secrets."
    exit 0
fi

ssh ovh 'sudo tar --exclude="./secrets.cfg" --exclude="./cache" --exclude="./*.log" --exclude="*.git" --exclude="./.replxx_history" --exclude="./db" -czf - -C /opt/fivem/server-data .' | tar -xzf - -C server-data

echo "Pull completed successfully. Run 'git status' or 'git diff' to review incoming changes."
