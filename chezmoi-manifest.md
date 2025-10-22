# Chezmoi Manifest

**Purpose:** Organization of dotfiles and tools by chezmoi management relationship
**Node:** cooperator | **Updated:** 2025-10-21
**Dotfiles Repo:** github.com/IMUR/dotfiles (public)
**Source Directory:** ~/.local/share/chezmoi/ (direct git clone, not a submodule)

**Recent Changes (2025-10-21):**
- Removed cluster management scripts (now documented in CLUSTER-MANAGEMENT-DISCUSSION.md)
- Simplified .ssh/rc to only source .profile (removed unnecessary .ssh/environment creation)
- Total reduction: 759 lines of bash removed from dotfiles

---

## Chezmoi Itself

### chezmoi
 - Version: v2.66.0 (verified 2025-10-21)
 - Install: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply IMUR`
 - Binary: `~/.local/bin/chezmoi`
 - Config: `~/.config/chezmoi/chezmoi.toml`
 - Source: `~/.local/share/chezmoi/` (direct git clone from github.com/IMUR/dotfiles)
 - Purpose: Manages dotfiles via templates
 - **Note:** Source directory is an independent git repository, NOT a submodule of crtr-config

---

## Files Directly Managed by Chezmoi

*Chezmoi templates these files and keeps them in sync*

### Shell Configuration

**~/.zshrc**
 - Template: `dot_zshrc.tmpl`
 - Purpose: ZSH interactive shell configuration
 - Contains: Aliases, functions, tool initializations, PATH setup

**~/.bashrc**
 - Template: `dot_bashrc.tmpl`
 - Purpose: Bash interactive shell configuration (fallback)
 - Contains: Similar to zshrc for bash compatibility

**~/.profile**
 - Template: `dot_profile.tmpl`
 - Purpose: Universal shell environment (sourced by both zsh and bash)
 - Contains: PATH, environment variables, tool detection

### Terminal & Multiplexer

**~/.tmux.conf**
 - Template: `dot_tmux.conf.tmpl`
 - Purpose: Tmux terminal multiplexer configuration
 - Contains: Key bindings, status bar, cluster theming

### Tool Configurations

**~/.config/starship.toml**
 - Template: `dot_config/starship.toml`
 - Purpose: Starship prompt configuration
 - Contains: Prompt modules, cluster-aware styling

**~/.config/atuin/**
 - Template: `dot_config/atuin/`
 - Purpose: Atuin shell history sync configuration
 - Contains: Sync settings, keybindings

**~/.ssh/config**
 - Template: `dot_ssh/config.tmpl`
 - Purpose: SSH client configuration
 - Contains: Node definitions, connection multiplexing, GitHub config
 - **Note:** Templates can adapt to node-specific settings

**~/.ssh/rc**
 - Template: `dot_ssh/executable_rc`
 - Purpose: SSH session initialization - sources .profile for non-interactive sessions
 - Critical for: Remote commands (ansible, ssh user@host 'command', git over SSH)
 - Note: Ensures PATH includes ~/.cargo/bin, ~/.local/bin, ~/.atuin/bin for remote commands

### Cluster Management

**Note (2025-10-21):** Cluster management scripts (`dot_cluster-functions.sh`, `dot_cluster-mgmt.sh`) were removed from dotfiles.

**Rationale:**
- Cluster orchestration doesn't belong in personal dotfiles
- 750+ lines of complex bash better suited for project repo or ansible
- Functionality documented in `CLUSTER-MANAGEMENT-DISCUSSION.md` for future redesign

**Alternative approaches:** See `CLUSTER-MANAGEMENT-DISCUSSION.md` in crtr-config repo


---

## Tools Required by Chezmoi-Managed Configs

*These tools must be installed for the configs to work properly*

### Shells
- **zsh** (`/usr/bin/zsh`) - Primary shell, config managed by chezmoi
- **bash** (`/usr/bin/bash`) - Fallback shell, config managed by chezmoi

### Prompt & History
- **starship** (`~/.local/bin/starship`) - Prompt (config managed by chezmoi)
- **atuin** (`~/.atuin/bin/atuin`) - History sync (config managed by chezmoi)

### Modern CLI Tools (Referenced in Shell Configs)
- **eza** (`~/.cargo/bin/eza`) - ls replacement (aliases in .zshrc)
- **zoxide** (`~/.cargo/bin/zoxide`) - Smart cd (init in .zshrc)
- **bat** (`~/.cargo/bin/bat`) - cat replacement (aliases in configs)
- **fzf** (`/usr/bin/fzf`) - Fuzzy finder (integration in .zshrc)
- **fd** (`/usr/bin/fdfind`) - find replacement (aliased in .zshrc)
- **ripgrep** (`/usr/bin/rg`) - grep replacement (used by other tools)

### Terminal & Editors
- **tmux** (`/usr/bin/tmux`) - Multiplexer (config managed by chezmoi)
- **vim** (`/usr/bin/vim`) - Editor (referenced in configs)
- **git** (`/usr/bin/git`) - Version control (referenced in configs)

### Tool Dependencies
- **cargo** (`~/.cargo/bin/cargo`) - For Rust tools (eza, zoxide, bat, etc.)
- **rustup** (`~/.cargo/bin/rustup`) - Rust toolchain manager

---

## Files NOT Managed by Chezmoi

*Intentionally excluded from chezmoi for security or other reasons*

### Security-Sensitive
**~/.ssh/id_*** (Private keys)
 - Reason: Security - never version control private keys
 - Management: Manual copy, secure storage

**~/.git-credentials**
 - Reason: Contains plaintext passwords
 - Management: Manual copy (consider switching to credential helper)

### Personal Configuration
**~/.gitconfig**
 - Reason: Contains personal email and signing key
 - Management: Manual copy
 - **Could be managed:** Template with .chezmoi.toml.tmpl for personal data

---

## Chezmoi Template System

### Template Variables Available
From `.chezmoi.toml.tmpl`:
- `hostname` - Auto-detected node name
- `arch` - Architecture (aarch64/x86_64)
- `is_arm64` / `is_x86_64` - Architecture flags
- `cluster.*` - Cluster configuration (nas_path, domain, network)

### How Templates Work
1. **Source**: Templates stored in `~/.local/share/chezmoi/`
2. **Processing**: Chezmoi evaluates templates using variables
3. **Deployment**: Generated files placed in home directory
4. **Sync**: `chezmoi apply` updates files from templates

### Useful Commands
```bash
# See what would change
chezmoi diff

