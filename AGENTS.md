# Repository Guidelines

## Project Structure & Module Organization
This repository is a Chezmoi-managed dotfiles source of truth for cluster nodes. Most managed files live at the repo root as templates such as `dot_profile.tmpl`, `dot_zshrc.tmpl`, and `dot_bashrc.tmpl`.

- `dot_config/`: templated app/tool configs (for example `dot_config/mise/config.toml`, `dot_config/starship.toml`)
- `dot_local/bin/`: user executables deployed to `~/.local/bin`
- `dot_ssh/`: SSH helper scripts
- `docs/` and `.context/`: operational and architecture records
- `run_onchange_*.sh.tmpl`: hooks executed when template content changes

## Build, Test, and Development Commands
Use Chezmoi commands as the validation/build loop:

- `chezmoi diff`: preview pending changes
- `chezmoi execute-template < dot_zshrc.tmpl`: validate template rendering
- `chezmoi doctor`: check Chezmoi health and config
- `chezmoi apply`: apply locally after validation
- `chezmoi update --force`: pull/apply latest repo state on target nodes
- `mise install --yes`: install/update tools after changing `dot_config/mise/config.toml`

For remote execution, always use a login shell:
`ssh drtr 'zsh -l -c "chezmoi status"'`.

## Coding Style & Naming Conventions
Follow existing shell/template style and keep logic simple and explicit.

- Keep portable environment setup in `dot_profile.tmpl`; keep shell-specific behavior in `dot_zshrc.tmpl`/`dot_bashrc.tmpl`
- Prefer small helper functions over repeated command snippets
- Naming rules:
- `dot_` prefix maps to hidden files
- `.tmpl` suffix means Go template rendering
- `executable_` prefix sets execute permission
- `run_onchange_` prefix defines change-triggered hooks

## Testing Guidelines
There is no unit test framework here; validation is command-driven.

1. Run `chezmoi diff` and review output.
2. Render changed templates with `chezmoi execute-template`.
3. Apply and verify on one node first.
4. Promote cluster-wide with `chezmoi update --force`.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commit style (examples: `docs: ...`, `chore(tools): ...`, `fix(shell): ...`, `feat(tools): ...`).

- Keep commits focused to one concern and scope.
- In PRs, include: intent, affected files/nodes, verification commands run, and rollout/rollback notes.
- Never commit secrets; keep sensitive values outside tracked templates.

## Security & Workflow Notes
- Edit only in `/mnt/ops/dotfiles` (or `/Volumes/ops/dotfiles` on `trtr`), then commit/push.
- Do not edit `~/.local/share/chezmoi` directly; it is a managed clone, not the authoring workspace.
