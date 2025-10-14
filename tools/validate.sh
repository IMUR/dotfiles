#!/bin/bash
#
# ssot validate - Check state/ files for correctness
#
# Purpose: Catch errors before deployment
# Why: Prevent deploying broken configuration
#

set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

# check_state_dir

STATE_DIR="$REPO_ROOT/ssot/state"

info "Validating state files..."

FAILED=0

for file in "$STATE_DIR"/*.yml; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        echo -n "  Checking $filename... "

        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            success "✓"
        else
            error "✗ Invalid YAML syntax"
            FAILED=$((FAILED + 1))
        fi
    fi
done

echo ""

if [[ $FAILED -eq 0 ]]; then
    success "All state files valid"
    exit 0
else
    fatal "$FAILED file(s) failed validation"
fi
