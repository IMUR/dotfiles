#!/usr/bin/env bash
# .meta/ Initialization Script
# Initializes .meta/ after copying from template
# Generates required files at .meta/ root and sets up infrastructure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

success() { echo -e "${GREEN}✓ $1${NC}"; }
info() { echo -e "${BLUE}ℹ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}" >&2; }

usage() {
    cat << EOF
Usage: $0 [TYPE]

Initialize .meta/ directory after copying from template.

ARGUMENTS:
    TYPE    Repository type: cluster, node, service, or library
            (Optional - will prompt if not provided)

This script:
1. Sets META-TYPE.txt
2. Generates required root files (AGENTS.md, structure.yaml)
3. Creates file index at .meta/file-index.json
4. Runs initial SSOT discovery (if applicable)
5. Creates initialization status file

EXAMPLES:
    $0 cluster    # Initialize for cluster repository
    $0 node       # Initialize for node repository
    $0            # Interactive mode (prompts for type)

EOF
}

# Prompt for repository type
prompt_repo_type() {
    # Prompts go to stderr so they aren't captured by command substitution
    echo "What type of repository is this?" >&2
    echo "  1) cluster  - Multi-node cluster configuration" >&2
    echo "  2) node     - Single node configuration" >&2
    echo "  3) service  - Service/application" >&2
    echo "  4) library  - Code library" >&2
    echo "" >&2

    # Shell-specific prompt (zsh vs bash)
    if [ -n "${ZSH_VERSION:-}" ]; then
        read "choice?Enter number [1-4]: " <&1 >&2
    elif [ -n "${BASH_VERSION:-}" ]; then
        read -p "Enter number [1-4]: " choice </dev/tty
    else
        printf "Enter number [1-4]: " >&2
        read choice </dev/tty
    fi

    # Only the result goes to stdout (gets captured)
    case $choice in
        1) echo "cluster" ;;
        2) echo "node" ;;
        3) echo "service" ;;
        4) echo "library" ;;
        *) error "Invalid choice"; exit 1 ;;
    esac
}

# Main initialization
main() {
    local repo_type="${1:-}"

    if [[ "$repo_type" == "-h" || "$repo_type" == "--help" ]]; then
        usage
        exit 0
    fi

    # Welcome
    echo ""
    info "=== .meta/ Initialization ==="
    echo ""

    # Get or confirm repository type
    if [[ -z "$repo_type" ]]; then
        repo_type=$(prompt_repo_type)
    else
        info "Repository type: $repo_type"
    fi

    # Validate type
    if [[ ! "$repo_type" =~ ^(cluster|node|service|library)$ ]]; then
        error "Invalid repository type: $repo_type"
        error "Must be: cluster, node, service, or library"
        exit 1
    fi

    echo ""

    # Step 1: Set META-TYPE
    info "Setting META-TYPE.txt..."
    echo "$repo_type" > "$SCRIPT_DIR/META-TYPE.txt"
    success "META-TYPE set to: $repo_type"

    # Step 2: Generate required root files
    info "Generating required meta files..."
    if [[ -x "$SCRIPT_DIR/whitelists/generate-meta-files.sh" ]]; then
        cd "$PROJECT_ROOT"
        "$SCRIPT_DIR/whitelists/generate-meta-files.sh" --all
        success "Generated AGENTS.md and structure.yaml"
    else
        warn "Generator script not found, skipping"
    fi

    # Step 3: Generate file index
    info "Generating file index..."
    find "$SCRIPT_DIR" -type f -name "*.md" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.sh" | \
        sort | \
        jq -R -s 'split("\n") | map(select(length > 0))' > "$SCRIPT_DIR/file-index.json"
    success "Created file-index.json"

    # Step 4: Run SSOT discovery (if applicable)
    if [[ "$repo_type" == "cluster" || "$repo_type" == "node" ]]; then
        info "Running initial SSOT discovery..."
        if [[ -x "$SCRIPT_DIR/ssot/discover-truth.sh" ]]; then
            "$SCRIPT_DIR/ssot/discover-truth.sh" 2>/dev/null || warn "SSOT discovery failed (may need configuration)"
        fi
    fi

    # Step 5: Create initialization status
    info "Creating initialization status..."
    cat > "$SCRIPT_DIR/initialization-status.yaml" << EOF
# .meta/ Initialization Status
initialized: true
initialized_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
repository_type: $repo_type
repository_name: $(basename "$PROJECT_ROOT")
initialization_version: "1.0"

steps_completed:
  - set_meta_type
  - generate_root_files
  - create_file_index
  $(if [[ "$repo_type" == "cluster" || "$repo_type" == "node" ]]; then echo "- run_ssot_discovery"; fi)
  - create_status_file

generated_files:
  root:
    - AGENTS.md
    - structure.yaml
  meta:
    - file-index.json
    - initialization-status.yaml
    $(if [[ "$repo_type" == "cluster" ]]; then echo "- ssot/infrastructure-truth.yaml"; fi)
    $(if [[ "$repo_type" == "node" ]]; then echo "- ssot/node-truth.yaml"; fi)

next_steps:
  - "Review generated AGENTS.md and customize if needed"
  - "Review generated structure.yaml"
  - "Customize foundation/principles/ for your context"
  - "Update whitelists/root-whitelist.yml for your structure"
  $(if [[ "$repo_type" == "cluster" ]]; then echo '- "Configure SSOT DNS discovery in ssot/dns/"'; fi)
  $(if [[ "$repo_type" == "service" || "$repo_type" == "library" ]]; then echo '- "Consider removing ssot/ directory (not needed)"'; fi)

EOF
    success "Created initialization-status.yaml"

    # Done!
    echo ""
    success "=== Initialization Complete ==="
    echo ""
    info "Generated files:"
    echo "  • AGENTS.md (root)"
    echo "  • structure.yaml (root)"
    echo "  • .meta/file-index.json"
    echo "  • .meta/initialization-status.yaml"
    if [[ "$repo_type" == "cluster" || "$repo_type" == "node" ]]; then
        echo "  • .meta/ssot/infrastructure-truth.yaml (if configured)"
    fi
    echo ""
    info "Next steps:"
    echo "  1. Review and customize AGENTS.md"
    echo "  2. Review structure.yaml"
    echo "  3. Customize .meta/foundation/principles/"
    echo "  4. Run: ./.meta/whitelists/check-root-whitelist.sh"
    echo ""
    info "See: .meta/initialization-status.yaml for details"
    echo ""
}

main "$@"
