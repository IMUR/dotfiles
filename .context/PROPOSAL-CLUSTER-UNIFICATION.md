# Proposal: Declarative Cluster Unification
**Target:** cooperator (crtr), director (drtr), terminator (trtr)
**Philosophy:** Zero maintenance scripts. 100% Declarative State.

## Core Principle
We reject the use of "cleanup scripts" or "maintenance scripts" to manage cluster state. State must be:
1.  **Defined** in `chezmoi` (dotfiles) and `mise` (tools).
2.  **Enforced** by PATH precedence and tool self-management.
3.  **Self-Correcting** on every shell session or `chezmoi apply`.

---

## 1. The "Shadowing" Strategy (Solve Duplicates)
Instead of writing scripts to hunt down and delete `~/.local/bin/bat` or `~/.cargo/bin/eza`, we simply make them irrelevant.

**Mechanism:** `dot_zshenv.tmpl`
We strictly enforce PATH order. `mise` shims **ALWAYS** come before legacy paths.

```zsh
typeset -U PATH
# 1. Mise (The Authority)
PATH="$HOME/.local/share/mise/shims:$PATH"
# 2. Local Overrides (Custom scripts only)
PATH="$HOME/.local/bin:$PATH"
# 3. Legacy/System (Ignored if shadowed)
PATH="$HOME/.cargo/bin:$PATH"
PATH="$HOME/.bun/bin:$PATH"
PATH="$HOME/go/bin:$PATH"
export PATH
```

**Result:**
- Old binary at `~/.cargo/bin/eza` exists? **Irrelevant.**
- `mise` provides `eza`? **Shell uses mise version.**
- No cleanup script required. Old binaries rot harmlessly until the heat death of the SD card.

---

## 2. Universal Tool Definition (`mise.toml`)
All nodes share a single, identical toolset defined in `dot_config/mise/config.toml`. No node-specific tool lists.

**Current Scope:**
- Runtime: `node`, `python`, `go`, `bun`, `uv`
- Core CLI: `bat`, `eza`, `fd`, `ripgrep`, `fzf`, `zoxide`, `starship`

**Proposed Expansion (Replace OS Packages):**
- `delta` (Git diffs)
- `dust` (Disk usage)
- `jq` / `yq` (Data processing)
- `tldr` (Docs)
- `usage` (Completions)
- `bottom` (Monitoring)

**Implementation:**
Update `dot_config/mise/config.toml` once. All nodes receive it via `chezmoi update`.

---

## 3. Self-Healing Bootstrapping
We need **one** touchpoint to ensure the declarative state is realized. This is handled by a single `run_onchange_` hook in chezmoi that triggers only when the tool definition changes.

**File:** `run_onchange_after_mise-install.sh.tmpl`
```bash
#!/bin/bash
# hash: {{ include "dot_config/mise/config.toml" | sha256sum }}
mise install
```

**Workflow:**
1. You add `dust = "latest"` to `config.toml`.
2. You push.
3. Nodes pull & apply.
4. Chezmoi sees config hash changed -> runs `mise install`.
5. `dust` binary appears in shims.
6. `dust` is available immediately.

---

## 4. Configuration Unification
Tools are useless without config. We move all "loose" configs into chezmoi templates.

| Tool | Config Path | Action |
| :--- | :--- | :--- |
| **Git** | `~/.gitconfig` | Create `dot_gitconfig.tmpl` (Identity, delta config, aliases) |
| **Atuin** | `~/.config/atuin/config.toml` | Already managed. Verify sync. |
| **Starship** | `~/.config/starship.toml` | Already managed. |
| **Ghostty** | `~/.config/ghostty/config` | Import if in use. |
| **Nvim** | `~/.config/nvim/` | **Out of Scope** (Too complex for simple templating, use separate repo/stow) |

---

## 5. Execution Plan

### Phase 1: The Definition
1.  Update `dot_config/mise/config.toml` with the expanded toolset.
2.  Create `run_onchange_after_mise-install.sh.tmpl` to auto-hydrate tools.
3.  Create `dot_gitconfig.tmpl` for unified git behavior.

### Phase 2: The Push
1.  Commit and push changes to `main`.

### Phase 3: The Convergence
1.  Run `chezmoi update` on `crtr`, `drtr`, `trtr`.
    *   `chezmoi` updates config files.
    *   `chezmoi` runs `mise install`.
    *   `.zshenv` ensures new tools are prioritized.

**Outcome:** A fully synced cluster with zero manual maintenance scripts.
