# Cooperator (crtr) Configuration Repository

Node-specific configuration management for **cooperator** (192.168.254.10), the gateway node of the Co-lab cluster.

## Quick Reference

- **Hostname**: cooperator / crtr
- **IP**: 192.168.254.10 (internal), 47.155.237.161 (external via crtrcooperator.duckdns.org)
- **Architecture**: ARM64 - Raspberry Pi 5
- **OS**: Debian 13 (Trixie)
- **Role**: Gateway, reverse proxy, DNS, NFS server

## Directory Structure

```
crtr-config/
├── CLAUDE.md              # AI assistant guidance
├── README.md              # This file
├── services/              # Service configurations
│   ├── caddy/            # Reverse proxy
│   ├── pihole/           # DNS/ad blocking
│   └── n8n/              # Workflow automation
├── network/
│   └── dns/              # DNS configs and zone files
├── docs/                 # Documentation
│   ├── network-spec.md   # Network specifications
│   └── n8n-deployment-plan.md
└── scripts/              # Node-specific scripts
```

## Key Services

### Gateway Services
- **Caddy** - Reverse proxy for all *.ism.la domains (ports 80, 443)
- **Pi-hole** - DNS server with ad blocking (port 53)
- **NFS** - Exports `/cluster-nas` (1.8TB) to cluster

### Running Services
- **n8n** - Workflow automation (https://n8n.ism.la)
- **Semaphore** - Ansible UI (https://smp.ism.la)
- **Cockpit** - System management (https://mng.ism.la)
- **GoTTY** - Web terminal (https://ssh.ism.la)
- **Atuin** - Shell history sync (port 8811)

## Configuration Locations

| Service | Config Path | Type |
|---------|-------------|------|
| Caddy | `/etc/caddy/Caddyfile` | Systemd |
| Pi-hole | `/etc/pihole/` | Systemd |
| DNS Overrides | `/etc/dnsmasq.d/02-custom-local-dns.conf` | Config |
| n8n | `/cluster-nas/services/n8n/` | Docker Compose |
| Cluster Storage | `/cluster-nas/` | NFS Export |

## Common Tasks

### Add New Service Domain

1. Add DNS override for local network
2. Add Caddy reverse proxy
3. Add external DNS CNAME (if needed)

See `CLAUDE.md` for detailed steps.

### Deploy Docker Service

1. Create directory in `/cluster-nas/services/<service>/`
2. Create `docker-compose.yml` and `.env`
3. Deploy with `docker compose up -d`
4. Add reverse proxy in Caddy

### Check Service Health

```bash
systemctl status caddy pihole-FTL
docker ps
df -h /cluster-nas
```

## Documentation

- `CLAUDE.md` - Detailed AI assistant guidance
- `docs/network-spec.md` - Complete network specifications
- `docs/n8n-deployment-plan.md` - n8n deployment reference
- Service-specific READMEs in `services/*/`

## Related Repositories

- **colab-config** (`~/Projects/colab-config/`) - Cluster-wide configurations
- **crtr-config** (this repo) - Cooperator-specific configurations

## Notes

- This repository tracks cooperator-specific configurations
- Live configs are on the system; this repo is for reference and version control
- Always backup configs before changes
- Test changes before applying (especially Caddy, Pi-hole)
