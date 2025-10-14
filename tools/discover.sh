#!/bin/bash
#
# ssot discover - Extract live system state → state/ files
#
# Purpose: Capture running system truth
# Why: Live system is source of truth, capture it for version control
#

set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

STATE_DIR="$REPO_ROOT/ssot/state"

info "Discovering live system state..."

# This is a placeholder - actual implementation would:
# 1. Query running services (systemctl list-units, docker ps)
# 2. Extract Caddy config
# 3. Extract Pi-hole DNS overrides
# 4. Query network configuration
# 5. Update state/*.yml files

warning "discover command not yet implemented"
echo "Would extract:"
echo "  - Running services → state/services.yml"
echo "  - Domain routing → state/domains.yml"
echo "  - Network config → state/network.yml"
echo "  - Node identity → state/node.yml"

exit 0
