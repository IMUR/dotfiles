# Node SSOT (Template)

**Single Source of Truth** for a single node, auto-discovered locally.

## Purpose

This template is deployed to each node's `~/Projects/<user>-config/.meta/ssot/` directory.

Each node runs its own discovery script that auto-detects:
- Hostname (cooperator/projector/director)
- Node short name (crtr/prtr/drtr)
- Role (gateway/compute/ml_platform)
- IP address (192.168.254.x)
- Architecture (aarch64/x86_64)
- Hardware specs (CPU, cores, RAM, storage, GPU)
- Running services (Docker containers, systemd services)

## Key Features

**No SSH Required**: Runs entirely locally

**Auto-Detection**: All node-specific details discovered automatically

**Identical Template**: Same script runs on all 3 nodes, adapts to each

**Node-Specific Output**: Each node gets its own `node-truth.yaml`

## Usage

```bash
# Run discovery on this node
./.meta/ssot/discover-node-truth.sh

# Output: node-truth.yaml with THIS node's infrastructure
```

## Example Output

```yaml
node:
  identity:
    hostname: cooperator
    short_name: crtr
    role: gateway

  network:
    primary_ip: 192.168.254.10

  hardware:
    architecture: aarch64
    cpu: "ARM Cortex-A76"
    cores: 4
    ram: "15Gi"
    # ... auto-detected specs
```

## Deployment

This template is deployed by running on each node:
```bash
colab-config/.meta/DEPLOY-NODE-META.sh
```

Or manually copy to each node's `.meta/ssot/` directory.

## Cluster vs Node SSOT

**Node SSOT** (this):
- Discovers only THIS node
- Runs locally (no SSH)
- Auto-detects all node specifics
- Located in `~/Projects/<user>-config/.meta/ssot/`

**Cluster SSOT**:
- Discovers all 3 nodes via SSH
- Includes DNS records
- Located in `colab-config/.meta/ssot/`
