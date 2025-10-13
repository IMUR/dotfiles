# DX Insights from .stems/ for Fresh OS Migration

**Extracted from**: `/home/crtr/Projects/crtr-config/.stems/` methodology
**Applied to**: Raspberry Pi OS migration (Debian SD → RasPi OS USB)
**Focus**: Human-in-the-loop, observable, recoverable migration

---

## Executive Summary

The `.stems/` methodology provides 5 critical DX patterns for migration:

1. **Progressive Disclosure** - Simple tasks stay simple, complexity reveals on-demand
2. **Explicit Approval Gates** - Human control at decision points
3. **Observability First** - System explains itself without investigation
4. **Recovery Over Prevention** - Fast rollback beats perfect execution
5. **Self-Documenting Configuration** - Config files explain their purpose

These principles transform the migration from a "run script and hope" process into a **transparent, controllable, confidence-building workflow**.

---

## 1. Progressive Disclosure (PRINCIPLES O2)

### The Problem
Traditional migration scripts are monolithic: you either run everything or nothing. Simple checks require reading complex code.

### The .stems/ Pattern
**"Simple tasks remain simple, advanced features available but not required"**

### Application to Migration

#### Before (Monolithic)
```bash
./migrate.sh  # What does this do? How long will it take? Can I stop midway?
```

#### After (Progressive Disclosure)
```bash
# Level 1: Simple health check
./health-check.sh
# Output: "3/5 services healthy, NFS down (expected), DNS working"

# Level 2: Detailed inspection (only if needed)
./health-check.sh --verbose
# Shows: service logs, port status, disk usage, network connectivity

# Level 3: Full diagnostic (only when troubleshooting)
./health-check.sh --debug
# Shows: systemd unit analysis, docker inspect, strace output
```

### Quick Win: Layered Migration Commands

**Create command hierarchy**:

```bash
# migration/commands.sh

# Simple: Status overview
colab-status() {
    echo "Cooperator Status:"
    echo "Boot device: $(lsblk | grep "/" | awk '{print $1}')"
    echo "Services: $(systemctl list-units --type=service --state=running | wc -l) running"
    echo "Docker: $(docker ps --filter 'status=running' | wc -l) containers"
    echo "NFS: $(showmount -e localhost 2>/dev/null | tail -n +2 | wc -l) exports"
}

# Medium: Service-level details
colab-status-services() {
    systemctl status caddy pihole-FTL docker nfs-kernel-server --no-pager
}

# Advanced: Full diagnostic
colab-status-full() {
    echo "=== System ==="
    uptime
    df -h /cluster-nas
    echo -e "\n=== Services ==="
    systemctl --failed
    echo -e "\n=== Network ==="
    dig @localhost n8n.ism.la +short
    echo -e "\n=== Docker ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo -e "\n=== Recent Errors ==="
    journalctl -p err -n 10 --no-pager
}
```

**Usage**:
```bash
# Quick check during migration
colab-status
# Output: "4/5 services, Docker running, DNS resolving"

# Detailed investigation only when needed
colab-status-full
```

---

## 2. Human Approval Gates (METHODOLOGY Phase 3)

### The Problem
Automation removes control. You want to verify each step before proceeding, not "run and hope".

### The .stems/ Pattern
**"Explicit approval for system-level changes, automatic approval for safe operations"**

From `LIFECYCLE.md`:
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

### Application to Migration

#### Critical Decision Points

**Gate 1: Pre-Migration State Validation**
```bash
# scripts/migration/gate-1-validate-state.sh
#!/bin/bash

echo "=== Gate 1: State Validation ==="
echo ""
echo "Checking current system state..."

# Automatic checks
echo "[AUTO] Validating YAML syntax..."
./.meta/validation/validate.sh || exit 1

echo "[AUTO] Generating configs from state..."
./scripts/generate/regenerate-all.sh || exit 1

echo "[AUTO] Comparing live vs generated..."
diff -u /etc/caddy/Caddyfile config/caddy/Caddyfile

# Manual approval gate
echo ""
echo "Generated configs match live system: $(diff /etc/caddy/Caddyfile config/caddy/Caddyfile &>/dev/null && echo 'YES' || echo 'NO')"
echo ""
read -p "Proceed to USB preparation? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted at Gate 1"; exit 1; }
echo "Gate 1: APPROVED"
```

