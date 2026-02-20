# Record: Dotfiles File Registry

This record provides a mapping of all managed files in the `dotfiles` repository and their intended purpose across the cluster.

## 🛠 Core Configuration

| File | Purpose | Target Path |
|:---|:---|:---|
| `.chezmoi.toml.tmpl` | Logic for node detection and architecture mapping. | `~/.config/chezmoi/chezmoi.toml` |
| `.chezmoiexternal.toml` | External resources (e.g., fzf-tab) to be pulled. | N/A |
| `dot_profile.tmpl` | Universal profile; handles PATH and tool flags. | `~/.profile` |
| `dot_zshenv.tmpl` | Environment variables; sets critical PATH for Mise. | `~/.zshenv` |
| `dot_zshrc.tmpl` | Interactive Zsh config; aliases and prompts. | `~/.zshrc` |
| `dot_bashrc.tmpl` | Interactive Bash config (fallback). | `~/.bashrc` |
| `dot_tmux.conf.tmpl` | Shared tmux environment. | `~/.tmux.conf` |

## 📦 Tool Management (Mise)

| File | Purpose |
|:---|:---|
| `dot_config/mise/config.toml` | **Source of Truth** for all tool versions (Node, UV, Bun, etc.). |
| `run_onchange_after_mise-install.sh.tmpl` | Hook that triggers `mise install` when `config.toml` changes. |

## 🛰 System Integration

| File | Purpose |
|:---|:---|
| `run_onchange_install_packages.sh.tmpl` | Script to install native packages via `apt` or `brew`. |
| `dot_ssh/executable_rc` | SSH environment setup for non-interactive sessions. |
| `dot_local/bin/executable_skill-browser` | Custom utility script for the local node. |

## 📋 Registry Metadata
- **Status**: Active
- **Last Audit**: 2026-02-03
- **Compliance**: Zero-Drift Policy
