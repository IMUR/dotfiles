# System Migration Inventory - Cooperator (crtr)
**Generated:** 2025-10-14
**Source System:** Raspberry Pi (ARM64/aarch64), Debian Linux 6.12.47
**Hostname:** cooperator (192.168.254.10)
**User:** crtr

---

## Executive Summary

### System Overview
- **Platform:** Raspberry Pi (ARM64) - Debian-based Linux
- **Node Role:** Gateway/Cooperator node in Co-lab cluster
- **Development Focus:** Python, Rust, Node.js, Go, Ansible automation
- **Key Services:** Docker (n8n, postgres), NFS, DNS, Caddy, Pi-hole, Atuin
- **Modern Toolchain:** Extensive modern CLI tools (eza, bat, fd, rg, zoxide, fzf, starship, atuin, delta)
- **Total Debian Packages:** 1,449 installed

### Migration Complexity Assessment
- **Complexity Level:** Medium-High (Simplified by Chezmoi)
- **Estimated Migration Time:** 6-10 hours (reduced with chezmoi dotfile automation)
- **Critical Dependencies:**
  - Cluster-aware configurations (NFS mounts, node coordination)
  - SSH key infrastructure (4 different keys for different purposes)
  - Running Docker services (n8n workflow automation)
  - Cron jobs and systemd services
- **Migration Advantage:**
  - **Chezmoi-managed dotfiles** - No manual dotfile copying required
  - Version-controlled configuration via `git@github.com:IMUR/dotfiles.git`
  - Template-based system auto-adapts to new node characteristics

---

## 🎯 Migration Quick Start (Recommended Path)

**The Chezmoi Advantage**: Your entire shell environment is version-controlled and template-based!

Instead of manually copying hundreds of configuration files, follow this streamlined migration path:

1. **Setup SSH keys** on new system (secure transfer)
2. **Install base tools**: `git`, `zsh`, `chezmoi`, development languages
3. **Clone & apply dotfiles**:
   ```bash
   git clone --recursive git@github.com:IMUR/colab-config.git ~/Projects/colab-config
   chezmoi init --source ~/Projects/colab-config/dotfiles
   chezmoi apply  # Generates ALL dotfiles automatically!
   ```
4. **Install package managers**: UV, cargo, npm global packages
5. **Restore application data**: Docker containers, cron jobs, services

**Time Savings**: Reduces configuration restoration from 2-3 hours to ~30 minutes!

**Repository Information**:
- **Dotfiles**: `git@github.com:IMUR/dotfiles.git` (submodule)
- **Parent Config**: `git@github.com:IMUR/colab-config.git`
- **Managed Files**: All shell configs, SSH config, starship, tmux, cluster scripts

---

## 1. Development Tools & Languages

| Tool | Version | Location | Priority | Notes |
|------|---------|----------|----------|-------|
| Git | 2.47.3 | /usr/bin/git | CRITICAL | Signed commits configured |
| Python 3 | 3.13.5 | /usr/bin/python3 | CRITICAL | Latest stable |
| pip | 25.1.1 | System package | HIGH | Python package manager |
| uv | 0.9.2 | ~/.local/bin | HIGH | Modern Python package manager |
| pipx | 1.7.1 | System installed | HIGH | Python app isolation |
| Node.js | 20.19.2 | /usr/bin/node | CRITICAL | LTS version |
| npm | 9.2.0 | /usr/bin/npm | CRITICAL | Package manager |
| Rust | 1.88.0 | ~/.cargo/bin/rustc | HIGH | Via rustup |
| Cargo | 1.88.0 | ~/.cargo/bin/cargo | HIGH | Rust package manager |
| Go | 1.24.4 | /usr/bin/go | MEDIUM | Latest stable |
| Docker | 28.5.1 | /usr/bin/docker | CRITICAL | Container runtime |
| Perl | 5.40.1 | /usr/bin/perl | LOW | System dependency |

**Configuration Files:**
- Python: `~/.python_history`
- Cargo: `~/.cargo/` (15 binaries installed)
- Docker: `/var/lib/docker/` (system-managed)

---

## 2. Package Managers & Dependencies

### APT (Debian Packages)
- **Total Packages:** 1,449 installed
- **Location:** System-managed via dpkg
- **Migration:** Export with `dpkg --get-selections > packages.list`
- **Restore:** `dpkg --set-selections < packages.list && apt-get dselect-upgrade`