**Gate 2: USB Configuration Review**
```bash
# scripts/migration/gate-2-review-usb.sh
#!/bin/bash

echo "=== Gate 2: USB Configuration Review ==="
echo ""
echo "USB drive prepared with:"
echo "  - Hostname: cooperator"
echo "  - Static IP: 192.168.254.10"
echo "  - SSH keys: $(ls /mnt/usb-root/home/pi/.ssh/authorized_keys 2>/dev/null && echo 'copied' || echo 'MISSING')"
echo "  - NVMe mount: $(grep cluster-nas /mnt/usb-root/etc/fstab | wc -l) entry"
echo ""
echo "Reviewing fstab:"
grep cluster-nas /mnt/usb-root/etc/fstab
echo ""
read -p "Configuration looks correct? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted at Gate 2"; exit 1; }
echo "Gate 2: APPROVED"
```

**Gate 3: Service Verification Before Cutover**
```bash
# scripts/migration/gate-3-verify-services.sh
#!/bin/bash

echo "=== Gate 3: Service Verification (USB) ==="
echo ""
echo "Testing services on USB system before cutover..."

# Automatic checks
services=(caddy pihole-FTL docker nfs-kernel-server)
all_healthy=true

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "[OK] $service: running"
    else
        echo "[FAIL] $service: not running"
        all_healthy=false
    fi
done

# Test connectivity
echo ""
echo "Testing DNS resolution:"
dns_result=$(dig @localhost n8n.ism.la +short)
[ -n "$dns_result" ] && echo "[OK] DNS resolving" || { echo "[FAIL] DNS not working"; all_healthy=false; }

echo ""
echo "Testing HTTPS endpoints:"
for domain in n8n.ism.la dns.ism.la smp.ism.la; do
    if curl -s -o /dev/null -w "%{http_code}" "https://$domain" | grep -q "^[23]"; then
        echo "[OK] $domain: responding"
    else
        echo "[FAIL] $domain: not responding"
        all_healthy=false
    fi
done

# Manual approval gate
echo ""
if [ "$all_healthy" = true ]; then
    echo "All checks passed. USB system ready for production."
else
    echo "WARNINGS DETECTED. Review failures above."
fi
echo ""
read -p "Proceed with cutover to USB system? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted at Gate 3"; exit 1; }
echo "Gate 3: APPROVED - proceeding to cutover"
```

**Gate 4: Final Cutover Confirmation**
```bash
# scripts/migration/gate-4-final-cutover.sh
#!/bin/bash

echo "=== Gate 4: FINAL CUTOVER ==="
echo ""
echo "WARNING: This will stop services on SD and boot to USB."
echo ""
echo "Current state:"
echo "  - SD system: PRODUCTION (serving traffic)"
echo "  - USB system: TESTED (ready to go)"
echo "  - Rollback: Change boot order, 5 min recovery"
echo ""
echo "Downtime estimate: 5-10 minutes"
echo ""
read -p "Execute cutover NOW? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || { echo "Cutover cancelled"; exit 1; }

echo ""
read -p "Are you ABSOLUTELY SURE? [yes/no] " answer
[[ "$answer" == "yes" ]] || { echo "Cutover cancelled"; exit 1; }

echo "Gate 4: APPROVED - executing cutover..."
```

### Quick Win: Migration Checkpoint Script

```bash
#!/bin/bash
# migration-checklist.sh - Interactive checkpoint tracker

checkpoints=(
    "1|validate|State files validated"
    "2|usb-prep|USB drive prepared"
    "3|usb-test|USB system tested"
    "4|cutover|Production cutover"
    "5|verify|Post-cutover verification"
)

for checkpoint in "${checkpoints[@]}"; do
    IFS='|' read -r num name desc <<< "$checkpoint"

    echo ""
    echo "Checkpoint $num: $desc"
    echo "==============="

    read -p "Complete this checkpoint? [y/N] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[DONE] $name: $(date)" >> /tmp/migration-progress.log
        echo "Checkpoint $num: COMPLETE"
    else
        echo "Migration paused at checkpoint $num"
        echo "Resume with: ./migration-checklist.sh"
        exit 0
    fi
done

echo ""
echo "=== MIGRATION COMPLETE ==="
cat /tmp/migration-progress.log
```

