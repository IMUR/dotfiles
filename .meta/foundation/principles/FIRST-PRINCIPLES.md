# First Principles

## System Identity

- The 3-node cluster is treated as a unified personal machine
- No personal/cluster dichotomy applies to core nodes (crtr, prtr, drtr)
- The cluster has a single operational identity

## Configuration Organization

- Configuration is organized by **operational relationships** (aspects)
- Each aspect defines a boundary of operational concern
- Aspects are separated by what they manage, not by tool or location

## UX Parity

- User experience must be identical across all 3 core nodes
- Baseline shell environment is cluster-wide, not per-node
- SSH into any node yields the same operational interface

## Hardware Realism

- UX parity has hard cap defined by hardware differences (ARM64 vs x86_64, GPU count)
- Parity within reason: compatability and best practices override forced uniformity
- Hardware-specific configuration is acceptable when necessary

## Scope Boundaries

- Cluster-wide identical → aspect managed centrally
- Node-specific variation → aspect managed locally
- Decision boundary: "Would this be identical on all 3 nodes?"

## Node Independence

- Each node maintains its own identity and credentials
- Nodes are sovereign entities within unified cluster
- No shared secrets between nodes
- Inter-node trust is explicitly configured, never implicit
