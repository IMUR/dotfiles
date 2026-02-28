# Dotfiles Cluster Fix - Continuation Prompt

**Created:** 2026-02-03
**Context:** Follow-up to CLUSTER-AUDIT-RESULTS.md validation session
**Status:** Audit complete, fixes designed, implementation pending

---

## Background

You are continuing work on the IMUR/dotfiles chezmoi repository that manages shell configuration across a 3-node Raspberry Pi cluster:

| Node | Hostname | OS | Role |
|------|----------|-----|------|
| crtr | cooperator | Debian 13 arm64 | Edge services, NFS host |
| drtr | director | Debian 13 x86_64 | GPU/compute node |
| trtr | terminator | macOS Tahoe arm64 | Workstation |

**Repository locations:**
- Canonical source: `/mnt/ops/dotfiles/` (on crtr, NFS-shared)
- GitHub: `https://github.com/IMUR/dotfiles`
- Per-node chezmoi: `~/.local/share/chezmoi/` (each node)

---

## Problem Statement

Non-interactive SSH commands fail to find tools because PATH isn't set:

```bash
# This fails on crtr and trtr:
ssh crtr 'which chezmoi'  # "not found" - but chezmoi exists at ~/.local/bin/chezmoi

# This works on drtr:
ssh drtr 'which chezmoi'  # /home/drtr/.local/bin/chezmoi
```

**Root cause:** crtr and trtr lack `~/.zshenv`. drtr has one and works.

---

## Current State

### What Works
- drtr: Full PATH in all shell contexts (has ~/.zshenv)
- All nodes: Tools installed and functional in interactive shells

### What's Broken
- crtr: 16 tools invisible in non-interactive shells
- trtr: 17 tools invisible in non-interactive shells (100% failure rate)
- crtr: Internal version conflicts (two versions of uv, two versions of go)
- trtr: Ancient system Python (3.9.6) conflicts with Homebrew Python (3.14.2)
- All nodes: Different git commits in chezmoi source

### Files to Reference
- `/mnt/ops/dotfiles/CLUSTER-AUDIT-RESULTS.md` - Full audit with Addendum A corrections
- `/mnt/ops/dotfiles/CLUSTER-DOTFILES-STATUS.md` - High-level status
- `/mnt/ops/dotfiles/dot_profile.tmpl` - PATH setup (currently only sourced by .zshrc)
- `/mnt/ops/dotfiles/dot_zshrc.tmpl` - Interactive shell config

---

## Required Fixes (Priority Order)

### 1. CRITICAL: Create `dot_zshenv.tmpl`

This is the primary fix. Create a new chezmoi template:

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

**Why `.zshenv` not `.zprofile`:**
- `.zprofile` = login shells only (won't help `ssh node 'command'`)
- `.zshenv` = ALL zsh invocations (fixes everything)

### 2. CRITICAL: Sync git state

All nodes should be at the same commit:

```bash
# From crtr (has NFS access):
cd /mnt/ops/dotfiles && git pull origin main

# On each node:
ssh <node> 'zsh -l -i -c "cd ~/.local/share/chezmoi && git pull origin main && chezmoi apply"'
```

Note: drtr uses SSH remote - may need to switch to HTTPS:
```bash
ssh drtr 'cd ~/.local/share/chezmoi && git remote set-url origin https://github.com/IMUR/dotfiles.git'
```

### 3. HIGH: Resolve crtr duplicate installations

crtr has conflicting versions:
- uv: mise 0.9.21 vs ~/.local/bin 0.9.7
- go: /usr/bin 1.24.4 vs mise 1.25.5

**Decision needed:** Use mise-managed versions only? Remove ~/.local/bin duplicates?

### 4. HIGH: trtr tooling strategy

Options:
1. Install mise on trtr and use same config as Linux nodes
2. Accept Homebrew-only approach for macOS, document differences
3. Hybrid: mise for some tools, Homebrew for others

**Current trtr state:**
- Has: bun (1.3.6), bat, fzf, starship, chezmoi, node (25.5.0), python (3.14.2) via Homebrew
- Missing: mise, atuin, zoxide, eza, fd, go

### 5. MEDIUM: Python strategy

All nodes have multiple Python installations:
| Node | System | Managed |
|------|--------|---------|
| crtr | 3.13.5 | mise 3.14.2 |
| drtr | 3.13.5 | mise 3.14.0 |
| trtr | 3.9.6 (ancient!) | brew 3.14.2 |

**Decision needed:**
- Always use mise/brew Python, never system?
- Pin specific version across cluster?
- Let PATH order decide (current implicit behavior)?

---

## Validation Commands

After implementing fixes, verify with:

```bash
# Test non-interactive PATH (the problem case)
for node in crtr drtr trtr; do
  echo "=== $node ==="
  ssh $node 'echo $PATH | tr ":" "\n" | head -5'
done

# Test tool visibility
for node in crtr drtr trtr; do
  echo "=== $node ==="
  ssh $node 'which chezmoi uv bun node python3 2>&1'
done

# Test git state
for node in crtr drtr trtr; do
  echo "=== $node ==="
  ssh $node 'zsh -l -i -c "chezmoi git -- log --oneline -1"'
done
```

---

## Do NOT Do

- Do not create `.zprofile` - it doesn't solve the non-interactive shell problem
- Do not assume `which` results from non-interactive SSH are accurate (the audit had this bug)
- Do not remove drtr's existing `~/.zshenv` - it's the reference implementation
- Do not run destructive commands without understanding current state

---

## Session History

1. Initial audit conducted via non-interactive SSH
2. Audit identified PATH issues but recommended wrong fix (.zprofile)
3. Validation session discovered drtr works due to .zshenv
4. Full tool inventory revealed extensive false negatives
5. Version conflicts identified (Python, Node, Go, uv)
6. This continuation prompt created for follow-up implementation

---

## First Steps for Next Session

1. Read `CLUSTER-AUDIT-RESULTS.md` including Addendum A
2. Verify current git state: `cd /mnt/ops/dotfiles && git status`
3. Create `dot_zshenv.tmpl` with the template above
4. Test on one node before applying cluster-wide
5. Commit and push, then sync other nodes

---

## Questions to Resolve with User

Before implementing, confirm:

1. **Duplicate tools on crtr:** Remove ~/.local/bin versions or keep both?
2. **trtr strategy:** Install mise or stay Homebrew-only?
3. **Python pinning:** Explicit version or "latest"?
4. **Git workflow:** Push directly to main or use feature branch?
