# Chezmoi Manifest

Quick reference for dotfiles installation confirmation

**Node:** cooperator | **Updated:** 2025-10-19

---

## Current PATH

```
/home/crtr/.local/bin
/home/crtr/.bun/bin
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
/usr/local/games
/usr/games
```

**Issues:**
- Duplicates in PATH (.local/bin appears 3x, .bun/bin appears 2x) - needs cleanup in shell config
- `~/.cargo/bin` needs to be added permanently to PATH in shell config
- `~/.atuin/bin` needs to be added permanently to PATH in shell config

---

## INSTALLED - Meta-Tools

### chezmoi
 - Install: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply IMUR`
 - Binary Location: `~/.local/bin/chezmoi`
 - Configuration Location: `~/.config/chezmoi/chezmoi.toml`
 - Dotfile location: Source templates in `~/.local/share/chezmoi/` (cloned from github.com/IMUR/dotfiles)

### rustup / cargo
 - Install: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y`
 - Binary Location: `~/.cargo/bin/` (rustc, cargo, rustup)
 - Configuration Location: `~/.cargo/env`
 - Version: rustc 1.90.0, cargo 1.90.0
 - Dotfile location: N/A (environment sourced by shells)

### apt
 - Installation method: System package manager
 - Binary Location: `/usr/bin/apt`
 - Configuration Location: `/etc/apt/`
 - Dotfile location: N/A

---

## INSTALLED - Shells & Environment

### bash
 - Installation method: System default (currently active)
 - Binary Location: `/usr/bin/bash`
 - Configuration Location: `~/.bashrc`
 - Dotfile location: `~/.local/share/chezmoi/dot_bashrc.tmpl` → `~/.bashrc` (chezmoi-managed)

### zsh
 - Install: `apt install zsh` + `sudo chsh -s $(which zsh) crtr`
 - Binary Location: `/usr/bin/zsh`
 - Configuration Location: `~/.zshrc`
 - Dotfile location: `~/.local/share/chezmoi/dot_zshrc.tmpl` → `~/.zshrc` (chezmoi-managed)
 - **Note:** Installed but not default shell yet (requires logout/login)

### profile
 - Installation method: System default
 - Binary Location: N/A (not a binary)
 - Configuration Location: `~/.profile`
 - Dotfile location: `~/.local/share/chezmoi/dot_profile.tmpl` → `~/.profile` (chezmoi-managed)

---

## INSTALLED - Chezmoi-Managed Configs

### ssh
 - Installation method: System default
 - Binary Location: `/usr/bin/ssh`
 - Configuration Location: `~/.ssh/config`
 - Dotfile location: `~/.local/share/chezmoi/dot_ssh/config.tmpl` → `~/.ssh/config` (chezmoi-managed, keys NOT managed)

### tmux
 - Install: `apt install tmux`
 - Binary Location: `/usr/bin/tmux`
 - Configuration Location: `~/.tmux.conf`
 - Dotfile location: `~/.local/share/chezmoi/dot_tmux.conf.tmpl` → `~/.tmux.conf` (chezmoi-managed)

---

## INSTALLED - APT Packages

### git
 - Install: `apt install git`
 - Binary Location: `/usr/bin/git`
 - Configuration Location: See .gitconfig in Manual section
 - Dotfile location: N/A

### ripgrep
 - Install: `apt install ripgrep`
 - Binary Location: `/usr/bin/rg`
 - Configuration Location: None
 - Dotfile location: N/A

### fzf
 - Install: `apt install fzf`
 - Binary Location: `/usr/bin/fzf`
 - Configuration Location: Integrated in shell configs
 - Dotfile location: Config in `~/.zshrc` (chezmoi-managed)

### fd-find
 - Install: `apt install fd-find`
 - Binary Location: `/usr/bin/fdfind` (aliased as `fd`)
 - Configuration Location: None
 - Dotfile location: Alias in `~/.zshrc` (chezmoi-managed)

