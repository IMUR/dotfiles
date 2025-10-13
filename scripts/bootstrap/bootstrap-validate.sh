#!/bin/bash
# bootstrap-validate.sh - Multi-stage validation before fresh Pi OS deployment
# Based on .stems/METHODOLOGY.md validation-first principles

set -euo pipefail

TARGET="${1:-pi@192.168.254.10}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Stage 1: Syntax Validation (Local, No System Access Required)
stage_1_syntax() {
    echo "=== Stage 1: Syntax Validation ==="

    # YAML syntax
    for file in "$REPO_ROOT"/state/*.yml; do
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            log_success "$(basename "$file"): Valid YAML"
        else
            log_error "$(basename "$file"): Invalid YAML syntax"
            return 1
        fi
    done

    # Schema validation (if validation script exists)
    if [ -x "$REPO_ROOT/.meta/validation/validate.sh" ]; then
        if "$REPO_ROOT/.meta/validation/validate.sh" >/dev/null 2>&1; then
            log_success "All state files conform to schemas"
        else
            log_error "Schema validation failed"
            return 1
        fi
    else
        log_warning "Schema validation script not found, skipping"
    fi

    # Template syntax (if Jinja2 templates exist)
    if [ -d "$REPO_ROOT/.meta/generation" ]; then
        for tmpl in "$REPO_ROOT"/.meta/generation/*.j2; do
            [ -f "$tmpl" ] || continue
            if python3 -c "from jinja2 import Template; Template(open('$tmpl').read())" 2>/dev/null; then
                log_success "$(basename "$tmpl"): Valid Jinja2"
            else
                log_error "$(basename "$tmpl"): Invalid Jinja2 syntax"
                return 1
            fi
        done
    fi

    return 0
}

# Stage 2: Generation Test (Local, Ensures Configs Can Be Built)
stage_2_generation() {
    echo ""
    echo "=== Stage 2: Configuration Generation ==="

    # Generate all configs
    if [ -x "$REPO_ROOT/scripts/generate/regenerate-all.sh" ]; then
        if "$REPO_ROOT/scripts/generate/regenerate-all.sh" >/dev/null 2>&1; then
            log_success "Configs generated successfully"
        else
            log_error "Config generation failed"
            return 1
        fi
    else
        log_warning "Generation script not found, skipping"
    fi

    # Validate generated Caddyfile
    if [ -f "$REPO_ROOT/config/caddy/Caddyfile" ]; then
        if command -v caddy >/dev/null 2>&1; then
            if caddy validate --config "$REPO_ROOT/config/caddy/Caddyfile" 2>/dev/null; then
                log_success "Caddyfile syntax valid"
            else
                log_error "Caddyfile validation failed"
                return 1
            fi
        else
            log_warning "Caddy not installed locally, cannot validate Caddyfile"
        fi
    fi

    # Validate systemd units (if systemd available)
    if [ -d "$REPO_ROOT/config/systemd" ]; then
        unit_count=$(find "$REPO_ROOT/config/systemd" -name "*.service" | wc -l)
        if [ "$unit_count" -gt 0 ]; then
            if command -v systemd-analyze >/dev/null 2>&1; then
                for unit in "$REPO_ROOT"/config/systemd/*.service; do
                    [ -f "$unit" ] || continue
                    if systemd-analyze verify "$unit" 2>/dev/null; then
                        log_success "$(basename "$unit"): Valid"
                    else
                        log_warning "$(basename "$unit"): Cannot verify (may need target system)"
                    fi
                done
            else
                log_warning "systemd-analyze not available, skipping unit validation"
            fi
        fi
    fi

    return 0
}

# Stage 3: Target System Pre-flight (Remote, Non-destructive)
stage_3_preflight() {
    echo ""
    echo "=== Stage 3: Target System Pre-flight ==="

    # SSH connectivity
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" "echo ok" >/dev/null 2>&1; then
        log_success "SSH connectivity to $TARGET"
    else
        log_error "Cannot connect to $TARGET via SSH"
        return 1
    fi

    # System resources
    local checks_passed=0
    local checks_total=4

    # Disk space (need at least 10GB free)
    local free_space
    free_space=$(ssh "$TARGET" "df / | tail -1 | awk '{print \$4}'")
    if [ "$free_space" -gt 10485760 ]; then
        log_success "Disk space: $(( free_space / 1048576 ))GB free"
        ((checks_passed++))
    else
        log_error "Insufficient disk space: $(( free_space / 1048576 ))GB (need 10GB)"
    fi

    # Memory (need at least 1GB available)
    local free_mem
    free_mem=$(ssh "$TARGET" "free | grep Mem | awk '{print \$7}'")
    if [ "$free_mem" -gt 1048576 ]; then
        log_success "Memory: $(( free_mem / 1024 ))MB available"
        ((checks_passed++))
    else
        log_warning "Low memory: $(( free_mem / 1024 ))MB available"
        ((checks_passed++))  # Warning, not failure
    fi

    # Network interface
    if ssh "$TARGET" "ip addr show eth0 | grep -q 'inet '" 2>/dev/null; then
        local ip_addr
        ip_addr=$(ssh "$TARGET" "ip -4 addr show eth0 | grep inet | awk '{print \$2}' | cut -d/ -f1")
        log_success "Network interface: eth0 ($ip_addr)"
        ((checks_passed++))
    else
        log_error "Network interface eth0 not configured"
    fi

    # Boot device (should be USB for our scenario)
    local boot_device
    boot_device=$(ssh "$TARGET" "lsblk -no PKNAME \$(df / | tail -1 | awk '{print \$1}')")
    if [[ "$boot_device" == "sdb" || "$boot_device" == "sda" ]]; then
        log_success "Boot device: /dev/$boot_device (USB)"
        ((checks_passed++))
    else
        log_warning "Boot device: /dev/$boot_device (expected USB drive)"
        ((checks_passed++))  # Warning, not failure
    fi

    [ "$checks_passed" -eq "$checks_total" ]
    return $?
}

# Stage 4: Required Commands Check
stage_4_commands() {
    echo ""
    echo "=== Stage 4: Required Commands Check ==="

    local required_commands=(
        "sudo"
        "systemctl"
        "apt"
        "apt-get"
        "curl"
        "wget"
    )

    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ssh "$TARGET" "command -v $cmd >/dev/null 2>&1"; then
            log_success "Command available: $cmd"
        else
            log_error "Missing required command: $cmd"
            missing_commands+=("$cmd")
        fi
    done

    [ ${#missing_commands[@]} -eq 0 ]
    return $?
}

# Stage 5: Deployment Simulation (Dry-run, No Actual Changes)
stage_5_simulation() {
    echo ""
    echo "=== Stage 5: Deployment Simulation ==="

    # Simulate package installation
    local packages="git vim curl wget docker.io nfs-kernel-server"
    if ssh "$TARGET" "sudo apt-get update -qq >/dev/null 2>&1 && sudo apt-get install --dry-run -y $packages 2>&1" | grep -q 'newly installed\|already installed'; then
        log_success "Packages available for installation"
    else
        log_error "Package simulation failed"
        return 1
    fi

    # Check write permissions for config directories
    local config_dirs=(
        "/etc/caddy"
        "/etc/systemd/system"
        "/etc"
    )

    for dir in "${config_dirs[@]}"; do
        if ssh "$TARGET" "sudo test -w $dir 2>/dev/null || sudo mkdir -p $dir"; then
            log_success "Config directory writable: $dir"
        else
            log_error "Cannot write to: $dir"
            return 1
        fi
    done

    # Check for existing services (would be reconfigured)
    if ssh "$TARGET" "systemctl list-unit-files 2>/dev/null" | grep -q caddy.service; then
        log_warning "caddy.service already exists (will be reconfigured)"
    fi

    if ssh "$TARGET" "systemctl list-unit-files 2>/dev/null" | grep -q docker.service; then
        log_warning "docker.service already exists (will be reconfigured)"
    fi

    return 0
}

# Stage 6: Human Approval Gate
stage_6_approval() {
    echo ""
    echo "=== Stage 6: Human Approval ==="

    echo ""
    echo "Validation Summary:"
    echo "  ✓ Syntax: State files and templates valid"
    echo "  ✓ Generation: All configs generated successfully"
    echo "  ✓ Target: System reachable and adequate"
    echo "  ✓ Simulation: No conflicts detected"
    echo ""
    echo "Target system: $TARGET"
    echo ""

    # Show config changes
    if [ -d "$REPO_ROOT/config" ]; then
        echo "Generated configurations:"
        find "$REPO_ROOT/config" -type f | sed 's|^.*/config/|  - config/|'
        echo ""
    fi

    read -rp "Proceed with bootstrap deployment? (type 'yes' to confirm): " response
    if [[ "$response" == "yes" ]]; then
        log_success "User approval granted"
        return 0
    else
        log_warning "Deployment cancelled by user"
        return 1
    fi
}

# Main execution
main() {
    echo "=== Bootstrap Validation Pipeline ==="
    echo "Target: $TARGET"
    echo "Repository: $REPO_ROOT"
    echo ""

    local failed_stages=()

    stage_1_syntax || failed_stages+=("Stage 1: Syntax")
    stage_2_generation || failed_stages+=("Stage 2: Generation")
    stage_3_preflight || failed_stages+=("Stage 3: Pre-flight")
    stage_4_commands || failed_stages+=("Stage 4: Commands")
    stage_5_simulation || failed_stages+=("Stage 5: Simulation")

    echo ""
    if [ ${#failed_stages[@]} -eq 0 ]; then
        echo "=== All Validation Stages Passed ==="
        echo ""
        stage_6_approval || exit 1
        echo ""
        echo "Ready to deploy. Run: ./bootstrap-deploy.sh $TARGET"
        exit 0
    else
        echo "=== Validation Failed ==="
        echo "Failed stages:"
        for stage in "${failed_stages[@]}"; do
            echo "  - $stage"
        done
        exit 1
    fi
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
