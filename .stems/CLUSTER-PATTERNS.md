# Cluster Patterns for 3-Node Topology

## Topology Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    crtr     │────│    prtr     │────│    drtr     │
│  Gateway &  │     │  GPU/Comp   │     │  ML Platform│
│  Services   │     │   Node      │     │    Node     │
│192.168.254  │     │192.168.254  │     │192.168.254  │
│    .10      │     │    .20      │     │    .30      │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       └───────────────────┴───────────────────┘
              Shared Storage (NAS/NFS)
```

## Node Role Patterns

### Pattern: Specialized Nodes with Shared Foundation

**Problem:** Different hardware capabilities but need unified experience.

**Solution:** Layer specialization on common base.

```yaml
# Base layer (all nodes)
base_config:
  shell: zsh
  tools: [git, vim, tmux]
  ssh_keys: shared
  user: consistent

# Specialization layer
node_specialization:
  crtr:
    role: gateway
    services: [nginx, dns, monitoring]
    
  prtr:
    role: compute
    runtime: [cuda, pytorch, tensorflow]
    gpu_allocation: dynamic
    
  drtr:
    role: ml_platform
    services: [jupyter, mlflow, wandb]
```

### Pattern: Service Placement Strategy

**Problem:** Where to run which services?

**Solution:** Hardware-aware placement.

```yaml
service_placement:
  # Gateway services on crtr
  ingress:
    node: crtr
    reason: "External access point"
    
  # GPU workloads on prtr
  model_training:
    node: prtr
    reason: "GPU availability"
    
  # Interactive platforms on drtr
  notebooks:
    node: drtr
    reason: "User-facing, no GPU needed"
    
  # Distributed services
  monitoring:
    node: all
    reason: "Local metrics collection"
```

## Configuration Distribution Patterns

### Pattern: Push-Based Configuration

**Problem:** How to distribute configuration to all nodes?

**Solution:** Git pull + local apply.

```bash
# Central repo push
git add . && git commit -m "Update config"
git push origin main

# Each node pulls and applies
for node in crtr prtr drtr; do
    ssh $node "cd ~/colab-config && git pull && chezmoi apply"
done
```

### Pattern: Template Variable Hierarchy

**Problem:** Managing common and specific variables.

**Solution:** Layered variable resolution.

```yaml
# Global variables (all nodes)
global:
  cluster_name: colab
  domain: local
  timezone: UTC

# Architecture variables
arch_specific:
  arm64:
    docker_platform: linux/arm64
  x86_64:
    docker_platform: linux/amd64

# Node variables (highest priority)
node_specific:
  crtr:
    hostname: cooperator
    ip: 192.168.254.10
    arch: x86_64
```

### Pattern: Configuration Validation Pipeline

**Problem:** Ensuring configuration works before deployment.

**Solution:** Multi-stage validation.

```bash
#!/bin/bash
# validate-config.sh

# Stage 1: Syntax validation
echo "Checking syntax..."
chezmoi verify || exit 1
ansible-playbook --syntax-check site.yml || exit 1

# Stage 2: Dry run
echo "Running simulation..."
chezmoi diff || exit 1
ansible-playbook --check site.yml || exit 1

# Stage 3: Approval
echo "Changes will be:"
chezmoi diff --no-pager
read -p "Apply? (y/n) " -n 1 -r
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

# Stage 4: Application
echo "Applying configuration..."
chezmoi apply
ansible-playbook site.yml
```

## Communication Patterns

### Pattern: SSH Mesh Topology

**Problem:** Enable any-node-to-any-node access.

**Solution:** Shared SSH keys with host aliases.

```ssh-config
# ~/.ssh/config on all nodes

Host crtr cooperator
    HostName 192.168.254.10
    User trtr
    
Host prtr projector
    HostName 192.168.254.20
    User trtr
    
Host drtr director
    HostName 192.168.254.30
    User trtr
```

### Pattern: Service Discovery

**Problem:** Services need to find each other.

**Solution:** Static resolution via hosts/DNS.

```yaml
# /etc/hosts (managed by Ansible)
192.168.254.10 cooperator cooperator.local crtr
192.168.254.20 projector projector.local prtr
192.168.254.30 director director.local drtr

# Service endpoints
192.168.254.10 prometheus.local grafana.local
192.168.254.20 gpu-server.local
192.168.254.30 jupyter.local mlflow.local
```

## Storage Patterns

### Pattern: Shared Configuration Store

**Problem:** Configuration needs to be accessible from all nodes.

**Solution:** NFS-mounted shared directory.

```yaml
# /etc/fstab (via Ansible)
nas.local:/volume1/colab /mnt/colab-shared nfs defaults 0 0

# Usage
shared_paths:
  configs: /mnt/colab-shared/configs
  datasets: /mnt/colab-shared/datasets
  models: /mnt/colab-shared/models
  backups: /mnt/colab-shared/backups
```

### Pattern: Local Cache with Shared Fallback

**Problem:** Performance vs consistency.

**Solution:** Local caching with periodic sync.

```bash
# Local cache structure
/var/cache/colab/
├── configs/     # Cached configurations
├── packages/    # Cached packages
└── metadata/    # Cache metadata

# Sync script
#!/bin/bash
rsync -av --delete \
    /mnt/colab-shared/configs/ \
    /var/cache/colab/configs/
