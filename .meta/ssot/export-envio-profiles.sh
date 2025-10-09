#!/usr/bin/env bash
# Export envio profiles to .env files for use in scripts and services
# Run this manually when you want to update .env files from envio profiles

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

success() { echo -e "${GREEN}✓ $1${NC}"; }
info() { echo -e "${BLUE}ℹ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

echo ""
info "=== Exporting Envio Profiles to .env Files ==="
echo ""

# Check if envio is installed
if ! command -v envio >/dev/null 2>&1; then
    warn "envio is not installed. Install it first: https://envio-cli.github.io/installation/"
    exit 1
fi

# Export godaddy-dns profile
if envio list 2>/dev/null | grep -q "godaddy-dns"; then
    info "Exporting godaddy-dns profile..."
    envio export godaddy-dns -f "$SCRIPT_DIR/dns/.env.godaddy"
    success "Exported to: $SCRIPT_DIR/dns/.env.godaddy"
else
    warn "godaddy-dns profile not found. Create it with: envio create godaddy-dns"
fi

# Export github-tokens profile (if needed for git operations)
if envio list 2>/dev/null | grep -q "github-tokens"; then
    info "Exporting github-tokens profile..."
    envio export github-tokens -f "$SCRIPT_DIR/../.env.github"
    success "Exported to: $SCRIPT_DIR/../.env.github"
fi

echo ""
success "=== Export Complete ==="
echo ""
info "Remember to add .env files to .gitignore!"
info "These files contain plaintext secrets - never commit them!"
echo ""