### UV Tools (Python - Modern)
| Tool | Version | Location | Purpose |
|------|---------|----------|---------|
| ansible | 11.9.0 | ~/.local/share/uv/tools/ansible | Automation framework |
| ansible-core | 2.19.1 | ~/.local/share/uv/tools/ansible-core | Core automation |
| ansible-builder | 3.1.0 | ~/.local/share/uv/tools/ansible-builder | Execution environment builder |
| ansible-creator | 25.8.0 | ~/.local/share/uv/tools/ansible-creator | Project scaffolding |
| ansible-lint | 25.8.2 | ~/.local/share/uv/tools/ansible-lint | Playbook linter |
| ansible-sign | 0.1.2 | ~/.local/share/uv/tools/ansible-sign | Content signing |
| molecule | 25.7.0 | ~/.local/share/uv/tools/molecule | Testing framework |
| ruff | 0.12.12 | ~/.local/share/uv/tools/ruff | Python linter/formatter |
| yamllint | 1.37.1 | ~/.local/share/uv/tools/yamllint | YAML linter |

**Export:** `uv tool list > uv-tools.txt`
**Restore:** Install via `uv tool install <tool>`

### NPM Global Packages
| Package | Version | Purpose |
|---------|---------|---------|
| @google/gemini-cli | 0.8.2 | AI CLI interface |
| @clduab11/gemini-flow | 1.3.3 | Workflow automation |
| @openai/codex | 0.46.0 | OpenAI CLI |
| @qwen-code/qwen-code | 0.0.14 | Qwen AI CLI |

**Export:** `npm list -g --depth=0 > npm-global.txt`

### Cargo Installed Binaries
- **Count:** 15 binaries in ~/.cargo/bin/
- **Primary:** eza (v0.23.1)
- **Location:** `~/.cargo/bin/`
- **Export:** `cargo install --list > cargo-tools.txt`

---

## 3. Shell Configurations & Environment

### Shell Setup
- **Current Shell:** ZSH (/usr/bin/zsh)
- **Available Shells:** bash, zsh, dash, tmux
- **History Management:** Atuin (cloud-synced shell history)

### Critical Configuration Files

| File | Purpose | Priority | Notes |
|------|---------|----------|-------|
| ~/.zshrc | ZSH interactive config | CRITICAL | Cluster-optimized, 307 lines |
| ~/.zprofile | ZSH login shell | HIGH | Sources ~/.profile |
| ~/.profile | Universal shell environment | CRITICAL | PATH, tool detection, 365 lines |
| ~/.bashrc | Bash config (fallback) | MEDIUM | Maintained for compatibility |
| ~/.bash_history | Bash history | LOW | Historical data |
| ~/.zsh_history | ZSH history | MEDIUM | Local history (Atuin primary) |
| ~/.bash-preexec.sh | Bash hook system | LOW | For hooks compatibility |

**Key Features in Shell Config:**
- Unified tool detection (HAS_* environment variables)
- Modern aliases (eza, bat, fd, rg, dust)
- FZF integration with fd backend
- Zoxide smart directory jumping
- Starship prompt with cluster awareness
- Atuin shell history sync
- Performance monitoring (startup time tracking)
- Cluster-specific shortcuts and navigation

### Environment Variables (Key)
```
PATH=~/.claude/local:~/.cargo/bin:~/.local/bin:/usr/local/bin:/usr/bin:/bin
EDITOR=vim
VISUAL=vim
GIT_PAGER=delta
CLUSTER_NAS=/cluster-nas
COOPERATOR_SERVICES_PATH=/opt/cooperator/services
XDG_CONFIG_HOME=~/.config
XDG_DATA_HOME=~/.local/share
XDG_CACHE_HOME=~/.cache
```

---

## 4. Modern CLI Tools (Rust-based)

| Tool | Version | Location | Purpose | Config |
|------|---------|----------|---------|--------|
| eza | 0.23.1 | ~/.cargo/bin/eza | ls replacement | Aliased in .zshrc |
| bat | - | /usr/local/bin/bat | cat replacement | ~/.config/bat/ |
| fd | - | /usr/local/bin/fd | find replacement | Used by FZF |
| ripgrep (rg) | - | /usr/bin/rg | grep replacement | Aliased in .zshrc |
| zoxide | - | ~/.local/bin/zoxide | Smart cd | ~/.local/share/zoxide/ |
| fzf | - | /usr/bin/fzf | Fuzzy finder | Integrated with fd |
| delta | - | /usr/bin/delta | Git diff viewer | GIT_PAGER=delta |
| dust | - | ~/.local/bin/dust | du replacement | Aliased in .zshrc |
| starship | - | ~/.local/bin/starship | Shell prompt | ~/.config/starship.toml |
| atuin | - | /usr/local/bin/atuin | History sync | ~/.local/share/atuin/ |
| nnn | - | System (aliased) | File manager | NNN_FIFO, NNN_PLUG configured |
| fastfetch | - | /usr/bin/fastfetch | System info | System installed |

