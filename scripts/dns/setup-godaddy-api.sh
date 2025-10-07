#!/usr/bin/env bash
# Quick setup script for GoDaddy DNS API credentials

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env.godaddy"
TEMPLATE_FILE="$SCRIPT_DIR/env.template"

echo "GoDaddy DNS API Setup"
echo "===================="
echo ""

# Check if .env.godaddy already exists
if [[ -f "$ENV_FILE" ]]; then
    warning "Configuration file already exists: $ENV_FILE"
    read -r -p "Overwrite? (yes/no): " overwrite
    if [[ "$overwrite" != "yes" ]]; then
        info "Setup cancelled. Use existing configuration."
        exit 0
    fi
fi

# Guide user through setup
info "This will help you configure GoDaddy DNS API access."
echo ""
echo "You'll need:"
echo "1. GoDaddy API Key"
echo "2. GoDaddy API Secret"
echo ""
echo "Get your credentials from: https://developer.godaddy.com/keys"
echo ""

# Get API Key
read -r -p "Enter your GoDaddy API Key: " api_key
if [[ -z "$api_key" ]]; then
    error "API Key cannot be empty"
fi

# Get API Secret
read -r -s -p "Enter your GoDaddy API Secret: " api_secret
echo ""
if [[ -z "$api_secret" ]]; then
    error "API Secret cannot be empty"
fi

# Get Environment
echo ""
echo "Select API Environment:"
echo "1) OTE (Test environment - recommended for first time)"
echo "2) PRODUCTION (Live environment - affects real DNS)"
read -r -p "Choose (1 or 2): " env_choice

case "$env_choice" in
    1)
        api_env="OTE"
        warning "Using OTE (test) environment"
        ;;
    2)
        api_env="PRODUCTION"
        warning "Using PRODUCTION environment - changes will affect live DNS!"
        read -r -p "Are you sure? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            info "Switching to OTE environment for safety"
            api_env="OTE"
        fi
        ;;
    *)
        warning "Invalid choice. Defaulting to OTE (test) environment"
        api_env="OTE"
        ;;
esac

# Get Domain
echo ""
read -r -p "Enter your domain (default: ism.la): " domain
domain="${domain:-ism.la}"

# Create .env.godaddy file
cat > "$ENV_FILE" << EOF
# GoDaddy DNS API Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# DO NOT commit this file to git!

# Your GoDaddy API credentials
GODADDY_API_KEY="$api_key"
GODADDY_API_SECRET="$api_secret"

# API Environment: OTE (test) or PRODUCTION (live)
GODADDY_API_ENV="$api_env"

# Domain to manage
GODADDY_DOMAIN="$domain"
EOF

success "Configuration saved to: $ENV_FILE"
echo ""

# Verify .gitignore
if ! grep -q "^\.env\.godaddy$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    echo ".env.godaddy" >> "$PROJECT_ROOT/.gitignore"
    success "Added .env.godaddy to .gitignore"
fi

# Test the configuration
echo ""
info "Testing API connection..."
echo ""

# Source the env file and test
if source "$ENV_FILE" && "$SCRIPT_DIR/godaddy-dns-manager.sh" list >/dev/null 2>&1; then
    success "API connection successful!"
    echo ""
    echo "You can now use the DNS manager:"
    echo "  source .env.godaddy"
    echo "  ./scripts/dns/godaddy-dns-manager.sh list"
else
    warning "API connection test failed. Please verify your credentials."
    echo ""
    echo "To test manually:"
    echo "  source .env.godaddy"
    echo "  ./scripts/dns/godaddy-dns-manager.sh list"
fi

echo ""
info "Setup complete!"

