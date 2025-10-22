# Migration Status - Cooperator Node
**Updated:** 2025-10-21
**Node:** cooperator (192.168.254.10)
**Platform:** Raspberry Pi 5, Debian 13 (Trixie), Linux 6.12.47
**User:** crtr

---

## Executive Summary

**Migration from old SD card to fresh Debian 13 install on same hardware**

### Current Status: 🟡 **In Progress** (≈70% Complete)

- ✅ **Phase 1:** Base system installed
- ✅ **Phase 2:** Core development tools installed
- ✅ **Phase 3:** Chezmoi dotfiles deployed and working
- ✅ **Phase 4:** Modern CLI tools installed (eza, bat, zoxide, dust, delta, starship, atuin)
- ✅ **Phase 5:** SSH keys & Git config migrated
- 🟡 **Phase 6:** Python/Node ecosystems (uv, pipx, Node.js - not yet installed)
- 🟡 **Phase 7:** Services restoration (Docker ready, containers not restored)
- ⬜ **Phase 8:** Data restoration (history, projects, etc.)

---

## ✅ Completed Migration Tasks

### System Foundation
- [x] Fresh Debian 13 (Trixie) installed on Raspberry Pi 5
- [x] Base packages installed (git, build-essential, etc.)
- [x] User account configured (crtr)

### Chezmoi Dotfile System
- [x] Chezmoi v2.66.0 installed (`~/.local/bin/chezmoi`)
- [x] Dotfiles repository cloned from `github.com/IMUR/dotfiles`
- [x] Source directory: `~/.local/share/chezmoi/` (clean working tree)
- [x] Configuration: `~/.config/chezmoi/chezmoi.toml`
- [x] All dotfiles generated and deployed via `chezmoi apply`

**Managed Files (13 total):**
```
.bashrc                      # Bash fallback shell config
.cluster-functions.sh        # Cluster utility functions
.cluster-mgmt.sh            # Cluster management functions
.config/atuin/config.toml   # Shell history sync config
.config/starship.toml       # Starship prompt config
.profile                    # Universal shell environment
.ssh/config                 # SSH client configuration
.ssh/rc                     # SSH session init script
.tmux.conf                  # Tmux multiplexer config
.zshrc                      # ZSH interactive shell config
README.md                   # Dotfiles documentation
```

### Shell Environment
- [x] Bash installed (`/usr/bin/bash`)
- [x] ZSH installed (`/usr/bin/zsh`)
- [x] ZSH set as default shell
- [x] PATH properly configured:
  ```
  ~/.atuin/bin
  ~/.cargo/bin
  ~/.local/bin
  /usr/local/sbin:/usr/local/bin
  /usr/sbin:/usr/bin
  /sbin:/bin
  /usr/local/games:/usr/games
  ```

### Development Languages
- [x] **Git** 2.47.3 (`/usr/bin/git`)
- [x] **Rust** via rustup (`~/.cargo/bin/`)
  - rustc, cargo, clippy, rustfmt, rust-analyzer
- [x] **Python 3.13.5** (`/usr/bin/python3`)
- [x] **Docker** 28.5.1 (`/usr/bin/docker`)
- [x] **Perl** (system)

### Modern CLI Tools (Rust-based)
- [x] **starship** - Shell prompt (`~/.local/bin/starship`)
- [x] **atuin** - Shell history sync (`~/.atuin/bin/atuin`)
- [x] **eza** v0.23.4 - ls replacement (`~/.cargo/bin/eza`)
- [x] **zoxide** v0.9.8 - Smart cd (`~/.cargo/bin/zoxide`)
- [x] **bat** - cat replacement (`~/.cargo/bin/bat`)
- [x] **dust** - du replacement (`~/.cargo/bin/dust`)
- [x] **delta** - Git diff viewer (`~/.cargo/bin/delta`)