---

## 3. Observability Over Debugging (PRINCIPLES O4)

### The Problem
Traditional migrations fail silently or with cryptic errors. You discover problems after the fact.

### The .stems/ Pattern
**"Systems should explain themselves without investigation"**

From `PRINCIPLES.md`:
```yaml
observability:
  - Validation output is comprehensive
  - Changes shown before application
  - Logs capture all activities
  - State is always discoverable
```

### Application to Migration

#### Self-Explaining Status Display

```bash
#!/bin/bash
# migration-status.sh - Observable state display

echo "=== Cooperator Migration Status ==="
echo ""

# Boot device (immediate context)
boot_device=$(lsblk | grep "/" | awk '{print $1}')
if [[ "$boot_device" =~ "mmcblk0" ]]; then
    echo "Boot Device: SD Card (Debian) - ORIGINAL"
elif [[ "$boot_device" =~ "sdb" ]]; then
    echo "Boot Device: USB Drive (RasPi OS) - MIGRATED"
else
    echo "Boot Device: UNKNOWN ($boot_device)"
fi

# OS Detection
os_name=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
echo "OS: $os_name"

# Service health (self-explanatory)
echo ""
echo "Service Health:"
echo "---------------"

declare -A service_purposes=(
    ["caddy"]="Reverse proxy (HTTPS gateway)"
    ["pihole-FTL"]="DNS resolver (local .ism.la domains)"
    ["docker"]="Container runtime (n8n, etc)"
    ["nfs-kernel-server"]="NFS server (cluster storage)"
)

for service in caddy pihole-FTL docker nfs-kernel-server; do
    if systemctl is-active --quiet "$service"; then
        echo "[RUNNING] $service - ${service_purposes[$service]}"
    else
        echo "[STOPPED] $service - ${service_purposes[$service]}"
    fi
done

# Docker containers (with purpose)
echo ""
echo "Docker Containers:"
echo "------------------"
docker ps --format "{{.Names}}: {{.Status}}" | while read -r line; do
    container=$(echo "$line" | cut -d: -f1)
    status=$(echo "$line" | cut -d: -f2-)

    case $container in
        n8n*) purpose="Workflow automation" ;;
        *) purpose="Unknown purpose" ;;
    esac

    echo "$container$status - $purpose"
done

# Storage (self-documenting)
echo ""
echo "Storage:"
echo "--------"
nvme_mounted=$(df -h | grep cluster-nas)
if [ -n "$nvme_mounted" ]; then
    echo "[OK] /cluster-nas mounted"
    df -h /cluster-nas | tail -1 | awk '{print "     Used: "$3" / "$2" ("$5")"}'
else
    echo "[FAIL] /cluster-nas NOT mounted"
fi

# Network (DNS resolution check)
echo ""
echo "Network:"
echo "--------"
for domain in n8n.ism.la dns.ism.la; do
    ip=$(dig @localhost +short "$domain" 2>/dev/null)
    if [ -n "$ip" ]; then
        echo "[OK] $domain → $ip"
    else
        echo "[FAIL] $domain: not resolving"
    fi
done

# Recent errors (surface problems immediately)
echo ""
echo "Recent Errors (last hour):"
echo "--------------------------"
error_count=$(journalctl -p err --since "1 hour ago" --no-pager 2>/dev/null | grep -c "^")
if [ "$error_count" -eq 0 ]; then
    echo "[OK] No errors logged"
else
    echo "[WARNING] $error_count errors found"
    echo "View with: journalctl -p err --since '1 hour ago'"
fi

# Migration phase detection
echo ""
echo "Migration Phase:"
echo "----------------"
if [[ "$boot_device" =~ "mmcblk0" ]]; then
    if [ -d /mnt/usb-root ]; then
        echo "Phase: USB PREPARATION (SD running, USB being configured)"
    else
        echo "Phase: PRE-MIGRATION (SD running, USB not prepared)"
    fi
elif [[ "$boot_device" =~ "sdb" ]]; then
    echo "Phase: POST-MIGRATION (USB running in production)"
else
    echo "Phase: UNKNOWN"
fi

echo ""
echo "Last updated: $(date)"
```

