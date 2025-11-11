# Session Summary: Self-Hosted VPN & Network Infrastructure Setup
**Date:** November 11, 2025
**Node:** cooperator (crtr) - 192.168.254.10
**Cluster:** colab

---

## 🎯 Mission Accomplished

Successfully built a complete self-hosted VPN infrastructure with centralized network management, spanning Linux, macOS, and Windows systems.

---

## ✅ Major Accomplishments

### 1. Headscale VPN Server (Self-Hosted Tailscale)
- **Service:** Headscale v0.27.0
- **Deployment:** Docker Compose on crtr
- **Access:** https://vpn.ism.la (via Caddy reverse proxy)
- **Database:** SQLite (lightweight, suitable for cluster size)
- **Status:** ✅ Running and operational

**Configuration:**
```yaml
Location: /home/crtr/docker/headscale/
- docker-compose.yml
- config/config.yaml
- config/acl.yaml
- data/ (SQLite database)
```

**Key Settings:**
- Server URL: `https://vpn.ism.la`
- VPN Network: `100.64.0.0/10`
- IPv6 Network: `fd7a:115c:a1e0::/48`
- Namespace: `colab`
- MagicDNS: Enabled (base domain: hs.ism.la)

### 2. Pi-hole DHCP Migration
- **Migrated from:** Gateway router (192.168.254.254)
- **Now managed by:** Pi-hole on crtr
- **DHCP Range:** 192.168.254.100 - 192.168.254.200
- **Lease Time:** 24 hours
- **Status:** ✅ Active and serving IPs

**Static Reservations:**
```
crtr (cooperator)  - 88:a2:9e:07:04:22 → 192.168.254.10
prtr (projector)   - 40:b0:76:44:7b:f3 → 192.168.254.20
wrtr (writer)      - 40:b0:76:44:7b:f2 → 192.168.254.21
drtr (director)    - 80:fa:5b:74:f2:9e → 192.168.254.30
trtr (terminator)  - 2c:ca:16:81:44:7b → 192.168.254.40
zerouter           - 2c:cf:67:b2:02:f2 → 192.168.254.11
raspberrypi        - b8:27:eb:60:f5:a8 → 192.168.254.12
brtr (barter)      - 30:ed:a0:2a:24:64 → 192.168.254.123
PLW1000v2          - 44:a5:6e:90:4a:50 → 192.168.254.100
```

**Configuration File:** `/etc/pihole/04-pihole-dhcp.conf`

### 3. Split DNS Configuration
- **Local DNS Records:** All *.ism.la domains resolve to 192.168.254.10
- **Upstream DNS:** Cloudflare (1.1.1.1) + Google (8.8.8.8)
- **Benefit:** Internal traffic stays local, external queries go upstream

**Local Domains Added:**
```
vpn.ism.la → 192.168.254.10
dns.ism.la → 192.168.254.10
mng.ism.la → 192.168.254.10
env.ism.la → 192.168.254.10
ssh.ism.la → 192.168.254.10
n8n.ism.la → 192.168.254.10
sch.ism.la → 192.168.254.10
cht.ism.la → 192.168.254.10
smp.ism.la → 192.168.254.10
btr.ism.la → 192.168.254.10
```

### 4. VPN Mesh Network - All Nodes Connected

| Node | Platform | LAN IP | VPN IP | Status |
|------|----------|--------|--------|--------|
| crtr | Debian 13 (ARM64) | 192.168.254.10 | 100.64.0.1 | ✅ Online |
| drtr | Debian 13 (x86_64) | 192.168.254.30 | 100.64.0.2 | ✅ Online |
| trtr | macOS 15 (ARM64) | 192.168.254.40 | 100.64.0.3 | ✅ Online |
| wrtr | Windows 11 | 192.168.254.21 | 100.64.0.4 | ✅ Online |

**Verification:**
```bash
tailscale status
# Shows all nodes with traffic stats (tx/rx)
```

