# Cooperator: Complete Aspect Breakdown

**Purpose**: Comprehensive mapping of every configuration element of cooperator organized by technical aspect.

---

## 1. BASE SYSTEM

**Domain**: Operating system, packages, system-level configuration

### OS Configuration
- Distribution: Debian GNU/Linux 13 (trixie)
- Hostname: cooperator
- Short name: crtr
- Timezone: UTC
- Locale: en_US.UTF-8

### System Packages (APT)
```
Essential tools:
- git, vim, curl, wget
- tmux, htop, tree, ncdu
- rsync, duf

Service packages:
- caddy
- nfs-kernel-server
- docker-ce (via Docker installer)

User tools (APT):
- eza, bat, fd-find, ripgrep
```

### System Configuration Files
- `/etc/hostname` → cooperator
- `/etc/hosts` → Local host entries
- `/etc/timezone` → UTC
- `/etc/locale.gen` → en_US.UTF-8

### Boot Configuration
- `/boot/firmware/cmdline.txt` → Kernel parameters
- `/boot/firmware/config.txt` → Boot settings

---

## 2. STORAGE

**Domain**: Disks, filesystems, mounts, NFS exports

### Partition Layout
```
/dev/sdb (USB 3.0, 931GB)
├── /dev/sdb1 (128MB, vfat)  → /boot/firmware
└── /dev/sdb2 (931GB, ext4)  → /

/dev/sda (NVMe, 1.8TB)
└── /dev/sda1 (1.8TB, xfs)   → /cluster-nas
```

### Filesystems & Mounts
```
/dev/sdb2  /              ext4  noatime,lazytime
/dev/sdb1  /boot/firmware vfat  defaults
/dev/sda1  /cluster-nas   xfs   defaults
```

### tmpfs Mounts
```
tmpfs  /tmp      8GB   noatime,lazytime,nodev,nosuid,mode=1777
tmpfs  /var/log  50MB  noatime,lazytime,nodev,nosuid
```

### Configuration Files
- `/etc/fstab` → Mount definitions

### NFS Server
```
Service: nfs-kernel-server.service
Config: /etc/exports

Export:
/cluster-nas  192.168.254.0/24(rw,sync,no_subtree_check,no_root_squash)
```

### Directory Structure (/cluster-nas)
```
/cluster-nas/
├── services/
│   ├── n8n/
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── data/
│   ├── semaphore/
│   │   └── config.json
│   └── qcash/
├── backups/
│   └── migration-2025-10-07/
├── repos/
└── docs/
```

---

## 3. NETWORK

**Domain**: Interfaces, IP addressing, DNS client/server, connectivity

### Network Interface
```
Interface: eth0
IP: 192.168.254.10/24
Gateway: 192.168.254.1
MAC: 88:A2:9E:07:04:22
```

### DNS Client
```
Config: /etc/resolv.conf
Nameserver: 127.0.0.1 (local Pi-hole)
```

### DNS Server (Pi-hole)
```
Service: pihole-FTL.service
Port: 53 (bind: 0.0.0.0)
Config: /etc/pihole/

Files:
- /etc/pihole/custom.list → Custom DNS entries
- /etc/dnsmasq.d/02-custom-local-dns.conf → Local overrides

Upstream DNS:
- 1.1.1.1 (Cloudflare)
- 1.0.0.1 (Cloudflare)

Local DNS Overrides:
address=/dns.ism.la/192.168.254.10
address=/mng.ism.la/192.168.254.10
address=/smp.ism.la/192.168.254.10
address=/ssh.ism.la/192.168.254.10
address=/n8n.ism.la/192.168.254.10
address=/acn.ism.la/192.168.254.10
address=/api.ism.la/192.168.254.10
address=/dtb.ism.la/192.168.254.10
address=/mcp.ism.la/192.168.254.10
address=/cht.ism.la/192.168.254.10
```

### Dynamic DNS (DuckDNS)
```
Script: ~/duckdns/duck.sh
Domain: crtrcooperator.duckdns.org
Token: dd3810d4-6ea3-497b-832f-ec0beaf679b3
Cron: */5 * * * * ~/duckdns/duck.sh
Log: ~/duckdns/duck.log
```

### External Access
```
Public IP: 47.155.237.161
DDNS: crtrcooperator.duckdns.org

Port Forwarding (at router):
22/tcp  → 192.168.254.10:22   (SSH)
80/tcp  → 192.168.254.10:80   (HTTP)
443/tcp → 192.168.254.10:443  (HTTPS)
```

### Cluster Connectivity
```
Cluster network: 192.168.254.0/24

Nodes:
- cooperator: 192.168.254.10
- projector:  192.168.254.20
- director:   192.168.254.30
```

---

## 4. SERVICES

**Domain**: All running processes and workloads

### Systemd Services

#### Gateway Infrastructure
```
caddy.service
  Binary: /usr/bin/caddy
  Config: /etc/caddy/Caddyfile
  Ports: 80/tcp, 443/tcp
  Bind: 0.0.0.0

pihole-FTL.service
  Binary: /usr/bin/pihole-FTL
  Config: /etc/pihole/
  Ports: 53/udp, 8080/tcp
  Bind: 0.0.0.0:53, 127.0.0.1:8080

nfs-kernel-server.service
  Config: /etc/exports
  Port: 2049/tcp
```

