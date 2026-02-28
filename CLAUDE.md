# CLAUDE.md — dotfiles

This file provides guidance to Claude Code when working in this repository.

## Core Guidelines

Read `AGENTS.md` before beginning any task. It is the single source of truth for project architecture, node inventory, commands, conventions, and operational constraints.

## Quick Orientation

Chezmoi-managed dotfiles for a 4-node cluster (cooperator, director, terminator, projector). Edits go in `/mnt/ops/dotfiles/` (shared NFS mount), then `git push`, then `chezmoi update --force` on targets. Never edit `~/.local/share/chezmoi/` directly.

## Tooling Notes

MCP tools available in this session: Figma, Hugging Face, n8n, Perplexity, Mermaid, GoDaddy. Use them when relevant.

## Critical Constraints

- Always use login shell for remote commands: `ssh node 'zsh -l -c "command"'`
- Never commit secrets or sensitive values to templates
- Never modify system files or make root user changes
- `chezmoi diff` before every `chezmoi apply`
