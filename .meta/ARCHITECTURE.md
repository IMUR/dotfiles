# crtr-config Architecture: Schema-First Infrastructure-as-Code

## Philosophy

**State drives everything. Schemas validate. AI assists. Configs generate.**

### Core Principles

1. **Single Source of Truth**: `state/*.yml` files are the authoritative definition
2. **Schema Validation**: All state must pass JSON schema validation
3. **Generated Artifacts**: Configs, docs, tests generated from state
4. **AI-First Design**: Metadata optimized for AI understanding and assistance
5. **Idempotent Deployment**: Can re-run safely to converge to desired state

---

## Directory Structure

```
crtr-config/
├── .meta/                          # Metadata layer (AI-first)
│   ├── schemas/                    # JSON schemas for validation
│   │   ├── node.schema.json        # Node identity & hardware
│   │   ├── service.schema.json     # Service definitions
│   │   ├── domain.schema.json      # Domain routing rules
│   │   └── network.schema.json     # Network configuration
│   ├── ai/                         # AI operational context
│   │   ├── context.json            # Node role, critical paths, etc.
│   │   ├── workflows.yml           # Common operational workflows
│   │   └── knowledge.yml           # Troubleshooting knowledge base
│   ├── generation/                 # Template generation
│   │   ├── caddyfile.j2            # Jinja2 template
│   │   ├── dns-overrides.j2
│   │   └── systemd-unit.j2
│   └── validation/
│       ├── validate.sh             # Schema validation runner
│       └── rules.yml               # Additional validation rules
│
├── state/                          # Current desired state (schema-valid YAML)
│   ├── node.yml                    # Identity, hardware, OS config
│   ├── services.yml                # All services (systemd + docker)
│   ├── domains.yml                 # Domain → service mappings
│   ├── network.yml                 # Network, DNS, NFS config
│   └── secrets.yml                 # Secret references (not values)
│
├── config/                         # Generated configuration files
│   ├── caddy/
│   │   ├── Caddyfile               # Generated from state/domains.yml
│   │   └── .generated              # Marker: don't edit manually
│   ├── pihole/
│   │   ├── local-dns.conf          # Generated from state/domains.yml
│   │   └── custom.list             # Static entries
│   ├── systemd/
│   │   ├── atuin-server.service    # From state/services.yml
│   │   ├── semaphore.service
│   │   └── gotty.service
│   ├── docker/
│   │   └── n8n/
│   │       └── compose.yml         # From state/services.yml
│   ├── nfs/
│   │   └── exports                 # From state/network.yml
│   └── user/
│       ├── zshrc
│       ├── bashrc
│       └── bin/
│
├── deploy/                         # Deployment automation
│   ├── deploy                      # Main CLI: ./deploy [phase|service|all]
│   ├── phases/
│   │   ├── 01-base.sh              # OS packages, system config
│   │   ├── 02-storage.sh           # Mounts, NFS server
│   │   ├── 03-network.sh           # Network, DNS, DuckDNS
│   │   ├── 04-services.sh          # Systemd services
│   │   ├── 05-gateway.sh           # Caddy, domain routing
│   │   └── 06-verify.sh            # Comprehensive verification
│   ├── lib/
│   │   ├── deploy-lib.sh           # Shared functions
│   │   ├── state-query.sh          # Query state/*.yml
│   │   └── config-gen.sh           # Generate configs from state
│   └── verify/
│       ├── verify-base.sh
│       ├── verify-network.sh
│       └── verify-services.sh
│
├── scripts/                        # Operational utilities
│   ├── ssot/                       # Single source of truth queries
│   ├── dns/                        # DNS management (GoDaddy API)
│   ├── sync/                       # State ↔ system sync
│   │   ├── export-state.sh         # System → state/*.yml
│   │   └── import-state.sh         # state/*.yml → system
│   └── generate/
│       └── regenerate-all.sh       # Regenerate all configs from state
│
├── docs/                           # Generated documentation
│   ├── DEPLOY.md                   # Generated from state + phases
│   ├── REFERENCE.md                # Generated from state
│   ├── SERVICES.md                 # Generated from state/services.yml
│   └── TROUBLESHOOTING.md          # Generated from .meta/ai/knowledge.yml
│
├── tests/                          # Automated testing
│   ├── test-state.sh               # Validate state against schemas
│   ├── test-generation.sh          # Test config generation
│   └── test-deployment.sh          # Test deployment in container
│
├── CLAUDE.md                       # AI assistant operational guide
└── README.md                       # Human entry point
```

