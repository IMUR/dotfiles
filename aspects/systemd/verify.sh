#!/bin/bash
# Systemd Aspect - Verification Script

set -euo pipefail

SERVICES=(
    "caddy"
    "pihole-FTL"
    "nfs-kernel-server"
    "docker"
    "atuin-server"
    "semaphore"
    "gotty"
)

echo "Verifying Systemd Aspect..."
echo

# Check all services are enabled
echo "Checking enabled status..."
for service in "${SERVICES[@]}"; do
    if systemctl is-enabled "$service" &>/dev/null; then
        echo "✓ $service is enabled"
    else
        echo "✗ $service is NOT enabled"
        exit 1
    fi
done
echo

# Check all services are active
echo "Checking active status..."
for service in "${SERVICES[@]}"; do
    if systemctl is-active "$service" &>/dev/null; then
        echo "✓ $service is active"
    else
        echo "✗ $service is NOT active"
        exit 1
    fi
done
echo

# Check for failed services
echo "Checking for failed services..."
FAILED=$(systemctl --failed --no-legend | wc -l)
if [ "$FAILED" -eq 0 ]; then
    echo "✓ No failed services"
else
    echo "✗ $FAILED failed services detected:"
    systemctl --failed
    exit 1
fi
echo

echo "✓ Systemd aspect verification PASSED"
