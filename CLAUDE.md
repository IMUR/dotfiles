# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Repository Purpose

**crtr-config** is the single source of truth (SSOT) for the cooperator node (192.168.254.10) configuration in a multi-node Raspberry Pi cluster. This repository manages:

- Service definitions (systemd, docker-compose)
- Domain routing (Caddy reverse proxy)
- Network configuration (DDNS, DNS)
- Node identity and hardware specs

**Philosophy:** `ssot/state/` contains the truth, `tools/` operate on it to discover, validate, and deploy configuration.

---

## Core Architecture

### SSOT Pattern

All configuration is declarative YAML in `ssot/state/`:

- **services.yml** - Services running on cooperator (systemd services, docker containers)
- **domains.yml** - Domain-to-backend mappings for Caddy reverse proxy
- **network.yml** - Network config, DDNS, DNS overrides
- **node.yml** - Node identity, hardware, and role

The SSOT tools **extract** live state, **validate** desired state, **compare** them, and **deploy** changes.

### Workflow

```
Edit ssot/state/*.yml → Validate → Deploy → Verify
```

Never manually edit live config files (`/etc/caddy/Caddyfile`, systemd units, etc.). Always:
1. Edit YAML in `ssot/state/`
2. Run validation
3. Deploy via tools
4. Commit changes to git

---

## Essential Commands

### SSOT Operations

```bash
# Discover current live state → ssot/state/
./tools/ssot discover
git diff ssot/state/  # Review what changed

# Validate state files (run before deploy!)
./tools/ssot validate

# Compare desired state vs live
./tools/ssot diff

# Deploy state to live system (requires sudo)
sudo ./tools/ssot deploy --all
sudo ./tools/ssot deploy --service=caddy

# Update DNS records
./tools/ssot dns --update
```

### Service Management

Services are defined in `ssot/state/services.yml` with types:
- `systemd` - Native systemd services (caddy, pihole, custom services)
- `docker-compose` - Docker containers (n8n, infisical)

After editing services.yml, deploy changes:
```bash
sudo ./tools/ssot deploy --service=<service-name>
systemctl status <service-name>
```

### Domain Routing

Domains in `ssot/state/domains.yml` map to Caddy reverse proxy config:
- `type: standard` - Basic HTTP reverse proxy
- `type: https_backend` - Proxy to HTTPS backend (e.g., cockpit)
- `type: websocket` - WebSocket support (e.g., gotty)
- `type: sse` - Server-sent events (e.g., n8n)

After editing domains.yml:
```bash
sudo ./tools/ssot deploy --service=caddy
sudo systemctl reload caddy
```

---

## Key Conventions

### Service Definitions

Each service in `services.yml` must specify:
- `type`: systemd or docker-compose
- `enabled`: true/false
- `binary` or `compose_file`: Path to executable or compose file
- `port` and `bind`: Network binding
- `restart`: Restart policy
- `dependencies`: Other services that must run first

### Domain Definitions

Each domain in `domains.yml` must specify:
- `fqdn`: Full domain name (e.g., `mng.ism.la`)
- `service`: Service name (matches services.yml)
- `backend`: Internal endpoint (e.g., `localhost:9090`)
- `type`: Proxy type (standard, https_backend, websocket, sse)
- `local_ip`: Node IP (always 192.168.254.10 for cooperator)
- `external_dns`: Whether to create external DNS record

### Cluster Context

**Network Architecture:**
- **Gateway Router**: 192.168.254.254 - Frontier ISP router (DHCP, port forwarding, internet gateway)
- **Cooperator**: Edge services & ingress node (reverse proxy, DNS, secrets management for cluster)

**Cluster Nodes:**
- **cooperator (crtr)**: 192.168.254.10 - Edge services, runs Caddy, Pi-hole, NFS
- **projector (prtr)**: 192.168.254.20 - GPU node (some services proxied through cooperator)
- **director (drtr)**: 192.168.254.30 - Available node
- **terminator (trtr)**: 192.168.254.40 - Available node

Some domains proxy to projector services (e.g., `mcp.ism.la` → `192.168.254.20:8051`).

---

## Important Locations

