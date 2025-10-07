# Pi-hole DNS Configuration

**Live Config Location**: `/etc/pihole/`

## Local DNS Overrides

**File**: `/etc/dnsmasq.d/02-custom-local-dns.conf`

This file contains local network DNS overrides for *.ism.la domains to resolve to cooperator's internal IP (192.168.254.10).

### Adding New Service

```bash
echo "address=/newservice.ism.la/192.168.254.10" | sudo tee -a /etc/dnsmasq.d/02-custom-local-dns.conf
sudo systemctl restart pihole-FTL
```

## Custom Host Entries

**File**: `/etc/pihole/custom.list`

Alternative location for A record overrides (format: `IP HOSTNAME`).

## Backup Strategy

Pi-hole automatically backs up configs to `/etc/pihole/config_backups/`.
