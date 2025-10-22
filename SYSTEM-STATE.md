# Cooperator System State
**Updated:** 2025-10-22
**Node:** 192.168.254.10 (cooperator/crtr)
**Platform:** Raspberry Pi 5, Debian 13, 16GB RAM
**Migration:** ~85% complete from old SD card

---

## 🟢 Current Services

| Service | Type | Status | Access | Notes |
|---------|------|--------|--------|-------|
| **Docker** | systemd | ✅ Running | - | v28.5.1 |
| **Caddy** | systemd | ✅ Running | :80/:443 | SSL certificates active |
| **Pi-hole** | systemd | ✅ Running | dns.ism.la | v6.2.3 native install |
| **Cockpit** | systemd | ✅ Running | mng.ism.la | v337-1 system management |
| **Infisical** | docker | ✅ Running | env.ism.la | Secrets management with PostgreSQL + Redis |
| **n8n** | docker | ⏳ Pending | n8n.ism.la | Data exists at /media/crtr/crtr-data/services/n8n/ |
| **Semaphore** | systemd | ❌ Not installed | smp.ism.la | Deployment automation |
| **GoTTY** | systemd | ❌ Not installed | ssh.ism.la | Web terminal |
| **NFS** | systemd | ❌ Not configured | - | /cluster-nas export pending |

---

## 🌐 Working Domains

**Cooperator Services (this node):**
- ✅ `https://mng.ism.la` → Cockpit (localhost:9090)
- ✅ `https://dns.ism.la` → Pi-hole (localhost:8080)
- ✅ `https://env.ism.la` → Infisical (localhost:8081)
- ⏳ `https://n8n.ism.la` → n8n (localhost:5678) - pending
- ⏳ `https://smp.ism.la` → Semaphore (localhost:3000) - pending

**Proxied to Projector (192.168.254.20):**
- ✅ `https://cht.ism.la` → OpenWebUI (:8080)
- ✅ `https://mcp.ism.la` → MCP Server (:8051)
- ✅ `https://acn.ism.la` → Archon (:3737)
- ✅ `https://api.ism.la` → API Server (:3737)
- ✅ `https://dtb.ism.la` → Database UI (:54321)

---

## 🔧 Installed Tools

**System Package Managers:**
- ✅ apt (Debian packages)
- ✅ cargo (Rust packages)
- ✅ chezmoi v2.66.0 (dotfiles)
- ❌ uv (Python packages) - not installed
- ❌ npm (Node packages) - not installed

**CLI Tools:**
- ✅ Modern replacements: `eza` (ls), `bat` (cat), `zoxide` (cd), `dust` (du), `delta` (diff)
- ✅ Shell: `starship` prompt, `atuin` history
- ✅ Network: `dig`, `nslookup`, `host` (DNS tools)
- ✅ Secrets: `infisical` v0.38.0 (on all nodes)

---

## 🗂️ Repository Structure

```
/home/crtr/Projects/crtr-config/
├── ssot/               # Single Source of Truth
│   ├── state/          # Current configuration
│   │   ├── services.yml    # Service definitions
│   │   ├── domains.yml     # Domain routing
│   │   ├── network.yml     # Network config
│   │   └── node.yml        # Node identity
│   └── schemas/        # JSON schemas for validation
├── tools/              # SSOT management scripts
│   ├── ssot            # Main CLI
│   ├── discover.sh     # Extract live config
│   ├── validate.sh     # Check state files
│   ├── diff.sh         # Compare desired vs actual
│   └── deploy.sh       # Apply configuration
├── docker/             # Docker service configs
│   └── infisical/      # Infisical setup
├── backups/            # Encrypted backups
├── archives/           # Old documentation
├── README.md           # Project overview
├── CLAUDE.md           # Claude Code instructions
└── SYSTEM-STATE.md     # This file

**Dotfiles:** Separate repo at github.com/IMUR/dotfiles (13 files managed by chezmoi)
```

---

## 🚀 Next Steps

### Immediate (Today)
1. **Set Pi-hole password:** `sudo pihole -a -p`
2. **Test Infisical on other nodes:**
   ```bash
   ssh prtr 'source ~/.infisical-tokens && infisical secrets --domain=https://env.ism.la --token=$INFISICAL_TOKEN_KEYS --projectId=499561e0-1ed4-43dd-a5fe-13db53d3292b --env=dev'
   ```

### Soon (This Week)
3. **Restore n8n:** Mount /cluster-nas, use existing docker-compose.yml
4. **Install GoTTY:** Web-based SSH terminal
5. **Install Semaphore:** Deployment automation

### Later (As Needed)
6. **Configure NFS:** Export /cluster-nas for shared storage
7. **Install Python/Node ecosystems:** uv, pipx, npm
8. **Restore application data:** Projects, history databases

---

## 📝 Quick Commands

```bash
# Service Management
systemctl status caddy pihole-FTL cockpit docker
docker ps --filter name=infisical

# Test Services
curl -I https://dns.ism.la   # Pi-hole
curl -I https://env.ism.la   # Infisical
curl -I https://mng.ism.la   # Cockpit

# SSOT Workflow
cd /home/crtr/Projects/crtr-config
./tools/ssot discover         # See current state
./tools/ssot validate         # Check YAML syntax
./tools/ssot diff            # Compare desired vs actual
sudo ./tools/ssot deploy     # Apply changes

# Chezmoi (Dotfiles)
chezmoi diff                 # See pending changes
chezmoi update               # Pull and apply from GitHub
```

---

## 🔄 Migration Progress

**From:** Old Debian SD card (mounted at /media/crtr/rootfs/)
**To:** Fresh Debian 13 on same hardware

**Completed:**
- ✅ Base OS and users
- ✅ SSH keys and Git config
- ✅ Docker and container runtime
- ✅ Dotfiles via chezmoi (all nodes synced)
- ✅ Core services (Caddy, Pi-hole, Cockpit, Infisical)
- ✅ Cluster DNS working

**Remaining (~15%):**
- ⏳ Application containers (n8n)
- ❌ Python/Node.js ecosystems
- ❌ NFS configuration
- ❌ Remaining systemd services
- ❌ Historical data (projects, databases)

---

**Last Verified:** 2025-10-22 04:00 PDT