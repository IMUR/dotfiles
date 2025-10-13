# Cooperator System State Report

**Generated**: 2025-10-07  
**Node**: cooperator (crtr)  
**Purpose**: Comprehensive snapshot for schema-first migration

---

## Executive Summary

**System Identity**
- **Hostname**: cooperator
- **IP**: 192.168.254.10/24 (internal), 47.155.237.161 (external)
- **OS**: Debian GNU/Linux 13 (trixie) aarch64
- **Kernel**: Linux 6.12.47+rpt-rpi-2712
- **Hardware**: Raspberry Pi 5 (BCM2712, 4-core @ 2.40 GHz)
- **Memory**: 15.84 GiB total, 24% used (3.87 GiB)
- **Uptime**: 7 hours, 12 minutes
- **Shell**: zsh (/usr/bin/zsh)

---

## 1. Systemd Services

### 1.1 Core Gateway Services (Enabled & Active)

**Infrastructure**
- `caddy.service` - Reverse proxy (ports 80, 443)
- `pihole-FTL.service` - DNS server with ad blocking (port 53)
- `nfs-server.service` - NFS kernel server (port 2049)
- `docker.service` - Container runtime
- `containerd.service` - Container daemon

**Custom Services**
- `atuin-server.service` - Shell history sync (port 8811, user: crtr)
- `semaphore.service` - Ansible UI (port 3000, user: crtr)
- `gotty.service` - Web terminal (port 7681, user: crtr)

**System Services**
- `ssh.service` - SSH server (port 22)
- `NetworkManager.service` - Network management
- `systemd-timesyncd.service` - Time synchronization
- `cron.service` - Scheduled tasks

### 1.2 Virtualization/Container Services

- `libvirtd.service` - Libvirt daemon
- `virtlogd.service` - Virtual machine logging
- `libvirt-guests.service` - VM guest management
- `netavark-dhcp-proxy.service` - Container networking
- `netavark-firewalld-reload.service` - Container firewall

### 1.3 Systemd Timers (Enabled)

- `dpkg-db-backup.timer` - Package database backup
- `fake-hwclock-save.timer` - Clock persistence
- `fstrim.timer` - SSD/filesystem trim
- `logrotate.timer` - Log rotation

### 1.4 Notable Disabled Services

Performance monitoring (PCP):
- `pmcd.service`, `pmie.service`, `pmlogger.service`, `pmproxy.service` - All disabled

Podman:
- `podman.service`, `podman-auto-update.service` - Disabled (using Docker instead)

---

## 2. Network Configuration

### 2.1 Network Interfaces

**Loopback (lo)**
- IPv4: 127.0.0.1/8
- IPv6: ::1/128

**Primary Ethernet (eth0)**
- MAC: 88:a2:9e:07:04:22
- IPv4: 192.168.254.10/24 (DHCP, 11288s lease)
- Gateway: 192.168.254.1 (implied)
- IPv6 Link-Local: fe80::8aa2:9eff:fe07:422/64

**Docker Bridge (docker0)**
- State: DOWN (no containers using default bridge)
- IPv4: 172.17.0.1/16

**Custom Docker Network (br-8c9e8fbb668b)**
- State: UP
- IPv4: 172.18.0.1/16
- IPv6 Link-Local: fe80::a446:45ff:fe86:c264/64
- Connected: 2 containers (n8n stack)
  - vethe8a1c53@if2
  - vethb744198@if2

### 2.2 Listening Ports

**UDP Services**
- `53` - DNS (Pi-hole)
- `67`, `68` - DHCP client/server
- `111` - RPC bind
- `123` - NTP (timesyncd)
- `443` - QUIC (Caddy HTTP/3)
- Various ephemeral ports (49571, 49910, 50617, etc.)

**TCP Services - Public/Cluster**
- `22` - SSH (all interfaces)
- `53` - DNS (Pi-hole)
- `80` - HTTP (Caddy, IPv4/IPv6)
- `443` - HTTPS (Caddy)
- `2049` - NFS (IPv4/IPv6)
- `8080` - Pi-hole web UI
- `8443` - Cockpit (IPv4/IPv6)
- `8811` - Atuin server (192.168.254.10 only)

**TCP Services - Localhost Only**
- `2019` - Caddy admin API
- `3000` - Semaphore (proxied)
- `5678` - n8n (proxied)
- `7681` - GoTTY (proxied)
- `9090` - Cockpit (proxied)
- Various container ports (15903, 38177, 38207, etc.)

### 2.3 DNS Configuration

