# n8n Deployment Guide for Cooperator (crtr)

**Target Node**: cooperator.ism.la (192.168.254.10)  
**Known Hardware**: Raspberry Pi 5, ARM64, 4-core, 16GB RAM  
**Storage Available**: 1TB internal NVMe + 2TB external USB 3.0 NVMe  
**Guide Type**: Collaborative - make decisions based on what you discover  
**Date**: 2025-10-05

---

## Overview & Goals

You're setting up n8n as a workflow orchestrator on your cooperator node. The goal is to:
- Run n8n with PostgreSQL for reliable storage
- Connect to Ollama on projector for LLM workflows
- Keep data isolated and easily backed up
- Integrate with your existing Caddy/DNS setup

**Key principle**: This guide provides options and decision points, not rigid commands. Adapt based on what you discover during deployment.

---

## Architecture Concept

```
┌─────────────────────────────────────────────────────────────┐
│                    Cooperator (crtr)                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Existing Services (already running)                  │  │
│  │  • Pi-hole, Caddy, NFS, Cockpit, Semaphore           │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  New: n8n Stack (location TBD)                       │  │
│  │  ┌─────────────────┐  ┌──────────────────┐          │  │
│  │  │   PostgreSQL    │  │      n8n         │          │  │
│  │  │   :5432         │◄─┤   :5678          │          │  │
│  │  └─────────────────┘  └──────────────────┘          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ API Calls over cluster network
                           ▼
        ┌──────────────────────────────────────┐
        │   Projector (prtr) - 192.168.254.20  │
        │   • Ollama :11434 (if running)        │
        └──────────────────────────────────────┘
```

---

## Decision Point 1: Storage Location

You mentioned a 2TB USB drive. Let's figure out where to put n8n data.

### Option A: External USB Drive (Recommended)
**Pros**: Isolated, portable, lots of space, easy backups  
**Cons**: USB dependency, slightly slower than internal

**Discovery needed**:
```bash
# Find your USB drive
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE

# Look for ~2TB drive - probably /dev/sda or similar
# Check if it's already mounted
df -h | grep -i usb
mount | grep -i sda
```

**Questions to answer**:
- Is the USB drive already mounted somewhere?
- Does it have a filesystem already? (ext4, xfs, etc.)
- Is there existing data you need to preserve?
- What's the current mount point (if any)?

### Option B: Internal NVMe
**Pros**: Faster, no USB dependency  
**Cons**: Shares space with system, harder to migrate

### Option C: NFS Share
**Pros**: Centralized storage, accessible from multiple nodes  
**Cons**: Network dependency, potential performance impact

**Decision framework**: 
- If USB is available and empty → Option A
- If USB has data you can't move → Consider subdirectory or Option B
- If you want high availability → Option C
- If unsure → Start with Option B, migrate later

---

## Decision Point 2: Mount Strategy (If using USB)

Once you've identified the USB drive, decide how to mount it.

### Discover Current State
```bash
# Is it already mounted?
mount | grep <device>

# What filesystem does it have?
sudo blkid /dev/<device>

# Can you mount it temporarily?
sudo mkdir -p /mnt/test
sudo mount /dev/<device> /mnt/test
ls -la /mnt/test
sudo umount /mnt/test
```

### Mounting Options

**Temporary mount** (test first):
```bash
sudo mkdir -p /mnt/n8n-data
sudo mount /dev/<device> /mnt/n8n-data
```

**Persistent mount** (after testing):
```bash
# Get UUID
sudo blkid /dev/<device>

# Add to /etc/fstab
# UUID=xxx /mnt/n8n-data ext4 defaults,nofail 0 2
```

**Consider**:
- Use `nofail` option so boot doesn't hang if USB is unplugged
- Check permissions after mounting
- Verify write access with a test file

---

## Decision Point 3: Directory Organization

Where should Docker volumes live?

### Discover Your Preferences
Consider your existing patterns:
```bash
# Where do other services keep data?
ls -la /var/lib/docker/volumes/
ls -la /opt/
ls -la /srv/
ls -la ~/
```

### Suggested Structure (Adapt as needed)
```
<storage-location>/
├── docker/            # Docker compose files
│   └── n8n/
│       ├── docker-compose.yml
│       └── .env
├── data/              # Persistent volumes
│   ├── postgres/
│   └── n8n/
├── backups/           # (Optional) Local backups
└── logs/              # (Optional) Centralized logs
```

**Or simpler**:
```
~/n8n/                 # Project files
├── docker-compose.yml
└── .env

<storage-location>/n8n-data/  # Just data
├── postgres/
└── n8n/
```

Choose based on:
- Your organizational preferences
- Existing directory conventions
- Backup strategy
- Whether you use /cluster-nas for shared configs

---

## Decision Point 4: Docker Setup Discovery

Before creating the compose file, understand your current Docker setup.

### Check Current State
```bash
# Is Docker installed?
docker --version
docker compose version  # Note: might be 'docker-compose' (older) or 'docker compose' (newer)

# What's already running?
docker ps

# Where are volumes stored?
docker volume ls
docker system info | grep -i "Docker Root Dir"

# Any existing networks?
docker network ls
```

