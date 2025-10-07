# Cooperator Build Plan: From Scratch Architecture

**Purpose**: Transform crtr-config into a reproducible Infrastructure-as-Code repository that can rebuild cooperator from a fresh Raspberry Pi OS installation.

**Goal**: Fresh RPi OS → Full Cooperator in ~30 minutes

---

## Build Philosophy

**Declarative Infrastructure**: Every service, configuration, and setting is defined in code and can be rebuilt identically.

**Idempotent**: Scripts can be run multiple times safely without breaking the system.

**Modular**: Each service is independent and can be installed/updated separately.

**Testable**: Validation scripts confirm everything works correctly.

---

## Directory Structure (Proposed)

```
crtr-config/
├── bootstrap.sh                 # Initial setup - run once on fresh RPi OS
├── build.sh                     # Main orchestration - builds entire system
├── install/                     # Service installation scripts (modular)
│   ├── 00-prepare.sh           # Pre-flight checks, /cluster-nas mount
│   ├── 01-base-system.sh       # System packages, updates
│   ├── 02-docker.sh            # Docker + Docker Compose
│   ├── 03-caddy.sh             # Caddy reverse proxy
│   ├── 04-pihole.sh            # Pi-hole DNS server
│   ├── 05-nfs-server.sh        # NFS kernel server
│   ├── 06-custom-services.sh   # Atuin, Semaphore, GoTTY
│   └── 07-docker-services.sh   # n8n, other containers
├── config/                      # Configuration templates
│   ├── caddy/
│   │   ├── Caddyfile.template  # Master Caddyfile with all services
│   │   └── README.md
│   ├── pihole/
│   │   ├── custom.list         # Custom DNS entries
│   │   └── local-dns.conf      # Local DNS overrides
│   ├── systemd/
│   │   ├── atuin-server.service
│   │   ├── semaphore.service
│   │   └── gotty.service
│   ├── nfs/
│   │   └── exports             # NFS export configuration
│   └── network/
│       └── hosts.cooperator    # /etc/hosts additions
├── services/                    # Docker Compose service definitions
│   ├── n8n/
│   │   ├── docker-compose.yml
│   │   └── .env.template
│   ├── qcash/
│   │   ├── docker-compose.yml
│   │   └── README.md
│   └── atuin/
│       └── docker-compose.yml
├── validate/                    # Validation and testing scripts
│   ├── check-services.sh       # Verify all services running
│   ├── check-network.sh        # Test DNS, connectivity
│   └── full-validation.sh      # Complete system check
├── docs/                        # Documentation
│   ├── network-spec.md         # Network specifications
│   ├── service-guide.md        # Service management guide
│   └── troubleshooting.md      # Common issues and fixes
├── network/
│   └── dns/
│       └── ism.la.txt          # DNS zone file (reference)
├── CLAUDE.md                    # AI assistant guidance (updated)
├── README.md                    # Repository overview (updated)
└── BUILD-PLAN.md               # This file
```

---

## Build Stages

### Stage 0: Bootstrap (bootstrap.sh)
**Run once on fresh Raspberry Pi OS**

```bash
# Prerequisites check
- Verify running on Raspberry Pi 5
- Verify Debian 13 (Trixie)
- Verify network connectivity
- Verify /dev/sda1 (cluster-nas) is available

# Initial setup
- Update system: apt update && apt upgrade
- Install git, vim, curl, wget, tmux, htop
- Clone crtr-config to ~/Projects/crtr-config
- Mount /cluster-nas (/dev/sda1)
- Add /cluster-nas to /etc/fstab
- Set correct hostname (cooperator)
- Configure /etc/hosts
```

### Stage 1: Base System (install/01-base-system.sh)
```bash
# System configuration
- Configure timezone (UTC or America/New_York)
- Install essential packages
- Configure unattended-upgrades (optional)
- Set up logging
- Configure tmpfs for /tmp and /var/log
```

### Stage 2: Docker (install/02-docker.sh)
```bash
# Container runtime
- Install Docker using official script
- Add user to docker group
- Install Docker Compose plugin
- Configure Docker daemon.json
- Enable and start docker.service
- Verify installation
```

### Stage 3: Caddy (install/03-caddy.sh)
```bash
# Reverse proxy
- Add Caddy repository
- Install Caddy
- Copy Caddyfile from config/caddy/
- Configure for *.ism.la domains
- Set email for Let's Encrypt
- Enable and start caddy.service
- Validate configuration
```

### Stage 4: Pi-hole (install/04-pihole.sh)
```bash
# DNS server
- Run Pi-hole installer
- Configure DNS settings
- Copy custom.list (local DNS entries)
- Copy local DNS overrides (dnsmasq.d)
- Set web interface password
- Configure for cluster DNS
- Enable and start pihole-FTL.service
```

### Stage 5: NFS Server (install/05-nfs-server.sh)
```bash
# Network file system
- Install nfs-kernel-server
- Copy /etc/exports configuration
- Create /cluster-nas if not exists
- Mount /dev/sda1 to /cluster-nas (XFS)
- Configure permissions
- Enable and start nfs-kernel-server
- Export shares
- Test from other nodes
```

### Stage 6: Custom Services (install/06-custom-services.sh)
```bash
# Node-specific services
- Install Atuin server
  - Download ARM64 binary
  - Configure systemd service
  - Set up data directory
  - Enable and start

- Install Semaphore
  - Download ARM64 binary
  - Configure systemd service
  - Set data path on /cluster-nas
  - Enable and start

- Install GoTTY
  - Download ARM64 binary
  - Configure systemd service
  - Enable and start
```

