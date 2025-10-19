#!/bin/bash
#
# validate-security.sh - Check for security issues in state files
#
# Purpose: Detect potential secrets and insecure configurations
# Philosophy: Explicit over implicit - warn about anything suspicious
#

set -euo pipefail

# Known safe placeholder patterns
SAFE_PATTERNS=(
    'CHANGEME'
    'your-.*-here'
    '\$\{[A-Z_]+\}'
    'PLACEHOLDER'
    'TODO'
    'FIXME'
)

# Patterns that indicate secrets
SECRET_PATTERNS=(
    'token:'
    'password:'
    'secret:'
    'api_key:'
    'private_key:'
)

check_file_security() {
    local file="$1"
    local issues=0
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for secret patterns
        for pattern in "${SECRET_PATTERNS[@]}"; do
            if echo "$line" | grep -qi "$pattern"; then
                # Extract the value
                value=$(echo "$line" | sed -n "s/.*${pattern}[[:space:]]*\(.*\)/\1/ip")

                # Skip if empty or looks like placeholder
                [[ -z "$value" ]] && continue

                is_safe=false
                for safe in "${SAFE_PATTERNS[@]}"; do
                    if echo "$value" | grep -Eq "$safe"; then
                        is_safe=true
                        break
                    fi
                done

                # If value is long and not a safe pattern, warn
                if ! $is_safe && [[ ${#value} -gt 10 ]]; then
                    echo "  ⚠️  Line $line_num: Potential secret in '$pattern' (length: ${#value})"
                    ((issues++))
                fi
            fi
        done

        # Check for UUID patterns (common in tokens)
        # if echo "$line" | grep -Eq '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'; then
        #     # Check if it's in a token/secret field
        #     if echo "$line" | grep -Eq 'token|secret|key|password'; then
        #         echo "  🔴 Line $line_num: UUID-format token detected (should use secret management)"
        #         ((issues++))
        #     fi
        # fi

        # Check for 0.0.0.0 binds
        if echo "$line" | grep -q 'bind.*0\.0\.0\.0'; then
            echo "  ℹ️  Line $line_num: Service bound to 0.0.0.0 (all interfaces)"
        fi

        # Check for TLS verification disabled
        if echo "$line" | grep -q 'tls_skip_verify.*true'; then
            echo "  ⚠️  Line $line_num: TLS verification disabled"
            ((issues++))
        fi

    done < "$file"

    return $issues
}

main() {
    local state_dir="${1:-$REPO_ROOT/ssot/state}"
    local total_issues=0

    if [[ ! -d "$state_dir" ]]; then
        echo "ERROR: State directory not found: $state_dir" >&2
        return 1
    fi

    echo "Stage 2: Security Validation"
    echo "----------------------------"

    for file in "$state_dir"/*.yml; do
        [[ -f "$file" ]] || continue

        filename=$(basename "$file")
        echo -n "Checking $filename... "

        if check_file_security "$file"; then
            echo "✓"
        else
            issues=$?
            echo "($issues issues found)"
            ((total_issues += issues))
        fi
    done

    echo ""
    return $total_issues
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
