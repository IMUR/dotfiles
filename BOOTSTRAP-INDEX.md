# Bootstrap Documentation Index

**Purpose**: Guide for deploying fresh Raspberry Pi OS using `.stems/` methodology

**Created**: 2025-10-13
**Status**: Ready for use

---

## Quick Navigation

**New to bootstrap?** → Read `docs/BOOTSTRAP-QUICK-START.md` (10 minutes)

**Need complete workflow?** → Read `docs/BOOTSTRAP-WORKFLOW.md` (45 minutes)

**Ready to deploy?** → Run `scripts/bootstrap/bootstrap-validate.sh`

**Understanding methodology?** → Read `docs/STEMS-TO-PRACTICE.md` (30 minutes)

---

## Document Hierarchy

```
BOOTSTRAP-INDEX.md (you are here)
│
├── docs/BOOTSTRAP-QUICK-START.md          ← START HERE
│   └── Quick command reference, common issues, 15-min guide
│
├── docs/BOOTSTRAP-WORKFLOW.md             ← COMPLETE GUIDE
│   ├── Part 1: .stems/ principles applied
│   ├── Part 2: Multi-stage validation
│   ├── Part 3: Incremental deployment
│   ├── Part 4: Rollback strategies
│   ├── Part 5: Tool boundaries
│   ├── Part 6: Safety gates
│   └── Part 7: Post-bootstrap operations
│
├── docs/STEMS-TO-PRACTICE.md              ← METHODOLOGY BRIDGE
│   └── Maps .stems/ patterns → bootstrap implementation
│
├── scripts/bootstrap/README.md            ← SCRIPT REFERENCE
│   └── All scripts explained, usage, troubleshooting
│
└── .stems/                                ← SOURCE METHODOLOGY
    ├── METHODOLOGY.md
    ├── LIFECYCLE.md
    ├── PRINCIPLES.md
    └── CLUSTER-PATTERNS.md
```

---

## Core Documents

### 1. BOOTSTRAP-QUICK-START.md

**What**: 15-minute practical guide for deploying fresh Pi OS
**Audience**: Operators ready to deploy
**Content**:
- Quick command reference
- Validation → Deploy → Verify workflow
- Common issues and fixes
- Emergency rollback procedure

**Read if**: You need to deploy NOW and want a quick reference.

**File**: `/home/crtr/Projects/crtr-config/docs/BOOTSTRAP-QUICK-START.md`

### 2. BOOTSTRAP-WORKFLOW.md

**What**: Complete 45-minute operational guide with detailed procedures
**Audience**: Operators and architects
**Content**:
- 7 comprehensive parts covering all aspects
- .stems/ principles applied to bootstrap
- Multi-stage validation pipeline
- Incremental deployment with checkpoints
- Rollback strategies
- Tool ownership boundaries
- Post-bootstrap operations

**Read if**: You need complete understanding of the bootstrap process.

**File**: `/home/crtr/Projects/crtr-config/docs/BOOTSTRAP-WORKFLOW.md`

### 3. STEMS-TO-PRACTICE.md

**What**: Bridge between .stems/ methodology and bootstrap implementation
**Audience**: Architects, methodology reviewers
**Content**:
- Pattern extraction from .stems/
- Mapping to bootstrap procedures
- Practical application examples
- Implementation checklist

**Read if**: You want to understand how .stems/ principles translate to practice.

**File**: `/home/crtr/Projects/crtr-config/docs/STEMS-TO-PRACTICE.md`

### 4. scripts/bootstrap/README.md

**What**: Complete script reference and usage guide
**Audience**: Script users and maintainers
**Content**:
- All bootstrap scripts explained
- Usage examples
- Safety features
- Troubleshooting
- Extension guide

**Read if**: You're using the bootstrap scripts or extending them.

**File**: `/home/crtr/Projects/crtr-config/scripts/bootstrap/README.md`

---

## Executable Scripts

### Validation Script

**File**: `scripts/bootstrap/bootstrap-validate.sh`
**Purpose**: Multi-stage validation pipeline (6 stages, non-destructive)
**Usage**: `./scripts/bootstrap/bootstrap-validate.sh [target]`
**Time**: 3-5 minutes
**Impact**: None (read-only checks)

**Stages**:
1. Syntax validation (YAML, Jinja2)
2. Config generation test
3. Target system pre-flight
4. Required commands check
5. Deployment simulation
6. Human approval gate

**Output**: Pass/fail, requires "yes" to proceed to deployment

### Deployment Script (Planned)

**File**: `scripts/bootstrap/bootstrap-deploy.sh` (to be created)
**Purpose**: Incremental deployment with checkpoints
**Usage**: `./scripts/bootstrap/bootstrap-deploy.sh [target]`
**Time**: 20-30 minutes
**Impact**: Writes to target system

**Phases**:
- Phase 1: Foundation (packages, users, network)
- Phase 2: Services (binaries, configs)
- Phase 3: Operations (startup, verification)

**Features**: Checkpoint tracking, human approval between phases

### Verification Script (Planned)

