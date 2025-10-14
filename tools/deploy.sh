#!/bin/bash
#
# ssot deploy - Apply state/ → live system
#
# Purpose: Materialize desired state
# Why: Make live system match state/ definitions
#
# Options:
#   --all              Deploy everything
#   --service=<name>   Deploy specific service
#   --caddy            Deploy Caddy only
#   --pihole           Deploy Pi-hole only
#   --systemd          Deploy systemd units
#

set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

require_root "deploy"
# check_state_dir

info "Deployment not yet implemented"
echo "This would:"
echo "  1. Validate state/ files"
echo "  2. Generate configs from state/"
echo "  3. Deploy to /etc/"
echo "  4. Reload/restart services"
echo ""
echo "Current workaround:"
echo "  - Edit files in backups/"
echo "  - Manually deploy: sudo cp backups/... /etc/..."

exit 0
