# Colab Cluster Architecture

**Version:** 1.0
**Purpose:** Operational structure for heterogeneous cluster running Docker services with shared storage, secrets management, and mesh networking.

---

## Node Roles

**cooperator** (ARM64, Debian 13)

- Edge services and storage server
- Runs: Caddy, Pi-hole, Infisical, Headscale, Gitea, Cockpit, MCP servers (3-4)
- Hosts: Fortress Samba server (955GB flash storage)
- Network: 100.64.0.1 (Headscale)

**director** (x86_64, Debian 13)

- Compute node for CPU-intensive workloads
- Runs: AI/ML services, compute containers, workload processing
- Mounts: Fortress via Samba client
- Network: 100.64.0.2 (Headscale)

**writer** (x86_64, Windows 11 + WSL2)

- Windows/WSL2 workloads
- Runs: Windows-specific containers, development services
- Mounts: Fortress as network drive
- Network: 100.64.0.4 (Headscale)

**projector** (x86_64, Windows + WSL2)

- GPU compute node (NVIDIA)
- Runs: GPU workloads, CUDA containers
- Status: Currently offline (on-demand)
- Network: 100.64.0.7 (Headscale)

**terminator** (ARM64, macOS)

- Developer workstation and cluster management
- Runs: Development tools, admin interfaces
- Mounts: Fortress via SMB
- Network: 100.64.0.6 (Headscale)

**Network:** All nodes connected to same ethernet switch (192.168.254.0/24) plus Headscale mesh overlay (100.64.0.0/16)

---

## Storage Architecture

### Fortress (Shared Storage)

**Server:** Cooperator hosts Samba server
**Device:** mmcblk0 (955GB flash, XFS filesystem)
**Performance:** 91 MB/s sequential read
**Mount:** `/media/crtr/fortress` on cooperator

**Clients:**

