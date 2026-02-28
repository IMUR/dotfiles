# GEMINI.md — dotfiles

## Core Guidelines

Read `AGENTS.md` before beginning any task. It is the single source of truth for project architecture, node inventory, commands, conventions, and operational constraints.

## Quick Orientation

Chezmoi-managed dotfiles for a 4-node cluster (cooperator, director, terminator, projector). All edits happen in `/mnt/ops/dotfiles/` (shared NFS mount on Linux, `/Volumes/ops/dotfiles/` on macOS `trtr`), then committed and pushed to GitHub, then applied via `chezmoi update --force` on each node.

## Tooling Notes

Gemini CLI's built-in `run_shell_command` is available. When running remote commands, always use a login shell (`ssh node 'zsh -l -c "command"'`) so mise-managed tools are in PATH.

## Critical Constraints

- Never edit `~/.local/share/chezmoi/` — that is a managed clone, not the authoring workspace
- Never commit secrets to templates
- Always run `chezmoi diff` before `chezmoi apply`
- `run_onchange_` scripts must be idempotent
