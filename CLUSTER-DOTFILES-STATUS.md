# Cluster Dotfiles Status Report

Generated: 2026-02-03 from crtr (cooperator) node session

---

## Cluster Topology

| User | Hostname | LAN IP | Tailscale IP | OS | Role |
|------|----------|--------|--------------|-----|------|
| crtr | cooperator | 192.168.254.10 | 100.64.0.1 | Debian 13 (Trixie), arm64 | Edge services, ingress |
| drtr | director | 192.168.254.124 | 100.64.0.2 | Debian 13 (Trixie), x86_64 | Inference, machine learning |
| trtr | terminator | 192.168.254.184 | 100.64.0.8 | macOS Tahoe 26.2, arm64 | Workstation |

**All nodes have `fastfetch` installed** - run it for quick system profile.

**Shared Storage:** `/mnt/ops/` is a Samba mount accessible from all nodes.

---

## Cluster Access

### SSH Access

All nodes have **passwordless SSH** configured to each other using short aliases:

```bash
ssh crtr    # → cooperator (100.64.0.1)
ssh drtr    # → director (100.64.0.2)
ssh trtr    # → terminator (100.64.0.8)
```

### Sudo Access

All nodes have **passwordless sudo** configured for their respective users.

### Tailscale Subnet

All nodes are on the Tailscale mesh network (`100.64.0.0/10`):

- Headscale server: `vpn.rtr.dev` (self-hosted on crtr)
- Subnet routing enabled for cross-node access

### Quick Node Profile

```bash
# Run on any node for system info
fastfetch

# Check connectivity to other nodes
ssh crtr 'hostname && fastfetch --logo none'
ssh drtr 'hostname && fastfetch --logo none'
ssh trtr 'hostname && fastfetch --logo none'
```

---

## Chezmoi Scope

**Chezmoi is strictly for cross-platform configurations** - only what can be reliably aligned across ALL included nodes (crtr, drtr, trtr).

### What Chezmoi SHOULD Manage

- Shell configs (`.zshrc`, `.bashrc`, `.profile`) with templated conditionals
- Tool configs that work identically across platforms (starship, atuin, mise)
- Aliases and functions that are OS-agnostic or properly templated
- Environment variables common to all nodes

### What Chezmoi Should NOT Manage

- Node-specific service configs (Docker, Caddy, etc.)
- Platform-specific paths that can't be templated reliably
- Configs that only apply to one node's role (GPU settings, ingress configs)
- Anything that requires manual intervention after `chezmoi apply`

### Template Conditionals Available

```go
{{ .chezmoi.os }}          // "linux" or "darwin"
{{ .chezmoi.arch }}        // "arm64" or "amd64"
{{ output "hostname" }}    // "cooperator", "director", "terminator"
```

If a config can't be made cross-platform with these conditionals, **it doesn't belong in chezmoi**.

---

## Critical Architecture Issue

**Problem:** Each node has its own local chezmoi source directory, separate from the shared `/mnt/ops/dotfiles`.

### crtr current state

```
chezmoi source path:  ~/.local/share/chezmoi (LOCAL)
shared dotfiles:      /mnt/ops/dotfiles (SAMBA)
both git remotes:     github.com/IMUR/dotfiles (SAME REPO)
```

This creates a **3-way sync problem**:

1. Local chezmoi source (`~/.local/share/chezmoi`)
2. Git remote (`github.com/IMUR/dotfiles`)
3. Samba share (`/mnt/ops/dotfiles`)

Changes made on one node don't automatically propagate. Manual git push/pull required, plus samba share may drift.

---

## Observed Symptoms on crtr

### 1. zshrc Conflict

```
chezmoi status: MM .zshrc
```

`MM` = modified in BOTH source template AND target file.

**Diff shows:** Target `.zshrc` has pnpm config block that's NOT in the template:

```bash
# pnpm
export PNPM_HOME="/home/crtr/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
```

### 2. Persistent zoxide Warning

```
zoxide: detected a possible configuration issue.
Please ensure that zoxide is initialized right at the end of your shell configuration file
```

This appears on every shell operation that changes directory. Indicates shell init ordering issue.

### 3. PATH Fragmentation

Multiple tools adding to PATH in different ways:

- mise (via eval)
- bun (`~/.bun/bin`, `~/.cache/.bun/bin`)
- pnpm (`~/.local/share/pnpm`)
- Potential conflicts with tool ordering

---

## Current mise Configuration (crtr)

Location: `~/.config/mise/config.toml`

```toml
[tools]
atuin = "latest"
bun = "latest"
go = "latest"
node = "lts"
python = "3.14"
ripgrep = "latest"
uv = "latest"
fd = "latest"
starship = "latest"
bat = "latest"
eza = "latest"
zoxide = "latest"
fzf = "latest"
```