#### Container Runtime
```
docker.service
  Binary: /usr/bin/dockerd
  Socket: /var/run/docker.sock
  Compose: plugin (v2.39.4)
```

#### Custom Services
```
atuin-server.service
  Binary: /usr/local/bin/atuin
  Unit: /etc/systemd/system/atuin-server.service
  Port: 8811/tcp
  Bind: 0.0.0.0 (cluster access)
  Data: /home/crtr/.local/share/atuin/
  User: crtr

semaphore.service
  Binary: /usr/local/bin/semaphore
  Unit: /etc/systemd/system/semaphore.service
  Port: 3000/tcp
  Bind: 127.0.0.1 (proxied via Caddy)
  Data: /cluster-nas/services/semaphore/
  User: crtr

gotty.service
  Binary: /usr/local/bin/gotty
  Unit: /etc/systemd/system/gotty.service
  Port: 7681/tcp
  Bind: 127.0.0.1 (proxied via Caddy)
  User: crtr
```

### Docker Services

```
n8n
  Image: n8nio/n8n:latest
  Compose: /cluster-nas/services/n8n/docker-compose.yml
  Port: 5678/tcp
  Bind: 127.0.0.1 (proxied via Caddy)
  Volumes:
    - /cluster-nas/services/n8n/data/n8n:/home/node/.n8n
  Environment: /cluster-nas/services/n8n/.env
  Network: n8n_n8n-network

n8n-postgres
  Image: postgres:16-alpine
  Volumes:
    - /cluster-nas/services/n8n/data/postgres:/var/lib/postgresql/data
  Network: n8n_n8n-network
```

### Service Dependencies
```
Startup order:
1. nfs-kernel-server (mount /cluster-nas)
2. pihole-FTL (DNS)
3. docker (container runtime)
4. caddy (reverse proxy)
5. atuin-server, semaphore, gotty (custom services)
6. n8n (containerized service)
```

---

## 5. GATEWAY

**Domain**: Reverse proxy, domain routing, HTTPS certificates

### Caddy Configuration
```
Config: /etc/caddy/Caddyfile
Service: caddy.service
Ports: 80/tcp, 443/tcp
Email: admin@ism.la (Let's Encrypt)
```

### Domain Routing

#### Root Domains
```
ism.la
  Action: redir https://www.ism.la permanent

www.ism.la
  Action: respond "Welcome to ism.la - Co-lab Cluster Gateway" 200
```

#### Cooperator Services
```
dns.ism.la
  Backend: localhost:8080
  Service: Pi-hole admin
  Type: standard

mng.ism.la
  Backend: https://localhost:9090
  Service: Cockpit
  Type: https_backend + tls_skip_verify

smp.ism.la
  Backend: localhost:3000
  Service: Semaphore
  Type: standard

ssh.ism.la
  Backend: localhost:7681
  Service: GoTTY
  Type: websocket
  Headers: Upgrade, Connection

n8n.ism.la
  Backend: localhost:5678
  Service: n8n
  Type: sse (flush_interval: -1)
```

#### Projector Services (Proxied)
```
acn.ism.la
  Backend: 192.168.254.20:3737
  Service: Archon (on projector)
  Type: cross_node

api.ism.la
  Backend: 192.168.254.20:3737
  Service: Archon alternate domain
  Type: cross_node

dtb.ism.la
  Backend: 192.168.254.20:54321
  Service: Database (on projector)
  Type: cross_node

mcp.ism.la
  Backend: 192.168.254.20:8051
  Service: MCP (on projector)
  Type: cross_node

cht.ism.la
  Backend: 192.168.254.20:8080
  Service: OpenWebUI (on projector)
  Type: cross_node
```

### HTTPS Certificates
```
Provider: Let's Encrypt
Method: Automatic (Caddy)
Renewal: Automatic
Storage: /var/lib/caddy/
```

### External DNS (GoDaddy)
```
Domain: ism.la
Records: *.ism.la CNAME crtrcooperator.duckdns.org
TTL: 3600
```

---

## 6. USER ENVIRONMENT

**Domain**: User-level configuration, tools, workspace

### User Account
```
Username: crtr
UID: 1000
Groups: sudo, docker, users
Home: /home/crtr
Shell: /bin/zsh
```

### Shell Configuration
```
Primary shell: zsh
Config: ~/.zshrc

Fallback shell: bash
Config: ~/.bashrc

Managed by: chezmoi
```

### Dotfiles (Chezmoi)
```
Manager: chezmoi
Binary: ~/.local/bin/chezmoi
Source: ~/Projects/dotfiles (or remote repo)

Files managed:
- .zshrc
- .bashrc
- .gitconfig
- .config/starship.toml
- .config/atuin/config.toml
- .ssh/config
```

### User-Installed Tools
```
APT packages:
- eza (modern ls)
- bat (modern cat)
- fd-find (modern find)
- ripgrep (fast grep)

Standalone binaries:
- starship (shell prompt) → ~/.local/bin/starship
- zoxide (smart cd)
```

