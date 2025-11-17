# 🏗️ Architecture Design

## Cluster Node Roles

### cooperator (100.64.0.1, 192.168.254.10) - ARM64, Debian 13

- Docker Engine + Compose V2
- Samba server (`/media/crtr/fortress`)
- Infisical secrets (already running)
- Headscale coordinator
- Cockpit with Samba management (cockpit-identities + cockpit-file-sharing)
- Services: Caddy, Pi-hole, Gitea (new!)
- **Role:** Edge + Storage + Secrets + Registry

### director (100.64.0.2, 192.168.254.30) - x86_64, Debian 13

- Docker Engine + Compose V2
- Samba client (mounts fortress)
- Headscale client
- Services: Compute workloads, MCP containers
- **Role:** Compute + AI/ML

### projector (192.168.254.20) - Windows + WSL2

- Docker Desktop (Windows) OR Engine (WSL2)
- Samba client (native Windows)
- Headscale client
- Services: GPU workloads
- **Role:** GPU compute

### terminator (192.168.254.40) - macOS

- Docker Desktop (macOS)
- Samba client (native Finder)
- Headscale client
- Services: Development, GUI tools
- **Role:** Developer workstation

---

# 🎨 Integration Architecture

## Layer 1: Storage (Samba)

**On cooperator - Samba server:**

```
/media/crtr/fortress/
├── docker/              # Docker Compose files (chezmoi-managed)
│   ├── gitea/
│   ├── mcp/
│   └── shared-services/
├── data/                # Persistent volumes
│   ├── gitea-data/
│   ├── postgres/
│   └── minio/
└── cache/               # Shared build cache
```

**All nodes mount via Samba:**

- `//100.64.0.1/fortress` → `/mnt/fortress` (Linux)
- `\\100.64.0.1\fortress` → `Z:\` (Windows)
- `smb://100.64.0.1/fortress` → `/Volumes/fortress` (macOS)

**Management:** Cockpit File Sharing module at https://mng.ism.la

## Layer 2: Secrets (Infisical)

**Infisical "keys" project:**

```
/docker
  ├─ REGISTRY_USERNAME
  ├─ REGISTRY_PASSWORD
  └─ GITHUB_TOKEN

/gitea
  ├─ GITEA_ADMIN_PASSWORD
  ├─ GITEA_SECRET_KEY
  └─ GITEA_DB_PASSWORD

/samba
  └─ COLAB_NAS_SAMBA_PASSWORD (fortress mount credentials)

/mcp
  └─ OPENAI_API_KEY
```

**Compose integration:**

```
services:
  gitea:
    image: gitea/gitea:latest
    environment:
      - GITEA__database__PASSWD=${GITEA_DB_PASSWORD}
      - GITEA__security__SECRET_KEY=${GITEA_SECRET_KEY}
# ...
```

Run with Infisical:

```
infisical run --env=prod --path=/gitea -- docker compose up -d
```

## Layer 3: Networking (Headscale)

**Container network strategy:**

```
networks:
  cluster-local:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

  headscale:
    external: true
    name: tailscale
```

**Access patterns:**

- Local: `http://localhost:3000` → Caddy → service
- Cluster: `http://gitea.colab:3000` → Headscale mesh
- External: `https://git.ism.la` → Caddy → service

## Layer 4: Orchestration (Compose V2 + chezmoi)

```
~/.local/share/chezmoi/
├── dot_config/
│   └── docker/
│       ├── compose/
│       │   ├── gitea.yml.tmpl        # Node-specific templates
│       │   ├── mcp.yml.tmpl
│       │   └── shared.yml
│       └── config.json.tmpl
└── run_once_install-docker.sh.tmpl   # Bootstrap script
```

**Template example (gitea.yml.tmpl):**

```
version: "3.8"

services:
  gitea:
    image: gitea/gitea:{{ .docker.gitea_version | default "latest" }}
    volumes:
      {{ if eq .chezmoi.hostname "cooperator" }}
      - /media/crtr/fortress/data/gitea:/data
      {{ else }}
      - /mnt/fortress/data/gitea:/data
      {{ end }}
    networks:
      - cluster-local
    ports:
      - "3300:3000"
```

---

# 🚀 Implementation Roadmap