**Output example**:
```
=== Cooperator Migration Status ===

Boot Device: USB Drive (RasPi OS) - MIGRATED
OS: Raspberry Pi OS GNU/Linux 12 (bookworm)

Service Health:
---------------
[RUNNING] caddy - Reverse proxy (HTTPS gateway)
[RUNNING] pihole-FTL - DNS resolver (local .ism.la domains)
[RUNNING] docker - Container runtime (n8n, etc)
[RUNNING] nfs-kernel-server - NFS server (cluster storage)

Docker Containers:
------------------
n8n: Up 2 hours - Workflow automation

Storage:
--------
[OK] /cluster-nas mounted
     Used: 1.2T / 1.8T (67%)

Network:
--------
[OK] n8n.ism.la → 192.168.254.10
[OK] dns.ism.la → 192.168.254.10

Recent Errors (last hour):
--------------------------
[OK] No errors logged

Migration Phase:
----------------
Phase: POST-MIGRATION (USB running in production)

Last updated: Mon Oct 13 15:42:33 UTC 2025
```

### Quick Win: Pre-Flight Checklist with Live Validation

```bash
#!/bin/bash
# pre-flight-check.sh - Observable pre-migration validation

echo "=== Pre-Flight Check ==="
echo ""

checks=(
    "USB drive connected|lsblk | grep -q sdb"
    "USB drive has RasPi OS|grep -q 'Raspberry Pi OS' /mnt/usb-root/etc/os-release"
    "SSH keys copied to USB|[ -f /mnt/usb-root/home/pi/.ssh/authorized_keys ]"
    "NVMe backup exists|[ -f /cluster-nas/backups/latest/nvme-backup.tar.gz ]"
    "State files validated|./.meta/validation/validate.sh &>/dev/null"
    "SD card currently booted|lsblk | grep '/$' | grep -q mmcblk0"
)

pass_count=0
fail_count=0

for check in "${checks[@]}"; do
    IFS='|' read -r desc command <<< "$check"

    if eval "$command"; then
        echo "[PASS] $desc"
        ((pass_count++))
    else
        echo "[FAIL] $desc"
        ((fail_count++))
    fi
done

echo ""
echo "Results: $pass_count passed, $fail_count failed"

if [ $fail_count -gt 0 ]; then
    echo "Status: NOT READY - fix failures above"
    exit 1
else
    echo "Status: READY TO PROCEED"
    exit 0
fi
```

---

## 4. Recovery Over Prevention (PRINCIPLES O5)

### The Problem
Perfect execution is impossible. You need fast recovery, not flawless plans.

### The .stems/ Pattern
**"Fast rollback is better than perfect prevention"**

From `PRINCIPLES.md`:
```yaml
recovery:
  - Git provides instant rollback
  - Previous states always recoverable
  - Partial failures don't cascade
  - Learn from failures, don't fear them
```

### Application to Migration

#### Instant Rollback Procedure

```bash
#!/bin/bash
# emergency-rollback.sh - One-command recovery

echo "=== EMERGENCY ROLLBACK ==="
echo ""
echo "This will:"
echo "  1. Shutdown USB system"
echo "  2. Boot back to SD card"
echo "  3. Restore service within 5 minutes"
echo ""

read -p "Execute rollback? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 0

echo ""
echo "Step 1: Stopping services gracefully..."
sudo systemctl stop caddy pihole-FTL docker
docker compose -f /cluster-nas/services/n8n/docker-compose.yml down

echo "Step 2: Flushing writes..."
sync

echo "Step 3: Shutting down..."
sudo shutdown -h now

# After physical boot order change and power on:
# System will boot from SD card
# All services will start automatically
# /cluster-nas will mount (same NVMe drive)
# Zero data loss
```

**Rollback documentation** (paste into terminal):
```bash
# ROLLBACK INSTRUCTIONS (if script fails)
# =======================================

# Physical steps:
# 1. Power off the Pi
# 2. Access BIOS (hold SHIFT during boot)
# 3. Change boot order: SD first, USB second
# 4. Save and reboot

# Verification (after SD boots):
lsblk | grep "/"  # Should show mmcblk0p2
systemctl status caddy docker  # Should be active
curl -I https://n8n.ism.la  # Should respond

# Rollback time: ~5 minutes
# Data loss: NONE (all data on /cluster-nas NVMe)
```

