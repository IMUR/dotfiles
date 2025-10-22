# n8n Installation
**Service:** n8n Workflow Automation
**Domain:** n8n.ism.la
**Port:** 5678 (internal)
**Updated:** 2025-10-21

---

## Prerequisites

- Docker and docker-compose installed ✓
- Caddy configured (n8n.ism.la → localhost:5678) ✓
- Infisical running (for secrets) - Optional but recommended
- Directory: `/media/crtr/crtr-data/services/n8n/`
- Existing setup found: ✓

---

## Installation Steps

### 1. Verify Existing Setup

```bash
# Check if data exists from old system
ls -la /media/crtr/crtr-data/services/n8n/

# Expected:
# - docker-compose.yml
# - .env (or will use Infisical)
# - data/ directory
```

### 2. Review docker-compose.yml

**File:** `/media/crtr/crtr-data/services/n8n/docker-compose.yml`

Already exists - verify it points to correct paths.

### 3. Secrets Setup

**Option A: Use Infisical (Recommended)**

Add secrets to Infisical:
- Project: cooperator
- Environment: production
- Secrets:
  - `POSTGRES_PASSWORD`
  - `N8N_ENCRYPTION_KEY`
  - `N8N_HOST=n8n.ism.la`
  - `N8N_PROTOCOL=https`
  - `WEBHOOK_URL=https://n8n.ism.la`
  - `TZ=America/Los_Angeles`

**Option B: Use .env file**

Check existing `.env` file:
```bash
cat /media/crtr/crtr-data/services/n8n/.env
```

### 4. Mount /cluster-nas

n8n docker-compose expects `/cluster-nas` mount:

```bash
# Check if crtr-data is the NAS
ls -la /media/crtr/crtr-data/

# Create symlink or mount point
sudo mkdir -p /cluster-nas
sudo mount --bind /media/crtr/crtr-data /cluster-nas

# Or add to /etc/fstab for permanent mount
echo "/media/crtr/crtr-data /cluster-nas none bind 0 0" | sudo tee -a /etc/fstab
```

### 5. Start n8n

**With Infisical:**
```bash
cd /media/crtr/crtr-data/services/n8n
infisical run --env=production -- docker-compose up -d
```

**Without Infisical:**
```bash
cd /media/crtr/crtr-data/services/n8n
docker-compose up -d
```

### 6. Verify

```bash
# Check containers
docker ps | grep n8n

# Check logs
docker logs -f n8n
docker logs -f n8n-postgres

# Test access
curl -I http://localhost:5678
```

---

## Post-Installation

1. Access https://n8n.ism.la
2. Verify workflows are intact
3. Test a simple workflow
4. Check database connection

---

## Maintenance Commands

```bash
cd /media/crtr/crtr-data/services/n8n

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Update
docker-compose pull
docker-compose up -d
```

---

## Backup

```bash
# Backup workflows (export from n8n UI)
# Or backup postgres database:
docker exec n8n-postgres pg_dump -U n8n n8n > ~/backups/n8n-db-$(date +%Y%m%d).sql
```

---

**Status:** Ready to restore (data exists)
**Location:** `/media/crtr/crtr-data/services/n8n/`
