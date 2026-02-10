# Scope: Ops

## Focus
Chezmoi operations, dotfile deployment, cross-node synchronization.

## Key Resources
- `.chezmoi.toml.tmpl` — Node detection, architecture flags
- `dot_profile.tmpl` — Universal PATH/env setup
- `dot_zshrc.tmpl` — Zsh config + plugin orchestration
- `.chezmoiexternal.toml` — External plugin versions

## Current Priorities
1. Keep configs synchronized across nodes
2. Test template changes with `chezmoi diff` before apply
3. Maintain plugin load order (syntax-highlighting LAST)

## Cautions
- Non-interactive SSH needs `zsh -l -c` wrapper
- Never delete template variables without backup
- Test on single node before cluster-wide apply
