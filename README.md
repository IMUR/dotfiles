# crtr-config

**Cooperator node (192.168.254.10) configuration state**

## What This Is

Single source of truth for cooperator node configuration using YAML state files.

- **state/*.yml** = source of truth (edit these)
- **tools/ssot** = coherent SSOT tool (discover, validate, diff, deploy)
- **backups/** = historical snapshots

## Quick Operations

### Discover Live State

```bash
./tools/ssot/ssot discover
git diff state/
```

### Validate State Files

```bash
./tools/ssot/ssot validate
```

### Compare State vs Live

```bash
./tools/ssot/ssot diff
```

### Deploy State to Live

```bash
sudo ./tools/ssot/ssot deploy --all
sudo ./tools/ssot/ssot deploy --service=caddy
```

### DNS Operations

```bash
./tools/ssot/ssot dns --update
```

### Help

```bash
./tools/ssot/ssot --help
```

## SSOT Tool

**Purpose**: Maintain coherence between state/ (desired) and live system (actual)

| Command | Purpose | Why It Exists |
|---------|---------|---------------|
| `discover` | Extract live → state/ | Capture running system truth |
| `validate` | Check state/ correctness | Catch errors before deployment |
| `diff` | Compare state vs live | See drift, verify deployment |
| `deploy` | Apply state/ → live | Materialize desired state |
| `dns` | Manage DNS records | External dependency (GoDaddy) |

## State Files

| File | Purpose |
|------|---------|
| `state/services.yml` | Services that run (docker, systemd) |
| `state/domains.yml` | Domain routing (Caddy reverse proxy) |
| `state/network.yml` | Network config, DDNS, DNS overrides |
| `state/node.yml` | Node identity and hardware |

**Workflow**: Edit state/ → Validate → Deploy → Verify

## Backups

Historical snapshots in `backups/` organized by category.

## Methodology

See `.stems/` for cluster management methodology and patterns (optional reference).

## External Repositories

- **Dotfiles**: github.com/IMUR/dotfiles (chezmoi-managed user environment)
- **Cluster**: /home/crtr/Projects/colab-config (cluster-wide config)

## Node Spec

- **Name**: cooperator (crtr)
- **IP**: 192.168.254.10 (internal), 47.155.237.161 (external)
- **Role**: Gateway (Caddy, Pi-hole, NFS server)
- **Hardware**: Raspberry Pi 5, ARM64, 16GB RAM
- **OS**: Debian 13 (Trixie)
- **Storage**: 931GB USB (OS) + 1.8TB NVMe (/cluster-nas)

## Repository Structure

```
crtr-config/
├── README.md          # This file
├── state/             # Source of truth
│   ├── services.yml   # What runs
│   ├── domains.yml    # Routing
│   ├── network.yml    # Network
│   └── node.yml       # Identity
├── tools/ssot/        # SSOT tool
│   ├── ssot           # Main CLI
│   ├── commands/      # Subcommands
│   └── lib/           # Shared code
├── backups/           # Snapshots
├── archives/          # Old files
├── dotfiles/          # User env (submodule)
└── .stems/            # Methodology
```

---

**Philosophy**: One tool (`ssot`), one purpose (maintain state coherence), cooperator-specific.
