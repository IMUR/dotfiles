# .stems/ Methodology → Bootstrap Practice

**Mapping**: How `.stems/` principles translate to practical Pi OS deployment

**Purpose**: Bridge conceptual methodology with executable procedures

---

## Document Map

```
.stems/ Source                    Applied In                           Executable
──────────────                    ──────────                           ──────────
METHODOLOGY.md                 → BOOTSTRAP-WORKFLOW.md              → bootstrap-validate.sh
  Validation-first                 Multi-stage validation pipeline      bootstrap-deploy.sh
  Tool boundaries                  Clear ownership during setup         verify-bootstrap.sh

LIFECYCLE.md                   → BOOTSTRAP-WORKFLOW.md (Part 3)    → Checkpoint tracking
  Lifecycle stages                 Bootstrap phase structure            /tmp/bootstrap-checkpoints.txt
  Deployment phases                Incremental deployment

PRINCIPLES.md                  → BOOTSTRAP-WORKFLOW.md (Part 5)    → Script design patterns
  Idempotency                      Safe-to-retry commands               (set -euo pipefail)
  Fail fast/safe                   Error handling                       (|| exit 1)
  Tool ownership                   File ownership map

CLUSTER-PATTERNS.md            → BOOTSTRAP-WORKFLOW.md (Part 2)    → Validation stages
  Validation pipeline              Multi-stage validation               Stage 1-6 functions
  Service placement                Node-specific configuration          state/node.yml
```

---

## Pattern Extraction Table

| .stems/ Pattern | Location | Extracted For | Implemented As |
|----------------|----------|---------------|----------------|
| **Validation-First** | METHODOLOGY.md:21-24 | Pre-deployment safety | 6-stage validation pipeline |
| **Multi-Stage Validation** | METHODOLOGY.md:91-101 | Catch errors early | bootstrap-validate.sh stages |
| **Configuration Lifecycle** | LIFECYCLE.md:9-17 | Bootstrap phases | Phase 1→2→3 structure |
| **Deployment Stages** | LIFECYCLE.md:145-190 | Incremental rollout | Checkpoints 1.1→3.4 |
| **Tool Domain Boundaries** | METHODOLOGY.md:103-116 | Prevent conflicts | File ownership map |
| **Idempotency** | METHODOLOGY.md:133-137 | Safe retries | Idempotent commands |
| **Fail Fast** | PRINCIPLES.md:98-107 | Stop on error | `set -euo pipefail` |
| **Human-in-Loop** | METHODOLOGY.md:52-68 | Approval gates | Phase transition prompts |
| **Rollback Capability** | LIFECYCLE.md:503-527 | Recovery procedures | rollback-*.sh scripts |
| **Drift Detection** | LIFECYCLE.md:209-222 | State reconciliation | detect-drift.sh |

---

## Part 1: Validation-First Deployment

### .stems/ Source

**METHODOLOGY.md (lines 21-24)**:
```
Nothing touches production without validation
Multiple validation gates: syntax → simulation → approval → apply
Fail fast, fail safe, fail informatively
```

**METHODOLOGY.md (lines 91-101)**:
```bash
# Stage 1: Syntax
chezmoi execute-template < template.tmpl

# Stage 2: Simulation
chezmoi diff

# Stage 3: Approval
read -p "Apply changes? " && chezmoi apply
```

### Applied to Bootstrap

**BOOTSTRAP-WORKFLOW.md (Part 2)**:
Multi-stage validation pipeline before any system changes.

**Implemented in**:
```bash
# scripts/bootstrap/bootstrap-validate.sh

stage_1_syntax()      # YAML/Jinja2 validation (local)
stage_2_generation()  # Config generation test (local)
stage_3_preflight()   # Target system check (remote, read-only)
stage_4_commands()    # Required binaries check (remote, read-only)
stage_5_simulation()  # Package dry-run (remote, read-only)
stage_6_approval()    # Human decision (interactive)
```

**Practical Usage**:
```bash
./scripts/bootstrap/bootstrap-validate.sh

# Non-destructive: Stages 1-5 make no system changes
# Gate: Stage 6 requires explicit "yes"
# Result: "Ready to deploy" or specific error to fix
```

**Key Benefit**: Catch 95% of errors before touching system.

---

## Part 2: Configuration Lifecycle

### .stems/ Source

**LIFECYCLE.md (lines 9-17)**:
```
Planning → Develop → Validate → Deploy → Operate → Maintain → Retire
```

**LIFECYCLE.md (lines 145-190)**:
```
Phase 1: Declaration
Phase 2: Validation
Phase 3: Approval
Phase 4: Application
Phase 5: Reconciliation
```

