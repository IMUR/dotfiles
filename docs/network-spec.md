# Co-lab Cluster Network Specification

**Last Updated**: 2025-10-06
**Generated**: Auto-documented during n8n deployment

---

## Cluster Nodes

| Hostname | Short | IP Address | Architecture | Hardware | Role |
|----------|-------|------------|--------------|----------|------|
| cooperator | crtr | 192.168.254.10 | ARM64 (aarch64) | Raspberry Pi 5, 4-core, 16GB RAM | Gateway, NFS, DNS |
| projector | prtr | 192.168.254.20 | x86_64 | Multi-GPU (4x GPU) | Primary compute |
| director | drtr | 192.168.254.30 | x86_64 | Single GPU (1x GPU) | ML platform |

---

## Network Configuration

### External Access
| Type | Value |
|------|-------|
| Public IP | 47.155.237.161 |
| Dynamic DNS | crtrcooperator.duckdns.org |
| Domain | ism.la |

### Port Forwarding (Gateway)
| Port | Protocol | Service | Destination |
|------|----------|---------|-------------|
| 22 | TCP | SSH | cooperator |
| 80 | TCP | HTTP → HTTPS redirect | Caddy |
| 443 | TCP | HTTPS | Caddy |

### DNS Architecture
- **Primary DNS**: Pi-hole on cooperator (192.168.254.10:53)
- **Local DNS Overrides**: `/etc/dnsmasq.d/02-custom-local-dns.conf`
- **Custom Hosts**: `/etc/pihole/custom.list`
- **External Resolution**: `*.ism.la` CNAME → `crtrcooperator.duckdns.org` → Public IP

---

## Storage Configuration

### Cooperator (crtr)

| Device | Size | Mount Point | Filesystem | Usage | Purpose |
|--------|------|-------------|------------|-------|---------|
| /dev/sda2 | 931.4GB | / | ext4 | 19% (16GB used) | System |
| /dev/sdb1 | 1.8TB | /cluster-nas | XFS | 2% (21GB used) | Shared cluster storage |

**NFS Exports**: `/cluster-nas` (exported to cluster)

**Directory Structure** (`/cluster-nas`):
```
/cluster-nas/
├── services/          # Service configurations
│   ├── n8n/          # n8n workflow automation
│   └── semaphore/    # Ansible UI
├── backups/          # Cluster backups
├── configs/          # Shared configurations
├── projects/         # Project data
├── logs/             # Centralized logging
└── [other directories]
```

---

## Services Inventory

### Gateway Services (cooperator - 192.168.254.10)

#### Reverse Proxy (Caddy)
- **Service**: caddy.service (systemd)
- **Config**: `/etc/caddy/Caddyfile`
- **Ports**: 80 (HTTP), 443 (HTTPS), 2019 (admin)
- **TLS**: Let's Encrypt automatic certificates
- **Email**: admin@ism.la

#### DNS/Ad Blocking (Pi-hole)
- **Service**: pihole-FTL.service
- **Config**: `/etc/pihole/`
- **Port**: 53 (DNS), 8080 (Web UI)
- **Web UI**: https://dns.ism.la

#### System Management (Cockpit)
- **Port**: 9090
- **Access**: https://mng.ism.la

#### Configuration Management (Semaphore)
- **Service**: semaphore.service (systemd)
- **Binary**: /usr/local/bin/semaphore
- **Data**: /cluster-nas/services/semaphore/
- **Port**: 3000
- **Access**: https://smp.ism.la

#### Shell History Sync (Atuin)
- **Service**: atuin-server.service
- **Port**: 8811 (internal)
- **Data**: ~/.local/share/atuin/server.db

#### SSH Terminal (GoTTY)
- **Service**: gotty.service
- **Port**: 7681
- **Access**: https://ssh.ism.la
- **WebSocket**: Enabled

#### Workflow Automation (n8n)
- **Runtime**: Docker Compose
- **Location**: /cluster-nas/services/n8n/
- **Containers**: n8n, n8n-postgres
- **Port**: 127.0.0.1:5678 (localhost only)
- **Access**: https://n8n.ism.la
- **Database**: PostgreSQL 16 (Alpine)
- **Version**: n8n 1.113.3
- **Network**: n8n_n8n-network (bridge)

### Projector Services (192.168.254.20)

| Service | Port | Domain | Status |
|---------|------|--------|--------|
| Archon | 3737 | acn.ism.la, api.ism.la | Proxied via Caddy |
| Database | 54321 | dtb.ism.la | Proxied via Caddy |
| MCP | 8051 | mcp.ism.la | Proxied via Caddy |
| OpenWebUI | 8080 | cht.ism.la | Proxied via Caddy |
| Ollama | 11434 | - | Not running (tested 2025-10-06) |

### Other Services

| Service | IP | Port | Domain | Notes |
|---------|----|----|--------|-------|
| Barter | 192.168.254.123 | 80 | btr.ism.la | External node |

---

## Domain Mappings (*.ism.la)

### DNS Records (External - GoDaddy)
All `*.ism.la` subdomains use:
- **Type**: CNAME
- **Target**: crtrcooperator.duckdns.org
- **TTL**: 3600

### Local DNS Overrides (Pi-hole)
File: `/etc/dnsmasq.d/02-custom-local-dns.conf`

