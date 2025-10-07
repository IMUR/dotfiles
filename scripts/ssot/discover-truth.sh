#!/usr/bin/env bash
# Infrastructure SSOT Discovery Script
# Auto-discovers current infrastructure state and generates infrastructure-truth.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/infrastructure-truth.yaml"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

info "Discovering infrastructure state..."

# 1. Discover DNS from GoDaddy API
info "Querying GoDaddy DNS..."
source "$PROJECT_ROOT/.env.godaddy" 2>/dev/null || warn "No .env.godaddy found, skipping DNS"

DNS_RECORDS=""
if [[ -n "${GODADDY_API_KEY:-}" ]]; then
    DNS_JSON=$("$PROJECT_ROOT/scripts/dns/godaddy-dns-manager.sh" list 2>/dev/null | tail -n +2 | awk 'NF' || echo "")
    success "Retrieved DNS records"
else
    warn "GoDaddy credentials not configured, DNS section will be empty"
fi

# 2. Discover node hardware via SSH
info "Scanning cluster nodes..."

declare -A NODE_DATA

# Function to query a node via SSH (works for local or remote)
query_node() {
    local node=$1
    local ip=$2

    # Use SSH for all nodes - passwordless SSH should work even to localhost
    # Try both hostname and IP
    local ssh_target="$node"

    if ! ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$ssh_target" "exit" 2>/dev/null; then
        # Try IP if hostname fails
        ssh_target="$ip"
        if ! ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$ssh_target" "exit" 2>/dev/null; then
            return 1
        fi
    fi

    info "  Scanning $node ($ip)..."

    # Gather hardware info via SSH (with timeouts)
    local hostname=$(timeout 3 ssh "$ssh_target" "hostname" 2>/dev/null || echo "$node")
    local arch=$(timeout 3 ssh "$ssh_target" "uname -m" 2>/dev/null || echo "unknown")
    local cpu=$(timeout 3 ssh "$ssh_target" "lscpu | grep 'Model name' | cut -d: -f2 | xargs" 2>/dev/null || echo "unknown")
    local cores=$(timeout 3 ssh "$ssh_target" "nproc" 2>/dev/null || echo "0")
    local ram=$(timeout 3 ssh "$ssh_target" "free -h | grep 'Mem:' | awk '{print \$2}'" 2>/dev/null || echo "0")

    # GPU info (if available)
    # Use delimiter to handle multiple GPUs, filter out error messages
    local gpu_raw=$(timeout 3 ssh "$ssh_target" "nvidia-smi --query-gpu=name --format=csv,noheader 2>&1" || echo "")
    local gpu="none"
    if [[ -n "$gpu_raw" ]] && ! grep -qi "failed\|error\|not found" <<< "$gpu_raw"; then
        # Replace newlines with a unique delimiter for safe transport through pipe-separated storage
        gpu=$(echo "$gpu_raw" | tr '\n' '␞' | sed 's/␞$//')  # ␞ = Unicode delimiter (U+241E)
    fi

    # Storage info
    local storage=$(timeout 3 ssh "$ssh_target" "df -h / | tail -1 | awk '{print \$2}'" 2>/dev/null || echo "unknown")

    # Docker version
    local docker_ver=$(timeout 3 ssh "$ssh_target" "docker --version 2>/dev/null | awk '{print \$3}' | tr -d ','" || echo "not installed")

    # Running containers
    local containers=$(timeout 5 ssh "$ssh_target" "docker ps --format '{{.Names}}' 2>/dev/null" || echo "")

    # Active systemd services (top 5)
    local services=$(timeout 3 ssh "$ssh_target" "systemctl list-units --type=service --state=running --no-pager --no-legend | awk '{print \$1}' | head -5" 2>/dev/null || echo "")

    NODE_DATA[$node]="hostname=$hostname|arch=$arch|cpu=$cpu|cores=$cores|ram=$ram|gpu=$gpu|storage=$storage|docker=$docker_ver|containers=$containers|services=$services"
    success "  $node scanned"
    return 0
}

# Query each node
for node in crtr prtr drtr; do
    ip="192.168.254.$(case $node in crtr) echo 10;; prtr) echo 20;; drtr) echo 30;; esac)"

    if ! query_node "$node" "$ip"; then
        warn "  $node unreachable, skipping"
    fi
done

# 3. Generate YAML
info "Generating infrastructure-truth.yaml..."

cat > "$OUTPUT_FILE" << 'YAML_HEADER'
# Infrastructure Single Source of Truth
# Auto-generated from live infrastructure
# Last discovered: TIMESTAMP
#
# This file is the authoritative source for:
# - DNS records (from GoDaddy API)
# - Hardware specifications (from SSH queries)
# - Running services (from systemd/Docker)
# - Network configuration
#
# Validate with: ./scripts/ssot/validate-truth.sh
# Update with: ./scripts/ssot/discover-truth.sh

