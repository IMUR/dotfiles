# Service Configuration - Cooperator Node
**Created:** 2025-10-21
**Purpose:** Document crtr-specific service configurations (non-dotfiles)
**Node:** cooperator (192.168.254.10)

---

## Overview

This document tracks the configuration and setup of system services on the cooperator node. These are distinct from dotfiles (which are managed by chezmoi) and represent the infrastructure layer.

### Service Categories

1. **Reverse Proxy** - Caddy (HTTP/HTTPS ingress)
2. **Container Runtime** - Docker (application containers)
3. **System Management** - Cockpit (web-based admin UI)
4. **Secrets Management** - Infisical (environment variables, API keys)
5. **DNS/Ad-blocking** - Pi-hole (network-wide filtering)
6. **Applications** - n8n, postgres (workflow automation)

---

## Service Status

**Last Updated:** 2025-10-21

| Service | Status | Auto-start | Notes |
|---------|--------|------------|-------|
| docker.service | ✅ Running | ✅ Enabled | v28.5.1, user in docker group |
| caddy.service | ✅ Running | ✅ Enabled | Default config, needs reverse proxy setup |
| cockpit.service | ❌ Not installed | - | Need to install |
| pihole-FTL.service | ❌ Not installed | - | Need to install |
| infisical | ❌ Not running | - | Need to set up (docker or binary) |
| n8n (container) | ❌ Not running | - | Need to restore from backup |
| postgres (container) | ❌ Not running | - | Need to restore for n8n |

---

## 1. Caddy Reverse Proxy

### Purpose
- HTTPS termination with automatic Let's Encrypt certificates
- Reverse proxy to internal services
- Single entry point for all web services

### Current State
- **Installed:** ✅ Yes (system package)
- **Running:** ✅ Yes
- **Config:** `/etc/caddy/Caddyfile`
- **Current config:** Default (static file server on :80)

### Planned Configuration

Services to proxy:
1. **Cockpit** - System management UI (port 9090)
2. **Infisical** - Secrets management (port 8080 or custom)
3. **n8n** - Workflow automation (port 5678)
4. **Pi-hole** - DNS admin UI (port 80/443)

### Domain Strategy

**Options:**
1. **Subdomains** - cockpit.ism.la, infisical.ism.la, n8n.ism.la
2. **Paths** - ism.la/cockpit, ism.la/infisical, ism.la/n8n
3. **Ports** - cockpit.ism.la:9090 (direct)
4. **Internal only** - Use IP:port for local network only

**Recommendation:** Subdomains with automatic HTTPS (most professional, easiest to manage)

### Configuration Template

```caddyfile
# /etc/caddy/Caddyfile

# Main site
ism.la {
    root * /var/www/html
    file_server
}

# System management
cockpit.ism.la {
    reverse_proxy localhost:9090 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}

# Secrets management
infisical.ism.la {
    reverse_proxy localhost:8080
}

# Workflow automation
n8n.ism.la {
    reverse_proxy localhost:5678
}

# MCP server (if needed)
mcp.ism.la {
    reverse_proxy localhost:3000
}
```

### DNS Requirements

Before Caddy can get SSL certificates, DNS must point to this server:
```
ism.la          A     <PUBLIC_IP>
*.ism.la        A     <PUBLIC_IP>  (wildcard for subdomains)
```

**Current issue:** Caddy logs show HTTP challenge failures for ism.la and mcp.ism.la
- This means DNS is not properly configured OR
- Port 80/443 not accessible from internet

### Action Items
- [ ] Verify DNS records point to cooperator public IP
- [ ] Verify firewall allows port 80/443 inbound
- [ ] Configure Caddyfile with reverse proxies
- [ ] Reload Caddy: `sudo systemctl reload caddy`

---

## 2. Docker Configuration

### Current State
- **Installed:** ✅ Yes (v28.5.1)
- **Running:** ✅ Yes
- **User in docker group:** ✅ Yes
- **Containers running:** ❌ None
- **Images present:** ❌ None

### Docker Group Membership
```bash
$ groups
crtr ... docker ...
```
✅ User can run docker commands without sudo

### Planned Containers

