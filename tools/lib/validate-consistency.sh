#!/bin/bash
#
# validate-consistency.sh - Check cross-file consistency
#
# Purpose: Validate references between state files
# Philosophy: Explicit state - ensure all references are valid
#

set -euo pipefail

source "$(dirname "$0")/common.sh"

check_service_references() {
    local domains_file="$1"
    local services_file="$2"
    local issues=0

    # Extract service names from services.yml
    local available_services=$(yq eval '.services | keys | .[]' "$services_file" 2>/dev/null || echo "")

    if [[ -z "$available_services" ]]; then
        warning "Could not extract services from $services_file"
        return 0
    fi

    # Check each domain references an existing service
    local domain_count=$(yq eval '.domains | length' "$domains_file" 2>/dev/null || echo "0")

    for ((i=0; i<domain_count; i++)); do
        local service=$(yq eval ".domains[$i].service" "$domains_file" 2>/dev/null)
        local fqdn=$(yq eval ".domains[$i].fqdn" "$domains_file" 2>/dev/null)

        if [[ -n "$service" ]] && ! echo "$available_services" | grep -q "^${service}$"; then
            echo "  ❌ Domain $fqdn references non-existent service: $service"
            ((issues++))
        fi
    done

    return $issues
}

check_ip_consistency() {
    local node_file="$1"
    local network_file="$2"
    local issues=0

    # Extract IPs
    local node_ip=$(yq eval '.node.network.internal_ip' "$node_file" 2>/dev/null)
    local network_ip=$(yq eval '.network.interface.ip' "$network_file" 2>/dev/null | cut -d'/' -f1)

    if [[ -n "$node_ip" ]] && [[ -n "$network_ip" ]] && [[ "$node_ip" != "$network_ip" ]]; then
        echo "  ❌ IP mismatch: node.yml has $node_ip, network.yml has $network_ip"
        ((issues++))
    fi

    return $issues
}

check_cluster_nodes() {
    local network_file="$1"
    local domains_file="$2"
    local issues=0

    # Extract cluster node IPs
    local cluster_ips=$(yq eval '.network.cluster.nodes[]' "$network_file" 2>/dev/null || echo "")

    if [[ -z "$cluster_ips" ]]; then
        return 0
    fi

    # Check each domain's local_ip is in cluster
    local domain_count=$(yq eval '.domains | length' "$domains_file" 2>/dev/null || echo "0")

    for ((i=0; i<domain_count; i++)); do
        local local_ip=$(yq eval ".domains[$i].local_ip" "$domains_file" 2>/dev/null)
        local fqdn=$(yq eval ".domains[$i].fqdn" "$domains_file" 2>/dev/null)

        if [[ -n "$local_ip" ]] && ! echo "$cluster_ips" | grep -q "^${local_ip}$"; then
            echo "  ⚠️  Domain $fqdn has local_ip $local_ip not in cluster nodes"
            ((issues++))
        fi
    done

    return $issues
}

main() {
    local state_dir="${1:-$REPO_ROOT/ssot/state}"
    local total_issues=0

    if [[ ! -d "$state_dir" ]]; then
        echo "ERROR: State directory not found: $state_dir" >&2
        return 1
    fi

    # Check if yq is available
    if ! command -v yq &> /dev/null; then
        warning "yq not installed - skipping consistency checks"
        warning "Install with: sudo apt install yq"
        return 0
    fi

    echo "Stage 3: Consistency Validation"
    echo "-------------------------------"

    # Check service references
    if [[ -f "$state_dir/domains.yml" ]] && [[ -f "$state_dir/services.yml" ]]; then
        echo -n "Checking service references... "
        if check_service_references "$state_dir/domains.yml" "$state_dir/services.yml"; then
            echo "✓"
        else
            issues=$?
            total_issues=$((total_issues + issues))
        fi
    fi

    # Check IP consistency
    if [[ -f "$state_dir/node.yml" ]] && [[ -f "$state_dir/network.yml" ]]; then
        echo -n "Checking IP consistency... "
        if check_ip_consistency "$state_dir/node.yml" "$state_dir/network.yml"; then
            echo "✓"
        else
            issues=$?
            total_issues=$((total_issues + issues))
        fi
    fi

    # Check cluster node references
    if [[ -f "$state_dir/network.yml" ]] && [[ -f "$state_dir/domains.yml" ]]; then
        echo -n "Checking cluster node references... "
        if check_cluster_nodes "$state_dir/network.yml" "$state_dir/domains.yml"; then
            echo "✓"
        else
            issues=$?
            total_issues=$((total_issues + issues))
        fi
    fi

    echo ""
    return $total_issues
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
