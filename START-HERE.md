# START HERE: crtr-config

**Schema-first Infrastructure-as-Code** for cooperator (192.168.254.10)

**Current Status:** Pre-migration (Debian SD → Raspberry Pi OS USB)

---

## Quick Orientation

### What Is This Repository?

A **state-driven** infrastructure repository where:
- All configuration lives in validated YAML state files
- Configs auto-generate from state (no manual editing)
- Changes follow: State → Validate → Generate → Deploy

### Repository Purpose

Manage the **cooperator node** - the gateway node of the Co-lab cluster:
- Reverse proxy (Caddy) for all *.ism.la domains
- DNS server (Pi-hole) for cluster
- NFS server for shared storage
- Docker services (n8n, Semaphore, etc.)

---

## Essential Reading

**New users:**
1. [README.md](README.md) - Repository overview (5 min)
2. [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) - System design (15 min)
3. [CLAUDE.md](CLAUDE.md) - Operational guidance (10 min)

**AI assistants:**
1. [CLAUDE.md](CLAUDE.md) - Complete operational guidance
2. `.meta/ai/context.json` - File locations and patterns
3. `.meta/ai/knowledge.yml` - Troubleshooting knowledge base

**Complete reference:**
- [COOPERATOR-ASPECTS.md](COOPERATOR-ASPECTS.md) - Full technical documentation

---

## Repository Structure

```
crtr-config/
├── state/                     # 👈 EDIT THESE (source of truth)
│   ├── services.yml           # All services
│   ├── domains.yml            # Domain routing
│   ├── network.yml            # Network config
│   └── node.yml               # Node identity
│
├── config/                    # Generated configs (DO NOT EDIT)
│   ├── caddy/Caddyfile
│   ├── pihole/local-dns.conf
│   └── systemd/*.service
│
├── .meta/                     # Architecture & schemas
│   ├── schemas/               # JSON schemas for validation
│   ├── generation/            # Jinja2 templates
│   ├── validation/            # Validation scripts
│   └── ai/                    # AI operational context
│
├── scripts/                   # Operational tools
│   ├── generate/              # Config generators
│   ├── sync/                  # State sync
│   ├── dns/                   # DNS management
│   └── ssot/                  # Infrastructure truth
│
├── backups/                   # Configuration snapshots
├── docs/                      # Documentation
└── archives/                  # Old documentation
```

---

## The Schema-First Workflow

### Core Principle

**Never edit generated configs directly.** Always edit state files.

```
state/*.yml (edit)
  ↓ validate
.meta/schemas/*.json (enforce structure)
  ↓ generate
config/* (auto-generated)
  ↓ deploy
Live system (cooperator)
```

### Example: Add a New Service

**❌ Wrong (manual editing):**
```bash
sudo vim /etc/caddy/Caddyfile      # Direct edit
sudo systemctl reload caddy
# Config drifts from state, no validation
```

**✅ Right (schema-first):**
```bash
# 1. Edit state
vim state/domains.yml
# Add: myservice.ism.la → localhost:8080

# 2. Validate
./.meta/validation/validate.sh

# 3. Generate
./scripts/generate/regenerate-all.sh

# 4. Review
git diff config/caddy/Caddyfile

# 5. Deploy (manual for now)
sudo cp config/caddy/Caddyfile /etc/caddy/
sudo systemctl reload caddy

# 6. Verify
curl -I https://myservice.ism.la
```

---

## Essential Commands

### Validate State Files

```bash
./.meta/validation/validate.sh
```

Ensures all state files conform to schemas before generating configs.

### Generate Configs

```bash
./scripts/generate/regenerate-all.sh
```

Regenerates all configs from state files (Caddy, Pi-hole, systemd, docker-compose).

### Export Live State

```bash
./scripts/sync/export-live-state.sh --dry-run all
```

Exports current system configuration to state files (useful for syncing).

---

## Current System

### Node Profile

- **Hostname:** cooperator (crtr)
- **IP:** 192.168.254.10 (internal)
- **External:** 47.155.237.161 via crtrcooperator.duckdns.org
- **Hardware:** Raspberry Pi 5 (ARM64, 4-core, 16GB RAM)
- **OS:** Debian 13 (Trixie) → migrating to Raspberry Pi OS
- **Storage:** 931GB USB (OS) + 1.8TB NVMe (/cluster-nas)

### Key Services

**Gateway:**
- Caddy - Reverse proxy (80, 443, 8443)
- Pi-hole - DNS server (53)
- NFS - Cluster storage (2049)

**Applications:**
- n8n - Workflow automation (n8n.ism.la)
- Semaphore - Ansible UI (smp.ism.la)
- Cockpit - System management (mng.ism.la)
- GoTTY - Web terminal (ssh.ism.la)
- Atuin - Shell history sync (8811)

---

## Current Phase: Pre-Migration

### Migration Overview

**From:** Debian 13 on microSD card
**To:** Raspberry Pi OS on USB 3.2 drive
**Goal:** 4x-7x performance improvement, modern OS

### Migration Documentation

- [docs/MINIMAL-DOWNTIME-MIGRATION.md](docs/MINIMAL-DOWNTIME-MIGRATION.md) - Detailed procedure
- [docs/MIGRATION-CHECKLIST.md](docs/MIGRATION-CHECKLIST.md) - Execution checklist

