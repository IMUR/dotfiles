#!/bin/bash
# Minimal state validation script
# Validates YAML syntax of state files

set -e

echo "=== State File Validation ==="
echo ""

STATE_DIR="state"
ERRORS=0

# Check if state directory exists
if [ ! -d "$STATE_DIR" ]; then
    echo "❌ State directory not found: $STATE_DIR"
    exit 1
fi

# Check each state file
for file in "$STATE_DIR"/*.yml; do
    if [ ! -f "$file" ]; then
        continue
    fi

    echo -n "Checking $(basename $file)... "

    # Basic YAML syntax check using python
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo "✓"
    else
        echo "✗ Invalid YAML syntax"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✅ All state files valid"
    exit 0
else
    echo "❌ $ERRORS file(s) with errors"
    exit 1
fi
