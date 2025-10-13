# Bootstrap Scripts

**Purpose**: Automated scripts for bootstrapping fresh Raspberry Pi OS installation on cooperator node

**Based on**: `.stems/` methodology - validation-first, human-in-loop, incremental deployment

---

## Scripts Overview

| Script | Purpose | Safety Level |
|--------|---------|--------------|
| `bootstrap-validate.sh` | Multi-stage validation pipeline | Non-destructive |
| `bootstrap-deploy.sh` | Incremental deployment with checkpoints | Writes to system |
| `verify-bootstrap.sh` | Post-deployment verification | Read-only |
| `rollback-to-sd.sh` | Emergency rollback to SD card | Recovery |
| `detect-drift.sh` | Configuration drift detection | Read-only |

---

## Usage

### 1. Validation (Safe - No System Changes)

```bash
# Validate state files, generate configs, check target system
./bootstrap-validate.sh [target]

# Default target: pi@192.168.254.10
./bootstrap-validate.sh

# Custom target:
./bootstrap-validate.sh pi@192.168.254.20
```

**Validation Stages**:
1. Syntax validation (YAML, Jinja2)
2. Config generation test
3. Target system pre-flight
4. Required commands check
5. Deployment simulation
6. Human approval gate

**Output**: Pass/fail for each stage, requires "yes" to proceed

### 2. Deployment (Writes to System)

```bash
# Deploy with checkpoints and human approval between phases
./bootstrap-deploy.sh [target]

# Phases:
#   Phase 1: Foundation (packages, users, network)
#   Phase 2: Services (binaries, configs)
#   Phase 3: Operations (startup, verification)
```

**Features**:
- Checkpoint tracking in `/tmp/bootstrap-checkpoints.txt`
- Human approval required between phases
- Idempotent commands (safe to retry)
- Fail-fast error handling

### 3. Verification (Post-Bootstrap)

```bash
# Check system health, services, connectivity
./verify-bootstrap.sh [target]
```

**Checks**:
- System uptime, disk, memory
- Service status (caddy, docker, nfs, pihole)
- DNS resolution
- HTTP/HTTPS connectivity
- Failed systemd units

### 4. Rollback (Emergency Recovery)

```bash
# Emergency rollback to SD card system
./rollback-to-sd.sh

# Config-only rollback
./rollback-configs.sh

# Service-specific rollback
./rollback-service.sh caddy
```

### 5. Drift Detection (Ongoing Maintenance)

```bash
# Detect config drift from state files
./detect-drift.sh
```

---

## Workflow Example

```bash
# Step 1: Validate everything before making changes
cd ~/Projects/crtr-config
./scripts/bootstrap/bootstrap-validate.sh

# Stages run automatically:
# ✓ Stage 1: Syntax validation
# ✓ Stage 2: Config generation
# ✓ Stage 3: Target system pre-flight
# ✓ Stage 4: Required commands
# ✓ Stage 5: Deployment simulation
# Prompt: "Proceed with bootstrap deployment? (type 'yes' to confirm):"

# Step 2: Deploy (if validation passed)
./scripts/bootstrap/bootstrap-deploy.sh

# Checkpoint: Phase 1 complete
# Prompt: "Continue to Phase 2? (y/n):"
# Checkpoint: Phase 2 complete
# Prompt: "Continue to Phase 3? (y/n):"

# Step 3: Verify deployment
./scripts/bootstrap/verify-bootstrap.sh

# Step 4: Monitor for drift
./scripts/bootstrap/detect-drift.sh
```

---

## Safety Features

### Validation-First (From .stems/METHODOLOGY.md)

**No system changes until all validation passes**:
- Syntax errors caught locally
- Config generation tested before deployment
- Target system verified before writes
- Human approval required before deployment

### Checkpoints (From .stems/LIFECYCLE.md)

**Progress tracked at each stage**:
```
Phase 1.1: System packages installed
Phase 1.2: User account created
Phase 1.3: Network configured
Phase 1.4: Storage mounted
Phase 2.1: Docker installed
Phase 2.2: Caddy installed
...
```

**Resume from last checkpoint** if script interrupted.

### Idempotency (From .stems/PRINCIPLES.md)

**All commands safe to run multiple times**:
```bash
# Safe to retry
sudo apt install -y package       # Skips if installed
sudo cp config.file /etc/          # Overwrites (config is source of truth)
id user || sudo useradd user       # Creates only if missing
```

### Fail Fast (From .stems/PRINCIPLES.md)

**Script stops at first error**:
```bash
set -euo pipefail

stage_1_syntax || exit 1
stage_2_generation || exit 1
stage_3_preflight || exit 1
```