- Director: `/mnt/fortress` (CIFS mount, fstab + systemd automount)
- Writer: `Z:\` (persistent network drive)
- Terminator: `/Volumes/fortress` (LaunchAgent auto-mount)

**Credentials:** Username `crtr`, password stored in Infisical

**Directory Structure:**

```
fortress/
├── docker/     # Compose files, service configs
├── data/       # Persistent volumes (databases, repos, uploads)
└── cache/      # Shared artifacts, temporary data
```

### Hybrid Storage Strategy

**Shared on Fortress:**

- Docker Compose files
- Persistent application data (databases, git repositories, user uploads)
- Service configurations
- Shared state that must survive node restart

**Local on Each Node:**

- Docker images and layers (`/var/lib/docker/overlay2`)
- Build cache (`/var/lib/docker/buildx`)
- Container logs (`/var/lib/docker/containers`)
- Temporary files and scratch space

**Rationale:** Network storage has latency. Docker build operations generate thousands of small I/O operations. Keeping image layers and build cache local prevents saturating network bandwidth and improves performance.

---

## Secrets Management

**Tool:** Infisical
**Method:** Runtime injection only, never written to disk

**How It Works:**

1. Secrets stored in Infisical (cloud or self-hosted)
2. Organized by service path (`/gitea`, `/samba`, `/mcp`)
3. At deployment: `infisical run --env=prod --path=/service -- docker compose up -d`
4. Infisical injects secrets as environment variables in command execution context
5. Docker Compose passes env vars to containers
6. Secrets exist in container memory only

**Why Not .env Files:**

- Files on disk can be committed to git, backed up, exposed in logs
- Runtime injection keeps secrets ephemeral

**Current Secrets:**

- `/samba/COLAB_NAS_SAMBA_PASSWORD` = fortress mount credentials
- Additional service secrets added as services deploy

---

## Networking

**Physical:** Ethernet switch (192.168.254.0/24)
**Overlay:** Headscale mesh (100.64.0.0/16)
**DNS:** Pi-hole on cooperator (192.168.254.10)

**Headscale Mesh:**

- Encrypted tunnels between all nodes
- Persistent IPs regardless of physical location
- All nodes can reach each other via 100.64.0.x addresses
- Works across network boundaries (local, VPN, internet)

**Access Patterns:**

- Local: Services on same node via localhost
- Cluster: Services on different nodes via Headscale IP or local IP
- External: Public services via Caddy reverse proxy (HTTPS)

---

## Configuration Management

### chezmoi (Config Files)

**Purpose:** Single source of truth for all node configurations with per-node customization

**How It Works:**

- Configuration templates in git repository
- Templates detect node hostname, OS, architecture
- Same file generates different output per node
- Example: Fortress mount path differs (cooperator: `/media/crtr/fortress`, others: `/mnt/fortress`)

**Bootstrap:** `chezmoi init --apply <repo-url>` on new node installs and configures everything

### mise (Tool Versioning + Tasks)

**Dual Purpose:**

**1. Version Management:**

- Pins tool versions (Docker Compose, chezmoi, etc.)
- Ensures consistency across nodes
- Declared in `~/.config/mise/config.toml`

**2. Task Runner:**

- Named commands for common operations
- Example: `mise run deploy:gitea` runs multi-step deployment
- Combines: navigate to directory, inject secrets, execute compose
- Self-documenting: `mise tasks` lists all available tasks

---

## Container Orchestration

**Engine:** Docker Engine on each node (distributed, not centralized)
**Compose:** Docker Compose V2 for multi-container services
**Deployment:** Via mise tasks with Infisical secret injection

**Service Deployment Pattern:**

1. Create Compose file in `fortress/docker/service-name/`
2. Add secrets to Infisical under `/service-name` path
3. Define mise task: `deploy:service-name`
4. Run: `mise run deploy:service-name`
5. Infisical injects secrets → Compose starts containers → Data persists to fortress

**Placement Strategy:**

- Infrastructure services (Gitea, Infisical, monitoring): cooperator
- MCP servers (lightweight APIs): cooperator
- CPU-intensive compute: director
- GPU workloads: projector
- Development/testing: any node

**Each node runs its own Docker Engine** - containers execute where deployed, not remotely.

---

## Backup Strategy

**RAID1 Backup Volume:**

- Two HDDs mirrored (sdb + sdd)
- 1.8TB usable capacity
- Mounted at `/mnt/backup` on cooperator

**Automated Backups:**

- Daily: Fortress incremental snapshot (rsync)
- Weekly: Full fortress copy
- Database dumps: PostgreSQL pg_dump to backup volume
- Retention: 7 daily, 4 weekly, 12 monthly

**Recovery:**

- Fortress corruption: Restore from `/mnt/backup/fortress-YYYYMMDD/`
- Database failure: Restore from SQL dump
- Cooperator hardware failure: Rebuild node, restore fortress from RAID

---

## Service Integration Pattern

**Standard Service Anatomy:**

**Compose File:**

- Service container(s) and dependencies
- Network definitions (internal + cluster-wide)
- Volume mounts (fortress paths for persistent data)
- Environment variable placeholders (injected by Infisical)
- Resource limits (CPU, memory caps)
- Health checks

**Deployment:**

- mise task wraps: change directory + Infisical injection + compose up
- Same command works from any node
- Secrets never in Compose file or committed to git

**Data Persistence:**

- Volumes point to fortress paths
- Survives container recreation and node restarts
- Automatically backed up via daily fortress snapshot

**Networking:**

- Internal bridge for service-to-service (e.g., app ↔ database)
- Cluster bridge for cross-node access
- Port exposure for local/mesh connectivity
- Caddy handles external HTTPS routing

---

## Cockpit Management Interface

**Access:** https://mng.ism.la (Caddy reverse proxy to localhost:9090)

**Installed Extensions:**

- **cockpit-identities** (v0.1.12) - User and group management
  - Create/delete Linux users and groups
  - Manage Samba passwords (separate from system passwords)
  - View user properties and group memberships
  - Accessible at: Cockpit → Identities

- **cockpit-file-sharing** (v4.3.2) - Samba share management
  - Create/edit/delete Samba shares via web UI
  - Configure share permissions, protocols, and access control
  - View active connections and share statistics
  - Replaces manual `/etc/samba/smb.conf` editing
  - Accessible at: Cockpit → File Sharing

**Benefits:**

- Web-based administration - no SSH required for common tasks
- Visual management of fortress share and future shares
- User-friendly password management (avoids `smbpasswd` CLI)
- Integrated with Cockpit's existing system monitoring

**Note:** NFS support available in cockpit-file-sharing but not used (Samba-only configuration).

---

## Operational Workflows

### Deploy New Service

1. Write Compose file (or use chezmoi template)
2. Add secrets to Infisical
3. Create mise deployment task
4. Run task from any node
5. Service starts, data on fortress, accessible via network

### Bootstrap New Node

1. Join Headscale mesh
2. Install Docker, mise
3. Mount fortress (OS-specific: CIFS/SMB/network drive)
4. Run: `chezmoi init --apply <repo-url>`
5. chezmoi detects node, applies appropriate configs
6. Node ready to deploy services or act as client

### Update Service

1. Edit Compose file or update image tag
2. Run: `mise run deploy:service-name`
3. Compose pulls new image, recreates container
4. Data persists (volumes on fortress unchanged)

### Recover from Failure

**Container crash:** Docker restart policy handles automatically
**Cooperator restart:** All mounts auto-restore, services restart
**Data corruption:** Restore from `/mnt/backup/fortress-latest/`
**Full node failure:** Bootstrap replacement node, restore from backup

---

## Design Principles

**1. Distributed Engines, Shared State**

- Each node runs own Docker Engine (independence)
- Fortress provides shared storage (data survives any node restart)
- Services placed where they make sense (infra on cooperator, compute on director, GPU on projector)

**2. Secrets Runtime-Only**

- Infisical injects at deployment time
- Never written to disk, Compose files, or logs
- Rotation happens in Infisical vault, not in configs

**3. Configuration as Code**

- Git repository is source of truth (chezmoi)
- Templates handle per-node differences
- Version controlled infrastructure

**4. Idempotent Operations**

- Deploy twice = same result as once
- Bootstrap scripts safe to re-run
- Backups don't fail on repeated execution

**5. Accept Single Points of Failure**

- Cooperator hosts storage and core services (SPOF)
- Mitigate via backups, not false HA claims
- Document recovery procedures

**6. Appropriate Scale Tooling**

- Docker Compose (not Kubernetes) - 4 nodes don't need orchestrator overhead
- Samba (not distributed filesystem) - simpler, cross-platform
- Headscale (not complex VPN) - Tailscale simplicity, self-hosted control

---

## Current State

**Implemented:**

- ✅ Headscale mesh (all active nodes connected)
- ✅ Fortress Samba server (955GB flash, 91 MB/s)
- ✅ Persistent mounts on director, writer, terminator
- ✅ Infisical CLI with Universal Auth (runtime secrets injection working)
- ✅ mise installed on cooperator
- ✅ Docker Engine on all nodes
- ✅ Cockpit with Samba management extensions (cockpit-identities + cockpit-file-sharing)
- ✅ Gitea deployed (rootless + PostgreSQL, https://git.ism.la, user: rtr)

**Next Phases:**

1. RAID1 backup volume setup (sdb + sdd mirrored)
2. Docker daemon standardization (logging, storage driver, network pools)
3. Add MCP servers (3-4 lightweight containers)
4. Deploy monitoring stack (metrics, logs, health)
5. Enable Gitea Actions and Package Registry
6. Additional services as needed

---

## Tool Selection Rationale

| Tool | Purpose | Why This One |
|------|---------|--------------|
| **Fortress (Samba)** | Shared storage | Cross-platform (Win/Mac/Linux), simple setup |
| **Headscale** | Mesh network | Self-hosted Tailscale, stable IPs, encrypted |
| **Infisical** | Secrets vault | Lightweight, CLI-friendly, runtime injection |
| **chezmoi** | Config management | Per-node templating, git-based, idempotent |
| **mise** | Tools + tasks | Version pinning + task runner in one |
| **Docker Compose** | Container orchestration | Declarative, no cluster overhead, widely supported |
| **Gitea** | Git + CI/CD + Registry | All-in-one, lightweight, self-hosted |
| **Caddy** | Reverse proxy | Automatic HTTPS, simple config |
| **Pi-hole** | DNS + ad-blocking | Web UI, DHCP integration, local DNS |
| **Cockpit** | System admin | Debian native, SSH/systemd integration |
| **cockpit-identities** | User/group management | Web UI for Samba passwords, 45Drives extension |
| **cockpit-file-sharing** | Samba share management | Web-based smb.conf editing, 45Drives extension |

---

**End of Architecture Document**
