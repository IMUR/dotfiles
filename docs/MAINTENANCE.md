# Node Repo Alignment Checklist

This checklist defines the canonical structure for all node-specific configuration repositories (`crtr-config`, `drtr-config`, `trtr-config`, `prtr-config`).

## Structural Contract

- [ ] **Root Files:**
  - [ ] `README.md` (Overview, typically < 50 lines)
  - [ ] `CLAUDE.md` (AI Context, pointing to `docs/` as truth)
  - [ ] `.gitignore` (Standard exclusions)
  - [ ] `.infisical.json` (Optional, if secrets usage exists)
- [ ] **Directories:**
  - [ ] `docs/` (Canonical Node Truth)
  - [ ] `config/` (Optional, local config files)
  - [ ] `scripts/` (Optional, local utilities)
- [ ] **Forbidden:**
  - [ ] No `.meta/` (Legacy governance)
  - [ ] No `.stems/` (Legacy governance)
  - [ ] No `NODE-PROFILES.md` (except in canonical `crtr-config` or `colab-config`)

## Content Contract (docs/)

Each repo must contain these core documents in `docs/`:

- [ ] `NODE.md`: Identity (Hostname, IP, Role)
- [ ] `NETWORK.md`: Interfaces, DNS, Routing facts
- [ ] `SYSTEM.md`: Hardware specs (CPU, RAM, GPU, Storage)

## Operational Contract

- [ ] **Workflow:** Edit -> Validate -> Apply (inherited from `dotfiles`)
- [ ] **Truth:** Node repos own *local* overrides; Cluster truth is referenced from `crtr-config` or `colab-config`.

## Audit Schedule

- **Frequency:** Quarterly
- **Procedure:**
    1. Verify file structure matches this checklist.
    2. Check `CLAUDE.md` for stale instructions.
    3. Validate `docs/NETWORK.md` against actual `ip a` / `tailscale status`.
