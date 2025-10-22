# Infisical Secrets Management Setup
**Created:** 2025-10-21
**Purpose:** Fresh Infisical deployment with best practices
**Domain:** env.ism.la
**Port:** 8081 (internal)

---

## Architecture Decision

### Cluster Context
- **cooperator (crtr)**: Gateway node - runs Caddy, DNS, services
- **director (drtr)**: Available via SSH+sudo
- **terminator (trtr)**: Available via SSH+sudo
- **projector (prtr)**: Hardware issues, unavailable
- **zerouter (zrtr)**: Down

### Deployment Strategy

**Option A: Single Infisical Instance on Cooperator (Recommended)**
- ✅ Simple: One source of truth
- ✅ Already has Caddy (env.ism.la configured)
- ✅ Central management from gateway node
- ✅ Nodes pull secrets via CLI
- ⚠️ Single point of failure (acceptable for 3-node cluster)

**Option B: Replicated Across Nodes**
- More complex, requires database replication
- Overkill for small cluster
- Not recommended for initial setup

**Decision: Option A - Single instance on cooperator**

---

## Installation Plan

### Step 1: Create Infisical Docker Setup

```bash
# Create service directory
mkdir -p ~/docker/infisical
cd ~/docker/infisical
```

### Step 2: Docker Compose Configuration

**File: `~/docker/infisical/docker-compose.yml`**
```yaml
version: '3.8'

services:
  infisical:
    image: infisical/infisical:latest
    container_name: infisical
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:8080"  # Internal only, Caddy proxies
    environment:
      # Site configuration
      - SITE_URL=https://env.ism.la
      - TELEMETRY_ENABLED=false

      # Database (embedded SQLite for simplicity)
      - DB_CONNECTION_URI=file:/data/infisical.db

      # Encryption keys (IMPORTANT: Generate unique keys!)
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - AUTH_SECRET=${AUTH_SECRET}

      # Redis (optional, for caching - can add later)
      # - REDIS_URL=redis://redis:6379

    volumes:
      - infisical-data:/data
    networks:
      - infisical-net

volumes:
  infisical-data:
    driver: local

networks:
  infisical-net:
    driver: bridge
```

### Step 3: Generate Secure Keys

```bash
# Generate encryption key (32 bytes, hex encoded)
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Generate auth secret (32 bytes, hex encoded)
AUTH_SECRET=$(openssl rand -hex 32)

# Create .env file
cat > ~/docker/infisical/.env << EOF
ENCRYPTION_KEY=${ENCRYPTION_KEY}
AUTH_SECRET=${AUTH_SECRET}
EOF

# Secure the .env file
chmod 600 ~/docker/infisical/.env

# IMPORTANT: Backup these keys securely!
echo "Backup these keys in a secure location (password manager):"
echo "ENCRYPTION_KEY=${ENCRYPTION_KEY}"
echo "AUTH_SECRET=${AUTH_SECRET}"
```

### Step 4: Start Infisical

```bash
cd ~/docker/infisical
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

### Step 5: Access & Initialize

1. **Via Caddy (once running):** https://env.ism.la
2. **Direct (testing):** http://localhost:8081

**Initial Setup:**
- Create admin account
- Set up organization (e.g., "co-lab")
- Create projects:
  - `cooperator` (crtr node secrets)
  - `director` (drtr node secrets)
  - `terminator` (trtr node secrets)
  - `cluster-shared` (shared secrets)

---

## Organization Structure

### Recommended Hierarchy

```
Organization: co-lab
├── Project: cooperator
│   ├── Environment: production
│   │   ├── N8N_ENCRYPTION_KEY
│   │   ├── POSTGRES_PASSWORD
│   │   ├── GITHUB_TOKEN
│   │   └── ...
│   └── Environment: development
│
├── Project: director
│   ├── Environment: production
│   └── ...
│
├── Project: terminator
│   └── ...
│
└── Project: cluster-shared
    ├── NFS_MOUNT_PASSWORD (if needed)
    ├── CLUSTER_SSH_KEY (if centralizing)
    └── DUCKDNS_TOKEN
```

---

## CLI Installation on All Nodes

### On cooperator (already has docker running infisical)

```bash
# Install infisical CLI
curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
sudo apt-get install -y infisical

# Verify
infisical --version

# Login (interactive)
infisical login

# This opens browser to env.ism.la for authentication
# Saves token to ~/.config/infisical/
```

### On director and terminator

```bash
# SSH to each node
ssh drtr
ssh trtr

# Same installation commands
curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
sudo apt-get install -y infisical
infisical --version
infisical login  # Authenticate via env.ism.la
```

---

## Usage Patterns

### Pattern 1: Inject Secrets into Docker Compose

**Before (plaintext .env):**
```bash
# Bad: .env file with plaintext secrets
cat n8n/.env
POSTGRES_PASSWORD=mypassword123
N8N_ENCRYPTION_KEY=secretkey456
```

**After (Infisical):**
```bash
# Good: Secrets pulled from Infisical
cd ~/docker/n8n
infisical run --env=production -- docker-compose up -d

# Or export to .env file (for compatibility)
infisical export --env=production --format=dotenv > .env
docker-compose up -d
```

### Pattern 2: Use Secrets in Scripts

```bash
#!/bin/bash
# Script that needs secrets

# Pull secrets into environment
eval $(infisical export --env=production --format=shell)

# Now use secrets
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/...
```

### Pattern 3: Service-Specific Secrets

```yaml
# docker-compose.yml
services:
  myapp:
    environment:
      # Reference secrets (injected by infisical run)
      - DB_PASSWORD=${DB_PASSWORD}
      - API_KEY=${API_KEY}
