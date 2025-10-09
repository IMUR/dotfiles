# DNS Management Scripts

Tools for managing DNS zones via provider APIs.

## GoDaddy DNS Manager

Real-time DNS zone management for domains hosted on GoDaddy.

### Features

- ✅ List all DNS records or filter by type
- ✅ Add/update/delete individual records
- ✅ Export current DNS to zone file format
- ✅ Compare local zone file with live DNS
- ✅ Support for both OTE (test) and Production environments
- ✅ Safe operations with confirmation prompts for deletions

### Prerequisites

```bash
# Install required tools
sudo apt-get install curl jq  # Debian/Ubuntu
# or
brew install curl jq          # macOS
```

### Setup

1. **Get GoDaddy API Credentials**
   - Log in to [GoDaddy Developer Portal](https://developer.godaddy.com/)
   - Create API keys for OTE (test) environment
   - Create separate keys for Production when ready

2. **Configure Environment Variables**

Create a `.env` file in the project root or export variables:

```bash
# Required
export GODADDY_API_KEY="your-api-key"
export GODADDY_API_SECRET="your-api-secret"

# Optional (defaults shown)
export GODADDY_API_ENV="OTE"        # OTE for test, PRODUCTION for live
export GODADDY_DOMAIN="ism.la"      # Your domain
```

Or source the env file:
```bash
source .env.godaddy
./scripts/dns/godaddy-dns-manager.sh list
```

### Usage

#### List All Records
```bash
./scripts/dns/godaddy-dns-manager.sh list
```

#### List Records by Type
```bash
./scripts/dns/godaddy-dns-manager.sh list-type CNAME
./scripts/dns/godaddy-dns-manager.sh list-type A
./scripts/dns/godaddy-dns-manager.sh list-type TXT
```

#### Get Specific Record
```bash
./scripts/dns/godaddy-dns-manager.sh get CNAME n8n
./scripts/dns/godaddy-dns-manager.sh get A @
```

#### Add New Record
```bash
# Add CNAME record
./scripts/dns/godaddy-dns-manager.sh add CNAME test crtrcooperator.duckdns.org

# Add A record with custom TTL
./scripts/dns/godaddy-dns-manager.sh add A api 192.168.1.100 600
```

#### Update Existing Record
```bash
# Update CNAME
./scripts/dns/godaddy-dns-manager.sh update CNAME n8n newhost.example.com

# Update A record
./scripts/dns/godaddy-dns-manager.sh update A @ 47.154.26.190 3600
```

#### Delete Record
```bash
# Will prompt for confirmation
./scripts/dns/godaddy-dns-manager.sh delete CNAME test
```

#### Export to Zone File
```bash
# Export to default location (ism.la.txt)
./scripts/dns/godaddy-dns-manager.sh export

# Export to custom file
./scripts/dns/godaddy-dns-manager.sh export backups/dns-backup-$(date +%Y%m%d).txt
```

#### Compare Local vs Live
```bash
# Compare ism.la.txt with current DNS
./scripts/dns/godaddy-dns-manager.sh compare

# Compare custom file
./scripts/dns/godaddy-dns-manager.sh compare backups/dns-backup-20251006.txt
```

### Integration with Project

#### As Validation Check
Add to validation workflow:

```bash
# In scripts/validation/check-dns.sh
./scripts/dns/godaddy-dns-manager.sh compare
```

#### As Pre-Commit Hook
Ensure local zone file is in sync:

```bash
# .git/hooks/pre-commit
if ! ./scripts/dns/godaddy-dns-manager.sh compare >/dev/null 2>&1; then
    echo "Warning: Local DNS zone file differs from live DNS"
    echo "Run: ./scripts/dns/godaddy-dns-manager.sh export"
fi
```

#### Regular Backup
Add to cron or systemd timer:

```bash
# Daily DNS backup at 2 AM
0 2 * * * cd /home/crtr/Projects/colab-config && \
  ./scripts/dns/godaddy-dns-manager.sh export \
  backups/dns-$(date +\%Y\%m\%d).txt
```

### Safety Features

1. **Confirmation Prompts**: Delete operations require explicit "yes" confirmation
2. **Environment Separation**: OTE (test) and Production environments kept separate
3. **No Silent Failures**: All operations report success or failure clearly
4. **Validation**: Uses `jq` to validate API responses
5. **Read-Only by Default**: List and compare operations don't modify anything

### Switching to Production

⚠️ **Important**: The default environment is OTE (test). When ready for production:

1. Generate Production API keys from GoDaddy
2. Update environment variables:
   ```bash
   export GODADDY_API_ENV="PRODUCTION"
   export GODADDY_API_KEY="your-production-key"
   export GODADDY_API_SECRET="your-production-secret"
   ```
3. Test with read-only operations first:
   ```bash
   ./scripts/dns/godaddy-dns-manager.sh list
   ./scripts/dns/godaddy-dns-manager.sh compare
   ```
4. Only then perform write operations

### API Documentation

- [GoDaddy API Docs](https://developer.godaddy.com/doc)
- [DNS Records API](https://developer.godaddy.com/doc/endpoint/domains#/v1/recordGet)
- [Authentication](https://developer.godaddy.com/getstarted)

### Troubleshooting

**"Missing required dependencies"**
- Install `curl` and `jq` packages

**"GoDaddy API credentials not set"**
- Ensure `GODADDY_API_KEY` and `GODADDY_API_SECRET` are exported

**"Failed to fetch records"**
- Check API credentials are valid
- Verify domain name is correct
- Ensure API environment (OTE vs PRODUCTION) matches your keys
- Check network connectivity

**"Record not found"**
- Verify record name and type are correct
- Use `list` or `list-type` to see all records
- Remember @ represents the apex/root domain

### File Locations

- Script: `scripts/dns/godaddy-dns-manager.sh`
- Zone file: `ism.la.txt` (root of repository)
- Backups: `backups/` (if using backup strategy)
- Credentials: `.env.godaddy` (not in git, create locally)

### Security Notes

- ⚠️ Never commit API credentials to git
- 🔒 Add `.env.godaddy` to `.gitignore`
- 🔐 Use OTE environment for testing
- 🛡️ Rotate API keys periodically
- 👥 Use separate API keys per team member/system

