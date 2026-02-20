# Cluster Dotfiles Audit Results

**Audit Date:** 2026-02-03
**Auditor:** Claude Code (Opus 4.5)
**Scope:** cooperator (crtr), director (drtr), terminator (trtr)
**Validated:** 2026-02-03 (see Addendum A)

---

## Executive Summary

**Critical Issues Found: 5**
- PATH not set in non-interactive SSH on crtr/trtr (missing `.zshenv`) ~~[CORRECTED: was ".zprofile"]~~
- All 4 git repositories at different commits (massive drift)
- mise not installed on trtr (macOS)
- chezmoi not in PATH on crtr (PATH issue symptom)
- drtr using SSH remote while others use HTTPS

> **⚠️ AUDIT METHODOLOGY WARNING**
> This audit was conducted via non-interactive SSH (`ssh node 'command'`). Due to the very PATH issue being diagnosed, many tool detection commands (`which`, `command -v`) returned false negatives. See **Addendum A** for validated corrections.

---

## Phase 1: Raw State Collection

### 1.1 System Identity

| Node | Hostname | OS | Arch | CPU | Memory |
|------|----------|-----|------|-----|--------|
| crtr | cooperator | Debian 13 (trixie) | aarch64 | BCM2712 (Pi5) 4c @ 2.4GHz | 16GB |
| drtr | director | Debian 13 (trixie) | x86_64 | i9-9900K 16c @ 5.0GHz | 63GB |
| trtr | terminator | macOS Tahoe 26.2 | arm64 | Apple M4 10c @ 4.5GHz | 24GB |

### 1.2 Chezmoi State

<details>
<summary>crtr - chezmoi NOT in PATH</summary>

```
$ chezmoi doctor
zsh: command not found: chezmoi

Binary exists at: /home/crtr/.local/bin/chezmoi (v2.66.0)
PATH during zsh -l: /usr/local/bin:/usr/bin:/bin:/usr/games
Root cause: ~/.local/bin not added to PATH (see Shell Configuration section)
```
</details>

<details>
<summary>drtr - chezmoi v2.65.1 (outdated)</summary>

```
RESULT    CHECK                       MESSAGE
ok        version                     v2.65.1
warning   latest-version              v2.69.3
ok        source-dir                  ~/.local/share/chezmoi is a git working tree (clean)
error     hardlink                    failed creating hardlink (cross-device link)
warning   edit-command                vim not found in $PATH
warning   merge-command               vimdiff not found in $PATH
```

**Source Path:** `/home/drtr/.local/share/chezmoi`
**Git Status:** clean
**Remote:** `git@github.com:IMUR/dotfiles.git` (SSH - different from others!)
</details>

<details>
<summary>trtr - chezmoi v2.69.3 (current via Homebrew)</summary>

```
RESULT   CHECK                       MESSAGE
ok       version                     v2.69.3 (Homebrew)
ok       source-dir                  ~/.local/share/chezmoi is a git working tree (clean)
```

**Source Path:** `/Users/trtr/.local/share/chezmoi`
**Git Status:** clean
**Remote:** `https://github.com/IMUR/dotfiles.git`
**Local Drift:** `.zshrc` has local Docker completion modifications
</details>

### 1.3 Mise State

| Node | Mise Version | Activated | Shims in PATH | Tools Installed |
|------|--------------|-----------|---------------|-----------------|
| crtr | 2026.2.1 | No (warning) | No | 13 (atuin, bat, bun, eza, fd, fzf, go, node, python, ripgrep, starship, uv, zoxide) |
| drtr | 2026.1.2 | No | Yes | 4 (bun, node, python, uv) |
| trtr | **NOT INSTALLED** | N/A | N/A | Config file exists but mise not in PATH |

<details>
<summary>crtr mise config (~/.config/mise/config.toml)</summary>