#### n8n (Workflow Automation)
```yaml
# docker-compose.yml (n8n stack)
services:
  postgres:
    image: postgres:16-alpine
    container_name: n8n-postgres
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: <FROM_INFISICAL>
      POSTGRES_DB: n8n
    volumes:
      - n8n-postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: <FROM_INFISICAL>
      N8N_HOST: n8n.ism.la
      N8N_PORT: 5678
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://n8n.ism.la
    ports:
      - "5678:5678"
    volumes:
      - n8n-data:/home/node/.n8n
    depends_on:
      - postgres
    restart: unless-stopped

volumes:
  n8n-postgres-data:
  n8n-data:
```

#### Infisical (Secrets Management)
```yaml
# docker-compose.yml (infisical)
services:
  infisical:
    image: infisical/infisical:latest
    container_name: infisical
    ports:
      - "8080:8080"
    environment:
      # Config here
    volumes:
      - infisical-data:/app/data
    restart: unless-stopped

volumes:
  infisical-data:
```

### Action Items
- [ ] Create docker-compose.yml files
- [ ] Set up secrets management strategy
- [ ] Restore n8n database from backup (if available)
- [ ] Start containers
- [ ] Verify containers running: `docker ps`

---

## 3. Cockpit System Management

### Purpose
Web-based system administration interface for:
- System monitoring (CPU, memory, disk, network)
- Service management (systemctl via web)
- Container management (podman/docker integration)
- Log viewing
- Terminal access
- User management

### Installation

```bash
# Install cockpit
sudo apt update
sudo apt install -y cockpit cockpit-docker cockpit-podman

# Enable and start
sudo systemctl enable --now cockpit.socket

# Verify
sudo systemctl status cockpit
```

### Access
- **Local:** https://192.168.254.10:9090
- **Via Caddy:** https://cockpit.ism.la (after Caddy config)

### Security
- HTTPS only (self-signed cert by default)
- PAM authentication (use system users)
- Can integrate with SSH keys
- Consider firewall rules for external access

### Action Items
- [ ] Install cockpit packages
- [ ] Enable cockpit.socket
- [ ] Test local access: https://localhost:9090
- [ ] Configure Caddy reverse proxy
- [ ] Test external access via domain

---

## 4. Infisical Secrets Management

### Purpose
- Store environment variables securely
- Manage API keys, tokens, passwords
- Alternative to plaintext .env files
- Can sync secrets to applications

### Deployment Options

**Option A: Docker (Recommended)**
```bash
# Run infisical in docker
docker run -d \
  --name infisical \
  -p 8080:8080 \
  -v infisical-data:/app/data \
  --restart unless-stopped \
  infisical/infisical:latest
```

**Option B: Cloud (Infisical Cloud)**
- Use hosted version at app.infisical.com
- Free tier available
- No self-hosting required

**Option C: Binary Installation**
```bash
# Install infisical CLI
curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
sudo apt install infisical
```

### Integration with Docker Compose

```yaml
# Use infisical to inject secrets
services:
  n8n:
    # ... other config ...
    environment:
      DB_PASSWORD: ${DB_PASSWORD}  # Loaded from infisical
```

### Action Items
- [ ] Decide: Self-hosted docker vs Cloud
- [ ] If docker: Create docker-compose.yml
- [ ] If cloud: Sign up and configure
- [ ] Install infisical CLI
- [ ] Migrate secrets from ~/.git-credentials and other plaintext files
- [ ] Test secret injection

---

## 5. Pi-hole DNS & Ad-blocking

### Purpose
- Network-wide ad-blocking
- DNS server for cluster
- Query logging and statistics
- Custom DNS records for local services

### Installation

```bash
# One-line installer
curl -sSL https://install.pi-hole.net | bash

# Or manual:
sudo apt install pihole-FTL
```

### Configuration Decisions

1. **Upstream DNS:**
   - Cloudflare (1.1.1.1)
   - Google (8.8.8.8)
   - Quad9 (9.9.9.9)

2. **Interface:**
   - Listen on all interfaces
   - Or eth0 only (recommended for cluster)

3. **Web interface:**
   - Enable (recommended)
   - Access via http://<IP>/admin
   - Proxy via Caddy: pihole.ism.la

4. **DHCP:**
   - Disable (router handles DHCP)
   - Or enable if cooperator is DHCP server

### Local DNS Records

Add custom DNS for cluster services:
```
cooperator.local    192.168.254.10
crtr.local          192.168.254.10
projector.local     192.168.254.20
prtr.local          192.168.254.20
director.local      192.168.254.30
drtr.local          192.168.254.30
```

