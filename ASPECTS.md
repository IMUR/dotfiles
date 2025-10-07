# Cooperator Technical Aspects

**Definition**: Top-level operational technical domains that define cooperator's configuration and function.

---

## The Aspects

### 1. BASE SYSTEM
**OS, packages, system configuration**

- Hostname, timezone, locale
- APT packages and repositories
- System-level configuration files
- Kernel parameters, boot configuration

### 2. STORAGE
**Disks, filesystems, mount points**

- Partition layout (/dev/sdb, /dev/sda)
- Filesystem types (ext4, xfs, vfat)
- Mount points (/, /boot/firmware, /cluster-nas)
- tmpfs configuration
- NFS server and exports

### 3. NETWORK
**Interfaces, IPs, DNS, connectivity**

- Network interfaces (eth0)
- IP addressing (192.168.254.10)
- DNS resolution (client-side)
- DNS serving (Pi-hole)
- External access (DuckDNS, port forwarding)
- Cluster connectivity

### 4. SERVICES
**Processes and workloads that run**

- Systemd units (caddy, pihole-FTL, etc.)
- Docker containers (n8n, etc.)
- Service configuration files
- Service dependencies and ordering

### 5. GATEWAY
**Reverse proxy and domain routing**

- Caddy configuration
- Domain → backend mappings
- HTTPS certificates
- Traffic routing (local + cross-node)

### 6. USER ENVIRONMENT
**User-level configuration and tools**

- Shell configuration (zsh/bash)
- Dotfiles (managed by chezmoi)
- User-installed tools
- Directory structure (~/.local, ~/Projects)
- Development environment

### 7. SECURITY
**Access control and protection**

- SSH configuration and keys
- User permissions and sudo
- Firewall rules
- Service binding (localhost vs 0.0.0.0)
- Secrets management

---

## Aspect Structure

```
aspects/
├── base-system/
├── storage/
├── network/
├── services/
├── gateway/
├── user-environment/
└── security/
```

Each contains:
- `state.yml` - Desired state definition
- `deploy.md` - How to achieve state from clean install
- `verify.sh` - Test that state is achieved
- `config/` - Configuration files/templates