```toml
[tools]
atuin = "latest"
bun = "latest"
go = "latest"
node = "lts"
python = "3.14"
ripgrep = "latest"
uv = "latest"
fd = "latest"
starship = "latest"
bat = "latest"
eza = "latest"
zoxide = "latest"
fzf = "latest"
```
</details>

<details>
<summary>drtr mise config (~/.config/mise/config.toml)</summary>

```toml
[tools]
bun = "latest"
node = "lts"
python = "latest"
uv = "latest"

[settings.python]
venv_stdlib = true
```
</details>

<details>
<summary>trtr mise config - FILE EXISTS but mise NOT INSTALLED</summary>

```toml
[tools]
atuin = "latest"
bun = "latest"
go = "latest"
node = "lts"
python = "3.14"
ripgrep = "latest"
uv = "latest"
fd = "latest"
starship = "latest"
bat = "latest"
eza = "latest"
zoxide = "latest"
fzf = "latest"
```
</details>

### 1.4 Shell Configuration

#### How `.profile` is sourced (CRITICAL DIFFERENCE)

| Node | Method in `.zshrc` | Line |
|------|-------------------|------|
| crtr | `source ~/.profile` | 15 |
| drtr | `emulate sh -c 'source ~/.profile'` | 14 |
| trtr | `source ~/.profile` | 15 |

**drtr uses a different sourcing method** which may cause subtle differences.

#### PATH After Full Shell Init

| Node | Shell Type | PATH Contains ~/.local/bin | PATH Contains mise |
|------|------------|---------------------------|-------------------|
| crtr | `zsh -l` (non-interactive) | **NO** | **NO** |
| crtr | `zsh -l -i` (interactive) | YES | YES |
| crtr | `bash -l` (login) | YES | YES |
| drtr | `zsh -l` | YES | YES (shims) |
| trtr | `zsh -l` | N/A (Homebrew-based) | **NO** (mise not installed) |

**ROOT CAUSE:** `.profile` is sourced in `.zshrc`, but `.zshrc` is only loaded for **interactive** shells. Non-interactive login shells (`zsh -l -c "command"`) don't load `.zshrc`, so PATH is never set.

**~~Missing:~~ CORRECTED:** ~~A `.zprofile` that sources `.profile` for login-only shells.~~

> **✅ CORRECT FIX: `.zshenv` not `.zprofile`**
>
> drtr works because it has `~/.zshenv`:
> ```bash
> . "$HOME/.cargo/env"
> export PATH="$HOME/.local/share/mise/shims:$PATH"
> ```
> `.zshenv` is sourced for ALL zsh invocations (login, non-login, interactive, non-interactive).
> `.zprofile` only helps login shells. `.zshenv` fixes everything.

### 1.5 Tool Availability

> **⚠️ FALSE NEGATIVES:** This table contains errors due to non-interactive shell PATH issues.
> See **Addendum A** for validated tool locations.

| Tool | crtr | drtr | trtr | Source |
|------|------|------|------|--------|
| zoxide | NO (PATH issue) | ~/.local/bin | **NOT FOUND** | mise/cargo |
| starship | NO (PATH issue) | ~/.local/bin | /opt/homebrew/bin | mise/brew |
| atuin | NO (PATH issue) | ~/.cargo/bin | **NOT FOUND** | mise/cargo |
| fzf | /usr/bin | /usr/bin | /opt/homebrew/bin | system/brew |
| bat | NO (PATH issue) | ~/.local/bin | /opt/homebrew/bin | mise/brew |
| eza | NO (PATH issue) | ~/.cargo/bin | **NOT FOUND** | mise/cargo |
| fd | NO (PATH issue) | ~/.local/bin | **NOT FOUND** | mise |
| node | NO (PATH issue) | mise shims | /opt/homebrew/bin | mise/brew |
| python | /usr/bin (system) | mise shims | **NOT FOUND** ~~[FALSE: brew 3.14.2]~~ | system/mise |
| go | /usr/bin (system) | **NOT FOUND** | **NOT FOUND** | system |
| uv | NO (PATH issue) | mise shims | **NOT FOUND** ~~[FALSE: ~/.local/bin]~~ | mise |
| bun | NO (PATH issue) | mise shims | **NOT FOUND** ~~[FALSE: ~/.bun/bin 1.3.6]~~ | mise |

