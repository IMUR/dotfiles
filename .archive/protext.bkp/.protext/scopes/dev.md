# Scope: Development

## Focus
Template development, testing, and shell configuration patterns for cross-architecture deployment.

## Key Resources
- Template naming: `dot_` (→ `.`), `.tmpl` (Go template), `executable_`, `run_onchange_`
- Go template variables: `.hostname`, `.arch`, `.is_arm64`, `.is_x86_64`, `.cluster.*`
- Tool detection pattern: runtime flags (`$HAS_EZA`) vs template-time checks (`{{- if .is_arm64 }}`)

## Current Priorities
1. Template rendering validation before deployment
2. Cross-architecture compatibility testing
3. Shell configuration layer separation (.profile → .zshrc/.bashrc → .zshrc.local)

## Cautions
- `.profile` is shell-agnostic foundation - sets `$HAS_*` flags used by all shell RCs
- Plugin load order matters: compinit → fzf-tab → fzf → atuin → zoxide/mise/starship → autosuggestions → **syntax-highlighting (LAST)**
- Test template output: `chezmoi execute-template < file.tmpl`
- Architecture flags are template-time; `$HAS_*` flags are runtime