```

```bash
# Run with infisical
infisical run --env=production -- docker-compose up -d
```

---

## Secrets Migration Plan

### Step 1: Identify Current Plaintext Secrets

```bash
# On cooperator
~/docker/n8n/.env
~/.git-credentials
~/.ssh/config (if contains passwords)
```

### Step 2: Add to Infisical

Via Web UI (env.ism.la):
1. Navigate to Project → cooperator → Environment → production
2. Add each secret:
   - Key: `POSTGRES_PASSWORD`
   - Value: `<actual password>`
   - Description: "PostgreSQL password for n8n database"

### Step 3: Update Service Deployments

```bash
# Update n8n to use infisical
cd ~/docker/n8n

# Backup old .env
cp .env .env.backup

# Update docker-compose.yml if needed
# Then run with infisical
infisical run --env=production -- docker-compose up -d
```

### Step 4: Remove Plaintext Secrets

```bash
# After verifying services work with infisical
rm ~/docker/n8n/.env.backup
# Rotate old passwords in Infisical
```

---

## Service Integration - n8n Example

### Update n8n Docker Compose

**File: `/media/crtr/crtr-data/services/n8n/docker-compose.yml`**

Add comment at top:
```yaml
# Secrets managed via Infisical
# Run with: infisical run --env=production -- docker-compose up -d
# Project: cooperator, Environment: production

version: '3.8'
services:
  postgres:
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}  # From Infisical

  n8n:
    environment:
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}  # From Infisical
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}  # From Infisical
```

### Create Systemd Service (Optional)

**File: `/etc/systemd/system/n8n.service`**
```ini
[Unit]
Description=n8n Workflow Automation
Requires=docker.service
After=docker.service network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/media/crtr/crtr-data/services/n8n
ExecStart=/usr/local/bin/infisical run --env=production -- /usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=crtr
Group=crtr

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable n8n.service
sudo systemctl start n8n.service
```

---

## Backup Strategy

### What to Backup

1. **Infisical Database:** `/var/lib/docker/volumes/infisical_infisical-data/`
2. **Encryption Keys:** `~/docker/infisical/.env` (CRITICAL!)
3. **Organization Structure:** Export secrets regularly

### Backup Commands

```bash
# Stop infisical
cd ~/docker/infisical
docker-compose down

# Backup volume
sudo tar czf ~/backups/infisical-data-$(date +%Y%m%d).tar.gz \
  /var/lib/docker/volumes/infisical_infisical-data/

# Backup keys (encrypted)
tar czf - ~/docker/infisical/.env | \
  gpg --symmetric --cipher-algo AES256 -o ~/backups/infisical-keys-$(date +%Y%m%d).tar.gz.gpg

# Restart
docker-compose up -d
```

### Export Secrets (Disaster Recovery)

```bash
# Export all secrets to JSON (store securely!)
infisical export --env=production --format=json > ~/backups/secrets-$(date +%Y%m%d).json

# Encrypt it
gpg --symmetric --cipher-algo AES256 ~/backups/secrets-$(date +%Y%m%d).json
rm ~/backups/secrets-$(date +%Y%m%d).json
```

---

## Security Best Practices

### Access Control

1. **Web UI Access:**
   - Use strong admin password
   - Enable 2FA (recommended)
   - Create separate users for team members
   - Use role-based access (admin, developer, read-only)

2. **CLI Access:**
   - Each node authenticates independently
   - Tokens stored in `~/.config/infisical/`
   - Tokens can be revoked via web UI

3. **Network Security:**
   - Infisical only listens on 127.0.0.1:8081
   - External access only via Caddy (HTTPS + auth)
   - Consider adding basic auth to Caddy for env.ism.la

### Caddy Basic Auth (Optional)

```caddyfile
# /etc/caddy/Caddyfile
env.ism.la {
    basicauth {
        admin $2a$14$hashed_password_here
    }
    reverse_proxy localhost:8081
}
```

Generate hash:
```bash
caddy hash-password
```

---

## Monitoring & Maintenance

### Check Infisical Status

```bash
# Container status
docker ps | grep infisical

# Logs
docker logs -f infisical

# Resource usage
docker stats infisical
```

### Regular Tasks

- **Weekly:** Review access logs
- **Monthly:** Rotate sensitive secrets
- **Quarterly:** Full backup and disaster recovery test
- **Yearly:** Update Infisical version

---

## Disaster Recovery

### Scenario: Cooperator Node Fails

1. **Stand up new cooperator:**
   ```bash
   # Install docker
   # Restore infisical backup
   sudo tar xzf infisical-data-backup.tar.gz -C /

   # Restore keys
   gpg --decrypt infisical-keys.tar.gz.gpg | tar xzf - -C ~/

   # Start infisical
   cd ~/docker/infisical
   docker-compose up -d
   ```

2. **Other nodes:** No changes needed, they connect to env.ism.la (update DNS if IP changed)

### Scenario: Lost Encryption Keys

- **With backup:** Restore from encrypted backup
- **Without backup:** ⚠️ ALL SECRETS ARE LOST (emphasizes importance of backups!)

---

## Next Steps

1. ✅ Create `~/docker/infisical/` directory
2. ✅ Generate encryption keys
3. ✅ Create docker-compose.yml
4. ✅ Start Infisical container
5. ✅ Access env.ism.la and create admin account
6. ✅ Set up organization structure
7. ✅ Install CLI on all nodes
8. ✅ Migrate n8n secrets
9. ✅ Test and verify
10. ✅ Backup encryption keys

---

**Status:** Ready to implement
**Priority:** HIGH (needed for secure n8n deployment)