### 1.6 Hook Conflicts (Zsh chpwd_functions)

| Node | chpwd_functions | Potential Conflicts |
|------|-----------------|---------------------|
| crtr | `_mise_hook_chpwd __zoxide_hook` | None detected |
| drtr | `__zoxide_hook` | Missing mise hook (expected if mise not activated) |
| trtr | (empty) | No hooks - zoxide not active |

---

## Phase 2: Cross-Node Comparison

### 2.1 Chezmoi Source Drift vs /mnt/ops/dotfiles

| Node | Can Access /mnt/ops/dotfiles | Drift |
|------|------------------------------|-------|
| crtr | YES | `dot_profile.tmpl` differs, missing `dot_local/`, `run_onchange_install_packages.sh.tmpl` |
| drtr | NO (empty mount) | Cannot compare |
| trtr | NO (no /mnt) | Cannot compare |

### 2.2 Template vs Reality (`chezmoi diff`)

| Node | Local Changes to Remove |
|------|------------------------|
| crtr | pnpm config block in `.zshrc` |
| drtr | Clean - no diff |
| trtr | Docker CLI completions in `.zshrc` |

### 2.3 Git State Comparison (CRITICAL)

| Location | HEAD Commit | Commits Behind /mnt/ops/dotfiles | Remote URL |
|----------|-------------|----------------------------------|------------|
| /mnt/ops/dotfiles | **fed4d64** (canonical) | 0 | https://github.com/IMUR/dotfiles |
| crtr ~/.local/share/chezmoi | a33b634 | **4 commits** | https://github.com/IMUR/dotfiles.git |
| drtr ~/.local/share/chezmoi | 582d066 | **12 commits** | git@github.com:IMUR/dotfiles.git (SSH!) |
| trtr ~/.local/share/chezmoi | 7993c9b | **2 commits** | https://github.com/IMUR/dotfiles.git |

**Commit Timeline (newest first):**
```
fed4d64 docs: update CLUSTER-DOTFILES-STATUS.md          <- /mnt/ops/dotfiles (HEAD)
0205c77 status
7993c9b fix(path): add ~/.bun/bin to PATH                <- trtr (HEAD)
1395950 feat: add skill-browser and fzf/bat installer
a33b634 fix(zsh): correct plugin loading order           <- crtr (HEAD)
c483079 feat(zsh): add autosuggestions, syntax-highlighting, and fzf-tab plugins
2e28773 fix: hostname detection using output
800f352 feat(shell): modernize with mise, starship, zoxide and bun
...
582d066 Remove cluster management scripts from dotfiles  <- drtr (HEAD, 12 commits behind!)
```

**drtr is SIGNIFICANTLY behind** - missing the entire mise/starship/zoxide modernization!

---

## Phase 3: Architecture Analysis

### 3.1 Source of Truth Question

**Current State:** Unclear/Fragmented
- `/mnt/ops/dotfiles` appears intended as canonical but is only accessible from crtr
- drtr and trtr cannot access this path (mount not configured)
- Each node has its own local chezmoi source with different commits

**Git Workflow Issues:**
- drtr uses SSH remote (`git@github.com`) while others use HTTPS
- No apparent push/pull synchronization happening
- Nodes at wildly different commit states

### 3.2 Shell Init Order Analysis

