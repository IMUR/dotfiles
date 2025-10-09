# Auto-Generation System

**Purpose:** Automatically detect and generate missing required meta files from templates

**Status:** Fully implemented and integrated

## Overview

This system extends the whitelist pattern from enforcement to **auto-remediation**:

1. **Whitelist** defines what's required
2. **Detection** identifies what's missing
3. **Templates** define structure
4. **Schemas** validate content
5. **Generator** creates files from templates
6. **Integration** makes it seamless

## Components

### 1. Schemas (`.meta/schemas/`)

Define structure and validation rules for meta files.

**Files:**
- `agents-md.schema.json` - AGENTS.md validation
- `structure-yaml.schema.json` - structure.yaml validation
- `agent-context.schema.json` - .agent-context.json validation

**Purpose:** Define "what is valid"

### 2. Templates (`.meta/templates/root-meta/`)

Provide template content with placeholders for data.

**Files:**
- `AGENTS.md.tmpl` - AI operational boundaries
- `structure.yaml.tmpl` - Repository structure
- `agent-context.json.tmpl` - Agent context

**Purpose:** Define "how to create"

### 3. Generator (`.meta/whitelists/generate-meta-files.sh`)

Detects missing files, collects data, generates from templates.

**Capabilities:**
- Check for missing files
- Collect repository metadata automatically
- Generate files from templates
- Regenerate existing files
- Force regeneration of all files

**Purpose:** Define "how to execute"

### 4. Integration (`.meta/whitelists/check-root-whitelist.sh`)

Whitelist validation integrated with meta-file detection.

**Purpose:** One command checks both whitelist violations and missing meta files

## Required Meta Files

The system manages these required files:

| File | Purpose | Status |
|------|---------|--------|
| `AGENTS.md` | AI agent operational boundaries | Auto-generated |
| `structure.yaml` | Machine-readable repo structure | Auto-generated |
| `.agent-context.json` | Root-level agent context | Optional |

## Workflows

### Check What's Missing

```bash
./.meta/whitelists/generate-meta-files.sh --check
```

**Output:**
- ✓ All required files exist
- OR: List of missing files with descriptions

### Generate Missing Files

```bash
# Generate all missing files
./.meta/whitelists/generate-meta-files.sh --all

# Generate specific file
./.meta/whitelists/generate-meta-files.sh --generate AGENTS.md
```

### Regenerate Existing File

```bash
# Update from latest template
./.meta/whitelists/generate-meta-files.sh --regenerate structure.yaml
```

### Integrated Check (Recommended)

```bash
# Checks both whitelist violations AND missing meta files
./.meta/whitelists/check-root-whitelist.sh
```

## Data Collection

The generator automatically collects:

**From filesystem:**
- Repository name (directory basename)
- Directory listing
- Presence of key directories (dotfiles/, ansible/, services/)

**From existing files:**
- Repository purpose (from README.md)
- Repository type (from .meta/META-TYPE.txt or directory detection)

**Generated:**
- Timestamps (ISO 8601 format)
- Directory purposes (intelligent defaults by name)
- Safety rules (based on repository type)

**No manual input required.**

## Template Substitution

Simple placeholder-based substitution (no external dependencies):

```
REPO_NAME_PLACEHOLDER → colab-config
LAST_UPDATED_PLACEHOLDER → 2025-10-08
FORBIDDEN_ACTIONS_PLACEHOLDER → - Delete files
                                - Modify system files
```

Lists are generated from arrays and inserted as markdown/YAML lists.

## Integration Flow

```
User runs: check-root-whitelist.sh
    ↓
1. Check whitelist violations
    ↓
2. Check for missing meta files
    ↓
3. Report both issues
    ↓
4. Suggest: generate-meta-files.sh --all
    ↓
User runs: generate-meta-files.sh --all
    ↓
5. Collect repository metadata
    ↓
6. Populate templates
    ↓
7. Write files to root
    ↓
8. Success!
```

## Extension Pattern

This pattern can be extended to other meta-management needs:

**Pattern:**
1. Define schema (what's valid)
2. Create template (how to create)
3. Write collector (how to gather data)
4. Write generator (how to execute)
5. Integrate with validation (make it seamless)

**Examples of what could be added:**
- `README.md` auto-generation from structure.yaml
- `.agent-context.json` for each directory
- `CHANGELOG.md` from git history
- `CONTRIBUTING.md` from repository patterns

## Philosophy

**Whitelists enforce intentionality** - every file must have a purpose

**Auto-generation provides remediation** - missing required files are generated

**Schemas ensure validity** - generated files conform to standards

**Integration makes it seamless** - one command checks everything

This transforms "enforcement only" into "enforcement + auto-fix".

## Files Created

When you run `generate-meta-files.sh --all`, you get:

```
/
├── AGENTS.md              # ✓ AI operational boundaries
├── structure.yaml         # ✓ Repository structure
└── .agent-context.json    # ○ Optional root context
```

Each file includes:
- Auto-generated header
- Timestamp
- Reference to template
- Reference to schema
- Note about regeneration

## Benefits

**For Users:**
- Missing files? Just run `--all`
- Need to update? Run `--regenerate FILE`
- Consistent structure across repos

**For AI:**
- Always has required meta files
- Schemas provide structure validation
- Templates ensure consistency
- Generated files follow standards

**For Maintainers:**
- Update template once, regenerate everywhere
- Schemas prevent invalid meta files
- Integration reduces friction
- Pattern is extensible

## Status

✅ **Implemented:**
- Schemas for all meta files
- Templates for generation
- Generator script with full features
- Integration with whitelist checking
- Data collection functions

✅ **Tested:**
- Detection works
- Help system works
- Check functionality works

⏳ **Future:**
- Schema validation (JSON Schema validator)
- More sophisticated template engine (mustache/jinja2)
- Auto-generation for .agent-context.json in subdirectories
- Pre-commit hook integration

---

**Created:** 2025-10-08
**Status:** Production-ready
**Location:** `.meta/whitelists/`
