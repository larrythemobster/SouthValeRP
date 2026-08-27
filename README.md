# SouthVale RP FiveM Server

Configuration, resources, and operations repository for the SouthVale RP FiveM server, running on the Qbox framework and Overextended ecosystem.

---

## Directory Structure

```text
.
├── AGENTS.md                  # Development guide and production rules for agents & developers
├── README.md                  # Project overview and workflow documentation
├── .gitignore                 # Exclusions for runtime caches, logs, and secrets
├── server-data/               # FiveM server configurations and resources
│   ├── server.cfg             # Main FiveM server configuration
│   ├── permissions.cfg        # ACE permissions & administrator bindings
│   ├── ox.cfg                 # Overextended ecosystem settings (ox_lib, ox_inventory, ox_target)
│   ├── voice.cfg              # PMA-Voice audio settings
│   ├── misc.cfg               # Server convars and performance flags
│   ├── secrets.cfg.example    # Safe template for production credentials
│   └── resources/             # Active game resources ([qbx], [ox], [standalone], [voice], [assets], [npwd])
├── ops/                       # Operational definitions and deployment tooling
│   ├── systemd/               # Production systemd service unit snapshot (fivem.service)
│   ├── database/              # Schema-only SQL definition (qbox-schema.sql)
│   ├── firewall/              # UFW firewall status snapshot (ufw-status.txt)
│   └── scripts/               # PowerShell and Bash management scripts (status, logs, deploy, pull)
└── docs/                      # Server documentation and architectural notes
```

---

## Production Host & Access

- **Target Host:** `ssh ovh` (`vps-fb3604b7`)
- **Game Endpoints:** `30120 TCP` & `30120 UDP`
- **txAdmin Management:** Port `40120` is blocked from public internet. Access via SSH tunnel:
  ```bash
  ssh -L 40120:127.0.0.1:40120 ovh
  ```
  Then open [http://127.0.0.1:40120/](http://127.0.0.1:40120/) in your browser.

---

## Workflow

1. **Edit Locally:** Make configuration or script changes in this repository.
2. **Track with Git:** Review diffs with `git diff` and commit changes.
3. **Deploy:** Use the deployment script to push changes to production:
   - PowerShell: `.\ops\scripts\deploy.ps1`
   - Bash: `./ops/scripts/deploy.sh`
4. **Monitor:** Stream live server logs:
   - PowerShell: `.\ops\scripts\logs.ps1`
   - Bash: `./ops/scripts/logs.sh`

---

## Security Warning

Never commit secrets (license keys, database passwords, Discord tokens, or webhooks) to Git. Production credentials belong exclusively in `secrets.cfg` on the production server.

Refer to [AGENTS.md](AGENTS.md) for full architectural guidelines, administration rules, and safety protocols.