### Action Items
- [ ] Install Pi-hole
- [ ] Configure upstream DNS
- [ ] Set admin password
- [ ] Add custom DNS records
- [ ] Configure Caddy reverse proxy for web UI
- [ ] Test DNS resolution: `dig @localhost google.com`
- [ ] Update router/DHCP to use Pi-hole as DNS

---

## 6. n8n Workflow Automation

### Current State
- **Container:** ❌ Not running
- **Database:** ❌ Not running
- **Backup available:** ❓ Unknown (check migration backups)

### Restoration Steps

1. **Check for backup:**
   ```bash
   # From MIGRATION_INVENTORY.md:
   # docker exec n8n n8n export:workflow --all --output=/data/workflows-backup.json
   # docker exec n8n-postgres pg_dump -U postgres n8n > ~/migration/data/n8n-postgres.sql
   ```

2. **Create docker-compose.yml** (see Docker section above)

3. **Restore database (if backup exists):**
   ```bash
   # Start postgres first
   docker-compose up -d postgres

   # Restore database dump
   cat n8n-postgres.sql | docker exec -i n8n-postgres psql -U postgres -d n8n
   ```

4. **Start n8n:**
   ```bash
   docker-compose up -d n8n
   ```

5. **Verify:**
   ```bash
   docker ps
   curl http://localhost:5678
   ```

### Action Items
- [ ] Check for n8n backup files
- [ ] Create docker-compose.yml
- [ ] Start postgres container
- [ ] Restore database (if backup exists)
- [ ] Start n8n container
- [ ] Configure Caddy reverse proxy
- [ ] Test workflows

---

## Configuration Files Location

### Systemd Services
```
/etc/systemd/system/          # Custom service units
/usr/lib/systemd/system/      # Package-provided units
```

### Service Configs
```
/etc/caddy/Caddyfile          # Caddy reverse proxy
/etc/docker/daemon.json       # Docker daemon config
/etc/pihole/                  # Pi-hole configuration
```

### Docker Compose Files
```
~/docker/                     # Recommended location
├── n8n/
│   └── docker-compose.yml
├── infisical/
│   └── docker-compose.yml
└── ...
```

### Backups
```
~/migration/data/             # Migration backups
~/backups/                    # Ongoing backups
```

---

## Next Steps (Priority Order)

### Phase 1: Web Services Infrastructure (Today)
1. [ ] Install cockpit
2. [ ] Configure Caddy with reverse proxies
3. [ ] Verify DNS and SSL certificates
4. [ ] Test cockpit access via Caddy

### Phase 2: Secrets Management (Today/Tomorrow)
5. [ ] Choose infisical deployment method
6. [ ] Set up infisical (docker or cloud)
7. [ ] Configure Caddy proxy for infisical
8. [ ] Migrate plaintext secrets to infisical

### Phase 3: DNS & Network (This Week)
9. [ ] Install Pi-hole
10. [ ] Configure DNS upstream and local records
11. [ ] Set up Caddy proxy for Pi-hole admin
12. [ ] Update network to use Pi-hole DNS

### Phase 4: Application Restoration (This Week)
13. [ ] Check for n8n/postgres backups
14. [ ] Create docker-compose.yml for n8n stack
15. [ ] Restore database if backup exists
16. [ ] Start containers and verify
17. [ ] Configure Caddy proxy for n8n

---

## Useful Commands

### Caddy
```bash
# Test configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload without downtime
sudo systemctl reload caddy

# View logs
sudo journalctl -u caddy -f
```

### Docker
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Remove everything (careful!)
docker-compose down -v
```

### Cockpit
```bash
# Check status
sudo systemctl status cockpit.socket

# View logs
sudo journalctl -u cockpit
```

### Pi-hole
```bash
# Reconfigure
sudo pihole reconfigure

# Update gravity (blocklists)
sudo pihole updateGravity

# View logs
sudo pihole tail
```

---

## Security Considerations

1. **Firewall Rules**
   - Only expose necessary ports (80, 443)
   - Use Caddy for internal service access
   - Consider VPN for admin interfaces

2. **SSL/TLS**
   - Let's Encrypt automatic certificates via Caddy
   - Internal services can use Caddy's reverse proxy

3. **Secrets**
   - Use Infisical instead of plaintext files
   - Rotate secrets from old system
   - Never commit secrets to git

4. **Access Control**
   - Cockpit: PAM authentication
   - Pi-hole: Admin password
   - n8n: Basic auth or OAuth
   - Infisical: User accounts

---

**Last Updated:** 2025-10-21
**Next Review:** After Phase 1 completion