---

## How It Works

### 1. State Definition (Human-Editable)

**state/services.yml**:
```yaml
services:
  n8n:
    type: docker-compose
    compose_file: config/docker/n8n/compose.yml
    port: 5678
    bind: 127.0.0.1
    data: /cluster-nas/services/n8n/data
    enabled: true
```

**state/domains.yml**:
```yaml
domains:
  - fqdn: n8n.ism.la
    service: n8n
    backend: localhost:5678
    type: sse  # Server-Sent Events
    local_ip: 192.168.254.10
    external_dns: true
```

### 2. Schema Validation (Automated)

```bash
./deploy/lib/validate-state.sh
# ✓ state/services.yml: valid against .meta/schemas/service.schema.json
# ✓ state/domains.yml: valid against .meta/schemas/domain.schema.json
```

### 3. Config Generation (Automated)

```bash
./scripts/generate/regenerate-all.sh
# Generated: config/caddy/Caddyfile from state/domains.yml
# Generated: config/pihole/local-dns.conf from state/domains.yml
```

**Generated config/caddy/Caddyfile** (excerpt):
```caddy
# GENERATED from state/domains.yml - DO NOT EDIT MANUALLY
# To modify: Edit state/domains.yml, then run: ./scripts/generate/regenerate-all.sh

n8n.ism.la {
    reverse_proxy localhost:5678 {
        flush_interval -1  # SSE support
    }
}
```

### 4. Deployment (One Command)

```bash
./deploy all
# [01] Base system: packages, timezone, hostname
# [02] Storage: mount /cluster-nas, configure NFS
# [03] Network: DNS, DuckDNS, connectivity
# [04] Services: systemd units, Docker containers
# [05] Gateway: Caddy, domain routing
# [06] Verify: comprehensive validation
# ✓ Deployment complete
```

### 5. AI Assistance (Context-Aware)

**.meta/ai/knowledge.yml**:
```yaml
troubleshooting:
  n8n_ui_not_updating:
    symptoms:
      - n8n interface loads but doesn't show real-time updates
      - Workflows execute but UI doesn't reflect changes
    cause: Server-Sent Events require unbuffered HTTP streaming
    solution:
      - Add flush_interval: -1 to Caddy reverse proxy config
      - Restart Caddy: systemctl restart caddy
    state_fix:
      file: state/domains.yml
      change: "type: sse (not type: standard)"
    verification:
      - Open n8n UI
      - Create workflow
      - Verify real-time updates appear

  dns_not_resolving_internally:
    symptoms:
      - *.ism.la works from internet but not from cluster
      - curl fails from projector/director
    cause: External DNS returns public IP, breaks internal routing
    solution:
      - Add local DNS overrides in Pi-hole
      - File: /etc/dnsmasq.d/02-custom-local-dns.conf
    state_fix:
      file: state/domains.yml
      ensure: local_ip field is set for all domains
    verification:
      - From any cluster node: dig @192.168.254.10 n8n.ism.la
      - Should return: 192.168.254.10
```

When AI encounters an issue, it can:
1. Query `.meta/ai/knowledge.yml` for known issues
2. Suggest exact state changes
3. Generate fix commands
4. Verify solution

---

## Workflows

### Adding a New Service

**Human action**:
1. Edit `state/services.yml` - add service definition
2. Edit `state/domains.yml` - add domain routing
3. Run `./deploy/deploy service newservice`

**System does**:
1. Validates state against schemas
2. Generates Caddyfile entry
3. Generates DNS override
4. Generates systemd unit (if needed)
5. Deploys service
6. Verifies service is running
7. Updates generated documentation

### Modifying Caddy Config

