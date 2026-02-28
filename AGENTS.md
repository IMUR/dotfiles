# AGENTS.md — dotfiles

Single source of truth for all AI agents working in this repository.

## Project Overview

Chezmoi-managed dotfiles for a 4-node Co-lab cluster. Uses Go templates for cross-architecture deployment (ARM64/x86_64) with automatic tool detection. All nodes share an **out-of-band edit workflow**: edits happen in the shared source clone (`/mnt/ops/dotfiles/` on Linux, `/Volumes/ops/dotfiles/` on macOS `trtr`), get pushed to GitHub, and are pulled down via `chezmoi update` on targets.

**Never edit `~/.local/share/chezmoi/` directly** — those are managed per-node clones, not the authoring workspace.

## Node Inventory

| Alias | Hostname | Role | Arch | SSH |
|-------|----------|------|------|-----|
| crtr | cooperator | Gateway (RPi5) | linux/arm64 | local |
| drtr | director | AI/Ollama (i9-9900K) | linux/amd64 | `ssh drtr` |
| trtr | terminator | Desktop (M4 Mac) | darwin/arm64 | `ssh trtr` |
| prtr | projector | Compute (i9-9900X) | linux/amd64 | `ssh prtr` |

Chezmoi is **100% managed by Mise** on all nodes (`dot_config/mise/config.toml`).

## Key Files

| File | Purpose |
|------|---------|
| `.chezmoi.toml.tmpl` | Node detection, architecture flags, cluster variables |
| `dot_profile.tmpl` | Universal environment: PATH, tool detection, mise activation |
| `dot_zshrc.tmpl` | Zsh config with plugin orchestration |
| `dot_bashrc.tmpl` | Bash config |
| `.chezmoiexternal.toml.tmpl` | Zsh plugin version pins |
| `run_onchange_install_packages.sh.tmpl` | OS-aware package installation hook |
| `dot_config/mise/config.toml` | Tool version pins (chezmoi, and others) |

## File Naming Conventions

- `dot_` prefix → deployed as `.` (dot_bashrc.tmpl → `~/.bashrc`)
- `.tmpl` suffix → processed as Go template by Chezmoi
- `executable_` prefix → deployed with execute permission
- `run_onchange_` prefix → hook that runs when file content changes

## Shell Configuration Architecture

```
Layer 0: /etc/profile (system)
Layer 1: .profile (PATH, tool detection, mise activation) — shell-agnostic
Layer 2: .bashrc / .zshrc (shell-specific aliases, plugins, prompts)
Layer 3: .zshrc.local (optional local overrides)
```

`.profile` is the foundation. It sets `$HAS_*` flags used by all downstream configs:

```bash
# Runtime detection in .profile
export HAS_EZA=$(_has_cmd eza && echo 1 || echo 0)
```

### Zsh Plugin Loading Order (critical)

