# ============================================================================
# Cluster Navigation Functions - Co-lab Cluster
# ============================================================================
# Managed by colab-config/dotfiles
# Applied identically across: cooperator, projector, director
#
# Provides convenient functions for:
# - Tmux cluster session management
# - Multi-node window layouts
# - Synchronized pane control
# - Quick node navigation
# ============================================================================

# ----------------------------------------------------------------------------
# Tmux Cluster Session Management
# ----------------------------------------------------------------------------

# Open tmux session with split windows for all 3 nodes
tmux-cluster() {
    local session_name="${1:-cluster}"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' already exists. Attaching..."
        tmux attach-session -t "$session_name"
        return
    fi

    echo "Creating cluster session: $session_name"

    # Create new session with first window for local node
    tmux new-session -d -s "$session_name" -n "local"

    # Split horizontally - top pane stays local
    tmux split-window -h -t "$session_name:local"
    tmux split-window -v -t "$session_name:local.1"

    # Now we have 3 panes:
    # - Pane 0 (left): cooperator
    # - Pane 1 (top-right): projector
    # - Pane 2 (bottom-right): director

    # SSH to other nodes
    tmux send-keys -t "$session_name:local.1" "ssh prtr" C-m
    tmux send-keys -t "$session_name:local.2" "ssh drtr" C-m

    # Select first pane
    tmux select-pane -t "$session_name:local.0"

    # Attach to session
    tmux attach-session -t "$session_name"
}

# Open tmux session for GPU nodes only (projector + director)
tmux-gpu() {
    local session_name="${1:-gpu}"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' already exists. Attaching..."
        tmux attach-session -t "$session_name"
        return
    fi

    echo "Creating GPU nodes session: $session_name"

    # Create new session
    tmux new-session -d -s "$session_name" -n "gpu"

    # Split vertically for 2 nodes
    tmux split-window -v -t "$session_name:gpu"

    # SSH to GPU nodes
    tmux send-keys -t "$session_name:gpu.0" "ssh prtr" C-m
    tmux send-keys -t "$session_name:gpu.1" "ssh drtr" C-m

    # Attach to session
    tmux attach-session -t "$session_name"
}

# Quick attach to existing cluster sessions
tmux-attach-cluster() {
    if tmux has-session -t cluster 2>/dev/null; then
        tmux attach-session -t cluster
    elif tmux has-session -t gpu 2>/dev/null; then
        tmux attach-session -t gpu
    else
        echo "No cluster sessions found. Use 'tmux-cluster' or 'tmux-gpu' to create one."
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Tmux Synchronized Panes (Type Once, Run Everywhere)
# ----------------------------------------------------------------------------

# Enable synchronized input across all panes in current window
tmux-sync-on() {
    if [ -z "$TMUX" ]; then
        echo "Error: Not in a tmux session"
        return 1
    fi
    tmux setw synchronize-panes on
    echo "Synchronized panes: ON (input will go to all panes)"
}

# Disable synchronized input
tmux-sync-off() {
    if [ -z "$TMUX" ]; then
        echo "Error: Not in a tmux session"
        return 1
    fi
    tmux setw synchronize-panes off
    echo "Synchronized panes: OFF (normal input mode)"
}

# Toggle synchronized panes
tmux-sync-toggle() {
    if [ -z "$TMUX" ]; then
        echo "Error: Not in a tmux session"
        return 1
    fi
    tmux setw synchronize-panes
}

# ----------------------------------------------------------------------------
# Quick Node Navigation (within tmux)
# ----------------------------------------------------------------------------

# Open new tmux window and SSH to specified node
tn() {
    local node="$1"

    if [ -z "$TMUX" ]; then
        echo "Error: Not in a tmux session"
        echo "Usage: tn <crtr|prtr|drtr>"
        return 1
    fi

    if [ -z "$node" ]; then
        echo "Usage: tn <crtr|prtr|drtr>"
        return 1
    fi

    case "$node" in
        crtr|cooperator)
            tmux new-window -n "crtr" "ssh crtr || $SHELL"
            ;;
        prtr|projector)
            tmux new-window -n "prtr" "ssh prtr || $SHELL"
            ;;
        drtr|director)
            tmux new-window -n "drtr" "ssh drtr || $SHELL"
            ;;
        *)
            echo "Unknown node: $node"
            echo "Usage: tn <crtr|prtr|drtr>"
            return 1
            ;;
    esac
}