**Wrong way** (old approach):
```bash
sudo vim /etc/caddy/Caddyfile  # Manual edit
sudo systemctl reload caddy
# Config drift - repo out of sync
```

**Right way** (schema-first):
```bash
vim state/domains.yml  # Edit source of truth
./scripts/generate/regenerate-all.sh  # Generate new Caddyfile
./deploy/deploy gateway  # Deploy updated config
# State, config, system all in sync
```

### Exporting Current System State

**After manual changes on live system**:
```bash
./scripts/sync/export-state.sh
# Exported /etc/caddy/Caddyfile → state/domains.yml
# Exported systemd units → state/services.yml
# Exported DNS overrides → state/domains.yml
# ⚠ Review changes, then commit
```

---

## AI Integration

**.meta/ai/context.json**:
```json
{
  "node": {
    "hostname": "cooperator",
    "role": "gateway",
    "ip": "192.168.254.10",
    "critical_services": ["caddy", "pihole-FTL", "nfs-kernel-server"]
  },
  "deployment_constraints": {
    "order": ["storage", "network", "services", "gateway"],
    "storage_dependency": "Services requiring /cluster-nas must wait for NFS mount"
  },
  "service_patterns": {
    "localhost_binding": "Services proxied via Caddy bind to 127.0.0.1",
    "cluster_binding": "Services accessed cluster-wide bind to 0.0.0.0",
    "external_binding": "Only Caddy (80/443) and SSH (22) bind externally"
  },
  "state_locations": {
    "services": "state/services.yml",
    "domains": "state/domains.yml",
    "network": "state/network.yml",
    "node": "state/node.yml"
  },
  "generation_triggers": {
    "domains_changed": "Regenerate: Caddyfile, DNS overrides, docs",
    "services_changed": "Regenerate: systemd units, docker compose, docs"
  }
}
```

AI can query this to understand:
- What files to edit for what changes
- What gets regenerated when state changes
- What order things must happen
- Why things are configured certain ways

---

## Benefits

### For Humans
- **Single edit point**: Change state/*.yml, everything else follows
- **No config drift**: Generated configs always match state
- **Safe experimentation**: Can preview generated configs before deploying
- **Clear history**: Git shows exactly what changed in state

### For AI
- **Complete context**: .meta/ai/ provides full operational knowledge
- **Structured knowledge**: Troubleshooting in queryable YAML, not prose
- **Validation**: Can check state against schemas before suggesting changes
- **Deterministic**: Same state always generates same configs

### For Operations
- **Reproducible**: ./deploy all rebuilds identical system
- **Testable**: Can validate state without deploying
- **Auditable**: State changes are version controlled
- **Extensible**: Add new services by adding to state

---

## Migration Path

### From Current crtr-config

1. **Phase 1**: Create schemas for existing state
2. **Phase 2**: Migrate current docs to state/*.yml
3. **Phase 3**: Build generators (Caddyfile, DNS, systemd)
4. **Phase 4**: Build deployment automation
5. **Phase 5**: Remove old documentation, keep generated only

### Validation Points

At each phase:
```bash
./tests/test-state.sh      # State validates against schemas
./tests/test-generation.sh # Generation produces valid configs
./tests/test-deployment.sh # Deployment succeeds in test container
```

---

## Example: Complete Service Addition

**Add Grafana monitoring**:

1. Edit state/services.yml:
```yaml
services:
  grafana:
    type: docker-compose
    image: grafana/grafana:latest
    port: 3001
    bind: 127.0.0.1
    data: /cluster-nas/services/grafana/data
    enabled: true
```

2. Edit state/domains.yml:
```yaml
domains:
  - fqdn: mon.ism.la
    service: grafana
    backend: localhost:3001
    type: standard
    local_ip: 192.168.254.10
    external_dns: true
```

3. Deploy:
```bash
./deploy/deploy service grafana
# Validated state
# Generated Caddyfile entry
# Generated DNS override
# Generated docker compose
# Started grafana container
# Verified https://mon.ism.la accessible
# Updated documentation
✓ grafana deployed successfully
```

That's it. State drives everything.

---

This is the architecture. Everything else is implementation details.
