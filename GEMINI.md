# GEMINI.md

## Project Overview

This repository contains the **dotfiles** for the 4-node Co-lab cluster, managed by **Chezmoi**. It is designed to provide a consistent, cross-platform (Linux/macOS), and cross-architecture (x86_64/ARM64) user environment across all nodes (`cooperator`, `director`, `terminator`, `projector`).

The core philosophy is a **unified profile** (`dot_profile.tmpl`) that handles environment detection and tool availability checks, ensuring that shell configurations (`bash`, `zsh`) are robust and adaptable to the specific capabilities of each node.

## Key Technologies

* **Manager:** [Chezmoi](https://www.chezmoi.io/)
* **Templating:** Go Templates (standard Chezmoi templating)
* **Shells:** Bash, Zsh
* **Package Management:** `apt-get` (Linux), `brew` (macOS)
* **Tool Management:** `mise`, `cargo`, `bun` (detected dynamically)

## Environment Architecture

The configuration is layered to ensure correct loading order and compatibility, especially for SSH sessions.

### 1. The Unified Profile (`dot_profile.tmpl`)

This is the single source of truth for the environment. It is templated by Chezmoi and performs the following at runtime:

* **Node Identification:** Exports `NODE_ROLE`, `ARCH`, `OS`.
* **Path Management:** Adds paths (`~/.local/bin`, `~/.cargo/bin`, `/usr/local/cuda/bin`, etc.) safely without duplication.
* **Tool Detection:** Checks for the existence of tools (`eza`, `bat`, `fzf`, `zoxide`, etc.) and exports boolean flags (e.g., `export HAS_EZA=1`). These flags are used by downstream shell RCs to conditionally enable features.
* **Mise Activation:** Activates `mise` early so managed tools are available for detection.
* **Terminal Compatibility:** Fixes `TERM` issues (e.g., for Ghostty/Kitty) to prevent SSH breakage.

### 2. Shell Configurations (`dot_bashrc.tmpl`, `dot_zshrc.tmpl`)

These files source `.profile` first, then apply shell-specific configurations (aliases, prompts, completion) based on the `HAS_*` flags exported by the profile.

## Configuration Structure

### File Naming Conventions

* `dot_filename`: Installs as `~/.filename`.
* `.tmpl`: Indicates a template file processed by Chezmoi.
* `executable_filename`: Installs as an executable file.
* `run_onchange_`: Scripts that run automatically when their content changes (e.g., package installation).

### Key Files

| File | Purpose |
| :--- | :--- |
| `.chezmoi.toml.tmpl` | **Configuration**: Defines node-specific variables (`hostname`, `arch`, `cluster` settings) used in templates. |
| `dot_profile.tmpl` | **Foundation**: The unified environment setup described above. |
| `run_onchange_install_packages.sh.tmpl` | **Bootstrapping**: Installs essential packages (`fzf`, `bat`) using the OS native package manager. |
| `dot_bashrc.tmpl` | **Bash**: Bash-specific config, heavily reliant on `.profile`. |
| `dot_zshrc.tmpl` | **Zsh**: Zsh-specific config, plugin management. |

### Template Variables

Variables are defined in `.chezmoi.toml.tmpl`. Common variables include:

* `.hostname`: Node hostname (e.g., "cooperator").
* `.arch`: CPU architecture.
* `.is_arm64` / `.is_x86_64`: Boolean architecture flags.
* `.cluster.nas_path`: Path to shared NAS storage.

## Building and Running

Since this is a configuration repository, "building" implies applying the templates to the local system.

### The Out-of-Band Edit Workflow

**CRITICAL:** All nodes use an out-of-band edit workflow. You must edit the files here in the local clone (`/mnt/ops/dotfiles/` on Linux nodes, `/Volumes/ops/dotfiles/` on macOS `trtr`) which serves as the shared source of truth. Commit and push them to GitHub, and then run `chezmoi update --force` on the target nodes. Do not run `chezmoi edit` on downstream nodes as that operates on the local `~/.local/share/chezmoi/` cache rather than your source of truth.

### Core Commands

| Command | Description |
| :--- | :--- |
| `chezmoi diff` | **Always run this first.** Shows the difference between the target state and the current state. |
| `chezmoi apply` | Applies the changes to the user's home directory. |
| `chezmoi update` | Pulls the latest changes from the repo and applies them. |
| `chezmoi doctor` | Checks for configuration issues. |
| `chezmoi execute-template < file.tmpl` | Renders a template to stdout for testing without applying. |

### Testing Changes

To test a specific template (e.g., `.bashrc`) without overwriting your config:

```bash
chezmoi execute-template < dot_bashrc.tmpl
```

## Development Conventions

1. **Safety First:** Always use `chezmoi diff` before `chezmoi apply`.
2. **Idempotency:** Scripts (especially `run_onchange_`) should be safe to run multiple times.
3. **Template Logic:**
    * Use `{{- if .is_arm64 }}` for architecture-specific blocks.
    * Use `{{- if eq .hostname "node-name" }}` for node-specific overrides.
4. **No Secrets:** Do not commit secrets to this repository. Use a password manager or Chezmoi's secret management features if necessary (though none are currently evident in the inspected files).

## Special Features

### The `meta()` Function

The `.profile` includes a sophisticated `meta()` function for initializing project metadata structures. It supports:

* Cloning a template from `github.com/IMUR/.meta.git`.
* Vendoring the template (removing `.git`).
* Handling backups of existing `.meta` directories.
* Interactive and flag-based operation modes.

### SSH/Terminal Fix

The `.profile` contains logic to handle modern terminals (Ghostty, Kitty, VSCode) connecting to older or standard Linux hosts. It detects if `TERM` is unsupported on the remote host and falls back to `xterm-256color` to prevent "unknown terminal type" errors.