### 5. Caddy Reverse Proxy Update
- **Added:** vpn.ism.la → localhost:8084
- **SSL:** Automatic via Let's Encrypt
- **Configuration:** `/etc/caddy/Caddyfile`

### 6. Network Manager Configuration
- **crtr Static IP:** Configured via NetworkManager
  - IP: 192.168.254.10/24
  - Gateway: 192.168.254.254
  - DNS: 127.0.0.1 (Pi-hole locally)

---

## 🔧 Technical Details

### Headscale ACL Policy
**File:** `/home/crtr/docker/headscale/config/acl.yaml`

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }
  ]
}
```

**Note:** Full mesh connectivity - all colab nodes can communicate with each other.

### Pre-Auth Key (Reusable, 7-day expiration)
```
3ad50bbc505c4711e4564c27f2b5db2eade07cf5d562ce1b
```

**Usage:** Connect new nodes to the VPN
```bash
# Linux
sudo tailscale up --login-server=https://vpn.ism.la --authkey=<KEY> --hostname=<nodename>

# macOS (Homebrew)
sudo /opt/homebrew/bin/tailscale up --login-server=https://vpn.ism.la --authkey=<KEY> --hostname=<nodename>

# Windows (PowerShell as Admin)
tailscale up --login-server=https://vpn.ism.la --authkey=<KEY> --hostname=<nodename>
```

---

## 📊 Network Architecture

### Physical Network (192.168.254.0/24)
```
Gateway Router (192.168.254.254)
    ↓
cooperator (192.168.254.10)
├── Caddy Reverse Proxy (ports 80, 443)
├── Pi-hole (DNS port 53, DHCP)
├── Headscale (port 8084)
└── All *.ism.la services
```

### VPN Overlay Network (100.64.0.0/10)
```
Headscale Control Server (crtr)
    ↓
VPN Mesh Network
├── crtr  (100.64.0.1) - Linux
├── drtr  (100.64.0.2) - Linux
├── trtr  (100.64.0.3) - macOS
└── wrtr  (100.64.0.4) - Windows
```

---

## 🚀 Key Benefits Achieved

1. **Self-Hosted VPN** - No dependency on Tailscale cloud
2. **Centralized Network Management** - Pi-hole handles DNS + DHCP
3. **Split DNS** - Internal traffic stays local, faster and more reliable
4. **Cross-Platform Mesh** - Linux, macOS, Windows all connected
5. **Secure Overlay Network** - Encrypted communication between all nodes
6. **MagicDNS** - Simple hostname resolution within VPN (e.g., `ssh crtr`)

---

## 📝 Common Operations

### Headscale Management
```bash
# List all nodes
docker exec headscale headscale nodes list

# Create new pre-auth key
docker exec headscale headscale preauthkeys create --user 1 --reusable --expiration 168h

# List users
docker exec headscale headscale users list

# Delete a node
docker exec headscale headscale nodes delete <node-id>
```

### VPN Status
```bash
# Check status
tailscale status

# Check connection to Headscale
tailscale status --json | jq .BackendState

# Restart Tailscale
sudo systemctl restart tailscaled
```

### Pi-hole Management
```bash
# Reload DNS
sudo pihole reloaddns

# Restart Pi-hole
sudo systemctl restart pihole-FTL

# View DHCP leases
sudo cat /var/lib/misc/dnsmasq.leases

# Check DHCP status
sudo ss -ulnp | grep :67
```

### Caddy Management
```bash
# Validate configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload configuration
sudo systemctl reload caddy

# Check status
sudo systemctl status caddy
```

---

## 🔍 Troubleshooting Reference

### VPN Connection Issues
**Problem:** Node won't connect to Headscale
**Solution:**
```bash
# Check DNS resolution
dig +short vpn.ism.la

# Test Headscale health endpoint
curl https://vpn.ism.la/health

