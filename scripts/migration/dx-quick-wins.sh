#!/bin/bash
# dx-quick-wins.sh - Quick DX improvements from .stems/ methodology
#
# PURPOSE: Implement high-impact observability and control patterns
# EFFORT: 2-3 hours total, use individually as needed
# SOURCE: /home/crtr/Projects/crtr-config/docs/DX-INSIGHTS-FROM-STEMS.md

set -euo pipefail

# =============================================================================
# QUICK WIN 1: Observable System Status (Progressive Disclosure Level 1)
# =============================================================================
# Shows WHAT, not HOW - understandable at a glance

colab_status() {
    echo "=== Cooperator Status ==="
    echo ""

    # Boot device (immediate context)
    boot_device=$(lsblk | grep "/" | awk '{print $1}')
    if [[ "$boot_device" =~ "mmcblk0" ]]; then
        echo "Boot: SD Card (Debian) [ORIGINAL]"
    elif [[ "$boot_device" =~ "sdb" ]]; then
        echo "Boot: USB Drive (RasPi OS) [MIGRATED]"
    else
        echo "Boot: UNKNOWN ($boot_device)"
    fi

    # Service summary
    running_services=$(systemctl list-units --type=service --state=running | grep -c ".service" || echo "0")
    echo "Services: $running_services running"

    # Docker summary
    running_containers=$(docker ps --filter "status=running" --quiet | wc -l)
    echo "Docker: $running_containers containers"

    # Storage
    if df -h | grep -q cluster-nas; then
        nas_usage=$(df -h /cluster-nas | tail -1 | awk '{print $5}')
        echo "Storage: /cluster-nas mounted ($nas_usage used)"
    else
        echo "Storage: /cluster-nas NOT MOUNTED"
    fi

    # Network
    if dig @localhost n8n.ism.la +short &>/dev/null; then
        echo "DNS: Resolving .ism.la domains"
    else
        echo "DNS: NOT RESOLVING"
    fi

    # Recent errors
    error_count=$(journalctl -p err --since "1 hour ago" --no-pager 2>/dev/null | grep -c "^" || echo "0")
    if [ "$error_count" -eq 0 ]; then
        echo "Errors: None (last hour)"
    else
        echo "Errors: $error_count logged (last hour)"
    fi

    echo ""
    echo "For details: colab-status-full"
}

# =============================================================================
# QUICK WIN 2: Detailed Status (Progressive Disclosure Level 2)
# =============================================================================

colab_status_services() {
    echo "=== Service Details ==="
    echo ""

    services=(caddy pihole-FTL docker nfs-kernel-server)

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            status="[RUNNING]"
        else
            status="[STOPPED]"
        fi

        case $service in
            caddy) purpose="Reverse proxy (HTTPS gateway)" ;;
            pihole-FTL) purpose="DNS resolver (.ism.la domains)" ;;
            docker) purpose="Container runtime" ;;
            nfs-kernel-server) purpose="NFS server (cluster storage)" ;;
            *) purpose="" ;;
        esac

        echo "$status $service - $purpose"
    done

    echo ""
    echo "Docker Containers:"
    if docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | tail -n +2 | grep -q .; then
        docker ps --format "  {{.Names}}: {{.Status}}"
    else
        echo "  (none running)"
    fi
}

# =============================================================================
# QUICK WIN 3: Full Diagnostic (Progressive Disclosure Level 3)
# =============================================================================

colab_status_full() {
    echo "=== Full System Diagnostic ==="
    echo ""

    echo "--- System ---"
    uptime
    echo ""
    df -h /cluster-nas 2>/dev/null || echo "/cluster-nas not mounted"
    echo ""

    echo "--- Boot Device ---"
    lsblk | grep -E "NAME|mmcblk0|sdb"
    echo ""

    echo "--- Services ---"
    systemctl --failed --no-pager
    echo ""
    colab_status_services
    echo ""

    echo "--- Network ---"
    echo "Internal IPs:"
    ip -4 addr show eth0 2>/dev/null | grep inet || echo "  No eth0"
    echo ""
    echo "DNS Resolution:"
    for domain in n8n.ism.la dns.ism.la smp.ism.la; do
        ip=$(dig @localhost +short "$domain" 2>/dev/null)
        if [ -n "$ip" ]; then
            echo "  $domain → $ip"
        else
            echo "  $domain: FAIL"
        fi
    done
    echo ""

    echo "--- Recent Errors ---"
    journalctl -p err --since "1 hour ago" -n 10 --no-pager 2>/dev/null | grep -v "^--" || echo "None"
}