**Migration Priority:** HIGH - These tools are deeply integrated into daily workflow

---

## 5. Git Configuration

### Git Config (~/.gitconfig)
```ini
[user]
    name = crtr
    email = rjallen22@gmail.com
    signingkey = ~/.ssh/id_ed25519.pub

[init]
    defaultBranch = main

[core]
    editor = nano
    pager = bat --paging=always
    autocrlf = input

[pull]
    rebase = true

[push]
    default = simple

[credential]
    helper = store

[gpg]
    format = ssh

[commit]
    gpgsign = true
```

**Priority:** CRITICAL
**Location:** `~/.gitconfig`
**Note:** Commit signing enabled with SSH key

---

## 6. SSH Keys & Configuration

### SSH Keys (CRITICAL - SECURE MIGRATION REQUIRED)

| Key Name | Location | Purpose | Public Key Location |
|----------|----------|---------|-------------------|
| id_ed25519 | ~/.ssh/id_ed25519 | Primary cluster key | ~/.ssh/id_ed25519.pub |
| id_ed25519_self | ~/.ssh/id_ed25519_self | Self-SSH (crtr→crtr) | ~/.ssh/id_ed25519_self.pub |
| id_ed25519_github | ~/.ssh/id_ed25519_github | GitHub authentication | ~/.ssh/id_ed25519_github.pub |
| id_rsa | ~/.ssh/id_rsa | Legacy RSA key | ~/.ssh/id_rsa.pub |

**Permissions:** All private keys are 0600 (owner read/write only)

### SSH Configuration (~/.ssh/config)
- **Size:** 2.5 KB
- **Purpose:** Cluster node definitions, GitHub access, connection multiplexing
- **Key Features:**
  - TERM=xterm-256color for all connections
  - Connection multiplexing (ControlMaster)
  - ControlPath: ~/.ssh/sockets/
  - ServerAliveInterval: 60s
  - Node definitions: crtr, zrtr, prtr, drtr, trtr
  - GitHub SSH config

**Backups Found:**
- config.backup (1.5 KB)
- config.backup.20251003-073039 (1.7 KB)
- config.bak (1.1 KB)

### SSH Other Files
- `~/.ssh/authorized_keys` - Authorized public keys for incoming connections
- `~/.ssh/known_hosts` - Known host fingerprints (13 KB)
- `~/.ssh/environment` - SSH environment variables
- `~/.ssh/rc` - SSH shell initialization script (552 bytes)
- `~/.ssh/sockets/` - Connection multiplexing sockets

**SECURITY WARNING:** Git credentials stored in plaintext at `~/.git-credentials`

---

## 7. Configuration Directories (~/.config/)

| Directory | Purpose | Priority | Size/Notes |
|-----------|---------|----------|------------|
| age/ | Age encryption | MEDIUM | Encryption keys |
| atuin/ | Shell history config | HIGH | Sync settings |
| bat/ | Bat theme config | MEDIUM | Syntax themes |
| bottom/ | System monitor | LOW | btm config |
| chezmoi/ | Dotfile manager | HIGH | Dotfile state |
| cursor/ | Cursor editor | MEDIUM | IDE settings |
| fastfetch/ | System info tool | LOW | Display config |
| git/ | Git config | HIGH | Additional git settings |
| ghostty/ | Terminal emulator | MEDIUM | Terminal config |
| nnn/ | File manager | LOW | Plugin config |
| nvim/ | Neovim editor | MEDIUM | Editor config |
| starship.toml | Prompt config | HIGH | Cluster-themed prompt (137 lines) |

**Additional Notable Configs:**
- `~/.tmux.conf` - Tmux configuration (154 lines, cluster-specific)

---

## 8. Docker Environment

### Running Containers
| Container | Image | Status | Purpose |
|-----------|-------|--------|---------|
| n8n | n8nio/n8n:latest | Up 4 days | Workflow automation |
| n8n-postgres | postgres:16-alpine | Up 4 days (healthy) | Database for n8n |

