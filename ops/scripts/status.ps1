# Status check helper script for SouthVale RP production server
Write-Host "=== FiveM Service Status ===" -ForegroundColor Cyan
ssh ovh 'sudo systemctl status fivem.service --no-pager'

Write-Host "`n=== MariaDB Service Status ===" -ForegroundColor Cyan
ssh ovh 'sudo systemctl status mariadb --no-pager'

Write-Host "`n=== Listening Network Ports ===" -ForegroundColor Cyan
ssh ovh 'sudo ss -lntup | grep -E "30120|40120|3306"'

Write-Host "`n=== FiveM HTTP Endpoints ===" -ForegroundColor Cyan
ssh ovh 'curl -s http://127.0.0.1:30120/info.json | jq "{server: .server, resources: (.resources | length), vars: .vars.gamename}"'
ssh ovh 'curl -s http://127.0.0.1:30120/players.json'
