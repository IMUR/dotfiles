# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chezmoi-managed dotfiles for a multi-node cluster (cooperator, director, terminator, projector). Uses Go templates for cross-architecture deployment (ARM64/x86_64) with automatic tool detection. All nodes use an out-of-band edit workflow: edits happen in the `/mnt/ops/dotfiles/` local clone, get pushed to GitHub, and are pulled down via `chezmoi update` on the targets.

## Commands

```bash
# Preview changes before applying
chezmoi diff

# Apply configuration changes
chezmoi apply

# Test template rendering
chezmoi execute-template < dot_bashrc.tmpl

# Validate chezmoi configuration
chezmoi doctor

# Debug template variables
chezmoi data
```

## Chezmoi Installation Per Node

Chezmoi is now **100% managed by Mise** across all nodes. It is pinned in `dot_config/mise/config.toml`.

| Node | Hostname | Role | Arch | Chezmoi Path |
|------|----------|------|------|--------------|
| crtr | cooperator | Gateway | linux/arm64 (RPi5) | `~/.local/share/mise/shims/chezmoi` |
| drtr | director | AI/Ollama | linux/amd64 (i9) | `~/.local/share/mise/shims/chezmoi` |
| trtr | terminator | Desktop | darwin/arm64 (M4) | `~/.local/share/mise/shims/chezmoi` |
| prtr | projector | Compute | linux/amd64 (i9) | `~/.local/share/mise/shims/chezmoi` |

## SSH Command Execution

**CRITICAL:** Non-interactive SSH (`ssh host 'command'`) spawns a non-login shell that does NOT source `.profile`. Tools in `~/.local/bin` or mise-managed tools won't be in PATH.

**Always use login shell wrapper for remote commands:**

```bash
# WRONG - tools not in PATH
ssh crtr 'chezmoi doctor'

# CORRECT - sources full shell config
ssh crtr 'zsh -l -c "chezmoi doctor"'
ssh drtr 'zsh -l -c "mise list"'
ssh trtr 'zsh -l -c "chezmoi status"'
```

This is a known shell configuration issue - PATH setup is in `.profile` which only loads for login shells.

## Architecture

### File Naming Convention

- `dot_` prefix → becomes `.` (dot_bashrc.tmpl → ~/.bashrc)
- `.tmpl` suffix → processed as Go template
- `executable_` prefix → gets execute permission
- `run_onchange_` prefix → runs when file content changes

### Shell Configuration Layers

```
Layer 0: /etc/profile (system)
Layer 1: .profile (PATH, tool detection, mise activation) - shell-agnostic
Layer 2: .bashrc/.zshrc (shell-specific aliases, plugins, prompts)
Layer 3: .zshrc.local (optional local overrides)
```

`.profile` is the foundation - always sourced first by shell RCs. It sets `$HAS_*` flags for tool detection that other configs use.

### Plugin Loading Order (Zsh Critical)

The order in `.zshrc` matters:

1. compinit (completion system)
2. fzf-tab
3. fzf integration
4. atuin (must override fzf's Ctrl-R)
5. zoxide, mise, starship
6. autosuggestions
7. **syntax-highlighting (MUST be last)**

### Key Files

| File | Purpose |
|------|---------|
| `.chezmoi.toml.tmpl` | Node detection, architecture flags, cluster variables |
| `dot_profile.tmpl` | Universal environment (PATH, tool detection, mise) |
| `dot_zshrc.tmpl` | Zsh config with plugin orchestration |
| `dot_bashrc.tmpl` | Bash config |
| `.chezmoiexternal.toml` | Zsh plugin version pins |
| `run_onchange_install_packages.sh.tmpl` | OS-aware package installation |

### Template Variables (from `.chezmoi.toml.tmpl`)

```go
.hostname        // Node name (cooperator, director, etc.)
.arch            // Architecture string
.is_arm64        // Boolean for ARM64
.is_x86_64       // Boolean for x86_64
.cluster.nas_path  // /cluster-nas
.cluster.domain    // ism.la
```

### Tool Detection Pattern

`.profile` sets environment flags that templates and shell configs use:

```bash
# In .profile (runtime detection)
export HAS_EZA=$(_has_cmd eza && echo 1 || echo 0)

# In templates (template-time checks)
{{- if .is_arm64 }}
# ARM64-specific config
{{- end }}
```

## Validation Workflow

Before applying changes:

1. `chezmoi diff` - preview what will change
2. `chezmoi execute-template < file.tmpl` - test template renders correctly
3. Test on single node first
4. Apply cluster-wide

## Operational Constraints

**Safe**: template modification, `chezmoi diff`, `chezmoi apply`

**Restricted**: template deletion, removing node variables (backup first)

**Forbidden**: modifying system files, root user changes
