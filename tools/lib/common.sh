#!/bin/bash
#
# common.sh - Shared functions for ssot tools
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

fatal() {
    error "$*"
    exit 1
}

# Check if running as root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        fatal "This command must be run as root. Use: sudo tools/ssot $*"
    fi
}

# Validate ssot/state directory exists
check_state_dir() {
    if [[ ! -d "$REPO_ROOT/ssot/state" ]]; then
        fatal "ssot/state/ directory not found in $REPO_ROOT"
    fi
}
