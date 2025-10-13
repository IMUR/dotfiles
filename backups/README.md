# Backups Directory

This directory contains essential configuration backups, exports, and snapshots for the cooperator system.

## Directory Structure

```
backups/
├── dns/                    # DNS zone files and configuration
│   ├── ism.la.txt         # GoDaddy DNS zone export
│   └── duckdns/           # DuckDNS configuration backups
├── pihole/                 # Pi-hole configuration exports
│   ├── teleporter/        # Pi-hole Teleporter full exports
│   ├── custom-lists/      # Custom blocklists/allowlists
│   └── dns-records/       # Local DNS record exports
├── services/               # Service-specific configuration backups
│   ├── caddy/             # Caddy configuration snapshots
│   ├── docker/            # Docker compose files and configs
│   ├── systemd/           # Systemd unit file backups
│   ├── n8n/               # n8n workflow exports
│   └── semaphore/         # Semaphore project/inventory exports
├── configs/                # System configuration snapshots
│   ├── network/           # Network configuration files
│   ├── fstab/             # Filesystem mount configs
│   └── ssh/               # SSH configuration (keys NOT included)
└── exports/                # Full system exports
    ├── state-exports/     # Exported state/*.yml snapshots
    ├── live-configs/      # Live system config dumps
    └── migration/         # Migration-specific backups
```

## Purpose

### dns/
**What**: DNS zone files from external DNS providers
**When to update**: After any DNS record changes at GoDaddy or other providers
**Format**: BIND zone file format (.txt)
**Usage**:
- Restore DNS records after provider changes
- Track DNS record history
- Quick reference for current DNS configuration

### pihole/
**What**: Complete Pi-hole configuration exports
**When to update**:
- Before major system changes
- After significant Pi-hole configuration updates
- Before migrations
**Format**:
- Teleporter: `.tar.gz` archive containing complete Pi-hole config
- Custom lists: Plain text files
**Usage**:
- Full Pi-hole restore via Teleporter import
- Migrate Pi-hole to new system
- Restore custom DNS configurations

### services/
**What**: Individual service configuration snapshots
**When to update**:
- Before service updates
- After configuration changes
- Before migrations
**Format**: Service-specific formats (yaml, json, conf files)
**Usage**:
- Rollback service configurations
- Compare config versions
- Migrate services to new systems

### configs/
**What**: System-level configuration files
**When to update**:
- Before OS upgrades
- After network configuration changes
- Before migrations
**Format**: Original config file formats
**Usage**:
- System recovery
- Configuration reference
- Pre-migration snapshots

### exports/
**What**: Complete system state exports
**When to update**:
- Before major system changes
- During migration preparation
- Weekly scheduled backups
**Format**:
- State exports: YAML files
- Live configs: tar.gz archives
**Usage**:
- Full system restore
- Migration preparation
- Disaster recovery

## Backup Best Practices

### Version Control
- All non-sensitive backups are tracked in git
- Sensitive files (API keys, passwords) should be:
  - Stored encrypted
  - Added to .gitignore
  - Backed up to /cluster-nas/backups/

### Naming Convention
```
{service}-{date}-{description}.{ext}

Examples:
- ism.la.txt (DNS zone, latest)
- pihole-teleporter-2025-10-13.tar.gz
- caddy-Caddyfile-2025-10-13-pre-migration.conf
- state-export-2025-10-13.tar.gz
```

### Retention Policy
- **Latest**: Always keep current version
- **Pre-change**: Keep snapshot before any major change
- **Migration**: Keep full backup set during migrations
- **Historical**: Keep monthly snapshots for 1 year

## Git Handling

### What IS committed to git:
- ✅ DNS zone files (public information)
- ✅ Service configurations (without secrets)
- ✅ Systemd unit files
- ✅ Pi-hole exports (sanitized)
- ✅ State exports