### Docker Images (Local)
| Repository | Tag | Size | Purpose |
|------------|-----|------|---------|
| searxng/searxng | latest | 157 MB | Search engine |
| postgres | 16-alpine | 273 MB | Database |
| n8nio/n8n | latest | 958 MB | Workflow automation |
| hello-world | latest | 5.2 kB | Test image |

### Docker Configuration
- **Version:** 28.5.1
- **Location:** System service
- **Data:** `/var/lib/docker/` (requires root/sudo for backup)
- **No named volumes** currently in use

**Migration Notes:**
- Export n8n configuration/workflows before migration
- Database dump required for n8n-postgres
- Docker compose file location: TBD (check /opt or project directories)

---

## 9. System Services & Automation

### Critical Systemd Services (Running)
| Service | Purpose | Priority | Config Location |
|---------|---------|----------|----------------|
| docker.service | Container runtime | CRITICAL | /etc/docker/ |
| caddy.service | Web server/proxy | HIGH | /etc/caddy/ |
| pihole-FTL.service | DNS/Ad-blocking | HIGH | /etc/pihole/ |
| atuin-server.service | Shell history sync | HIGH | Check systemd unit |
| containerd.service | Container runtime | CRITICAL | /etc/containerd/ |
| nfs-mountd.service | NFS server | CRITICAL | /etc/exports |
| gotty.service | Web terminal | MEDIUM | Check systemd unit |

### Cron Jobs
```cron
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
0 3 * * * /usr/local/bin/cluster-backup.sh
```

**Migration Priority:** CRITICAL
**Locations:**
- User crontab: `crontab -l`
- Scripts: `~/duckdns/duck.sh`, `/usr/local/bin/cluster-backup.sh`

### Systemd Timers
- dpkg-db-backup.timer - Daily dpkg database backup
- fake-hwclock-save.timer - Periodic clock save
- fstrim.timer - Weekly filesystem trim
- logrotate.timer - Daily log rotation
- systemd-tmpfiles-clean.timer - Daily temp cleanup

---

## 10. Custom Scripts & Tools

### /usr/local/bin/ (System-wide tools)
| Tool | Purpose | Type |
|------|---------|------|
| cluster-backup.sh | Cluster backup automation | Shell script |
| chezmoi | Dotfile manager | Binary |
| chezmoi-ansible | Ansible integration | Wrapper script |
| colab | Cluster management CLI | Custom tool |
| ac (ansible-center) | Ansible shortcut | Symlink to /opt/ansible/scripts/ |
| gotty | Web-based terminal | Binary |
| ttyd | Web-based terminal | Binary |
| semaphore | Ansible UI/API | Binary |
| atuin | Shell history | Binary |
| starship | Shell prompt | Binary |
| eza, bat, fd, nvim, pihole | Modern CLI tools | Various binaries |

### Custom Cluster Scripts
- `~/.cluster-functions.sh` - Sourced by .zshrc
- `~/.cluster-mgmt.sh` - Sourced by .zshrc

### Meta-Management Function
- **Defined in:** ~/.profile
- **Purpose:** Initialize `.meta` template system for repos
- **Commands:** `meta --cluster`, `meta --node`, `meta --service`, etc.

---

## 11. Application Data & State

### Important Data Directories
| Path | Purpose | Size | Backup Priority |
|------|---------|------|----------------|
| ~/Projects/ | Active projects | Multiple subdirs | CRITICAL |
| ~/.local/share/atuin/ | Shell history database | Growing | HIGH |
| ~/.local/share/zoxide/ | Directory jump database | Small | MEDIUM |
| ~/.local/share/uv/ | Python tool installations | ~500 MB | HIGH |
| ~/.local/share/chezmoi/ | Dotfile backups | Various | HIGH |
| ~/.cargo/ | Rust toolchain + binaries | ~1 GB | MEDIUM |
| ~/.cache/ | Application caches | Variable | LOW |

### Current Projects (~/Projects/)
- crtr-config/ - Current working directory
- colab-config/ - Cluster configuration
- meta-framework/ - Meta template framework
- qcash/ - Project
- .meta/ - Meta templates
- .meta-template/ - Template source
- .stems/ - Stem templates

---

## 12. Credentials & Secrets (LOCATIONS ONLY)

**CRITICAL SECURITY NOTICE:** These files contain sensitive data. Migrate securely.

