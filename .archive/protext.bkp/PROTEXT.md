# Protext: Dotfiles (Multi-Node Cluster)
> Generated: 2026-02-10 | Scope: ops | Tokens: ~480

## Identity
Chezmoi-managed dotfiles for a 3-node cluster (cooperator, director, terminator). Cross-architecture deployment (ARM64/x86_64) using Go templates with automatic tool detection and shell configuration orchestration.

## Current State
Active: System maintenance | Blocked: None | Recent: feat(tools) Lightpanda browser, uv 0.9.28, bun 1.3.8

## Hot Context
- `.profile` is foundation layer - sets `$HAS_*` flags for tool detection used by all shell configs
- SSH command execution requires login shell wrapper: `ssh node 'zsh -l -c "command"'` (PATH not available in non-login shells)
- Zsh plugin load order critical: syntax-highlighting MUST be last
- Three chezmoi installations with different paths/versions across nodes

## Scope Signals
- `@ops` → .protext/scopes/ops.md (deployment, validation workflow)
- `@dev` → .protext/scopes/dev.md (template development, testing)
- `@deep:architecture` → Extract from index (file naming, layers, detection patterns)
- `@deep:validation` → Extract from index (testing workflow, commands)

## Links
- `../configs/crtr-config` → peer | Cooperator node services (Caddy, Pi-hole, Headscale)
- `../configs/drtr-config` → peer | Director ML platform (Ollama, Kokoro TTS)
- `../configs/trtr-config` → peer | Terminator macOS admin console

## Handoff
Last: Project initialized | Next: Normal operations | Caution: Always test templates with `chezmoi execute-template` before applying cluster-wide