### System Packages (APT)
- [x] **tmux** - Terminal multiplexer (`/usr/bin/tmux`)
- [x] **vim** - Text editor (`/usr/bin/vim`)
- [x] **ripgrep** - grep replacement (`/usr/bin/rg`)
- [x] **fzf** - Fuzzy finder (`/usr/bin/fzf`)
- [x] **fd-find** - find replacement (`/usr/bin/fdfind`)
- [x] **build-essential** - Compilers and build tools

---

## ✅ Recently Verified (2025-10-21)

### SSH & Credentials
- [x] **SSH keys migrated successfully** ✅
  - `~/.ssh/id_ed25519` (primary cluster key) - Present, perms 600
  - `~/.ssh/id_ed25519_self` (self-SSH) - Present, perms 600
  - `~/.ssh/id_ed25519_github` (GitHub auth) - Present, perms 600
  - `~/.ssh/id_rsa` (legacy RSA) - Present, perms 600
  - All public keys (.pub) present with perms 644

### Git Configuration
- [x] **Git config complete** ✅
  - User: crtr <rjallen22@gmail.com>
  - Commit signing: ENABLED (SSH format)
  - Signing key: `~/.ssh/id_ed25519.pub`
  - Core pager: `bat --paging=always`
  - Credential helper: store

**Status:** Ready for testing GitHub access and commit signing

### Docker
- [x] **Docker installed** ✅
  - Version: 28.5.1, build e180ab8
  - Location: `/usr/bin/docker`
  - Status: Ready for container restoration

---

## ⬜ Pending Migration Tasks

### Python Ecosystem
- [ ] **uv** - Modern Python package manager
  - Install: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [ ] **pipx** - Python app isolation
- [ ] **UV Tools** to install:
  - [ ] ansible-core
  - [ ] ansible
  - [ ] ansible-lint
  - [ ] ansible-builder
  - [ ] ansible-creator
  - [ ] molecule
  - [ ] ruff
  - [ ] yamllint

### Node.js Ecosystem
- [ ] **Install Node.js** (v20+ LTS recommended)
  - Recommended: Use nvm or official NodeSource repository
  - Command: `curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs`
- [ ] **Global NPM packages** to install (after Node.js):
  - [ ] @google/gemini-cli
  - [ ] @clduab11/gemini-flow
  - [ ] @openai/codex
  - [ ] @qwen-code/qwen-code

### Services & Infrastructure
- [x] **Docker** ✅ Installed (v28.5.1)
  - [ ] Verify docker.service running
  - [ ] Verify user in docker group: `sudo usermod -aG docker crtr`
  - [ ] Test: `docker ps` (should work without sudo)
- [ ] **Docker Containers** restoration:
  - [ ] n8n (workflow automation)
  - [ ] n8n-postgres (database)
  - [ ] searxng (search engine)
- [ ] **Caddy** - Web server/reverse proxy
- [ ] **Pi-hole** - DNS/ad-blocking
- [ ] **NFS** - Network file sharing
  - [ ] Configure /etc/exports
  - [ ] Mount points (/cluster-nas)
- [ ] **Atuin Server** - Shell history sync server
- [ ] **GoTTY** - Web terminal

### Application Data Restoration
- [ ] **Atuin history database**
  - Source: Old system `~/.local/share/atuin/`
  - Destination: `~/.local/share/atuin/`
- [ ] **Zoxide directory database**
  - Source: Old system `~/.local/share/zoxide/`
  - Destination: `~/.local/share/zoxide/`
- [ ] **Projects directory**
  - Source: Old system `~/Projects/`
  - Destination: `~/Projects/`
- [ ] **Docker container data**
  - n8n workflows
  - n8n database dump
- [ ] **Custom scripts**
  - `/usr/local/bin/cluster-backup.sh`
  - `/usr/local/bin/colab`
  - Other custom tools

### System Configuration
- [ ] **Cron jobs** restoration
  ```cron
  */5 * * * * ~/duckdns/duck.sh
  0 3 * * * /usr/local/bin/cluster-backup.sh
  ```
