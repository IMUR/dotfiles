# Infrastructure Documentation Index

Central index for all infrastructure documentation in crtr-config.

---

## Core Documentation

### Architecture & Planning
- **ASPECTS.md** - Overview of the 7 technical aspects
- **COOPERATOR-ASPECTS.md** - Complete technical breakdown of cooperator
- **BUILD-PLAN.md** - Comprehensive rebuild architecture (work in progress)

### Repository Guides
- **README.md** - Repository overview and quick reference
- **CLAUDE.md** - AI assistant guidance for working with this repository

---

## Cluster Documentation

### Node Information
- **NODE-PROFILES.md** - Hardware and configuration profiles for all cluster nodes
  - Cooperator (crtr) - Gateway/coordinator, Raspberry Pi 5
  - Projector (prtr) - Multi-GPU compute, 4x NVIDIA GPUs
  - Director (drtr) - ML platform, RTX 2080
  - Terminator (trtr) - Remote terminal, M4 MacBook Air

### Network Specifications
- **network-spec.md** - Complete network topology and configuration
  - IP addressing and subnets
  - DNS architecture (external + internal)
  - Port forwarding and external access
  - Service mappings and routing

### Service Documentation
- **n8n-deployment-plan.md** - n8n workflow automation deployment
- **services/caddy/README.md** - Caddy reverse proxy configuration
- **services/pihole/README.md** - Pi-hole DNS server configuration
- **services/n8n/README.md** - n8n service-specific documentation

---

## Configuration State

### State Definitions
Location: `state/`

- **system.yml** - System identity, network, storage, users
- **services.yml** - All running services (systemd + docker)
- **domains.yml** - Domain routing and reverse proxy mappings
- **network.yml** - Network configuration and cluster connectivity

### Aspect Definitions
Location: `aspects/`

Each aspect contains:
- `aspect.yml` - State definition
- `deploy.md` - Deployment strategy
- `verify.sh` - Verification script

Current aspects:
- systemd/ - Systemd service management
- user-environment/ - User-level configuration

---

## Operational Scripts

### DNS Management
Location: `scripts/dns/`

- **godaddy-dns-manager.sh** - GoDaddy API integration for *.ism.la
- **setup-godaddy-api.sh** - Initial API credential setup
- **QUICKSTART.md** - Quick start guide for DNS management
- **README.md** - Complete DNS management documentation

### SSOT (Single Source of Truth)
Location: `scripts/ssot/`

- **infrastructure-truth.yaml** - Truth database for cluster infrastructure
- **discover-truth.sh** - Automated truth discovery
- **validate-truth.sh** - Validation against truth database
- **ssot** - Query utility for infrastructure truth
- **README.md** - SSOT system documentation

### System Operations
Location: `scripts/`

- **clone-usb-to-microsd.sh** - Clone USB system to microSD
- **backup-usb-to-nas.sh** - Backup/restore USB drive to /cluster-nas
- **backup-before-migration.sh** - Pre-migration backup script

---

## Quick Navigation

### By Task

**Setting up a new service:**
1. COOPERATOR-ASPECTS.md → See multi-aspect deployment pattern
2. CLAUDE.md → "Adding a New Service" section
3. state/services.yml → Add service definition
4. state/domains.yml → Add domain routing

**Modifying DNS:**
1. scripts/dns/README.md → External DNS management
2. network-spec.md → Current DNS architecture
3. scripts/ssot/infrastructure-truth.yaml → Update truth database

**Understanding the cluster:**
1. NODE-PROFILES.md → Hardware specs and roles
2. network-spec.md → Network topology
3. COOPERATOR-ASPECTS.md → Cooperator's specific role

**Rebuilding cooperator:**
1. BUILD-PLAN.md → Architecture overview
2. ASPECTS.md → Aspect-based organization
3. state/*.yml → Current desired state

---

## External References

### Related Repositories
- **colab-config** - Cluster-wide configuration (`~/Projects/colab-config/`)
  - Chezmoi dotfiles
  - Ansible playbooks
  - Shared cluster tooling

### System Locations
- `/etc/caddy/Caddyfile` - Caddy reverse proxy configuration
- `/etc/pihole/` - Pi-hole DNS server configuration
- `/etc/dnsmasq.d/02-custom-local-dns.conf` - Local DNS overrides
- `/cluster-nas/` - Shared cluster storage
- `/cluster-nas/services/` - Service data directories

---

## Document Maintenance

### When Adding New Documentation
1. Add entry to this index
2. Update relevant cross-references
3. Add to CLAUDE.md if AI-relevant
4. Consider aspect categorization

### Documentation Standards
All markdown files follow `.meta/document-standards.yml` (in colab-config):
- Blank lines before/after headings
- Blank lines before/after code blocks
- File must end with single newline
- Use `*asterisks*` for emphasis

---

Last Updated: 2025-10-07