```

## Operational Patterns

### Pattern: Rolling Updates

**Problem:** Updating nodes without full cluster downtime.

**Solution:** Sequential updates with validation.

```bash
#!/bin/bash
# rolling-update.sh

nodes=(crtr prtr drtr)
for node in "${nodes[@]}"; do
    echo "Updating $node..."
    
    # Pre-update validation
    ssh $node "cd ~/colab-config && ./validate.sh" || exit 1
    
    # Apply update
    ssh $node "cd ~/colab-config && git pull && chezmoi apply"
    
    # Post-update validation
    ssh $node "cd ~/colab-config && ./health-check.sh" || exit 1
    
    echo "$node updated successfully"
    sleep 5  # Grace period
done
```

### Pattern: Cluster-Wide Commands

**Problem:** Running commands across all nodes.

**Solution:** Parallel SSH execution.

```bash
#!/bin/bash
# cluster-exec.sh

command="$1"
for node in crtr prtr drtr; do
    echo "[$node]"
    ssh "$node" "$command" &
done
wait
```

### Pattern: Health Monitoring

**Problem:** Knowing cluster state at a glance.

**Solution:** Lightweight status checks.

```bash
#!/bin/bash
# cluster-status.sh

echo "Cluster Status Report"
echo "===================="

# Node availability
for node in crtr prtr drtr; do
    if ssh -o ConnectTimeout=2 "$node" "echo ok" &>/dev/null; then
        echo "✓ $node: Online"
    else
        echo "✗ $node: Offline"
    fi
done

# Service status
echo ""
echo "Services:"
ssh crtr "docker ps --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null

# Resource usage
echo ""
echo "Resources:"
for node in crtr prtr drtr; do
    echo -n "$node: "
    ssh "$node" "free -h | grep Mem | awk '{print \$3\"/\"\$2}'" 2>/dev/null
done
```

## Failure Patterns

### Pattern: Single Node Failure Handling

**Problem:** One node becomes unavailable.

**Solution:** Degraded operation with clear status.

```yaml
failure_modes:
  crtr_down:
    impact: "No external access, no gateway services"
    mitigation: "Direct connection to other nodes"
    
  prtr_down:
    impact: "No GPU compute available"
    mitigation: "Queue jobs or use CPU fallback"
    
  drtr_down:
    impact: "No ML platform services"
    mitigation: "Use CLI tools or direct compute"
```

### Pattern: Configuration Rollback

**Problem:** Bad configuration deployed.

**Solution:** Git-based instant rollback.

```bash
#!/bin/bash
# rollback.sh

# Get previous commit
previous=$(git rev-parse HEAD~1)

# Rollback
git checkout "$previous"

# Apply on all nodes
for node in crtr prtr drtr; do
    ssh "$node" "cd ~/colab-config && git pull && chezmoi apply --force"
done

echo "Rolled back to $previous"
```

## Scale Patterns

### Pattern: Add Fourth Node

**Problem:** Expanding beyond 3 nodes.

**Solution:** Extend patterns, don't restructure.

```yaml
# Easy extension
nodes:
  existing: [crtr, prtr, drtr]
  new: wrtr  # New worker node
  
# Update patterns
network:
  wrtr: 192.168.254.40
  
roles:
  wrtr: worker  # Generic compute
  
# No architectural changes needed
```

### Pattern: Service Scaling

**Problem:** Service needs more resources.

**Solution:** Vertical scaling within node limits.

```yaml
# docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2.0'    # Increase
          memory: '4G'    # Increase
        reservations:
          cpus: '1.0'
          memory: '2G'
```

## Migration Patterns

### Pattern: Blue-Green Configuration

**Problem:** Testing new configuration safely.

**Solution:** Parallel configuration with switch.

```bash
# Prepare green (new) config
git checkout -b green-config
# Make changes
git commit -am "New configuration"

# Test on single node
ssh crtr "cd ~/colab-config && git checkout green-config && chezmoi apply"

# If successful, apply everywhere
for node in prtr drtr; do
    ssh "$node" "cd ~/colab-config && git checkout green-config && chezmoi apply"
done

# Make permanent
git checkout main
git merge green-config
```

## Documentation Patterns

### Pattern: Configuration Documentation

**Problem:** Understanding why configuration exists.

**Solution:** Inline documentation in templates.

```yaml
# Template with documentation
# Purpose: Configure cluster networking
# Dependency: Requires static IPs assigned
# Last-Updated: 2025-01-27
# Author: Infrastructure Team

network:
  # Gateway node handles external traffic
  gateway: {{ .gateway_ip }}  # Usually crtr
  
  # Internal communication subnet
  internal_subnet: {{ .internal_subnet }}  # Must not conflict with home network
```

### Pattern: Decision Records

**Problem:** Remembering why decisions were made.

**Solution:** Architecture Decision Records (ADRs).

```markdown
# ADR-001: Use Chezmoi for Dotfiles

## Status
Accepted

## Context
Need consistent user environment across nodes.

## Decision
Use Chezmoi for managing dotfiles.

## Consequences
- ✓ Template support for node differences
- ✓ Built-in diff and apply
- ✗ Additional tool to learn
- ✗ Requires Go runtime
```

## Summary

These patterns provide proven solutions for common 3-node cluster challenges. They emphasize:

- **Simplicity** over complexity
- **Explicit** configuration over magic
- **Manual control** over automation
- **Clear boundaries** over flexibility

Apply patterns as needed, adapt to your specific requirements, and document your variations.
