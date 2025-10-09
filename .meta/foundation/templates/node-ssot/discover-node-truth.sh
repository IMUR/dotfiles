#!/usr/bin/env bash
# Node SSOT Discovery Script
# Auto-discovers THIS node's infrastructure state and generates node-truth.yaml
# No SSH required - runs locally and detects all node specifics automatically

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/node-truth.yaml"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

info "Discovering node infrastructure state..."

# Auto-detect node identity
HOSTNAME=$(hostname)
ARCH=$(uname -m)
CPU=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs || echo "unknown")
CORES=$(nproc)
RAM=$(free -h | grep 'Mem:' | awk '{print $2}')
STORAGE=$(df -h / | tail -1 | awk '{print $2}')

# Detect IP address (prefer 192.168.254.x range)
IP=$(ip -4 addr show | grep -oP '192\.168\.254\.\d+' | head -1 || \
     ip -4 addr show | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+' | grep -v '127.0.0.1' | head -1 || \
     echo "unknown")

# Determine node short name and role from hostname
case "$HOSTNAME" in
    cooperator)
        NODE_SHORT="crtr"
        ROLE="gateway"
        ;;
    projector)
        NODE_SHORT="prtr"
        ROLE="compute"
        ;;
    director)
        NODE_SHORT="drtr"
        ROLE="ml_platform"
        ;;
    *)
        NODE_SHORT="unknown"
        ROLE="unknown"
        warn "Unknown hostname: $HOSTNAME"
        ;;
esac

# GPU detection (if nvidia-smi available)
GPU_DATA=""
if command -v nvidia-smi &> /dev/null; then
    GPU_RAW=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "")
    if [[ -n "$GPU_RAW" ]]; then
        # Convert to YAML list format
        while IFS= read -r gpu_line; do
            if [[ -n "$gpu_line" ]]; then
                GPU_DATA="${GPU_DATA}      - \"${gpu_line}\"\n"
            fi
        done <<< "$GPU_RAW"
    fi
fi

# Docker info
DOCKER_VERSION="not installed"
DOCKER_CONTAINERS=""
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo "unknown")
    CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null || echo "")
    if [[ -n "$CONTAINERS" ]]; then
        while IFS= read -r container; do
            if [[ -n "$container" ]]; then
                DOCKER_CONTAINERS="${DOCKER_CONTAINERS}        - ${container}\n"
            fi
        done <<< "$CONTAINERS"
    else
        DOCKER_CONTAINERS="        []\n"
    fi
fi

# Systemd services (top 5 running)
SYSTEMD_SERVICES=""
SERVICES=$(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | awk '{print $1}' | head -5 || echo "")
if [[ -n "$SERVICES" ]]; then
    while IFS= read -r service; do
        if [[ -n "$service" ]]; then
            SYSTEMD_SERVICES="${SYSTEMD_SERVICES}      - ${service}\n"
        fi
    done <<< "$SERVICES"
else
    SYSTEMD_SERVICES="      []\n"
fi

# Generate YAML
info "Generating node-truth.yaml..."

cat > "$OUTPUT_FILE" << EOF
# Node Infrastructure Truth
# Auto-discovered from local node: $HOSTNAME
# Last discovered: $(date -u +%Y-%m-%dT%H:%M:%SZ)
#
# This file is the authoritative source for THIS node's:
# - Hardware specifications
# - Running services (systemd/Docker)
# - Network configuration
#
# Update with: ./.meta/ssot/discover-node-truth.sh

metadata:
  version: "1.0.0"
  last_discovered: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  discovery_method: "local_auto_detection"
  node_hostname: "$HOSTNAME"
  node_short: "$NODE_SHORT"

node:
  identity:
    hostname: $HOSTNAME
    short_name: $NODE_SHORT
    role: $ROLE

  network:
    primary_ip: $IP
    cluster_subnet: "192.168.254.0/24"

  hardware:
    architecture: $ARCH
    cpu: "$CPU"
    cores: $CORES
    ram: "$RAM"
    storage: "$STORAGE"
EOF

# Add GPU if present
if [[ -n "$GPU_DATA" ]]; then
    cat >> "$OUTPUT_FILE" << EOF
    gpu:
$(echo -e "$GPU_DATA")
EOF
fi

# Add services section
cat >> "$OUTPUT_FILE" << EOF

  services:
EOF

# Docker section
if [[ "$DOCKER_VERSION" != "not installed" ]]; then
    cat >> "$OUTPUT_FILE" << EOF
    docker:
      version: "$DOCKER_VERSION"
      containers:
$(echo -e "$DOCKER_CONTAINERS")
EOF
fi

# Systemd section
cat >> "$OUTPUT_FILE" << EOF

    systemd:
      running_services:
$(echo -e "$SYSTEMD_SERVICES")

validation:
  last_validated: null
  validation_status: "pending"

  rules:
    - "Hardware specs match actual system state"
    - "Services are running as listed"
    - "Network configuration is reachable"

# Note: This file represents THIS node only.
# For cluster-wide SSOT see: colab-config/.meta/ssot/infrastructure-truth.yaml
EOF

success "Generated node-truth.yaml"
info "Location: $OUTPUT_FILE"
info ""
info "Node detected:"
echo "  Hostname: $HOSTNAME ($NODE_SHORT)"
echo "  Role: $ROLE"
echo "  IP: $IP"
echo "  Architecture: $ARCH"
echo "  Cores: $CORES"
echo "  RAM: $RAM"
