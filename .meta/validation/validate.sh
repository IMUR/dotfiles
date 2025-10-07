#!/bin/bash
#
# Schema validation script for crtr-config state files
#
# Usage:
#   ./validate.sh [file]        # Validate specific file
#   ./validate.sh               # Validate all state files
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCHEMA_DIR="$REPO_ROOT/.meta/schemas"
STATE_DIR="$REPO_ROOT/state"

# Track validation results
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0

# Check for validation tool
check_validator() {
    if python3 -c "import jsonschema, yaml" 2>/dev/null; then
        VALIDATOR="python-jsonschema"
        echo "Using Python jsonschema module for validation"
    else
        echo -e "${RED}ERROR: Python jsonschema and PyYAML modules required${NC}"
        echo "Install with:"
        echo "  pip install jsonschema PyYAML"
        exit 1
    fi
}

# Validate a single file using Python
validate_file() {
    local state_file="$1"
    local schema_file="$2"
    local file_name
    file_name="$(basename "$state_file")"

    TOTAL_FILES=$((TOTAL_FILES + 1))

    echo -n "Validating $file_name against $(basename "$schema_file")... "

    if [[ ! -f "$state_file" ]]; then
        echo -e "${YELLOW}SKIP${NC} (file not found)"
        return 0
    fi

    if [[ ! -f "$schema_file" ]]; then
        echo -e "${YELLOW}SKIP${NC} (schema not found)"
        return 0
    fi

    # Validate using Python jsonschema
    local result=0
    local output

    output=$(python3 <<EOF
import sys
import json
import yaml
from jsonschema import validate, ValidationError, SchemaError

try:
    with open('$schema_file') as f:
        schema = json.load(f)
    with open('$state_file') as f:
        instance = yaml.safe_load(f)

    validate(instance=instance, schema=schema)
    print('✓ Valid')
except FileNotFoundError as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
except yaml.YAMLError as e:
    print(f'YAML parse error: {e}', file=sys.stderr)
    sys.exit(1)
except SchemaError as e:
    print(f'Schema error: {e}', file=sys.stderr)
    sys.exit(1)
except ValidationError as e:
    print(f'Validation error:', file=sys.stderr)
    print(f'  Path: {".".join(str(p) for p in e.absolute_path)}', file=sys.stderr)
    print(f'  Error: {e.message}', file=sys.stderr)
    if e.context:
        for suberror in e.context:
            print(f'  - {suberror.message}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Unexpected error: {e}', file=sys.stderr)
    sys.exit(1)
EOF
) || result=$?

    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_FILES=$((PASSED_FILES + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        FAILED_FILES=$((FAILED_FILES + 1))
        echo "$output" | sed 's/^/  /'
        return 1
    fi
}

# Show usage
usage() {
    cat <<EOF
Schema Validation for crtr-config

Usage:
  $0 [file]           Validate specific state file
  $0                  Validate all state files
  $0 --help           Show this help

Examples:
  $0                              # Validate all state files
  $0 state/services.yml           # Validate services.yml
  $0 state/domains.yml            # Validate domains.yml

State Files:
  state/services.yml  → .meta/schemas/service.schema.json
  state/domains.yml   → .meta/schemas/domain.schema.json
  state/network.yml   → .meta/schemas/network.schema.json
  state/node.yml      → .meta/schemas/node.schema.json

Requirements:
  - Python 3
  - jsonschema module: pip install jsonschema
  - PyYAML module: pip install PyYAML

EOF
    exit 0
}

# Main validation logic
main() {
    # Check for help flag
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        usage
    fi

    echo "=== crtr-config State Validation ==="
    echo "Repository: $REPO_ROOT"
    echo ""

    # Check for validator tool
    check_validator
    echo ""

    # If file specified, validate only that file
    if [[ $# -gt 0 ]]; then
        local file="$1"
        local basename
        basename="$(basename "$file" .yml)"
        local schema=""

        case "$basename" in
            services)
                schema="$SCHEMA_DIR/service.schema.json"
                ;;
            domains)
                schema="$SCHEMA_DIR/domain.schema.json"
                ;;
            network)
                schema="$SCHEMA_DIR/network.schema.json"
                ;;
            node)
                schema="$SCHEMA_DIR/node.schema.json"
                ;;
            *)
                echo -e "${RED}ERROR: Unknown state file type: $basename${NC}"
                echo "Expected: services, domains, network, or node"
                exit 1
                ;;
        esac

        validate_file "$file" "$schema"
    else
        # Validate all state files
        echo "Validating all state files..."
        echo ""

        validate_file "$STATE_DIR/services.yml" "$SCHEMA_DIR/service.schema.json"
        validate_file "$STATE_DIR/domains.yml" "$SCHEMA_DIR/domain.schema.json"
        validate_file "$STATE_DIR/network.yml" "$SCHEMA_DIR/network.schema.json"
        validate_file "$STATE_DIR/node.yml" "$SCHEMA_DIR/node.schema.json"
    fi

    # Summary
    echo ""
    echo "=== Validation Summary ==="
    echo "Total files: $TOTAL_FILES"
    echo -e "Passed: ${GREEN}$PASSED_FILES${NC}"
    if [[ $FAILED_FILES -gt 0 ]]; then
        echo -e "Failed: ${RED}$FAILED_FILES${NC}"
    else
        echo -e "Failed: $FAILED_FILES"
    fi

    # Exit with failure if any files failed
    if [[ $FAILED_FILES -gt 0 ]]; then
        echo ""
        echo -e "${RED}Validation failed${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}All validations passed!${NC}"
        exit 0
    fi
}

main "$@"
