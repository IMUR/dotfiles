# Protext: Cluster Dotfiles

> Generated: 2026-02-05 | Scope: ops | Tokens: ~400

## Identity

Chezmoi-managed dotfiles for a multi-node cluster (cooperator, director, terminator, projector). Uses Go templates for cross-architecture deployment (ARM64/x86_64) with automatic tool detection. All nodes use an out-of-band edit workflow: edits happen in the `/mnt/ops/dotfiles/` local clone, get pushed to GitHub, and are pulled down via `chezmoi update` on the targets.

## Current State

Active: Maintenance | Blocked: None | Recent: Lightpanda browser + puppeteer-core added

## Hot Context

- **Shell layers**: `.profile` → `.zshrc` (Layer 0 sets PATH + HAS_* flags)
- **SSH caveat**: Use `ssh host 'zsh -l -c "cmd"'` for tools in PATH
- **Nodes**: crtr (linux/arm64), drtr (linux/amd64), trtr (darwin/arm64), prtr (linux/amd64)

## Scope Signals

- `@ops` → .protext/scopes/ops.md
- `@dev` → .protext/scopes/dev.md
- `@security` → .protext/scopes/security.md

## Handoff

Last: Protext initialized | Next: Customize hot context | Caution: Review auto-generated content
