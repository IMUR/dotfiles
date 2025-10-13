# Backup Structure Documentation

**Created**: 2025-10-13
**Purpose**: Document the backup and export directory structure for essential configuration files

---

## Overview

The `backups/` directory has been created to organize all essential configuration backups, exports, and snapshots in a structured, maintainable way.

## Directory Structure

```
backups/
├── README.md              # Comprehensive backup documentation
├── .gitignore             # Protects sensitive files from being committed
│
├── dns/                   # DNS zone files and configuration
│   ├── ism.la.txt        # ✅ GoDaddy DNS zone export (already added)
│   └── duckdns/          # DuckDNS configuration backups
│
├── pihole/                # Pi-hole configuration exports
│   ├── teleporter/       # 📦 Add Pi-hole Teleporter exports here
│   ├── custom-lists/     # Custom blocklists/allowlists
│   └── dns-records/      # Local DNS record exports
│
├── services/              # Service-specific configuration backups
│   ├── caddy/            # Caddy configuration snapshots
│   ├── docker/           # Docker compose files and configs
│   ├── systemd/          # Systemd unit file backups
│   ├── n8n/              # n8n workflow exports
│   └── semaphore/        # Semaphore project/inventory exports
│
├── configs/               # System configuration snapshots
│   ├── network/          # Network configuration files
│   ├── fstab/            # Filesystem mount configs
│   └── ssh/              # SSH configuration (keys NOT included)
│
└── exports/               # Full system exports
    ├── state-exports/    # Exported state/*.yml snapshots
    ├── live-configs/     # Live system config dumps
    └── migration/        # Migration-specific backups
```

## Files Already Organized

### ✅ DNS Zone File
- **Location**: `backups/dns/ism.la.txt`
- **Source**: GoDaddy DNS zone export
- **Content**: Complete ism.la zone file with all CNAME records
- **Last Updated**: 2025-10-13 12:44:14

## Files to Add

### 📦 Pi-hole Teleporter Export
**Where to put it**: `backups/pihole/teleporter/`

If you have the Pi-hole Teleporter export file, please move it to:
```bash
mv /path/to/pihole-teleporter-*.tar.gz \
   ~/Projects/crtr-config/backups/pihole/teleporter/
```

**File naming convention**:
- `pihole-teleporter-2025-10-13.tar.gz` (with date)
- Or keep original filename if it includes timestamp

## What Gets Committed to Git

### ✅ Safe to Commit (Public/Non-Sensitive)
- DNS zone files (public DNS records)
- Service configuration templates (without secrets)
- Systemd unit files
- Pi-hole exports (sanitized, no API keys)
- State exports (YAML files)
- Network config templates

### ❌ NOT Committed (Sensitive/Private)
Protected by `.gitignore`:
- API keys, tokens, passwords
- SSL certificates and private keys
- SSH private keys
- Database dumps with sensitive data
- Complete .env files
- Large archives (*.tar.gz, *.zip)

**Where sensitive backups go**:
```
/cluster-nas/backups/crtr-config/sensitive/
```

## Usage Examples

### Add DNS Zone Export
```bash
# After exporting from GoDaddy
cp ~/Downloads/ism.la.txt ~/Projects/crtr-config/backups/dns/

# Commit to git
cd ~/Projects/crtr-config
git add backups/dns/ism.la.txt
git commit -m "Update DNS zone file from GoDaddy"
```

### Add Pi-hole Export
```bash
# After exporting from Pi-hole Teleporter
mv ~/Downloads/pihole-teleporter-*.tar.gz \
   ~/Projects/crtr-config/backups/pihole/teleporter/

# Note: Large .tar.gz files are in .gitignore
# For git tracking, extract and commit only configs:
mkdir -p /tmp/pihole-extract
tar xzf backups/pihole/teleporter/pihole-teleporter-*.tar.gz -C /tmp/pihole-extract

# Review and selectively commit non-sensitive configs
cp /tmp/pihole-extract/custom.list backups/pihole/dns-records/
git add backups/pihole/dns-records/custom.list
git commit -m "Update Pi-hole custom DNS records"
```

### Backup Service Configs
```bash
# Caddy
sudo cp /etc/caddy/Caddyfile \
   ~/Projects/crtr-config/backups/services/caddy/Caddyfile-$(date +%F)

# Custom systemd services
sudo cp /etc/systemd/system/atuin-server.service \
   ~/Projects/crtr-config/backups/services/systemd/

# Docker compose
cp /cluster-nas/services/n8n/docker-compose.yml \
   ~/Projects/crtr-config/backups/services/docker/n8n-docker-compose-$(date +%F).yml

# Commit
git add backups/services/
git commit -m "Backup service configurations"
```

### Create State Export
```bash
cd ~/Projects/crtr-config

# Export current live state
./scripts/sync/export-live-state.sh

# Create timestamped backup
tar czf backups/exports/state-exports/state-export-$(date +%F).tar.gz state/

# Note: .tar.gz files ignored by git
# Instead, commit the individual state/*.yml files
git add state/
git commit -m "Update state from live system export"
```