| Type | Location | Purpose | Permissions |
|------|----------|---------|-------------|
| SSH Private Keys | ~/.ssh/id_* (no .pub) | Authentication | 0600 (owner only) |
| Git Credentials | ~/.git-credentials | HTTPS git auth | 0600 (PLAINTEXT!) |
| Claude Config | ~/.claude.json | Claude CLI config | Check permissions |
| Age Keys | ~/.config/age/ | Encryption keys | Check directory |
| SSH Authorized Keys | ~/.ssh/authorized_keys | Incoming SSH auth | 0600 |

**Secure Migration Procedure:**
1. **DO NOT** copy credentials via insecure channels
2. Use `rsync` with SSH: `rsync -av --chmod=0600 ~/.ssh/id_* newhost:~/.ssh/`
3. Verify permissions after transfer: `chmod 600 ~/.ssh/id_*`
4. Consider rotating credentials after migration
5. Store backup of keys in encrypted offline storage

**RECOMMENDATION:** Consider using a password manager or secrets manager instead of plaintext storage (e.g., `git-credential-libsecret`, `pass`, `1password-cli`)

---

## 13. Dotfiles Summary

### Primary Dotfiles
| File | Size | Purpose | Managed By | Priority |
|------|------|---------|------------|----------|
| .profile | 365 lines | Universal environment | Manual/chezmoi | CRITICAL |
| .zshrc | 307 lines | ZSH interactive config | Manual/chezmoi | CRITICAL |
| .zprofile | 22 lines | ZSH login shell | Manual/chezmoi | HIGH |
| .bashrc | - | Bash config (fallback) | Manual/chezmoi | MEDIUM |
| .gitconfig | 30 lines | Git configuration | Manual | CRITICAL |
| .tmux.conf | 154 lines | Tmux configuration | Manual/chezmoi | HIGH |
| .config/starship.toml | 137 lines | Prompt configuration | Manual/chezmoi | HIGH |

### Dotfile Management System
- **System:** Chezmoi (template-based dotfile manager)
- **Source Repository:** `git@github.com:IMUR/dotfiles.git`
- **Source Path:** `/home/crtr/Projects/colab-config/dotfiles/` (git submodule)
- **Parent Repository:** `git@github.com:IMUR/colab-config.git`
- **Config:** `~/.config/chezmoi/` (local state)
- **Templates:** Node-aware, architecture-aware, capability-aware

**Managed Files (Templated):**
- `dot_profile.tmpl` → `~/.profile` (365 lines, universal environment)
- `dot_zshrc.tmpl` → `~/.zshrc` (307 lines, interactive shell)
- `dot_bashrc.tmpl` → `~/.bashrc` (bash fallback)
- `dot_tmux.conf.tmpl` → `~/.tmux.conf` (154 lines, cluster-themed)
- `dot_ssh/config.tmpl` → `~/.ssh/config` (SSH configuration)
- `dot_ssh/executable_rc` → `~/.ssh/rc` (SSH initialization)
- `dot_config/starship.toml` → `~/.config/starship.toml` (prompt config)
- `dot_config/atuin/` → `~/.config/atuin/` (history sync config)
- `dot_cluster-functions.sh` → `~/.cluster-functions.sh` (cluster utilities)
- `dot_cluster-mgmt.sh` → `~/.cluster-mgmt.sh` (cluster management)

**Template Variables:**
- `hostname`: Auto-detected node name
- `arch`: Architecture (aarch64/x86_64)
- `is_arm64`, `is_x86_64`: Architecture flags
- `cluster.nas_path`, `cluster.domain`, `cluster.network`: Cluster config

**CRITICAL MIGRATION ADVANTAGE:**
Chezmoi eliminates manual dotfile copying! The entire configuration is version-controlled and can be applied with a single command.

**Proper Migration Strategy:**
1. **Clone repositories on new system:**
   ```bash
   cd ~/Projects
   git clone --recursive git@github.com:IMUR/colab-config.git
   # OR if already cloned without --recursive:
   git clone git@github.com:IMUR/colab-config.git
   cd colab-config
   git submodule update --init --recursive
   ```

2. **Initialize chezmoi:**
   ```bash
   chezmoi init --source ~/Projects/colab-config/dotfiles
   ```

3. **Preview changes:**
   ```bash
   chezmoi diff  # See what will change
   ```

4. **Apply dotfiles:**
   ```bash
   chezmoi apply  # Generate all dotfiles from templates
   ```