# Mosh variants (if mosh is installed)
tnm() {
    local node="$1"

    if [ -z "$TMUX" ]; then
        echo "Error: Not in a tmux session"
        echo "Usage: tnm <crtr|prtr|drtr>"
        return 1
    fi

    if ! command -v mosh >/dev/null 2>&1; then
        echo "Error: mosh not installed"
        echo "Falling back to regular SSH..."
        tn "$node"
        return
    fi

    if [ -z "$node" ]; then
        echo "Usage: tnm <crtr|prtr|drtr>"
        return 1
    fi

    case "$node" in
        crtr|cooperator)
            tmux new-window -n "crtr" "mosh crtr || $SHELL"
            ;;
        prtr|projector)
            tmux new-window -n "prtr" "mosh prtr || $SHELL"
            ;;
        drtr|director)
            tmux new-window -n "drtr" "mosh drtr || $SHELL"
            ;;
        *)
            echo "Unknown node: $node"
            echo "Usage: tnm <crtr|prtr|drtr>"
            return 1
            ;;
    esac
}

# ----------------------------------------------------------------------------
# Cluster Status & Information
# ----------------------------------------------------------------------------

# Show quick cluster status (using ClusterShell if available)
cluster-status() {
    if command -v clush >/dev/null 2>&1; then
        echo "=== Cluster Status (via ClusterShell) ==="
        clush -b -g all 'echo "$(hostname): Load $(uptime | cut -d, -f3-)"' 2>/dev/null || {
            echo "ClusterShell groups not configured. Falling back to SSH..."
            _cluster_status_fallback
        }
    else
        _cluster_status_fallback
    fi
}

# Fallback cluster status using SSH
_cluster_status_fallback() {
    echo "=== Cluster Status ==="
    for node in crtr prtr drtr; do
        echo -n "$node: "
        ssh -o ConnectTimeout=2 "$node" 'uptime | cut -d, -f3-' 2>/dev/null || echo "unreachable"
    done
}

# Show which nodes are reachable
cluster-ping() {
    echo "=== Cluster Connectivity ==="
    for node in crtr prtr drtr; do
        echo -n "$node: "
        if ping -c 1 -W 1 "$node" >/dev/null 2>&1; then
            echo "✓ reachable"
        else
            echo "✗ unreachable"
        fi
    done
}

# ----------------------------------------------------------------------------
# Tmux Session List & Management
# ----------------------------------------------------------------------------

# List all tmux sessions across all nodes
cluster-tmux-list() {
    echo "=== Tmux Sessions Across Cluster ==="
    echo ""
    echo "Cooperator (crtr):"
    ssh crtr 'tmux list-sessions 2>/dev/null || echo "  No sessions"'
    echo ""
    echo "Projector (prtr):"
    ssh prtr 'tmux list-sessions 2>/dev/null || echo "  No sessions"'
    echo ""
    echo "Director (drtr):"
    ssh drtr 'tmux list-sessions 2>/dev/null || echo "  No sessions"'
}

# ----------------------------------------------------------------------------
# Helper Aliases
# ----------------------------------------------------------------------------

# Short aliases for common operations
alias tc='tmux-cluster'
alias tg='tmux-gpu'
alias ta='tmux-attach-cluster'
alias tsync='tmux-sync-toggle'
alias cstatus='cluster-status'
alias cping='cluster-ping'

# ============================================================================
# Usage Examples
# ============================================================================
#
# Create cluster session:
#   tmux-cluster              # Create session with all 3 nodes
#   tmux-gpu                  # Create session with GPU nodes only
#
# Synchronized input:
#   tmux-sync-on              # Enable (type once, runs on all panes)
#   tmux-sync-off             # Disable
#   tsync                     # Toggle
#
# Quick navigation:
#   tn prtr                   # New window, SSH to projector
#   tnm drtr                  # New window, mosh to director
#
# Cluster status:
#   cluster-status            # Show load across all nodes
#   cluster-ping              # Check connectivity
#   cluster-tmux-list         # Show all tmux sessions
#
# ============================================================================
