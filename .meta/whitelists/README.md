# Whitelists - Structure Enforcement

**Purpose:** Define what belongs where through explicit allowlists and auto-generation

## Files

### `root-whitelist.yml`

Defines allowed files/directories in repository root.

**Purpose:**
- Prevent root directory clutter
- Policy-driven file organization
- Auto-processing rules for common patterns

**Usage:**
```bash
# Check for violations
./.meta/whitelists/check-root-whitelist.sh

# Show suggested destinations
./.meta/whitelists/check-root-whitelist.sh --suggest

# Auto-fix violations
./.meta/whitelists/check-root-whitelist.sh --fix
```

### `NODE-META-WHITELIST.yml`

Template for node-level .meta/ directory structure.

**Purpose:**
- Define allowed node .meta/ structure
- Enforce minimal node-specific meta-management
- Deployed to all nodes via `deployment/DEPLOY-NODE-META.sh`

### `WHITELIST-COMPARISON.md`

Comparison of cluster and node whitelist patterns.

**Purpose:**
- Document whitelist philosophy
- Show similarity in pattern across scopes
- Explain deployment differences

### `check-root-whitelist.sh`

Validation script for root whitelist enforcement.

**Features:**
- Detects files not on whitelist
- Suggests destinations based on patterns
- Auto-moves files with --fix flag
- **Integrated meta-file detection** - checks for missing required meta files

**Usage:**
```bash
./check-root-whitelist.sh           # Check violations + missing meta files
./check-root-whitelist.sh --suggest # Show where files would move
./check-root-whitelist.sh --fix     # Auto-fix violations
```

### `generate-meta-files.sh`

**Auto-generates missing required meta files from templates.**

**Purpose:**
- Detect missing meta files (AGENTS.md, structure.yaml, .agent-context.json)
- Collect repository metadata automatically
- Generate files from templates
- Validate against schemas

**Usage:**
```bash
# Check for missing files
./.meta/whitelists/generate-meta-files.sh --check

# Generate specific file
./.meta/whitelists/generate-meta-files.sh --generate AGENTS.md

# Generate all missing files
./.meta/whitelists/generate-meta-files.sh --all

# Regenerate existing file
./.meta/whitelists/generate-meta-files.sh --regenerate structure.yaml

# Force regenerate everything
./.meta/whitelists/generate-meta-files.sh --force
```

## Auto-Generation System

### How It Works

1. **Detection:** `check-root-whitelist.sh` detects missing meta files
2. **Collection:** `generate-meta-files.sh` collects repository metadata
3. **Generation:** Populates templates with collected data
4. **Validation:** (Future) Validates against JSON schemas

### Required Meta Files

- **AGENTS.md** - AI agent operational boundaries
- **structure.yaml** - Machine-readable repository structure
- **.agent-context.json** - Root-level agent context (optional)

### Templates

Located in `.meta/templates/root-meta/`:
- `AGENTS.md.tmpl` - AI operational boundaries template
- `structure.yaml.tmpl` - Repository structure template
- `agent-context.json.tmpl` - Agent context template

### Schemas

Located in `.meta/schemas/`:
- `agents-md.schema.json` - AGENTS.md validation
- `structure-yaml.schema.json` - structure.yaml validation
- `agent-context.schema.json` - .agent-context.json validation

### Data Collection

The generator automatically collects:
- Repository name (from directory)
- Repository type (cluster-config, node-config, etc.)
- Repository purpose (from README.md)
- Directory listing and purposes
- Presence of key directories (dotfiles/, ansible/, services/)
- Current date/time for timestamps

## Integration

**Root whitelist checking** is integrated with **meta-file generation**:

```bash
# Single command checks both
./.meta/whitelists/check-root-whitelist.sh

# Output includes:
# 1. Whitelist violations (files not on allowlist)
# 2. Missing meta files (required files not present)
# 3. Suggested actions for both
```

## Philosophy

**Whitelists enforce intentionality:**

Every file must have a purpose, every directory must have a scope.

**Auto-generation provides remediation:**

Missing required files? Generate them from templates with collected data.

**Extension pattern:**

1. Define what's required (whitelist)
2. Detect what's missing (validation)
3. Generate what's needed (auto-remediation)
4. Validate what's created (schemas)

This pattern can be extended to other aspects of meta-management.