# Apply all dotfiles
chezmoi apply

# Edit a managed file (opens in editor, updates source)
chezmoi edit ~/.zshrc

# Update dotfiles from git repo
chezmoi update

# Check chezmoi health
chezmoi doctor

# See source directory
chezmoi source-path
```

---

## PATH Management Strategy

Chezmoi-managed shell configs should include:
```bash
~/.local/bin        # Standalone installers (chezmoi, starship)
~/.cargo/bin        # Rust tools (eza, zoxide, bat)
~/.atuin/bin        # Atuin
/usr/local/bin      # System-wide manual installs
/usr/bin            # APT packages
/bin                # System binaries
```

**Current Issue:** PATH duplicates and missing entries
**Solution:** Update `dot_profile.tmpl` to properly construct PATH

---

## Adding New Managed Files

To add a new dotfile to chezmoi:

```bash
# Add existing file to chezmoi
chezmoi add ~/.newconfig

# Creates: ~/.local/share/chezmoi/dot_newconfig

# Make it a template (if needed)
chezmoi add --template ~/.newconfig

# Creates: ~/.local/share/chezmoi/dot_newconfig.tmpl

# Commit to git
cd ~/.local/share/chezmoi
git add dot_newconfig.tmpl
git commit -m "Add newconfig"
git push
```

---

## Removing Files from Chezmoi

To stop managing a file:

```bash
# Remove from chezmoi (keeps file in home dir)
chezmoi forget ~/.oldconfig

# Remove from source repo
cd ~/.local/share/chezmoi
git rm dot_oldconfig
git commit -m "Remove oldconfig from management"
git push
```

---

## Notes

- Chezmoi templates enable **node-adaptive configs** (same repo, different results per node)
- All managed files are **version controlled** at github.com/IMUR/dotfiles
- Security-sensitive files **intentionally excluded** from version control
- Tool installation is **separate from chezmoi** - this manifest tracks both
- Templates can use conditionals: `{{- if eq .hostname "cooperator" }}`