### Directory Structure
```
~/.local/
├── bin/          User scripts and binaries
└── share/
    └── atuin/    Atuin server database

~/.config/        Application configurations

~/Projects/
├── colab-config/ Cluster-wide config repo
└── crtr-config/  Cooperator-specific config repo

~/workspace/      Active work area

~/duckdns/        DuckDNS update script
├── duck.sh
└── duck.log
```

### Environment Variables
```
PATH: ~/.local/bin:$PATH
EDITOR: vim
VISUAL: vim
SHELL: /bin/zsh
```

### User Cron Jobs
```
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
```

---

## 7. SECURITY

**Domain**: Access control, permissions, firewall, secrets

### SSH Configuration
```
Server config: /etc/ssh/sshd_config
  Port: 22
  PasswordAuthentication: no (key-based only)
  PubkeyAuthentication: yes
  PermitRootLogin: no

User SSH: ~/.ssh/
  config           Client SSH configuration
  authorized_keys  Public keys for access
  id_*             Private/public key pairs
```

### User Permissions
```
User: crtr
Sudo access: yes (in sudo group)
Docker access: yes (in docker group)

System services run as:
- root: caddy, pihole-FTL, nfs-kernel-server, docker
- crtr: atuin-server, semaphore, gotty
```

### Service Binding Strategy
```
Localhost only (proxied via Caddy):
- 127.0.0.1:5678  (n8n)
- 127.0.0.1:3000  (semaphore)
- 127.0.0.1:7681  (gotty)
- 127.0.0.1:8080  (pihole web)
- 127.0.0.1:9090  (cockpit)

Cluster-wide access:
- 0.0.0.0:53      (DNS)
- 0.0.0.0:8811    (atuin sync)
- 0.0.0.0:2049    (NFS)

Public access:
- 0.0.0.0:80      (HTTP → Caddy)
- 0.0.0.0:443     (HTTPS → Caddy)
- 0.0.0.0:22      (SSH)
```

### Firewall
```
Status: Disabled (ufw not active)

Intended rules (if enabled):
- Allow: 22/tcp (SSH)
- Allow: 53/udp (DNS)
- Allow: 80/tcp (HTTP)
- Allow: 443/tcp (HTTPS)
- Allow: 2049/tcp (NFS) from 192.168.254.0/24
- Allow: 8811/tcp (Atuin) from 192.168.254.0/24
- Deny: all other incoming
```

### Secrets Management
```
DuckDNS token: ~/duckdns/duck.sh (plaintext - needs improvement)
n8n credentials: /cluster-nas/services/n8n/.env (not committed to git)
Database passwords: /cluster-nas/services/n8n/.env
Pi-hole web password: /etc/pihole/cli_pw

Strategy: .env files on /cluster-nas (not in version control)
```

### File Permissions
```
/etc/caddy/Caddyfile: 644 (root:root)
/etc/pihole/: 640 (pihole:pihole)
/cluster-nas/: 755 (root:root)
/home/crtr/: 755 (crtr:crtr)
~/.ssh/: 700 (crtr:crtr)
~/.ssh/authorized_keys: 600 (crtr:crtr)
```

---

## Aspect Interactions

### Deploying a New Service (Example: n8n)

**SERVICES aspect:**
- Create /cluster-nas/services/n8n/docker-compose.yml
- Create .env file with secrets
- `docker compose up -d`

**GATEWAY aspect:**
- Add n8n.ism.la block to /etc/caddy/Caddyfile
- Configure flush_interval: -1 for SSE
- `systemctl reload caddy`

**NETWORK aspect:**
- Add `address=/n8n.ism.la/192.168.254.10` to local DNS
- `systemctl restart pihole-FTL`

**SECURITY aspect:**
- Ensure n8n binds to 127.0.0.1 only
- Store secrets in .env (not git)
- Access only via HTTPS through Caddy

### System Rebuild Dependencies

1. **STORAGE** must exist first (mount /cluster-nas)
2. **NETWORK** needs working interfaces
3. **BASE SYSTEM** provides packages for everything
4. **SERVICES** depend on storage + network
5. **GATEWAY** depends on services being available
6. **USER ENVIRONMENT** is independent (user-level only)
7. **SECURITY** is cross-cutting (affects all aspects)

---

## Verification Commands

### Check All Aspects

```bash
# BASE SYSTEM
hostname
cat /etc/timezone
dpkg -l | grep -E "caddy|docker|nfs-kernel-server"

# STORAGE
df -h
lsblk
showmount -e localhost

# NETWORK
ip addr show eth0
dig @localhost ism.la
curl -I https://n8n.ism.la

# SERVICES
systemctl status caddy pihole-FTL nfs-kernel-server docker \
  atuin-server semaphore gotty
docker ps

# GATEWAY
curl -I https://dns.ism.la
curl -I https://smp.ism.la

# USER ENVIRONMENT
echo $SHELL
chezmoi status
which eza bat fd rg starship

# SECURITY
sudo -l
ssh -T localhost
ss -tlnp | grep -E ":80|:443|:53|:5678"
```