**Expected Order:**
```
┌─────────────────────────────────────────────────────────┐
│ Login Shell (zsh -l)                                    │
├─────────────────────────────────────────────────────────┤
│ 1. /etc/zsh/zshenv                                      │
│ 2. ~/.zshenv           <- NOT MANAGED BY CHEZMOI        │
│ 3. /etc/zsh/zprofile                                    │
│ 4. ~/.zprofile         <- MISSING! Should source .profile│
│ 5. /etc/zsh/zshrc      (interactive only)               │
│ 6. ~/.zshrc            (interactive only) <- sources .profile│
└─────────────────────────────────────────────────────────┘
```

**Current Problem:**
- `.profile` contains PATH setup and mise activation
- `.profile` is sourced in `.zshrc` (line 15)
- `.zshrc` only loads for **interactive** shells
- Non-interactive SSH (`ssh host 'zsh -l -c "cmd"'`) never loads `.zshrc`
- Result: PATH not set, tools not found

**Required Fix:** Create `dot_zprofile.tmpl`:
```bash
# Source .profile for PATH and environment in login shells
# This is sourced even for non-interactive login shells
[[ -f ~/.profile ]] && source ~/.profile
```

### 3.3 Mise Management Analysis

**Current Mise Activation:**

| Location | Activation Method | Issue |
|----------|-------------------|-------|
| `.profile:75` | `eval "$(mise activate bash --shims)"` | bash-specific, may not work in other shells |
| `.zshrc:236` | `eval "$(mise activate zsh)"` | Only for interactive zsh |
| `.bashrc:205` | `eval "$(mise activate bash)"` | Only for interactive bash |

**Problem:** Double activation potential - `.profile` activates with shims, then `.zshrc` activates again with hooks.

### 3.4 Drift Inventory

| Drift Type | Node | Details | Action |
|------------|------|---------|--------|
| Git commit | drtr | 12 commits behind | Pull latest |
| Git commit | crtr | 4 commits behind | Pull latest |
| Git commit | trtr | 2 commits behind | Pull latest |
| Local mod | crtr | pnpm block in .zshrc | `chezmoi apply` |
| Local mod | trtr | Docker completions in .zshrc | `chezmoi apply` |
| Missing file | ALL | `.zprofile` | Create template |
| Tool missing | trtr | mise not installed | Install via Homebrew |
| Config | drtr | `is_x86_64 = false` (should be true) | Regenerate chezmoi.toml |

---

## Phase 4: Issue Inventory

| # | Issue | Node(s) | Severity | Category | Status |
|---|-------|---------|----------|----------|--------|
| 1 | No `.zshenv` - PATH not set in non-interactive shells | crtr, trtr | **CRITICAL** | config | ~~was .zprofile~~ |
| 2 | drtr 12 commits behind canonical source | drtr | **CRITICAL** | drift | |
| 3 | mise not installed | trtr | **HIGH** | missing | |
| 4 | All nodes at different git commits | ALL | **HIGH** | drift | |
| 5 | drtr uses SSH remote while others use HTTPS | drtr | **MEDIUM** | config | |
| 6 | drtr `is_x86_64 = false` (incorrect) | drtr | **MEDIUM** | config | |
| 7 | drtr sources .profile with `emulate sh` (different method) | drtr | **MEDIUM** | config | |
| 8 | Double mise activation (.profile + .zshrc) | crtr, trtr | **LOW** | order | |
| 9 | pnpm config not in template (local addition) | crtr | **LOW** | drift | |
| 10 | Docker completions not in template (local addition) | trtr | **LOW** | drift | |
| 11 | No shared mount access from drtr/trtr to /mnt/ops/dotfiles | drtr, trtr | **LOW** | infra | |
| 12 | Mise tool versions inconsistent (drtr has fewer tools) | drtr | **LOW** | config | |
| 13 | **NEW** Multiple Python installations causing version conflicts | ALL | **HIGH** | config | See Addendum A |
| 14 | **NEW** Tool version drift across nodes | ALL | **MEDIUM** | config | See Addendum A |

---

## Phase 5: Recommendations