5. **Verify templating:**
   ```bash
   chezmoi doctor  # Validate configuration
   ```

**Benefits:**
- No manual copying of individual dotfiles
- Automatic adaptation to new node's architecture/hostname
- Version-controlled changes
- Easy rollback: `git checkout` and `chezmoi apply`
- Consistent configuration across cluster nodes

---

## Migration Roadmap

### Phase 1: Pre-Migration Preparation (1-2 hours)

#### 1.1 Data Export & Backup
```bash
# System package list
dpkg --get-selections > ~/migration/packages.list
apt-mark showmanual > ~/migration/manually-installed.list

# Python tools
uv tool list > ~/migration/uv-tools.txt
pip list --user > ~/migration/pip-user.txt

# Node.js global packages
npm list -g --depth=0 > ~/migration/npm-global.txt

# Rust installed tools
cargo install --list > ~/migration/cargo-tools.txt

# Cron jobs
crontab -l > ~/migration/crontab.txt

# Systemd services
systemctl list-unit-files --state=enabled > ~/migration/systemd-enabled.txt

# Docker exports
docker ps -a --format "{{.Names}},{{.Image}},{{.Status}}" > ~/migration/docker-containers.csv
docker images --format "{{.Repository}}:{{.Tag}}" > ~/migration/docker-images.txt

# Environment variables
env | sort > ~/migration/environment.txt
```

#### 1.2 Application Data Backup
```bash
# Create migration directory
mkdir -p ~/migration/{configs,data,keys}

# Backup SSH keys (CRITICAL - not managed by chezmoi for security)
rsync -av ~/.ssh/ ~/migration/keys/ssh/ --exclude=sockets

# Backup non-chezmoi configs (application-specific settings)
rsync -av ~/.config/age/ ~/migration/configs/age/ 2>/dev/null || true
rsync -av ~/.config/cursor/ ~/migration/configs/cursor/ 2>/dev/null || true
# Note: Most ~/.config/ is managed by chezmoi, no need to backup manually

# Backup application data
rsync -av ~/.local/share/atuin/ ~/migration/data/atuin/
rsync -av ~/.local/share/zoxide/ ~/migration/data/zoxide/
rsync -av ~/Projects/ ~/migration/data/Projects/

# Docker container data (n8n workflows)
docker exec n8n n8n export:workflow --all --output=/data/workflows-backup.json
docker exec n8n-postgres pg_dump -U postgres n8n > ~/migration/data/n8n-postgres.sql
```

**Note on Dotfiles:** Since your dotfiles are managed by chezmoi and stored in `git@github.com:IMUR/dotfiles.git`, you don't need to backup `.zshrc`, `.profile`, `.tmux.conf`, etc. manually. Just clone the repository on the new system and run `chezmoi apply`.

#### 1.3 Secure Credential Migration
```bash
# Create encrypted archive for credentials
tar czf - ~/.ssh/id_* ~/.git-credentials ~/.claude.json | \
    gpg --symmetric --cipher-algo AES256 -o ~/migration/credentials.tar.gz.gpg

# Verify archive
gpg --decrypt ~/migration/credentials.tar.gz.gpg | tar tzf -
```

### Phase 2: New System Setup (2-3 hours)

#### 2.1 Base System Installation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install from package list (selective)
# Review packages.list first, remove unnecessary packages
sudo dpkg --set-selections < packages.list
sudo apt-get dselect-upgrade

# Or install critical packages manually:
sudo apt install -y \
    zsh git curl wget build-essential \
    docker.io containerd \
    python3 python3-pip python3-venv \
    nodejs npm golang-go perl \
    tmux vim nano ripgrep fzf
```

#### 2.2 Rust Toolchain
```bash
# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install Rust tools
cargo install eza
```

#### 2.3 Modern Python Tooling
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install pipx
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Reinstall UV tools
uv tool install ansible-core
uv tool install ansible
uv tool install ansible-lint
uv tool install molecule
uv tool install ruff
uv tool install yamllint
```

#### 2.4 Modern CLI Tools
```bash
# Install from binaries or package managers
# bat, fd, ripgrep, delta, dust, starship, atuin, etc.
# Refer to each tool's installation documentation

# Example for starship:
curl -sS https://starship.rs/install.sh | sh

# Example for atuin:
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
```

### Phase 3: Configuration Restoration (1-2 hours - Simplified with Chezmoi!)

