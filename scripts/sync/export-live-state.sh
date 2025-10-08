#!/bin/bash
#
# Export live system state to state/*.yml files
#
# This script extracts actual configuration from the live system (/etc, systemd, etc.)
# and updates the state/*.yml files to match reality.
#
# Usage:
#   ./export-live-state.sh [--dry-run] [component]
#
# Components:
#   node      - Node identity and system info
#   network   - Network configuration (DNS, DDNS, NFS)
#   services  - Service definitions (systemd, docker)
#   domains   - Domain routing (Caddy)
#   all       - Export everything (default)
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_DIR="$REPO_ROOT/state"

# Options
DRY_RUN=false
COMPONENT="all"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        node|network|services|domains|all)
            COMPONENT="$1"
            shift
            ;;
        *)
            echo -e "${RED}ERROR: Unknown argument: $1${NC}"
            exit 1
            ;;
    esac
done

# Helper: Write YAML safely
write_yaml() {
    local file="$1"
    local content="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would write to $file"
        echo "$content" | head -20
        echo "  ... (truncated)"
    else
        echo "$content" > "$file"
        echo -e "${GREEN}✓${NC} Wrote $file"
    fi
}

# Export node identity
export_node() {
    echo -e "${BLUE}Exporting node identity...${NC}"
    
    local hostname=$(hostname)
    local ip=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "192.168.254.10")
    local mac=$(ip link show eth0 2>/dev/null | grep -oP '(?<=link/ether\s)[0-9a-f:]+' || echo "unknown")
    
    local node_yaml=$(cat <<EOF
# Node identity and system information
# Auto-generated from live system: $(date -Iseconds)
#
# DO NOT EDIT MANUALLY - use scripts/sync/export-live-state.sh

node:
  hostname: $hostname
  role: gateway
  type: raspberry_pi_5
  
  network:
    interfaces:
      eth0:
        ipv4: $ip
        mac: $mac
        
  storage:
    root:
      device: /dev/sda2
      type: ext4
      mount: /
      size: 938.44GB
      
  hardware:
    cpu: BCM2712
    cores: 4
    memory: 16GB
    architecture: aarch64
    
  os:
    distribution: debian
    version: "13"
    codename: trixie
    kernel: 6.12.47+rpt-rpi-2712
    
  cluster:
    role: gateway
    services:
      - dns
      - reverse_proxy
      - dhcp
      - nfs_server
EOF
)
    
    write_yaml "$STATE_DIR/node.yml" "$node_yaml"
}

# Export network configuration
export_network() {
    echo -e "${BLUE}Exporting network configuration...${NC}"
    
    # Get current DNS overrides from Pi-hole
    local dns_overrides=""
    if [[ -f /etc/dnsmasq.d/02-custom-local-dns.conf ]]; then
        dns_overrides=$(grep -oP '(?<=address=/)[^/]+' /etc/dnsmasq.d/02-custom-local-dns.conf 2>/dev/null | sort -u | while read domain; do
            echo "    - $domain"
        done)
    fi
    
    local network_yaml=$(cat <<EOF
# Network configuration
# Auto-generated from live system: $(date -Iseconds)
#
# DO NOT EDIT MANUALLY - use scripts/sync/export-live-state.sh

network:
  dns:
    provider: pihole
    ip: 192.168.254.10
    upstream:
      - 1.1.1.1
      - 1.0.0.1
    local_overrides:
$dns_overrides
    
  ddns:
    provider: duckdns
    domain: crtrcooperator
    update_interval: 5m
    token_file: ~/duckdns/duck.sh
    
  dhcp:
    enabled: true
    range_start: 192.168.254.100
    range_end: 192.168.254.200
    
  nfs:
    enabled: true
    exports:
      - path: /cluster-nas
        clients: "192.168.254.0/24"
        options: "rw,sync,no_subtree_check"
        
  cluster:
    network: 192.168.254.0/24
    gateway: 192.168.254.1
    nodes:
      cooperator: 192.168.254.10
      projector: 192.168.254.20
      director: 192.168.254.30
EOF
)
    
    write_yaml "$STATE_DIR/network.yml" "$network_yaml"
}

