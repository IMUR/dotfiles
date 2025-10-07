# DNS Configuration for Cooperator

**Note**: Active DNS management has moved to `/scripts/dns/` which uses the GoDaddy API.

This directory is reserved for DNS-related configuration files specific to cooperator's role as the cluster DNS server (Pi-hole).

## DNS Management Tools

### GoDaddy DNS Management
Location: `../../scripts/dns/`

Manages external DNS records for *.ism.la via GoDaddy API.

```bash
# List all DNS records
../../scripts/dns/godaddy-dns-manager.sh list

# Add a new subdomain
../../scripts/dns/godaddy-dns-manager.sh add myservice CNAME crtrcooperator.duckdns.org
```

See `../../scripts/dns/README.md` for complete documentation.

### SSOT (Single Source of Truth)
Location: `../../scripts/ssot/`

Infrastructure truth database that tracks actual cluster state.

```bash
# Query infrastructure truth
../../scripts/ssot/ssot query dns

# Discover current DNS configuration
../../scripts/ssot/discover-truth.sh dns

# Validate against truth database
../../scripts/ssot/validate-truth.sh
```

See `../../scripts/ssot/README.md` for complete documentation.

## Local DNS Configuration (Pi-hole)

### Pi-hole Local Overrides
File: `/etc/dnsmasq.d/02-custom-local-dns.conf`

Contains local DNS overrides for *.ism.la domains to resolve to 192.168.254.10 within the cluster.

### Custom DNS Entries
File: `/etc/pihole/custom.list`

Additional custom DNS entries managed by Pi-hole.

## DNS Architecture

**External Resolution** (from internet):
```
*.ism.la → GoDaddy DNS → CNAME crtrcooperator.duckdns.org → 47.155.237.161
```

**Internal Resolution** (from cluster):
```
*.ism.la → Pi-hole (192.168.254.10) → Local override → 192.168.254.10
```

**Management**:
- External: GoDaddy API via `scripts/dns/`
- Internal: Pi-hole + dnsmasq overrides
- Truth: `scripts/ssot/infrastructure-truth.yaml`