## Phase 1: Storage Foundation (Samba) ✅ COMPLETE

**Fortress Samba server configured on cooperator:**

- Device: `/dev/mmcblk0p1` (955GB flash, XFS filesystem)
- Mount: `/media/crtr/fortress`
- Share name: `fortress`
- Protocol: SMB3
- Workgroup: COLAB
- Credentials: User `crtr`, password in Infisical `/samba/COLAB_NAS_SAMBA_PASSWORD`
- Directory structure: `docker/`, `data/`, `cache/`
- Management: Cockpit File Sharing module at https://mng.ism.la

**Client mounts:**
- director (Linux): `/mnt/fortress` via CIFS fstab
- writer (Windows): `Z:\` via persistent network drive
- terminator (macOS): `/Volumes/fortress` via LaunchAgent

---

## Phase 2: Docker Compose V2 Standardization

1. Ensure Compose V2 on all nodes:

   **Via mise (recommended):**

   ```
   # ~/.config/mise/config.toml (chezmoi-managed)
   [tools]
   docker-compose = "2.40.3"
   ```

   **Manual install (fallback):**

   ```
   sudo curl -SL https://github.com/docker/compose/releases/download/v2.40.3/docker-compose-linux-$(uname -m) -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

   **Verify:**

   ```
   docker compose version
   ```

2. Configure Docker daemon for cluster:

   ```
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     },
     "storage-driver": "overlay2",
     "insecure-registries": ["git.ism.la:5000"],
     "registry-mirrors": ["http://git.ism.la:5000"]
   }
   ```

---

## Phase 3: Gitea Deployment (First Service)

1. Create Compose file:

   ```
   version: "3.8"
   services:
     gitea-db:
       image: postgres:16-alpine
       restart: always
       environment:
         - POSTGRES_USER=gitea
         - POSTGRES_PASSWORD=${GITEA_DB_PASSWORD}
         - POSTGRES_DB=gitea
       volumes:
         - /mnt/fortress/data/postgres-gitea:/var/lib/postgresql/data
       networks:
         - gitea-internal

     gitea:
       image: gitea/gitea:1.21-rootless
       restart: always
       depends_on:
         - gitea-db
       environment:
         - USER_UID=1000
         - USER_GID=1000
         - GITEA__database__DB_TYPE=postgres
         - GITEA__database__HOST=gitea-db:5432
         - GITEA__database__NAME=gitea
         - GITEA__database__USER=gitea
         - GITEA__database__PASSWD=${GITEA_DB_PASSWORD}
         - GITEA__security__SECRET_KEY=${GITEA_SECRET_KEY}
         - GITEA__server__DOMAIN=git.ism.la
         - GITEA__server__ROOT_URL=https://git.ism.la/
         - GITEA__server__SSH_DOMAIN=git.ism.la
         - GITEA__server__SSH_PORT=2222
       volumes:
         - /mnt/fortress/data/gitea:/var/lib/gitea
         - /mnt/fortress/data/gitea-config:/etc/gitea
         - /etc/timezone:/etc/timezone:ro
         - /etc/localtime:/etc/localtime:ro
       ports:
         - "3300:3000"
         - "2222:2222"
       networks:
         - gitea-internal
         - cluster-local

   networks:
     gitea-internal:
       driver: bridge
     cluster-local:
       external: true
   ```

2. Deploy with Infisical:

   ```
   cd ~/.config/docker/compose
   infisical run --env=prod --path=/gitea -- docker compose -f gitea.yml up -d
   ```

3. Add domain to SSOT:

   ```
   # ssot/state/domains.yml
   - fqdn: git.ism.la
     service: gitea
     backend: localhost:3300
     type: standard
     local_ip: 192.168.254.10
     external_dns: true
   ```

---

## Phase 4: MCP Integration (AI/ML Toolkit)

1. Deploy MCP:

   ```
   version: "3.8"
   services:
     ollama:
       image: ollama/ollama:latest
       restart: always
       volumes:
         - /mnt/fortress/data/ollama:/root/.ollama
       ports:
         - "11434:11434"
       deploy:
         resources:
           reservations:
             devices:
               - driver: nvidia
                 count: all
                 capabilities: [gpu]

     open-webui:
       image: ghcr.io/open-webui/open-webui:main
       restart: always
       environment:
         - OLLAMA_BASE_URL=http://ollama:11434
       volumes:
         - /mnt/fortress/data/open-webui:/app/backend/data
       ports:
         - "8080:8080"
       depends_on:
         - ollama

   networks:
     default:
       name: cluster-local
       external: true
   ```