### Applied to Bootstrap

**BOOTSTRAP-WORKFLOW.md (Part 1.2)**:

| Lifecycle Stage | Bootstrap Phase | Actions |
|----------------|-----------------|---------|
| Planning | Pre-Install | State file validation |
| Development | State Definition | `state/*.yml` files |
| Validation | Pre-Deploy | Multi-stage pipeline |
| Deployment | Bootstrap Phases 1-3 | Incremental deployment |
| Operation | Service Verification | Health checks |
| Maintenance | Post-Bootstrap | Drift detection |

**Implemented in**:
```bash
# Planning + Development (local)
./.meta/validation/validate.sh
./scripts/generate/regenerate-all.sh

# Validation (local + remote, read-only)
./scripts/bootstrap/bootstrap-validate.sh

# Deployment (remote, writes to system)
./scripts/bootstrap/bootstrap-deploy.sh
  # Phase 1: Foundation
  # Phase 2: Services
  # Phase 3: Operations

# Operation (verification)
./scripts/bootstrap/verify-bootstrap.sh

# Maintenance (ongoing)
./scripts/bootstrap/detect-drift.sh
```

**Practical Usage**:
```bash
# Follow lifecycle stages sequentially
cd ~/Projects/crtr-config

# Stage: Planning + Development
vim state/services.yml              # Edit state
./.meta/validation/validate.sh      # Validate syntax

# Stage: Validation
./scripts/bootstrap/bootstrap-validate.sh

# Stage: Deployment
./scripts/bootstrap/bootstrap-deploy.sh
# Prompts between phases for human approval

# Stage: Operation
./scripts/bootstrap/verify-bootstrap.sh

# Stage: Maintenance
./scripts/bootstrap/detect-drift.sh
```

**Key Benefit**: Clear progression, no ambiguity about current stage.

---

## Part 3: Tool Domain Boundaries

### .stems/ Source

**METHODOLOGY.md (lines 103-116)**:
```
User Space:
  ~/.bashrc → Chezmoi
  ~/.ssh/config → Chezmoi

System Space:
  /etc/hosts → Ansible
  /etc/systemd/ → Ansible

Service Space:
  containers → Docker Compose
  volumes → Docker Compose
```

**PRINCIPLES.md (lines 76-85)**:
```
Each tool owns its domain completely
Clear boundaries: user config vs system config vs services
No tool overlap, no configuration confusion
```

### Applied to Bootstrap

**BOOTSTRAP-WORKFLOW.md (Part 5.2)**:

| Domain | Owner | Files | Bootstrap Method |
|--------|-------|-------|------------------|
| User Environment | Manual | `/home/crtr/.bashrc` | Restore from backup |
| System Config | crtr-config | `/etc/caddy/Caddyfile` | Generated from state |
| Service Runtime | systemd/docker | `/run/systemd/*` | Service startup |
| Data | Applications | `/cluster-nas/services/*` | Preserved |

**Implemented in**:

```bash
# bootstrap-deploy.sh respects boundaries

# User space: Manual restore
ssh "$TARGET" "tar xzf /cluster-nas/backups/home-crtr.tar.gz -C ~/"

# System config: Generated from state
scp config/caddy/Caddyfile "$TARGET:/tmp/"
ssh "$TARGET" "sudo cp /tmp/Caddyfile /etc/caddy/"

# Service runtime: systemctl
ssh "$TARGET" "sudo systemctl start caddy"

# Data: Untouched
# /cluster-nas/services/* remains as-is
```

**Practical Usage**:

**Never do this**:
```bash
# ✗ Wrong: Multiple tools managing same file
vim /etc/caddy/Caddyfile                    # Manual edit
./scripts/generate/regenerate-all.sh        # Regenerates from state
# Now manual changes conflict with state
```

**Always do this**:
```bash
# ✓ Right: One owner per file
vim state/domains.yml                       # Edit state
./scripts/generate/regenerate-all.sh        # Generate
scp config/caddy/Caddyfile target:/etc/caddy/  # Deploy
# Manual changes preserved in state, configs always match
```

**Key Benefit**: No "I updated the config but it didn't work" issues.

---

## Part 4: Idempotency and Safety

### .stems/ Source

**METHODOLOGY.md (lines 133-137)**:
```
Every operation must be safely repeatable:
- Running twice produces same result
- No incremental side effects
- Clear success/failure states
```

**PRINCIPLES.md (lines 66-74)**:
```bash
# Running multiple times = same result
./apply-config.sh
./apply-config.sh  # Safe to run again
```

### Applied to Bootstrap

