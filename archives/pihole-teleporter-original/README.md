# Pi-hole Teleporter Export (Original)

**Date:** Original export from Debian SD card system
**Purpose:** Historical reference - Pi-hole configuration snapshot

## Contents

This directory contains the original Pi-hole Teleporter export from the Debian SD card system:

- `pihole/` - Pi-hole configuration files
- `dnsmasq.d/` - DNS override configurations
- `hosts` - Local hostname mappings

## Why Archived

This was moved from `etc/` to resolve directory redundancy:

- **`etc/`** (this archive) - Static historical snapshot from Teleporter export
- **`backups/pihole/`** - Ongoing Pi-hole backups (current)
- **`config/pihole/`** - Generated configs from state/ (schema-first)

The schema-first architecture means:
- State files (`state/domains.yml`, `state/services.yml`) are source of truth
- Configs generate from state
- Static snapshots are archived for reference only

## If You Need This

These files are preserved for historical reference. If you need to reference the original Teleporter export configuration, it's here.

For current Pi-hole backups, use `backups/pihole/teleporter/`.

## Pi-hole Databases Not Included

Note: Pi-hole databases (`.db` files) should NOT be in git. They contain:
- Query logs (browsing history)
- MAC addresses (network topology)

These should be backed up separately and encrypted if sensitive.