2. Access via Headscale:

   ```
   curl http://director.colab:11434/api/tags
   ```

---

## Phase 5: chezmoi Integration

- Add Compose files:

  ```
  chezmoi add ~/.config/docker/compose/gitea.yml
  chezmoi add ~/.config/docker/compose/mcp.yml
  chezmoi add --template ~/.config/docker/daemon.json
  ```

- Example bootstrap script (`run_once_install-docker-stack.sh.tmpl`):

  ```
  #!/bin/bash
  set -euo pipefail

  echo "Bootstrapping Docker stack on {{ .chezmoi.hostname }}..."

  {{ if eq .chezmoi.os "linux" }}
  sudo apt update
  sudo apt install -y docker.io docker-compose-v2 cifs-utils
  {{ end }}

  {{ if ne .chezmoi.hostname "cooperator" }}
  sudo mkdir -p /mnt/fortress
  echo "//100.64.0.1/fortress /mnt/fortress cifs credentials=/home/{{ .chezmoi.username }}/.smbcredentials,uid=1000,gid=1000,_netdev,x-systemd.automount 0 0" | sudo tee -a /etc/fstab
  sudo mount /mnt/fortress
  {{ end }}

  mkdir -p ~/.config/docker/compose
  chezmoi apply

  echo "✓ Docker stack ready on {{ .chezmoi.hostname }}"
  ```

---

## Phase 6: Unified Workflow

- Deploy service (any node):

  ```
  cd ~/.config/docker/compose
  infisical run --env=prod --path=/gitea -- docker compose -f gitea.yml up -d
  # Or via mise-managed script
  mise run deploy:gitea
  ```

- mise task definition:

  ```
  # ~/.config/mise/config.toml
  [tasks.deploy]
  gitea = "cd ~/.config/docker/compose && infisical run --env=prod --path=/gitea -- docker compose -f gitea.yml up -d"
  mcp   = "cd ~/.config/docker/compose && infisical run --env=prod --path=/mcp -- docker compose -f mcp.yml up -d"
  ```

---

# 🎯 Final Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Headscale Mesh (100.64.0.0/16)           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ cooperator   │  │  director    │  │  terminator  │      │
│  │ (ARM64)      │  │  (x86_64)    │  │  (macOS)     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          │ Samba Server     │ Samba Client     │ Samba Client
          │                  │                  │
    ┌─────▼──────────────────▼──────────────────▼──────┐
    │         fortress (Shared Storage - 955GB)        │
    │  ┌─────────────┬─────────────┬──────────────┐   │
    │  │ docker/     │ data/       │ cache/       │   │
    │  │ (Compose)   │ (Volumes)   │ (Builds)     │   │
    │  └─────────────┴─────────────┴──────────────┘   │
    │  Managed via Cockpit File Sharing (mng.ism.la)  │
    └──────────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼───┐      ┌────▼───┐     ┌────▼───┐
    │ Gitea  │      │  MCP   │     │ Minio  │
    │ (repo) │      │ (AI)   │     │ (S3)   │
    └────┬───┘      └────┬───┘     └────┬───┘
         │               │              │
         └───────────────┼──────────────┘
                         │
                    ┌────▼────┐
                    │Infisical│
                    │(Secrets)│
                    └─────────┘
```

---

## ★ Insight

- **Storage-first architecture:** Fortress (Samba) provides the shared state layer on high-performance flash storage, allowing Compose files and persistent data to live in one place, managed by cooperator, consumed by all nodes.
- **Web-based management:** Cockpit File Sharing module eliminates manual smb.conf editing—manage shares, users, and permissions via web UI.
- **Secrets at deploy-time:** Infisical injects credentials only as services start—no secrets leak into Compose files, chezmoi, or git.
- **Headscale as service mesh:** Every container can reach every other container via stable DNS names (`service.colab`), turning your physical cluster into a logical cluster mesh.
