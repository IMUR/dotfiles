# DX Quick Reference - Migration Tools

**Source**: `.stems/` methodology applied to cooperator migration
**Implementation**: `/home/crtr/Projects/crtr-config/scripts/migration/dx-quick-wins.sh`

---

## Installation (One-Time)

```bash
# Add to ~/.bashrc
echo 'source ~/Projects/crtr-config/scripts/migration/dx-quick-wins.sh' >> ~/.bashrc
source ~/.bashrc
```

Now all commands available directly.

---

## Essential Commands

### System Status (Progressive Disclosure)

```bash
# Level 1: Quick overview (10 seconds)
colab-status
# Output: Boot device, services count, storage, DNS, errors

# Level 2: Service details (30 seconds)
colab-status-services
# Output: Per-service status with purpose

# Level 3: Full diagnostic (2 minutes)
colab-status-full
# Output: Complete system state, recent errors, network
```

### Pre-Migration Validation

```bash
# Check prerequisites before starting
pre-flight-check
# Validates: USB present, state valid, backups exist, on SD
```

### Progress Tracking

```bash
# Log completed phase
log-progress "phase1" "State validated"

# View progress
show-progress

# Clear log
clear-progress
```

### Service Health

```bash
# Check specific service
check-service-health caddy
# Shows: status, enabled, errors, service-specific checks
```

### Emergency Recovery

```bash
# Get rollback advice
rollback-advisor
# Interactive guide based on problem type

# Execute rollback
emergency-rollback
# Guided shutdown with BIOS instructions
```

---

## Migration Workflow Example

```bash
# Step 1: Check current state
colab-status
# Verify: SD boot, services running, no errors

# Step 2: Pre-flight validation
pre-flight-check
# Verify: All prerequisites met

# Step 3: Log start
log-progress "start" "Migration initiated"

# Step 4: Validate state
cd ~/Projects/crtr-config
./.meta/validation/validate.sh
log-progress "validate" "State files validated"

# Step 5: Generate configs
./scripts/generate/regenerate-all.sh
log-progress "generate" "Configs generated"

# Step 6: Prepare USB
./scripts/migration/usb-setup.sh
log-progress "usb-prep" "USB drive prepared"

# Step 7: Test USB (after booting to USB)
colab-status  # Should show "USB Drive (RasPi OS) [MIGRATED]"
colab-status-full  # Check all services
log-progress "usb-test" "USB system verified"

# Step 8: If issues, get advice
rollback-advisor
# Follow recommendations

# Step 9: View progress
show-progress
```

---

## Problem Solving

### Service Won't Start
```bash
# Check service
check-service-health caddy

# View recent logs
journalctl -u caddy -n 50

# Restart
sudo systemctl restart caddy

# If still failing
rollback-advisor  # Choose option 1
```

### DNS Not Resolving
```bash
# Quick fix
sudo systemctl restart pihole-FTL

# Verify
dig @localhost n8n.ism.la +short

# If still failing
check-service-health pihole-FTL
```

### Multiple Services Failing
```bash
# Get full diagnostic
colab-status-full

# Restart all
sudo systemctl restart caddy pihole-FTL docker

# If persists
rollback-advisor  # Choose option 2
```

### Can't Access System
```bash
# Physical access needed
# Boot to SD via BIOS:
#   1. Hold SHIFT during boot
#   2. Change boot order: SD first
#   3. Save and reboot
```

---

## Understanding Output

### colab-status Output
```
Boot: USB Drive (RasPi OS) [MIGRATED]
Services: 12 running
Docker: 3 containers
Storage: /cluster-nas mounted (67% used)
DNS: Resolving .ism.la domains
Errors: None (last hour)
```

**What it means**:
- **Boot**: Currently running from USB (migrated successfully)
- **Services**: 12 systemd services active
- **Docker**: 3 containers running (n8n, etc)
- **Storage**: NVMe mounted and accessible
- **DNS**: Pi-hole resolving local domains
- **Errors**: No errors in last hour

### pre-flight-check Output
```
[PASS] USB device connected (/dev/sdb)
[PASS] State files valid
[PASS] /cluster-nas mounted
[PASS] Found 5 backup files
[PASS] Booted from SD (ready to migrate)

Results: 5 passed, 0 failed
Status: READY TO PROCEED ✓
```

**What it means**: All prerequisites met, safe to start migration.

---

## Key Principles

### Progressive Disclosure
- Start with `colab-status` (simple)
- Add `colab-status-full` (detailed) only when needed
- Complexity on-demand, not by default

### Observable State
- Commands explain WHAT, not HOW
- Output self-documenting
- No investigation required

### Human Control
- Verify each phase before proceeding
- No "run and hope"
- Explicit approval at gates

### Fast Recovery
- 5-minute rollback via boot order
- No data loss (NVMe separate)
- Rollback advisor guides decisions

---

## File Locations

**DX Tools**:
- Implementation: `/home/crtr/Projects/crtr-config/scripts/migration/dx-quick-wins.sh`
- Documentation: `/home/crtr/Projects/crtr-config/docs/DX-INSIGHTS-FROM-STEMS.md`
- Quick ref: This file

**Migration Procedure**:
- Main guide: `/home/crtr/Projects/crtr-config/docs/MIGRATION-PROCEDURE.md`
- State files: `/home/crtr/Projects/crtr-config/state/`
- Configs: `/home/crtr/Projects/crtr-config/config/`

**Logs**:
- Progress log: `/tmp/migration-progress.log`
- System logs: `journalctl -p err --since "1 hour ago"`

---

## Troubleshooting DX Tools

### Commands not found after ~/.bashrc update
```bash
source ~/.bashrc
# Or open new terminal
```

### Permission denied
```bash
chmod +x ~/Projects/crtr-config/scripts/migration/dx-quick-wins.sh
```

### Script errors
```bash
# Check script exists
ls -la ~/Projects/crtr-config/scripts/migration/dx-quick-wins.sh

# Run with bash explicitly
bash ~/Projects/crtr-config/scripts/migration/dx-quick-wins.sh status
```

---

## Next Steps

1. **Install**: Add to `~/.bashrc` (see Installation section)
2. **Test**: Run `colab-status` on current system
3. **Familiarize**: Try each command to understand output
4. **Migrate**: Use during actual migration
5. **Adapt**: Modify commands for your workflow

---

**Generated**: 2025-10-13
**Methodology**: `.stems/` (observability, progressive disclosure, recovery)
**Status**: Ready to use
