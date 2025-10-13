# crtr-config

**Schema-first Infrastructure-as-Code** for the cooperator node (192.168.254.10), the gateway of the Co-lab cluster.

## Quick Start

**New to this repository?** Read [START-HERE.md](START-HERE.md) first.

**For AI assistants:** Read [CLAUDE.md](CLAUDE.md) for operational guidance.

## What Is This?

A **state-driven** infrastructure repository where all system configuration lives in validated YAML state files that generate configs automatically.

**State → Validation → Generation → Deployment**

```
state/*.yml (edit)
  ↓ validate
.meta/schemas/*.json (enforce structure)
  ↓ generate
config/* (auto-generated)
  ↓ deploy
Live system (cooperator)
```

**Never edit generated configs directly.** Always edit state files.

## Node Profile: Cooperator (crtr)

- **IP**: 192.168.254.10 (internal), 47.155.237.161 (external)
- **Hardware**: Raspberry Pi 5 (ARM64, 4-core, 16GB RAM)
- **OS**: Debian 13 (Trixie) → migrating to Raspberry Pi OS
- **Role**: Gateway - reverse proxy (Caddy), DNS (Pi-hole), NFS server
- **Storage**: 931GB USB (OS) + 1.8TB NVMe (/cluster-nas)

## Repository Structure

```
crtr-config/
├── START-HERE.md              # 👈 Read this first
├── CLAUDE.md                  # AI assistant guidance
├── COOPERATOR-ASPECTS.md      # Complete technical reference
│
├── state/                     # 👈 EDIT THESE (source of truth)
│   ├── services.yml           # All services
│   ├── domains.yml            # Domain routing
│   ├── network.yml            # Network config
│   └── node.yml               # Node identity
│
├── config/                    # Generated configs (DO NOT EDIT)
│   ├── caddy/
│   ├── pihole/
│   └── systemd/
│
├── .meta/                     # Architecture & schemas
│   ├── schemas/               # JSON schemas
│   ├── generation/            # Jinja2 templates
│   └── validation/            # Validation tools
│
├── scripts/                   # Operational scripts
├── backups/                   # Backup snapshots
├── docs/                      # Documentation
└── archives/                  # Old documentation
```

## Essential Commands

### State Management Workflow

```bash
# 1. Edit state
vim state/services.yml

# 2. Validate
./.meta/validation/validate.sh

# 3. Generate configs
./scripts/generate/regenerate-all.sh

# 4. Review generated configs
git diff config/

# 5. Deploy (manual for now)
sudo cp config/caddy/Caddyfile /etc/caddy/
sudo systemctl reload caddy
```

### Validation

```bash
# Validate all state files
./.meta/validation/validate.sh
```

### Config Generation

```bash
# Regenerate all configs from state
./scripts/generate/regenerate-all.sh
```

## Key Services

**Gateway Services:**
- Caddy - Reverse proxy (ports 80, 443, 8443)
- Pi-hole - DNS server (port 53)
- NFS - Cluster storage (/cluster-nas)

**Running Services:**
- n8n - Workflow automation (n8n.ism.la)
- Semaphore - Ansible UI (smp.ism.la)
- Cockpit - System management (mng.ism.la)
- GoTTY - Web terminal (ssh.ism.la)
- Atuin - Shell history sync (port 8811)

## Documentation

- [START-HERE.md](START-HERE.md) - Getting started guide
- [CLAUDE.md](CLAUDE.md) - AI assistant guidance
- [COOPERATOR-ASPECTS.md](COOPERATOR-ASPECTS.md) - Complete technical reference
- [docs/INDEX.md](docs/INDEX.md) - Documentation index
- [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) - System architecture
- [docs/MINIMAL-DOWNTIME-MIGRATION.md](docs/MINIMAL-DOWNTIME-MIGRATION.md) - Current migration plan

## Current Status

**Phase**: Pre-migration (Debian SD → Raspberry Pi OS USB)
**Architecture**: Schema-first system functional (validate → generate)
**Next**: Migration execution with human-in-the-loop

## Related

- **colab-config** (`~/Projects/colab-config/`) - Cluster-wide configurations
- **crtr-config** (this repo) - Cooperator-specific configurations