#### 3.1 Dotfiles Restoration (Chezmoi Method - RECOMMENDED)
```bash
# Clone colab-config repository with dotfiles submodule
cd ~/Projects
git clone --recursive git@github.com:IMUR/colab-config.git

# Initialize chezmoi with dotfiles source
chezmoi init --source ~/Projects/colab-config/dotfiles

# Preview what will be created/changed
chezmoi diff

# Apply all dotfiles (generates from templates automatically)
chezmoi apply

# Verify configuration
chezmoi doctor

# Set ZSH as default shell
chsh -s $(which zsh)

# Source the new configuration
exec zsh
```

**Chezmoi Benefits:**
- Automatic generation of all dotfiles from templates
- Node-specific adaptation (hostname, architecture)
- No manual file copying required
- Version controlled and easy to update
- Consistent across all cluster nodes

#### 3.1.1 Manual Dotfiles Restoration (Fallback - NOT RECOMMENDED)
**Only use if chezmoi method fails**
```bash
# Copy dotfiles manually
rsync -av ~/migration/configs/dot-config/ ~/.config/
cp ~/migration/.profile ~/.profile
cp ~/migration/.zprofile ~/.zprofile
cp ~/migration/.zshrc ~/.zshrc
cp ~/migration/.bashrc ~/.bashrc
cp ~/migration/.gitconfig ~/.gitconfig
cp ~/migration/.tmux.conf ~/.tmux.conf

# Set ZSH as default shell
chsh -s $(which zsh)
```

#### 3.2 SSH & Credentials (SECURE)
```bash
# Decrypt and restore credentials
gpg --decrypt ~/migration/credentials.tar.gz.gpg | tar xzf - -C ~/

# Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
chmod 600 ~/.ssh/config
chmod 600 ~/.git-credentials

# Verify SSH keys
ssh-keygen -l -f ~/.ssh/id_ed25519
ssh-keygen -l -f ~/.ssh/id_ed25519_github
```

#### 3.3 Application Data Restoration
```bash
# Restore application data
mkdir -p ~/.local/share
rsync -av ~/migration/data/atuin/ ~/.local/share/atuin/
rsync -av ~/migration/data/zoxide/ ~/.local/share/zoxide/

# Restore projects
rsync -av ~/migration/data/Projects/ ~/Projects/
```

### Phase 4: Service & Docker Setup (2-3 hours)

#### 4.1 Docker Setup
```bash
# Ensure Docker is running
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

# Pull images
docker pull n8nio/n8n:latest
docker pull postgres:16-alpine
docker pull searxng/searxng:latest

# Restore n8n with docker compose (create docker-compose.yml first)
docker-compose up -d
```

#### 4.2 Systemd Services
```bash
# Review and restore systemd services
# Caddy, Pi-hole, atuin-server, gotty, etc.
# This is highly environment-specific

# Restore cron jobs
crontab ~/migration/crontab.txt
```

#### 4.3 NFS & Cluster Integration
```bash
# Configure NFS (if cooperator role)
# Setup /etc/exports
# Setup cluster mount points
```

### Phase 5: Verification & Testing (1-2 hours)

#### 5.1 Tool Verification
```bash
# Verify all tools are accessible
which git python3 node npm docker rustc cargo go
which eza bat fd rg zoxide fzf delta dust starship atuin

# Check versions
git --version
python3 --version
node --version
cargo --version
```

#### 5.2 Configuration Verification
```bash
# Test shell configuration
zsh -c "echo \$PATH"
zsh -c "source ~/.zshrc && type eza"

# Test SSH connections
ssh -T git@github.com
ssh crtr  # Test cluster SSH if applicable

# Test Git
cd ~/Projects/crtr-config
git status
git log --show-signature -1  # Verify commit signing
```

#### 5.3 Service Verification
```bash
# Check Docker containers
docker ps
curl localhost:5678  # n8n (adjust port)

# Test systemd services
systemctl status docker
systemctl status caddy  # If applicable

# Verify cron jobs
crontab -l
```

---

## Quick Reference Checklist

### Pre-Migration
- [ ] Export package lists (apt, uv, npm, cargo)
- [ ] ~~Backup all dotfiles~~ **SKIP** - Managed by chezmoi/git
- [ ] Verify access to `git@github.com:IMUR/dotfiles.git` and `git@github.com:IMUR/colab-config.git`
- [ ] Backup application configs NOT managed by chezmoi (cursor, age, etc.)
- [ ] Export Docker container configs and data
- [ ] Backup SSH keys and Git credentials (SECURE!)
- [ ] Export cron jobs and systemd service configs
- [ ] Backup project directories
- [ ] Document running services and their configs
- [ ] Create encrypted credential archive
- [ ] Test chezmoi on new system: `chezmoi diff` (optional but recommended)