# =============================================================================
# QUICK WIN 4: Pre-Flight Checklist (Observable Validation)
# =============================================================================

pre_flight_check() {
    echo "=== Pre-Flight Check ==="
    echo ""

    pass_count=0
    fail_count=0

    # Check 1: USB device present
    echo -n "[....] Checking USB device..."
    if lsblk | grep -q sdb; then
        echo -e "\r[PASS] USB device connected (/dev/sdb)"
        ((pass_count++))
    else
        echo -e "\r[FAIL] USB device not found"
        ((fail_count++))
    fi

    # Check 2: State files valid
    echo -n "[....] Validating state files..."
    if [ -f ./.meta/validation/validate.sh ]; then
        if ./.meta/validation/validate.sh &>/dev/null; then
            echo -e "\r[PASS] State files valid"
            ((pass_count++))
        else
            echo -e "\r[FAIL] State validation failed"
            ((fail_count++))
        fi
    else
        echo -e "\r[SKIP] Validation script not found"
    fi

    # Check 3: NVMe mounted
    echo -n "[....] Checking NVMe mount..."
    if df -h | grep -q cluster-nas; then
        echo -e "\r[PASS] /cluster-nas mounted"
        ((pass_count++))
    else
        echo -e "\r[FAIL] /cluster-nas not mounted"
        ((fail_count++))
    fi

    # Check 4: Backup exists
    echo -n "[....] Checking backups..."
    if [ -d /cluster-nas/backups ]; then
        backup_count=$(find /cluster-nas/backups -type f -name "*.tar.gz" 2>/dev/null | wc -l)
        echo -e "\r[PASS] Found $backup_count backup files"
        ((pass_count++))
    else
        echo -e "\r[FAIL] Backup directory not found"
        ((fail_count++))
    fi

    # Check 5: Currently on SD
    echo -n "[....] Checking boot device..."
    if lsblk | grep "/" | grep -q mmcblk0; then
        echo -e "\r[PASS] Booted from SD (ready to migrate)"
        ((pass_count++))
    else
        echo -e "\r[WARN] Not on SD (already migrated or unexpected device)"
        ((fail_count++))
    fi

    # Results
    echo ""
    echo "Results: $pass_count passed, $fail_count failed"
    echo ""

    if [ $fail_count -eq 0 ]; then
        echo "Status: READY TO PROCEED ✓"
        return 0
    else
        echo "Status: NOT READY - fix failures above"
        return 1
    fi
}

# =============================================================================
# QUICK WIN 5: Migration Progress Tracker
# =============================================================================

PROGRESS_LOG="/tmp/migration-progress.log"

log_progress() {
    local phase="$1"
    local description="$2"
    echo "$(date +"%Y-%m-%d %H:%M:%S")|$phase|$description" >> "$PROGRESS_LOG"
    echo "[LOGGED] $phase: $description"
}

show_progress() {
    if [ ! -f "$PROGRESS_LOG" ]; then
        echo "No migration progress logged yet"
        return
    fi

    echo "=== Migration Progress ==="
    echo ""
    echo "Timestamp          | Phase        | Description"
    echo "-------------------+--------------+---------------------------"

    while IFS='|' read -r timestamp phase description; do
        printf "%-18s | %-12s | %s\n" "$timestamp" "$phase" "$description"
    done < "$PROGRESS_LOG"

    echo ""
    echo "Log file: $PROGRESS_LOG"
}

