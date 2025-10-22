# Pi-hole Installation
**Service:** Pi-hole DNS & Ad-blocking
**Domain:** dns.ism.la
**Port:** 8080 (web UI), 53 (DNS)
**Updated:** 2025-10-21

---

## Prerequisites

- Docker NOT recommended for Pi-hole (use native install)
- OR use system package install
- Caddy configured (dns.ism.la → localhost:8080) ✓
- Existing config: `/media/crtr/rootfs/etc/pihole/`

---

## Installation Method

### Recommended: System Package

```bash
# Install via apt
sudo apt update
sudo apt install -y pihole-FTL

# Or use official installer
curl -sSL https://install.pi-hole.net | bash
```

---

## Restore Configuration

### 1. Stop Pi-hole

```bash
sudo systemctl stop pihole-FTL
```

### 2. Restore Config Files

```bash
# Backup current (if any)
sudo cp -r /etc/pihole /etc/pihole.backup

# Restore from old system
sudo rsync -av /media/crtr/rootfs/etc/pihole/ /etc/pihole/

# Important files:
# - custom.list (custom DNS)
# - dnsmasq.conf (DNS settings)
# - pihole.toml (Pi-hole config)
# - gravity.db (blocklists)
```

### 3. Set Permissions

```bash
sudo chown -R pihole:pihole /etc/pihole
sudo chmod 644 /etc/pihole/*.conf
sudo chmod 644 /etc/pihole/*.list
```

### 4. Start Pi-hole

```bash
sudo systemctl start pihole-FTL
sudo systemctl enable pihole-FTL
```

### 5. Verify

```bash
# Check status
sudo systemctl status pihole-FTL

# Test DNS
dig @localhost google.com

# Access web UI
curl -I http://localhost:8080/admin
```

---

## Set Admin Password

```bash
sudo pihole -a -p
# Enter new password when prompted
```

---

## Update Gravity (Blocklists)

```bash
sudo pihole updateGravity
```

---

## Maintenance

```bash
# View logs
sudo pihole tail

# Update blocklists
sudo pihole updateGravity

# Restart
sudo systemctl restart pihole-FTL

# Reconfigure
sudo pihole reconfigure
```

---

**Status:** Config ready to restore
**Source:** `/media/crtr/rootfs/etc/pihole/`
**Priority:** LOW (do after n8n and Infisical)