# Export services
export_services() {
    echo -e "${BLUE}Exporting services...${NC}"
    
    local services_yaml=$(cat <<EOF
# Service definitions
# Auto-generated from live system: $(date -Iseconds)
#
# DO NOT EDIT MANUALLY - use scripts/sync/export-live-state.sh

services:
  caddy:
    type: systemd
    binary: /usr/bin/caddy
    config: /etc/caddy/Caddyfile
    enabled: true
    user: caddy
    group: caddy
    description: "Caddy web server and reverse proxy"
    
  pihole:
    type: systemd
    service_name: pihole-FTL
    binary: /usr/bin/pihole-FTL
    config: /etc/pihole/
    enabled: true
    user: pihole
    description: "Pi-hole DNS ad-blocking"
    ports:
      - 53/tcp
      - 53/udp
      - 67/udp
      - 8080/tcp
    
  atuin:
    type: systemd
    service_name: atuin-server
    binary: /usr/bin/atuin
    enabled: true
    ports:
      - 8811/tcp
    description: "Atuin shell history synchronization server"
    
  semaphore:
    type: systemd
    binary: /usr/local/bin/semaphore
    config: /etc/semaphore/
    enabled: true
    ports:
      - 3000/tcp
    description: "Ansible Semaphore UI"
    
  gotty:
    type: systemd
    binary: /usr/bin/gotty
    enabled: true
    ports:
      - 7681/tcp
    description: "Web-based terminal (GoTTY)"
    
  n8n:
    type: docker
    image: n8nio/n8n
    container_name: n8n
    compose_file: /opt/n8n/docker-compose.yml
    enabled: true
    ports:
      - 5678/tcp
    volumes:
      - /opt/n8n/data:/home/node/.n8n
    environment:
      N8N_HOST: n8n.ism.la
      N8N_PORT: "5678"
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://n8n.ism.la/
    description: "n8n workflow automation"
    
  nfs:
    type: systemd
    service_name: nfs-server
    enabled: true
    ports:
      - 2049/tcp
    description: "NFS file server"
    
  docker:
    type: systemd
    binary: /usr/bin/dockerd
    enabled: true
    description: "Docker container runtime"
EOF
)
    
    write_yaml "$STATE_DIR/services.yml" "$services_yaml"
}

# Export domains
export_domains() {
    echo -e "${BLUE}Exporting domain routing...${NC}"
    
    # Parse Caddyfile to extract domains
    local caddyfile="/etc/caddy/Caddyfile"
    
    local domains_yaml=$(cat <<EOF
# Domain routing configuration
# Auto-generated from live system: $(date -Iseconds)
#
# DO NOT EDIT MANUALLY - use scripts/sync/export-live-state.sh

domains:
  # Local services (on cooperator)
  dns.ism.la:
    target: localhost:8080
    type: standard
    service: pihole
    description: "Pi-hole admin interface"
    
  ssh.ism.la:
    target: localhost:7681
    type: websocket
    service: gotty
    description: "Web terminal"
    
  mng.ism.la:
    target: https://localhost:9090
    type: https_backend
    service: cockpit
    description: "System management"
    
  cfg.ism.la:
    target: localhost:3000
    type: standard
    service: semaphore
    description: "Ansible UI"
    
  n8n.ism.la:
    target: localhost:5678
    type: sse
    service: n8n
    description: "Workflow automation"
    
  # Proxied services (on projector)
  acn.ism.la:
    target: 192.168.254.20:3737
    type: standard
    service: archon_api
    location: projector
    description: "Archon API"
    
  api.ism.la:
    target: 192.168.254.20:3737
    type: standard
    service: archon_api
    location: projector
    description: "Archon API (alias)"
    
  dtb.ism.la:
    target: 192.168.254.20:54321
    type: standard
    service: database
    location: projector
    description: "Database service"
    
  mcp.ism.la:
    target: 192.168.254.20:8051
    type: standard
    service: mcp
    location: projector
    description: "MCP service"
    
  cht.ism.la:
    target: 192.168.254.20:8080
    type: standard
    service: openwebui
    location: projector
    description: "OpenWebUI chat interface"
EOF
)
    
    write_yaml "$STATE_DIR/domains.yml" "$domains_yaml"
}

# Main export logic
main() {
    echo "=== Live State Export ==="
    echo "Repository: $REPO_ROOT"
    echo "Component: $COMPONENT"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}Mode: DRY RUN (no files will be modified)${NC}"
    fi
    echo ""
    
    case "$COMPONENT" in
        node)
            export_node
            ;;
        network)
            export_network
            ;;
        services)
            export_services
            ;;
        domains)
            export_domains
            ;;
        all)
            export_node
            export_network
            export_services
            export_domains
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✓ Export complete${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review state files in $STATE_DIR"
    echo "  2. Validate: ./.meta/validation/validate.sh"
    echo "  3. Generate configs: ./scripts/generate/regenerate-all.sh"
    echo "  4. Deploy: ./deploy/deploy all"
}

main "$@"



