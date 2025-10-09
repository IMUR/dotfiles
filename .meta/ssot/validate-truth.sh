#!/usr/bin/env bash
# Infrastructure SSOT Validation Script
# Validates infrastructure-truth.yaml against current live infrastructure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TRUTH_FILE="$SCRIPT_DIR/infrastructure-truth.yaml"
REPORT_FILE="$SCRIPT_DIR/cache/validation-report.txt"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; }

# Check if SSOT file exists
if [[ ! -f "$TRUTH_FILE" ]]; then
    error "infrastructure-truth.yaml not found!"
    echo "Run ./scripts/ssot/discover-truth.sh first"
    exit 1
fi

mkdir -p "$SCRIPT_DIR/cache"

info "Validating infrastructure against SSOT..."
echo "" > "$REPORT_FILE"

# Initialize counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0

# 1. Validate DNS Records
info "Validating DNS records..."
if [[ -f "$PROJECT_ROOT/.env.godaddy" ]]; then
    source "$PROJECT_ROOT/.env.godaddy"

    # Get current DNS from API
    CURRENT_DNS=$("$PROJECT_ROOT/scripts/dns/godaddy-dns-manager.sh" list 2>/dev/null | tail -n +2 | wc -l)
    YAML_DNS=$(grep "type:" "$TRUTH_FILE" | grep -v "# type:" | wc -l)

    if [[ $CURRENT_DNS -eq $((YAML_DNS - 1)) ]] || [[ $CURRENT_DNS -eq $YAML_DNS ]]; then
        success "DNS: $CURRENT_DNS records (matches SSOT)"
        ((CHECKS_PASSED++))
    else
        warn "DNS: SSOT has $YAML_DNS records, API shows $CURRENT_DNS"
        echo "DNS record count mismatch: YAML=$YAML_DNS, Live=$CURRENT_DNS" >> "$REPORT_FILE"
        ((CHECKS_WARNED++))
    fi
else
    warn "DNS: No GoDaddy credentials, skipping validation"
    ((CHECKS_WARNED++))
fi

# 2. Validate Node Connectivity
info "Validating node connectivity..."

for node in crtr prtr drtr; do
    ip="192.168.254.$(case $node in crtr) echo 10;; prtr) echo 20;; drtr) echo 30;; esac)"

    if timeout 3 ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$node" "exit" 2>/dev/null; then
        success "  $node: Reachable"
        ((CHECKS_PASSED++))
    else
        error "  $node: Unreachable"
        echo "Node $node ($ip) is unreachable" >> "$REPORT_FILE"
        ((CHECKS_FAILED++))
    fi
done

# 3. Quick Hardware Spot Check (RAM)
info "Spot-checking hardware specs..."

for node in crtr prtr drtr; do
    # Get RAM from YAML
    yaml_ram=$(grep -A 20 "^  $node:" "$TRUTH_FILE" | grep "ram:" | head -1 | awk '{print $2}' | tr -d '"')

    # Get current RAM
    if timeout 3 ssh "$node" "exit" 2>/dev/null; then
        current_ram=$(timeout 3 ssh "$node" "free -h | grep 'Mem:' | awk '{print \$2}'" 2>/dev/null || echo "unknown")

        if [[ "$yaml_ram" == "$current_ram" ]]; then
            success "  $node RAM: $current_ram (matches)"
            ((CHECKS_PASSED++))
        else
            warn "  $node RAM: YAML=$yaml_ram, Current=$current_ram"
            echo "$node RAM mismatch: YAML=$yaml_ram, Current=$current_ram" >> "$REPORT_FILE"
            ((CHECKS_WARNED++))
        fi
    fi
done

# 4. Validate Docker (if installed)
info "Validating Docker status..."

for node in crtr prtr drtr; do
    yaml_docker=$(grep -A 30 "^  $node:" "$TRUTH_FILE" | grep "version:" | head -1 | awk '{print $2}' | tr -d '"')

    if [[ "$yaml_docker" != "not" ]] && [[ -n "$yaml_docker" ]]; then
        if timeout 3 ssh "$node" "exit" 2>/dev/null; then
            current_docker=$(timeout 3 ssh "$node" "docker --version 2>/dev/null | awk '{print \$3}' | tr -d ','" || echo "")

            if [[ -n "$current_docker" ]]; then
                success "  $node Docker: $current_docker"
                ((CHECKS_PASSED++))
            else
                warn "  $node Docker: YAML says installed, but not detected"
                echo "$node Docker not detected but YAML shows version $yaml_docker" >> "$REPORT_FILE"
                ((CHECKS_WARNED++))
            fi
        fi
    fi
done

# 5. Generate validation hash
info "Generating validation hash..."
VALIDATION_HASH=$(sha256sum "$TRUTH_FILE" | awk '{print $1}')
echo "sha256:$VALIDATION_HASH" > "$SCRIPT_DIR/cache/last-validation-hash.txt"
date -u +%Y-%m-%dT%H:%M:%SZ > "$SCRIPT_DIR/cache/last-validation-time.txt"

# Report Summary
echo ""
echo "═══════════════════════════════════════════════════"
echo "Validation Summary"
echo "═══════════════════════════════════════════════════"
echo ""

success "Checks passed: $CHECKS_PASSED"
if [[ $CHECKS_WARNED -gt 0 ]]; then
    warn "Checks with warnings: $CHECKS_WARNED"
fi
if [[ $CHECKS_FAILED -gt 0 ]]; then
    error "Checks failed: $CHECKS_FAILED"
fi

echo ""
info "Validation hash: sha256:${VALIDATION_HASH:0:16}..."
info "Report saved: $REPORT_FILE"

if [[ $CHECKS_FAILED -eq 0 ]] && [[ $CHECKS_WARNED -eq 0 ]]; then
    echo ""
    success "✅ All validations PASSED - SSOT is current"
    exit 0
elif [[ $CHECKS_FAILED -eq 0 ]]; then
    echo ""
    warn "⚠️  Validation PASSED with warnings"
    echo ""
    info "Review report for details: $REPORT_FILE"
    info "Consider running: ./scripts/ssot/discover-truth.sh"
    exit 0
else
    echo ""
    error "❌ Validation FAILED"
    echo ""
    info "Issues found:"
    cat "$REPORT_FILE"
    exit 1
fi