#### Progressive Rollback Levels

```bash
# Level 1: Service-only rollback (keep USB)
sudo systemctl restart caddy pihole-FTL docker
# Time: 30 seconds

# Level 2: Configuration rollback (keep USB)
cd ~/Projects/crtr-config
git checkout HEAD~1  # Previous config
./scripts/generate/regenerate-all.sh
sudo cp config/caddy/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
# Time: 2 minutes

# Level 3: Full OS rollback (back to SD)
sudo shutdown -h now
# Change boot order → SD first
# Power on
# Time: 5 minutes
```

### Quick Win: Rollback Decision Tree

```bash
#!/bin/bash
# rollback-advisor.sh - Guides recovery decisions

echo "=== Rollback Advisor ==="
echo ""
echo "What's the problem?"
echo ""
echo "1) Single service not working (e.g., Caddy down)"
echo "2) Multiple services failing"
echo "3) DNS not resolving"
echo "4) Can't access system at all"
echo "5) Data corruption suspected"
echo ""
read -p "Choose option [1-5]: " -n 1 -r
echo

case $REPLY in
    1)
        echo ""
        echo "Recommended: SERVICE RESTART"
        echo "Command: sudo systemctl restart <service>"
        echo "Risk: None"
        echo "Time: 30 seconds"
        ;;
    2)
        echo ""
        echo "Recommended: CONFIGURATION ROLLBACK"
        echo "Command: git checkout HEAD~1 && regenerate configs"
        echo "Risk: Low (config changes only)"
        echo "Time: 2 minutes"
        ;;
    3)
        echo ""
        echo "Recommended: DNS SERVICE RESTART"
        echo "Command: sudo systemctl restart pihole-FTL"
        echo "Risk: None"
        echo "Time: 10 seconds"
        ;;
    4)
        echo ""
        echo "Recommended: FULL OS ROLLBACK TO SD"
        echo "Command: ./emergency-rollback.sh"
        echo "Risk: None (SD unchanged)"
        echo "Time: 5 minutes"
        ;;
    5)
        echo ""
        echo "Recommended: STOP - DO NOT ROLLBACK"
        echo "Action: Investigate /cluster-nas, verify backups"
        echo "Risk: High if you proceed without diagnosis"
        echo "Note: OS rollback won't fix data issues"
        ;;
esac
```

---

## 5. Self-Documenting Configuration (METHODOLOGY)

### The Problem
Configuration files are opaque. Why does this setting exist? What happens if I change it?

### The .stems/ Pattern
**"Configuration is data, documentation embedded in templates"**

From `CLUSTER-PATTERNS.md`:
```yaml
# Template with documentation
# Purpose: Configure cluster networking
# Dependency: Requires static IPs assigned
# Last-Updated: 2025-01-27
# Author: Infrastructure Team
```

### Application to Migration

#### Self-Documenting State Files

**Before** (`state/services.yml`):
```yaml
services:
  caddy:
    type: systemd
    enabled: true
```

**After** (self-documenting):
```yaml
# =============================================================================
# SERVICE DEFINITIONS - Source of Truth
# =============================================================================
# Last validated: 2025-10-13
# Migration phase: USB system (Raspberry Pi OS)
#
# IMPORTANT: These definitions generate actual service configs.
# After editing:
#   1. Validate: ./.meta/validation/validate.sh
#   2. Generate: ./scripts/generate/regenerate-all.sh
#   3. Review: git diff config/
#   4. Deploy: ./deploy/deploy service <name>
#
# DO NOT edit generated configs directly. Always edit this file.
# =============================================================================

services:
  caddy:
    type: systemd
    enabled: true

    # Purpose: Reverse proxy for all HTTPS services
    # Port: 80 (HTTP), 443 (HTTPS), 2019 (admin API)
    # Config: /etc/caddy/Caddyfile (generated from state/domains.yml)
    # Logs: journalctl -u caddy
    #
    # Dependencies:
    #   - DNS (pihole-FTL) must resolve *.ism.la domains
    #   - Backend services must bind to 127.0.0.1:<port>
    #
    # Troubleshooting:
    #   - 502 Bad Gateway → Backend service not running
    #   - 404 Not Found → Domain not in state/domains.yml
    #   - Cert errors → Check Caddy logs for ACME challenges

  pihole-FTL:
    type: systemd
    enabled: true

    # Purpose: DNS resolver with local domain overrides
    # Port: 53 (DNS), 4711 (FTL API)
    # Config: /etc/dnsmasq.d/02-custom-local-dns.conf (generated)
    # Admin: http://dns.ism.la/admin
    #
    # Why Pi-hole:
    #   - Provides DNS for .ism.la local domains
    #   - Routes n8n.ism.la → 192.168.254.10 (this node)
    #   - Ad-blocking as bonus
    #
    # Critical: All cluster nodes must use 192.168.254.10 as DNS
```