### Questions to Answer:
- Do you use `docker compose` (plugin) or `docker-compose` (standalone)?
- Are there naming conventions you follow for containers/networks?
- Do you already have a postgres container running?
- Where do you typically store docker-compose.yml files?
- Do you use Docker volumes or bind mounts for other services?

---

## Decision Point 5: Port Allocation

n8n needs port 5678 exposed. Check what's available.

### Check Port Availability
```bash
# Is 5678 in use?
sudo ss -tlnp | grep 5678
sudo lsof -i :5678

# What ports are currently in use?
sudo ss -tlnp | grep LISTEN
```

### Port Options:
- **5678** (default): Use if available
- **Different port**: If 5678 is taken, choose another (update compose file)
- **Behind proxy only**: Don't expose directly, only through Caddy

**Consider**:
- Will you access n8n directly or only through Caddy?
- Do you want metrics exposed on a separate port?
- Are there firewall rules to consider?

---

## Decision Point 6: Caddy Integration

You have Caddy running. Let's figure out how to integrate.

### Discover Caddy Configuration
```bash
# Where is Caddyfile?
sudo find /etc -name "Caddyfile" 2>/dev/null
sudo find /opt -name "Caddyfile" 2>/dev/null

# Is Caddy running in Docker or system service?
systemctl status caddy 2>/dev/null
docker ps | grep caddy

# What's the current config pattern?
# (You'll need to look at existing Caddyfile)
```

### Integration Approaches:

**Option A: Add to existing Caddyfile**
- Pro: Centralized config
- Con: Need to reload Caddy

**Option B: Separate config file (if Caddy supports imports)**
- Pro: Isolated, modular
- Con: Need to verify import support

**Option C: Docker network sharing**
- Pro: Caddy can reach n8n by container name
- Con: Need shared network

**Things to check**:
- Do other services use `*.ism.la` domains?
- How is SSL/TLS currently handled?
- Is there existing authentication pattern?
- Does Caddy run on same Docker network or host network?

---

## Docker Compose Template

