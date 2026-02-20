# Protext: Dotfiles
>
> Generated: 2026-02-10 | Scope: ops | Tokens: ~450

## Identity
<!-- marker:identity -->
Chezmoi-managed dotfiles for a 4-node cluster (cooperator, director, terminator, projector). All nodes use an out-of-band edit workflow: edits happen in the local clone (`/mnt/ops/dotfiles/` on Linux nodes, `/Volumes/ops/dotfiles/` on macOS `trtr`), get pushed to GitHub, and are pulled down via `chezmoi update` on the targets. Go templates handle cross-architecture deployment (linux/arm64, linux/amd64, darwin/arm64) with runtime tool detection via `$HAS_*` flags.
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
- Nodes: `crtr` (linux/arm64), `drtr` (linux/amd64), `trtr` (darwin/arm64 - macOS), `prtr` (linux/amd64 - headless compute)
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
- `/mnt/ops/configs/drtr-config` → peer | director node config (AI/Ollama)
- `/Volumes/ops/configs/trtr-config` → peer | terminator node config (macOS desktop)
- `/mnt/ops/configs/prtr-config` → peer | projector node config (headless compute)
<!-- /marker:links -->

## Handoff
<!-- marker:handoff -->
Last: Protext initialized | Next: Customize scopes for cluster ops | Caution: Review auto-generated content
<!-- /marker:handoff -->
