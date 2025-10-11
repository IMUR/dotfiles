# ============================================================================
# Cluster Management Commands - Co-lab Cluster
# ============================================================================
# Managed by colab-config/dotfiles
# Applied identically across all nodes with node-aware logic
#
# Provides cluster-wide management commands with:
# - Interactive prompts and validation
# - Error handling and recovery
# - Support for core + pseudo nodes
# - Consistent UX across all entry points
# ============================================================================

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

# Node definitions
declare -a CLUSTER_CORE_NODES=("crtr" "prtr" "drtr")
declare -a CLUSTER_PSEUDO_NODES=("trtr" "zrtr")
declare -a CLUSTER_ALL_NODES=("crtr" "prtr" "drtr" "trtr" "zrtr")

# Node details (hostname:ip:short)
declare -A CLUSTER_NODE_INFO=(
    [crtr]="cooperator:192.168.254.10:crtr"
    [prtr]="projector:192.168.254.20:prtr"
    [drtr]="director:192.168.254.30:drtr"
    [trtr]="terminator:192.168.254.40:trtr"
    [zrtr]="zerouter:192.168.254.11:zrtr"
)

# Colors for output
if [[ -t 1 ]]; then
    COLOR_RESET='\033[0m'
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_CYAN='\033[0;36m'
    COLOR_BOLD='\033[1m'
else
    COLOR_RESET=''
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_CYAN=''
    COLOR_BOLD=''
fi

# ----------------------------------------------------------------------------
# Output Formatting Functions
# ----------------------------------------------------------------------------

_cluster_info() {
    echo -e "${COLOR_CYAN}ℹ${COLOR_RESET} $*"
}

_cluster_success() {
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"
}

_cluster_warning() {
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $*"
}

_cluster_error() {
    echo -e "${COLOR_RED}✗${COLOR_RESET} $*" >&2
}

_cluster_status() {
    local node="$1"
    local node_status="$2"
    local message="$3"

    local symbol status_color
    case "$node_status" in
        success|up|ok) symbol="✓"; status_color="$COLOR_GREEN" ;;
        warning|skip) symbol="⊗"; status_color="$COLOR_YELLOW" ;;
        error|down|fail) symbol="✗"; status_color="$COLOR_RED" ;;
        *) symbol="·"; status_color="$COLOR_RESET" ;;
    esac

    printf "  ${COLOR_BOLD}%-6s${COLOR_RESET} ${status_color}%s${COLOR_RESET} %s\n" \
        "$node" "$symbol" "$message"
}

# ----------------------------------------------------------------------------
# Node Detection Functions
# ----------------------------------------------------------------------------

_cluster_current_node() {
    local hostname=$(hostname)
    case "$hostname" in
        cooperator) echo "crtr" ;;
        projector) echo "prtr" ;;
        director) echo "drtr" ;;
        terminator) echo "trtr" ;;
        zerouter) echo "zrtr" ;;
        *) echo "unknown" ;;
    esac
}

_cluster_is_core_node() {
    local node="${1:-$(_cluster_current_node)}"
    [[ " ${CLUSTER_CORE_NODES[*]} " =~ " ${node} " ]]
}

_cluster_has_git_repo() {
    [[ -d ~/Projects/colab-config/.git ]]
}

_cluster_has_chezmoi() {
    command -v chezmoi >/dev/null 2>&1
}

# ----------------------------------------------------------------------------
# Interactive Prompt Functions
# ----------------------------------------------------------------------------

_cluster_confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local reply

    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n] " reply
        reply="${reply:-y}"
    else
        read -p "$prompt [y/N] " reply
        reply="${reply:-n}"
    fi

    [[ "$reply" =~ ^[Yy] ]]
}

_cluster_prompt() {
    local question="$1"
    local default="$2"
    local reply

    if [[ -n "$default" ]]; then
        read -p "$question [$default] " reply
        echo "${reply:-$default}"
    else
        read -p "$question " reply
        echo "$reply"
    fi
}

# ----------------------------------------------------------------------------
# SSH Functions
# ----------------------------------------------------------------------------

