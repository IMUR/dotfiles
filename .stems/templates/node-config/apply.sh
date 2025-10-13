#!/bin/bash
# Node Configuration Apply Script
# Applies configuration to a target node

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <node-name-or-ip>"
    exit 1
fi

NODE="$1"
VARIABLES_FILE="variables.yml"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Pre-flight checks
log_info "Running pre-flight checks..."

# Check if variables file exists
if [ ! -f "$VARIABLES_FILE" ]; then
    log_error "Variables file not found: $VARIABLES_FILE"
    exit 1
fi

# Check SSH connectivity
log_info "Checking SSH connectivity to $NODE..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$NODE" "echo 'SSH OK'" &>/dev/null; then
    log_error "Cannot connect to $NODE via SSH"
    exit 1
fi

# Check sudo access
log_info "Checking sudo access on $NODE..."
if ! ssh "$NODE" "sudo -n true" &>/dev/null; then
    log_warn "Sudo requires password or not available"
fi

# Run validation first
log_info "Running validation..."
if [ -x ./validate.sh ]; then
    ./validate.sh || {
        log_error "Validation failed"
        exit 1
    }
else
    log_warn "No validation script found, skipping validation"
fi

# Create backup
log_info "Creating configuration backup on $NODE..."
ssh "$NODE" "mkdir -p ~/backups && tar -czf ~/backups/config-backup-$(date +%Y%m%d-%H%M%S).tar.gz ~/.bashrc ~/.zshrc ~/.ssh/config 2>/dev/null || true"

# Apply configuration stages
log_info "Starting configuration apply..."

# Stage 1: System packages
log_info "Stage 1: Installing system packages..."
if [ -f base-packages.txt ]; then
    PACKAGES=$(cat base-packages.txt | tr '\n' ' ')
    ssh "$NODE" "sudo apt-get update && sudo apt-get install -y $PACKAGES" || {
        log_error "Package installation failed"
        exit 1
    }
else
    log_warn "No base-packages.txt found, skipping package installation"
fi

# Stage 2: User configuration
log_info "Stage 2: Configuring user environment..."
if [ -d dotfiles ]; then
    log_info "Copying dotfiles..."
    rsync -av --exclude='.git' dotfiles/ "$NODE:~/" || {
        log_error "Dotfiles sync failed"
        exit 1
    }
fi

# Stage 3: SSH configuration
log_info "Stage 3: Configuring SSH..."
if [ -f ssh_config ]; then
    scp ssh_config "$NODE:~/.ssh/config"
    ssh "$NODE" "chmod 600 ~/.ssh/config"
fi

# Stage 4: Docker setup (if enabled in variables)
if grep -q "docker:.*enabled: true" "$VARIABLES_FILE"; then
    log_info "Stage 4: Setting up Docker..."
    ssh "$NODE" << 'DOCKER_SETUP'
        # Check if Docker is installed
        if ! command -v docker &> /dev/null; then
            echo "Installing Docker..."
            curl -fsSL https://get.docker.com | sudo sh
            sudo usermod -aG docker $USER
        fi
        
        # Check Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            echo "Installing Docker Compose..."
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi
DOCKER_SETUP
fi

# Stage 5: Services configuration
log_info "Stage 5: Configuring services..."
if [ -d services ]; then
    rsync -av services/ "$NODE:/tmp/services/"
    ssh "$NODE" "sudo cp -r /tmp/services/* /opt/services/ 2>/dev/null || sudo mkdir -p /opt/services && sudo cp -r /tmp/services/* /opt/services/"
fi

# Stage 6: Directory structure
log_info "Stage 6: Creating directory structure..."
ssh "$NODE" << 'DIRS'
    sudo mkdir -p /opt/services /var/log/cluster /mnt/shared
    sudo chmod 755 /opt/services
    sudo chmod 775 /var/log/cluster
DIRS

# Stage 7: Environment variables
log_info "Stage 7: Setting environment variables..."
ssh "$NODE" << 'ENV_VARS'
    # Add to bashrc if not already present
    grep -q "CLUSTER_NODE=" ~/.bashrc || echo 'export CLUSTER_NODE=$(hostname)' >> ~/.bashrc
    grep -q "CLUSTER_ROLE=" ~/.bashrc || echo 'export CLUSTER_ROLE=worker' >> ~/.bashrc
    
    # Add to zshrc if exists
    [ -f ~/.zshrc ] && {
        grep -q "CLUSTER_NODE=" ~/.zshrc || echo 'export CLUSTER_NODE=$(hostname)' >> ~/.zshrc
        grep -q "CLUSTER_ROLE=" ~/.zshrc || echo 'export CLUSTER_ROLE=worker' >> ~/.zshrc
    }
ENV_VARS

# Stage 8: Final validation
log_info "Stage 8: Running post-configuration validation..."
ssh "$NODE" << 'VALIDATION'
    echo "System information:"
    uname -a
    echo ""
    echo "Network configuration:"
    ip addr show | grep inet | grep -v inet6
    echo ""
    echo "Docker status:"
    docker --version 2>/dev/null || echo "Docker not installed"
    echo ""
    echo "User environment:"
    echo "Shell: $SHELL"
    echo "User: $USER"
    echo "Home: $HOME"
VALIDATION

# Completion
log_info "✅ Configuration applied successfully to $NODE"
log_info ""
log_info "Next steps:"
log_info "1. Log out and back in to apply group changes"
log_info "2. Verify services are running: ssh $NODE 'docker ps'"
log_info "3. Test application access"
log_info ""
log_info "To rollback if needed: ./rollback.sh $NODE"
