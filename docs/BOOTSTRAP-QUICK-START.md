# Bootstrap Quick Start: Fresh Pi OS Deployment

**TL;DR**: Deploy cooperator node on fresh Raspberry Pi OS using `.stems/` methodology

**Time**: 30-45 minutes
**Risk**: Low (rollback in 5 minutes)
**Prerequisites**: Fresh Pi OS on USB, SSH access, state files validated

---

## What You're Deploying

From `.stems/` **principles** to **practical** Pi OS bootstrap:

```
.stems/ Patterns                 Applied to Bootstrap
─────────────────                ────────────────────
Validation-first      →          Multi-stage validation pipeline
Configuration lifecycle →        Bootstrap phase structure (Foundation → Services → Operations)
Tool domain boundaries →         Clear ownership (crtr-config, systemd, docker)
Idempotency          →           Safe-to-retry commands
Fail fast/safe       →           Checkpoint tracking, rollback procedures
Human-in-loop        →           Approval gates between phases
```

**Result**: Cooperator node (192.168.254.10) running Caddy, Pi-hole, Docker, NFS with schema-first config management

---

## Quick Command Reference

### 1. Validate (5 minutes)

```bash
cd ~/Projects/crtr-config

# Run validation pipeline (6 stages, non-destructive)
./scripts/bootstrap/bootstrap-validate.sh

# Expected output:
# ✓ Stage 1: Syntax validation
# ✓ Stage 2: Config generation
# ✓ Stage 3: Target system pre-flight
# ✓ Stage 4: Required commands
# ✓ Stage 5: Deployment simulation
# ✓ Stage 6: Human approval
# Prompt: "Proceed with bootstrap deployment? (type 'yes' to confirm):"
```

**What it checks**:
- State file syntax (YAML, schemas)
- Config generation (Caddyfile, systemd units)
- Target system (SSH, disk space, memory)
- Package availability
- No conflicts

**If fails**: Fix indicated issue, retry validation

### 2. Deploy (20-30 minutes)

```bash
# Run deployment with checkpoints
./scripts/bootstrap/bootstrap-deploy.sh

# Phase 1: Foundation (10 min)
#   - System packages (git, vim, curl, etc.)
#   - User account (crtr)
#   - Network validation
#   - Storage verification
# Prompt: "Continue to Phase 2? (y/n):"

# Phase 2: Services (10 min)
#   - Docker installation
#   - Caddy installation
#   - Config deployment (from generated configs)
#   - Systemd units
# Prompt: "Continue to Phase 3? (y/n):"

# Phase 3: Operations (5 min)
#   - Start core services
#   - Start application services
#   - Verify local access
#   - Verify external access
```

**What it does**:
- Installs packages (idempotent)
- Creates users (idempotent)
- Deploys configs (overwrites from state)
- Starts services

**If fails**: Script shows last checkpoint, options to resume/rollback

### 3. Verify (2 minutes)

```bash
# Check everything works
./scripts/bootstrap/verify-bootstrap.sh

# Expected output:
# ✓ nfs-kernel-server
# ✓ docker
# ✓ caddy
# ✓ DNS resolution (local)
# ✓ HTTP localhost:80
# ✓ HTTPS n8n.ism.la
# ✓ No failed units
```

**What it checks**:
- Service status
- DNS resolution
- Local/external connectivity
- Failed systemd units

---

## Emergency Rollback

**If deployment fails completely**:

```bash
# 1. Shutdown USB system
ssh crtr@192.168.254.10 "sudo shutdown -h now"

# 2. Change boot order: SD first (in BIOS/UEFI)

# 3. Power on (boots from SD card)

# 4. Verify services
ssh crtr@192.168.254.10 "systemctl status caddy docker"
curl -I https://n8n.ism.la
```

**Time**: 5 minutes
**Data loss**: None (all data on `/cluster-nas` NVMe, unchanged)

---

## Understanding the Validation Pipeline

**From** `.stems/METHODOLOGY.md` (lines 91-101):

```
Stage 1: Syntax → Local, no system access
Stage 2: Simulation → Local, config generation test
Stage 3: Approval → Human decision point
Stage 4: Application → Writes to system
Stage 5: Verification → Post-deployment check
```

**Applied** to bootstrap:

