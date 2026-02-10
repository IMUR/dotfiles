# Scope: Dev

## Focus
Template development, shell configuration, tool integration.

## Key Resources
- `dot_*.tmpl` — Template files (Go templates)
- `run_onchange_*.sh.tmpl` — Install scripts
- `executable_*` — Scripts requiring execute permission

## Current Priorities
1. Maintain shell config layer hierarchy
2. Keep plugin versions pinned in `.chezmoiexternal.toml`
3. Document template variables in CLAUDE.md

## Cautions
- Test templates: `chezmoi execute-template < file.tmpl`
- HAS_* flags are runtime-detected in `.profile`
- Zsh plugin order matters (compinit → fzf-tab → ... → syntax-highlighting)