**File**: `scripts/bootstrap/verify-bootstrap.sh` (to be created)
**Purpose**: Post-deployment verification
**Usage**: `./scripts/bootstrap/verify-bootstrap.sh [target]`
**Time**: 2 minutes
**Impact**: None (read-only)

### Rollback Scripts (Planned)

**Files**:
- `scripts/bootstrap/rollback-to-sd.sh` - Emergency rollback to SD card
- `scripts/bootstrap/rollback-configs.sh` - Config-only rollback
- `scripts/bootstrap/rollback-service.sh` - Service-specific rollback

**Purpose**: Recovery from failed deployment
**Time**: 3-15 minutes depending on scenario

### Drift Detection Script (Planned)

**File**: `scripts/bootstrap/detect-drift.sh` (to be created)
**Purpose**: Detect configuration drift post-bootstrap
**Usage**: `./scripts/bootstrap/detect-drift.sh`
**Schedule**: Run daily via cron

---

## Source Methodology

### .stems/ Documents

Located in `.stems/` directory (root of repository):

**METHODOLOGY.md**:
- Core philosophy (5 pillars)
- Configuration lifecycle
- Implementation patterns
- Operational principles
- Used for: Validation-first, tool boundaries, safety gates

**LIFECYCLE.md**:
- Lifecycle stages (Planning → Retire)
- Stage activities and deliverables
- Deployment execution
- Used for: Bootstrap phase structure, checkpoint system

**PRINCIPLES.md**:
- First-order principles
- Derived principles
- Operational principles
- Decision framework
- Used for: Idempotency, fail-fast, tool ownership

**CLUSTER-PATTERNS.md**:
- 3-node topology patterns
- Service placement
- Configuration distribution
- Validation pipeline
- Used for: Multi-stage validation, node-specific config

---

## Workflow Overview

### Complete Bootstrap Sequence

```bash
# 1. Pre-Flight (Local)
cd ~/Projects/crtr-config
./.meta/validation/validate.sh              # Validate state files
./scripts/generate/regenerate-all.sh        # Generate configs
git diff config/                            # Review generated configs

# 2. Validation Pipeline (Local + Remote, Non-destructive)
./scripts/bootstrap/bootstrap-validate.sh   # 6-stage validation
# Prompts: "Proceed with bootstrap deployment? (type 'yes' to confirm):"

# 3. Deployment (Remote, Writes to System)
./scripts/bootstrap/bootstrap-deploy.sh     # Incremental deployment
# Phase 1: Foundation
# Prompt: "Continue to Phase 2? (y/n):"
# Phase 2: Services
# Prompt: "Continue to Phase 3? (y/n):"
# Phase 3: Operations

# 4. Verification (Post-Bootstrap)
./scripts/bootstrap/verify-bootstrap.sh     # Health checks

# 5. Ongoing Maintenance
./scripts/bootstrap/detect-drift.sh         # Daily via cron
```

**Total time**: 30-45 minutes
**Rollback time**: 5 minutes (emergency SD card rollback)
**Data loss**: None (all data on separate NVMe)

---

## Key Concepts

### Validation-First

From `.stems/METHODOLOGY.md`:
> Nothing touches production without validation

**Applied**:
- 6-stage validation pipeline
- All stages must pass before deployment
- Stages 1-5 are non-destructive
- Stage 6 requires human approval

### Multi-Stage Validation

**Stages**:
1. **Syntax**: YAML, Jinja2 validation (local)
2. **Generation**: Config build test (local)
3. **Pre-flight**: Target system check (remote, read-only)
4. **Commands**: Required binaries (remote, read-only)
5. **Simulation**: Package dry-run (remote, read-only)
6. **Approval**: Human decision (interactive)

### Incremental Deployment

**Phases**:
- **Phase 1: Foundation** - System packages, user accounts
- **Phase 2: Services** - Service binaries, configurations
- **Phase 3: Operations** - Service startup, verification

**Checkpoints**: Progress tracked at each sub-step (1.1, 1.2, ..., 3.4)

### Tool Boundaries

**Clear ownership**:
- **crtr-config** (schema-first): Owns `/etc/caddy/*`, `/etc/systemd/system/*`
- **Manual** (user space): Owns `/home/crtr/.bashrc`, `.ssh/config`
- **systemd/docker** (runtime): Owns `/run/systemd/*`, running processes

**No overlap**: Each file has exactly one owner.

### Idempotency

**All commands safe to run multiple times**:
```bash
sudo apt install -y package    # Skips if installed
sudo cp config.file /etc/      # Overwrites (safe)
id user || sudo useradd user   # Creates only if missing
```

### Fail Fast

**Scripts stop at first error**:
```bash
set -euo pipefail              # Exit on error
stage_1 || exit 1              # Stop if stage fails
```

### Human-in-Loop

**Approval gates**:
- Before any system changes (validation stage 6)
- Between deployment phases (phase transitions)
- Can abort at any checkpoint

### Rollback Capability

**Multiple strategies**:
- Emergency: Rollback to SD card (5 min)
- Config-only: Rollback configs (5 min)
- Service-specific: Rollback one service (3 min)

---

## Use Cases

### Case 1: Fresh Pi OS Installation

