# dotfiles/

**Management Tool**: Chezmoi
**Purpose**: Cross-node user environment management via templates
**Safety Level**: Low Risk

## Overview

This directory contains Chezmoi templates for managing user configurations across the 4-node Co-lab cluster (`crtr`, `drtr`, `trtr`, `prtr`). Templates automatically adapt based on node roles, architectures, and capabilities.

**Critical Workflow Context:** All nodes use an out-of-band edit workflow. You must edit the files here in the local clone (`/mnt/ops/dotfiles/` on Linux nodes, `/Volumes/ops/dotfiles/` on macOS `trtr`) which serves as the shared source of truth, commit and push them to GitHub, and then run `chezmoi update --force` on the target nodes. Do not run `chezmoi edit`.

### Structured Records

- [Configuration Architecture](.context/ARCHITECTURE.md) - How we manage state.
- [Cluster Topology](.context/CLUSTER-TOPOLOGY.md) - Node inventory and roles.
- [File Registry](.context/RECORD-FILE-REGISTRY.md) - Inventory of managed templates.
- [Promotion Workflow](.context/RECORD-PROMOTION-WORKFLOW.md) - How to propagate changes.

## Quick Start

```bash
# Preview changes before applying
chezmoi diff

# Apply configuration changes
chezmoi apply

# Test template rendering
chezmoi execute-template < dotfiles/dot_bashrc.tmpl

# Validate Chezmoi configuration
chezmoi doctor
```

## Key Files

| File | Purpose |
|------|---------|
| `.chezmoi.toml.tmpl` | Node detection and capability mapping |
| `dot_profile.tmpl` | Universal profile with tool detection |
| `dot_bashrc.tmpl` | Bash shell configuration |
| `dot_zshrc.tmpl` | Zsh shell configuration |
| `dot_ssh/executable_rc` | SSH environment setup for non-interactive sessions |
| `.chezmoitemplate.*` | Shared template includes |

## Node Variables

**Required**: `node_role`, `has_gpu`, `architecture`
**Optional**: `gpu_count`, `cuda_version`, `has_docker`
**Custom**: Defined in `.chezmoi.toml.tmpl`

## Common Patterns

### Conditional Configuration

```bash
{{- if .has_gpu }}
# GPU-specific configuration
{{- end }}
```

### Node-Specific Configuration

```bash
{{- if eq .node_role "gateway" }}
# Gateway-specific configuration
{{- end }}
```

### Shared Template Includes

```bash
{{- template "nvm-loader" . -}}
```

## Workflow

**Template Modification**:

1. Edit template in `dotfiles/`
2. Run `chezmoi diff` to preview changes
3. Test with `chezmoi execute-template`
4. Validate syntax
5. Test on single node first
6. Apply cluster-wide

**Rollback**:

```bash
chezmoi forget  # Remove managed file
# Re-init from git if needed
```

## Validation

**Before Apply**:

- Run `chezmoi diff`
- Test with `chezmoi execute-template --dry-run`
- Verify node variables exist
- Check conditional logic

**Node Testing**:

- Test on single node first
- Verify node-specific sections render correctly

## Safe Operations

✅ Template modification
✅ `chezmoi diff`
✅ `chezmoi apply`
✅ Template syntax validation
✅ Node variable testing

⚠️ **Restricted**: Template deletion, node variable removal
🚫 **Forbidden**: System file modification, root user changes

## Escalation Triggers

- Template syntax errors
- Undefined node variables
- Breaking changes detected

## Terminal Compatibility (SSH/VSCode/Cursor Fix)

The dotfiles include automatic TERM variable handling to fix issues when SSHing from modern terminals like Ghostty, Kitty, VSCode, and Cursor.

**The Fix**:

- `dot_profile.tmpl`: Automatically sets `TERM=xterm-256color` if TERM is unset, "dumb", or unsupported
- Prevents "unsuitable terminal" errors on remote systems
- Works for both interactive shells and VSCode/Cursor remote sessions

**Why This Matters**:
Modern terminals like Ghostty set custom TERM values (e.g., `xterm-ghostty`) that aren't in the terminfo database on remote Linux systems, causing broken terminal behavior in SSH sessions.

**Note**: SSH config (`~/.ssh/config`) is managed manually, not via chezmoi, as it's static and working well across the cluster.

## Additional Documentation

See `.agent-context.json` for detailed operational boundaries and AI-specific constraints.
