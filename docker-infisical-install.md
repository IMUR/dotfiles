# Infisical Installation
**Service:** Infisical Secrets Management
**Domain:** env.ism.la
**Port:** 8081 (internal)
**Updated:** 2025-10-21

---

## Prerequisites

- Docker and docker-compose installed ✓
- Caddy configured (env.ism.la → localhost:8081) ✓
- Directory: `~/docker/infisical/`

---

## Installation Steps

### 1. Create Directory Structure

```bash
mkdir -p ~/docker/infisical
cd ~/docker/infisical
```

### 2. Create docker-compose.yml

**File:** `~/docker/infisical/docker-compose.yml`

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: infisical-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=infisical
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=infisical
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - infisical-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U infisical"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: infisical-redis
    restart: unless-stopped
    networks:
      - infisical-net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  infisical:
    image: infisical/infisical:latest
    container_name: infisical
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      - NODE_ENV=production
      - SITE_URL=https://env.ism.la
      - TELEMETRY_ENABLED=false
      - DB_CONNECTION_URI=postgres://infisical:${POSTGRES_PASSWORD}@postgres:5432/infisical
      - REDIS_URL=redis://redis:6379
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - AUTH_SECRET=${AUTH_SECRET}
      - JWT_AUTH_SECRET=${JWT_AUTH_SECRET}
      - JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
    networks:
      - infisical-net

volumes:
  postgres-data:

networks:
  infisical-net:
    driver: bridge
```

### 3. Generate Encryption Keys

```bash
cd ~/docker/infisical

# Generate secure random keys
POSTGRES_PASSWORD=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
AUTH_SECRET=$(openssl rand -hex 32)
JWT_AUTH_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)

# Create .env file
cat > .env << EOF
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
AUTH_SECRET=${AUTH_SECRET}
JWT_AUTH_SECRET=${JWT_AUTH_SECRET}
JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
EOF

# Secure permissions
chmod 600 .env
```

### 4. Backup Keys (CRITICAL!)

```bash
# Create encrypted backup
tar czf - .env | gpg --symmetric --cipher-algo AES256 -o ~/backups/infisical-keys-$(date +%Y%m%d).tar.gz.gpg

# Store password in password manager!
```

### 5. Start Services

```bash
cd ~/docker/infisical
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f infisical
```

### 6. Verify

```bash
# Check containers running
docker ps | grep infisical

# Test local access
curl -I http://localhost:8081

# Test via Caddy (once DNS configured)
curl -k -I https://env.ism.la
```

---

## Initial Configuration

1. Open https://env.ism.la (or http://192.168.254.10:8081)
2. Create admin account
3. Set up organization: "co-lab"
4. Create first project: "cooperator"

---

## Maintenance Commands

```bash
cd ~/docker/infisical

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

## Troubleshooting

**Container won't start:**
```bash
docker-compose logs infisical
```

**Database issues:**
```bash
docker-compose logs postgres
docker exec -it infisical-postgres psql -U infisical -c '\l'
```

**Reset (WARNING: Deletes all data):**
```bash
docker-compose down -v
# Re-run installation from step 5
```

---

**Status:** Ready to install
**Next:** After installation, see `docker-infisical-usage.md` for CLI setup and secret management
