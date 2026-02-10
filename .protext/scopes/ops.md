# Scope: Operations

## Focus
Chezmoi template management, cross-node deployment, tool version tracking.

## Key Resources
- Chezmoi source: `/mnt/ops/dotfiles/`
- Template config: `.chezmoi.toml.tmpl`
- External plugins: `.chezmoiexternal.toml.tmpl`
- Package installer: `run_onchange_install_packages.sh.tmpl`

## Current Priorities
1. Keep tool versions aligned across nodes (chezmoi, mise, bun)
2. Validate templates before applying cluster-wide
3. Maintain shell plugin load order (syntax-highlighting last)

## Patterns
- Always `chezmoi diff` before `chezmoi apply`
- Test template rendering with `chezmoi execute-template`
- SSH remote: wrap in `zsh -l -c "..."` for login shell
- Tool detection via `$HAS_*` flags set in `.profile`

## Cautions
- Non-login SSH shells miss PATH — always use login wrapper
- Plugin order in zshrc is fragile — syntax-highlighting must be last
- trtr uses Homebrew chezmoi; crtr/drtr use ~/.local/bin
