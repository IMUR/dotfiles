# crtr-config

**Cooperator node (192.168.254.10) configuration state**

## What This Is

This repository defines the desired state of the cooperator node using YAML files.

- **state/*.yml** = source of truth (edit these)
- **config/** = generated or manual configs (deploy these)
- **scripts/** = utilities (export, validate, deploy, DNS)

## Quick Operations

### Export Current System State

```bash
./scripts/export-current.sh
git diff state/
```

### Validate State Files

```bash
./scripts/validate.sh
```

### Deploy Configs

```bash
sudo ./scripts/deploy.sh            # Deploy all
sudo ./scripts/deploy.sh caddy      # Deploy Caddy only
sudo ./scripts/deploy.sh pihole     # Deploy Pi-hole only
sudo ./scripts/deploy.sh systemd    # Deploy systemd units
sudo ./scripts/deploy.sh docker     # Deploy docker services
```

### Update DNS

```bash
./scripts/dns-update.sh
```

## State Files

| File | Purpose |
|------|---------|
| `state/services.yml` | Services that run (docker, systemd) |
| `state/domains.yml` | Domain routing (Caddy reverse proxy) |
| `state/network.yml` | Network config, DDNS, DNS overrides |
| `state/node.yml` | Node identity and hardware |

**Edit state files → Validate → Deploy**

## Config Files

Generated or manually maintained in `config/`:

- `config/caddy/Caddyfile` - Reverse proxy
- `config/pihole/local-dns.conf` - DNS overrides
- `config/systemd/*.service` - Systemd units
- `config/docker/*/docker-compose.yml` - Container definitions

## Backups

Snapshots in `backups/` organized by category.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/export-current.sh` | Pull live system state into state/ |
| `scripts/validate.sh` | Check state file syntax |
| `scripts/deploy.sh` | Deploy configs to system |
| `scripts/dns-update.sh` | Update DNS records |

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
├── state/             # Source of truth (edit these)
│   ├── services.yml
│   ├── domains.yml
│   ├── network.yml
│   └── node.yml
├── config/            # Deployable configs
│   ├── caddy/
│   ├── pihole/
│   ├── systemd/
│   └── docker/
├── scripts/           # Utilities
│   ├── export-current.sh
│   ├── validate.sh
│   ├── deploy.sh
│   └── dns-update.sh
├── backups/           # Snapshots
├── archives/          # Old files
└── .stems/            # Methodology (optional)
```

---

**That's it.** One node, one purpose: maintain cooperator configuration state.