### New System Setup
- [ ] Install base OS (match architecture if critical)
- [ ] Install system packages (from exported list)
- [ ] Install Rust via rustup
- [ ] Install uv (Python package manager)
- [ ] Install modern CLI tools (eza, bat, fd, rg, etc.)
- [ ] Install Node.js and npm
- [ ] Install Docker
- [ ] Set up ZSH as default shell

### Configuration Migration
- [ ] Clone colab-config repository: `git clone --recursive git@github.com:IMUR/colab-config.git`
- [ ] Initialize chezmoi: `chezmoi init --source ~/Projects/colab-config/dotfiles`
- [ ] Preview chezmoi changes: `chezmoi diff`
- [ ] Apply dotfiles: `chezmoi apply`
- [ ] Verify chezmoi: `chezmoi doctor`
- [ ] Restore SSH keys (verify permissions 0600!)
- [ ] Restore Git credentials (consider rotating)
- [ ] Restore ~/.local/share/ application data (atuin, zoxide)
- [ ] Restore ~/Projects/ directory
- [ ] Change shell: `chsh -s $(which zsh)`
- [ ] Source shell configs: `exec zsh` or logout/login

### Service & Application Setup
- [ ] Reinstall UV Python tools
- [ ] Reinstall global npm packages
- [ ] Reinstall Rust cargo tools
- [ ] Restore Docker containers (docker-compose)
- [ ] Restore cron jobs
- [ ] Enable and start systemd services
- [ ] Configure cluster-specific settings (NFS, node configs)

### Verification
- [ ] All command-line tools accessible
- [ ] Shell prompt displays correctly (starship)
- [ ] SSH connections work (cluster nodes, GitHub)
- [ ] Git operations work (clone, commit with signing)
- [ ] Docker containers running
- [ ] Cron jobs scheduled
- [ ] Systemd services active
- [ ] Application data accessible
- [ ] Modern CLI tools working (eza, bat, fd, etc.)
- [ ] Python/Node/Rust environments functional
- [ ] History syncing (Atuin)

### Post-Migration Cleanup
- [ ] Verify no data left on old system
- [ ] Rotate compromised credentials (if any)
- [ ] Update DNS/network configs (if hostname changed)
- [ ] Update cluster node registry (if applicable)
- [ ] Test backup/restore procedure on new system
- [ ] Document any migration issues for future reference

---

## Critical Migration Notes

### Architecture Considerations
- **Source:** ARM64 (aarch64) Raspberry Pi
- **Target:** Ensure architecture compatibility or rebuild binaries
- **Docker:** ARM64 images required (check image manifests)

### Cluster-Specific Requirements
- Node role definitions in configs
- NFS server configuration (/etc/exports)
- Cluster SSH key infrastructure
- Shared storage mount points (/cluster-nas)
- Node IP addressing (192.168.254.10 for cooperator)

### Security Best Practices
1. Never transfer credentials over unencrypted channels
2. Use `rsync` over SSH for file transfers
3. Verify file permissions after restoration
4. Consider credential rotation after migration
5. Store encrypted backups offline
6. Test SSH key authentication before removing old keys

### Common Pitfalls
- Forgetting to set correct permissions on SSH keys (0600)
- Not sourcing profile files after restoration
- Missing environment variables (HAS_* detection flags)
- Docker containers not starting due to volume/network issues
- Cron jobs failing due to incorrect paths
- Systemd services not enabled on boot
- Git commit signing failing due to missing GPG/SSH setup
- Modern CLI tools not in PATH

---

## Automation Opportunities

### Dotfile Management
- Current: Appears to use chezmoi
- Recommendation: Leverage chezmoi for automated dotfile sync
- Repository: Create/maintain chezmoi repo for instant setup

### Configuration as Code
- Ansible playbooks for system setup
- Docker Compose for service orchestration
- Shell scripts for post-install automation

### Backup Automation
- Regular automated backups of critical configs
- Cloud sync for non-sensitive configs (GitHub)
- Encrypted backups for credentials (restic, borg, etc.)

---

**End of Migration Inventory**

Generated by Claude Code
Source: Comprehensive system discovery (2025-10-14)
