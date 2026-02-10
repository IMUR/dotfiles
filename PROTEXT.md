# Protext: Dotfiles
> Generated: 2026-02-10 | Scope: ops | Tokens: ~450

## Identity
<!-- marker:identity -->
Chezmoi-managed dotfiles for a 3-node Pi cluster (cooperator, director, terminator). Go templates handle cross-architecture deployment (ARM64/x86_64) with runtime tool detection via `$HAS_*` flags.
<!-- /marker:identity -->

## Current State
<!-- marker:state -->
Active: Tool additions (Lightpanda, puppeteer-core) | Blocked: None | Recent: PATH precedence fix in zshenv
<!-- /marker:state -->

## Hot Context
<!-- marker:hot -->
- Shell layers: .profile (foundation) → .bashrc/.zshrc (shell-specific) → .zshrc.local (overrides)
- Zsh plugin order matters: compinit → fzf-tab → fzf → atuin → zoxide/mise/starship → autosuggestions → syntax-highlighting (LAST)
- SSH remote commands need login shell: `ssh node 'zsh -l -c "cmd"'`
- Template vars: `.hostname`, `.arch`, `.is_arm64`, `.is_x86_64`, `.cluster.domain` (ism.la)
<!-- /marker:hot -->

## Scope Signals
- `@ops` → .protext/scopes/ops.md
- `@dev` → .protext/scopes/dev.md
- `@security` → .protext/scopes/security.md
- `@deep:architecture` → .context/ARCHITECTURE.md
- `@deep:maintenance` → docs/MAINTENANCE.md

## Links
<!-- marker:links -->
- `/mnt/ops/configs/crtr-config` → peer | cooperator node config (gateway, 192.168.254.10)
- `/mnt/ops/configs/drtr-config` → peer | director node config (ML/inference compute)
- `/mnt/ops/configs/trtr-config` → peer | terminator node config (admin console)
<!-- /marker:links -->

## Handoff
<!-- marker:handoff -->
Last: Protext initialized | Next: Customize scopes for cluster ops | Caution: Review auto-generated content
<!-- /marker:handoff -->
