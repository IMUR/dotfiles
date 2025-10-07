# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚀 Quick Start

**New to this repository?** Read [`START-HERE.md`](START-HERE.md) first.

**For AI context**, read:

1. `.meta/ai/context.json` - Complete operational context
2. `.meta/ai/knowledge.yml` - Troubleshooting knowledge base

## Repository Overview

**crtr-config** is a **schema-first, state-driven** Infrastructure-as-Code repository for the cooperator node (192.168.254.10), the gateway of a 3-node Co-lab cluster.

### What Makes This Special

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

### Node Profile: Cooperator (crtr)

- **IP**: 192.168.254.10 (internal), 47.155.237.161 (external)
- **Hardware**: Raspberry Pi 5 (ARM64, 4-core, 16GB RAM)
- **OS**: Debian 13 (Trixie)
- **Role**: Gateway - reverse proxy (Caddy), DNS (Pi-hole), NFS server
- **Storage**: 931GB USB (OS) + 1.8TB NVMe (/cluster-nas)

## Architecture: Schema-First State Management

### Core Principle

**Single Source of Truth**: All system configuration lives in validated YAML state files.

### Repository Structure

```
├── START-HERE.md              # 👈 Read this first
├── CLAUDE.md                  # This file
├── .meta/                     # Architecture & AI layer
│   ├── ARCHITECTURE.md        # Complete technical design
│   ├── VISION.md              # Why schema-first
│   ├── EXAMPLE-FLOW.md        # Workflow examples
│   ├── IMPLEMENTATION-ROADMAP.md  # Build plan
│   ├── schemas/               # JSON schemas for validation
│   │   ├── service.schema.json
│   │   ├── domain.schema.json
│   │   ├── network.schema.json
│   │   └── node.schema.json
│   ├── ai/                    # AI operational context
│   │   ├── context.json       # File locations, patterns
│   │   ├── knowledge.yml      # Troubleshooting KB
│   │   └── workflows.yml      # Common procedures
│   ├── generation/            # Jinja2 templates
│   │   ├── caddyfile.j2
│   │   ├── dns-overrides.j2
│   │   └── systemd-unit.j2
│   └── validation/            # Validation tools
│       └── validate.sh
├── state/                     # 👈 EDIT THESE (source of truth)
│   ├── services.yml           # All services
│   ├── domains.yml            # Domain routing
│   ├── network.yml            # Network config
│   └── node.yml               # Node identity
├── config/                    # Generated configs (DO NOT EDIT)
│   ├── caddy/
│   ├── pihole/
│   ├── systemd/
│   └── docker/
├── scripts/                   # Operational scripts
│   ├── generate/              # Config generators
│   │   └── regenerate-all.sh
│   ├── sync/                  # State sync tools
│   ├── ssot/                  # Infrastructure truth
│   └── dns/                   # DNS management
├── deploy/                    # Deployment automation
│   ├── deploy                 # Main CLI
│   ├── phases/                # Deploy stages
│   └── verify/                # Verification
├── docs/                      # Documentation
└── tests/                     # Test scripts
```

### State Files (Source of Truth)

| File | Purpose | Schema |
|------|---------|--------|
| `state/services.yml` | All systemd/docker services | `.meta/schemas/service.schema.json` |
| `state/domains.yml` | Domain → service routing | `.meta/schemas/domain.schema.json` |
| `state/network.yml` | Network configuration | `.meta/schemas/network.schema.json` |
| `state/node.yml` | Node identity & hardware | `.meta/schemas/node.schema.json` |

### Generated Configs (DO NOT EDIT)

These are auto-generated from state files:

| Config | Generated From | Template |
|--------|---------------|----------|
| `config/caddy/Caddyfile` | `state/domains.yml` | `.meta/generation/caddyfile.j2` |
| `config/pihole/local-dns.conf` | `state/domains.yml` | `.meta/generation/dns-overrides.j2` |
| `config/systemd/*.service` | `state/services.yml` | `.meta/generation/systemd-unit.j2` |
| `config/docker/*/docker-compose.yml` | `state/services.yml` | `.meta/generation/docker-compose.j2` |

## Essential Commands

### State Management Workflow

```bash
# 1. Edit state
vim state/services.yml

# 2. Validate
./tests/test-state.sh
# or
.meta/validation/validate.sh state/services.yml

# 3. Generate configs
./scripts/generate/regenerate-all.sh

# 4. Review generated configs
git diff config/

# 5. Deploy
./deploy/deploy service myservice
# or
./deploy/deploy all
```

### Validation

