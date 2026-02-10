# Scope: Operations

## Focus
Deployment, validation, and cluster-wide configuration management for chezmoi-managed dotfiles.

## Key Resources
- `.chezmoi.toml.tmpl` — Node detection and cluster variables
- `dot_profile.tmpl` — Universal environment setup (PATH, tool detection)
- `run_onchange_install_packages.sh.tmpl` — OS-aware package installation

## Current Priorities
1. Validate template changes with `chezmoi diff` before applying
2. Test on single node before cluster-wide deployment
3. Monitor SSH command execution patterns (login shell wrapper requirement)

## Cautions
- **CRITICAL:** Use `ssh node 'zsh -l -c "cmd"'` for remote commands - non-login shells don't have correct PATH
- Never delete templates without backups (especially node variables)
- Respect Zsh plugin load order: syntax-highlighting MUST be last
- Test templates with `chezmoi execute-template < file.tmpl` before apply
