# SouthVale RP Agent Guide

## Project Overview

This repository houses the source code, configurations, database schema definitions, and operations tooling for the SouthVale RP FiveM server built on the Qbox framework and Overextended ecosystem.

The local working tree is the authoritative source of truth. All feature additions, resource adjustments, and configuration changes should be developed locally, tracked in Git, and deployed to production.

---

## Production Environment

- **SSH Target:** `ssh ovh`
- **Hostname:** `vps-fb3604b7`
- **Linux Distribution:** Ubuntu 26.04 LTS
- **Service Account:** `fivem:fivem` (unprivileged)
- **Production Paths:**
  - **FXServer Artifact:** `/opt/fivem/server`
  - **Server Data Root:** `/opt/fivem/server-data`
  - **txAdmin Profile Data:** `/opt/fivem/txData`
  - **Production Backups:** `/opt/fivem/backups/`
  - **Systemd Unit:** `fivem.service` (`/etc/systemd/system/fivem.service`)
  - **Database Name:** `qbox`
  - **Database Host:** `127.0.0.1:3306` (strictly bound to localhost)

---

## System Architecture

The server runs on FiveM FXServer (Linux) with OneSync enabled and the official Qbox ecosystem:

- **Core Framework:** `qbx_core` with active bridge compatibility for legacy scripts where required.
- **Database Engine:** `oxmysql` connecting to local MariaDB 11.8 LTS.
- **Inventory & Items:** `ox_inventory` (configured for framework `qbx`, targeting support, weapons data, weight/slot configurations, and custom robbery loot).
- **Targeting System:** `ox_target` (global interaction context, zone markers, vehicle interactions).
- **World & Mechanics:** `ox_doorlock`, `ox_fuel`, `Renewed-Weathersync`, `Renewed-Banking`, `illenium-appearance`.
- **Communications:** `pma-voice` and `mm_radio`.
- **Mobile Phone:** `npwd`, `qbx_npwd`, `npwd_qbx_garages`, `npwd_qbx_mail`.
- **Jobs & Public Services:** `qbx_police`, `qbx_medical`, `qbx_ambulancejob`, `qbx_garages`, `qbx_vehicleshop`, `qbx_management`, `qbx_cityhall`, and civilian careers (mechanic, taxi, bus, tow, trucker, garbage, diving, news).
- **Criminal Activities:** `qbx_storerobbery`, `qbx_bankrobbery`, `qbx_houserobbery`, `qbx_truckrobbery`, `qbx_jewelery`, `qbx_drugs`, `qbx_weed`, `qbx_pawnshop`, supported by `safecracker`, `mhacking`, and `ultra-voltlab`.

Upstream resource names and folder hierarchies may evolve. Inspect the live directory structure in `server-data/resources/` instead of assuming static paths.

---

## Core Safety Rules

1. **Protect Administrator Access:**
   Never remove, overwrite, or invalidate these Steam administrator entries in `permissions.cfg`:
   ```cfg
   add_principal identifier.steam:11000010bbd2289 group.admin # KushGuy
   add_principal identifier.steam:11000010df8da9c group.admin # Phmere
   ```
2. **Never Commit Secrets:**
   Production license keys (`sv_licenseKey`), database connection credentials (`mysql_connection_string`), API keys, and Discord tokens live in `secrets.cfg` on the production server. Never commit `secrets.cfg` or embed credentials into tracked files.
3. **No Destructive Syncing:**
   Never use `rsync --delete` against production without explicit instruction.
4. **Database Protection:**
   Never drop tables or execute destructive SQL queries on the live `qbox` database without taking an explicit backup first. Live player records, banking data, and inventories must not be committed to Git.
5. **Firewall Isolation:**
   - Keep MariaDB `3306` bound strictly to `127.0.0.1`.
   - Keep txAdmin `40120/tcp` blocked from public traffic in UFW. Access txAdmin through an SSH tunnel.
   - Keep `22/tcp`, `30120/tcp`, and `30120/udp` open for game traffic and administration.
6. **Pre-Change Backups:**
   Always create a timestamped backup of affected files in `/opt/fivem/backups/<timestamp>/` before modifying production configurations.

---

## Git Workflow & Conventions

1. **Local-First Development:**
   Make edits in the local workspace. Do not make untracked direct edits on the remote server unless resolving an urgent production outage, in which case immediately pull changes back to the repository using `ops/scripts/pull-production.ps1` or `ops/scripts/pull-production.sh`.
2. **Atomic Commits:**
   Keep Git commits focused on specific tasks. Write descriptive commit messages detailing:
   - What was changed
   - Why it was changed
   - Any schema migrations or config adjustments required
3. **Diff Auditing:**
   Run `git status` and `git diff` before staging to verify that no temporary runtime logs, caches, or secrets are staged.

---

## txAdmin Access

Public access to port 40120 is disabled in UFW. To access txAdmin from your PC, establish an SSH tunnel:

```bash
ssh -L 40120:127.0.0.1:40120 ovh
```

Then open your browser to:

```text
http://127.0.0.1:40120/
```

---

## Remote Operations Reference

Check service health:
```bash
ssh ovh 'sudo systemctl status fivem.service --no-pager'
```

Restart FiveM & txAdmin:
```bash
ssh ovh 'sudo systemctl restart fivem.service'
```

Stream live server logs:
```bash
ssh ovh 'sudo journalctl -u fivem.service -f'
```

Inspect recent startup logs:
```bash
ssh ovh 'sudo journalctl -u fivem.service -n 150 --no-pager'
```

Query FiveM server status endpoints:
```bash
ssh ovh 'curl -s http://127.0.0.1:30120/info.json | jq .'
ssh ovh 'curl -s http://127.0.0.1:30120/players.json'
```

Restart a single resource without stopping the server:
Run via txAdmin web console or client command: `restart <resource_name>`.

---

## Development Guidelines

- **Exports over Legacy Bridges:** Prefer direct Qbox exports (`exports.qbx_core:...`, `exports.ox_lib:...`) over legacy QB-Core backward compatibility wrappers.
- **Client/Server Trust:** Never trust client-sent values for money, items, weapons, or permission checks. Validate inventory state and player job permissions server-side.
- **Custom Content Isolation:** When adding custom features, create dedicated standalone resources under `server-data/resources/[custom]/` rather than hacking upstream Qbox core files. This keeps upstream upgrades clean.
- **Resource Verification:** After modifying or adding resources, check `fxmanifest.lua`, confirm dependency load order in `server.cfg`, and inspect server console logs for Lua runtime or syntax errors.