_cluster_check_ssh() {
    local node="$1"
    ssh -o ConnectTimeout=2 -o BatchMode=yes "$node" exit 2>/dev/null
}

_cluster_ssh_exec() {
    local node="$1"
    shift
    ssh -o ConnectTimeout=5 "$node" "$@"
}

# ----------------------------------------------------------------------------
# Git Functions
# ----------------------------------------------------------------------------

_cluster_git_has_changes() {
    [[ -n $(git status --porcelain 2>/dev/null) ]]
}

_cluster_git_is_synced() {
    git fetch origin -q 2>/dev/null || return 1
    local local_commit=$(git rev-parse HEAD 2>/dev/null)
    local remote_commit=$(git rev-parse origin/master 2>/dev/null)
    [[ "$local_commit" == "$remote_commit" ]]
}

_cluster_git_behind_count() {
    git rev-list --count HEAD..origin/master 2>/dev/null || echo "0"
}

# ----------------------------------------------------------------------------
# Main Commands
# ----------------------------------------------------------------------------

# Push dotfiles to all nodes
push-dotfiles() {
    local commit_message=""
    local force=false
    local dry_run=false
    local skip_git=false
    local target_nodes=("${CLUSTER_CORE_NODES[@]}")

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message)
                commit_message="$2"
                shift 2
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            --skip-git)
                skip_git=true
                shift
                ;;
            --nodes)
                IFS=',' read -ra target_nodes <<< "$2"
                shift 2
                ;;
            -h|--help)
                cat <<EOF
Usage: push-dotfiles [options]

Push dotfile changes from current node to all cluster nodes.

Options:
  -m, --message MSG    Commit message (required if changes exist)
  -f, --force          Force push even if behind upstream
  -n, --dry-run        Show what would happen without doing it
  --skip-git           Skip git commit/push (just sync existing)
  --nodes "node,..."   Deploy to specific nodes only
  -h, --help           Show this help

Examples:
  push-dotfiles -m "Update bash aliases"
  push-dotfiles --skip-git --nodes "prtr,drtr"
  push-dotfiles -n  # Dry run to preview changes
EOF
                return 0
                ;;
            *)
                _cluster_error "Unknown option: $1"
                return 2
                ;;
        esac
    done

    # Validate environment
    local current_node=$(_cluster_current_node)
    _cluster_info "Current node: $current_node"

    if ! _cluster_is_core_node; then
        _cluster_error "This command must be run from a core node (crtr, prtr, drtr)"
        return 3
    fi

    if ! _cluster_has_git_repo; then
        _cluster_error "Git repository not found at ~/Projects/colab-config"
        _cluster_info "Clone with: git clone https://github.com/IMUR/colab-config.git ~/Projects/colab-config"
        return 3
    fi

    # Change to git repo
    cd ~/Projects/colab-config || return 1

    # Handle git operations
    if [[ "$skip_git" == "false" ]]; then
        if _cluster_git_has_changes; then
            _cluster_info "Uncommitted changes detected"
            git status --short
            echo

            if [[ -z "$commit_message" ]]; then
                if [[ "$dry_run" == "true" ]]; then
                    _cluster_warning "Dry run: Would prompt for commit message"
                else
                    commit_message=$(_cluster_prompt "Commit message:")
                    if [[ -z "$commit_message" ]]; then
                        _cluster_error "Commit message required"
                        return 2
                    fi
                fi
            fi

            if [[ "$dry_run" == "true" ]]; then
                _cluster_warning "Dry run: Would commit and push"
            else
                git add dotfiles/ || return 1
                git commit -m "$commit_message" || return 1
                _cluster_success "Committed changes"

                git push || {
                    _cluster_error "Git push failed"
                    if _cluster_confirm "Force push?"; then
                        git push --force
                    else
                        return 1
                    fi
                }
                _cluster_success "Pushed to GitHub"
            fi
        else
            _cluster_info "No uncommitted changes"
        fi
    fi

    echo
    _cluster_info "Deploying to cluster nodes..."
    echo

    # Deploy to each node
    local success_count=0
    local skip_count=0
    local fail_count=0

    for node in "${target_nodes[@]}"; do
        if [[ "$node" == "$current_node" ]]; then
            if [[ "$dry_run" == "true" ]]; then
                _cluster_status "$node" "skip" "Dry run: Would update (current node)"
            else
                if _cluster_has_chezmoi; then
                    if chezmoi update >/dev/null 2>&1; then
                        _cluster_status "$node" "success" "Updated (current node)"
                        ((success_count++))
                    else
                        _cluster_status "$node" "error" "Update failed"
                        ((fail_count++))
                    fi
                else
                    _cluster_status "$node" "skip" "No chezmoi installed"
                    ((skip_count++))
                fi
            fi
            continue
        fi

        if ! _cluster_check_ssh "$node"; then
            _cluster_status "$node" "skip" "Unreachable"
            ((skip_count++))
            continue
        fi

        if [[ "$dry_run" == "true" ]]; then
            _cluster_status "$node" "skip" "Dry run: Would update via SSH"
            continue
        fi

        if _cluster_ssh_exec "$node" 'command -v chezmoi >/dev/null 2>&1' 2>/dev/null; then
            if _cluster_ssh_exec "$node" 'chezmoi update' >/dev/null 2>&1; then
                _cluster_status "$node" "success" "Updated"
                ((success_count++))
            else
                _cluster_status "$node" "error" "Update failed"
                ((fail_count++))
            fi
        else
            _cluster_status "$node" "skip" "No chezmoi installed"
            ((skip_count++))
        fi
    done

    echo
    if [[ "$dry_run" == "true" ]]; then
        _cluster_info "Dry run complete - no changes made"
    else
        _cluster_success "Deployment complete: $success_count succeeded, $skip_count skipped, $fail_count failed"

        if [[ $success_count -gt 0 ]]; then
            if _cluster_confirm "Reload shell on current node?"; then
                exec "$SHELL"
            fi
        fi
    fi
}