**Client**: Uses localhost (127.0.0.1) via Pi-hole  
**Server**: Pi-hole on port 53  
**External DNS**: crtrcooperator.duckdns.org → 47.155.237.161

---

## 3. Package Inventory

### 3.1 Core System Packages (141 manually installed)

**Essential Tools**
- bash-completion, curl, wget, git, vim, nano
- tmux, htop, tree, ncdu
- rsync, duf

**Modern CLI Tools**
- eza (modern ls)
- bat (modern cat)
- fd-find (modern find)
- ripgrep (fast grep)
- fzf (fuzzy finder)
- git-delta (diff viewer)
- fastfetch (system info)
- nnn (file manager)

**Development**
- golang-go, nodejs, npm
- python3, python3-dev, python3-pip, python3-venv, pipx
- build-essential, cmake, pkg-config
- Various dev libraries (libssl-dev, libffi-dev, etc.)

**Container/Virtualization**
- docker-ce, docker-ce-cli, containerd.io
- docker-buildx-plugin, docker-compose-plugin
- cockpit, cockpit-podman, cockpit-machines

**Services**
- caddy - Reverse proxy
- pihole-meta - DNS/ad blocking (via installer)
- nfs-kernel-server - NFS server
- ansible, ansible-core, ansible-lint

**System**
- linux-image-rpi-2712, raspi-firmware
- firmware-* (atheros, brcm80211, iwlwifi, realtek, misc-nonfree)
- systemd-sysv, systemd-timesyncd

**Monitoring**
- pcp, python3-pcp (Performance Co-Pilot, services disabled)

**Media/Graphics**
- gstreamer1.0-*, mplayer, fbset
- tesseract-ocr, python3-opencv
- fontconfig

### 3.2 Fonts

**Total Installed**: 307 fonts

**Samples**
- DejaVu Serif/Sans/Mono (system)
- JetBrainsMono Nerd Font (user installed, ~/.local/share/fonts/)
- Hack Nerd Font (user installed)

---

## 4. User Environment

### 4.1 User: crtr

**UID**: 1000  
**Groups**: sudo, docker, users  
**Home**: /home/crtr  
**Shell**: /usr/bin/zsh  
**PATH**: `/usr/local/bin:/usr/bin:/bin:/usr/games`  
**TERM**: xterm-256color

### 4.2 Hidden Files/Directories in Home

**Configuration Management**
- `.config/` - Application configs
- `.ssh/` - SSH keys and config
- `.gitconfig` - Git configuration
- `.zshrc` - Zsh configuration
- `.bashrc` - Bash configuration (fallback)
- `.profile`, `.zprofile` - Shell initialization

**Tool Data**
- `.atuin/` - Shell history sync data
- `.local/` - User binaries and data
- `.cache/` - Application caches
- `.cargo/`, `.rustup/` - Rust toolchain
- `.npm/` - Node.js packages

**AI/Editor Tools**
- `.claude/`, `.claude.json` - Claude AI config
- `.cursor/`, `.cursor-server/` - Cursor editor
- `.zed_server/` - Zed editor
- `.codex/` - Codex integration
- `.gemini/` - Gemini AI
- `.specstory/` - Spec Story

**Other**
- `.ansible/` - Ansible data
- `.semaphore/` - Semaphore data
- `.hailo/` - Hailo AI accelerator config

### 4.3 Git Configuration

```gitconfig
[user]
    name = crtr
    email = rjallen22@gmail.com
    signingkey = ~/.ssh/id_ed25519.pub

[init]
    defaultBranch = main

[core]
    editor = nano
    pager = bat --paging=always
    autocrlf = input

[pull]
    rebase = true

[push]
    default = simple

[credential]
    helper = store

[gpg]
    format = ssh

[commit]
    gpgsign = true
```

### 4.4 Key Config Files in ~/.config

**Core Tools**
- `atuin/config.toml`, `atuin/server.toml` - Shell history sync
- `chezmoi/chezmoi.toml` - Dotfile management
- `git/ignore` - Global gitignore
- `ghostty/config` - Terminal emulator
- `cursor/cli-config.json` - Cursor CLI

**AI/Development**
- `coderabbit/user-data.json` - Code review AI
- `go/telemetry/` - Go telemetry data
- `gopls/prompt/` - Go language server

### 4.5 Shell Configuration

**Zsh (~/.zshrc)**
- Sources `.profile` first for foundation
- History: 50,000 lines with dedup
- Modern tools: eza, bat, fzf integration
- Auto-cd, pushd, intelligent completion
- Shared history across sessions

**Bash (~/.bashrc)**
- Managed by chezmoi
- Modern tool aliases (eza, bat)
- Color support for ls, grep
- Fallback for non-zsh environments

