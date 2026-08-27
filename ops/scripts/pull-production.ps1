# Safely pull editable server-data from OVH production into local repository
param(
    [switch]$DryRun
)

Write-Host "Pulling editable server-data from ovh:/opt/fivem/server-data/ to ./server-data..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[DRY RUN] Would fetch server configs and resources over SSH excluding runtime caches and secrets." -ForegroundColor Yellow
    exit 0
}

# Stream tar over SSH excluding runtime caches and secrets
ssh ovh 'sudo tar --exclude="./secrets.cfg" --exclude="./cache" --exclude="./*.log" --exclude="*.git" --exclude="./.replxx_history" --exclude="./db" -czf - -C /opt/fivem/server-data .' | tar -xzf - -C server-data

Write-Host "Pull completed successfully. Run 'git status' or 'git diff' to review incoming changes." -ForegroundColor Green