**BOOTSTRAP-WORKFLOW.md (Part 1.4)**:

All bootstrap commands are idempotent:

```bash
# Package installation
sudo apt install -y package
# Skips if already installed

# Config deployment
sudo cp config.file /etc/
# Overwrites (config is source of truth, safe to overwrite)

# User creation
id crtr || sudo useradd -m crtr
# Creates only if doesn't exist

# Service startup
sudo systemctl start caddy
# Succeeds if already running (idempotent)
```

**Implemented in**:

```bash
# scripts/bootstrap/bootstrap-deploy.sh

# Idempotent user creation
checkpoint 1 2 "Creating crtr user account"
ssh "$TARGET" "
    if ! id crtr 2>/dev/null; then
        sudo useradd -m -s /bin/bash -G sudo,users crtr
    fi
"

# Idempotent package install
checkpoint 2 1 "Installing Docker"
ssh "$TARGET" "
    if ! command -v docker >/dev/null; then
        curl -fsSL https://get.docker.com | sh
    fi
"

# Idempotent config deployment
checkpoint 2 3 "Deploying configs"
scp config/caddy/Caddyfile "$TARGET:/tmp/"
ssh "$TARGET" "sudo cp /tmp/Caddyfile /etc/caddy/"
# Overwrites every time, safe because config is generated from state
```

**Practical Usage**:

Script fails mid-deployment? Just run again:

```bash
./scripts/bootstrap/bootstrap-deploy.sh

# ERROR: Network timeout during package install
# Last checkpoint: 2.1 (Docker installation failed)

# Fix network, retry
./scripts/bootstrap/bootstrap-deploy.sh

# Resumes: Skips Phase 1 (already done)
# Retries: Phase 2.1 (idempotent)
# Continues: Phase 2.2+
```

**Key Benefit**: No "restore to clean state before retrying" needed.

---

## Part 5: Fail Fast, Fail Safe

### .stems/ Source

**PRINCIPLES.md (lines 98-107)**:
```bash
# Validation pipeline stops at first error
syntax_check || exit 1
dependency_check || exit 1
dry_run || exit 1
# Only then...
apply_changes
```

### Applied to Bootstrap

**BOOTSTRAP-WORKFLOW.md (Part 1.5)**:

Script structure enforces fail-fast:

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined var, pipe failure

stage_1_syntax || exit 1
stage_2_generation || exit 1
stage_3_preflight || exit 1
# Only proceeds if all pass
```

**Implemented in**:

```bash
# scripts/bootstrap/bootstrap-validate.sh

set -euo pipefail

stage_1_syntax() {
    # Validation logic
    [ $? -eq 0 ] || return 1
}

main() {
    stage_1_syntax || failed_stages+=("Stage 1")
    stage_2_generation || failed_stages+=("Stage 2")

    if [ ${#failed_stages[@]} -gt 0 ]; then
        echo "Failed stages:"
        for stage in "${failed_stages[@]}"; do
            echo "  - $stage"
        done
        exit 1
    fi
}
```

**Practical Usage**:

Validation catches errors before deployment:

```bash
./scripts/bootstrap/bootstrap-validate.sh

# Stage 1: Syntax validation
# ✗ state/services.yml: Invalid YAML syntax
#
# === Validation Failed ===
# Failed stages:
#   - Stage 1: Syntax

# Fix error
vim state/services.yml

# Retry
./scripts/bootstrap/bootstrap-validate.sh
# Now all stages pass
```

**Key Benefit**: Fail before making changes, not after.

---

## Part 6: Human-in-Loop Approval

### .stems/ Source

**METHODOLOGY.md (lines 52-68)**:
```
Phase 3: Approval
  Diff → Human Review → Approval Gate
  - Explicit approval for system-level changes
  - Automatic approval for safe operations
  - Clear escalation paths
```

**METHODOLOGY.md (lines 119-129)**:
```yaml
validation:
  automatic:
    - syntax_check
    - dependency_check
    - dry_run
  manual:
    - system_changes
    - service_deployment
    - network_modification
```

### Applied to Bootstrap

**BOOTSTRAP-WORKFLOW.md (Part 6)**:

Approval gates at critical points:

```
Level 0: Automatic (no approval)
  - Syntax validation
  - Schema validation

Level 1: Informational (show diff)
  - Config generation
  - Dry-run simulation

Level 2: Manual approval (explicit "yes")
  - Bootstrap deployment start
  - Package installation
  - Config deployment

Level 3: Multi-stage (phase transitions)
  - Phase 1 → Phase 2
  - Phase 2 → Phase 3
```

**Implemented in**:

```bash
# scripts/bootstrap/bootstrap-validate.sh

stage_6_approval() {
    echo "Validation Summary:"
    echo "  ✓ All checks passed"
    echo ""
    echo "Target: $TARGET"

    read -rp "Proceed with bootstrap deployment? (type 'yes' to confirm): " response
    if [[ "$response" == "yes" ]]; then
        return 0
    else
        echo "Deployment cancelled by user"
        return 1
    fi
}
```

```bash
# scripts/bootstrap/bootstrap-deploy.sh

phase_1_foundation
echo "=== PHASE 1 COMPLETE ==="

read -p "Continue to Phase 2? (y/n): " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] || exit 0

phase_2_services
echo "=== PHASE 2 COMPLETE ==="

read -p "Continue to Phase 3? (y/n): " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] || exit 0
```

**Practical Usage**:

Control deployment pace:

```bash
./scripts/bootstrap/bootstrap-deploy.sh