### Migration Approach

**Human-in-the-loop** - Manual deployment with schema-first workflow:
1. Validate state files
2. Generate configs from state
3. Manually deploy generated configs
4. Verify each step before proceeding

**NOT using:** Black-box automation
**Using:** Schema-first workflow with manual verification

---

## Common Tasks

### Add New Domain

1. Edit `state/domains.yml`:
   ```yaml
   myservice.ism.la:
     backend: localhost:8080
     type: standard
   ```

2. Validate → Generate → Deploy:
   ```bash
   ./.meta/validation/validate.sh
   ./scripts/generate/regenerate-all.sh
   sudo cp config/caddy/Caddyfile /etc/caddy/
   sudo systemctl reload caddy
   ```

### Modify Service Configuration

1. Edit `state/services.yml`
2. Validate → Generate → Deploy

### Update DNS Records

External DNS (GoDaddy):
```bash
./scripts/dns/godaddy-dns-manager.sh
```

DuckDNS (dynamic):
```bash
~/duckdns/duck.sh
```

### Check System Health

```bash
systemctl status caddy pihole-FTL nfs-kernel-server
docker ps
df -h /cluster-nas
```

---

## Documentation Index

### Architecture & Design
- [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) - Complete technical design
- [docs/architecture/VISION.md](docs/architecture/VISION.md) - Why schema-first

### Infrastructure
- [docs/NODE-PROFILES.md](docs/NODE-PROFILES.md) - Cluster node profiles
- [docs/network-spec.md](docs/network-spec.md) - Network topology
- [docs/INFRASTRUCTURE-INDEX.md](docs/INFRASTRUCTURE-INDEX.md) - Infrastructure docs index

### Operations
- [COOPERATOR-ASPECTS.md](COOPERATOR-ASPECTS.md) - Complete technical reference
- [docs/BACKUP-STRUCTURE.md](docs/BACKUP-STRUCTURE.md) - Backup organization
- [backups/README.md](backups/README.md) - Backup directory guide

### Migration
- [docs/MINIMAL-DOWNTIME-MIGRATION.md](docs/MINIMAL-DOWNTIME-MIGRATION.md) - Migration procedure
- [docs/MIGRATION-CHECKLIST.md](docs/MIGRATION-CHECKLIST.md) - Execution checklist

### Full Index
- [docs/INDEX.md](docs/INDEX.md) - Complete documentation index

---

## State Files Reference

### state/services.yml

Defines all services (systemd and docker):
- Service type (systemd, docker)
- Ports and bindings
- Dependencies
- Environment variables
- Volume mounts

### state/domains.yml

Domain to service routing:
- Domain names (*.ism.la)
- Backend targets (localhost:port or IP:port)
- Connection type (standard, websocket, sse)
- TLS settings

### state/network.yml

Network configuration:
- Interface settings
- Static IP configuration
- DNS settings
- NFS exports
- Firewall rules

### state/node.yml

Node identity and hardware:
- Hostname and IPs
- Hardware specs
- OS version
- Storage configuration
- Role in cluster

---

## Troubleshooting

### State Validation Fails

```bash
./.meta/validation/validate.sh
# Check error message
# Fix state/*.yml file
# Retry validation
```

### Generated Config Doesn't Match Live

```bash
# Export current live state
./scripts/sync/export-live-state.sh

# Compare
git diff state/

# Either:
# - Update state to match live (if live is correct)
# - Regenerate and deploy (if state is correct)
```

### Service Won't Start

Check `.meta/ai/knowledge.yml` for troubleshooting patterns, or refer to [COOPERATOR-ASPECTS.md](COOPERATOR-ASPECTS.md).

---

## Next Steps

### If You're New Here

1. Read [docs/architecture/VISION.md](docs/architecture/VISION.md) to understand why schema-first
2. Read [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) for how it works
3. Try the workflow: edit state → validate → generate → review

### If Preparing for Migration

1. Review [docs/MINIMAL-DOWNTIME-MIGRATION.md](docs/MINIMAL-DOWNTIME-MIGRATION.md)
2. Address critical issues from multi-agent review (see archives/old-docs-2025-10-13/HANDOFF-2025-10-13.md)
3. Validate state files represent current system
4. Test config generation

### If Maintaining System

1. Always edit state files, never generated configs
2. Always validate before generating
3. Always review generated configs before deploying
4. Keep backups current

---

## Getting Help

**Documentation:**
- Full docs index: [docs/INDEX.md](docs/INDEX.md)
- AI guidance: [CLAUDE.md](CLAUDE.md)
- Complete reference: [COOPERATOR-ASPECTS.md](COOPERATOR-ASPECTS.md)

**For AI Assistants:**
- Operational context: `.meta/ai/context.json`
- Troubleshooting KB: `.meta/ai/knowledge.yml`
- Always follow schema-first workflow

---

## Related Repositories

- **colab-config** (`~/Projects/colab-config/`) - Cluster-wide configuration
- **crtr-config** (this repo) - Cooperator-specific configuration

---

**Questions?** Read [CLAUDE.md](CLAUDE.md) for complete operational guidance.