Order in `.zshrc` must be:
1. compinit
2. fzf-tab
3. fzf integration
4. atuin (must override fzf's Ctrl-R)
5. zoxide, mise, starship
6. autosuggestions
7. **syntax-highlighting (MUST be last)**

## Template Variables

Defined in `.chezmoi.toml.tmpl`:

```go
.hostname          // Node name (cooperator, director, etc.)
.arch              // Architecture string
.is_arm64          // Boolean
.is_x86_64         // Boolean
.cluster.nas_path  // /cluster-nas
.cluster.domain    // ism.la
```

Use `{{- if .is_arm64 }}` for architecture-specific blocks; `{{- if eq .hostname "cooperator" }}` for node-specific overrides.

## Build & Validation Commands

```bash
chezmoi diff                              # Preview pending changes — always run first
chezmoi execute-template < file.tmpl      # Render template to stdout for testing
chezmoi doctor                            # Check Chezmoi health
chezmoi apply                             # Apply locally after validation
chezmoi update --force                    # Pull latest repo state and apply on a node
chezmoi data                              # Inspect template variables
mise install --yes                        # Install/update tools after config changes
```

## SSH Command Execution

**CRITICAL:** Non-interactive SSH does NOT source `.profile`. Mise-managed tools won't be in PATH.

Always use a login shell:

```bash
# WRONG — tools not in PATH
ssh drtr 'chezmoi doctor'

# CORRECT — sources full shell config
ssh drtr 'zsh -l -c "chezmoi doctor"'
ssh trtr 'zsh -l -c "chezmoi status"'
```

## Validation Workflow

1. `chezmoi diff` — review what will change
2. `chezmoi execute-template < file.tmpl` — verify template renders correctly
3. Apply and verify on one node first
4. Promote cluster-wide with `chezmoi update --force`

Scripts (especially `run_onchange_`) must be **idempotent** — safe to run multiple times.

## Commit & PR Guidelines

Follow Conventional Commits (examples from history: `feat(tools): ...`, `chore(tools): ...`, `fix(shell): ...`).

- Keep commits focused to one concern and scope
- PR description should include: intent, affected files/nodes, verification commands run, rollout/rollback notes
- Never commit secrets; keep sensitive values outside tracked templates

## Operational Constraints

**Safe:** template modification, `chezmoi diff`, `chezmoi apply`

**Restricted:** template deletion, removing node variables (backup first)

**Forbidden:** modifying system files, root user changes, committing secrets

---

<!-- protext:begin -->
<!-- This section is managed by /protext. Do not edit manually. Do not add content below this block. -->
## Project Context
> Updated: 2026-02-26 | Scope: ops | Tokens: ~450

### Identity
<!-- marker:identity -->
Chezmoi-managed dotfiles for a 4-node cluster (cooperator, director, terminator, projector). Out-of-band edit workflow: edit in `/mnt/ops/dotfiles/` (Linux) or `/Volumes/ops/dotfiles/` (macOS trtr), push to GitHub, apply via `chezmoi update`. Go templates handle cross-architecture deployment (linux/arm64, linux/amd64, darwin/arm64) with runtime tool detection via `$HAS_*` flags.
<!-- /marker:identity -->

### Current State
<!-- marker:state -->
Active: None | Blocked: None | Recent: align-agentfiles refactor — AGENTS.md is now source of truth, CLAUDE.md/GEMINI.md are thin wrappers
<!-- /marker:state -->

### Hot Context
<!-- marker:hot -->
- Edit only in `/mnt/ops/dotfiles/` — never edit `~/.local/share/chezmoi/` (managed per-node clone)
- Always `chezmoi diff` before `chezmoi apply`; SSH remotes need login shell: `ssh node 'zsh -l -c "cmd"'`
- Zsh plugin order: compinit → fzf-tab → fzf → atuin → zoxide/mise/starship → autosuggestions → syntax-highlighting (LAST)
- Template vars: `.hostname`, `.arch`, `.is_arm64/.is_x86_64`, `.cluster.domain` (ism.la)
- Tool versions pinned in `dot_config/mise/config.toml`; macOS node (trtr) expects `/Volumes/ops` mounts
<!-- /marker:hot -->

### Scope Signals
- `@ops` → .protext/scopes/ops.md
- `@dev` → .protext/scopes/dev.md
- `@security` → .protext/scopes/security.md
- `@deep:maintenance` → .protext/index.yaml

### Links
<!-- marker:links -->
- `../configs` → parent | Configs parent directory
- `../configs/crtr-config` → peer | cooperator node config (gateway, 192.168.254.10)
- `../configs/drtr-config` → peer | director node config (AI/Ollama)
- `../configs/trtr-config` → peer | terminator node config (macOS desktop)
- `../configs/prtr-config` → peer | projector node config (headless compute)
<!-- /marker:links -->

### Handoff
<!-- marker:handoff -->
Last: align-agentfiles refactor + PROTEXT.md migrated to AGENTS.md footer | Next: Validate zoxide plugin drift across nodes | Caution: macOS trtr expects /Volumes/ops mounts
<!-- /marker:handoff -->
<!-- protext:end -->
