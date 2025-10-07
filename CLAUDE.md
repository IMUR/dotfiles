# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**crtr-config** is a declarative Infrastructure-as-Code repository for the cooperator node (192.168.254.10), the gateway of a 3-node Co-lab cluster. This repository uses an **aspect-based architecture** to define system state declaratively and provide reproducible deployment.

### Node Profile: Cooperator (crtr)

- **IP**: 192.168.254.10 (internal), 47.155.237.161 (external via crtrcooperator.duckdns.org)
- **Hardware**: Raspberry Pi 5 (ARM64, 4-core, 16GB RAM)
- **OS**: Debian 13 (Trixie)
- **Role**: Cluster gateway - reverse proxy (Caddy), DNS (Pi-hole), NFS server
- **Storage**: 931GB USB (OS) + 1.8TB NVMe (/cluster-nas)

## Architecture: Aspect-Based Configuration

This repository organizes configuration by **technical aspects** (domains of system functionality) rather than by service or application. Each aspect defines desired state, deployment procedure, and verification.

### Aspect Structure

```
aspects/
├── systemd/                    # All systemd services
│   ├── aspect.yml             # Service definitions and state
│   ├── deploy.md              # How to achieve this state
│   └── verify.sh              # Test that state is achieved
└── user-environment/          # User-level configuration
    ├── aspect.yml
    ├── deploy.md
    └── verify.sh
```

**Aspect Pattern**:
- `aspect.yml` - Declarative state definition (what should exist)
- `deploy.md` - Imperative deployment steps (how to achieve state)
- `verify.sh` - Validation script (how to test state is correct)

### The Seven Aspects

See `ASPECTS.md` and `COOPERATOR-ASPECTS.md` for complete breakdown:

1. **BASE SYSTEM** - OS, packages, system configuration
2. **STORAGE** - Disks, filesystems, mounts, NFS exports
3. **NETWORK** - Interfaces, IPs, DNS client/server
4. **SERVICES** - Systemd units and Docker containers
5. **GATEWAY** - Caddy reverse proxy, domain routing
6. **USER ENVIRONMENT** - Shell, dotfiles, user tools
7. **SECURITY** - SSH, permissions, secrets, firewall

### State Declaration Files

```
state/
├── system.yml        # Identity, network, storage, users
├── services.yml      # All running services
├── domains.yml       # Domain → service mappings
└── network.yml       # DNS overrides, cluster connectivity
```

These files declare the **desired state** of the system. They are the source of truth.

## Key Commands

### Service Management

```bash
# Gateway services (systemd)
sudo systemctl status caddy pihole-FTL nfs-kernel-server
sudo systemctl reload caddy              # Preferred for config changes
sudo caddy validate --config /etc/caddy/Caddyfile

# Custom services (systemd)
systemctl status atuin-server semaphore gotty

# Docker services
docker ps
docker compose -f /cluster-nas/services/n8n/docker-compose.yml logs -f
docker compose -f /cluster-nas/services/n8n/docker-compose.yml up -d
```

### Configuration Testing

```bash
# Validate Caddy configuration before applying
sudo caddy validate --config /etc/caddy/Caddyfile

# Test DNS resolution
dig @localhost n8n.ism.la +short          # Should return 192.168.254.10
dig @8.8.8.8 n8n.ism.la +short            # Should return external IP

# Reload DNS after changes
sudo systemctl restart pihole-FTL

# Check NFS exports
showmount -e localhost
```

### Aspect Verification

```bash
# Run aspect verification scripts
./aspects/systemd/verify.sh
./aspects/user-environment/verify.sh

# Check overall health
systemctl --failed                        # Should show no failed units
docker ps --filter "status=exited"       # Should be empty
df -h /cluster-nas                       # Check storage
```

## Configuration Locations

| Component | Live Location | Repo Reference | Backup |
|-----------|---------------|----------------|--------|
| Caddy config | `/etc/caddy/Caddyfile` | `services/caddy/` | `/etc/caddy/Caddyfile.backup.*` |
| Pi-hole config | `/etc/pihole/` | `services/pihole/` | `/etc/pihole/config_backups/` |
| DNS overrides | `/etc/dnsmasq.d/02-custom-local-dns.conf` | `network/dns/` | - |
| NFS exports | `/etc/exports` | `state/system.yml` | - |
| Systemd units | `/etc/systemd/system/*.service` | `aspects/systemd/` | - |
| Docker services | `/cluster-nas/services/*/` | `services/*/` | Version controlled |

**Important**: Live configs on the system are the source of truth. This repo provides templates and reference configurations.

## Adding a New Service

This is a multi-aspect operation:

### 1. SERVICES Aspect - Deploy the service

```bash
# For Docker service
mkdir -p /cluster-nas/services/myservice
cd /cluster-nas/services/myservice
# Create docker-compose.yml with service bound to 127.0.0.1:PORT
docker compose up -d
```

### 2. GATEWAY Aspect - Add reverse proxy

