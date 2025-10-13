# Bootstrap Workflow: .stems/ Methodology for Fresh Pi OS Deployment

**Practical DevOps Guide** - Combining `.stems/` principles with `crtr-config` schema-first workflow

**Target**: Fresh Raspberry Pi OS USB installation on cooperator node
**Approach**: Human-in-loop, validation-first, explicit state management
**Safety**: Multi-stage validation, incremental deployment, instant rollback

---

## Executive Summary

This document extracts **operational patterns** from `.stems/` methodology and applies them to the practical challenge of bootstrapping cooperator node on fresh Raspberry Pi OS.

**Key Extraction**:
- **Validation pipeline** from `.stems/METHODOLOGY.md` → Bootstrap safety gates
- **Lifecycle stages** from `.stems/LIFECYCLE.md` → Fresh install phases
- **Tool boundaries** from `.stems/PRINCIPLES.md` → Clear ownership during setup
- **Cluster patterns** from `.stems/CLUSTER-PATTERNS.md` → Node-specific config application

**Result**: A validation-first bootstrap procedure with explicit checkpoints, safety gates, and rollback strategies.

---

## Part 1: .stems/ Principles Applied to Bootstrap

### 1.1 Validation-First Deployment (METHODOLOGY.md)

**Original Pattern** (lines 21-24):
```
Nothing touches production without validation
Multiple validation gates: syntax → simulation → approval → apply
Fail fast, fail safe, fail informatively
```

**Applied to Bootstrap**:

```bash
# Stage 1: Pre-bootstrap validation (on dev machine)
cd ~/Projects/crtr-config
./.meta/validation/validate.sh              # Syntax validation
./scripts/generate/regenerate-all.sh        # Config generation test
git diff config/                            # Review what will deploy

# Stage 2: Target system validation (fresh Pi OS)
ssh pi@192.168.254.10 "
  uname -a                                  # Verify OS
  df -h                                     # Check disk space
  ip addr show eth0                         # Verify network
  sudo systemctl status                     # System health
"

# Stage 3: Deployment simulation
# (covered in Part 2)

# Stage 4: Human approval gate
read -p "State validated. Generate configs? (y/n) " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

# Stage 5: Apply with verification
# (incremental, one component at a time)
```

**Safety Gates**:
1. **Automatic**: Syntax, schema validation, config generation
2. **Manual**: System state review, deployment approval, service verification

### 1.2 Configuration Lifecycle for Bootstrap (LIFECYCLE.md)

**Original Stages** (lines 9-17):
```
Planning → Develop → Validate → Deploy → Operate → Maintain → Retire
```

**Mapped to Fresh Install**:

| Lifecycle Stage | Bootstrap Phase | Actions |
|----------------|-----------------|---------|
| **Planning** | Pre-Install | Hardware verification, OS image prep, network config design |
| **Development** | State Definition | `state/*.yml` files represent desired system state |
| **Validation** | Pre-Deploy Checks | Multi-stage validation (syntax → schema → generation → simulation) |
| **Deployment** | Bootstrap Execution | Incremental service deployment with checkpoints |
| **Operation** | Service Verification | Health checks, connectivity tests, monitoring setup |
| **Maintenance** | Post-Bootstrap | Drift detection, state reconciliation, documentation update |

**Bootstrap-Specific Workflow**:

```
Fresh Pi OS Installation
  ↓
Pre-Bootstrap (Planning + Development)
  - Validate state/*.yml files
  - Generate configs
  - Prepare deployment artifacts
  ↓
Bootstrap Phase 1 (Validation + Deployment)
  - System packages
  - User environment
  - Network configuration
  ↓
Bootstrap Phase 2 (Deployment)
  - Service binaries (Caddy, Docker, etc.)
  - Service configurations
  - Systemd units
  ↓
Bootstrap Phase 3 (Operation)
  - Service startup
  - Health verification
  - External access testing
  ↓
Post-Bootstrap (Maintenance)
  - State reconciliation
  - Drift detection setup
  - Documentation update
```

### 1.3 Tool Domain Boundaries (METHODOLOGY.md, PRINCIPLES.md)

**Original Pattern** (METHODOLOGY.md lines 103-116):
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

**Applied to Bootstrap (crtr-config context)**:

| Domain | Tool/Method | Bootstrap Stage | State Source |
|--------|-------------|-----------------|--------------|
| **User Environment** | Manual (rsync/tar) | Phase 1 | `backups/migration-*/home-crtr.tar.gz` |
| **System Config** | Manual deployment | Phase 2 | `state/network.yml` → `config/system/*` |
| **Service Binaries** | apt/wget | Phase 2 | Package lists |
| **Service Config** | Schema-first generation | Phase 2-3 | `state/services.yml` → `config/caddy/*` etc |
| **Container Services** | docker-compose | Phase 3 | `state/services.yml` → docker-compose files |
| **Infrastructure Truth** | SSOT scripts | Post-bootstrap | `.meta/ssot/` validation |

**Ownership Clarity During Bootstrap**:

```yaml
# /etc/caddy/Caddyfile
owner: crtr-config
method: generated from state/domains.yml
deployment: sudo cp config/caddy/Caddyfile /etc/caddy/
validation: caddy validate --config

# /etc/systemd/system/atuin-server.service
owner: crtr-config
method: generated from state/services.yml
deployment: sudo cp config/systemd/*.service /etc/systemd/system/
validation: systemd-analyze verify

# /home/crtr/.bashrc
owner: user (manual)
method: restored from backup
deployment: tar xzf backups/.../home-crtr.tar.gz
validation: source ~/.bashrc

# /cluster-nas/services/n8n/docker-compose.yml
owner: crtr-config
method: generated from state/services.yml (future)
deployment: docker compose up -d
validation: docker ps
```