### System Paths
- `/etc/caddy/Caddyfile` - Generated from domains.yml (do not edit directly)
- `/etc/pihole/` - Pi-hole configuration
- `/cluster-nas/` - NFS mount point for shared services (n8n, semaphore)
- `/media/crtr/crtr-data/` - 1.8TB NVMe drive (may be cluster-nas source)

### Repository Structure
- `ssot/state/` - Source of truth (edit these)
- `ssot/schemas/` - JSON schemas for validation
- `tools/` - SSOT utilities (discover, validate, diff, deploy, dns)
- `tools/lib/` - Shared library functions
- `backups/` - Historical snapshots
- `archives/` - Old documentation
- `docker-*.md` - Service-specific installation guides

### Related Repositories
- **Dotfiles**: `github.com/IMUR/dotfiles` - Chezmoi-managed user environment (separate from node config)
- **Cluster config**: `/home/crtr/Projects/colab-config` - Cluster-wide configuration

---

## Migration Context

This node is in active migration from old SD card to fresh Debian 13:
- Old rootfs mounted at: `/media/crtr/rootfs/`
- Old NAS data at: `/media/crtr/crtr-data/`
- Migration tracking: `MIGRATION-STATUS.md`, `CURRENT-STATE-SUMMARY.md`

When restoring services, check these locations for existing configs and data.

---

## Documentation Organization

### Active Documents
- `README.md` - Repository overview and quick reference
- `MIGRATION-STATUS.md` - Current migration progress (~70% complete)
- `CURRENT-STATE-SUMMARY.md` - Quick "where we are" reference
- `SERVICE-CONFIGURATION.md` - Service setup and status
- `docker-*.md` - Installation guides for specific services (infisical, n8n, pihole)
- `chezmoi-manifest.md` - Dotfiles management (separate concern)

### Reference
- `MIGRATION_INVENTORY.md` - Snapshot of old system (historical, don't edit)
- `CLUSTER-MANAGEMENT-DISCUSSION.md` - Removed cluster scripts, future approaches
- `archives/` - Old documentation for reference

---

## Common Pitfalls

1. **Never edit live config files directly** - Always edit `ssot/state/`, validate, then deploy
2. **Run validation before deploy** - `./tools/ssot validate` catches errors before breaking live system
3. **Caddyfile is generated** - Don't manually edit `/etc/caddy/Caddyfile`, edit `domains.yml`
4. **Check dependencies** - Services with dependencies must have those services running first
5. **Cluster-nas mount** - Many services expect `/cluster-nas/` to be mounted (NFS or bind mount)
6. **Domain types matter** - Use correct `type` in domains.yml (websocket for WebSockets, https_backend for HTTPS backends)

---

## Node Specification

- **Hostname**: cooperator (short: crtr)
- **Role**: Edge services & ingress node - Caddy reverse proxy, Pi-hole DNS, NFS server
- **IPs**: 192.168.254.10 (internal), 47.155.237.161 (external)
- **Hardware**: Raspberry Pi 5, ARM64, 16GB RAM
- **OS**: Debian 13 (Trixie)
- **Storage**: 931GB USB (OS), 1.8TB NVMe (/cluster-nas)
- **Domain**: ism.la (all subdomains route through this node)

---

## Tool Design

The `tools/` directory contains bash scripts that operate on `ssot/`:

- `discover.sh` - Reads live system → generates YAML
- `validate.sh` - Checks YAML against schemas
- `diff.sh` - Compares YAML vs live state
- `deploy.sh` - Applies YAML → live system
- `dns.sh` - Manages external DNS (GoDaddy API)
- `ssot` - Main CLI that orchestrates the above

All tools source `tools/lib/common.sh` for shared functions.

---

## Python Development

**Primary Tool: uv** (`~/.local/bin/uv`)

Use **uv** as the primary Python package manager and environment tool wherever applicable:
- **Package installation**: `uv pip install <package>` instead of `pip install`
- **Virtual environments**: `uv venv` instead of `python -m venv`
- **Script execution**: `uvx <script>` for one-off tools
- **Project setup**: `uv init` for new Python projects

**Benefits**: Faster, more reliable, and better dependency resolution than pip/venv.

**Note**: System packages installed via apt (e.g., `python3-picamera2`, `python3-libcamera`) remain available globally and should not be reinstalled with uv.