### vim
 - Install: `apt install vim`
 - Binary Location: `/usr/bin/vim`
 - Configuration Location: `~/.vimrc` (not yet configured)
 - Dotfile location: N/A

### build-essential
 - Install: `apt install build-essential`
 - Binary Location: `/usr/bin/gcc`, `/usr/bin/g++`, `/usr/bin/make`
 - Configuration Location: N/A
 - Dotfile location: N/A

---

## INSTALLED - Standalone Installer Tools

### starship
 - Install: `curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin`
 - Binary Location: `~/.local/bin/starship`
 - Configuration Location: `~/.config/starship.toml`
 - Dotfile location: `~/.local/share/chezmoi/dot_config/starship.toml` → `~/.config/starship.toml` (chezmoi-managed)

### atuin
 - Install: `curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh`
 - Binary Location: `~/.atuin/bin/atuin`
 - Configuration Location: `~/.config/atuin/`
 - Data Location: `~/.local/share/atuin/` (history database)
 - Dotfile location: `~/.local/share/chezmoi/dot_config/atuin/` → `~/.config/atuin/` (chezmoi-managed)

---

## INSTALLED - Cargo Tools

### eza
 - Install: `cargo install eza`
 - Binary Location: `~/.cargo/bin/eza`
 - Version: 0.23.4
 - Configuration Location: None (uses CLI flags + shell aliases)
 - Dotfile location: Aliases in `~/.zshrc` (chezmoi-managed)

### zoxide
 - Install: `cargo install zoxide`
 - Binary Location: `~/.cargo/bin/zoxide`
 - Version: 0.9.8
 - Data Location: `~/.local/share/zoxide/` (directory jump database)
 - Configuration Location: Integrated in shell configs
 - Dotfile location: Shell init hooks in `~/.zshrc` (chezmoi-managed)

---

## INSTALLED - Manual (NOT Automated)

### ssh-keys
 - Installation method: Manual copy from old system
 - Configuration Location: `~/.ssh/id_ed25519*`, `id_rsa*` (8 keys total)
 - Dotfile location: NOT managed (security-sensitive)

### git-credentials
 - Installation method: Manual copy
 - Configuration Location: `~/.git-credentials`
 - Dotfile location: NOT managed (plaintext passwords)

### gitconfig
 - Installation method: Manual copy from old system
 - Configuration Location: `~/.gitconfig`
 - Dotfile location: NOT managed (contains email, signing key)
 - **Note:** Could be templated in chezmoi but currently isn't

---

## PENDING - Cargo Tools

### bat
 - Install: `cargo install bat`
 - **Status:** Currently installing (compiling in background)

### dust
 - Install: `cargo install du-dust`

### delta
 - Install: `cargo install git-delta`

---

## PENDING - Standalone Tools

### infisical
 - Install: `curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash && sudo apt-get install -y infisical`
 - Purpose: Secrets management CLI

---

## PENDING - Python Ecosystem

### uv
 - Install method: TBD

### pipx
 - Install method: TBD

### UV Tools
 - ansible
 - ansible-lint
 - ruff
 - yamllint
 - molecule

---

## PENDING - Node.js Ecosystem

### nodejs
 - Install method: TBD

### npm
 - Included with nodejs

### Global Packages
 - @google/gemini-cli
 - @clduab11/gemini-flow
 - @openai/codex
 - @qwen-code/qwen-code

---

## PENDING - Services

### Docker
 - Install method: TBD
 - Containers to restore: n8n, n8n-postgres

### Caddy
 - Install method: TBD
 - Web server/reverse proxy

### Pi-hole
 - Install method: TBD
 - DNS/ad-blocking

### NFS
 - Install method: TBD
 - Network file sharing

---

## PENDING - Data Restoration

- Atuin history database (`~/.local/share/atuin/`)
- Zoxide directory database (`~/.local/share/zoxide/`)
- Project files from old system
- Docker container data
- Systemd services
- Cron jobs