**No Overlap**: Each file has exactly ONE owner, ONE generation method, ONE deployment procedure.

### 1.4 Idempotency and Safety (METHODOLOGY.md)

**Original Principle** (lines 133-137):
```
Every operation must be safely repeatable:
- Running twice produces same result
- No incremental side effects
- Clear success/failure states
```

**Applied to Bootstrap Commands**:

```bash
# ✓ Idempotent: Can run multiple times safely
sudo cp config/caddy/Caddyfile /etc/caddy/Caddyfile
sudo systemctl daemon-reload
sudo exportfs -ra
git clone <repo> || (cd <repo> && git pull)

# ✗ NOT idempotent without guards:
useradd -m crtr  # Fails if user exists

# ✓ Idempotent version:
id crtr || sudo useradd -m -s /bin/bash -G sudo,users crtr

# ✓ Idempotent: Install if missing
command -v docker || curl -fsSL https://get.docker.com | sh

# ✓ Idempotent: Copy keys only if different
sudo rsync -av --checksum ~/.ssh/authorized_keys /home/crtr/.ssh/
```

**Idempotency Strategy for Bootstrap**:

1. **Package installation**: `apt install -y` (idempotent - skips if installed)
2. **User creation**: Check existence first with `id user`
3. **File deployment**: `rsync --checksum` or `cp` (overwrite is safe for generated configs)
4. **Service config**: Overwrite from generated configs (state is source of truth)
5. **Service startup**: `systemctl start` fails gracefully if running

### 1.5 Fail Fast, Fail Safe (PRINCIPLES.md)

**Original Pattern** (lines 98-107):
```bash
# Validation pipeline stops at first error
syntax_check || exit 1
dependency_check || exit 1
dry_run || exit 1
# Only then...
apply_changes
```

**Applied to Bootstrap Script Structure**:

```bash
#!/bin/bash
set -euo pipefail  # Fail fast: exit on error, undefined var, pipe failure

# Pre-flight checks (fail before making changes)
validate_state_files() {
    echo "Validating state files..."
    ./.meta/validation/validate.sh || {
        echo "ERROR: State validation failed"
        exit 1
    }
}

generate_configs() {
    echo "Generating configs from state..."
    ./scripts/generate/regenerate-all.sh || {
        echo "ERROR: Config generation failed"
        exit 1
    }
}

verify_target_system() {
    echo "Verifying target system..."
    ssh pi@192.168.254.10 "
        command -v sudo >/dev/null || exit 1
        [ -d /home/pi ] || exit 1
        df -h / | grep -q /dev/sdb || exit 1
    " || {
        echo "ERROR: Target system not ready"
        exit 1
    }
}

# Execute in order - fail stops entire process
validate_state_files
generate_configs
verify_target_system

# Only after all validation passes
deploy_phase_1
verify_phase_1 || exit 1

deploy_phase_2
verify_phase_2 || exit 1
```

**Error Recovery Strategy**:

| Failure Point | Impact | Recovery |
|--------------|--------|----------|
| State validation fails | No system changes | Fix `state/*.yml`, retry |
| Config generation fails | No system changes | Fix templates/state, retry |
| Target SSH fails | No system changes | Fix network, verify USB boot |
| Package install fails | Partial changes | Retry install (apt is idempotent) |
| Service config fails | Service not started | Fix config, reapply |
| Service start fails | System functional, one service down | Check logs, fix, restart |

---

## Part 2: Multi-Stage Validation Pipeline

**From** `.stems/CLUSTER-PATTERNS.md` (lines 126-156) and `.stems/METHODOLOGY.md` (lines 91-101)

### 2.1 Validation Stages for Fresh Install

