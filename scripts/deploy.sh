#!/bin/bash
#
# Simple deployment script for cooperator node configs
#
# Usage:
#   ./deploy.sh            # Deploy all
#   ./deploy.sh caddy      # Deploy Caddy only
#   ./deploy.sh pihole     # Deploy Pi-hole only
#   ./deploy.sh systemd    # Deploy systemd units
#   ./deploy.sh docker     # Deploy docker services
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/config"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}ERROR: This script must be run as root${NC}"
        echo "Use: sudo ./deploy.sh"
        exit 1
    fi
}

deploy_caddy() {
    echo -n "Deploying Caddy config... "
    cp "$CONFIG_DIR/caddy/Caddyfile" /etc/caddy/Caddyfile
    systemctl reload caddy
    echo -e "${GREEN}DONE${NC}"
}

deploy_pihole() {
    echo -n "Deploying Pi-hole DNS overrides... "
    cp "$CONFIG_DIR/pihole/local-dns.conf" /etc/dnsmasq.d/02-custom-local-dns.conf
    systemctl restart pihole-FTL
    echo -e "${GREEN}DONE${NC}"
}

deploy_systemd() {
    echo "Deploying systemd units..."
    for service_file in "$CONFIG_DIR/systemd"/*.service; do
        if [[ -f "$service_file" ]]; then
            service_name=$(basename "$service_file")
            echo -n "  $service_name... "
            cp "$service_file" /etc/systemd/system/
            echo -e "${GREEN}DONE${NC}"
        fi
    done
    systemctl daemon-reload
    echo -e "${GREEN}Systemd reload complete${NC}"
}

deploy_docker() {
    echo "Deploying docker services..."
    for service_dir in "$CONFIG_DIR/docker"/*; do
        if [[ -d "$service_dir" ]] && [[ -f "$service_dir/docker-compose.yml" ]]; then
            service_name=$(basename "$service_dir")
            echo "  $service_name..."
            cd "$service_dir"
            docker compose up -d
        fi
    done
    echo -e "${GREEN}Docker services deployed${NC}"
}

deploy_all() {
    echo "=== Deploying All Configs ==="
    deploy_caddy
    deploy_pihole
    deploy_systemd
    deploy_docker
    echo ""
    echo -e "${GREEN}All configs deployed successfully!${NC}"
}

main() {
    check_root

    case "${1:-all}" in
        caddy)
            deploy_caddy
            ;;
        pihole)
            deploy_pihole
            ;;
        systemd)
            deploy_systemd
            ;;
        docker)
            deploy_docker
            ;;
        all)
            deploy_all
            ;;
        *)
            echo "Usage: $0 {all|caddy|pihole|systemd|docker}"
            exit 1
            ;;
    esac
}

main "$@"
