# Documentation Index

**Last Updated:** 2025-10-13

## Quick Start

**New to this repository?** → Read [START-HERE.md](../START-HERE.md)

**For AI assistants:** → Read [CLAUDE.md](../CLAUDE.md)

## Core Documentation

### Repository Overview
- [README.md](../README.md) - Repository overview and quick links
- [START-HERE.md](../START-HERE.md) - Comprehensive getting started guide
- [CLAUDE.md](../CLAUDE.md) - AI assistant operational guidance

### System Reference
- [COOPERATOR-ASPECTS.md](../COOPERATOR-ASPECTS.md) - Complete technical reference for cooperator node

## Architecture & Design

### Core Architecture
- [ARCHITECTURE.md](architecture/ARCHITECTURE.md) - Schema-first system design
- [VISION.md](architecture/VISION.md) - Why schema-first, benefits, philosophy

## Infrastructure Documentation

### Network & Nodes
- [NODE-PROFILES.md](NODE-PROFILES.md) - Cluster node specifications
- [network-spec.md](network-spec.md) - Network topology and configuration
- [INFRASTRUCTURE-INDEX.md](INFRASTRUCTURE-INDEX.md) - Infrastructure documentation index

### Backups & Recovery
- [BACKUP-STRUCTURE.md](BACKUP-STRUCTURE.md) - Backup organization and strategy
- [backups/README.md](../backups/README.md) - Backup directory documentation

## Migration Documentation

**Current Migration:** Debian SD card → Raspberry Pi OS USB

- [MINIMAL-DOWNTIME-MIGRATION.md](MINIMAL-DOWNTIME-MIGRATION.md) - Detailed migration procedure (<45 min downtime)
- [MIGRATION-CHECKLIST.md](MIGRATION-CHECKLIST.md) - Printable execution checklist

## Scripts & Tools

### DNS Management
- [scripts/dns/README.md](../scripts/dns/README.md) - DNS management tools
- [scripts/dns/QUICKSTART.md](../scripts/dns/QUICKSTART.md) - Quick reference for DNS updates

### Infrastructure Truth
- [scripts/ssot/README.md](../scripts/ssot/README.md) - Single source of truth utilities

## Repository Structure

```
crtr-config/
├── README.md                   # Overview
├── START-HERE.md               # Getting started
├── CLAUDE.md                   # AI guidance
├── COOPERATOR-ASPECTS.md       # Technical reference
│
├── docs/                       # Documentation hub
│   ├── INDEX.md                # This file
│   ├── architecture/           # Design docs
│   ├── MINIMAL-DOWNTIME-MIGRATION.md
│   ├── MIGRATION-CHECKLIST.md
│   └── [infrastructure docs]
│
├── state/                      # Source of truth (EDIT HERE)
│   ├── services.yml
│   ├── domains.yml
│   ├── network.yml
│   └── node.yml
│
├── config/                     # Generated configs (DO NOT EDIT)
├── backups/                    # Backup snapshots
├── scripts/                    # Operational tools
└── archives/                   # Old documentation
```

## Finding Information

### I want to...

**Understand the system architecture** → [architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md)

**Migrate to new OS** → [MINIMAL-DOWNTIME-MIGRATION.md](MINIMAL-DOWNTIME-MIGRATION.md)

**Update DNS records** → [scripts/dns/QUICKSTART.md](../scripts/dns/QUICKSTART.md)

**Backup/restore configs** → [BACKUP-STRUCTURE.md](BACKUP-STRUCTURE.md)

**Learn about the cluster** → [NODE-PROFILES.md](NODE-PROFILES.md)

**Add a new service** → [CLAUDE.md](../CLAUDE.md) - Workflow Patterns section

**Troubleshoot issues** → [COOPERATOR-ASPECTS.md](../COOPERATOR-ASPECTS.md) - Complete reference

## Documentation Status

**Last Cleanup:** 2025-10-13
**Files Archived:** 9 (moved to archives/old-docs-2025-10-13/)
**Current Docs:** 18 essential files
**Focus:** Schema-first infrastructure, migration, operations