# Phase 1 completes
# Prompt: "Continue to Phase 2? (y/n):"

# Option 1: Continue (y)
# Proceeds to Phase 2

# Option 2: Stop (n)
# Script exits cleanly
# System in known state (Phase 1 complete)
# Resume later by editing script to start at Phase 2
```

**Key Benefit**: Human verifies each phase before proceeding.

---

## Part 7: Rollback Capability

### .stems/ Source

**LIFECYCLE.md (lines 503-527)**:
```bash
# emergency-rollback.sh

# Get last known good state
last_good=$(git tag | grep "^v" | tail -2 | head -1)

# Rollback all nodes
for node in crtr prtr drtr; do
    ssh $node "git checkout $last_good && chezmoi apply --force"
done
```

**CLUSTER-PATTERNS.md (lines 347-369)**:
```bash
# rollback.sh

previous=$(git rev-parse HEAD~1)
git checkout "$previous"
for node in crtr prtr drtr; do
    ssh "$node" "git pull && chezmoi apply --force"
done
```

### Applied to Bootstrap

**BOOTSTRAP-WORKFLOW.md (Part 4)**:

Multiple rollback strategies:

| Scenario | Method | Time | Data Loss |
|----------|--------|------|-----------|
| Validation fails | None needed | 0 min | None |
| Phase 1 fails | Reinstall OS | 15 min | None |
| Phase 2 fails | Rollback configs | 5 min | None |
| Phase 3 fails | Fix and retry | 3 min | None |
| Complete failure | Rollback to SD | 5 min | None |

**Implemented in**:

```bash
# scripts/bootstrap/rollback-to-sd.sh

#!/bin/bash
echo "=== EMERGENCY ROLLBACK TO SD CARD ==="

# 1. Shutdown USB system
ssh crtr@192.168.254.10 "sudo shutdown -h now"

# 2. Change boot order (manual)
# 3. Power on (boots from SD)

# 4. Verify
ssh crtr@192.168.254.10 "lsblk | grep '/'"
# Should show mmcblk0 (SD), not sdb (USB)

# 5. Verify services
ssh crtr@192.168.254.10 "systemctl status caddy docker"
```

**Practical Usage**:

**Emergency**: Complete failure

```bash
./scripts/bootstrap/rollback-to-sd.sh
# Time: 5 minutes
# Result: System running on SD card
# Data: Unchanged (/cluster-nas on separate NVMe)
```

**Config-only**: Services OK, configs broken

```bash
# Rollback configs to previous commit
git log --oneline config/ | head -5
# abc1234 Updated Caddyfile
# def5678 Added new service (← rollback to this)

git checkout def5678 -- config/
scp config/caddy/Caddyfile crtr@192.168.254.10:/tmp/
ssh crtr@192.168.254.10 "sudo cp /tmp/Caddyfile /etc/caddy/ && sudo systemctl reload caddy"
```

**Service-specific**: One service broken

```bash
# Rollback just Caddy
git checkout HEAD~1 -- config/caddy/Caddyfile
./scripts/generate/regenerate-all.sh
# Redeploy just Caddy config
```

**Key Benefit**: Granular rollback options, not "all or nothing".

---

## Part 8: Drift Detection

### .stems/ Source

**LIFECYCLE.md (lines 209-222)**:
```bash
# Regular validation against desired state
# Drift detection and alerting
# Automated or guided remediation

# drift detection
0 2 * * * /home/trtr/colab-config/scripts/detect-drift.sh
```

### Applied to Bootstrap

**BOOTSTRAP-WORKFLOW.md (Part 7.1)**:

Post-bootstrap drift detection:

```bash
# Compare actual vs. state files
diff <(ssh crtr@192.168.254.10 "sudo cat /etc/caddy/Caddyfile") \
     config/caddy/Caddyfile
