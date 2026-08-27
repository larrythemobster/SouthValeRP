#!/usr/bin/env bash
set -euo pipefail
echo "Streaming live logs from fivem.service on ovh (Ctrl+C to exit)..."
ssh -t ovh 'sudo journalctl -u fivem.service -f'
