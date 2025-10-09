#!/usr/bin/env bash
# Root Whitelist Enforcement Script
# Checks for files in repository root that are not on the whitelist
# Can suggest moves or automatically relocate files based on patterns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WHITELIST_FILE="$PROJECT_ROOT/.meta/root-whitelist.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Modes
MODE="check"  # check|suggest|fix
VERBOSE=false

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Check repository root for files not on the whitelist.

OPTIONS:
    --check          Check for violations (default)
    --suggest        Show suggested destinations for violating files
    --fix            Automatically move files to suggested locations
    -v, --verbose    Verbose output
    -h, --help       Show this help message

EXAMPLES:
    # Check for violations
    $0

    # Show where files would be moved
    $0 --suggest

    # Automatically move violating files
    $0 --fix

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check) MODE="check"; shift ;;
        --suggest) MODE="suggest"; shift ;;
        --fix) MODE="fix"; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Logging functions
info() { echo -e "${BLUE}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# Check if whitelist file exists
if [[ ! -f "$WHITELIST_FILE" ]]; then
    error "Whitelist file not found: $WHITELIST_FILE"
    exit 1
fi

# Extract whitelisted files from YAML (simple grep-based parsing)
get_whitelisted_files() {
    # Extract from navigation_docs, structure_files, root_required_configs, standard_dotfiles sections
    grep -A 50 "navigation_docs:\|structure_files:\|root_required_configs:\|standard_dotfiles:" "$WHITELIST_FILE" \
        | grep -E '^\s+-\s+' \
        | sed 's/^\s*-\s*//' \
        | sed 's/#.*//' \
        | tr -d ' ' \
        | grep -v '^$'
}

# Extract allowed directories from YAML
get_allowed_directories() {
    grep -A 30 "allowed_directories:" "$WHITELIST_FILE" \
        | grep -E '^\s+-\s+' \
        | sed 's/^\s*-\s*//' \
        | sed 's/\/.*//' \
        | sed 's/#.*//' \
        | tr -d ' ' \
        | grep -v '^$'
}

# Get destination for file - SIMPLIFIED to use queue
get_destination() {
    local file=$1
    # Everything goes to docs/queue/ for manual review
    echo "docs/queue/"
}

# Get suggested destination based on pattern (for manifest tracking)
# This doesn't move files, just records what we think they might be
get_suggested_destination() {
    local file=$1
    local pattern=""

    # Session artifacts
    if [[ "$file" =~ -SETUP\.md$ ]]; then
        pattern="*-SETUP.md"
        echo ".sessions/$(date +%Y-%m-%d)-$(echo "$file" | sed 's/-SETUP.md//' | tr '[:upper:]' '[:lower:]')/"
    elif [[ "$file" =~ -TEST-RESULTS\.md$ ]]; then
        pattern="*-TEST-RESULTS.md"
        echo ".sessions/$(date +%Y-%m-%d)-$(echo "$file" | sed 's/-TEST-RESULTS.md//' | tr '[:upper:]' '[:lower:]')/"
    elif [[ "$file" =~ -COMPLETE\.md$ ]]; then
        pattern="*-COMPLETE.md"
        echo ".sessions/$(date +%Y-%m-%d)-$(echo "$file" | sed 's/-COMPLETE.md//' | tr '[:upper:]' '[:lower:]')/"
    elif [[ "$file" =~ ^SESSION-NOTES-.+\.md$ ]]; then
        pattern="SESSION-NOTES-*.md"
        local date_part=$(echo "$file" | sed -n 's/SESSION-NOTES-\([0-9-]*\).*/\1/p')
        echo ".sessions/${date_part}-session-notes/"

    # Technical specifications
    elif [[ "$file" =~ -specification\.md$ ]]; then
        pattern="*-specification.md"
        echo ".specs/"
    elif [[ "$file" =~ -format\.md$ ]]; then
        pattern="*-format.md"
        echo ".specs/"
    elif [[ "$file" =~ -schema\.(yml|yaml|json)$ ]]; then
        pattern="*-schema.{yml,yaml,json}"
        echo ".specs/"

    # Backups
    elif [[ "$file" =~ \.backup- ]]; then
        pattern="*.backup-*"
        echo ".sessions/backups/"
    elif [[ "$file" =~ \.(bak|orig)$ ]]; then
        pattern="*.{bak,orig}"
        echo ".sessions/backups/"

    # Working documents
    elif [[ "$file" =~ ^(TODO|DRAFT|WIP)-.+\.md$ ]]; then
        pattern="TODO-*.md|DRAFT-*.md|WIP-*.md"
        echo ".working/"

    # Unknown
    else
        pattern="unknown"
        echo ".working/"
    fi
}

# Get pattern that matched (for manifest)
get_pattern() {
    local file=$1

    if [[ "$file" =~ -SETUP\.md$ ]]; then echo "*-SETUP.md"
    elif [[ "$file" =~ -TEST-RESULTS\.md$ ]]; then echo "*-TEST-RESULTS.md"
    elif [[ "$file" =~ -COMPLETE\.md$ ]]; then echo "*-COMPLETE.md"
    elif [[ "$file" =~ ^SESSION-NOTES-.+\.md$ ]]; then echo "SESSION-NOTES-*.md"
    elif [[ "$file" =~ -specification\.md$ ]]; then echo "*-specification.md"
    elif [[ "$file" =~ -format\.md$ ]]; then echo "*-format.md"
    elif [[ "$file" =~ -schema\.(yml|yaml|json)$ ]]; then echo "*-schema.{yml,yaml,json}"
    elif [[ "$file" =~ \.backup- ]]; then echo "*.backup-*"
    elif [[ "$file" =~ \.(bak|orig)$ ]]; then echo "*.{bak,orig}"
    elif [[ "$file" =~ ^(TODO|DRAFT|WIP)-.+\.md$ ]]; then echo "{TODO,DRAFT,WIP}-*.md"
    else echo "no pattern match"
    fi
}

# Update manifest with new queue item
update_manifest() {
    local file=$1
    local suggested_dest=$2
    local pattern=$3
    local manifest="$PROJECT_ROOT/docs/queue/manifest.yml"

    # Create temporary entry (we'll use Python/yq in future, for now just append)
    cat >> "$manifest" << EOF
  - file: "$file"
    queued_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    reason: "Not on root whitelist"
    suggested_destination: "$suggested_dest"
    pattern_matched: "$pattern"
    status: "queued"
    notes: ""
EOF
}

# Main logic
main() {
    cd "$PROJECT_ROOT"

    info "Checking root directory: $PROJECT_ROOT"
    [[ "$VERBOSE" == true ]] && info "Whitelist file: $WHITELIST_FILE"

    # Get whitelists
    mapfile -t whitelisted_files < <(get_whitelisted_files)
    mapfile -t allowed_dirs < <(get_allowed_directories)

    [[ "$VERBOSE" == true ]] && info "Whitelisted files: ${#whitelisted_files[@]}"
    [[ "$VERBOSE" == true ]] && info "Allowed directories: ${#allowed_dirs[@]}"

    # Find all files in root (excluding .git)
    violations=()

    for file in *; do
        # Skip if doesn't exist (empty glob)
        [[ ! -e "$file" ]] && continue

        # Skip .git
        [[ "$file" == ".git" ]] && continue

        # Check if directory
        if [[ -d "$file" ]]; then
            # Check if directory is allowed
            is_allowed=false
            for allowed_dir in "${allowed_dirs[@]}"; do
                if [[ "$file" == "$allowed_dir" ]]; then
                    is_allowed=true
                    break
                fi
            done

            if [[ "$is_allowed" == false ]]; then
                warn "Unauthorized directory: $file/"
                violations+=("$file/")
            fi
            continue
        fi

        # Check if file is whitelisted
        is_whitelisted=false
        for whitelisted in "${whitelisted_files[@]}"; do
            if [[ "$file" == "$whitelisted" ]]; then
                is_whitelisted=true
                break
            fi
        done

        if [[ "$is_whitelisted" == false ]]; then
            violations+=("$file")
        fi
    done

    # Report results
    if [[ ${#violations[@]} -eq 0 ]]; then
        success "No whitelist violations found!"
        exit 0
    fi

    echo ""
    warn "Found ${#violations[@]} file(s) not on whitelist:"
    echo ""

    for violation in "${violations[@]}"; do
        case "$MODE" in
            check)
                echo "  • $violation"
                ;;

            suggest)
                dest=$(get_destination "$violation")
                suggested=$(get_suggested_destination "$violation")
                pattern=$(get_pattern "$violation")
                echo "  • $violation"
                echo "    → Destination: $dest"
                echo "    → Suggested final location: $suggested"
                echo "    → Pattern: $pattern"
                ;;

            fix)
                dest=$(get_destination "$violation")
                suggested=$(get_suggested_destination "$violation")
                pattern=$(get_pattern "$violation")

                # Create destination directory
                mkdir -p "$dest"

                # Move file
                if git ls-files --error-unmatch "$violation" &>/dev/null; then
                    # File is tracked by git, use git mv
                    git mv "$violation" "$dest"
                    success "Moved (git): $violation → $dest"
                else
                    # File is untracked, use regular mv
                    mv "$violation" "$dest"
                    success "Moved: $violation → $dest"
                fi

                # Update manifest
                update_manifest "$violation" "$suggested" "$pattern"
                ;;
        esac
    done

    echo ""

    case "$MODE" in
        check)
            error "Whitelist violations detected!"
            echo ""
            info "Run with --suggest to see suggested destinations"
            info "Run with --fix to automatically move files"
            exit 1
            ;;

        suggest)
            info "Run with --fix to apply these moves"
            exit 1
            ;;

        fix)
            success "All files moved to appropriate locations"
            echo ""
            info "Don't forget to:"
            echo "  1. Review the moved files"
            echo "  2. Update .sessions/INDEX.md if session artifacts were moved"
            echo "  3. Commit the changes"
            ;;
    esac
}

main

# ============================================================================
# Meta File Generation Integration
# ============================================================================

check_meta_files() {
    local generator_script="$SCRIPT_DIR/generate-meta-files.sh"

    if [[ ! -x "$generator_script" ]]; then
        return 0  # Generator not available, skip check
    fi

    if [[ "$MODE" != "check" ]]; then
        return 0  # Only check in check mode
    fi

    echo ""
    info "Checking for required meta files..."

    if "$generator_script" --check > /dev/null 2>&1; then
        success "All required meta files present"
        return 0
    fi

    echo ""
    warn "Some required meta files are missing!"
    echo ""

    # Show which files are missing
    "$generator_script" --check 2>&1 || true

    echo ""
    info "Generate missing files with:"
    echo "  .meta/whitelists/generate-meta-files.sh --all"
    echo ""
}

# Check meta files after main validation
check_meta_files