| Stage | What | Impact | Can Retry? |
|-------|------|--------|-----------|
| 1. Syntax | YAML/Jinja2 validation | None | Yes |
| 2. Generation | Config build test | None | Yes |
| 3. Pre-flight | Target system check | None (read-only) | Yes |
| 4. Commands | Required binaries check | None (read-only) | Yes |
| 5. Simulation | Package dry-run | None (read-only) | Yes |
| 6. Approval | Human decision | None | N/A |
| 7. Phase 1 Deploy | System changes | Moderate | Yes (idempotent) |
| 8. Phase 2 Deploy | Service configs | High | Yes (idempotent) |
| 9. Phase 3 Deploy | Service startup | Critical | Yes (idempotent) |

**Key insight**: Stages 1-6 are non-destructive and repeatable. Only stages 7-9 modify system.

---

## Understanding Tool Boundaries

**From** `.stems/PRINCIPLES.md` (lines 76-85):

```yaml
# Each domain has ONE owner

user_space:
  owner: manual (backup restore)
  files: /home/crtr/.bashrc, .ssh/config
  update: edit directly

system_config:
  owner: crtr-config (schema-first)
  files: /etc/caddy/Caddyfile, /etc/systemd/system/*.service
  update: edit state/*.yml → regenerate → redeploy

service_runtime:
  owner: systemd + docker
  files: /run/systemd/*, /var/lib/docker/*
  update: systemctl restart, docker compose restart
```

**During bootstrap**:
1. crtr-config **generates** configs from `state/*.yml`
2. Bootstrap scripts **deploy** generated configs to system
3. systemd/docker **run** services using deployed configs
4. No tool touches files owned by another

---

## Understanding Checkpoints

**From** `.stems/LIFECYCLE.md` (lines 145-190):

Bootstrap progress tracked:

```
Phase 1: Foundation
  ✓ Checkpoint 1.1: System packages installed
  ✓ Checkpoint 1.2: User account created
  ✓ Checkpoint 1.3: Network configured
  ✓ Checkpoint 1.4: Storage mounted

Phase 2: Services
  ✓ Checkpoint 2.1: Docker installed
  ✓ Checkpoint 2.2: Caddy installed
  ✓ Checkpoint 2.3: Configs deployed
  ✓ Checkpoint 2.4: Systemd units installed

Phase 3: Operations
  ✓ Checkpoint 3.1: Core services started
  ✓ Checkpoint 3.2: Application services started
  ✓ Checkpoint 3.3: Local access verified
  ✓ Checkpoint 3.4: External access verified
```

**Why checkpoints?**
- Know exactly where deployment stopped if error
- Resume from last successful checkpoint
- Verify each stage before proceeding

**Checkpoint file**: `/tmp/bootstrap-checkpoints.txt`

---

## Common Issues

### Validation Fails: "State file invalid"

```bash
# Check which file
./.meta/validation/validate.sh

# Fix YAML syntax
vim state/services.yml

# Retry
./scripts/bootstrap/bootstrap-validate.sh
```

### Target System: "Cannot connect via SSH"

```bash
# Check network
ping 192.168.254.10

# Check SSH keys
ssh-add -l
ssh pi@192.168.254.10

# Verify USB booted
ssh pi@192.168.254.10 "lsblk | grep '/'"
# Should show sdb (USB), not mmcblk0 (SD)
```

### Deployment: "Docker installation failed"

```bash
# Check last checkpoint
cat /tmp/bootstrap-checkpoints.txt
# Shows: "Phase 2.1: Docker installed" (failed here)

# Investigate
ssh pi@192.168.254.10 "sudo journalctl -xe | tail -50"

# Manual install/fix
ssh pi@192.168.254.10 "curl -fsSL https://get.docker.com | sudo sh"

# Resume from next checkpoint
# (Edit bootstrap-deploy.sh to start at Phase 2.2)
```

### Service Won't Start

```bash
# Check service logs
ssh crtr@192.168.254.10 "sudo journalctl -u caddy -n 50"

# Common causes:
# - Config syntax error → caddy validate --config /etc/caddy/Caddyfile
# - Port conflict → sudo lsof -i :80
# - Dependencies missing → systemctl list-dependencies caddy

# Fix config
vim state/domains.yml
./scripts/generate/regenerate-all.sh
scp config/caddy/Caddyfile crtr@192.168.254.10:/tmp/
ssh crtr@192.168.254.10 "sudo cp /tmp/Caddyfile /etc/caddy/ && sudo systemctl restart caddy"
```

