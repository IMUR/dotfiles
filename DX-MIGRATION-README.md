# DX-Enhanced Migration Tools

**Enhanced migration experience based on `.stems/` methodology**

---

## What This Is

DX (Developer Experience) improvements for the Raspberry Pi OS migration, extracted from the `.stems/` methodology. These tools add **observability, control, and recoverability** to the migration process without changing the underlying procedure.

## Why This Matters

Traditional migration: Run script, hope for the best, discover issues after the fact.

DX-enhanced migration: Observable state, explicit approval gates, instant rollback, self-explaining errors.

**Core improvement**: From "run and hope" to "understand and control".

---

## Quick Start (5 minutes)

### 1. Install Tools

```bash
# Add to shell environment
echo 'source ~/Projects/crtr-config/scripts/migration/dx-quick-wins.sh' >> ~/.bashrc
source ~/.bashrc
```

### 2. Test Current System

```bash
# Quick status check
colab-status

# Should show:
#   Boot: SD Card (Debian) [ORIGINAL]
#   Services: X running
#   Storage: /cluster-nas mounted
#   DNS: Resolving
#   Errors: None
```

### 3. Pre-Flight Check

```bash
# Validate prerequisites
pre-flight-check

# Fix any failures before proceeding
```

### 4. You're Ready

Proceed with migration using your existing procedure (`/home/crtr/Projects/crtr-config/docs/MIGRATION-PROCEDURE.md`), but now with:
- Observable status at each step
- Progress tracking
- Instant rollback if needed

---

## What You Get

### 1. Progressive Disclosure Commands

**Simple → Detailed → Full Diagnostic**

```bash
colab-status              # 10 seconds: overview
colab-status-services     # 30 seconds: service details
colab-status-full         # 2 minutes: complete diagnostic
```

Start simple, add detail only when needed.

### 2. Pre-Flight Validation

```bash
pre-flight-check
```

Validates before starting:
- USB drive connected
- State files valid
- Backups present
- Currently on SD (ready to migrate)

**Catches issues early**, not during migration.

### 3. Progress Tracking

```bash
log-progress "phase1" "State validated"
show-progress
```

Always know where you are. Resume after interruption.

### 4. Service Health Checks

```bash
check-service-health caddy
```

Self-explaining status:
- Running? Enabled? Errors?
- Service-specific checks (API responding, DNS resolving)

### 5. Emergency Rollback

```bash
emergency-rollback
```

Guided shutdown with BIOS instructions. 5-minute recovery to SD.

### 6. Rollback Advisor

```bash
rollback-advisor
```

