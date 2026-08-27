#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
RESTART_SERVER=false
RESTART_RESOURCE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --restart-server)
            RESTART_SERVER=true
            shift
            ;;
        --restart-resource)
            RESTART_RESOURCE="${2:-}"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

echo "=== SouthVale RP Production Deploy ==="

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Simulating deployment to ovh:/opt/fivem/server-data/..."
    tar --exclude="./secrets.cfg" --exclude="./cache" --exclude="./*.log" --exclude="*.git" -czf - -C server-data . | ssh ovh "tar -tzf -"
    echo "[DRY RUN] Complete. No changes made on production."
    exit 0
fi

# 1. Create timestamped remote backup on OVH
echo "Creating remote backup on OVH..."
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
echo "Transferring local server-data to production..."
tar --exclude="./secrets.cfg" --exclude="./cache" --exclude="./*.log" --exclude="*.git" -czf - -C server-data . | ssh ovh "sudo tar -xzf - -C /opt/fivem/server-data && sudo chown -R fivem:fivem /opt/fivem/server-data"

echo "File transfer complete."

# 3. Optional restart
if [[ "$RESTART_SERVER" == "true" ]]; then
    echo "Restarting fivem.service..."
    ssh ovh "sudo systemctl restart fivem.service"
    sleep 4
    ssh ovh "sudo systemctl status fivem.service --no-pager"
fi

echo "Deployment finished."