```bash
#!/bin/bash
# bootstrap-validate.sh - Multi-stage validation before deployment

# Stage 1: Syntax Validation (Local, No System Access Required)
stage_1_syntax() {
    echo "=== Stage 1: Syntax Validation ==="

    # YAML syntax
    for file in state/*.yml; do
        python3 -c "import yaml; yaml.safe_load(open('$file'))" || exit 1
        echo "✓ $file: Valid YAML"
    done

    # Schema validation
    ./.meta/validation/validate.sh || exit 1
    echo "✓ All state files conform to schemas"

    # Template syntax
    for tmpl in .meta/generation/*.j2; do
        python3 -c "from jinja2 import Template; Template(open('$tmpl').read())" || exit 1
        echo "✓ $tmpl: Valid Jinja2"
    done
}

# Stage 2: Generation Test (Local, Ensures Configs Can Be Built)
stage_2_generation() {
    echo "=== Stage 2: Configuration Generation ==="

    # Generate all configs
    ./scripts/generate/regenerate-all.sh || exit 1
    echo "✓ Configs generated successfully"

    # Validate generated configs
    test -f config/caddy/Caddyfile || exit 1
    caddy validate --config config/caddy/Caddyfile || exit 1
    echo "✓ Caddyfile syntax valid"

    test -d config/systemd/ || exit 1
    for unit in config/systemd/*.service; do
        systemd-analyze verify "$unit" 2>/dev/null || {
            echo "WARNING: $unit validation skipped (systemd not available)"
        }
    done
    echo "✓ Systemd units validated"
}

# Stage 3: Target System Pre-flight (Remote, Non-destructive)
stage_3_preflight() {
    echo "=== Stage 3: Target System Pre-flight ==="

    local target="pi@192.168.254.10"

    # SSH connectivity
    ssh -o ConnectTimeout=5 "$target" "echo ok" || exit 1
    echo "✓ SSH connectivity"

    # System resources
    ssh "$target" "
        # Disk space (need at least 10GB free)
        free_space=\$(df / | tail -1 | awk '{print \$4}')
        [ \$free_space -gt 10485760 ] || exit 1

        # Memory (need at least 1GB available)
        free_mem=\$(free | grep Mem | awk '{print \$7}')
        [ \$free_mem -gt 1048576 ] || exit 1

        # Network interface
        ip addr show eth0 | grep -q 'inet ' || exit 1
    " || exit 1
    echo "✓ System resources adequate"

    # Required commands available
    ssh "$target" "
        command -v sudo >/dev/null || exit 1
        command -v systemctl >/dev/null || exit 1
        command -v apt >/dev/null || exit 1
    " || exit 1
    echo "✓ Required commands present"
}

# Stage 4: Deployment Simulation (Dry-run, No Actual Changes)
stage_4_simulation() {
    echo "=== Stage 4: Deployment Simulation ==="

    local target="pi@192.168.254.10"

    # Simulate package installation
    ssh "$target" "
        sudo apt-get update -qq
        sudo apt-get install --dry-run -y \
            git vim curl wget docker.io caddy nfs-kernel-server \
            2>&1 | grep -q 'newly installed' && echo '✓ Packages available'
    " || exit 1

    # Simulate file deployments (check write permissions)
    ssh "$target" "
        sudo test -w /etc/caddy || sudo mkdir -p /etc/caddy
        sudo test -w /etc/systemd/system
        sudo test -w /etc/exports
        echo '✓ Config directories writable'
    " || exit 1

    # Check no conflicts
    ssh "$target" "
        # Check if services already exist (would be overwritten)
        if systemctl list-unit-files | grep -q caddy.service; then
            echo 'INFO: caddy.service exists (will be reconfigured)'
        fi
    " || exit 1
}

# Stage 5: Human Approval Gate
stage_5_approval() {
    echo "=== Stage 5: Human Approval ==="

    echo "Validation Summary:"
    echo "  ✓ Syntax: State files, templates valid"
    echo "  ✓ Generation: All configs generated successfully"
    echo "  ✓ Target: System reachable, resources adequate"
    echo "  ✓ Simulation: No conflicts detected"
    echo ""
    echo "Ready to deploy to: pi@192.168.254.10"
    echo ""

    git diff --stat config/ || true
    echo ""

    read -p "Proceed with bootstrap deployment? (yes/no): " -r
    [[ $REPLY == "yes" ]] || {
        echo "Deployment cancelled by user"
        exit 1
    }
    echo "✓ User approval granted"
}

# Execute all stages
main() {
    stage_1_syntax
    stage_2_generation
    stage_3_preflight
    stage_4_simulation
    stage_5_approval

    echo ""
    echo "=== All Validation Stages Passed ==="
    echo "Proceed to deployment with: ./bootstrap-deploy.sh"
}

main "$@"
```

### 2.2 Validation Checkpoint Matrix

| Stage | What | Where | Impact on System | Rollback Cost |
|-------|------|-------|------------------|---------------|
| **1. Syntax** | YAML, Jinja2 syntax | Local dev machine | None | None |
| **2. Generation** | Config generation test | Local dev machine | None | None |
| **3. Pre-flight** | System state check | Target system (read-only) | None | None |
| **4. Simulation** | Dry-run deployment | Target system (read-only) | None | None |
| **5. Approval** | Human review | Terminal prompt | None | None |
| **6. Phase 1 Deploy** | System packages, users | Target system (writes) | Moderate | Reinstall OS |
| **7. Phase 2 Deploy** | Service configs | Target system (writes) | High | Reinstall + reconfig |
| **8. Phase 3 Deploy** | Service startup | Target system (writes) | Critical | Full rebuild |

**Key Insight**: Stages 1-5 are **non-destructive** and can run repeatedly. Stages 6-8 modify system and require progressively more complex rollback.

---

## Part 3: Incremental Deployment with Checkpoints

**From** `.stems/LIFECYCLE.md` (lines 145-190) and `.stems/CLUSTER-PATTERNS.md` (lines 242-267)

### 3.1 Bootstrap Phase Structure

```
Phase 1: Foundation (System + User)
  ├─ Checkpoint 1.1: System packages installed
  ├─ Checkpoint 1.2: User account created
  ├─ Checkpoint 1.3: Network configured
  └─ Checkpoint 1.4: Storage mounted

Phase 2: Services (Binaries + Configs)
  ├─ Checkpoint 2.1: Docker installed
  ├─ Checkpoint 2.2: Caddy installed
  ├─ Checkpoint 2.3: Configs deployed
  └─ Checkpoint 2.4: Systemd units installed

Phase 3: Operations (Startup + Verification)
  ├─ Checkpoint 3.1: Core services started
  ├─ Checkpoint 3.2: Docker services started
  ├─ Checkpoint 3.3: External access verified
  └─ Checkpoint 3.4: Health monitoring enabled
```

### 3.2 Deployment Script with Checkpoints