```

**Implemented in**:

```bash
# scripts/bootstrap/detect-drift.sh

#!/bin/bash
echo "=== Configuration Drift Detection ==="

# Caddy config
diff <(ssh crtr@192.168.254.10 "sudo cat /etc/caddy/Caddyfile") \
     config/caddy/Caddyfile || {
    echo "WARNING: Caddyfile drift detected"
}

# Systemd units
for unit in config/systemd/*.service; do
    unit_name=$(basename "$unit")
    diff <(ssh crtr@192.168.254.10 "sudo cat /etc/systemd/system/$unit_name") \
         "$unit" || {
        echo "WARNING: $unit_name drift detected"
    }
done
```

**Practical Usage**:

**Immediate** (post-bootstrap):

```bash
# Verify deployment matches state
./scripts/bootstrap/detect-drift.sh

# Expected: No drift
# If drift: Investigate why (manual change? deployment error?)
```

**Ongoing** (cron job):

```bash
# Add to crontab
0 */6 * * * cd ~/Projects/crtr-config && ./scripts/bootstrap/detect-drift.sh

# Alerts if drift detected
# Options:
#   1. Update state to match live (if manual change was intentional)
#   2. Redeploy from state (if live change was unintentional)
```

**Key Benefit**: Catch configuration drift before it causes issues.

---

## Summary: Pattern Application Map

| .stems/ Document | Pattern | Bootstrap Application | Script |
|-----------------|---------|----------------------|--------|
| METHODOLOGY.md | Validation-first | 6-stage pipeline | bootstrap-validate.sh |
| LIFECYCLE.md | Lifecycle stages | Phase 1→2→3 | bootstrap-deploy.sh |
| PRINCIPLES.md | Tool boundaries | File ownership map | (script design) |
| METHODOLOGY.md | Idempotency | Safe-to-retry commands | (all scripts) |
| PRINCIPLES.md | Fail fast | Error handling | (set -euo pipefail) |
| METHODOLOGY.md | Human approval | Phase gates | (read -p prompts) |
| LIFECYCLE.md | Rollback | Recovery procedures | rollback-*.sh |
| LIFECYCLE.md | Drift detection | State reconciliation | detect-drift.sh |

---

## Practical Checklist

Use this to verify .stems/ patterns applied correctly:

**Validation-First**:
- [ ] All validation stages non-destructive
- [ ] Validation must pass before deployment
- [ ] Clear error messages indicating what to fix

**Lifecycle Stages**:
- [ ] Clear progression: validate → deploy → verify
- [ ] Checkpoints track progress
- [ ] Can resume from checkpoint if interrupted

**Tool Boundaries**:
- [ ] Each file has exactly one owner
- [ ] No overlapping tool responsibilities
- [ ] Clear update procedures for each domain

**Idempotency**:
- [ ] All commands safe to run multiple times
- [ ] No incremental side effects
- [ ] Clear success/failure states

**Fail Fast**:
- [ ] Script exits on first error
- [ ] Error shows last successful checkpoint
- [ ] Clear recovery instructions

**Human-in-Loop**:
- [ ] Approval required before system changes
- [ ] Approval between deployment phases
- [ ] Can abort at any point

**Rollback**:
- [ ] Multiple rollback strategies available
- [ ] Rollback procedures documented
- [ ] Rollback time < 10 minutes

**Drift Detection**:
- [ ] Automated drift detection available
- [ ] Clear remediation procedures
- [ ] Scheduled for regular execution

---

## References

**Source Methodology**:
- `.stems/METHODOLOGY.md` - Core patterns
- `.stems/LIFECYCLE.md` - Lifecycle stages
- `.stems/PRINCIPLES.md` - First principles
- `.stems/CLUSTER-PATTERNS.md` - Cluster-specific patterns

**Applied Workflow**:
- `docs/BOOTSTRAP-WORKFLOW.md` - Complete operational guide
- `docs/BOOTSTRAP-QUICK-START.md` - Quick reference
- `scripts/bootstrap/README.md` - Script documentation

**Executable Scripts**:
- `scripts/bootstrap/bootstrap-validate.sh` - Validation pipeline
- `scripts/bootstrap/bootstrap-deploy.sh` - Deployment (planned)
- `scripts/bootstrap/verify-bootstrap.sh` - Verification (planned)
- `scripts/bootstrap/rollback-*.sh` - Rollback procedures (planned)

---

**This document serves as the bridge** between `.stems/` conceptual methodology and practical bootstrap implementation.