```bash
# Validate all state files
./tests/test-state.sh

# Validate specific file
.meta/validation/validate.sh state/services.yml

# Check schema compliance
jsonschema -i state/services.yml .meta/schemas/service.schema.json
```

### Config Generation

```bash
# Regenerate all configs
./scripts/generate/regenerate-all.sh

# Generate specific config type
./scripts/generate/caddy.sh        # Caddyfile
./scripts/generate/dns.sh          # DNS overrides
./scripts/generate/systemd.sh      # systemd units
```

### Deployment

```bash
# Deploy everything
./deploy/deploy all

# Deploy specific service
./deploy/deploy service n8n

# Deploy specific component
./deploy/deploy gateway            # Caddy + DNS
./deploy/deploy storage            # NFS + mounts

# Verify deployment
./deploy/verify/verify-all.sh
./deploy/verify/verify-service.sh n8n
```

### Troubleshooting

```bash
# Query AI knowledge base
grep -A 20 "symptom: service won't start" .meta/ai/knowledge.yml

# Check service status
journalctl -u <service> -n 50

# Verify network
dig @localhost service.ism.la +short
curl -I https://service.ism.la
```

## Workflow Patterns

### Adding a New Service

**❌ Wrong (old way)**:

```bash
# Manual editing - DON'T DO THIS
sudo vim /etc/caddy/Caddyfile
sudo vim /etc/dnsmasq.d/02-custom-local-dns.conf
sudo systemctl reload caddy
```

**✅ Right (schema-first way)**:

1. **Edit state** (`state/services.yml`):

```yaml
services:
  myservice:
    type: docker
    image: myapp:latest
    port: 8080
    bind: 127.0.0.1
    volumes:
      - /cluster-nas/services/myservice/data:/data
```

2. **Add domain** (`state/domains.yml`):

```yaml
domains:
  myservice.ism.la:
    backend: localhost:8080
    type: standard
```

3. **Validate, generate, deploy**:

```bash
./tests/test-state.sh                    # Validate
./scripts/generate/regenerate-all.sh     # Generate
./deploy/deploy service myservice        # Deploy
```

### Modifying Service Configuration

**❌ Wrong**:

```bash
sudo vim /etc/caddy/Caddyfile  # Direct edit
```

**✅ Right**:

```bash
vim state/domains.yml                    # Edit state
./tests/test-state.sh                    # Validate
./scripts/generate/regenerate-all.sh     # Regenerate
./deploy/deploy gateway                  # Deploy
```

### Troubleshooting Issues

**Process**:

1. Check `.meta/ai/knowledge.yml` for symptom
2. Follow diagnostic steps
3. If fix needed, edit state files
4. Regenerate and redeploy

**Example**:

```bash
# Service won't start
journalctl -u myservice -n 50           # Check logs

# Find issue in knowledge base
grep -A 30 "service_start_failure" .meta/ai/knowledge.yml

# Fix in state (never direct config edit)
vim state/services.yml                   # Fix root cause
./scripts/generate/regenerate-all.sh     # Regenerate
./deploy/deploy service myservice        # Redeploy
```

## AI Assistant Guidelines

### When Loading This Repository

**Required reading order**:

1. `START-HERE.md` - Overview and current status
2. `.meta/ai/context.json` - File locations, patterns, system state
3. `.meta/ai/knowledge.yml` - Troubleshooting knowledge base
4. `.meta/ARCHITECTURE.md` - Technical design (if needed)

### When Troubleshooting

**Process**:

1. Query `.meta/ai/knowledge.yml` for symptom
2. Follow diagnostic procedure
3. Identify root cause
4. Suggest **state change** (never direct config edit)
5. Include verification steps

**Example**:

```yaml
# From .meta/ai/knowledge.yml
- symptom: "Caddy reverse proxy 502 Bad Gateway"
  root_cause: "Backend service not running"
  state_fix:
    file: state/services.yml
    change: "Ensure service.enabled: true"
  verify:
    - "systemctl status <service>"
    - "curl -I http://localhost:<port>"
```

### When Suggesting Changes

**Always**:

- Edit `state/*.yml` files
- Run validation: `./tests/test-state.sh`
- Regenerate configs: `./scripts/generate/regenerate-all.sh`
- Deploy properly: `./deploy/deploy <target>`
- Verify: `./deploy/verify/verify-<target>.sh`

**Never**:

- Edit generated configs directly
- Skip validation
- Guess at file locations (check `.meta/ai/context.json`)
- Make changes without verifying

### Context Lookup

**For file locations**:

```bash
jq '.file_locations' .meta/ai/context.json
```

**For troubleshooting patterns**:

```bash
yq '.troubleshooting[] | select(.symptom | contains("search-term"))' .meta/ai/knowledge.yml
```

