# Scope: Security

## Focus
Secrets handling, SSH configuration, credential management in dotfiles.

## Key Resources
- SSH configs via templates (no hardcoded keys)
- Tool detection for secrets managers
- Git hooks for sensitive file detection

## Current Priorities
1. Never commit secrets to dotfiles
2. Use template variables for sensitive paths
3. Audit .gitignore for credential patterns

## Cautions
- Check templates don't expose paths/credentials
- SSH keys managed separately, not in chezmoi
- Review changes with `chezmoi diff` before apply