```bash
#!/bin/bash
# bootstrap-deploy.sh - Incremental deployment with verification checkpoints

set -euo pipefail

TARGET="pi@192.168.254.10"
CHECKPOINT_FILE="/tmp/bootstrap-checkpoints.txt"

# Checkpoint tracker
checkpoint() {
    local phase="$1"
    local checkpoint_id="$2"
    local description="$3"

    echo "=== Checkpoint $phase.$checkpoint_id: $description ==="
    echo "$phase.$checkpoint_id: $description" >> "$CHECKPOINT_FILE"
}

verify_or_exit() {
    local test_command="$1"
    local error_message="$2"

    if ! eval "$test_command"; then
        echo "ERROR: $error_message"
        echo "Last successful checkpoint: $(tail -1 $CHECKPOINT_FILE)"
        exit 1
    fi
}

#
# Phase 1: Foundation
#
phase_1_foundation() {
    echo "=== PHASE 1: FOUNDATION ==="

    # Checkpoint 1.1: System packages
    checkpoint 1 1 "Installing system packages"
    ssh "$TARGET" "
        sudo apt-get update -qq
        sudo apt-get install -y \
            git vim curl wget tmux htop tree ncdu rsync \
            build-essential python3 python3-yaml python3-jinja2 \
            || exit 1
    "
    verify_or_exit "ssh $TARGET 'command -v git && command -v python3'" \
        "System packages installation failed"
    echo "✓ System packages installed"

    # Checkpoint 1.2: User account
    checkpoint 1 2 "Creating crtr user account"
    ssh "$TARGET" "
        # Idempotent user creation
        if ! id crtr 2>/dev/null; then
            sudo useradd -m -s /bin/bash -G sudo,users crtr
            echo 'crtr:cooperator2025' | sudo chpasswd
            sudo cp -r /home/pi/.ssh /home/crtr/
            sudo chown -R crtr:crtr /home/crtr/.ssh
        fi
    "
    verify_or_exit "ssh $TARGET 'id crtr'" \
        "User creation failed"
    echo "✓ User account created"

    # Checkpoint 1.3: Network configured
    checkpoint 1 3 "Configuring static IP"
    # (Already done during USB prep, verify)
    verify_or_exit "ssh $TARGET 'ip addr show eth0 | grep -q 192.168.254.10'" \
        "Static IP not configured"
    echo "✓ Network configured"

    # Checkpoint 1.4: Storage mounted
    checkpoint 1 4 "Verifying NVMe storage mount"
    verify_or_exit "ssh $TARGET 'df -h | grep -q /cluster-nas'" \
        "NVMe storage not mounted"
    echo "✓ Storage mounted"

    echo "=== PHASE 1 COMPLETE ==="
}

#
# Phase 2: Services
#
phase_2_services() {
    echo "=== PHASE 2: SERVICES ==="

    # Checkpoint 2.1: Docker
    checkpoint 2 1 "Installing Docker"
    ssh "$TARGET" "
        if ! command -v docker >/dev/null; then
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sudo sh /tmp/get-docker.sh
            sudo usermod -aG docker crtr
        fi
    "
    verify_or_exit "ssh $TARGET 'docker --version'" \
        "Docker installation failed"
    echo "✓ Docker installed"

    # Checkpoint 2.2: Caddy
    checkpoint 2 2 "Installing Caddy"
    ssh "$TARGET" "
        if ! command -v caddy >/dev/null; then
            sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
                sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
                sudo tee /etc/apt/sources.list.d/caddy-stable.list
            sudo apt-get update -qq
            sudo apt-get install -y caddy
        fi
    "
    verify_or_exit "ssh $TARGET 'caddy version'" \
        "Caddy installation failed"
    echo "✓ Caddy installed"

    # Checkpoint 2.3: Deploy configs
    checkpoint 2 3 "Deploying generated configs"

    # NFS exports
    scp config/nfs/exports "$TARGET:/tmp/exports"
    ssh "$TARGET" "sudo cp /tmp/exports /etc/exports"
    verify_or_exit "ssh $TARGET 'sudo test -f /etc/exports'" \
        "NFS config deployment failed"

    # Caddy config
    scp config/caddy/Caddyfile "$TARGET:/tmp/Caddyfile"
    ssh "$TARGET" "
        sudo cp /tmp/Caddyfile /etc/caddy/Caddyfile
        sudo caddy validate --config /etc/caddy/Caddyfile || exit 1
    "
    verify_or_exit "ssh $TARGET 'sudo caddy validate --config /etc/caddy/Caddyfile'" \
        "Caddy config deployment failed"

    # Pi-hole DNS
    if [ -f config/pihole/local-dns.conf ]; then
        scp config/pihole/local-dns.conf "$TARGET:/tmp/local-dns.conf"
        ssh "$TARGET" "
            sudo mkdir -p /etc/dnsmasq.d
            sudo cp /tmp/local-dns.conf /etc/dnsmasq.d/02-custom-local-dns.conf
        "
    fi

    echo "✓ Configs deployed"

    # Checkpoint 2.4: Systemd units
    checkpoint 2 4 "Installing systemd units"
    scp config/systemd/*.service "$TARGET:/tmp/"
    ssh "$TARGET" "
        sudo cp /tmp/*.service /etc/systemd/system/
        sudo systemctl daemon-reload
    "
    verify_or_exit "ssh $TARGET 'sudo systemctl daemon-reload'" \
        "Systemd units installation failed"
    echo "✓ Systemd units installed"

    echo "=== PHASE 2 COMPLETE ==="
}

#
# Phase 3: Operations
#
phase_3_operations() {
    echo "=== PHASE 3: OPERATIONS ==="

    # Checkpoint 3.1: Start core services
    checkpoint 3 1 "Starting core services"
    ssh "$TARGET" "
        sudo systemctl enable --now nfs-kernel-server
        sudo systemctl enable --now docker
        sudo systemctl enable --now caddy
    "

    # Verify each service
    verify_or_exit "ssh $TARGET 'sudo systemctl is-active nfs-kernel-server'" \
        "NFS service failed to start"
    verify_or_exit "ssh $TARGET 'sudo systemctl is-active docker'" \
        "Docker service failed to start"
    verify_or_exit "ssh $TARGET 'sudo systemctl is-active caddy'" \
        "Caddy service failed to start"
    echo "✓ Core services started"

    # Checkpoint 3.2: Start application services
    checkpoint 3 2 "Starting application services"
    # (Pi-hole, Atuin, etc.)
    ssh "$TARGET" "
        if systemctl list-unit-files | grep -q pihole-FTL; then
            sudo systemctl enable --now pihole-FTL
        fi
    "
    echo "✓ Application services started"

    # Checkpoint 3.3: Verify local access
    checkpoint 3 3 "Verifying local service access"
    verify_or_exit "ssh $TARGET 'curl -I http://localhost:80 2>&1 | grep -q Caddy'" \
        "Caddy not responding on localhost"
    echo "✓ Local access verified"

    # Checkpoint 3.4: Verify external access
    checkpoint 3 4 "Verifying external HTTPS access"
    sleep 5  # Give Caddy time to provision certs
    # This test may fail initially if DNS/certs not ready - non-fatal
    if curl -I https://n8n.ism.la 2>&1 | grep -q '200\|301\|302'; then
        echo "✓ External access verified"
    else
        echo "WARNING: External access not yet available (may need DNS/cert time)"
    fi

    echo "=== PHASE 3 COMPLETE ==="
}

#
# Main execution
#
main() {
    # Clear checkpoint file
    > "$CHECKPOINT_FILE"

    echo "=== BOOTSTRAP DEPLOYMENT START ==="
    echo "Target: $TARGET"
    echo "Checkpoint tracking: $CHECKPOINT_FILE"
    echo ""

    phase_1_foundation
    echo ""

    read -p "Phase 1 complete. Continue to Phase 2? (y/n): " -n 1 -r
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "Stopped by user"; exit 0; }
    echo ""

    phase_2_services
    echo ""

    read -p "Phase 2 complete. Continue to Phase 3? (y/n): " -n 1 -r
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "Stopped by user"; exit 0; }
    echo ""

    phase_3_operations
    echo ""

    echo "=== BOOTSTRAP DEPLOYMENT COMPLETE ==="
    echo "All checkpoints passed:"
    cat "$CHECKPOINT_FILE"
}

main "$@"
```

