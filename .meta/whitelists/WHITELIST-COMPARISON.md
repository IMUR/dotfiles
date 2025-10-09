# Whitelist Pattern Comparison

## Overview

Both cluster and node `.meta/` directories use whitelists to maintain clean, purposeful structure.

## Cluster Root Whitelist

**File:** `colab-config/.meta/root-whitelist.yml`

**Scope:** Repository root directory

**Purpose:** Prevent root directory clutter through policy-driven file organization

**Allowed Files:**
- Navigation docs (README.md, START-HERE.md, AGENTS.md, CLAUDE.md)
- Structure files (structure.yaml, .chezmoiroot, .gitignore)
- Root-required configs (docker-compose.yml, Makefile, etc.)
- Standard dotfiles (.editorconfig, .shellcheckrc, etc.)

**Allowed Directories:**
- dotfiles/ - User environment (Chezmoi)
- ansible/ - System automation
- services/ - Docker services
- scripts/ - Automation scripts
- docs/ - Documentation
- .meta/ - Meta-management
- .stems/, .sessions/, .specs/, .working/ - Special directories

**Auto-Processing Rules:**
- Session artifacts → `.sessions/`
- Specifications → `.specs/`
- Backups → `.sessions/backups/`
- Working/draft docs → `.working/`

## Node Meta Whitelist

**File:** `<user>-config/.meta/NODE-META-WHITELIST.yml`

**Scope:** Node-level .meta/ directory

**Purpose:** Define allowed structure for node-level meta-management

**Allowed Files:**
- META-TYPE.txt - Identifies as "node"
- NODE-PRINCIPLES.md - Node core principles
- NODE-README.md - Node .meta/ overview
- README.md - Detailed node documentation (legacy)

**Allowed Directories:**
- ssot/ - Node SSOT discovery (**ONLY non-meta-structural content**)
- ai/ - AI operational context (optional)
- schemas/ - Node-specific schemas (optional)
- generation/ - Config generation templates (optional)
- validation/ - Validation tools (optional)
- cache/ - Temporary files (gitignored)
- archive/ - Deprecated files

**Required Structure:**
- Must have: META-TYPE.txt, NODE-PRINCIPLES.md, NODE-README.md
- Must have: ssot/ directory with discovery script

**Prohibited:**
- *.bak, *.tmp, *.log files
- OS metadata (.DS_Store, thumbs.db)

## Key Differences

| Aspect | Cluster Root Whitelist | Node Meta Whitelist |
|--------|------------------------|---------------------|
| **Scope** | Entire repository root | Only .meta/ directory |
| **Complexity** | High - many categories | Low - focused on identity |
| **Auto-processing** | Yes - complex rules | No - simple structure |
| **Required items** | Many navigation/config files | 3 files + ssot/ directory |
| **Non-structural content** | Multiple directories | Only ssot/ |
| **Deployment** | Lives in cluster repo | Template deployed to nodes |

## Similarity in Pattern

Both whitelists follow the same philosophy:

1. **Explicit allowlist** - Define what's allowed, not what's forbidden
2. **Categorization** - Group files by purpose
3. **Documentation** - Explain why each item exists
4. **Enforcement** - Validation scripts check compliance
5. **Prevention** - Stop clutter before it accumulates

## Deployment

**Cluster Whitelist:**
- Location: `colab-config/.meta/root-whitelist.yml`
- Applies to: Cluster repository root
- Validation: `scripts/meta/check-root-whitelist.sh`

**Node Whitelist:**
- Template: `colab-config/.meta/NODE-META-WHITELIST.yml`
- Deployed to: Each node's `<user>-config/.meta/NODE-META-WHITELIST.yml`
- Validation: `.meta/validation/check-meta-whitelist.sh` (if exists)

## Philosophy

**The whitelist pattern enforces intentionality:**

- Every file must have a purpose
- Every directory must have a scope
- Clutter is addressed proactively, not reactively
- Structure serves function, not convention

This pattern scales from repository root to nested meta-management directories.
