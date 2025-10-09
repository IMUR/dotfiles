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

# Shell-compatible read helper
_read_prompt() {
    local prompt="$1"
    local varname="$2"
    local silent="${3:-}"

    if [ -n "${ZSH_VERSION:-}" ]; then
        [ "$silent" = "-s" ] && read -s "$varname?$prompt" || read "$varname?$prompt"
    elif [ -n "${BASH_VERSION:-}" ]; then
        [ "$silent" = "-s" ] && read -r -s -p "$prompt" $varname || read -r -p "$prompt" $varname
    else
        printf "%s" "$prompt"
        [ "$silent" = "-s" ] && read -r -s $varname || read -r $varname
    fi
}

# Check if .env.godaddy already exists
if [[ -f "$ENV_FILE" ]]; then
    warning "Configuration file already exists: $ENV_FILE"
    _read_prompt "Overwrite? (yes/no): " overwrite
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
_read_prompt "Enter your GoDaddy API Key: " api_key
if [[ -z "$api_key" ]]; then
    error "API Key cannot be empty"
fi

# Get API Secret
_read_prompt "Enter your GoDaddy API Secret: " api_secret -s
echo ""
if [[ -z "$api_secret" ]]; then
    error "API Secret cannot be empty"
fi

# Get Environment
echo ""
echo "Select API Environment:"
echo "1) OTE (Test environment - recommended for first time)"
echo "2) PRODUCTION (Live environment - affects real DNS)"
_read_prompt "Choose (1 or 2): " env_choice

case "$env_choice" in
    1)
        api_env="OTE"
        warning "Using OTE (test) environment"
        ;;
    2)
        api_env="PRODUCTION"
        warning "Using PRODUCTION environment - changes will affect live DNS!"
        _read_prompt "Are you sure? (yes/no): " confirm
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
_read_prompt "Enter your domain (default: ism.la): " domain
domain="${domain:-ism.la}"

# Check if envio is available
if command -v envio >/dev/null 2>&1; then
    info "Using envio for secure encrypted credential storage..."

    # Create envio profile
    if envio list 2>/dev/null | grep -q "^godaddy$"; then
        warning "Envio profile 'godaddy' already exists"
        _read_prompt "Update existing profile? (yes/no): " update_profile
        if [[ "$update_profile" != "yes" ]]; then
            info "Keeping existing envio profile"
            exit 0
        fi
        # Remove old profile
        envio remove godaddy 2>/dev/null || true
    fi

    # Create new profile with all variables
    envio create godaddy || error "Failed to create envio profile"
    envio add godaddy GODADDY_API_KEY="$api_key" || error "Failed to add API key"
    envio add godaddy GODADDY_API_SECRET="$api_secret" || error "Failed to add API secret"
    envio add godaddy GODADDY_API_ENV="$api_env" || error "Failed to add API environment"
    envio add godaddy GODADDY_DOMAIN="$domain" || error "Failed to add domain"

    success "Credentials securely stored in envio profile 'godaddy'"
    echo ""
    info "To use these credentials:"
    echo "  eval \"\$(envio load godaddy)\""
    echo ""

    # Optionally create .env.godaddy for compatibility
    _read_prompt "Also create .env.godaddy file for legacy compatibility? (yes/no): " create_env
    if [[ "$create_env" == "yes" ]]; then
        cat > "$ENV_FILE" << EOF
# GoDaddy DNS API Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# DO NOT commit this file to git!
# NOTE: Credentials are encrypted in envio profile 'godaddy'
# Load with: eval "\$(envio load godaddy)"

# Your GoDaddy API credentials
GODADDY_API_KEY="$api_key"
GODADDY_API_SECRET="$api_secret"

# API Environment: OTE (test) or PRODUCTION (live)
GODADDY_API_ENV="$api_env"

# Domain to manage
GODADDY_DOMAIN="$domain"
EOF
        success "Also created $ENV_FILE"
    fi
else
    warning "envio not found, falling back to plain text .env.godaddy file"
    warning "Install envio for encrypted credential storage: cargo install envio"
    echo ""

    # Fallback: Create plain .env.godaddy file
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
fi
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