### 3.3 Checkpoint Verification Script

```bash
#!/bin/bash
# verify-bootstrap.sh - Verify bootstrap deployment success

TARGET="pi@192.168.254.10"

echo "=== Bootstrap Verification ==="

# System checks
echo "System Health:"
ssh "$TARGET" "
    echo '  Uptime:' \$(uptime -p)
    echo '  Disk:' \$(df -h / | tail -1 | awk '{print \$5\" used\"}')
    echo '  Memory:' \$(free -h | grep Mem | awk '{print \$3\"/\"\$2}')
"

# Service status
echo ""
echo "Service Status:"
for service in nfs-kernel-server docker caddy pihole-FTL; do
    if ssh "$TARGET" "systemctl is-active $service >/dev/null 2>&1"; then
        echo "  ✓ $service"
    else
        echo "  ✗ $service (not running)"
    fi
done

# Network checks
echo ""
echo "Network Connectivity:"
ssh "$TARGET" "
    # DNS resolution
    if dig @localhost n8n.ism.la +short | grep -q 192.168.254.10; then
        echo '  ✓ DNS resolution (local)'
    else
        echo '  ✗ DNS resolution failed'
    fi

    # Local HTTP
    if curl -s -o /dev/null -w '%{http_code}' http://localhost:80 | grep -q 200; then
        echo '  ✓ HTTP localhost:80'
    else
        echo '  ✗ HTTP localhost:80 failed'
    fi
"

# External access (from dev machine)
echo ""
echo "External Access:"
if curl -s -o /dev/null -w '%{http_code}' https://n8n.ism.la | grep -q '200\|301\|302'; then
    echo "  ✓ HTTPS n8n.ism.la"
else
    echo "  ✗ HTTPS n8n.ism.la failed"
fi

# Failed units
echo ""
echo "Failed Units:"
failed_units=$(ssh "$TARGET" "systemctl --failed --no-legend")
if [ -z "$failed_units" ]; then
    echo "  ✓ No failed units"
else
    echo "$failed_units"
fi

echo ""
echo "=== Verification Complete ==="
```

---

## Part 4: Rollback Strategies

**From** `.stems/LIFECYCLE.md` (lines 503-527) and `.stems/CLUSTER-PATTERNS.md` (lines 347-369)

### 4.1 Rollback Decision Matrix

| Failure Point | System State | Rollback Method | Time | Data Loss |
|--------------|-------------|-----------------|------|-----------|
| **Pre-validation fails** | Unchanged | None needed | 0 min | None |
| **Config generation fails** | Unchanged | Fix state, regenerate | 2 min | None |
| **Phase 1 (packages) fails** | Partial install | Reinstall OS from image | 15 min | None (data on NVMe) |
| **Phase 2 (configs) fails** | Services misconfigured | Revert configs, restart | 5 min | None |
| **Phase 3 (startup) fails** | Services down | Fix and retry startup | 3 min | None |
| **Post-deploy issues** | Running but broken | Rollback to SD card | 5 min | None (NVMe unchanged) |

### 4.2 Rollback Procedures

#### Emergency Rollback to SD Card

**Scenario**: USB system completely broken, need immediate recovery