### 4.6 SSH Configuration

**Client Config (~/.ssh/config)**
- Global TERM fix: `xterm-256color`
- ServerAliveInterval: 60s (keepalive)

**Cluster Nodes**
- crtr (192.168.254.10) - Self
- prtr/pprt (192.168.254.20) - Projector
- drtr/dprt (192.168.254.30) - Director
- zrtr (192.168.254.11) - Zero (if exists)
- terminator/trtr (192.168.254.40) - MacBook Air M4

**Identity Files**
- `~/.ssh/id_ed25519` - Primary key
- `~/.ssh/id_ed25519_automation` - Automation key
- `~/.ssh/id_ed25519_self` - Self-SSH key

**Authorized Keys**: 9 keys total
- User key (ed25519)
- projector node key (rsa)
- 7 additional authorized keys

---

## 5. Service Configurations

### 5.1 Caddy Reverse Proxy

**Config**: `/etc/caddy/Caddyfile`  
**Binary**: `/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile`  
**PID**: 876  
**Email**: admin@ism.la (Let's Encrypt)

**Domain Routing**

*Root Domains*
- `ism.la` → redirect to `www.ism.la`
- `www.ism.la` → "Welcome to ism.la - Co-lab Cluster Gateway"

*Cooperator Services*
- `dns.ism.la` → localhost:8080 (Pi-hole)
- `ssh.ism.la` → localhost:7681 (GoTTY, WebSocket)
- `mng.ism.la` → localhost:9090 (Cockpit, HTTPS backend)
- `cfg.ism.la` → localhost:3001 (Config UI)
- `smp.ism.la` → localhost:3000 (Semaphore)
- `n8n.ism.la` → localhost:5678 (n8n, SSE with flush_interval: -1)

*Projector Services (Cross-node)*
- `acn.ism.la`, `api.ism.la` → 192.168.254.20:3737 (Archon)
- `dtb.ism.la` → 192.168.254.20:54321 (Database)
- `mcp.ism.la` → 192.168.254.20:8051 (MCP)
- `cht.ism.la` → 192.168.254.20:8080 (OpenWebUI)

*Other*
- `btr.ism.la` → 192.168.254.123:80 (Barter)
- `search.ism.la` → 503 "coming soon"

**Backup Locations**
- `/cluster-nas/backups/usb-original-system/root/etc/caddy/Caddyfile`
- `/mnt/usb-backup/root/etc/caddy/Caddyfile`
- `/home/crtr/Projects/crtr-config/config/caddy/Caddyfile`

### 5.2 Pi-hole DNS

**Binary**: `/usr/bin/pihole-FTL -f`  
**PID**: 940  
**Ports**: 53 (DNS), 8080 (Web UI, localhost only)

**Config Locations**
- `/etc/pihole/` - Main config
- `/etc/pihole/migration_backup_v6/setupVars.conf` - Backup
- `/etc/pihole/migration_backup/adlists.list` - Backup

**DNS Overrides**: `/etc/dnsmasq.d/02-custom-local-dns.conf`
- All `*.ism.la` → 192.168.254.10

### 5.3 DuckDNS

**Script**: `~/duckdns/duck.sh`  
**Domain**: crtrcooperator.duckdns.org  
**Token**: dd3810d4-6ea3-497b-832f-ec0beaf679b3  
**Status**: OK (last update successful)  
**Cron**: Every 5 minutes (`*/5 * * * *`)

### 5.4 Docker Services

**Runtime**: Docker 28.5.0, Compose v2.39.4

**Running Containers** (n8n stack on br-8c9e8fbb668b):
- n8n (port 5678, localhost only)
- n8n-postgres (internal database)

**Config**: `/cluster-nas/services/n8n/docker-compose.yml`

---

## 6. Cron Jobs

**User: crtr**
```cron
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
0 3 * * * /usr/local/bin/cluster-backup.sh
```

- DuckDNS update: Every 5 minutes
- Cluster backup: Daily at 3:00 AM

---

## 7. Kernel Modules

**Networking** (first 20 of many)
- `tcp_diag`, `inet_diag` - TCP diagnostics
- `veth` - Virtual ethernet (Docker)
- `bridge`, `stp`, `llc` - Network bridging
- `nf_conntrack*` - Connection tracking
- `nf_nat`, `xt_nat`, `xt_MASQUERADE` - NAT/masquerading
- `nf_defrag_ipv4`, `nf_defrag_ipv6` - IP defragmentation
- `ip_set`, `xt_set` - IP sets for firewall

---

## 8. Storage & Filesystem

**Root Filesystem**
- Device: /dev/sdb (USB 3.0 drive)
- Used: 18.45 GiB / 938.44 GiB (2%)
- Type: ext4

**Cluster NAS**
- Device: /dev/sda1 (NVMe SSD)
- Mount: /cluster-nas
- Type: XFS
- Size: 1.8TB
- NFS Export: 192.168.254.0/24 (rw,sync,no_subtree_check,no_root_squash)

**tmpfs**
- /tmp: 8GB
- /var/log: 50MB

---

## 9. Key Observations

### 9.1 System Health

✅ **Healthy**
- All core services running (caddy, pihole, nfs, docker)
- Network connectivity stable
- Low disk usage (2% root, cluster-nas available)
- Reasonable memory usage (24%)
- DuckDNS updating successfully

### 9.2 Configuration Management

**Current State**
- Live configs in `/etc/`
- Backups in `/cluster-nas/backups/` and `/mnt/usb-backup/`
- Repository configs in `/home/crtr/Projects/crtr-config/config/`
- **No automated sync** between live and repo

**Migration Opportunity**
- Multiple Caddyfile locations indicate backup/migration activity
- Pi-hole has migration backups (v6)
- Ready for schema-first consolidation

### 9.3 User Environment

**Well Configured**
- Modern CLI tools (eza, bat, fd, rg, fzf)
- Dotfiles managed by chezmoi
- Multiple shells configured (zsh primary, bash fallback)
- SSH config for cluster access
- Git signing with SSH keys

### 9.4 Services Architecture

**Gateway Pattern**
- Caddy as central reverse proxy
- All services bind to localhost (security)
- Public access only via HTTPS through Caddy
- Cross-node proxying to projector services

**Container Strategy**
- Docker (not Podman) for containers
- Custom bridge network for service isolation
- NFS-backed persistent storage

### 9.5 Missing/Disabled

- PCP (Performance Co-Pilot) - Installed but disabled
- Podman - Installed but not used (Docker preferred)
- Some systemd services masked/disabled (apt-daily, cryptdisks, etc.)

---

## 10. Files for Schema Migration

### 10.1 Critical Config Files

**Must Extract**
- `/etc/caddy/Caddyfile` - Domain routing
- `/etc/dnsmasq.d/02-custom-local-dns.conf` - DNS overrides
- `/etc/pihole/setupVars.conf` - Pi-hole config (if exists)
- `/etc/exports` - NFS exports
- `/etc/systemd/system/atuin-server.service`
- `/etc/systemd/system/semaphore.service`
- `/etc/systemd/system/gotty.service`

**Docker Services**
- `/cluster-nas/services/n8n/docker-compose.yml`
- `/cluster-nas/services/n8n/.env` (secrets)

**Network**
- `/etc/hosts` - Host entries
- `/etc/hostname` - System hostname

### 10.2 User Environment Files

**Shell Configuration**
- `~/.zshrc`, `~/.bashrc`, `~/.profile`
- `~/.config/atuin/config.toml`
- `~/.config/chezmoi/chezmoi.toml`

**SSH**
- `~/.ssh/config` - SSH client config
- `~/.ssh/authorized_keys` - Authorized keys

**Git**
- `~/.gitconfig` - Git configuration

---

## 11. Recommendations for Schema Migration

### 11.1 High Priority

1. **Extract service definitions** from systemd units and docker-compose
2. **Extract domain routing** from Caddyfile
3. **Extract DNS overrides** from dnsmasq config
4. **Document package list** for base system state
5. **Map port bindings** to services

### 11.2 Medium Priority

6. **User environment** → state/user.yml
7. **Cron jobs** → state/scheduled.yml
8. **SSH configuration** → state/ssh.yml
9. **Network interfaces** → state/network.yml

### 11.3 Low Priority (Optional)

10. Kernel modules (auto-loaded)
11. Font inventory (user preference)
12. Disabled services (document reasons)

---

## 12. Next Steps

### For Schema-First Migration

1. **Complete JSON schemas** (network, node)
2. **Create extraction scripts** to parse live configs → state/*.yml
3. **Validate extracted state** against schemas
4. **Generate test configs** from state
5. **Compare generated vs live** configs
6. **Iterate until perfect match**

### For Documentation

This report should be referenced in:
- `.meta/ai/context.json` - Update system state section
- `.meta/ai/knowledge.yml` - Add troubleshooting context
- `state/*.yml` - Source data for migration

---

**Report Complete**

This snapshot captures cooperator's complete system state as of 2025-10-07, providing the foundation for schema-first migration.