#### Self-Documenting Migration Scripts

```bash
#!/bin/bash
# scripts/migration/usb-setup.sh
#
# PURPOSE
# =======
# Prepares USB drive with Raspberry Pi OS for cooperator migration.
# Configures hostname, SSH, network, and NVMe mount BEFORE first boot.
#
# WHEN TO USE
# ===========
# Run this ONCE after flashing Raspberry Pi OS to USB drive.
# Run from SD card system (source) while USB is connected.
#
# WHAT IT DOES
# ============
# 1. Mounts USB boot and root partitions
# 2. Sets hostname to "cooperator"
# 3. Copies SSH authorized keys
# 4. Configures static IP 192.168.254.10
# 5. Adds /cluster-nas NVMe mount to fstab
# 6. Enables SSH on first boot
#
# WHAT IT DOESN'T DO
# ==================
# - Install packages (done after first boot)
# - Deploy configs (done via state files)
# - Start services (automatic on boot)
#
# PREREQUISITES
# =============
# - USB drive connected as /dev/sdb
# - Raspberry Pi OS already flashed to USB
# - Running on SD card system as user with sudo
#
# SAFETY
# ======
# - SD card not modified (rollback possible)
# - NVMe not touched (data safe)
# - Can re-run if interrupted (idempotent)
#
# VERIFICATION
# ============
# After running, check:
#   - /mnt/usb-root/etc/hostname shows "cooperator"
#   - /mnt/usb-root/home/pi/.ssh/authorized_keys exists
#   - /mnt/usb-root/etc/fstab contains cluster-nas mount
#
# NEXT STEPS
# ==========
# 1. Unmount USB: sudo umount /mnt/usb-boot /mnt/usb-root
# 2. Reboot to USB: sudo reboot (with USB boot priority)
# 3. SSH as pi: ssh pi@192.168.254.10
# 4. Create crtr user and deploy configs
#
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
USB_BOOT_DEV="/dev/sdb1"
USB_ROOT_DEV="/dev/sdb2"
MOUNT_BOOT="/mnt/usb-boot"
MOUNT_ROOT="/mnt/usb-root"
HOSTNAME="cooperator"
STATIC_IP="192.168.254.10/24"
GATEWAY="192.168.254.1"
NVME_UUID="810880b9-6e26-4b18-8246-ca19fd56bc8f"

# Validation functions (self-documenting checks)
validate_usb_device() {
    echo "[CHECK] Validating USB device..."
    if ! lsblk | grep -q sdb; then
        echo "[FAIL] USB device not found at /dev/sdb"
        echo "Available devices:"
        lsblk
        exit 1
    fi
    echo "[PASS] USB device present"
}

validate_not_mounted() {
    echo "[CHECK] Ensuring USB not already mounted..."
    if mount | grep -q "$USB_ROOT_DEV"; then
        echo "[FAIL] USB already mounted, unmount first"
        exit 1
    fi
    echo "[PASS] USB not mounted"
}

# ... rest of script with self-documenting functions
```

### Quick Win: Migration Runbook with Embedded Context