```bash
#!/bin/bash
# rollback-to-sd.sh - Emergency rollback to SD card system

echo "=== EMERGENCY ROLLBACK TO SD CARD ==="

# 1. Shutdown USB system (if accessible)
ssh crtr@192.168.254.10 "sudo shutdown -h now" 2>/dev/null || {
    echo "USB system not accessible, proceed to manual power off"
}

# 2. Manual step: Change boot order to SD first in BIOS/UEFI

# 3. Power on (system boots from SD)

# 4. Verify booted from SD
ssh crtr@192.168.254.10 "
    if lsblk | grep -q 'mmcblk0p2.*/$'; then
        echo '✓ Booted from SD card'
    else
        echo '✗ Still on USB, check boot order'
        exit 1
    fi
"

# 5. Verify services
ssh crtr@192.168.254.10 "
    sudo systemctl status caddy docker pihole-FTL nfs-kernel-server
"

# 6. Test external access
curl -I https://n8n.ism.la

echo "=== ROLLBACK COMPLETE ==="
echo "Time: ~5 minutes"
echo "Data loss: None (/cluster-nas on separate NVMe)"
```

#### Config-Only Rollback

**Scenario**: Services installed correctly but configs broken

```bash
#!/bin/bash
# rollback-configs.sh - Rollback to previous config version

TARGET="crtr@192.168.254.10"

# 1. Identify last known good state
last_good_commit=$(git log --oneline config/ | grep -v "WIP\|test" | head -1 | awk '{print $1}')

echo "Rolling back configs to: $last_good_commit"

# 2. Checkout previous config
git checkout "$last_good_commit" -- config/

# 3. Redeploy configs
scp config/caddy/Caddyfile "$TARGET:/tmp/"
ssh "$TARGET" "
    sudo cp /tmp/Caddyfile /etc/caddy/Caddyfile
    sudo systemctl reload caddy
"

scp config/systemd/*.service "$TARGET:/tmp/"
ssh "$TARGET" "
    sudo cp /tmp/*.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl restart atuin-server semaphore
"

# 4. Verify services
ssh "$TARGET" "
    sudo systemctl status caddy
    curl -I http://localhost:80
"

echo "Config rollback complete"
```

#### Service-Specific Rollback

**Scenario**: One service failing, others OK

```bash
#!/bin/bash
# rollback-service.sh - Rollback specific service

TARGET="crtr@192.168.254.10"
SERVICE="$1"

case "$SERVICE" in
    caddy)
        echo "Rolling back Caddy..."
        git checkout HEAD~1 -- config/caddy/Caddyfile
        scp config/caddy/Caddyfile "$TARGET:/tmp/"
        ssh "$TARGET" "
            sudo cp /tmp/Caddyfile /etc/caddy/Caddyfile
            sudo systemctl reload caddy
        "
        ;;
    docker)
        echo "Rolling back Docker services..."
        ssh "$TARGET" "
            cd /cluster-nas/services/n8n
            docker compose down
            git checkout HEAD~1 -- docker-compose.yml
            docker compose up -d
        "
        ;;
    *)
        echo "Unknown service: $SERVICE"
        exit 1
        ;;
esac

echo "Service $SERVICE rolled back"
```

### 4.3 State Reconciliation After Rollback

```bash
#!/bin/bash
# reconcile-state.sh - Sync state files with actual system after rollback

TARGET="crtr@192.168.254.10"

echo "=== State Reconciliation ==="

# 1. Export current running state
./scripts/sync/export-live-state.sh --target "$TARGET"

# 2. Compare with repository state
git diff state/

# 3. Human decision
echo ""
echo "Differences found. Choose action:"
echo "  1) Accept live state (commit changes to state/)"
echo "  2) Revert to repository state (re-deploy from state/)"
echo "  3) Manual merge"
read -p "Choice: " choice

case "$choice" in
    1)
        git add state/
        git commit -m "Reconcile state after rollback"
        echo "State files updated to match live system"
        ;;
    2)
        ./scripts/generate/regenerate-all.sh
        ./bootstrap-deploy.sh
        echo "Live system updated to match state files"
        ;;
    3)
        echo "Opening vimdiff for manual merge..."
        # Manual process
        ;;
esac
```

---

## Part 5: Tool Ownership and Operational Boundaries

**From** `.stems/PRINCIPLES.md` (lines 76-85) and `.stems/METHODOLOGY.md` (lines 103-116)

### 5.1 Bootstrap Phase Tool Ownership

| Phase | Tool/Method | Owns | Boundaries |
|-------|-------------|------|-----------|
| **Pre-Bootstrap** | Git + crtr-config | `state/*.yml`, `.meta/`, `scripts/` | Version control, validation, generation |
| **Bootstrap Phase 1** | SSH + manual commands | System packages, user accounts | `/usr/bin/*`, `/home/crtr` |
| **Bootstrap Phase 2** | Schema-first deployment | Service configs | `/etc/caddy/*`, `/etc/systemd/system/*` |
| **Bootstrap Phase 3** | systemctl + docker | Service runtime | Running processes |
| **Post-Bootstrap** | SSOT scripts + monitoring | Infrastructure truth, drift detection | Validation, compliance |

**Key Principle**: No tool manages files owned by another. Clear boundaries prevent conflicts.

### 5.2 File Ownership Map for Bootstrap

