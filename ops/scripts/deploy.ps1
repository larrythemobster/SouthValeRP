# Deploy local server-data changes to OVH production safely
param(
    [switch]$DryRun,
    [string]$RestartResource = "",
    [switch]$RestartServer
)

Write-Host "=== SouthVale RP Production Deploy ===" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[DRY RUN] Simulating deployment to ovh:/opt/fivem/server-data/..." -ForegroundColor Yellow
    tar --exclude="./secrets.cfg" --exclude="./cache" --exclude="./*.log" --exclude="*.git" -czf - -C server-data . | ssh ovh "tar -tzf -"
    Write-Host "[DRY RUN] Complete. No changes made on production." -ForegroundColor Yellow
    exit 0
}

# 1. Create timestamped remote backup on OVH
Write-Host "Creating remote backup on OVH..." -ForegroundColor Cyan
ssh ovh 'bash -s' << 'EOF'
set -euo pipefail
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/fivem/backups/pre_deploy_$TIMESTAMP"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -p /opt/fivem/server-data/*.cfg "$BACKUP_DIR/" 2>/dev/null || true
sudo chown -R fivem:fivem /opt/fivem/backups
echo "Remote backup saved to: $BACKUP_DIR"
EOF

# 2. Transfer local server-data to OVH safely (excluding secrets & caches)
Write-Host "Transferring local server-data to production..." -ForegroundColor Cyan
tar --exclude="./secrets.cfg" --exclude="./cache" --exclude="./*.log" --exclude="*.git" -czf - -C server-data . | ssh ovh "sudo tar -xzf - -C /opt/fivem/server-data && sudo chown -R fivem:fivem /opt/fivem/server-data"

Write-Host "File transfer complete." -ForegroundColor Green

# 3. Optional restart
if ($RestartServer) {
    Write-Host "Restarting fivem.service..." -ForegroundColor Cyan
    ssh ovh "sudo systemctl restart fivem.service"
    Start-Sleep -Seconds 4
    ssh ovh "sudo systemctl status fivem.service --no-pager"
} elseif ($RestartResource -ne "") {
    Write-Host "Restarting resource: $RestartResource..." -ForegroundColor Cyan
    ssh ovh "curl -s -X POST http://127.0.0.1:30120/ensure/$RestartResource || true"
}

Write-Host "Deployment finished." -ForegroundColor Green
