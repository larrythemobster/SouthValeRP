#!/usr/bin/env bash
set -euo pipefail

echo "=== FiveM Service Status ==="
ssh ovh 'sudo systemctl status fivem.service --no-pager'

echo -e "\n=== MariaDB Service Status ==="
ssh ovh 'sudo systemctl status mariadb --no-pager'

echo -e "\n=== Listening Network Ports ==="
ssh ovh 'sudo ss -lntup | grep -E "30120|40120|3306"'

echo -e "\n=== FiveM HTTP Endpoints ==="
ssh ovh 'curl -s http://127.0.0.1:30120/info.json | jq "{server: .server, resources: (.resources | length)}"'
ssh ovh 'curl -s http://127.0.0.1:30120/players.json'