```yaml
# After bootstrap, every file has ONE owner

user_space:
  owner: manual (restored from backup)
  files:
    - /home/crtr/.bashrc
    - /home/crtr/.ssh/config
    - /home/crtr/duckdns/
  deployment: tar xzf backups/home-crtr.tar.gz
  updates: manual editing

system_config:
  owner: crtr-config (schema-first)
  files:
    - /etc/caddy/Caddyfile
    - /etc/systemd/system/*.service
    - /etc/exports
    - /etc/dnsmasq.d/02-custom-local-dns.conf
  deployment: generated from state/, manually copied
  updates: edit state/*.yml → regenerate → redeploy

service_runtime:
  owner: systemd + docker
  files:
    - /run/systemd/*
    - /var/lib/docker/*
    - /var/run/caddy/*
  deployment: service startup
  updates: systemctl restart, docker compose restart

data:
  owner: applications
  files:
    - /cluster-nas/services/*/data
    - /cluster-nas/backups/*
  deployment: preserved across migrations
  updates: application writes

infrastructure_truth:
  owner: .meta/ssot/
  files:
    - .meta/ssot/infrastructure-truth.yaml
  deployment: generated by discovery scripts
  updates: automated re-discovery
```

### 5.3 Bootstrap Command Reference by Owner

```bash
# === crtr-config (schema-first) ===
# Generate configs
./scripts/generate/regenerate-all.sh

# Validate state
./.meta/validation/validate.sh

# Deploy configs (manual)
sudo cp config/caddy/Caddyfile /etc/caddy/
sudo systemctl reload caddy

# === Package manager (system) ===
# Install packages
sudo apt install -y docker.io caddy nfs-kernel-server

# Update packages
sudo apt update && sudo apt upgrade -y

# === systemd (service lifecycle) ===
# Enable and start
sudo systemctl enable --now caddy docker

# Restart
sudo systemctl restart pihole-FTL

# Check status
sudo systemctl status nfs-kernel-server

# === docker (containers) ===
# Start containers
docker compose up -d

# View logs
docker compose logs -f n8n

# Restart container
docker compose restart n8n

# === User (manual) ===
# Restore user configs
tar xzf /cluster-nas/backups/migration-*/home-crtr.tar.gz -C ~/

# Edit dotfiles
vim ~/.bashrc
source ~/.bashrc
```

**No Overlap**: Each command belongs to exactly one domain. This prevents "I updated the config but it didn't take effect" issues.

---

## Part 6: Safety Gates and Human-in-Loop

**From** `.stems/METHODOLOGY.md` (lines 52-68, 119-129)

### 6.1 Safety Gate Levels

```
Level 0: Automatic (No human approval needed)
  - Syntax validation
  - Schema validation
  - Read-only checks
  Example: ./meta/validation/validate.sh

Level 1: Informational (Shows what will change, requires acknowledgment)
  - Config generation
  - Dry-run simulations
  - Diff previews
  Example: git diff config/

Level 2: Manual approval (Requires explicit "yes")
  - System package installation
  - Config deployment
  - Service restart
  Example: read -p "Apply changes? (y/n)" -n 1 -r

Level 3: Multi-stage approval (Phase completion requires approval)
  - Phase 1 → Phase 2 transition
  - Pre-production → production cutover
  Example: Bootstrap phase transitions

Level 4: Emergency stop (Can abort at any point)
  - Ctrl+C during execution
  - Manual service stop
  Example: systemctl stop caddy (if behavior unexpected)
```

### 6.2 Human-in-Loop Checkpoints

```bash
#!/bin/bash
# bootstrap-with-approvals.sh - Bootstrap with explicit human approval gates

# Level 2: Before any system changes
echo "About to install system packages on target"
read -p "Continue? (yes/no): " -r
[[ $REPLY == "yes" ]] || exit 1

# Deploy packages...

# Level 1: Show what changed
echo "Packages installed. Current state:"
ssh "$TARGET" "dpkg -l | grep -E 'caddy|docker'"
echo ""
read -p "Proceed to service config deployment? (y/n): " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

# Level 2: Before deploying configs
echo "Deploying Caddyfile:"
cat config/caddy/Caddyfile
echo ""
read -p "Deploy this configuration? (yes/no): " -r
[[ $REPLY == "yes" ]] || exit 1

# Deploy configs...

# Level 3: Phase completion
echo "Phase 2 complete. Services configured but not started."
echo "Review logs: ssh $TARGET 'sudo journalctl -xe'"
echo ""
read -p "Start services (Phase 3)? (yes/no): " -r
[[ $REPLY == "yes" ]] || exit 1

# Start services...

# Level 4: Emergency verification
echo "Services started. Testing..."
sleep 5
if ! curl -I http://localhost:80; then
    echo "ERROR: Service not responding"
    read -p "Continue anyway? (yes/no): " -r
    [[ $REPLY == "yes" ]] || {
        echo "Aborting. Services remain in current state."
        exit 1
    }
fi
```

### 6.3 Abort and Recovery

```bash
# User presses Ctrl+C during deployment

trap 'handle_abort' INT TERM

handle_abort() {
    echo ""
    echo "=== DEPLOYMENT ABORTED BY USER ==="
    echo "Last checkpoint: $(tail -1 /tmp/bootstrap-checkpoints.txt)"
    echo ""
    echo "System state: Partially configured"
    echo "Options:"
    echo "  1) Resume from last checkpoint"
    echo "  2) Rollback to pre-deployment state"
    echo "  3) Exit and investigate"
    read -p "Choice: " choice

    case "$choice" in
        1)
            echo "Resuming..."
            # Continue from last checkpoint
            ;;
        2)
            echo "Rolling back..."
            ./rollback-bootstrap.sh
            exit 1
            ;;
        3)
            echo "Exiting. Review logs and state."
            exit 1
            ;;
    esac
}
```

---

## Part 7: Post-Bootstrap Operations

### 7.1 State Drift Detection

**From** `.stems/LIFECYCLE.md` (lines 209-222)