Here's a flexible template. **Adapt based on your decisions above.**

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: n8n-postgres  # Choose your naming convention
    restart: unless-stopped
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}  # Use .env file
      - POSTGRES_DB=n8n
    volumes:
      # DECISION: Choose volume strategy
      # Option A: Named volume
      # - postgres-data:/var/lib/postgresql/data
      # Option B: Bind mount to specific path
      # - /your/chosen/path/postgres:/var/lib/postgresql/data
      - ${DATA_PATH}/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -h localhost -U n8n -d n8n']
      interval: 5s
      timeout: 5s
      retries: 10
    networks:
      - n8n-network  # Or your preferred network name

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n  # Choose your naming convention
    restart: unless-stopped
    ports:
      # DECISION: Expose port or not?
      - "${N8N_PORT:-5678}:5678"  # Use env var with default
    environment:
      # Database Configuration
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      
      # n8n Configuration
      - N8N_HOST=${N8N_HOST:-n8n.ism.la}  # Adjust domain
      - N8N_PORT=5678
      - N8N_PROTOCOL=${N8N_PROTOCOL:-https}
      - NODE_ENV=production
      - WEBHOOK_URL=${WEBHOOK_URL:-https://n8n.ism.la/}
      
      # Execution Settings - ADJUST BASED ON USAGE
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=${EXEC_MAX_AGE:-168}  # Days, default 7
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=${SAVE_SUCCESS:-none}  # or 'all'
      - EXECUTIONS_DATA_SAVE_ON_PROGRESS=false
      
      # Performance - TUNE AS NEEDED
      - N8N_PAYLOAD_SIZE_MAX=16
      - EXECUTIONS_TIMEOUT=300
      - EXECUTIONS_TIMEOUT_MAX=3600
      
      # Optional: Metrics
      - N8N_METRICS=${ENABLE_METRICS:-false}
      
      # Timezone - ADJUST TO YOUR LOCATION
      - GENERIC_TIMEZONE=${TZ:-America/Los_Angeles}
      - TZ=${TZ:-America/Los_Angeles}
      
    volumes:
      # DECISION: Same as postgres - choose strategy
      - ${DATA_PATH}/n8n:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
    # OPTIONAL: Resource limits - adjust based on monitoring
    # deploy:
    #   resources:
    #     limits:
    #       cpus: '2.0'
    #       memory: 2G
    networks:
      - n8n-network

networks:
  n8n-network:
    # DECISION: Create new or use existing?
    # driver: bridge
    # OR: external: true (if using existing network)
```

### Companion .env File Template

```bash
# Storage paths - SET BASED ON YOUR DECISIONS
DATA_PATH=/path/you/chose/for/data

# Security - GENERATE STRONG VALUES
POSTGRES_PASSWORD=your_secure_password_here
N8N_ENCRYPTION_KEY=generate_with_openssl_rand_hex_32

# Network configuration - ADJUST TO YOUR SETUP
N8N_HOST=n8n.ism.la
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.ism.la/
N8N_PORT=5678

# Optional settings
TZ=America/Los_Angeles
EXEC_MAX_AGE=168
SAVE_SUCCESS=none
ENABLE_METRICS=true
```

---

## Deployment Approach (Flexible Steps)

### Phase 1: Preparation
1. **Review decisions** you've made above
2. **Create project directory** somewhere logical
3. **Copy template files** and customize based on decisions
4. **Generate secure passwords**
5. **Test configuration** syntax

### Phase 2: Initial Deployment
1. **Start with just postgres** first to verify database works
2. **Check postgres logs** for any issues
3. **Add n8n** once postgres is healthy
4. **Monitor startup logs** for problems

### Phase 3: Integration
1. **Test local access** (http://localhost:5678 or configured port)
2. **Configure Caddy** based on your integration decision
3. **Test external access** through domain
4. **Verify SSL/TLS** is working

### Phase 4: Configuration
1. **Access web interface**
2. **Create admin account**
3. **Configure initial settings**
4. **Test Ollama connection** (if projector is ready)

---

## Testing & Verification Framework

Rather than specific commands, here's what to verify:

### Container Health
- [ ] Both containers show "Up" status
- [ ] No restart loops in logs
- [ ] Healthcheck passing for postgres
- [ ] n8n responding on configured port

### Network Connectivity
- [ ] Containers can communicate
- [ ] Can reach from host machine
- [ ] Can reach through Caddy (if configured)
- [ ] DNS resolves correctly

### Data Persistence
- [ ] Create test workflow → Stop containers → Restart → Workflow still exists
- [ ] Database survives container restart
- [ ] Credentials stored properly

### External Integration
- [ ] Can access UI through browser
- [ ] Ollama connection test (create simple workflow)
- [ ] Webhook URLs work if using them

---

## Monitoring Strategy

### What to Watch Initially

**Container stats**:
```bash
docker stats --no-stream <container-names>
```

**Disk usage growth**:
```bash
# Check your data path
du -sh <data-path>/*
```

**Database size** (after you have some executions):
```bash
docker compose exec postgres \
  psql -U n8n -c "SELECT pg_size_pretty(pg_database_size('n8n'));"
```

**Execution count**:
```bash
docker compose exec postgres \
  psql -U n8n -c "SELECT COUNT(*) FROM execution_entity;"
```

### Performance Indicators
- Memory usage stable or growing?
- CPU spikes during workflow execution (expected) or constant (problem)?
- Disk growing at expected rate?
- Response time acceptable?

---

## Troubleshooting Framework

### If Container Won't Start
1. Check logs: `docker compose logs <service>`
2. Verify paths exist and permissions correct
3. Check environment variables are set
4. Try starting just postgres first

### If Can't Connect
1. Verify port is actually open: `docker compose ps`
2. Check from container: `docker compose exec n8n curl localhost:5678`
3. Check from host machine
4. Check through Caddy
5. Review firewall/network rules

### If Ollama Connection Fails
1. Verify Ollama is running on projector
2. Test connectivity: `curl http://192.168.254.20:11434/api/tags`
3. Check if containers can reach projector from n8n
4. Review network configuration

---

## Backup Considerations

Rather than prescriptive backup script, consider:

### What Needs Backup?
- PostgreSQL database (workflows, credentials, history)
- n8n data directory (files, configs)
- docker-compose.yml and .env files
- Caddy configuration (if modified)

### Backup Approaches:
- **Database dump**: Export postgres data
- **Volume backup**: Copy entire data directories
- **Workflow export**: Use n8n's built-in export
- **Snapshot**: If using certain filesystems

### Backup Frequency:
- Critical workflows: Daily or more
- Development/testing: Weekly or as-needed
- Before updates: Always

---

## Next Steps After Successful Deployment

1. **Document your decisions** - what paths, ports, configurations you chose
2. **Create a simple test workflow** - verify Ollama connection
3. **Set up your first real automation** - something useful but not critical
4. **Monitor for a few days** - watch resource usage, adjust as needed
5. **Plan backup strategy** - based on how you're actually using it
6. **Consider monitoring/alerting** - if this becomes critical

---

## Key Principles for This Deployment

✅ **Discover before deciding** - look at what's actually on the system  
✅ **Test incrementally** - one service at a time  
✅ **Monitor and adjust** - tune based on actual usage  
✅ **Document as you go** - note what you actually did  
✅ **Start conservative** - can always add features later  

---

## Resources & References

- **n8n Documentation**: https://docs.n8n.io
- **n8n Docker**: https://docs.n8n.io/hosting/installation/docker/
- **PostgreSQL**: https://hub.docker.com/_/postgres
- **Your cluster architecture**: Check your existing docs

---

**Guide Version**: 2.0 (Flexible)  
**Created**: 2025-10-05  
**Philosophy**: Collaborative decision-making during deployment  
**Estimated Time**: 1-3 hours depending on discoveries and decisions