- [ ] **Systemd services** configuration
- [ ] **Cluster-specific configuration**
  - Node role definitions
  - NFS mounts
  - Cluster SSH infrastructure

### Security & Credentials (VERIFY ONLY)
- [ ] Verify SSH key permissions (0600)
- [ ] Test SSH connections to cluster nodes
- [ ] Test GitHub SSH authentication
- [ ] Verify git commit signing works
- [ ] Test git push/pull with credentials

---

## 📝 Notes & Insights

### Chezmoi Architecture

**Repository Structure:**
```
github.com/IMUR/dotfiles (remote)
         ↓ git clone
~/.local/share/chezmoi/ (local source)
         ↓ chezmoi apply
~/ (generated dotfiles)
```

**Key Commands:**
```bash
chezmoi diff           # Preview changes
chezmoi apply          # Generate dotfiles from templates
chezmoi edit ~/.zshrc  # Edit template (not final file!)
chezmoi update         # Pull from git + apply
chezmoi doctor         # Health check
```

**Template System:**
- Templates use Go template syntax
- Variables: hostname, arch, cluster.*
- Enables node-adaptive configurations
- Example: `{{- if eq .hostname "cooperator" }}`

### PATH Management

✅ **Current PATH is correct** (as of 2025-10-21):
```
~/.atuin/bin          # Atuin shell history
~/.cargo/bin          # Rust tools (eza, bat, zoxide, dust, delta)
~/.local/bin          # Standalone installers (chezmoi, starship)
/usr/local/sbin       # System-wide manual installs
/usr/local/bin
/usr/sbin:/usr/bin    # APT packages
/sbin:/bin            # System binaries
/usr/local/games:/usr/games
```

**Strategy:** Shell configs (`.profile`, `.zshrc`) are managed by chezmoi templates and automatically construct the proper PATH.

### Migration Advantages

**Chezmoi eliminates manual dotfile copying:**
- Old approach: Copy dozens of files individually
- New approach: `chezmoi apply` generates everything
- Time savings: Hours → Minutes
- Consistency: Same source, different node adaptations

**What chezmoi manages:** Shell configs, SSH config, tmux, starship, atuin, cluster scripts
**What chezmoi does NOT manage:** SSH keys, git credentials, .gitconfig (security-sensitive)

### Security Considerations

**Files NEVER managed by chezmoi:**
- Private SSH keys (`~/.ssh/id_*` without .pub)
- Git credentials (`~/.git-credentials`)
- Personal git config (`~/.gitconfig`)
- Encryption keys (`~/.config/age/`)

**Migration Method:**
- Secure transfer: Use `rsync` over SSH
- Verify permissions: `chmod 600` for private keys
- Consider credential rotation after migration

---

## Next Steps (Priority Order)

1. **Verify SSH & Git Setup**
   - Test SSH key authentication
   - Verify git commit signing
   - Test GitHub access

2. **Install Python Ecosystem**
   - Install uv and pipx
   - Install ansible, ruff, yamllint via uv

3. **Install Node.js Global Packages**
   - Verify Node.js version
   - Install global packages

4. **Docker & Services**
   - Install Docker
   - Restore containers (n8n, postgres)
   - Configure systemd services

5. **Data Restoration**
   - Restore atuin history
   - Restore zoxide database
   - Restore projects directory

6. **Final Verification**
   - Test all tools and commands
   - Verify services running
   - Test cluster connectivity

---

## References

- **Migration Inventory:** `MIGRATION_INVENTORY.md` (comprehensive system snapshot from old system)
- **Chezmoi Manifest:** `chezmoi-manifest.md` (conceptual documentation)
- **Configuration Manifest:** `configuration-manifest.md` (installation tracking - OUTDATED)
- **Dotfiles Repository:** https://github.com/IMUR/dotfiles
- **Chezmoi Docs:** https://chezmoi.io/

---

**Status Key:**
- ✅ = Completed
- 🟡 = In Progress / Partial
- ⬜ = Not Started
- [?] = Needs Verification

**Last Updated:** 2025-10-21 by Claude Code