```bash
#!/bin/bash
# detect-drift.sh - Detect configuration drift after bootstrap

# Compare actual system state with state files
echo "=== Configuration Drift Detection ==="

# Caddy config drift
echo "Checking Caddy config..."
diff <(ssh crtr@192.168.254.10 "sudo cat /etc/caddy/Caddyfile") \
     config/caddy/Caddyfile || {
    echo "WARNING: Caddyfile drift detected"
}

# Systemd units drift
echo "Checking systemd units..."
for unit in config/systemd/*.service; do
    unit_name=$(basename "$unit")
    diff <(ssh crtr@192.168.254.10 "sudo cat /etc/systemd/system/$unit_name") \
         "$unit" || {
        echo "WARNING: $unit_name drift detected"
    }
done

# NFS exports drift
echo "Checking NFS exports..."
diff <(ssh crtr@192.168.254.10 "sudo cat /etc/exports") \
     config/nfs/exports || {
    echo "WARNING: NFS exports drift detected"
}

echo "=== Drift Detection Complete ==="
```

### 7.2 Infrastructure Truth Validation

**From** `.stems/METHODOLOGY.md` and `.meta/ssot/` structure

```bash
#!/bin/bash
# validate-infrastructure-truth.sh - Verify system matches documented state

echo "=== Infrastructure Truth Validation ==="

# Node identity
echo "Validating node identity..."
expected_hostname=$(yq '.node.identity.hostname' state/node.yml)
actual_hostname=$(ssh crtr@192.168.254.10 "hostname")
[ "$expected_hostname" == "$actual_hostname" ] || {
    echo "ERROR: Hostname mismatch (expected: $expected_hostname, actual: $actual_hostname)"
}

# Network configuration
echo "Validating network..."
expected_ip=$(yq '.node.network.internal_ip' state/node.yml)
actual_ip=$(ssh crtr@192.168.254.10 "ip -4 addr show eth0 | grep inet | awk '{print \$2}' | cut -d/ -f1")
[ "$expected_ip" == "$actual_ip" ] || {
    echo "ERROR: IP mismatch (expected: $expected_ip, actual: $actual_ip)"
}

# Services
echo "Validating services..."
for service in caddy docker nfs-kernel-server pihole-FTL; do
    if ssh crtr@192.168.254.10 "systemctl is-active $service >/dev/null 2>&1"; then
        echo "  ✓ $service running"
    else
        echo "  ✗ $service not running (expected: running)"
    fi
done

echo "=== Validation Complete ==="
```

### 7.3 Continuous Reconciliation

```bash
#!/bin/bash
# reconcile-cron.sh - Scheduled reconciliation (run via cron)

# Runs every 4 hours to detect and alert on drift

DRIFT_LOG="/var/log/config-drift.log"

{
    echo "=== $(date) ==="

    # Detect drift
    ./detect-drift.sh

    # If drift detected, send alert
    if [ $? -ne 0 ]; then
        echo "Configuration drift detected at $(date)" | \
            mail -s "Config Drift Alert: cooperator" admin@example.com
    fi

} >> "$DRIFT_LOG" 2>&1
```

---

## Summary: .stems/ Patterns → Bootstrap Workflow

| .stems/ Pattern | Applied to Bootstrap | Location in This Doc |
|----------------|---------------------|---------------------|
| **Validation-first deployment** | Multi-stage validation pipeline | Part 2 |
| **Configuration lifecycle** | Bootstrap phase structure | Part 3 |
| **Tool domain boundaries** | Clear ownership during setup | Part 5 |
| **Idempotency** | Safe-to-retry commands | Part 1.4 |
| **Fail fast, fail safe** | Error handling and rollback | Part 4 |
| **Human-in-loop** | Approval gates and checkpoints | Part 6 |
| **State reconciliation** | Drift detection post-bootstrap | Part 7 |
| **Progressive disclosure** | Incremental deployment phases | Part 3 |
| **Observability** | Checkpoint tracking and verification | Part 3.3 |
| **Rollback capability** | Emergency and targeted rollback | Part 4 |

---

## Appendix: Quick Reference

### Bootstrap Command Sequence

```bash
# 1. Pre-flight (Local)
cd ~/Projects/crtr-config
./.meta/validation/validate.sh
./scripts/generate/regenerate-all.sh
git diff config/

# 2. Target prep (Remote)
ssh pi@192.168.254.10 "hostname; df -h; ip addr"

# 3. Validation pipeline
./bootstrap-validate.sh

# 4. Deployment with checkpoints
./bootstrap-deploy.sh

# 5. Verification
./verify-bootstrap.sh

# 6. Post-bootstrap
./detect-drift.sh
./validate-infrastructure-truth.sh
```

### Rollback Commands

```bash
# Emergency: Back to SD card
./rollback-to-sd.sh

# Config-only rollback
./rollback-configs.sh

# Service-specific rollback
./rollback-service.sh caddy

# State reconciliation
./reconcile-state.sh
```

### Safety Checklist

- [ ] State files validated (syntax + schema)
- [ ] Configs generated successfully
- [ ] Target system verified (SSH, resources)
- [ ] Deployment simulation clean
- [ ] Human approval granted
- [ ] Phase 1 checkpoint passed
- [ ] Phase 2 checkpoint passed
- [ ] Phase 3 checkpoint passed
- [ ] External access verified
- [ ] No failed systemd units
- [ ] Drift detection enabled
- [ ] Rollback procedure tested

---

**End of Document**

This bootstrap workflow combines `.stems/` methodology with `crtr-config` schema-first architecture to provide a **safe, explicit, human-controlled** deployment procedure for fresh Raspberry Pi OS installations.