| Subdomain | Local IP | Purpose |
|-----------|----------|---------|
| dns.ism.la | 192.168.254.10 | Pi-hole Admin |
| cfg.ism.la | 192.168.254.10 | Grafana/Config UI |
| mng.ism.la | 192.168.254.10 | Cockpit Management |
| smp.ism.la | 192.168.254.10 | Semaphore Ansible UI |
| ssh.ism.la | 192.168.254.10 | GoTTY Terminal |
| n8n.ism.la | 192.168.254.10 | n8n Workflow Automation |
| sch.ism.la | 192.168.254.10 | (Purpose TBD) |
| acn.ism.la | 192.168.254.10 | Proxy to projector:3737 |
| api.ism.la | 192.168.254.10 | Proxy to projector:3737 |
| dtb.ism.la | 192.168.254.10 | Proxy to projector:54321 |
| mcp.ism.la | 192.168.254.10 | Proxy to projector:8051 |
| cht.ism.la | 192.168.254.10 | Proxy to projector:8080 |
| btr.ism.la | 192.168.254.123 | Barter service |

**Note**: Local network clients resolve to internal IPs, external clients resolve to public IP via CNAME.

---

## Container Runtime

### Cooperator

| Runtime | Version | Status | Notes |
|---------|---------|--------|-------|
| Docker | 28.5.0 | Active | Installed 2025-10-05 |
| Docker Compose | v2.39.4 | Active | Plugin version |
| Podman | 5.4.2 | Installed | Not actively used (rootless config incomplete) |

**Docker Networks**:
- `n8n_n8n-network` (172.x.x.x/24) - n8n services

**Docker Volumes**:
- Bind mounts to `/cluster-nas/services/n8n/data/`

---

## Caddy Configuration Patterns

### Standard HTTP Service
```caddy
service.ism.la {
    reverse_proxy localhost:PORT
}
```

### WebSocket Service (e.g., ssh.ism.la)
```caddy
service.ism.la {
    reverse_proxy localhost:PORT {
        header_up Upgrade {>Upgrade}
        header_up Connection {>Connection}
    }
}
```

### Server-Sent Events (e.g., n8n.ism.la)
```caddy
service.ism.la {
    reverse_proxy localhost:PORT {
        flush_interval -1
    }
}
```

### HTTPS Backend with TLS Skip
```caddy
service.ism.la {
    reverse_proxy https://localhost:PORT {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

### Cross-Node Proxy
```caddy
service.ism.la {
    reverse_proxy 192.168.254.XX:PORT
}
```

---

## Security Configuration

### TLS/SSL
- **Provider**: Let's Encrypt (via Caddy automatic HTTPS)
- **Certificate Email**: admin@ism.la
- **Renewal**: Automatic
- **Protocol**: TLS 1.3 preferred

### Firewall (Implied)
- External: Ports 22, 80, 443 forwarded
- Internal: All cluster nodes can communicate freely

### Service Isolation
- n8n: Bound to localhost only (127.0.0.1:5678)
- All external access via Caddy reverse proxy
- No direct container port exposure to network

---

## Known Issues & Limitations

### Resolved (2025-10-06)
- ✅ Docker not installed (resolved: Docker 28.5.0 installed)
- ✅ n8n WebSocket/SSE connection failing (resolved: added `flush_interval -1` to Caddy)
- ✅ Local DNS not resolving n8n.ism.la (resolved: added to Pi-hole local overrides)
- ✅ /var/log full (resolved: disabled PCP, freed 41MB)

### Current
- Ollama not running on projector (port 11434 connection refused as of 2025-10-06)
- Podman rootless configuration incomplete (newuidmap missing)
- Some planned services in `/home/crtr/Projects/colab-config/services/docker-compose.yml` not deployed (Prometheus, Grafana)

---

## Management Tools & Patterns

### Configuration Management
- **User Environment**: Chezmoi (dotfiles/)
- **System Automation**: Ansible (ansible/)
- **Service Management**: Docker Compose (services/)

### Monitoring
- **Planned**: Prometheus + Grafana (not deployed)
- **Current**: Cockpit web UI

### Backup Strategy
- **Location**: /cluster-nas/backups/
- **Method**: TBD

---

## Environment Variables (n8n Example)

**File**: `/cluster-nas/services/n8n/.env`

| Variable | Value | Purpose |
|----------|-------|---------|
| N8N_HOST | n8n.ism.la | Public hostname |
| N8N_PROTOCOL | https | Protocol |
| N8N_PORT | 5678 | Internal port |
| WEBHOOK_URL | https://n8n.ism.la/ | Webhook base URL |
| N8N_PUSH_BACKEND | websocket | Push notification method |
| VUE_APP_URL_BASE_API | https://n8n.ism.la/ | Frontend API base |
| DB_TYPE | postgresdb | Database type |
| POSTGRES_PASSWORD | [secret] | Database password |
| N8N_ENCRYPTION_KEY | [secret] | Credential encryption |
| TZ | UTC | Timezone |

---

## Network Diagnostics Reference

### DNS Testing
```bash
dig n8n.ism.la @192.168.254.10 +short  # Via Pi-hole
dig n8n.ism.la @8.8.8.8 +short         # Via Google DNS
```

### Connectivity Testing
```bash
curl -I https://n8n.ism.la             # HTTPS access
curl -I http://localhost:5678          # Direct service access
ping 192.168.254.XX                    # Node connectivity
```

### Service Status
```bash
systemctl status caddy                 # Caddy reverse proxy
systemctl status pihole-FTL            # Pi-hole DNS
docker ps                              # Container status
docker compose -f [path] logs          # Container logs
```

---

## Notes
- This document reflects configuration state as of n8n deployment (2025-10-06)
- Generated during troubleshooting and deployment session
- Subject to updates as cluster evolves
