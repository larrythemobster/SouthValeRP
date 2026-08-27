# Follow live journal logs from FiveM server
Write-Host "Streaming live logs from fivem.service on ovh (Ctrl+C to exit)..." -ForegroundColor Cyan
ssh -t ovh "sudo journalctl -u fivem.service -f"