### What is NOT committed to git:
- ❌ API keys, tokens, passwords
- ❌ SSL certificates and private keys
- ❌ Database dumps containing sensitive data
- ❌ Complete .env files (store on /cluster-nas)

Sensitive backups should be stored in:
```bash
/cluster-nas/backups/crtr-config/
```

## Common Operations

### Backup DNS Configuration
```bash
# Export from GoDaddy web interface
# Save as: backups/dns/ism.la.txt
```

### Backup Pi-hole
```bash
# Via Pi-hole web interface:
# Settings → Teleporter → Export
# Save to: backups/pihole/teleporter/pihole-teleporter-$(date +%F).tar.gz

# Or via CLI:
pihole -a -t
# Move export to backups/pihole/teleporter/
```

### Backup Service Configs
```bash
# Caddy
sudo cp /etc/caddy/Caddyfile backups/services/caddy/Caddyfile-$(date +%F)

# Docker Compose
cp /cluster-nas/services/n8n/docker-compose.yml \
   backups/services/docker/n8n-docker-compose-$(date +%F).yml

# Systemd units
sudo cp /etc/systemd/system/atuin-server.service \
   backups/services/systemd/atuin-server-$(date +%F).service
```

### Create Full System Export
```bash
cd ~/Projects/crtr-config

# Export current state
./scripts/sync/export-live-state.sh

# Create timestamped snapshot
tar czf backups/exports/state-exports/state-export-$(date +%F).tar.gz state/

# Export live configs
sudo tar czf backups/exports/live-configs/live-configs-$(date +%F).tar.gz \
  /etc/caddy \
  /etc/pihole \
  /etc/dnsmasq.d \
  /etc/systemd/system/*.service
```

### Restore from Backup

#### Restore DNS (GoDaddy)
```bash
# Use backups/dns/ism.la.txt as reference
# Manually recreate records in GoDaddy interface
# Or import via GoDaddy DNS API
```

#### Restore Pi-hole
```bash
# Via web interface:
# Settings → Teleporter → Import
# Select: backups/pihole/teleporter/pihole-teleporter-YYYY-MM-DD.tar.gz

# Or via CLI:
pihole -a -t /path/to/teleporter-backup.tar.gz
```

#### Restore Service Config
```bash
# Example: Restore Caddy config
sudo cp backups/services/caddy/Caddyfile-2025-10-13 /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

## Integration with State Files

The `state/*.yml` files are the **source of truth** for configuration. Backups serve as:
1. **Historical record**: Track config changes over time
2. **External service configs**: DNS, external APIs (not in state/)
3. **Migration snapshots**: Complete system state at migration time
4. **Disaster recovery**: When state/ files are corrupted or lost

**Workflow**:
```
Manual Config Change → Create Backup → Update State Files → Regenerate Configs
```

## Automated Backup Scripts

### Daily Backup (via cron)
```bash
# Add to crontab:
0 3 * * * ~/Projects/crtr-config/scripts/backup-essential-configs.sh
```

### Pre-Migration Backup
```bash
# Run before any migration:
./scripts/backup-pre-migration.sh
```

## Security Considerations

1. **Sensitive Data**: Never commit API keys, passwords, or private keys
2. **Encryption**: Sensitive backups on /cluster-nas should be encrypted
3. **Access Control**: Backup directory should be readable only by crtr user
4. **External Backups**: Critical backups should also exist off-system

## Related Documentation

- [MIGRATION-DEBIAN-TO-RASPIOS.md](../docs/MIGRATION-DEBIAN-TO-RASPIOS.md) - Migration procedures
- [MINIMAL-DOWNTIME-MIGRATION.md](../docs/MINIMAL-DOWNTIME-MIGRATION.md) - Fast migration strategy
- [COOPERATOR-ASPECTS.md](../COOPERATOR-ASPECTS.md) - Complete system reference
- [CLAUDE.md](../CLAUDE.md) - Repository guidelines

---

**Last Updated**: 2025-10-13
**Maintainer**: crtr