### 5.1 Immediate Fixes (Blocking)

#### ~~Fix 1: Create `.zprofile` template (CRITICAL)~~ SUPERSEDED

~~Create `dot_zprofile.tmpl`:~~

> **✅ CORRECTED FIX: Create `.zshenv` template**
>
> Create `dot_zshenv.tmpl`:
> ```bash
> # ~/.zshenv - sourced for ALL zsh shells (login, non-login, interactive, non-interactive)
> # This ensures PATH is set for: ssh host 'command', ssh host 'zsh -c "command"', scripts, etc.
>
> # Cargo/Rust environment
> [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
>
> # Core PATH additions (order matters - first wins)
> export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$PATH"
>
> # macOS Homebrew
> [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
> ```
>
> **Why `.zshenv` not `.zprofile`:**
> - `.zprofile` = login shells only
> - `.zshenv` = ALL zsh invocations
> - drtr already has this and it works

#### Fix 2: Sync all nodes to latest commit

```bash
# On each node (using interactive shell to ensure PATH):
ssh <node> 'zsh -l -i -c "cd ~/.local/share/chezmoi && git pull origin main && chezmoi apply"'
```

#### Fix 3: Install mise on trtr

```bash
ssh trtr 'zsh -l -i -c "brew install mise"'
```

Then run `chezmoi apply` to get config.

### 5.2 Architecture Decision

**Recommended: Git-only workflow (no symlinks)**

Rationale:
- Symlinks to NAS create dependency on network mount availability
- Git provides version control and audit trail
- Each node maintains its own local chezmoi source
- Sync via git pull from GitHub

**Workflow:**
1. Edit templates on any node (preferably crtr which has NAS access)
2. `chezmoi git -- add -A && chezmoi git -- commit -m "message" && chezmoi git -- push`
3. On other nodes: `chezmoi git -- pull && chezmoi apply`

**Consider:** Standardize all remotes to HTTPS (drtr uses SSH).

### 5.3 Init Order Fix

**Proposed Correct Order in Templates:**

```
.zprofile (NEW)
└── source ~/.profile
    ├── PATH setup (add ~/.local/bin, ~/.cargo/bin, etc.)
    ├── mise activate bash --shims (for PATH availability)
    └── HAS_* tool detection

.zshrc (interactive only)
├── (inherits PATH and HAS_* from .zprofile → .profile)
├── compinit
├── fzf-tab plugin
├── fzf --zsh
├── atuin init zsh
├── zoxide init zsh
├── mise activate zsh (full hook mode, not just shims)
├── starship init zsh
├── autosuggestions plugin
└── syntax-highlighting plugin (MUST BE LAST)
```

### 5.4 Drift Resolution

| Node | Action |
|------|--------|
| crtr | `chezmoi git -- pull && chezmoi apply` (removes pnpm block) |
| drtr | `chezmoi git -- remote set-url origin https://github.com/IMUR/dotfiles.git && chezmoi git -- pull && chezmoi apply` |
| trtr | `chezmoi git -- pull && chezmoi apply` (removes Docker block) |

**Local additions to consider upstreaming:**
- pnpm config (if needed cluster-wide)
- Docker completions (probably not - macOS-specific)

### 5.5 Validation Process

After fixes, verify with:

```bash
# Test non-interactive SSH (the problem case)
ssh <node> 'zsh -l -c "which chezmoi mise zoxide starship"'

# Should return paths, not "not found"

# Test tool detection
ssh <node> 'zsh -l -c "echo HAS_ZOXIDE=\$HAS_ZOXIDE"'

# Should return HAS_ZOXIDE=1

# Test git state
ssh <node> 'zsh -l -c "chezmoi git -- log --oneline -1"'

# All nodes should show same commit
```

---

## Appendix: File References

