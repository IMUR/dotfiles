# crtr-config

**Cooperator node (192.168.254.10) configuration repository**

## Quick Start

- 📄 **[SYSTEM-STATE.md](SYSTEM-STATE.md)** - Current services, status, and progress
- 🤖 **[CLAUDE.md](CLAUDE.md)** - Instructions for AI assistants
- 📁 **[ssot/state/](ssot/state/)** - YAML configuration files (single source of truth)

## What This Is

Configuration management for the cooperator (edge services) node:
- **ssot/state/** = desired state configuration (YAML)
- **tools/** = scripts to discover, validate, and deploy configuration
- **docs/** = installation guides and documentation
- **archives/** = historical/outdated documents

## Quick Operations

### Discover Live State

```bash
./tools/ssot discover
git diff ssot/state/
```

### Validate State Files

```bash
./tools/ssot validate
```

### Compare State vs Live

```bash
./tools/ssot diff
```

### Deploy State to Live

```bash
sudo ./tools/ssot deploy --all
sudo ./tools/ssot deploy --service=caddy
```

### DNS Operations

```bash
./tools/ssot dns --update
```

### Help

```bash
./tools/ssot --help
```

## Tools

**Purpose**: Utilities that maintain, verify, and deploy ssot/

| Tool | Purpose | Why It Exists |
|------|---------|---------------|
| `discover` | Extract live → ssot/state/ | Capture running system truth |
| `validate` | Check ssot/state/ correctness | Catch errors before deployment |
| `diff` | Compare ssot/state/ vs live | See drift, verify deployment |
| `deploy` | Apply ssot/state/ → live | Materialize desired state |
| `dns` | Manage DNS records | External dependency (GoDaddy) |

Tools operate ON the ssot/, they are not part of the truth itself.

## State Files

| File | Purpose |
|------|---------|
| `ssot/state/services.yml` | Services that run (docker, systemd) |
| `ssot/state/domains.yml` | Domain routing (Caddy reverse proxy) |
| `ssot/state/network.yml` | Network config, DDNS, DNS overrides |
| `ssot/state/node.yml` | Node identity and hardware |

**Workflow**: Edit ssot/state/ → Validate → Deploy → Verify

## SSOT Organization

The `ssot/` directory can contain different types of truth:
- `ssot/state/` - Current desired state (edit these)
- Future: `ssot/discovered/` - Auto-discovered facts
- Future: `ssot/history/` - Historical state tracking

## Backups

Historical snapshots in `backups/` organized by category.

## Methodology

See `.stems/` for cluster management methodology and patterns (optional reference).

## External Repositories

- **Dotfiles**: github.com/IMUR/dotfiles (chezmoi-managed user environment)
- **Cluster**: /home/crtr/Projects/colab-config (cluster-wide config)

## Node Specification

- **Hostname**: cooperator (crtr)
- **IP**: 192.168.254.10 (internal), 47.154.23.175 (external via DuckDNS)
- **Role**: Edge services & cluster ingress (Caddy, Pi-hole, Infisical, Cockpit)
- **Hardware**: Raspberry Pi 5, ARM64, 16GB RAM
- **OS**: Debian 13 (Trixie), kernel 6.12.47
- **Storage**: 931GB USB (OS) + 1.8TB NVMe (/media/crtr/crtr-data)

## Repository Structure

```
crtr-config/
├── README.md          # Project overview (you are here)
├── SYSTEM-STATE.md    # Current system status and services
├── CLAUDE.md          # Instructions for AI assistants
├── ssot/              # Single Source of Truth
│   ├── state/         # YAML configuration files
│   │   ├── services.yml  # Service definitions
│   │   ├── domains.yml   # Domain routing (Caddy)
│   │   ├── network.yml   # Network configuration
│   │   └── node.yml      # Node identity
│   └── schemas/       # JSON schemas for validation
├── tools/             # Management scripts
│   ├── ssot           # Main CLI orchestrator
│   ├── discover.sh    # Extract live config → YAML
│   ├── validate.sh    # Check YAML syntax
│   ├── diff.sh        # Compare desired vs actual
│   ├── deploy.sh      # Apply YAML → system
│   ├── dns.sh         # External DNS management
│   └── lib/           # Shared functions
├── docker/            # Docker service configurations
│   └── infisical/     # Infisical secrets management
├── docs/              # Documentation
│   └── install/       # Installation guides
│       ├── docker-infisical.md
│       ├── docker-n8n.md
│       └── docker-pihole.md
├── archives/          # Historical/outdated documents (14 files)
├── backups/           # Encrypted backups
└── .stems/            # Cluster methodology (optional)
```

---

**Philosophy**: `ssot/` contains truth, `tools/` operate on it. Cooperator-specific.
