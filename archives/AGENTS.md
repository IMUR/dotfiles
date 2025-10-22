# Repository Guidelines

## Project Structure & Module Organization
- `ssot/state/` holds the YAML source of truth for node, network, services, and domains; update these first before touching the live host.
- `tools/` provides operator scripts (`ssot`, `discover.sh`, `deploy.sh`, etc.) that read/write the state files; treat them as the preferred interface for automation.
- `backups/` stores sanitized configuration exports (DNS, Pi-hole, systemd); sensitive snapshots live off-repo on `/cluster-nas/backups/`.
- `archives/` contains historical planning docs; reference them for context, not live configuration.

## Build, Test, and Development Commands
- `./tools/ssot discover` — capture live configuration into `ssot/state/` for review.
- `./tools/ssot validate` — schema-check all state files; run before every commit or deploy.
- `./tools/ssot diff` — compare desired vs. live state to confirm intended changes.
- `./tools/ssot deploy --service=<name>` — apply a specific service configuration after validation; use `--all` for full rollouts.

## Coding Style & Naming Conventions
- YAML: two-space indentation, lowercase keys with hyphenated lists; keep comments explaining data provenance (e.g., `# Source: COOPERATOR-ASPECTS.md`).
- Bash: enable `set -euo pipefail`, prefer long-form flags, and document dependencies at the top of each script.
- File paths mirror capabilities (`services.yml`, `network.yml`); keep new files aligned with existing naming patterns.

## Testing Guidelines
- Treat `./tools/ssot validate` as the mandatory smoke test; it exercises JSON schema validation for all state files.
- Use `./tools/ssot diff` against a staging host before deploying to production hardware.
- For manual service checks, capture `systemctl status <service>` outputs and store them under `backups/services/` when relevant.

## Commit & Pull Request Guidelines
- Follow the existing history: short, imperative subject lines (e.g., “Fix tool paths after reorganization”).
- Squash related changes into cohesive commits that touch state, tooling, and docs together when required for traceability.
- Pull requests should summarize the operational effect, link to any tracked incident or ticket, list `ssot` commands executed (discover/validate/diff/deploy), and note any files copied to `/cluster-nas` or other out-of-repo locations.

## Security & Configuration Tips
- Never commit secrets (DuckDNS token, SSH keys); reference secure file locations instead, such as `/cluster-nas/secrets/duckdns.token`.
- Validate that `/etc/caddy/`, `/etc/pihole/`, and `/etc/exports` updates are mirrored in `ssot/state/` so automation remains authoritative.
- When running from a fresh Raspberry Pi OS install, recreate the `crtr` user environment via Chezmoi (`chezmoi init --source ~/Projects/colab-config/dotfiles && chezmoi apply`) before executing deployment scripts.