**Scenario**: New Raspberry Pi with fresh Pi OS, need to configure as cooperator gateway

**Workflow**:
1. Read `docs/BOOTSTRAP-QUICK-START.md`
2. Run `scripts/bootstrap/bootstrap-validate.sh`
3. Run `scripts/bootstrap/bootstrap-deploy.sh`
4. Run `scripts/bootstrap/verify-bootstrap.sh`

**Time**: 30-45 minutes
**Documentation**: All three quick start, workflow, and script README

### Case 2: Migration from Debian to Pi OS

**Scenario**: Existing Debian system on SD, migrating to Pi OS on USB

**Workflow**:
1. Read `docs/MIGRATION-PROCEDURE.md` (existing doc)
2. Use bootstrap scripts for USB system setup
3. Follow migration cutover procedure

**Time**: 1-2 hours (includes testing)
**Documentation**: MIGRATION-PROCEDURE.md + BOOTSTRAP-QUICK-START.md

### Case 3: Understanding Methodology

**Scenario**: Architect wants to understand how .stems/ principles apply

**Workflow**:
1. Read `.stems/METHODOLOGY.md` (source)
2. Read `docs/STEMS-TO-PRACTICE.md` (application)
3. Review `scripts/bootstrap/bootstrap-validate.sh` (implementation)

**Time**: 1 hour
**Documentation**: STEMS-TO-PRACTICE.md

### Case 4: Extending Bootstrap

**Scenario**: Need to add custom validation or deployment step

**Workflow**:
1. Read `scripts/bootstrap/README.md` (extension guide)
2. Study existing script structure
3. Add custom stage/checkpoint
4. Test with dry-run

**Time**: 1-2 hours
**Documentation**: scripts/bootstrap/README.md

---

## Status

### Completed

- ✓ Complete methodology extraction from .stems/
- ✓ Comprehensive workflow documentation (BOOTSTRAP-WORKFLOW.md)
- ✓ Quick start guide (BOOTSTRAP-QUICK-START.md)
- ✓ Methodology bridge (STEMS-TO-PRACTICE.md)
- ✓ Script documentation (scripts/bootstrap/README.md)
- ✓ Validation script (bootstrap-validate.sh)
- ✓ Index document (this file)

### Planned

- ⏳ Deployment script (bootstrap-deploy.sh)
- ⏳ Verification script (verify-bootstrap.sh)
- ⏳ Rollback scripts (rollback-*.sh)
- ⏳ Drift detection script (detect-drift.sh)
- ⏳ Testing on fresh Pi OS installation
- ⏳ Integration with existing migration procedure

---

## Quick Reference

### Essential Commands

```bash
# Validate before deploying
./scripts/bootstrap/bootstrap-validate.sh

# Deploy (when available)
./scripts/bootstrap/bootstrap-deploy.sh

# Verify deployment (when available)
./scripts/bootstrap/verify-bootstrap.sh

# Emergency rollback (when available)
./scripts/bootstrap/rollback-to-sd.sh

# Detect drift (when available)
./scripts/bootstrap/detect-drift.sh
```

### File Locations

| File | Purpose |
|------|---------|
| `docs/BOOTSTRAP-QUICK-START.md` | Quick reference guide |
| `docs/BOOTSTRAP-WORKFLOW.md` | Complete workflow guide |
| `docs/STEMS-TO-PRACTICE.md` | Methodology application |
| `scripts/bootstrap/README.md` | Script reference |
| `scripts/bootstrap/bootstrap-validate.sh` | Validation script |
| `.stems/METHODOLOGY.md` | Source methodology |

### Key Concepts

- **Validation-first**: No changes without validation
- **Multi-stage**: 6 stages, fail-fast
- **Incremental**: 3 phases, checkpoints
- **Idempotent**: Safe to retry
- **Human-in-loop**: Approval gates
- **Rollback**: Multiple strategies

---

## Getting Help

**Quick question?** → Read `docs/BOOTSTRAP-QUICK-START.md`

**Deep dive?** → Read `docs/BOOTSTRAP-WORKFLOW.md`

**Methodology?** → Read `docs/STEMS-TO-PRACTICE.md`

**Script usage?** → Read `scripts/bootstrap/README.md`

**Source?** → Read `.stems/METHODOLOGY.md` and related

---

## Related Documentation

### Existing Infrastructure

- `START-HERE.md` - Repository overview
- `CLAUDE.md` - AI operational guidance
- `docs/MIGRATION-PROCEDURE.md` - Debian → Pi OS migration
- `docs/MINIMAL-DOWNTIME-MIGRATION.md` - Detailed migration procedure

### Architecture

- `docs/architecture/ARCHITECTURE.md` - System design
- `docs/architecture/VISION.md` - Why schema-first
- `state/*.yml` - Source of truth (services, domains, network, node)

### Operations

- `COOPERATOR-ASPECTS.md` - Complete technical reference
- `scripts/generate/regenerate-all.sh` - Config generation
- `.meta/validation/validate.sh` - State validation

---

**This index provides complete navigation** through the bootstrap documentation ecosystem.

**Start with**: `docs/BOOTSTRAP-QUICK-START.md` for practical deployment.
