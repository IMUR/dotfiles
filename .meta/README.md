# .meta-template/ - Meta-Management Template

**Purpose:** Template for initializing `.meta/` directories in new repositories

**Status:** Pristine template (no generated files)

## Quick Start

```bash
# 1. Copy template to new repository
cp -r /path/to/colab-config/.meta-template /path/to/new-repo/.meta

# 2. Initialize
cd /path/to/new-repo
./.meta/initialize.sh cluster  # or node/service/library

# Done! You now have:
# - .meta/ with foundation, whitelists, ssot, deployment
# - Generated AGENTS.md at root
# - Generated structure.yaml at root
# - Generated .meta/file-index.json
# - Generated .meta/initialization-status.yaml
```

## What This Is

A **pristine template** for meta-management infrastructure. No generated files - only sources and tools.

**After initialization, generated files appear at `.meta/` root.**

## Structure

### Template (Before Initialization)

```
.meta-template/
├── foundation/              # Source content
│   ├── principles/         # First principles, derived principles
│   ├── standards/          # Document standards, alignment rules
│   ├── schemas/            # JSON schemas for validation
│   └── templates/          # Templates for generation
│
├── whitelists/             # Operational enforcement
│   ├── Auto-generation system
│   ├── Root whitelist
│   └── Validation scripts
│
├── ssot/                   # Infrastructure discovery
│   └── dns/               # DNS management (cluster only)
│
├── deployment/             # Node deployment (cluster only)
│
├── reference/              # Minimal (only NAMING-CLARITY.md)
│
└── initialize.sh           # Initialization script
```

### After Initialization

```
.meta/
├── foundation/             # (same - copied from template)
├── whitelists/             # (same - copied from template)
├── ssot/                   # (same - copied from template)
├── deployment/             # (same - copied from template)
├── reference/              # (same - copied from template)
│
├── file-index.json         # ← GENERATED
├── initialization-status.yaml  # ← GENERATED
└── (infrastructure-truth.yaml if cluster/node)  # ← GENERATED

And at repository root:
../AGENTS.md                # ← GENERATED
../structure.yaml           # ← GENERATED
```

## Key Differences from Old Template

### Consolidation

**foundation/** now contains:
- `principles/` - What is true
- `standards/` - How we maintain quality
- `schemas/` - What is valid
- `templates/` - How to create

**Rationale:** These are all foundational/source content that defines structure.

### Pristine Template

**Removed from template:**
- `.meta/reference/file-index.json` (generated during init)
- `.meta/reference/foundation-complete.md` (status file)
- `.meta/ssot/infrastructure-truth.yaml` (generated during init)
- All cache directories

**Added to template:**
- `initialize.sh` - Initialization workflow script

### Initialization as Workflow Step

**Old:** Copy template → manually edit files
**New:** Copy template → run initialize.sh → done

## Initialization Script

**`.meta/initialize.sh`** handles:

1. Set `META-TYPE.txt` (cluster/node/service/library)
2. Generate root files (AGENTS.md, structure.yaml)
3. Create file index at `.meta/file-index.json`
4. Run SSOT discovery (if cluster/node)
5. Create `.meta/initialization-status.yaml`

**Usage:**
```bash
./.meta/initialize.sh cluster    # For cluster repos
./.meta/initialize.sh node       # For node repos
./.meta/initialize.sh service    # For service repos
./.meta/initialize.sh            # Interactive (prompts)
```

## Generated Files Location

**At repository root:**
- `AGENTS.md` - AI operational boundaries
- `structure.yaml` - Machine-readable structure

**At .meta/ root:**
- `file-index.json` - Index of all meta files
- `initialization-status.yaml` - Initialization details
- `infrastructure-truth.yaml` - SSOT (cluster/node only)

**Why .meta/ root?**
These are outputs of the meta-management system, not source content.

## Customization After Init

1. **Review generated files:**
   - `AGENTS.md` - Customize operational boundaries
   - `structure.yaml` - Verify directory purposes

2. **Customize foundation:**
   - `.meta/foundation/principles/FIRST-PRINCIPLES.md`
   - `.meta/foundation/principles/DERIVED-PRINCIPLES.md`

3. **Configure whitelists:**
   - `.meta/whitelists/root-whitelist.yml`

4. **Remove cluster-specific content (if not cluster):**
   ```bash
   rm -rf .meta/ssot/dns .meta/deployment
   rm .meta/whitelists/NODE-META-WHITELIST.yml
   ```

## Repository Types

### Cluster
Keep everything. Configure DNS, node topology.

### Node
Remove: `deployment/`, `ssot/dns/`, `NODE-META-WHITELIST.yml`

### Service/Library
Remove: `ssot/`, `deployment/`
Keep: Core meta-management only

## Workflow

```
1. Copy .meta-template → new-repo/.meta
2. Run .meta/initialize.sh [type]
3. Review generated files
4. Customize foundation/principles/
5. Run .meta/whitelists/check-root-whitelist.sh
6. Commit
```

## Origin

**Source:** colab-config/.meta/
**Template Version:** 2.0
**Last Updated:** 2025-10-08
**Changes from 1.0:**
- Added foundation/ consolidation
- Removed generated files
- Added initialization workflow
- Generated files now at .meta/ root