| Issue | File | Line(s) |
|-------|------|---------|
| .profile sourcing in zshrc | `dot_zshrc.tmpl` | 15 |
| mise shim activation | `dot_profile.tmpl` | 75 |
| mise full activation | `dot_zshrc.tmpl` | 236 |
| Tool detection | `dot_profile.tmpl` | 82-96 |
| PATH setup | `dot_profile.tmpl` | 36-45 |
| zsh plugin order | `dot_zshrc.tmpl` | 148-265 |
| Architecture flags | `.chezmoi.toml.tmpl` | 12-13 |

---

## Summary

The cluster dotfiles have significant drift and a fundamental architectural issue with shell init order. The most critical fix is adding a `.zprofile` to ensure PATH is set in non-interactive login shells, which will resolve the "command not found" issues that have been plaguing SSH command execution.

Secondary priorities are synchronizing all nodes to the same git commit and installing mise on trtr.

**Do not apply any changes yet.** This report is for review. Once approved, implement fixes in the order specified in section 5.1.

---

## Addendum A: Post-Audit Validation (2026-02-03)

### A.1 Methodology Issue

The original audit used non-interactive SSH commands (`ssh node 'which tool'`), which failed to find tools due to the very PATH issue being diagnosed. This created **circular false negatives**.

**Validation method:** Direct path inspection (`ls -la ~/.local/bin/tool`) bypassing PATH.

### A.2 Why drtr Works

drtr has `~/.zshenv` (not managed by chezmoi):
```bash
. "$HOME/.cargo/env"
export PATH="$HOME/.local/share/mise/shims:$PATH"
```

**Non-interactive PATH comparison:**
| Node | PATH in `ssh node 'echo $PATH'` |
|------|--------------------------------|
| crtr | `/usr/local/bin:/usr/bin:/bin:/usr/games` (broken) |
| drtr | `~/.local/share/mise/shims:~/.local/bin:~/bin:~/.cargo/bin:...` (working) |
| trtr | `/usr/bin:/bin:/usr/sbin:/sbin` (broken) |

### A.3 False Negatives Corrected

#### crtr - 16 tools exist but invisible to `which`

| Tool | Actual Location | Audit Said |
|------|-----------------|------------|
| chezmoi | ~/.local/bin | NO (PATH issue) ✓ |
| starship | ~/.local/bin + mise shims | NO (PATH issue) ✓ |
| uv | ~/.local/bin + mise shims | NO (PATH issue) ✓ |
| claude | ~/.local/bin | NO (PATH issue) ✓ |
| aider | ~/.local/bin | NO (PATH issue) ✓ |
| cursor-agent | ~/.local/bin | NO (PATH issue) ✓ |
| skill-browser | ~/.local/bin | NO (PATH issue) ✓ |
| bat | ~/.cargo/bin + mise shims | NO (PATH issue) ✓ |
| eza | ~/.cargo/bin + mise shims | NO (PATH issue) ✓ |
| zoxide | ~/.cargo/bin + mise shims | NO (PATH issue) ✓ |
| atuin | mise shims | NO (PATH issue) ✓ |
| bun | ~/.bun/bin + mise shims | NO (PATH issue) ✓ |
| fd | mise shims | NO (PATH issue) ✓ |
| node | mise shims | NO (PATH issue) ✓ |
| gemini | mise shims | NO (PATH issue) ✓ |

*Audit was technically correct ("PATH issue") but severity was understated.*

#### trtr - 17 tools exist but 100% invisible to `which`