## Key Configuration Patterns

### Service Definitions (state/services.yml)

**Systemd service**:

```yaml
services:
  caddy:
    type: systemd
    binary: /usr/bin/caddy
    config: /etc/caddy/Caddyfile
    enabled: true
    unit_file: package  # or path to custom unit
```

**Docker service**:

```yaml
services:
  n8n:
    type: docker
    image: n8nio/n8n:latest
    port: 5678
    bind: 127.0.0.1
    volumes:
      - /cluster-nas/services/n8n/data:/home/node/.n8n
    environment:
      WEBHOOK_URL: https://n8n.ism.la
```

### Domain Routing (state/domains.yml)

**Standard HTTP**:

```yaml
domains:
  service.ism.la:
    backend: localhost:8080
    type: standard
```

**WebSocket**:

```yaml
domains:
  ws.ism.la:
    backend: localhost:9000
    type: websocket
```

**Server-Sent Events (SSE)**:

```yaml
domains:
  sse.ism.la:
    backend: localhost:5678
    type: sse
```

**Cross-node proxy**:

```yaml
domains:
  remote.ism.la:
    backend: 192.168.254.20:3737
    type: cross_node
```

## Security & Safety

### State File Security

- State files may contain **references** to secrets
- Actual secrets stored in `.env` files (not committed)
- Use environment variables for sensitive data

### Deployment Safety

- Always validate before generating
- Always review generated configs before deploying
- Test on microSD clone when possible
- Backup before major changes

### Port Binding Strategy

- **127.0.0.1**: Services proxied via Caddy
- **0.0.0.0**: Cluster-wide (DNS, NFS, Atuin)
- **Public**: Only 22, 80, 443 via firewall/router

## Documentation Reference

### Architecture & Vision

- `.meta/ARCHITECTURE.md` - Complete technical design
- `.meta/VISION.md` - Why schema-first, benefits
- `.meta/EXAMPLE-FLOW.md` - End-to-end workflow examples
- `.meta/IMPLEMENTATION-ROADMAP.md` - Build plan

### Operational Knowledge

- `.meta/ai/context.json` - System state, file locations
- `.meta/ai/knowledge.yml` - Troubleshooting KB
- `.meta/ai/workflows.yml` - Common procedures

### Infrastructure

- `docs/INFRASTRUCTURE-INDEX.md` - Documentation index
- `docs/NODE-PROFILES.md` - Cluster nodes
- `docs/network-spec.md` - Network topology
- `COOPERATOR-ASPECTS.md` - Complete technical reference (source)

### Schemas

- `.meta/schemas/service.schema.json` - Service definitions
- `.meta/schemas/domain.schema.json` - Domain routing
- `.meta/schemas/network.schema.json` - Network config
- `.meta/schemas/node.schema.json` - Node identity

## Common Tasks Reference

### Check System Health

```bash
./deploy/verify/verify-all.sh
systemctl --failed
docker ps --filter "status=exited"
df -h /cluster-nas
```

### Backup & Restore

```bash
# Backup USB drive
./scripts/backup-usb-to-nas.sh

# Clone to microSD
./scripts/clone-usb-to-microsd.sh

# Export current state
./scripts/sync/export-state.sh

# Import state
./scripts/sync/import-state.sh
```

### Sync State to Live System

```bash
# Export live system config to state files
./scripts/sync/export-state.sh

# Apply state to live system
./scripts/sync/apply-state.sh
```

## Migration Status

**Current Phase**: Foundation (Phase 1)

See `.meta/IMPLEMENTATION-ROADMAP.md` for complete timeline.

### Completed

- ✅ Architecture designed
- ✅ JSON schemas (basic)
- ✅ AI knowledge base structure
- ✅ Documentation complete

### In Progress

- 🚧 State file migration
- 🚧 Config generators
- 🚧 Deployment automation

### Not Started

- ⏳ Full testing
- ⏳ Production cutover

## Getting Help

**If something is unclear**:

1. Check `START-HERE.md`
2. Check `.meta/ARCHITECTURE.md`
3. Check `.meta/ai/knowledge.yml`
4. Check `COOPERATOR-ASPECTS.md` (complete reference)

**For AI assistants**:

- Always check `.meta/ai/context.json` first
- Query `.meta/ai/knowledge.yml` for troubleshooting
- Follow schema-first workflow (state → validate → generate → deploy)

## Critical Reminders for AI Assistants

- **Never edit generated configs** - always edit state and regenerate
- **Always validate** before generating
- **Always backup** before major changes
- **Test on microSD clone** when available
- **Follow the workflow** - state → validate → generate → deploy
