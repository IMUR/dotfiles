#!/bin/bash
#
# ssot diff - Compare state/ vs live system
#
# Purpose: See drift, verify deployment success
# Why: Detect when live diverges from desired state
#

set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

# check_state_dir

info "Comparing state/ vs live system..."

warning "diff command not yet implemented"
echo "Would compare:"
echo "  - state/services.yml vs running services"
echo "  - state/domains.yml vs /etc/caddy/Caddyfile"
echo "  - state/network.yml vs network configuration"
echo "  - state/node.yml vs system facts"

exit 0
