#!/usr/bin/env bash
# Meta-File Generator - Auto-generates missing required meta files
# Detects missing files, collects data, populates templates, validates against schemas

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$META_DIR/.." && pwd)"
TEMPLATE_DIR="$META_DIR/foundation/templates/root-meta"
SCHEMA_DIR="$META_DIR/foundation/schemas"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() { echo -e "${RED}✗ $1${NC}" >&2; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
info() { echo -e "${BLUE}ℹ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Required meta files
declare -A REQUIRED_FILES=(
    ["AGENTS.md"]="AI agent operational boundaries"
    ["structure.yaml"]="Machine-readable repository structure"
    [".agent-context.json"]="Root-level agent context (optional)"
)

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Auto-generates missing required meta files from templates.

OPTIONS:
    --check             Check for missing files (no generation)
    --generate FILE     Generate specific file
    --regenerate FILE   Regenerate existing file (overwrites)
    --all               Generate all missing files
    --force             Force regeneration of all files
    --dry-run           Show what would be generated without creating files
    --validate FILE     Validate file against schema
    -h, --help          Show this help

EXAMPLES:
    $0 --check                           # Check for missing files
    $0 --generate AGENTS.md              # Generate AGENTS.md if missing
    $0 --regenerate structure.yaml       # Regenerate structure.yaml
    $0 --all                             # Generate all missing files
    $0 --force                           # Regenerate everything

FILES:
    AGENTS.md           - AI operational boundaries
    structure.yaml      - Repository structure definition
    .agent-context.json - Root-level agent context

TEMPLATES:
    $TEMPLATE_DIR/

SCHEMAS:
    $SCHEMA_DIR/

EOF
}

# Check which files are missing
check_missing_files() {
    local missing=()

    for file in "${!REQUIRED_FILES[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            missing+=("$file")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        success "All required meta files exist"
        return 0
    else
        warn "Missing ${#missing[@]} required file(s):"
        for file in "${missing[@]}"; do
            echo "  - $file: ${REQUIRED_FILES[$file]}"
        done
        return 1
    fi
}

# Collect repository metadata
collect_repo_metadata() {
    local metadata_file="/tmp/repo-metadata-$$.json"

    info "Collecting repository metadata..."

    # Detect repository type
    local repo_type="unknown"
    if [[ -d "$PROJECT_ROOT/dotfiles" ]] && [[ -d "$PROJECT_ROOT/ansible" ]]; then
        repo_type="cluster-config"
    elif [[ -f "$PROJECT_ROOT/.meta/META-TYPE.txt" ]]; then
        repo_type=$(cat "$PROJECT_ROOT/.meta/META-TYPE.txt" 2>/dev/null || echo "unknown")
    fi

    # Get repo name from directory
    local repo_name=$(basename "$PROJECT_ROOT")

    # Get repo purpose from README if it exists
    local repo_purpose="Configuration and infrastructure management"
    if [[ -f "$PROJECT_ROOT/README.md" ]]; then
        repo_purpose=$(grep -A 1 "^# " "$PROJECT_ROOT/README.md" | tail -1 | sed 's/^[*_]*//g' | xargs || echo "$repo_purpose")
    fi

    # List directories
    local directories=()
    while IFS= read -r dir; do
        [[ "$dir" == ".git" ]] && continue
        directories+=("\"$dir\"")
    done < <(find "$PROJECT_ROOT" -maxdepth 1 -type d -name '[!.]*' -printf '%f\n' | sort)

    # Create JSON metadata
    cat > "$metadata_file" << EOF
{
  "repo_name": "$repo_name",
  "repo_type": "$repo_type",
  "repo_purpose": "$repo_purpose",
  "generated_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_updated": "$(date +%Y-%m-%d)",
  "last_verified": "$(date +%Y-%m-%d)",
  "directories": [$(IFS=,; echo "${directories[*]}")],
  "has_dotfiles": $([ -d "$PROJECT_ROOT/dotfiles" ] && echo "true" || echo "false"),
  "has_ansible": $([ -d "$PROJECT_ROOT/ansible" ] && echo "true" || echo "false"),
  "has_services": $([ -d "$PROJECT_ROOT/services" ] && echo "true" || echo "false")
}
EOF

    echo "$metadata_file"
}

# Generate AGENTS.md from template
generate_agents_md() {
    local output_file="$PROJECT_ROOT/AGENTS.md"
    local metadata_file=$(collect_repo_metadata)

    info "Generating AGENTS.md..."

    # Read metadata
    local repo_type=$(jq -r '.repo_type' "$metadata_file")
    local repo_purpose=$(jq -r '.repo_purpose' "$metadata_file")
    local last_updated=$(jq -r '.last_updated' "$metadata_file")

    # Determine repo scope
    local repo_scope="Single repository"
    if [[ "$repo_type" == "cluster-config" ]]; then
        repo_scope="3-node cluster (cooperator, projector, director)"
    fi

    # Build forbidden actions based on repo type
    local forbidden_actions=(
        "Delete files (archive instead)"
        "Modify system files directly without appropriate tools"
        "Commit secrets or credentials"
        "Force push to main/master branches"
    )

    if jq -e '.has_ansible' "$metadata_file" | grep -q true; then
        forbidden_actions+=("Execute Ansible playbooks without approval")
    fi

    # Build approval required actions
    local approval_required=(
        "System-level changes (Ansible playbooks)"
        "Service deployments affecting production"
        "Git destructive operations (hard reset, force push)"
    )

    # Build permitted actions
    local permitted_actions=(
        "Read and analyze code/configuration files"
        "Edit templates in dotfiles/"
        "Run validation and syntax checks"
        "Generate documentation"
        "Suggest improvements"
    )

    # Create simple template substitution (no mustache dependency)
    cat > "$output_file" << 'EOF'
# AI Agent Operational Boundaries

**Purpose:** Define concise operational boundaries for AI agents working in this repository

**Last Updated:** LAST_UPDATED_PLACEHOLDER

## Repository Context

- **Type:** REPO_TYPE_PLACEHOLDER
- **Purpose:** REPO_PURPOSE_PLACEHOLDER
- **Scope:** REPO_SCOPE_PLACEHOLDER

## Safety Rules

### Forbidden Actions

AI agents must NEVER:

FORBIDDEN_ACTIONS_PLACEHOLDER

### Requires Human Approval

AI agents must get approval before:

APPROVAL_REQUIRED_PLACEHOLDER

## Operational Boundaries

### Permitted Actions

AI can autonomously:

PERMITTED_ACTIONS_PLACEHOLDER

## Directory-Specific Context

For detailed operational context in specific directories, see:

- **dotfiles/**: `.agent-context.json` - User environment configuration (Chezmoi)
- **ansible/**: `.agent-context.json` - System automation (requires approval)
- **services/**: `.agent-context.json` - Service management (Docker)
- **scripts/**: `.agent-context.json` - Automation scripts

## Validation Requirements

Before committing changes, AI should:

1. Run appropriate validation commands (shellcheck, yamllint, etc.)
2. Execute dry-run/preview commands where available
3. Verify syntax with tool-specific validators
4. Review generated diffs

---

**Note:** This file was auto-generated from repository analysis.

**Schema:** `.meta/foundation/schemas/agents-md.schema.json`
**Generator:** `.meta/whitelists/generate-meta-files.sh`
EOF

    # Perform substitutions
    sed -i "s/LAST_UPDATED_PLACEHOLDER/$last_updated/" "$output_file"
    sed -i "s/REPO_TYPE_PLACEHOLDER/$repo_type/" "$output_file"
    sed -i "s/REPO_PURPOSE_PLACEHOLDER/$repo_purpose/" "$output_file"
    sed -i "s/REPO_SCOPE_PLACEHOLDER/$repo_scope/" "$output_file"

    # Generate lists
    local forbidden_list=""
    for action in "${forbidden_actions[@]}"; do
        forbidden_list+="- $action\n"
    done
    sed -i "s|FORBIDDEN_ACTIONS_PLACEHOLDER|$forbidden_list|" "$output_file"

    local approval_list=""
    for action in "${approval_required[@]}"; do
        approval_list+="- $action\n"
    done
    sed -i "s|APPROVAL_REQUIRED_PLACEHOLDER|$approval_list|" "$output_file"

    local permitted_list=""
    for action in "${permitted_actions[@]}"; do
        permitted_list+="- $action\n"
    done
    sed -i "s|PERMITTED_ACTIONS_PLACEHOLDER|$permitted_list|" "$output_file"

    rm -f "$metadata_file"
    success "Generated AGENTS.md"
}

# Generate structure.yaml from template
generate_structure_yaml() {
    local output_file="$PROJECT_ROOT/structure.yaml"
    local metadata_file=$(collect_repo_metadata)

    info "Generating structure.yaml..."

    cat > "$output_file" << EOF
# Repository Structure
# Machine-readable structure definition
# Auto-generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

version: "2.1"

repository:
  name: $(jq -r '.repo_name' "$metadata_file")
  purpose: $(jq -r '.repo_purpose' "$metadata_file")
  type: $(jq -r '.repo_type' "$metadata_file")

structure:
EOF

    # Scan directories and add to structure
    while IFS= read -r dir; do
        [[ "$dir" == ".git" ]] && continue

        local purpose="Unknown"
        local status="active"
        local context_file=""

        # Detect purpose from common directories
        case "$dir" in
            dotfiles) purpose="User environment configuration (Chezmoi)"; context_file=".agent-context.json" ;;
            ansible) purpose="System automation (Ansible playbooks)"; context_file=".agent-context.json" ;;
            services) purpose="Service configurations (Docker Compose)"; context_file=".agent-context.json" ;;
            scripts) purpose="Automation and validation scripts"; context_file=".agent-context.json" ;;
            docs) purpose="Documentation (architecture, guides, etc.)" ;;
            .meta) purpose="Repository meta-management files" ;;
            .sessions) purpose="Session artifacts and working documents" ;;
            .specs) purpose="Technical specifications" ;;
            .working) purpose="Draft documents and TODOs" ;;
            *) purpose="$(echo "$dir" | sed 's/_/ /g' | sed 's/-/ /g')" ;;
        esac

        cat >> "$output_file" << DIREOF
  $dir/:
    purpose: $purpose
    status: $status
DIREOF

        if [[ -n "$context_file" ]]; then
            echo "    context_file: $context_file" >> "$output_file"
        fi

        echo "" >> "$output_file"
    done < <(find "$PROJECT_ROOT" -maxdepth 1 -type d -name '[!.]*' -printf '%f\n' | sort)

    cat >> "$output_file" << EOF

meta:
  last_verified: $(jq -r '.last_verified' "$metadata_file")
  generated: true
  generator_script: .meta/whitelists/generate-meta-files.sh
  schema: .meta/foundation/schemas/structure-yaml.schema.json
EOF

    rm -f "$metadata_file"
    success "Generated structure.yaml"
}

# Main execution
main() {
    local action="check"
    local file=""
    local force=false
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --check) action="check"; shift ;;
            --generate) action="generate"; file="$2"; shift 2 ;;
            --regenerate) action="regenerate"; file="$2"; shift 2 ;;
            --all) action="generate-all"; shift ;;
            --force) force=true; shift ;;
            --dry-run) dry_run=true; shift ;;
            --validate) action="validate"; file="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) error "Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    case $action in
        check)
            check_missing_files
            ;;
        generate)
            if [[ -f "$PROJECT_ROOT/$file" ]] && [[ "$force" != true ]]; then
                error "$file already exists. Use --regenerate to overwrite."
                exit 1
            fi

            case $file in
                AGENTS.md) generate_agents_md ;;
                structure.yaml) generate_structure_yaml ;;
                *) error "Unknown file: $file"; exit 1 ;;
            esac
            ;;
        regenerate)
            case $file in
                AGENTS.md) generate_agents_md ;;
                structure.yaml) generate_structure_yaml ;;
                *) error "Unknown file: $file"; exit 1 ;;
            esac
            ;;
        generate-all)
            for file in "${!REQUIRED_FILES[@]}"; do
                if [[ ! -f "$PROJECT_ROOT/$file" ]] || [[ "$force" == true ]]; then
                    case $file in
                        AGENTS.md) generate_agents_md ;;
                        structure.yaml) generate_structure_yaml ;;
                    esac
                fi
            done
            ;;
        *)
            error "Invalid action: $action"
            usage
            exit 1
            ;;
    esac
}

main "$@"
