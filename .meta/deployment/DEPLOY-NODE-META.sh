#!/bin/bash
# Deploy node-level .meta/ to projector and director nodes
# Includes SSOT discovery template
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$META_DIR/foundation/templates/node-ssot"
WHITELIST_FILE="$META_DIR/whitelists/NODE-META-WHITELIST.yml"

create_node_meta() {
    local node_name=$1
    local node_short=$2
    local node_ip=$3
    local node_arch=$4
    local node_role=$5
    local target_dir="$HOME/Projects/${node_short}-config/.meta"

    echo "Creating .meta/ structure for ${node_name}..."

    mkdir -p "${target_dir}"

    # META-TYPE.txt
    echo "node" > "${target_dir}/META-TYPE.txt"

    # NODE-PRINCIPLES.md
    cat > "${target_dir}/NODE-PRINCIPLES.md" <<EOF
# Node Principles

## Node Identity

- This is \`${node_name}\` (${node_short}) - ${node_ip}
- ${node_role}
- Architecture: ${node_arch}

## Configuration Scope

- Node-specific personality respecting cluster UX baseline
- Local variations that don't pollute cluster-wide config
- Experimental tooling before promotion to colab-config

## Relationship to Cluster

- Inherits UX baseline from \`colab-config/dotfiles/\` via Chezmoi
- Node-specific configs managed locally in this repo
- Hardware-specific configurations for ${node_arch} architecture
- ${node_role}-specific services and configurations
EOF

    # NODE-README.md
    cat > "${target_dir}/NODE-README.md" <<EOF
# .meta/ - Node Meta-Management

**Type:** \`node\`
**Node:** \`${node_name}\` (${node_short})
**IP:** ${node_ip}

This directory contains node-specific principles, architecture, and operational metadata for the ${node_name} node.

## Purpose

Node-level .meta/ defines "how this node operates within the cluster" through:

- Node identity and role specifications
- Node-specific architectural decisions
- Hardware-specific configuration guidance
- Local operational knowledge for AI assistants

## Contents

### Node Foundation

- **NODE-PRINCIPLES.md** - Core principles for this node's configuration
- **META-TYPE.txt** - Identifies this as node-level metadata

## Relationship to Cluster

- Inherits cluster-wide principles from \`colab-config/.meta/\`
- Implements node-specific configurations respecting cluster UX baseline
- Hardware: ${node_arch}
- Role: ${node_role}

## See Also

- Cluster .meta/ at \`/home/crtr/Projects/colab-config/.meta/\`
- Sibling nodes: cooperator (crtr-config), projector (prtr-config), director (drtr-config)
EOF

    # Deploy SSOT template
    mkdir -p "${target_dir}/ssot"

    # Copy SSOT discovery script
    if [[ -f "$TEMPLATE_DIR/discover-node-truth.sh" ]]; then
        cp "$TEMPLATE_DIR/discover-node-truth.sh" "${target_dir}/ssot/"
        chmod +x "${target_dir}/ssot/discover-node-truth.sh"
    fi

    # Copy SSOT README
    if [[ -f "$TEMPLATE_DIR/README.md" ]]; then
        cp "$TEMPLATE_DIR/README.md" "${target_dir}/ssot/"
    fi

    # Create .gitignore for SSOT cache
    cat > "${target_dir}/ssot/.gitignore" <<'EOF'
# Ignore generated truth file (regenerate on each node)
node-truth.yaml
cache/
EOF

    # Deploy node meta whitelist
    if [[ -f "$WHITELIST_FILE" ]]; then
        cp "$WHITELIST_FILE" "${target_dir}/"
    fi

    echo "✓ Created .meta/ for ${node_name} at ${target_dir}"
    echo "  ✓ Deployed SSOT discovery template"
    echo "  ✓ Deployed node meta whitelist"
}

# Deploy to projector (if running on prtr)
if [[ "$(hostname)" == "projector" ]]; then
    create_node_meta "projector" "prtr" "192.168.254.20" "x86_64" "Primary compute, Multi-GPU (4x)"
fi

# Deploy to director (if running on drtr)
if [[ "$(hostname)" == "director" ]]; then
    create_node_meta "director" "drtr" "192.168.254.30" "x86_64" "ML platform, Single GPU (1x)"
fi

# If running on cooperator, deploy locally and show remote instructions
if [[ "$(hostname)" == "cooperator" ]]; then
    create_node_meta "cooperator" "crtr" "192.168.254.10" "aarch64" "Gateway, NFS, DNS authority"

    echo ""
    echo "To deploy to other nodes:"
    echo ""
    echo "  ssh projector 'bash -s' < $(realpath "$0")"
    echo "  ssh director 'bash -s' < $(realpath "$0")"
    echo ""
    echo "Or manually copy and run on each node."
    echo ""
    echo "After deployment, run on each node:"
    echo "  cd ~/Projects/<user>-config/.meta/ssot/"
    echo "  ./discover-node-truth.sh"
fi