# Clear Tailscale state and reconnect
sudo rm -rf /var/lib/tailscale/*
sudo tailscale up --login-server=https://vpn.ism.la --authkey=<KEY>
```

### DHCP Issues
**Problem:** Device not getting IP from Pi-hole
**Solution:**
```bash
# Check DHCP server is running
sudo ss -ulnp | grep :67

# Check DHCP configuration
sudo cat /etc/pihole/04-pihole-dhcp.conf

# Monitor DHCP requests
sudo tail -f /var/log/pihole/pihole.log | grep DHCP
```

### DNS Resolution Issues
**Problem:** Domain not resolving locally
**Solution:**
```bash
# Test DNS resolution
dig @127.0.0.1 vpn.ism.la

# Check Pi-hole local DNS records
cat /etc/pihole/custom.list

# Add local DNS record in Pi-hole web UI
# Settings → DNS → Local DNS records
```

---

## 📚 Configuration Files Reference

### Primary Configuration Locations
```
/home/crtr/docker/headscale/
├── docker-compose.yml          # Headscale container definition
├── config/
│   ├── config.yaml            # Main Headscale configuration
│   └── acl.yaml               # Access control policy
└── data/
    └── db.sqlite              # Headscale database

/etc/pihole/
├── 04-pihole-dhcp.conf        # DHCP configuration
└── custom.list                # Local DNS records

/etc/caddy/
└── Caddyfile                  # Reverse proxy configuration

/home/crtr/Projects/crtr-config/
├── ssot/state/
│   ├── services.yml           # Service definitions (SSOT)
│   ├── domains.yml            # Domain mappings (SSOT)
│   └── network.yml            # Network configuration (SSOT)
└── docs/
    └── SESSION-SUMMARY-2025-11-11.md  # This file
```

---

## 🎓 Lessons Learned

1. **Headscale ACL Gotcha:** ACL policy must match actual namespace and hostnames, not placeholder names. Using `"src": ["*"]` provides full mesh connectivity for initial setup.

2. **macOS Tailscale Variants:** App Store version requires GUI interaction. Homebrew version (`brew install tailscale`) provides full CLI support.

3. **Split DNS Importance:** Local DNS records prevent "hairpinning" where internal traffic goes out to the internet and back.

4. **Remote SSH Execution:** `tailscale up` via SSH can hang due to interactive prompts. Run locally when possible.

5. **Pi-hole DHCP Migration:** Setting crtr to static IP first prevents connectivity loss during DHCP migration.

---

## 🔮 Future Enhancements

### Potential Next Steps:
- [ ] Configure exit node on crtr for internet routing through VPN
- [ ] Set up subnet routing to access LAN devices from VPN
- [ ] Install Headscale web UI for easier management
- [ ] Configure granular ACL policies per node/service
- [ ] Add monitoring for VPN mesh status
- [ ] Document backup/restore procedures for Headscale
- [ ] Connect prtr (projector) when online

---

## 📞 Quick Reference Commands

### Check Everything is Working
```bash
# VPN status
tailscale status

# DHCP status
sudo ss -ulnp | grep :67

# DNS status
dig +short vpn.ism.la

# Headscale nodes
docker exec headscale headscale nodes list

# Service status
systemctl status tailscaled pihole-FTL caddy
```

### Restart Services
```bash
# VPN
sudo systemctl restart tailscaled

# Headscale
docker restart headscale

# Pi-hole
sudo systemctl restart pihole-FTL

# Caddy
sudo systemctl reload caddy
```

---

## 🏆 Final Status

**Infrastructure Status:** ✅ Fully Operational
**VPN Mesh:** ✅ 4/4 nodes connected
**DHCP/DNS:** ✅ Pi-hole managing network
**Split DNS:** ✅ Local resolution active
**Reverse Proxy:** ✅ All domains accessible

**Total Setup Time:** ~4 hours
**Services Configured:** 5 (Headscale, Pi-hole DHCP, Tailscale clients, NetworkManager, Caddy)
**Nodes Connected:** 4 (Linux x2, macOS, Windows)
**Configuration Files Modified:** 8

---

*Generated on November 11, 2025 by Claude Code*
*Session conducted on cooperator (crtr) - 192.168.254.10*
