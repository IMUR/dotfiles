# Complete Flow Example: Adding n8n

This shows the entire flow from state definition to working service.

---

## 1. State Definition (Human Action)

### state/services.yml
```yaml
services:
  n8n:
    type: docker-compose
    image: n8nio/n8n:latest
    compose_file: config/docker/n8n/compose.yml
    port: 5678
    bind: 127.0.0.1  # Localhost only, proxied via Caddy
    data: /cluster-nas/services/n8n/data
    env_file: /cluster-nas/services/n8n/.env
    enabled: true
    restart: unless-stopped
    dependencies:
      - docker
      - nfs-kernel-server  # Requires /cluster-nas

  n8n-postgres:
    type: docker-compose
    image: postgres:16-alpine
    compose_file: config/docker/n8n/compose.yml  # Same compose file
    data: /cluster-nas/services/n8n/data/postgres
    enabled: true
    restart: unless-stopped
```

### state/domains.yml
```yaml
domains:
  - fqdn: n8n.ism.la
    service: n8n
    backend: localhost:5678
    type: sse  # Server-Sent Events - critical for n8n
    local_ip: 192.168.254.10
    external_dns: true
```

---

## 2. Schema Validation (Automatic)

```bash
$ ./tests/test-state.sh

Validating state/services.yml against .meta/schemas/service.schema.json
✓ n8n: valid
✓ n8n-postgres: valid

Validating state/domains.yml against .meta/schemas/domain.schema.json
✓ n8n.ism.la: valid
  - Backend matches bind address in services.yml
  - Type 'sse' is valid
  - Service 'n8n' exists in services.yml

State validation: PASSED
```

---

## 3. Config Generation (Automatic)

```bash
$ ./scripts/generate/regenerate-all.sh

Generating configs from state...

[1/4] Generating config/caddy/Caddyfile
  Source: state/domains.yml
  Template: .meta/generation/caddyfile.j2
  Output: config/caddy/Caddyfile
  ✓ Generated

[2/4] Generating config/pihole/local-dns.conf
  Source: state/domains.yml
  Template: .meta/generation/dns-overrides.j2
  Output: config/pihole/local-dns.conf
  ✓ Generated

[3/4] Generating config/docker/n8n/compose.yml
  Source: state/services.yml (n8n, n8n-postgres)
  Template: .meta/generation/docker-compose.j2
  Output: config/docker/n8n/compose.yml
  ✓ Generated

[4/4] Generating docs/SERVICES.md
  Source: state/services.yml + state/domains.yml
  Template: .meta/generation/services-doc.j2
  Output: docs/SERVICES.md
  ✓ Generated

Generation complete. Review files before deploying.
```

---

## 4. Generated Artifacts

### config/caddy/Caddyfile (excerpt)
```caddy
# GENERATED from state/domains.yml
# DO NOT EDIT MANUALLY - Edit state/domains.yml then regenerate
# Last generated: 2025-10-07 16:30:00

# n8n.ism.la - n8n workflow automation
n8n.ism.la {
    reverse_proxy localhost:5678 {
        flush_interval -1  # Required for Server-Sent Events (SSE)
    }
}
```

### config/pihole/local-dns.conf (excerpt)
```conf
# GENERATED from state/domains.yml
# DO NOT EDIT MANUALLY - Edit state/domains.yml then regenerate
# Last generated: 2025-10-07 16:30:00

# Local DNS overrides for cluster internal routing
address=/n8n.ism.la/192.168.254.10
```

### config/docker/n8n/compose.yml
```yaml
# GENERATED from state/services.yml
# DO NOT EDIT MANUALLY - Edit state/services.yml then regenerate
# Last generated: 2025-10-07 16:30:00

version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "127.0.0.1:5678:5678"
    volumes:
      - /cluster-nas/services/n8n/data/n8n:/home/node/.n8n
    env_file:
      - /cluster-nas/services/n8n/.env
    depends_on:
      - n8n-postgres
    networks:
      - n8n-network

  n8n-postgres:
    image: postgres:16-alpine
    container_name: n8n-postgres
    restart: unless-stopped
    volumes:
      - /cluster-nas/services/n8n/data/postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  n8n-network:
    driver: bridge
```

---

## 5. Deployment (One Command)

```bash
$ ./deploy/deploy service n8n

Deploying service: n8n
Source: state/services.yml
Generated configs validated: ✓

[1/6] Checking prerequisites
  ✓ Docker is running
  ✓ /cluster-nas is mounted
  ✓ NFS server is active

[2/6] Creating data directories
  mkdir -p /cluster-nas/services/n8n/data/n8n
  mkdir -p /cluster-nas/services/n8n/data/postgres
  ✓ Data directories created

[3/6] Deploying configuration files
  cp config/caddy/Caddyfile → /etc/caddy/Caddyfile
  cp config/pihole/local-dns.conf → /etc/dnsmasq.d/02-custom-local-dns.conf
  ✓ Configs deployed

[4/6] Starting services
  docker compose -f config/docker/n8n/compose.yml up -d
  Creating network "n8n-network"
  Creating n8n-postgres ... done
  Creating n8n          ... done
  ✓ Containers started

[5/6] Reloading gateway services
  systemctl reload caddy
  systemctl restart pihole-FTL
  ✓ Gateway services reloaded

[6/6] Verification
  ✓ Container n8n is running
  ✓ Container n8n-postgres is healthy
  ✓ Port 5678 is listening on 127.0.0.1
  ✓ DNS resolves n8n.ism.la → 192.168.254.10
  ✓ HTTPS endpoint https://n8n.ism.la is accessible
  ✓ Caddy reverse proxy is working
  ✓ SSE connection established (flush_interval verified)

Deployment complete!
Service: n8n
Status: Running
Access: https://n8n.ism.la

Time: 47 seconds
```