# Sync dotfiles on current node
sync-dotfiles() {
    local force=false
    local show_diff=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force) force=true; shift ;;
            --show-diff) show_diff=true; shift ;;
            -h|--help)
                cat <<EOF
Usage: sync-dotfiles [options]

Pull latest dotfiles and apply on current node.

Options:
  -f, --force      Force update even with local changes
  --show-diff      Show what will change before applying
  -h, --help       Show this help
EOF
                return 0
                ;;
            *)
                _cluster_error "Unknown option: $1"
                return 2
                ;;
        esac
    done

    if ! _cluster_has_chezmoi; then
        _cluster_error "Chezmoi not installed on this node"
        return 3
    fi

    _cluster_info "Syncing dotfiles on $(_cluster_current_node)..."

    if [[ "$show_diff" == "true" ]]; then
        echo
        _cluster_info "Changes to apply:"
        chezmoi diff
        echo
        if ! _cluster_confirm "Apply these changes?"; then
            _cluster_info "Cancelled"
            return 0
        fi
    fi

    if chezmoi update; then
        _cluster_success "Dotfiles synced successfully"
        if _cluster_confirm "Reload shell?"; then
            exec "$SHELL"
        fi
    else
        _cluster_error "Sync failed"
        return 1
    fi
}

# Show cluster status
cluster-status() {
    echo "${COLOR_BOLD}Cluster Status:${COLOR_RESET}"
    echo

    for node in "${CLUSTER_ALL_NODES[@]}"; do
        local status_msg=""

        if _cluster_check_ssh "$node"; then
            # Node is reachable
            local has_chezmoi=$(_cluster_ssh_exec "$node" 'command -v chezmoi >/dev/null 2>&1' && echo "yes" || echo "no")

            if [[ "$has_chezmoi" == "yes" ]]; then
                status_msg="UP (chezmoi: installed)"
            else
                status_msg="UP (no chezmoi)"
            fi
            _cluster_status "$node" "success" "$status_msg"
        else
            _cluster_status "$node" "error" "DOWN (unreachable)"
        fi
    done
}

# ----------------------------------------------------------------------------
# Aliases
# ----------------------------------------------------------------------------

alias cstatus='cluster-status'
alias csync='sync-dotfiles'
alias cpush='push-dotfiles'

# ============================================================================
# End of Cluster Management Functions
# ============================================================================
