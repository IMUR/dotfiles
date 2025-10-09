# Infrastructure SSOT System (Cluster-Level)

**Single Source of Truth** for the entire Co-lab cluster infrastructure, auto-generated from live systems.

## Scope

This is the **cluster-level SSOT** that discovers all 3 nodes from a central location.

For **node-level SSOT**, see each node's `.meta/ssot/` directory:
- `~/Projects/crtr-config/.meta/ssot/` - cooperator node truth
- `~/Projects/prtr-config/.meta/ssot/` - projector node truth
- `~/Projects/drtr-config/.meta/ssot/` - director node truth

## What Is This?

The SSOT system eliminates stale documentation by **querying actual infrastructure** and generating truth from reality:

- ✅ **DNS records** from GoDaddy API
- ✅ **Hardware specs** from SSH queries to nodes
- ✅ **Running services** from Docker + systemd
- ✅ **Network config** from live cluster state

**No more manual documentation updates** - the truth is automatically discovered.

## Quick Start

```bash
# Discover current infrastructure (generates YAML for all 3 nodes)
./.meta/ssot/ssot discover

# Check status
./.meta/ssot/ssot status

# Validate SSOT against current state
./.meta/ssot/ssot validate
```

## Files

| File | Purpose |
|------|---------|
| `infrastructure-truth.yaml` | **The SSOT** - authoritative infrastructure state |
| `ssot` | Main command wrapper |
| `discover-truth.sh` | Auto-discovery script |
| `validate-truth.sh` | Validation against live state |
| `cache/` | Validation results and metadata |

## How It Works

### 1. Discovery

```bash
./scripts/ssot/ssot discover
```

**Collects from**:
- GoDaddy API → DNS records
- SSH to crtr, prtr, drtr → Hardware, services, containers
- Generates `infrastructure-truth.yaml` with **real data**

### 2. YAML Structure

```yaml
metadata:
  version: "1.0.0"
  last_discovered: "2025-10-06T15:06:21Z"
  collectors_used:
    - godaddy-api
    - ssh-hardware
    - ssh-services

dns:
  provider: godaddy
  domain: ism.la
  records:
    - type: A
      name: "@"
      value: "47.154.26.190"
      ttl: 3600
    # ... 18 total records

nodes:
  crtr:
    network:
      hostname: cooperator
      ip: 192.168.254.10
      role: gateway
    hardware:
      architecture: aarch64
      cpu: "ARM Cortex-A76"
      cores: 4
      ram: "16Gi"
    services:
      docker:
        version: "28.5.0"
        containers:
          - n8n
          - n8n-postgres
      systemd:
        - caddy.service
        - pihole-FTL.service
        # ... running services

  prtr:
    # ... projector node data

  drtr:
    # ... director node data
```

### 3. Validation

```bash
./scripts/ssot/ssot validate
```

**Checks**:
- DNS records match GoDaddy
- Nodes are reachable
- Hardware specs match
- Docker is running as expected

### 4. Status

```bash
./scripts/ssot/ssot status
```

Shows:
- Last discovery time
- Last validation time
- Node count
- DNS record count

## Integration with Alignment System

The SSOT becomes **Tier 0** in alignment:

```yaml
# In .meta/alignment-rules.yml
sources_of_truth:
  tier_0_queryable:
    - path: "scripts/ssot/infrastructure-truth.yaml"
      type: "dynamic_ssot"
      authority_level: "definitive"
      source: "auto-collected from live infrastructure"
      validated_against: ["godaddy-api", "ssh-queries", "docker-api"]

  tier_1_generated:
    - path: "docs/architecture/NETWORK-TOPOLOGY.md"
      generated_from: "scripts/ssot/infrastructure-truth.yaml"
      authority_level: "derived"
```

## Automation

### Manual Updates
```bash
# Run whenever you want fresh data
./scripts/ssot/ssot discover
```

### Cron Job (Every 6 hours)
```bash
0 */6 * * * cd /home/crtr/Projects/colab-config && ./scripts/ssot/ssot discover
```

### Pre-commit Hook
```bash
# .git/hooks/pre-commit
#!/bin/bash
./scripts/ssot/ssot validate || echo "Warning: SSOT validation failed"
```

## Requirements

1. **Passwordless SSH** to all nodes (crtr, prtr, drtr)
2. **GoDaddy API credentials** in `.env.godaddy`
3. **Network connectivity** to all cluster nodes

## Cluster vs Node SSOT

**Cluster SSOT** (this directory):
- Discovers **all 3 nodes** via SSH
- Requires network connectivity to all nodes
- Includes DNS records (GoDaddy API)
- Run from cooperator or any machine with cluster access

**Node SSOT** (in each node's config repo):
- Discovers **only local node** (no SSH required)
- Auto-detects hostname, IP, architecture, role
- Node-specific hardware and service discovery
- Run locally on each node

## Location-Agnostic Design

The cluster SSOT works **from anywhere** with cluster network access:
- Can run from any node (crtr, prtr, drtr)
- Can run from laptop connected to cluster network
- Uses SSH for all node queries
- Requires passwordless SSH to all nodes

## Next Steps

### Immediate
1. ✅ Discovery working
2. ⏳ Validation needs timeout fixes
3. ⏳ Update alignment system to use SSOT

### Future Enhancements
1. Vector cache (qcash) integration
2. Auto-generate docs from SSOT
3. Drift detection and alerts
4. Historical SSOT snapshots

## Philosophy

**Documentation should not be the source of truth. Reality is.**

This system inverts the traditional approach:
- ❌ Old way: Update infrastructure → manually update docs → docs become stale
- ✅ New way: Update infrastructure → auto-discover → docs always current

The SSOT is **queryable**, **validatable**, and **version-controlled**.

## Commands Reference

```bash
./.meta/ssot/ssot discover   # Generate SSOT from live infrastructure
./.meta/ssot/ssot validate   # Check SSOT matches reality
./.meta/ssot/ssot status     # Show SSOT information
./.meta/ssot/ssot help       # Show help
```

## Files Generated

- `infrastructure-truth.yaml` - The SSOT (commit to git)
- `cache/validation-report.txt` - Last validation results
- `cache/last-validation-time.txt` - When validated
- `cache/last-validation-hash.txt` - Content hash for change detection

---

**Type**: Cluster-level infrastructure discovery
**Scope**: All 3 Co-lab nodes + DNS
**Location**: colab-config/.meta/ssot/
**Created**: 2025-10-06
**Status**: Functional (discovery working, validation needs refinement)