clear_progress() {
    if [ -f "$PROGRESS_LOG" ]; then
        rm "$PROGRESS_LOG"
        echo "Progress log cleared"
    else
        echo "No progress log to clear"
    fi
}

# =============================================================================
# QUICK WIN 6: Emergency Rollback Helper
# =============================================================================

emergency_rollback() {
    echo "╔════════════════════════════════════════════════╗"
    echo "║         EMERGENCY ROLLBACK                     ║"
    echo "╚════════════════════════════════════════════════╝"
    echo ""
    echo "This will:"
    echo "  1. Stop all services gracefully"
    echo "  2. Flush disk writes"
    echo "  3. Shutdown the system"
    echo ""
    echo "After shutdown:"
    echo "  1. Access BIOS (hold SHIFT during boot)"
    echo "  2. Change boot order: SD first, USB second"
    echo "  3. Save and reboot"
    echo ""
    echo "Recovery time: ~5 minutes"
    echo "Data loss: NONE (all data on /cluster-nas)"
    echo ""

    read -p "Proceed with shutdown? [y/N] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Rollback cancelled"
        return 1
    fi

    echo ""
    echo "Shutting down in 10 seconds... (Ctrl+C to cancel)"
    sleep 10

    echo "Stopping services..."
    sudo systemctl stop caddy pihole-FTL docker 2>/dev/null || true

    echo "Stopping Docker containers..."
    if [ -f /cluster-nas/services/n8n/docker-compose.yml ]; then
        docker compose -f /cluster-nas/services/n8n/docker-compose.yml down 2>/dev/null || true
    fi

    echo "Flushing writes..."
    sync

    echo "Powering off..."
    sudo shutdown -h now
}

# =============================================================================
# QUICK WIN 7: Rollback Decision Advisor
# =============================================================================

rollback_advisor() {
    echo "=== Rollback Advisor ==="
    echo ""
    echo "What's the problem?"
    echo ""
    echo "1) Single service not working (e.g., Caddy down)"
    echo "2) Multiple services failing"
    echo "3) DNS not resolving"
    echo "4) System accessible but errors present"
    echo "5) Cannot access system at all"
    echo "6) Suspected data corruption"
    echo ""
    read -p "Choose option [1-6]: " choice

    echo ""

    case $choice in
        1)
            echo "RECOMMENDED: Service Restart"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Risk: None"
            echo "Time: 30 seconds"
            echo ""
            echo "Command:"
            echo "  sudo systemctl restart <service>"
            echo ""
            echo "Example:"
            echo "  sudo systemctl restart caddy"
            ;;
        2)
            echo "RECOMMENDED: Full Service Restart"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Risk: Low (brief service interruption)"
            echo "Time: 1-2 minutes"
            echo ""
            echo "Command:"
            echo "  sudo systemctl restart caddy pihole-FTL docker"
            ;;
        3)
            echo "RECOMMENDED: DNS Service Restart"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Risk: None"
            echo "Time: 10 seconds"
            echo ""
            echo "Command:"
            echo "  sudo systemctl restart pihole-FTL"
            echo ""
            echo "Verify:"
            echo "  dig @localhost n8n.ism.la +short"
            ;;
        4)
            echo "RECOMMENDED: Review Logs First"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Risk: None (investigation only)"
            echo "Time: 5 minutes"
            echo ""
            echo "Commands:"
            echo "  journalctl -p err --since '1 hour ago'"
            echo "  docker ps -a"
            echo "  systemctl --failed"
            ;;
        5)
            echo "RECOMMENDED: Full OS Rollback"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Risk: None (SD unchanged)"
            echo "Time: 5 minutes"
            echo ""
            echo "Command:"
            echo "  emergency-rollback"
            echo ""
            echo "This function will guide you through shutdown"
            echo "and provide BIOS instructions."
            ;;
        6)
            echo "WARNING: Data Corruption Suspected"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "DO NOT ROLLBACK - investigate first:"
            echo ""
            echo "1. Check /cluster-nas integrity:"
            echo "   df -h /cluster-nas"
            echo "   ls -la /cluster-nas"
            echo ""
            echo "2. Verify recent backups:"
            echo "   ls -lh /cluster-nas/backups/"
            echo ""
            echo "3. Check filesystem:"
            echo "   sudo xfs_repair -n /dev/nvme0n1p1"
            echo ""
            echo "OS rollback won't fix data issues."
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# =============================================================================
# QUICK WIN 8: Service Health Check (Observability)
# =============================================================================