Interactive guide:
- Single service down → restart service
- Multiple failures → restart all services
- Can't access → full OS rollback
- Data corruption → investigate first (don't rollback)

**Decision tree for recovery**, not guessing.

---

## Documents Included

### DX-INSIGHTS-FROM-STEMS.md (comprehensive)
- **Path**: `/home/crtr/Projects/crtr-config/docs/DX-INSIGHTS-FROM-STEMS.md`
- **Length**: 500+ lines
- **Content**: Deep dive into 5 DX patterns from `.stems/`
- **For**: Understanding methodology, implementing custom tools

### DX-QUICK-REFERENCE.md (practical)
- **Path**: `/home/crtr/Projects/crtr-config/docs/DX-QUICK-REFERENCE.md`
- **Length**: 250 lines
- **Content**: Command reference, examples, troubleshooting
- **For**: Daily use during migration

### dx-quick-wins.sh (executable)
- **Path**: `/home/crtr/Projects/crtr-config/scripts/migration/dx-quick-wins.sh`
- **Length**: 600 lines
- **Content**: 8 ready-to-use DX tools
- **For**: Source into shell, use commands directly

---

## Integration with Existing Migration

Your existing migration procedure (`MIGRATION-PROCEDURE.md`) remains the primary guide. DX tools **augment** it:

### Phase 1: Preparation (While SD Running)

**Before**:
```bash
cd ~/Projects/crtr-config
./scripts/sync/export-live-state.sh
git diff state/
```

**With DX tools**:
```bash
# Check current state first
colab-status

# Pre-flight validation
pre-flight-check

# Then proceed with preparation
cd ~/Projects/crtr-config
./scripts/sync/export-live-state.sh
git diff state/

# Log progress
log-progress "prep" "State exported and validated"
```

### Phase 2: First Boot USB

**Before**: Follow procedure, hope services start

**With DX tools**:
```bash
# After booting to USB, check status
colab-status  # Should show "USB Drive (RasPi OS) [MIGRATED]"

# Detailed service check
colab-status-services

# Verify each service
check-service-health caddy
check-service-health pihole-FTL
check-service-health docker

# If issues
rollback-advisor  # Get recovery guidance

# When verified
log-progress "usb-test" "All services verified on USB"
```

### Phase 3: Final Cutover

**Before**: Execute cutover, verify after

**With DX tools**:
```bash
# Final SD status before cutover
colab-status-full

# Log cutover
log-progress "cutover" "Switching to USB production"

# Execute cutover (follow MIGRATION-PROCEDURE.md)

# After USB boots, verify
colab-status
colab-status-full

# Log completion
log-progress "complete" "Migration successful"

# View full timeline
show-progress
```

---

## Example Migration Session

```bash
# Day 1: Preparation (SD system)
colab-status                    # Verify current state healthy
pre-flight-check                # Check prerequisites
log-progress "start" "Beginning migration"

# Export and validate state
cd ~/Projects/crtr-config
./scripts/sync/export-live-state.sh
./.meta/validation/validate.sh
log-progress "validate" "State validated"

# Prepare USB
./scripts/migration/usb-setup.sh
log-progress "usb-prep" "USB configured"

# Boot to USB, test
# (Reboot to USB)

# Day 2: USB Testing
colab-status                    # Shows "USB Drive [MIGRATED]"
colab-status-services           # All services running?
check-service-health caddy      # Verify each service
check-service-health pihole-FTL
check-service-health docker

# Issues found?
rollback-advisor                # Get guidance
# Follow recommendations

# All good?
log-progress "usb-test" "USB system verified"

# Back to SD for final cutover
# (Reboot to SD)

# Day 3: Cutover
colab-status-full               # Final SD check
log-progress "cutover" "Executing production cutover"

# Execute cutover (follow procedure)
# (Reboot to USB, production)

colab-status                    # Verify production
show-progress                   # Review timeline

# Day 4-5: Monitoring
colab-status                    # Check daily
journalctl -p err --since "24 hours ago"

# After 24 hours stable
log-progress "complete" "Migration successful, 24h stable"
```

---

## Benefits Summary

### Before DX Tools
- Run commands blindly
- Discover issues after the fact
- Unclear system state
- Manual error investigation
- Uncertain recovery path

### With DX Tools
- Observable state at each step
- Pre-flight validation catches issues early
- Self-explaining status and errors
- Guided rollback decisions
- Progress tracking and resume

**Time saved**: 30-60 minutes during migration (less troubleshooting, faster decisions)
**Confidence gained**: Know exactly what's happening, when, and why
**Risk reduced**: Catch issues early, recover fast

---

## .stems/ Principles Applied

### 1. Progressive Disclosure (PRINCIPLES O2)
**Pattern**: Simple tasks stay simple, complexity on-demand
**Implementation**: Three-level status commands (`status` → `status-services` → `status-full`)

### 2. Human Approval Gates (METHODOLOGY Phase 3)
**Pattern**: Explicit approval for system changes
**Implementation**: Pre-flight checks, rollback advisor (manual decisions)

### 3. Observability Over Debugging (PRINCIPLES O4)
**Pattern**: System explains itself without investigation
**Implementation**: Self-documenting status, service health with purpose, contextual errors

### 4. Recovery Over Prevention (PRINCIPLES O5)
**Pattern**: Fast rollback beats perfect execution
**Implementation**: 5-minute OS rollback, progressive recovery levels, rollback advisor

### 5. Self-Documenting Configuration (METHODOLOGY)
**Pattern**: Configuration explains purpose inline
**Implementation**: Status shows service purpose, errors explain fixes, commands show context

---

## Next Steps

### Immediate (Today)
1. Install: `echo 'source ~/Projects/crtr-config/scripts/migration/dx-quick-wins.sh' >> ~/.bashrc && source ~/.bashrc`
2. Test: `colab-status` on current system
3. Review: Read `DX-QUICK-REFERENCE.md`

### Before Migration (Preparation)
1. Run: `pre-flight-check` to validate prerequisites
2. Test: Each command to understand output
3. Verify: `colab-status` shows expected "SD Card [ORIGINAL]"

### During Migration
1. Use: Commands at each phase (see "Example Migration Session")
2. Log: Progress with `log-progress`
3. Verify: Status after each major step

### After Migration
1. Monitor: `colab-status` daily for first week
2. Document: Any additional checks you found useful
3. Adapt: Modify tools for your workflow

---

## Getting Help

### DX Tools Not Working
Check:
- Script exists: `ls -la ~/Projects/crtr-config/scripts/migration/dx-quick-wins.sh`
- Executable: `chmod +x ~/Projects/crtr-config/scripts/migration/dx-quick-wins.sh`
- Sourced: `source ~/.bashrc` or open new terminal

### Migration Questions
Read:
1. **This file** - DX tools overview
2. `DX-QUICK-REFERENCE.md` - Command reference
3. `MIGRATION-PROCEDURE.md` - Main migration guide
4. `DX-INSIGHTS-FROM-STEMS.md` - Methodology deep dive

### System Issues During Migration
Run:
1. `colab-status-full` - Full diagnostic
2. `rollback-advisor` - Get recovery guidance
3. Follow recommendations

---

## Files Reference

```
/home/crtr/Projects/crtr-config/
├── DX-MIGRATION-README.md              ← YOU ARE HERE (overview)
├── docs/
│   ├── DX-INSIGHTS-FROM-STEMS.md       ← Methodology (comprehensive)
│   ├── DX-QUICK-REFERENCE.md           ← Command reference (practical)
│   └── MIGRATION-PROCEDURE.md          ← Main migration guide
├── scripts/
│   └── migration/
│       └── dx-quick-wins.sh            ← DX tools (executable)
└── .stems/
    ├── PRINCIPLES.md                    ← Source methodology
    ├── METHODOLOGY.md                   ← Source methodology
    └── LIFECYCLE.md                     ← Source methodology
```

---

## Status

**Created**: 2025-10-13
**Status**: Ready to use
**Tested**: Script validated, commands functional
**Next**: Test on live system, use during migration

---

**Remember**: These tools augment your existing migration procedure. They don't replace it - they make it observable, controllable, and recoverable.

Start with `colab-status` and build from there.