---

## What's Different from Manual Deployment?

### Manual (Old Way)

```bash
ssh pi@192.168.254.10
sudo vim /etc/caddy/Caddyfile          # Direct editing
sudo systemctl reload caddy
# Config drifts from repo, no validation
```

### Schema-First (New Way)

```bash
vim state/domains.yml                  # Edit source of truth
./.meta/validation/validate.sh         # Validate
./scripts/generate/regenerate-all.sh   # Generate configs
./scripts/bootstrap/bootstrap-deploy.sh # Deploy validated configs
# Config in sync with repo, validated before deploy
```

**Benefits**:
- Validation catches errors before deployment
- Configs always match state files
- Reproducible (can regenerate anytime)
- Auditable (git history shows all changes)
- Rollback via git checkout

---

## Post-Bootstrap

### Monitor for Drift

```bash
# Detect config drift (run daily via cron)
./scripts/bootstrap/detect-drift.sh

# If drift detected:
# Option 1: Update state to match live
./scripts/sync/export-live-state.sh
git diff state/
git commit -am "Sync state with live system"

# Option 2: Revert live to match state
./scripts/generate/regenerate-all.sh
./scripts/bootstrap/bootstrap-deploy.sh
```

### Regular Validation

```bash
# Weekly: Verify infrastructure truth
./scripts/bootstrap/validate-infrastructure-truth.sh

# Monthly: Full validation
./scripts/bootstrap/bootstrap-validate.sh
```

---

## Files Created/Modified

### On Target System

```
/etc/caddy/Caddyfile                    (from config/caddy/)
/etc/systemd/system/*.service           (from config/systemd/)
/etc/exports                            (from config/nfs/)
/etc/dnsmasq.d/02-custom-local-dns.conf (from config/pihole/)
/home/crtr/                             (restored from backup)
```

### In Repository

```
/tmp/bootstrap-checkpoints.txt          (checkpoint tracking)
```

**All generated configs come from `state/*.yml`** - never edited directly.

---

## Next Steps After Bootstrap

1. **Verify external access**:
   ```bash
   curl -I https://n8n.ism.la
   dig @192.168.254.10 n8n.ism.la
   ```

2. **Start Docker services**:
   ```bash
   ssh crtr@192.168.254.10 "cd /cluster-nas/services/n8n && docker compose up -d"
   ```

3. **Enable monitoring**:
   ```bash
   ./scripts/bootstrap/detect-drift.sh
   # Add to cron for daily checks
   ```

4. **Update state if needed**:
   ```bash
   vim state/node.yml  # Update OS version, etc.
   git commit -am "Update node state post-bootstrap"
   ```

5. **Backup USB drive**:
   ```bash
   ssh crtr@192.168.254.10 "sudo dd if=/dev/sdb of=/cluster-nas/backups/usb-$(date +%F).img bs=4M status=progress"
   ```

---

## Full Documentation

- **Detailed workflow**: `docs/BOOTSTRAP-WORKFLOW.md` (complete operational guide)
- **Script usage**: `scripts/bootstrap/README.md` (all scripts explained)
- **Migration procedure**: `docs/MIGRATION-PROCEDURE.md` (full deployment steps)
- **.stems/ methodology**: `.stems/METHODOLOGY.md` (principles and patterns)

---

## Quick Troubleshooting Decision Tree

```
Deployment failed?
├─ Validation stage? → Fix state files, retry validation
├─ Phase 1 (packages)? → SSH in, install manually, resume
├─ Phase 2 (configs)? → Fix state, regenerate, redeploy
├─ Phase 3 (startup)? → Check logs, fix config, restart
└─ Complete failure? → Rollback to SD card (5 min)

Service not working?
├─ Not started? → systemctl status, check logs, restart
├─ Started but broken? → Validate config syntax
├─ Config drift? → Regenerate from state, redeploy
└─ External access fails? → Check DNS, firewall, Caddy

Need to rollback?
├─ Config only? → git checkout, redeploy configs
├─ Service specific? → Rollback just that service
├─ Complete system? → Boot from SD card
└─ State mismatch? → Reconcile state with live system
```

---

**Ready?** Run `./scripts/bootstrap/bootstrap-validate.sh` to start.