check_service_health() {
    local service="$1"

    echo "Checking $service..."

    # Is it running?
    if systemctl is-active --quiet "$service"; then
        echo "  [✓] Status: Running"
    else
        echo "  [✗] Status: Stopped"
        echo "  Fix: sudo systemctl start $service"
        return 1
    fi

    # Is it enabled?
    if systemctl is-enabled --quiet "$service"; then
        echo "  [✓] Enabled: Yes (starts on boot)"
    else
        echo "  [!] Enabled: No (won't start on boot)"
        echo "  Fix: sudo systemctl enable $service"
    fi

    # Any recent errors?
    error_count=$(journalctl -u "$service" -p err --since "1 hour ago" --no-pager 2>/dev/null | grep -c "^" || echo "0")
    if [ "$error_count" -eq 0 ]; then
        echo "  [✓] Errors: None (last hour)"
    else
        echo "  [!] Errors: $error_count logged (last hour)"
        echo "  View: journalctl -u $service -p err --since '1 hour ago'"
    fi

    # Service-specific checks
    case $service in
        caddy)
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:2019/config/ | grep -q "200"; then
                echo "  [✓] API: Responding (http://localhost:2019)"
            else
                echo "  [!] API: Not responding"
            fi
            ;;
        pihole-FTL)
            if dig @localhost +short google.com &>/dev/null; then
                echo "  [✓] DNS: Resolving queries"
            else
                echo "  [✗] DNS: Not resolving"
            fi
            ;;
        docker)
            container_count=$(docker ps --quiet | wc -l)
            echo "  [✓] Containers: $container_count running"
            ;;
    esac

    echo ""
}

# =============================================================================
# Main Command Router
# =============================================================================

usage() {
    cat << 'EOF'
DX Quick Wins - Observability & Control Tools

Usage: dx-quick-wins.sh <command>

Commands:
  status              Quick system status (Level 1)
  status-services     Detailed service status (Level 2)
  status-full         Full diagnostic (Level 3)

  pre-flight          Pre-migration validation checklist
  check <service>     Check specific service health

  log <phase> <msg>   Log migration progress
  progress            Show migration progress
  clear-progress      Clear migration log

  rollback            Emergency rollback helper
  advisor             Rollback decision advisor

Examples:
  ./dx-quick-wins.sh status
  ./dx-quick-wins.sh pre-flight
  ./dx-quick-wins.sh log "phase1" "State validated"
  ./dx-quick-wins.sh check caddy
  ./dx-quick-wins.sh advisor

Install to ~/.bashrc:
  source /path/to/dx-quick-wins.sh

Then use directly:
  colab-status
  pre-flight-check
  emergency-rollback
EOF
}

# Command routing
case "${1:-}" in
    status)
        colab_status
        ;;
    status-services)
        colab_status_services
        ;;
    status-full)
        colab_status_full
        ;;
    pre-flight)
        pre_flight_check
        ;;
    check)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 check <service>"
            exit 1
        fi
        check_service_health "$2"
        ;;
    log)
        if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
            echo "Usage: $0 log <phase> <description>"
            exit 1
        fi
        log_progress "$2" "$3"
        ;;
    progress)
        show_progress
        ;;
    clear-progress)
        clear_progress
        ;;
    rollback)
        emergency_rollback
        ;;
    advisor)
        rollback_advisor
        ;;
    help|--help|-h)
        usage
        ;;
    "")
        echo "Error: No command specified"
        echo ""
        usage
        exit 1
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        usage
        exit 1
        ;;
esac