mise is managing zoxide, which creates the ordering issue - zoxide init must come AFTER mise activation in shell config.

---

## Git History (shared dotfiles)

Recent commits on `/mnt/ops/dotfiles`:

```
7993c9b fix(path): add ~/.bun/bin to PATH for standard bun installations
1395950 feat: add skill-browser and fzf/bat installer
a33b634 fix(zsh): correct plugin loading order - syntax-highlighting must be absolute last
c483079 feat(zsh): add autosuggestions, syntax-highlighting, and fzf-tab plugins
2e28773 fix: hostname detection using output instead of .chezmoi.hostname
800f352 feat(shell): modernize with mise, starship, zoxide and bun
```

Note commit `a33b634` attempted to fix plugin loading order but zoxide issue persists.

---

## Files Managed by Chezmoi

| Template | Purpose |
|----------|---------|
| `.chezmoi.toml.tmpl` | Node detection (hostname, arch) |
| `dot_profile.tmpl` | Universal profile, TERM fixes |
| `dot_bashrc.tmpl` | Bash config |
| `dot_zshrc.tmpl` | Zsh config (PROBLEMATIC) |
| `dot_config/mise/config.toml` | mise tool versions |
| `run_onchange_install_packages.sh.tmpl` | Package installer script |

---

## Recommended Investigation Areas

### 1. Shell Init Order Audit

Review `dot_zshrc.tmpl` for correct ordering:

1. mise activation (`eval "$(mise activate zsh)"`)
2. Tool initializations (starship, atuin, etc.)
3. zoxide init (MUST BE LAST, after mise provides the binary)
4. zsh plugins (syntax-highlighting absolute last)

### 2. Resolve Chezmoi Source Strategy

Options:

- **Symlink:** `~/.local/share/chezmoi` → `/mnt/ops/dotfiles` on all nodes
- **Git-only:** Remove samba dependency, strict git push/pull workflow
- **Chezmoi sourceDir:** Configure chezmoi to use `/mnt/ops/dotfiles` directly

### 3. Handle Local Modifications

The pnpm PATH block in crtr's `.zshrc` needs to be either:

- Added to the template (if all nodes need it)
- Added via chezmoi's `modify_` script mechanism
- Removed and managed by mise instead

### 4. Verify Other Nodes

Check drtr and trtr for:

- Their chezmoi source paths
- Whether they have the same drift issues
- Git status of their local chezmoi repos

---

## Quick Commands for Investigation

```bash
# Check chezmoi source path on any node
chezmoi source-path

# See what chezmoi thinks is different
chezmoi diff

# Check git status of local chezmoi
cd $(chezmoi source-path) && git status

# Compare template output vs actual file
chezmoi execute-template < /mnt/ops/dotfiles/dot_zshrc.tmpl > /tmp/rendered.zsh
diff ~/.zshrc /tmp/rendered.zsh

# Check if a node can reach shared storage
ls -la /mnt/ops/dotfiles/

# mise doctor for tool health
mise doctor
```

---

## Node-Specific Configs on Samba

Location: `/mnt/ops/configs/`

```
brtr-config/
crtr-config/
rrtr-config/
trtr-config/
```

These appear to be node-specific config backups/overrides. Investigate relationship to chezmoi.

---

## Session Records

Location: `/mnt/ops/records/`

```
crtr-records/
drtr-records/
trtr-records/
```

Chat/session records are being unified here. One existing file:

- `trtr-records/2026-02-03-codex-symlink-skills-20260203-023547.md`

---

---

## Additional Issue: crtr-config Directory Duplication

Same pattern as chezmoi - multiple copies with different git remotes:

| Location | Git Origin |
|----------|------------|
| `/home/crtr/Projects/crtr-config` | `git.ism.la:2222/rtr/crtr-config.git` (gitea) |
| `/mnt/ops/configs/crtr-config` | `github.com/IMUR/crtr-config` (github) |

**Canonical should be:** `/mnt/ops/configs/crtr-config`

The local Projects copy also has a `gitea` remote pointing to `rtr/dotfiles.git` (wrong repo name - likely copy/paste error).

---

## Summary

**Root cause:** Fragmented architecture with multiple sources of truth across dotfiles AND config repos.

**Immediate issues:**

1. `.zshrc` has untracked local changes (pnpm)
2. zoxide init ordering broken
3. PATH management inconsistent across tools

**Recommended first steps:**

1. Audit `dot_zshrc.tmpl` init ordering
2. Decide on single source strategy (symlink vs git-only)
3. Reconcile local changes back to template or discard
4. Test on crtr, then propagate to other nodes