```bash
#!/bin/bash
# migration-runbook.sh - Interactive guide with context

show_context() {
    cat << 'EOF'
┌─────────────────────────────────────────────────────────┐
│  MIGRATION RUNBOOK: Debian SD → Raspberry Pi OS USB    │
├─────────────────────────────────────────────────────────┤
│  Current System:  Debian 13 on SD card (mmcblk0)       │
│  Target System:   Raspberry Pi OS on USB (sdb)         │
│  Data Location:   /cluster-nas (NVMe, unchanged)       │
│  Rollback:        Change boot order, 5 min recovery    │
│  Downtime:        5-10 minutes during cutover          │
└─────────────────────────────────────────────────────────┘

CURRENT STATE:
EOF

    # Live state detection
    boot_dev=$(lsblk | grep "/" | awk '{print $1}')
    echo "  Boot device: $boot_dev"

    if [[ "$boot_dev" =~ "mmcblk0" ]]; then
        echo "  Status: Running on SD (ready to migrate)"
    elif [[ "$boot_dev" =~ "sdb" ]]; then
        echo "  Status: Running on USB (already migrated)"
    fi

    echo ""
}

run_phase() {
    phase_num=$1
    phase_name=$2
    phase_desc=$3
    phase_script=$4

    echo ""
    echo "┌─────────────────────────────────────────────"
    echo "│ Phase $phase_num: $phase_name"
    echo "├─────────────────────────────────────────────"
    echo "│ $phase_desc"
    echo "└─────────────────────────────────────────────"
    echo ""
    echo "Script: $phase_script"
    echo ""
    read -p "Run this phase? [y/N/skip] " -n 1 -r
    echo

    case $REPLY in
        y|Y)
            echo "Running $phase_script..."
            if bash "$phase_script"; then
                echo "[SUCCESS] Phase $phase_num complete"
                echo "phase_${phase_num}|${phase_name}|$(date)" >> /tmp/migration-log.txt
            else
                echo "[FAILED] Phase $phase_num failed"
                echo "Review errors and:"
                echo "  - Fix issue and re-run phase"
                echo "  - Or rollback: ./emergency-rollback.sh"
                exit 1
            fi
            ;;
        s|S)
            echo "Skipping phase $phase_num"
            ;;
        *)
            echo "Exiting at phase $phase_num"
            exit 0
            ;;
    esac
}

# Main runbook
show_context

run_phase 1 "Validate State" \
    "Ensure state files match live system" \
    "./scripts/migration/gate-1-validate-state.sh"

run_phase 2 "Prepare USB" \
    "Configure USB drive before first boot" \
    "./scripts/migration/usb-setup.sh"

run_phase 3 "Test USB System" \
    "Boot USB, install packages, verify services" \
    "./scripts/migration/gate-3-verify-services.sh"

run_phase 4 "Cutover" \
    "Switch from SD to USB (production change)" \
    "./scripts/migration/gate-4-final-cutover.sh"

run_phase 5 "Post-Cutover Verification" \
    "Verify production system healthy" \
    "./scripts/migration/post-cutover-verify.sh"

echo ""
echo "┌─────────────────────────────────────────────"
echo "│  MIGRATION COMPLETE"
echo "├─────────────────────────────────────────────"
echo "│  Log: /tmp/migration-log.txt"
echo "│  Next: Monitor for 24 hours"
echo "└─────────────────────────────────────────────"
```

---

## Implementation Roadmap

### Phase 1: Observability (2-4 hours)
**Goal**: Make current state visible before migration

1. Create `migration-status.sh` (self-explaining system status)
2. Create `pre-flight-check.sh` (observable validation)
3. Test on current SD system
4. Verify output is self-explanatory

**Validation**: Run `migration-status.sh` - should understand system state without reading code.

---

### Phase 2: Approval Gates (2-3 hours)
**Goal**: Add human control at decision points

1. Create `gate-1-validate-state.sh` (pre-migration approval)
2. Create `gate-2-review-usb.sh` (USB config approval)
3. Create `gate-3-verify-services.sh` (pre-cutover approval)
4. Create `gate-4-final-cutover.sh` (cutover approval)
5. Test gates in sequence (skip actual migration)

**Validation**: Each gate should clearly explain what it's checking and why.

---

### Phase 3: Recovery (1-2 hours)
**Goal**: Ensure fast rollback at any point

1. Create `emergency-rollback.sh` (one-command recovery)
2. Document rollback for each migration phase
3. Create `rollback-advisor.sh` (decision tree)
4. Test rollback procedure (without actual cutover)

**Validation**: Rollback documentation should be pasteable into terminal.

---

### Phase 4: Progressive Disclosure (3-4 hours)
**Goal**: Layer migration complexity