### Human-in-Loop (From .stems/METHODOLOGY.md)

**Approval gates at critical points**:
- Before any system changes
- Between deployment phases
- Before service startup

---

## Error Handling

### Validation Failure

```
=== Validation Failed ===
Failed stages:
  - Stage 1: Syntax

Fix: Edit state/*.yml files, retry validation
Impact: None (no system changes)
```

### Deployment Failure

```
ERROR: Docker installation failed
Last checkpoint: Phase 1.4: Storage mounted

Options:
1. Fix issue and resume from Phase 2.1
2. Rollback to pre-deployment state
3. Exit and investigate
```

### Service Startup Failure

```
ERROR: Caddy service failed to start
Last checkpoint: Phase 2.4: Systemd units installed

Check: sudo journalctl -u caddy -n 50
Fix: Update config, redeploy
```

---

## Rollback Scenarios

| Scenario | Method | Time | Data Loss |
|----------|--------|------|-----------|
| Validation fails | None needed | 0 min | None |
| Phase 1 fails | Reinstall OS | 15 min | None |
| Phase 2 fails | Rollback configs | 5 min | None |
| Phase 3 fails | Fix and retry | 3 min | None |
| Complete failure | Rollback to SD | 5 min | None |

---

## Integration with crtr-config

### State-Driven

**Scripts read from**:
- `state/*.yml` - Source of truth
- `config/*` - Generated configs (from state)
- `.meta/validation/` - Schema validation

**Scripts write to**:
- Target system (`/etc/caddy/`, `/etc/systemd/system/`, etc.)
- Checkpoint file (`/tmp/bootstrap-checkpoints.txt`)
- Logs

### Tool Boundaries (From .stems/PRINCIPLES.md)

| Domain | Owner | Bootstrap Role |
|--------|-------|----------------|
| `state/*.yml` | crtr-config | Read (source of truth) |
| `config/*` | Generated | Read (deploy from here) |
| `/etc/caddy/*` | System | Write (deploy configs) |
| `/home/crtr/*` | User | Restore from backup |

**No overlap**: Each file has exactly one owner.

---

## Extending Bootstrap Scripts

### Add Custom Validation Stage

```bash
# In bootstrap-validate.sh

stage_7_custom() {
    echo "=== Stage 7: Custom Validation ==="

    # Your validation logic
    if custom_check; then
        log_success "Custom check passed"
        return 0
    else
        log_error "Custom check failed"
        return 1
    fi
}

# Add to main()
main() {
    stage_1_syntax || failed_stages+=("Stage 1")
    ...
    stage_7_custom || failed_stages+=("Stage 7: Custom")
}
```

### Add Custom Checkpoint

```bash
# In bootstrap-deploy.sh

checkpoint 2 5 "Installing custom package"
ssh "$TARGET" "sudo apt install -y custom-package"
verify_or_exit "ssh $TARGET 'command -v custom-binary'" \
    "Custom package installation failed"
```

---

## Troubleshooting

### SSH Connection Fails

```bash
# Check network
ping 192.168.254.10

# Check SSH service
ssh -v pi@192.168.254.10

# Check SSH keys
ssh-add -l
```

### Config Generation Fails

```bash
# Run manually to see errors
cd ~/Projects/crtr-config
./scripts/generate/regenerate-all.sh

# Check state files
./.meta/validation/validate.sh
```

### Service Won't Start

```bash
# Check service logs
ssh crtr@192.168.254.10 "sudo journalctl -u service-name -n 50"

# Verify config syntax
ssh crtr@192.168.254.10 "sudo caddy validate --config /etc/caddy/Caddyfile"

# Check dependencies
ssh crtr@192.168.254.10 "sudo systemctl list-dependencies service-name"
```

---

## Development

### Testing Locally

```bash
# Validate without deploying
./bootstrap-validate.sh

# Dry-run deployment (simulation only)
# Edit bootstrap-deploy.sh and add:
DRY_RUN=1 ./bootstrap-deploy.sh
```

### Adding New Scripts

1. Create script in `scripts/bootstrap/`
2. Make executable: `chmod +x script.sh`
3. Follow existing patterns (set -euo pipefail, checkpoint tracking)
4. Add to this README

---

## References

- **Methodology**: `../../.stems/METHODOLOGY.md`
- **Lifecycle**: `../../.stems/LIFECYCLE.md`
- **Principles**: `../../.stems/PRINCIPLES.md`
- **Workflow Guide**: `../../docs/BOOTSTRAP-WORKFLOW.md`
- **Migration Procedure**: `../../docs/MIGRATION-PROCEDURE.md`

---

**Questions?** See `../../docs/BOOTSTRAP-WORKFLOW.md` for detailed operational guide.