## Backup Checklist

### Before Major Changes
- [ ] Export DNS zone from GoDaddy → `backups/dns/`
- [ ] Export Pi-hole via Teleporter → `backups/pihole/teleporter/`
- [ ] Copy all Caddy configs → `backups/services/caddy/`
- [ ] Copy systemd units → `backups/services/systemd/`
- [ ] Export state files → `backups/exports/state-exports/`
- [ ] Backup to /cluster-nas for safety

### Before Migration
- [ ] Complete "Before Major Changes" checklist
- [ ] Create full system config archive
- [ ] Verify all critical files backed up
- [ ] Test restore procedures
- [ ] Document any custom configurations

### Weekly Maintenance
- [ ] Export Pi-hole configuration
- [ ] Backup n8n workflows (if changed)
- [ ] Update state files from live system
- [ ] Commit to git with descriptive message

## Integration with crtr-config

### Relationship to state/ directory
- **state/**: Source of truth for declarative configuration
- **backups/**: Historical snapshots and external service configs

### Workflow
```
1. Make manual config change on system
2. Create backup in backups/
3. Update corresponding state/*.yml file
4. Regenerate configs from state
5. Deploy via ./deploy/deploy
```

### Schema-First Approach
Backups support but don't replace the schema-first workflow:
- Use state/ for reproducible deployments
- Use backups/ for historical reference and external configs
- Use /cluster-nas/backups/ for sensitive data

## Restoration Procedures

### Restore DNS (GoDaddy)
```bash
# Reference file
cat backups/dns/ism.la.txt

# Manually recreate in GoDaddy interface
# Or use GoDaddy API for bulk import
```

### Restore Pi-hole
```bash
# Via web interface
# Settings → Teleporter → Import
# Select: backups/pihole/teleporter/pihole-teleporter-YYYY-MM-DD.tar.gz

# Via CLI
pihole -a -t ~/Projects/crtr-config/backups/pihole/teleporter/pihole-*.tar.gz
sudo systemctl restart pihole-FTL
```

### Restore Service Config
```bash
# Caddy
sudo cp backups/services/caddy/Caddyfile-2025-10-13 /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy

# Systemd service
sudo cp backups/services/systemd/atuin-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart atuin-server
```

## Security Best Practices

1. **Never commit secrets**: API keys, passwords, private keys
2. **Use .gitignore**: Protects sensitive files automatically
3. **Separate sensitive backups**: Store on /cluster-nas, not in git
4. **Review before commit**: Check for accidental sensitive data
5. **Encrypt sensitive archives**: Use gpg for sensitive .tar.gz files

```bash
# Encrypt sensitive backup
gpg --symmetric --cipher-algo AES256 backup-sensitive.tar.gz

# Store encrypted version
mv backup-sensitive.tar.gz.gpg /cluster-nas/backups/sensitive/

# Delete unencrypted
rm backup-sensitive.tar.gz
```

## Automated Backup Scripts

### Daily Backup Script (Future)
```bash
#!/bin/bash
# ~/Projects/crtr-config/scripts/backup-daily.sh

DATE=$(date +%F)

# Export Pi-hole
pihole -a -t /tmp/pihole-backup.tar.gz
mv /tmp/pihole-backup.tar.gz \
   ~/Projects/crtr-config/backups/pihole/teleporter/pihole-${DATE}.tar.gz

# Backup Caddy
sudo cp /etc/caddy/Caddyfile \
   ~/Projects/crtr-config/backups/services/caddy/Caddyfile-${DATE}

# Export state
cd ~/Projects/crtr-config
./scripts/sync/export-live-state.sh

# Commit to git (non-sensitive only)
git add backups/services/caddy/ state/
git commit -m "Automated backup: ${DATE}" || true
```

Add to crontab:
```cron
0 3 * * * ~/Projects/crtr-config/scripts/backup-daily.sh
```

## Related Documentation

- [backups/README.md](../backups/README.md) - Comprehensive backup guide
- [MIGRATION-DEBIAN-TO-RASPIOS.md](MIGRATION-DEBIAN-TO-RASPIOS.md) - Migration procedures using backups
- [MINIMAL-DOWNTIME-MIGRATION.md](MINIMAL-DOWNTIME-MIGRATION.md) - Fast migration with backups
- [CLAUDE.md](../CLAUDE.md) - Repository guidelines

## Quick Reference

### Current Status
- ✅ Directory structure created
- ✅ Documentation complete
- ✅ .gitignore configured
- ✅ DNS zone file organized
- 📦 Pi-hole export pending (please move to `backups/pihole/teleporter/`)

### Next Steps
1. Move Pi-hole Teleporter export to `backups/pihole/teleporter/`
2. Review and commit non-sensitive backups to git
3. Create automated backup script (optional)
4. Test restore procedures

---

**Last Updated**: 2025-10-13
**Maintainer**: crtr
**Status**: Structure complete, awaiting Pi-hole export
