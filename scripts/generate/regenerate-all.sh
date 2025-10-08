#!/bin/bash
#
# Config Generation Script
#
# Generates all configuration files from state/*.yml using Jinja2 templates
#
# Usage:
#   ./regenerate-all.sh           # Generate all configs
#   ./regenerate-all.sh --dry-run # Show what would be generated
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_DIR="$REPO_ROOT/state"
TEMPLATE_DIR="$REPO_ROOT/.meta/generation"
CONFIG_DIR="$REPO_ROOT/config"

# Track results
GENERATED=0
FAILED=0
DRY_RUN=false

# Check for dry-run flag
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}DRY RUN MODE - No files will be written${NC}"
    echo ""
fi

# Check dependencies
check_dependencies() {
    if ! python3 -c "import jinja2, yaml" 2>/dev/null; then
        echo -e "${RED}ERROR: Required Python modules not found${NC}"
        echo "Install with: pip install Jinja2 PyYAML"
        exit 1
    fi
}

# Generate Caddyfile
generate_caddyfile() {
    echo -n "Generating config/caddy/Caddyfile... "

    local output
    output=$(python3 <<'EOF'
import sys
import yaml
from jinja2 import Template
from datetime import datetime

try:
    # Load state
    with open('state/domains.yml') as f:
        state = yaml.safe_load(f)

    # Load template
    with open('.meta/generation/caddyfile.j2') as f:
        template = Template(f.read())

    # Render
    rendered = template.render(
        domains=state['domains'],
        timestamp=datetime.now().isoformat()
    )

    print(rendered)
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
EOF
) || { echo -e "${RED}FAIL${NC}"; return 1; }

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}DRY-RUN${NC}"
        return 0
    fi

    echo "$output" > "$CONFIG_DIR/caddy/Caddyfile"
    echo -e "${GREEN}DONE${NC}"
    GENERATED=$((GENERATED + 1))
}

# Generate DNS overrides
generate_dns_overrides() {
    echo -n "Generating config/pihole/local-dns.conf... "

    local output
    output=$(python3 <<'EOF'
import sys
import yaml
from jinja2 import Template
from datetime import datetime

try:
    # Load state
    with open('state/network.yml') as f:
        state = yaml.safe_load(f)

    # Load template
    with open('.meta/generation/dns-overrides.j2') as f:
        template = Template(f.read())

    # Render
    rendered = template.render(
        local_overrides=state['network']['dns']['server']['local_overrides'],
        timestamp=datetime.now().isoformat()
    )

    print(rendered)
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
EOF
) || { echo -e "${RED}FAIL${NC}"; return 1; }

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}DRY-RUN${NC}"
        return 0
    fi

    echo "$output" > "$CONFIG_DIR/pihole/local-dns.conf"
    echo -e "${GREEN}DONE${NC}"
    GENERATED=$((GENERATED + 1))
}

# Generate systemd units
generate_systemd_units() {
    echo "Generating systemd units..."

    # Get list of custom systemd services (those with custom unit_file paths)
    local services
    services=$(python3 <<'EOF'
import yaml

with open('state/services.yml') as f:
    state = yaml.safe_load(f)

for name, service in state['services'].items():
    if service['type'] == 'systemd' and service.get('unit_file', '').startswith('/etc/systemd'):
        print(name)
EOF
) || return 1

    for service_name in $services; do
        echo -n "  Generating config/systemd/${service_name}.service... "

        local output
        output=$(python3 <<EOF
import sys
import yaml
from jinja2 import Template
from datetime import datetime

try:
    # Load state
    with open('state/services.yml') as f:
        state = yaml.safe_load(f)

    service = state['services']['$service_name']

    # Load template
    with open('.meta/generation/systemd-unit.j2') as f:
        template = Template(f.read())

    # Render
    rendered = template.render(
        service_name='$service_name',
        service=service,
        timestamp=datetime.now().isoformat()
    )

    print(rendered)
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
EOF
) || { echo -e "${RED}FAIL${NC}"; FAILED=$((FAILED + 1)); continue; }

        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "${BLUE}DRY-RUN${NC}"
            continue
        fi

        echo "$output" > "$CONFIG_DIR/systemd/${service_name}.service"
        echo -e "${GREEN}DONE${NC}"
        GENERATED=$((GENERATED + 1))
    done
}

# Generate docker-compose files
generate_docker_compose() {
    echo "Generating docker-compose files..."

    # Get list of docker-compose services
    local services
    services=$(python3 <<'EOF'
import yaml

with open('state/services.yml') as f:
    state = yaml.safe_load(f)

for name, service in state['services'].items():
    if service['type'] == 'docker-compose':
        print(name)
EOF
) || return 1

    for service_name in $services; do
        echo -n "  Generating config/docker/${service_name}/docker-compose.yml... "

        mkdir -p "$CONFIG_DIR/docker/$service_name"

        local output
        output=$(python3 <<EOF
import sys
import yaml
from jinja2 import Template
from datetime import datetime

try:
    # Load state
    with open('state/services.yml') as f:
        state = yaml.safe_load(f)

    service = state['services']['$service_name']

    # Load template
    with open('.meta/generation/docker-compose.j2') as f:
        template = Template(f.read())

    # Render
    rendered = template.render(
        service_name='$service_name',
        service=service,
        timestamp=datetime.now().isoformat()
    )

    print(rendered)
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
EOF
) || { echo -e "${RED}FAIL${NC}"; FAILED=$((FAILED + 1)); continue; }

        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "${BLUE}DRY-RUN${NC}"
            continue
        fi

        echo "$output" > "$CONFIG_DIR/docker/${service_name}/docker-compose.yml"
        echo -e "${GREEN}DONE${NC}"
        GENERATED=$((GENERATED + 1))
    done
}

# Main
main() {
    echo "=== Config Generation ==="
    echo "Repository: $REPO_ROOT"
    echo ""

    # Change to repo root for Python scripts
    cd "$REPO_ROOT"

    check_dependencies

    # Ensure config directories exist
    mkdir -p "$CONFIG_DIR"/{caddy,pihole,systemd,docker}

    # Generate all configs
    generate_caddyfile
    generate_dns_overrides
    generate_systemd_units
    generate_docker_compose

    # Summary
    echo ""
    echo "=== Generation Summary ==="
    echo -e "Generated: ${GREEN}${GENERATED}${NC} files"
    if [[ $FAILED -gt 0 ]]; then
        echo -e "Failed: ${RED}${FAILED}${NC} files"
        exit 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}DRY RUN - No files were written${NC}"
    else
        echo -e "${GREEN}All configs generated successfully!${NC}"
    fi
}

main "$@"
