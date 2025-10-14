# crtr-config

**Cooperator node (192.168.254.10) configuration state**

## What This Is

Single source of truth for cooperator node configuration.

- **ssot/state/** = the source of truth (edit these YAML files)
- **tools/** = utilities that operate on ssot/ (discover, validate, deploy)
- **backups/** = historical snapshots

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
├── ssot/              # Single source of truth
│   └── state/         # Current state files
│       ├── services.yml
│       ├── domains.yml
│       ├── network.yml
│       └── node.yml
├── tools/             # Utilities (operate on ssot/)
│   ├── ssot           # Main CLI
│   ├── discover.sh    # Extract live → ssot/
│   ├── validate.sh    # Check ssot/
│   ├── diff.sh        # Compare ssot/ vs live
│   ├── deploy.sh      # Apply ssot/ → live
│   ├── dns.sh         # DNS management
│   └── lib/           # Shared functions
├── backups/           # Historical snapshots
├── archives/          # Old files
├── dotfiles/          # User env (submodule)
└── .stems/            # Methodology
```

---

**Philosophy**: `ssot/` contains truth, `tools/` operate on it. Cooperator-specific.