### Stage 7: Docker Services (install/07-docker-services.sh)
```bash
# Containerized services
- Deploy n8n
  - Copy docker-compose.yml
  - Create .env from template
  - Create data directories on /cluster-nas
  - docker compose up -d
  - Verify containers running

- Deploy qcash
  - Similar process

- Deploy other services as needed
```

---

## Configuration Templates

### config/caddy/Caddyfile.template
Complete Caddyfile with all service proxies:
- dns.ism.la → localhost:8080 (Pi-hole)
- n8n.ism.la → localhost:5678 (n8n)
- smp.ism.la → localhost:3000 (Semaphore)
- ssh.ism.la → localhost:7681 (GoTTY)
- mng.ism.la → localhost:9090 (Cockpit)
- acn.ism.la → 192.168.254.20:3737 (Archon on projector)
- cht.ism.la → 192.168.254.20:8080 (OpenWebUI on projector)
- etc.

### config/pihole/local-dns.conf
All *.ism.la → 192.168.254.10 overrides

### config/systemd/*.service
Complete systemd unit files for:
- atuin-server.service
- semaphore.service
- gotty.service

### config/nfs/exports
```
/cluster-nas 192.168.254.0/24(rw,sync,no_subtree_check,no_root_squash)
```

---

## Validation Scripts

### validate/check-services.sh
```bash
# Check all systemd services
systemctl is-active caddy pihole-FTL nfs-kernel-server \
  docker atuin-server semaphore gotty

# Check Docker containers
docker ps --format "{{.Names}}: {{.Status}}"

# Check network
ping -c 1 192.168.254.20  # projector
ping -c 1 192.168.254.30  # director

# Check DNS
dig @localhost ism.la
dig @localhost n8n.ism.la

# Check NFS
showmount -e localhost

# Check HTTPS
curl -I https://dns.ism.la
curl -I https://n8n.ism.la
```

---

## Build Execution Flow

### Fresh Install Workflow
```bash
# 1. Flash Raspberry Pi OS Lite (Debian 13) to USB drive
# 2. Boot with /dev/sda1 (cluster-nas) connected
# 3. SSH into the fresh system

# 4. Run bootstrap
curl -fsSL https://raw.githubusercontent.com/YOUR-USER/crtr-config/main/bootstrap.sh | bash
# OR if repo is on /cluster-nas:
bash /cluster-nas/repos/crtr-config/bootstrap.sh

# 5. Build the system
cd ~/Projects/crtr-config
./build.sh

# 6. Validate
./validate/full-validation.sh

# 7. Done! Cooperator is fully operational
```

### Partial Rebuild Workflow
```bash
# Reinstall just Caddy
cd ~/Projects/crtr-config
./install/03-caddy.sh

# Rebuild all Docker services
./install/07-docker-services.sh

# Update a single service
cd services/n8n
docker compose down
docker compose up -d
```

---

## Implementation Timeline

### Phase 1: Foundation Scripts (1-2 hours)
- [x] Create BUILD-PLAN.md (this file)
- [ ] Create bootstrap.sh
- [ ] Create build.sh orchestrator
- [ ] Create install/00-prepare.sh

### Phase 2: Core Services (2-3 hours)
- [ ] Create install/01-base-system.sh
- [ ] Create install/02-docker.sh
- [ ] Create install/03-caddy.sh
- [ ] Create config/caddy/Caddyfile.template

### Phase 3: Gateway Services (2-3 hours)
- [ ] Create install/04-pihole.sh
- [ ] Create install/05-nfs-server.sh
- [ ] Create config/pihole/* templates
- [ ] Create config/nfs/exports

### Phase 4: Custom Services (1-2 hours)
- [ ] Create install/06-custom-services.sh
- [ ] Create config/systemd/*.service files
- [ ] Test Atuin, Semaphore, GoTTY installation

### Phase 5: Docker Services (1-2 hours)
- [ ] Create install/07-docker-services.sh
- [ ] Update services/n8n/ with .env.template
- [ ] Test n8n deployment

### Phase 6: Validation (1 hour)
- [ ] Create validate/check-services.sh
- [ ] Create validate/check-network.sh
- [ ] Create validate/full-validation.sh

### Phase 7: Documentation (1 hour)
- [ ] Update CLAUDE.md
- [ ] Update README.md
- [ ] Create docs/service-guide.md
- [ ] Create docs/troubleshooting.md

---

## Testing Plan

### Test 1: Fresh Build
- Start: Fresh Raspberry Pi OS on USB drive
- Execute: bootstrap.sh + build.sh
- Verify: All services running, all domains resolving

### Test 2: Partial Rebuild
- Start: Working cooperator
- Execute: Single install script (e.g., install/03-caddy.sh)
- Verify: Service updated without breaking others

### Test 3: Recovery
- Start: Cloned microSD backup
- Execute: Individual service restoration
- Verify: Can rebuild specific services

---

## Benefits

1. **Reproducibility**: Rebuild cooperator identically anytime
2. **Documentation**: Code IS documentation
3. **Version Control**: All configs tracked in git
4. **Testing**: Can test changes on microSD before applying to USB
5. **Knowledge Sharing**: Other nodes can use similar patterns
6. **Recovery**: Fast rebuild if system breaks
7. **Experimentation**: Safe to try changes with easy rollback

---

## Next Steps

1. Get approval for this architecture
2. Start with bootstrap.sh and build.sh
3. Create install scripts one by one
4. Test each script on the microSD clone
5. Once validated, apply to fresh USB drive
6. Document any issues/improvements
7. Use this as template for projector and director configs

---

**Last Updated**: 2025-10-07
**Status**: Planning Phase
**Target**: Implement during USB migration