metadata:
  version: "1.0.0"
  last_discovered: "TIMESTAMP"
  discovery_method: "automated"
  collectors_used:
    - godaddy-api
    - ssh-hardware
    - ssh-services
  validation_required: true

dns:
  provider: godaddy
  domain: ism.la
  records:
YAML_HEADER

# Replace timestamp
sed -i "s/TIMESTAMP/$(date -u +%Y-%m-%dT%H:%M:%SZ)/g" "$OUTPUT_FILE"

# Add DNS records
if [[ -n "$DNS_JSON" ]]; then
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            read -r type name data ttl <<< "$line"
            cat >> "$OUTPUT_FILE" << EOF
    - type: $type
      name: $name
      value: $data
      ttl: $ttl
EOF
        fi
    done <<< "$DNS_JSON"
else
    echo "    [] # No DNS records discovered" >> "$OUTPUT_FILE"
fi

# Add nodes section
cat >> "$OUTPUT_FILE" << 'EOF'

nodes:
EOF

# Add each node
for node in crtr prtr drtr; do
    if [[ -v NODE_DATA[$node] ]]; then
        IFS='|' read -r -a fields <<< "${NODE_DATA[$node]}"

        # Parse fields
        declare -A data
        for field in "${fields[@]}"; do
            key="${field%%=*}"
            value="${field#*=}"
            data[$key]="$value"
        done

        ip="192.168.254.$(case $node in crtr) echo 10;; prtr) echo 20;; drtr) echo 30;; esac)"

        cat >> "$OUTPUT_FILE" << EOF
  $node:
    network:
      hostname: ${data[hostname]}
      ip: $ip
      role: $(case $node in crtr) echo gateway;; prtr) echo compute;; drtr) echo ml_platform;; esac)

    hardware:
      architecture: ${data[arch]}
      cpu: "${data[cpu]}"
      cores: ${data[cores]}
      ram: "${data[ram]}"
      storage: "${data[storage]}"
EOF

        # Add GPU if present
        if [[ "${data[gpu]}" != "none" ]]; then
            cat >> "$OUTPUT_FILE" << EOF
      gpu:
EOF
            # Convert delimiter back to newlines for processing
            gpu_data=$(echo "${data[gpu]}" | tr '␞' '\n')
            while IFS= read -r gpu_line; do
                if [[ -n "$gpu_line" ]]; then
                    echo "        - \"$gpu_line\"" >> "$OUTPUT_FILE"
                fi
            done <<< "$gpu_data"
        fi

        # Add services
        cat >> "$OUTPUT_FILE" << EOF

    services:
EOF

        if [[ "${data[docker]}" != "not installed" ]]; then
            cat >> "$OUTPUT_FILE" << EOF
      docker:
        version: "${data[docker]}"
        containers:
EOF
            if [[ -n "${data[containers]}" ]]; then
                while IFS= read -r container; do
                    if [[ -n "$container" ]]; then
                        echo "          - $container" >> "$OUTPUT_FILE"
                    fi
                done <<< "${data[containers]}"
            else
                echo "          []" >> "$OUTPUT_FILE"
            fi
        fi

        cat >> "$OUTPUT_FILE" << EOF

      systemd:
EOF
        if [[ -n "${data[services]:-}" ]]; then
            while IFS= read -r service; do
                if [[ -n "$service" ]]; then
                    echo "        - $service" >> "$OUTPUT_FILE"
                fi
            done <<< "${data[services]}"
        else
            echo "        []" >> "$OUTPUT_FILE"
        fi

        echo "" >> "$OUTPUT_FILE"
    fi
done

# Add validation section
cat >> "$OUTPUT_FILE" << 'EOF'
validation:
  last_validated: null
  validation_status: pending
  validation_hash: null

  rules:
    - "DNS records must match GoDaddy API"
    - "Hardware specs must match SSH queries"
    - "Services must be running as listed"
    - "Network configuration must be reachable"

# Note: This file should be validated regularly using:
#   ./scripts/ssot/validate-truth.sh
#
# To update this file with current infrastructure state:
#   ./scripts/ssot/discover-truth.sh
EOF

success "Generated infrastructure-truth.yaml"
info "Location: $OUTPUT_FILE"
info ""
info "Next steps:"
echo "  1. Review the generated file"
echo "  2. Run validation: ./scripts/ssot/validate-truth.sh"
echo "  3. Commit to git for version control"