1. Create command hierarchy:
   - `colab-status` (simple)
   - `colab-status-services` (medium)
   - `colab-status-full` (advanced)
2. Create `migration-runbook.sh` (interactive guide)
3. Add context displays to each script
4. Test workflow from simple to complex

**Validation**: Simple tasks should remain simple, detail available on-demand.

---

### Phase 5: Self-Documentation (2-3 hours)
**Goal**: Make configuration self-explanatory

1. Add inline documentation to `state/services.yml`
2. Add inline documentation to `state/domains.yml`
3. Add header comments to all migration scripts
4. Document "why" for each configuration choice

**Validation**: New person should understand purpose without asking.

---

## Quick Wins (Immediate Adoption)

### 1. Status Command (30 min)
```bash
# Add to ~/.bashrc
colab-status() {
    echo "Boot: $(lsblk | grep '/' | awk '{print $1}')"
    echo "Services: $(systemctl list-units --state=running --type=service | wc -l) running"
    echo "Docker: $(docker ps -q | wc -l) containers"
    echo "NFS: $(showmount -e localhost 2>/dev/null | tail -n +2 | wc -l) exports"
}
```

**Impact**: Instant system overview, no mental model required.

---

### 2. Pre-Flight Check (1 hour)
Create single script that validates prerequisites:
- USB connected
- SSH keys copied
- State files valid
- Backups present

**Impact**: Catch issues before starting, not during migration.

---

### 3. Emergency Rollback Alias (15 min)
```bash
# Add to ~/.bashrc
alias emergency-rollback='echo "Shutting down in 10s, Ctrl+C to cancel"; sleep 10; sudo shutdown -h now'
```

**Impact**: One command to escape any failure.

---

### 4. Migration Progress Log (30 min)
```bash
#!/bin/bash
# log-progress.sh
echo "$(date)|$1|$2" >> /tmp/migration-progress.log

# Usage
./log-progress.sh "phase1" "State validated"
./log-progress.sh "phase2" "USB prepared"

# View progress
cat /tmp/migration-progress.log
```

**Impact**: Always know where you are in migration.

---

### 5. Context-Rich Error Messages (ongoing)
Replace:
```bash
exit 1  # Cryptic
```

With:
```bash
echo "ERROR: USB device not found"
echo "Expected: /dev/sdb"
echo "Found: $(lsblk | grep disk)"
echo "Fix: Connect USB drive and re-run"
exit 1
```

**Impact**: Errors explain themselves, faster recovery.

---

## Key Takeaways

### From .stems/ to Migration DX

1. **Progressive Disclosure**: Start simple (`colab-status`), reveal detail on-demand (`--verbose`, `--debug`)

2. **Approval Gates**: Human control at each phase, no "run and hope"

3. **Observability**: System explains itself, no investigation needed

4. **Recovery Over Prevention**: Fast rollback (5 min) beats perfect execution

5. **Self-Documentation**: Configuration/scripts explain their purpose inline

### Alignment with Your Migration

Your migration procedure (`/home/crtr/Projects/crtr-config/docs/MIGRATION-PROCEDURE.md`) already follows .stems/ principles:

- **Human-in-the-loop**: Manual verification at each step
- **State-driven**: `state/*.yml` as source of truth
- **Rollback-ready**: SD card untouched, 5-minute recovery
- **Explicit**: Each command documented with purpose

### What .stems/ Adds

- **Observability tooling**: Scripts that explain system state
- **Approval gate scripts**: Formalized checkpoints
- **Progressive commands**: Layered complexity (simple → advanced)
- **Self-documenting configs**: Inline "why" for each setting

---

## Next Steps

1. **Read**: Review this document and mark quick wins to implement
2. **Implement**: Start with Phase 1 (Observability) - highest ROI
3. **Test**: Run new scripts on current SD system (safe)
4. **Refine**: Adjust based on what's actually helpful
5. **Migrate**: Use new tooling during actual migration

**Estimated total effort**: 10-15 hours to implement all phases
**Quick wins**: 2-3 hours for 80% of benefit
**Maintenance**: Scripts are reusable for future migrations

---

**Generated**: 2025-10-13
**Source methodology**: `/home/crtr/Projects/crtr-config/.stems/`
**Applied to**: Cooperator migration (Debian SD → RasPi OS USB)
