# Documentation Consolidation Plan
**Date:** 2025-10-22

## Current Problem
- 18 markdown files in root directory (way too many!)
- Lots of outdated, overlapping, and redundant content
- Hard to find what's current vs historical

## Proposed Structure

### 📁 KEEP IN ROOT (4 files only)
```
README.md           # Project overview and quick start
SYSTEM-STATE.md     # Current state, services, progress (NEW - CREATED)
CLAUDE.md           # Instructions for Claude Code instances
.gitignore          # (not markdown but essential)
```

### 📁 MOVE TO archives/ (14 files)
These are outdated, redundant, or historical:
```
archives/
├── MIGRATION-STATUS.md          # Replaced by SYSTEM-STATE.md
├── CURRENT-STATE-SUMMARY.md     # Replaced by SYSTEM-STATE.md
├── SERVICE-CONFIGURATION.md     # Replaced by SYSTEM-STATE.md
├── DOCUMENTATION-AUDIT-*.md     # One-time audit, not needed
├── MIGRATION_INVENTORY.md       # Historical snapshot
├── configuration-manifest.md    # Outdated
├── chezmoi-manifest.md         # Outdated (dotfiles are separate repo)
├── TOOLS-INSTALLED.md          # Now in SYSTEM-STATE.md
├── CLUSTER-NODE-AUDIT.md       # One-time audit
├── CLUSTER-MANAGEMENT-DISCUSSION.md  # Discussion doc
├── AGENTS.md                    # Unknown relevance
├── GEMINI.md                    # Unknown relevance
├── VALIDATION.md                # SSOT-specific, keep with tools/
└── docker-*.md files            # Move to docs/install/
```

### 📁 CREATE docs/install/ (3 files)
Keep installation guides separate but accessible:
```
docs/
└── install/
    ├── docker-infisical.md
    ├── docker-n8n.md
    └── docker-pihole.md
```

### 📁 SSOT Structure (Already Good!)
```
ssot/
├── state/          # YAML configs (services, domains, network, node)
├── schemas/        # Validation schemas
└── (README.md)     # How SSOT works
```

### 📁 tools/ (Already Good!)
Keep SSOT management scripts as-is.

---

## Migration Commands

```bash
# 1. Create directories
mkdir -p archives docs/install

# 2. Move outdated docs to archives
mv MIGRATION-STATUS.md CURRENT-STATE-SUMMARY.md SERVICE-CONFIGURATION.md archives/
mv DOCUMENTATION-AUDIT-*.md MIGRATION_INVENTORY.md configuration-manifest.md archives/
mv chezmoi-manifest.md TOOLS-INSTALLED.md CLUSTER-NODE-AUDIT.md archives/
mv CLUSTER-MANAGEMENT-DISCUSSION.md AGENTS.md GEMINI.md VALIDATION.md archives/

# 3. Move installation docs
mv docker-*.md docs/install/

# 4. Update README.md to point to new structure
# 5. Commit changes
git add -A
git commit -m "Consolidate documentation: 18 files → 3 core + organized subdirs"
```

---

## Why This Works

1. **Clarity**: Only 3 markdown files in root (README, SYSTEM-STATE, CLAUDE)
2. **Current**: SYSTEM-STATE.md is the single source of truth for "what's running"
3. **Organized**: Installation guides in docs/, old stuff in archives/
4. **SSOT-Ready**: State files in ssot/state/ ready for automation
5. **Findable**: Everything has a clear home

---

## SSOT State Files Need Updates

The `ssot/state/` files don't match reality:
- Missing Infisical service
- Missing Cockpit
- Some services marked enabled that aren't installed
- Need to add actual configs

But the STRUCTURE is good - just needs content updates.