```bash
# Edit /etc/caddy/Caddyfile
sudo vim /etc/caddy/Caddyfile

# Add block (choose appropriate pattern):
myservice.ism.la {
    reverse_proxy localhost:PORT
}

# For WebSocket support:
myservice.ism.la {
    reverse_proxy localhost:PORT {
        header_up Upgrade {>Upgrade}
        header_up Connection {>Connection}
    }
}

# For Server-Sent Events (SSE):
myservice.ism.la {
    reverse_proxy localhost:PORT {
        flush_interval -1
    }
}

# Validate and reload
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

### 3. NETWORK Aspect - Add DNS override

```bash
# Add local DNS override
echo "address=/myservice.ism.la/192.168.254.10" | \
  sudo tee -a /etc/dnsmasq.d/02-custom-local-dns.conf

sudo systemctl restart pihole-FTL

# Test resolution
dig @localhost myservice.ism.la +short
```

### 4. Update Repository State

```bash
# Update state/services.yml
# Update state/domains.yml
# Update aspects/systemd/aspect.yml (if systemd service)
# Commit changes
```

## Reverse Proxy Patterns

### Standard HTTP Service
```caddy
service.ism.la {
    reverse_proxy localhost:PORT
}
```

### WebSocket Support
```caddy
service.ism.la {
    reverse_proxy localhost:PORT {
        header_up Upgrade {>Upgrade}
        header_up Connection {>Connection}
    }
}
```

### Server-Sent Events (SSE)
```caddy
service.ism.la {
    reverse_proxy localhost:PORT {
        flush_interval -1
    }
}
```

### HTTPS Backend
```caddy
service.ism.la {
    reverse_proxy https://localhost:PORT {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

### Cross-Node Proxy (to projector/director)
```caddy
service.ism.la {
    reverse_proxy 192.168.254.XX:PORT
}
```

## Security Principles

### Port Binding Strategy
- **Localhost only** (`127.0.0.1:PORT`): Services accessed via Caddy reverse proxy
- **Cluster-wide** (`0.0.0.0:PORT`): DNS (53), Atuin (8811), NFS (2049)
- **Public** (`0.0.0.0:PORT`): Only SSH (22), HTTP (80), HTTPS (443)

### Secrets Management
- Never commit `.env` files with secrets
- Store secrets in `/cluster-nas/services/<service>/.env` (not in git)
- Use `.env.template` files in repo as examples
- DuckDNS token in `~/duckdns/duck.sh` (needs improvement)

## Development Workflow

### Making Configuration Changes

1. **Test on microSD clone first** (if available)
2. **Backup configs** before editing
3. **Validate** before applying (Caddy, systemd units)
4. **Reload** rather than restart when possible
5. **Update repo** to match live configs
6. **Commit** with descriptive message

### Testing Changes

```bash
# Check service status
systemctl status <service>
journalctl -u <service> -n 50

# Check network access
curl -I https://service.ism.la
curl http://localhost:PORT        # Direct access test

# Check DNS
dig @localhost service.ism.la +short

# Check logs
journalctl -u caddy -f
docker compose logs -f <service>
```

## Troubleshooting

### Service Won't Start
```bash
journalctl -u <service> -n 50     # Check logs
sudo ss -tlnp | grep PORT         # Check port conflicts
systemctl list-dependencies <service>  # Check dependencies
```

### DNS Issues
```bash
pihole status                     # Check Pi-hole status
cat /etc/dnsmasq.d/02-custom-local-dns.conf | grep service
dig @localhost service.ism.la
sudo systemctl restart pihole-FTL
```

### HTTPS Certificate Issues
```bash
journalctl -u caddy -n 50         # Check Caddy logs
dig service.ism.la @8.8.8.8       # Verify external DNS
sudo systemctl reload caddy
```

### WebSocket/SSE Connection Drops
- Verify Caddy config has appropriate headers/flush_interval
- Check browser console for connection errors
- Test direct access: `curl -I http://localhost:PORT`

## Cluster Context

### Network Topology
```
192.168.254.0/24 (cluster network)
├── 192.168.254.10 - cooperator (gateway)
├── 192.168.254.20 - projector  (services)
└── 192.168.254.30 - director   (workloads)
```

### Cooperator's Role
- **Gateway**: All *.ism.la domains route through cooperator
- **DNS**: Pi-hole serves DNS for entire cluster
- **NFS**: Exports /cluster-nas to other nodes
- **Reverse Proxy**: Caddy proxies to local and remote services

### Cross-Node Services
Cooperator proxies several services running on projector:
- `acn.ism.la` → `192.168.254.20:3737` (Archon)
- `dtb.ism.la` → `192.168.254.20:54321` (Database)
- `mcp.ism.la` → `192.168.254.20:8051` (MCP)
- `cht.ism.la` → `192.168.254.20:8080` (OpenWebUI)

## Related Documentation

- `BUILD-PLAN.md` - Comprehensive rebuild architecture (in progress)
- `ASPECTS.md` - Overview of the 7 technical aspects
- `COOPERATOR-ASPECTS.md` - Complete aspect breakdown with all configs
- `docs/network-spec.md` - Network specifications
- `docs/n8n-deployment-plan.md` - n8n deployment reference

## Related Repositories

- **colab-config** (`~/Projects/colab-config/`) - Cluster-wide configurations
- This repository is cooperator-specific; changes here should not break other nodes

## Notes for AI Assistants

- **Backup before changes**: Always create `.backup` files for critical configs
- **Validate before applying**: Use validation commands (caddy validate, etc.)
- **Update repo after changes**: Keep this repo in sync with live configs
- **Aspect interactions**: Consider multi-aspect impact when making changes
- **Test thoroughly**: Check logs, status, and actual connectivity after changes
