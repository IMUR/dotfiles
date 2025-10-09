# GoDaddy DNS Management - Quick Start

Get up and running with DNS management for your ism.la domain in 5 minutes.

## Step 1: Get Your API Credentials

1. Go to [GoDaddy Developer Portal](https://developer.godaddy.com/)
2. Sign in with your GoDaddy account
3. Navigate to "API Keys" section
4. Click "Create New API Key"
5. Choose **OTE (Test) Environment** for your first setup
6. Save your API Key and Secret securely

## Step 2: Run Setup Script

```bash
cd /home/crtr/Projects/colab-config
./scripts/dns/setup-godaddy-api.sh
```

The script will prompt you for:
- API Key
- API Secret  
- Environment (OTE/Production)
- Domain name (default: ism.la)

This creates `.env.godaddy` with your credentials (automatically added to .gitignore).

## Step 3: Test Your Connection

```bash
# Load credentials
source .env.godaddy

# List all DNS records
./scripts/dns/godaddy-dns-manager.sh list
```

You should see all your current DNS records!

## Common Tasks

### View All DNS Records
```bash
source .env.godaddy
./scripts/dns/godaddy-dns-manager.sh list
```

### View Specific Record Type
```bash
# View only CNAME records
./scripts/dns/godaddy-dns-manager.sh list-type CNAME

# View only A records
./scripts/dns/godaddy-dns-manager.sh list-type A
```

### Add a New Record
```bash
# Add CNAME: test.ism.la -> crtrcooperator.duckdns.org
./scripts/dns/godaddy-dns-manager.sh add CNAME test crtrcooperator.duckdns.org

# Add A record: api.ism.la -> 192.168.1.100
./scripts/dns/godaddy-dns-manager.sh add A api 192.168.1.100
```

### Update Existing Record
```bash
# Change where n8n.ism.la points
./scripts/dns/godaddy-dns-manager.sh update CNAME n8n newserver.duckdns.org
```

### Export Current DNS to File
```bash
# Updates ism.la.txt with current live DNS
./scripts/dns/godaddy-dns-manager.sh export
```

### Check if Local File Matches Live DNS
```bash
# Compare ism.la.txt with actual DNS records
./scripts/dns/godaddy-dns-manager.sh compare
```

## Integration with Validation

The DNS tools are integrated into your validation workflow:

```bash
# Run all validations including DNS
./scripts/validation/full-validation.sh

# Run just DNS validation
./scripts/validation/check-dns.sh
```

## Important Notes

### OTE vs Production

- **OTE (Test Environment)**: Safe sandbox for testing, doesn't affect live DNS
- **Production**: Changes affect your actual DNS immediately

Start with OTE to learn the tool, then switch to Production when ready.

### Switching to Production

1. Get Production API keys from GoDaddy Developer Portal
2. Edit `.env.godaddy`:
   ```bash
   GODADDY_API_ENV="PRODUCTION"
   GODADDY_API_KEY="your-production-key"
   GODADDY_API_SECRET="your-production-secret"
   ```
3. Test with read-only commands first:
   ```bash
   source .env.godaddy
   ./scripts/dns/godaddy-dns-manager.sh list
   ./scripts/dns/godaddy-dns-manager.sh compare
   ```

### Safety Features

- Delete operations require confirmation
- Separate test/production environments
- All operations show clear success/failure
- Compare command shows changes before applying

## Troubleshooting

### "Missing required dependencies"
```bash
# Install curl and jq
sudo apt-get install curl jq
```

### "API credentials not set"
```bash
# Make sure you've sourced the env file
source .env.godaddy

# Or re-run setup
./scripts/dns/setup-godaddy-api.sh
```

### "Failed to fetch records"
- Verify your API keys are correct
- Check that environment (OTE/PRODUCTION) matches your keys
- Ensure domain name is correct in .env.godaddy

### Can't see changes immediately
DNS changes can take time to propagate (usually 5-30 minutes). The GoDaddy API shows changes immediately, but DNS servers worldwide need time to update.

## Next Steps

- Read full documentation: [scripts/dns/README.md](./README.md)
- Set up automated backups
- Integrate with your deployment workflow
- Consider switching to Production environment

## Support

- [GoDaddy API Documentation](https://developer.godaddy.com/doc)
- [DNS Records API Reference](https://developer.godaddy.com/doc/endpoint/domains#/v1/recordGet)
- [GoDaddy Developer Support](https://developer.godaddy.com/support)