---

## 6. What If It Fails?

### Scenario: Port Already in Use

```bash
$ ./deploy/deploy service n8n

...
[4/6] Starting services
  docker compose -f config/docker/n8n/compose.yml up -d
  ERROR: Port 5678 is already allocated

Deployment failed at phase: Starting services

Troubleshooting:
  1. Check what's using port 5678:
     sudo ss -tlnp | grep 5678

  2. If another service is using it:
     - Edit state/services.yml to change n8n port
     - Regenerate configs: ./scripts/generate/regenerate-all.sh
     - Retry deployment

  3. If it's a leftover container:
     docker ps -a | grep 5678
     docker stop <container>
     docker rm <container>

Query AI assistant: "service port conflict"
See: .meta/ai/knowledge.yml → docker_container_not_starting
```

**AI Assistance** (automatic query):

From `.meta/ai/knowledge.yml`:
```yaml
docker_container_not_starting:
  common_causes:
    port_conflict:
      detection: "port is already allocated"
      solution: Change port in state/services.yml or stop conflicting container
```

---

## 7. AI-Assisted Troubleshooting

### User Reports Issue

**Symptom**: "n8n UI loads but doesn't show real-time updates"

### AI Query Process

1. **AI reads symptom**
2. **AI queries** `.meta/ai/knowledge.yml`
3. **AI finds match**:

```yaml
n8n_ui_not_updating:
  symptoms:
    - n8n interface loads but doesn't show real-time updates
    - Workflows execute but UI doesn't reflect changes
  root_cause:
    what: Server-Sent Events require unbuffered streaming
    why: Default Caddy buffering breaks SSE event stream
  solution:
    state_change:
      file: state/domains.yml
      field: type
      value: sse
    commands:
      - ./scripts/generate/regenerate-all.sh
      - ./deploy/deploy gateway
  verification:
    - Open n8n UI
    - Create new workflow
    - Verify real-time updates appear
```

4. **AI suggests exact fix**:

"The issue is that n8n uses Server-Sent Events (SSE) which require unbuffered HTTP streaming.

Fix:
1. Edit `state/domains.yml`
2. Find the n8n.ism.la entry
3. Change `type: standard` to `type: sse`
4. Regenerate configs: `./scripts/generate/regenerate-all.sh`
5. Deploy: `./deploy/deploy gateway`

This will add `flush_interval -1` to the Caddy reverse proxy configuration, enabling unbuffered streaming for SSE."

---

## 8. Documentation Generated Automatically

### docs/SERVICES.md (auto-generated excerpt)

```markdown
# Cooperator Services

*Auto-generated from state/services.yml and state/domains.yml*
*Last updated: 2025-10-07 16:35:00*

## n8n - Workflow Automation

**Status**: Enabled
**Type**: Docker Compose
**Port**: 5678 (bind: 127.0.0.1)
**Data**: /cluster-nas/services/n8n/data
**Access**: https://n8n.ism.la

**Configuration**:
- Service: n8n (n8nio/n8n:latest)
- Database: n8n-postgres (postgres:16-alpine)
- Network: n8n-network (bridge)
- Restart: unless-stopped

**Routing**:
- Domain: n8n.ism.la
- Backend: localhost:5678
- Type: SSE (Server-Sent Events)
- Local DNS: 192.168.254.10
- External DNS: CNAME → crtrcooperator.duckdns.org

**Dependencies**:
- docker (container runtime)
- nfs-kernel-server (requires /cluster-nas)

**Management**:
- Start: docker compose -f config/docker/n8n/compose.yml up -d
- Stop: docker compose -f config/docker/n8n/compose.yml down
- Logs: docker compose -f config/docker/n8n/compose.yml logs -f
- Status: docker ps | grep n8n

**Verification**:
- Container running: `docker ps | grep n8n`
- Port listening: `ss -tlnp | grep 5678`
- DNS resolves: `dig @localhost n8n.ism.la`
- HTTPS works: `curl -I https://n8n.ism.la`
```

---

## The Complete Flow Summary

```
1. Human edits state/*.yml
   ↓
2. Automatic schema validation
   ↓
3. Automatic config generation
   ↓
4. Human reviews generated configs
   ↓
5. ./deploy/deploy executes deployment
   ↓
6. Automatic verification
   ↓
7. If fails → AI-assisted troubleshooting
   ↓
8. Auto-generated documentation updated
```

**Key Points**:
- Edit state once, everything else flows automatically
- Validation before deployment prevents errors
- Generated configs are consistent and correct
- AI can troubleshoot using structured knowledge
- Documentation never out of sync

This is the schema-first, state-driven future.