| Tool | Actual Location | Audit Said |
|------|-----------------|------------|
| claude | ~/.local/bin + /opt/homebrew/bin | NOT FOUND ✗ |
| cursor-agent | ~/.local/bin | NOT FOUND ✗ |
| skill-browser | ~/.local/bin | NOT FOUND ✗ |
| uv | ~/.local/bin | NOT FOUND ✗ |
| uvx | ~/.local/bin | NOT FOUND ✗ |
| bun | ~/.bun/bin (v1.3.6) | NOT FOUND ✗ |
| bat | /opt/homebrew/bin | Correct ✓ |
| starship | /opt/homebrew/bin | Correct ✓ |
| fzf | /opt/homebrew/bin | Correct ✓ |
| chezmoi | /opt/homebrew/bin | NOT FOUND ✗ |
| mkdocs | ~/.local/bin | NOT FOUND ✗ |
| kimi | ~/.local/bin | NOT FOUND ✗ |
| python3.14 | ~/.local/bin + /opt/homebrew/bin | NOT FOUND ✗ |
| idb | ~/.local/bin | NOT FOUND ✗ |
| bytebot | ~/.local/bin | NOT FOUND ✗ |
| clawdhub | ~/.bun/bin | NOT FOUND ✗ |
| opencode | ~/.bun/bin | NOT FOUND ✗ |

**trtr's `.zprofile` only runs `brew shellenv`** - doesn't add ~/.local/bin or ~/.bun/bin.

### A.4 Tool Version Conflicts

#### Python (HIGH RISK)

| Node | System | Managed | Gap |
|------|--------|---------|-----|
| crtr | 3.13.5 (/usr/bin) | mise 3.14.2 | 0.1 |
| drtr | 3.13.5 (/usr/bin) | mise 3.14.0 | 0.1 |
| trtr | **3.9.6** (/usr/bin Apple CLT) | brew 3.14.2 | **4.5 majors** |

**Risk:** Scripts using `python3` get different versions depending on PATH order and shell context.

#### Node (MEDIUM RISK)

| Node | Version | Source |
|------|---------|--------|
| crtr | 24.12.0 | mise |
| drtr | 24.11.1 | mise |
| trtr | **25.5.0** | Homebrew |

**Risk:** trtr on Node 25 (major version ahead), potential breaking changes.

#### Go (HIGH RISK - crtr internal conflict)

| Node | System | Managed |
|------|--------|---------|
| crtr | 1.24.4 (/usr/bin) | mise 1.25.5 |
| drtr | NONE | NONE |
| trtr | NONE | NONE |

**Risk:** crtr has TWO Go versions; which runs depends on PATH order.

#### uv (HIGH RISK - crtr internal conflict)

| Node | Location 1 | Location 2 |
|------|------------|------------|
| crtr | mise 0.9.21 | ~/.local/bin 0.9.7 |
| drtr | mise 0.9.12 | - |
| trtr | ~/.local/bin | - |

**Risk:** crtr has TWO uv versions with different behaviors.

#### Other Tools

| Tool | crtr | drtr | trtr |
|------|------|------|------|
| bun | 1.3.5 | 1.3.3 | 1.3.6 |
| starship | 1.23.0 | 1.23.0 | 1.24.1 |
| atuin | 18.10.0 | 18.8.0 | **NONE** |

### A.5 Revised Fix Priority

1. **CRITICAL:** Create `dot_zshenv.tmpl` in chezmoi (fixes PATH for all contexts)
2. **CRITICAL:** Sync all nodes to same git commit
3. **HIGH:** Install mise on trtr OR standardize on Homebrew-only for macOS
4. **HIGH:** Resolve duplicate tool installations on crtr (uv, go)
5. **MEDIUM:** Standardize tool versions across nodes
6. **MEDIUM:** Decide on Python strategy (system vs managed)

### A.6 Recommended .zshenv Template

```bash
# ~/.zshenv - sourced for ALL zsh shells
# Ensures PATH works for: interactive, non-interactive, login, non-login, scripts, SSH commands

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# PATH construction (first entry wins on conflict)
typeset -U PATH  # unique entries only
PATH="$HOME/.local/share/mise/shims:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="$HOME/.bun/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"
PATH="$HOME/go/bin:$PATH"
export PATH

# macOS Homebrew (if present)
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
```

---

*Addendum added after validation session identifying audit false negatives and methodology limitations.*
