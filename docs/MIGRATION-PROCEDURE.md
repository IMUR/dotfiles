# Migration Procedure: Debian SD → Raspberry Pi OS USB

**Schema-First, Human-in-the-Loop Migration**

**Status**: Ready for execution
**Approach**: Manual deployment with state validation at each step

---

## Overview

Migrate cooperator from Debian on SD card to Raspberry Pi OS on USB drive using the schema-first workflow.

**Core Principle**: State files (`state/*.yml`) are source of truth. Configs generate from state, not copied from backups.

**Safety**: SD card remains untouched for instant rollback. All data on separate NVMe drive.

---

## Prerequisites

**Before starting:**

- [ ] USB drive with Raspberry Pi OS pre-installed
- [ ] SD card system currently operational
- [ ] `/cluster-nas` (NVMe) accessible and backed up
- [ ] SSH access to cooperator
- [ ] Git repository up to date

---

## Preparation (While SD System Running)

**Goal**: Validate state, generate configs, prepare USB system

### Export and Validate Current State

```bash
cd ~/Projects/crtr-config

# Export live system to state files
./scripts/sync/export-live-state.sh

# Review what changed
git diff state/

# Validate YAML syntax
./.meta/validation/validate.sh

# If validation fails, fix state files until it passes

# Generate configs from validated state
./scripts/generate/regenerate-all.sh

# Compare generated vs. live (should match)
diff config/caddy/Caddyfile /etc/caddy/Caddyfile

# If different, investigate why and fix state files

# Commit validated state
git add state/
git commit -m "Pre-migration validated state"
git push
```

### Backup User Configs

```bash
# Backup things not in state files
tar czf /cluster-nas/backups/migration-$(date +%F)/home-crtr.tar.gz \
  ~/.ssh \
  ~/.config \
  ~/.local/bin \
  ~/duckdns

# Document current running state
systemctl list-units --type=service --state=running > \
  /cluster-nas/backups/migration-$(date +%F)/running-services.txt
```

### Configure USB Drive

```bash
# Mount USB
sudo mkdir -p /mnt/usb-boot /mnt/usb-root
sudo mount /dev/sdb1 /mnt/usb-boot
sudo mount /dev/sdb2 /mnt/usb-root

# Set hostname
echo "cooperator" | sudo tee /mnt/usb-root/etc/hostname
sudo sed -i 's/raspberrypi/cooperator/g' /mnt/usb-root/etc/hosts

# Enable SSH
sudo touch /mnt/usb-boot/ssh

# Copy SSH keys
sudo mkdir -p /mnt/usb-root/home/pi/.ssh
sudo cp ~/.ssh/authorized_keys /mnt/usb-root/home/pi/.ssh/
sudo chmod 700 /mnt/usb-root/home/pi/.ssh
sudo chmod 600 /mnt/usb-root/home/pi/.ssh/authorized_keys

# Configure NVMe mount
echo "UUID=810880b9-6e26-4b18-8246-ca19fd56bc8f /cluster-nas xfs defaults 0 2" | \
  sudo tee -a /mnt/usb-root/etc/fstab
sudo mkdir -p /mnt/usb-root/cluster-nas

# Configure static IP
sudo tee -a /mnt/usb-root/etc/dhcpcd.conf <<EOF

interface eth0
static ip_address=192.168.254.10/24
static routers=192.168.254.1
static domain_name_servers=127.0.0.1
EOF

# Unmount
sudo umount /mnt/usb-boot /mnt/usb-root
```

---

## First Boot USB (Initial Setup)

**Boot USB to install packages and deploy configs**

### Boot from USB

```bash
# Shutdown SD system
sudo shutdown -h now

# Change boot order: USB first, SD second (keep SD inserted)
# Power on
```

### Initial Setup on USB

```bash
# SSH as pi user
ssh pi@192.168.254.10

# Create crtr user
sudo useradd -m -s /bin/bash -G sudo,users crtr
sudo cp -r ~/.ssh /home/crtr/
sudo chown -R crtr:crtr /home/crtr/.ssh
echo "crtr:yourpassword" | sudo chpasswd

# Switch to crtr user
sudo su - crtr

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y git vim curl wget tmux htop tree ncdu rsync \
  build-essential python3 python3-yaml

# Install Docker
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sudo sh /tmp/get-docker.sh
sudo usermod -aG docker crtr

# Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
  sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
  sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy

# Install NFS server
sudo apt install -y nfs-kernel-server

# Install Pi-hole if needed
# curl -sSL https://install.pi-hole.net | bash
```

### Deploy from State (Schema-First)

```bash
# Clone repository
mkdir -p ~/Projects
cd ~/Projects
git clone /cluster-nas/repos/crtr-config
cd crtr-config

# Verify state valid
./.meta/validation/validate.sh

# Generate all configs from state
./scripts/generate/regenerate-all.sh

# Review generated configs (YOU VERIFY)
ls -la config/

# Deploy configs manually (one at a time, verify each)

# NFS exports
sudo cp config/nfs/exports /etc/exports
sudo exportfs -ra

# Caddy
sudo cp config/caddy/Caddyfile /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile

# Pi-hole DNS overrides
sudo cp config/pihole/local-dns.conf /etc/dnsmasq.d/02-custom-local-dns.conf

# Systemd units
sudo cp config/systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload

# Restore user configs
cd /cluster-nas/backups/migration-$(date +%F)/
tar xzf home-crtr.tar.gz -C /home/crtr/

# Install custom binaries (ARM64 architecture)
ARCH=$(uname -m)  # Should be aarch64
curl -sL https://github.com/atuinsh/atuin/releases/latest/download/atuin-${ARCH}-unknown-linux-gnu.tar.gz | \
  sudo tar xz -C /usr/local/bin

sudo wget -O /usr/local/bin/semaphore \
  https://github.com/ansible-semaphore/semaphore/releases/latest/download/semaphore_linux_arm64
sudo chmod +x /usr/local/bin/semaphore

sudo wget -O /usr/local/bin/gotty \
  https://github.com/yudai/gotty/releases/latest/download/gotty_linux_arm
sudo chmod +x /usr/local/bin/gotty
```

### Test Services on USB

```bash
# Start services one at a time, verify each
sudo systemctl start nfs-kernel-server
sudo systemctl status nfs-kernel-server

sudo systemctl start pihole-FTL
sudo systemctl status pihole-FTL

sudo systemctl start docker
sudo systemctl status docker

sudo systemctl start caddy
sudo systemctl status caddy

sudo systemctl start atuin-server semaphore gotty
sudo systemctl status atuin-server semaphore gotty

# Start docker containers
cd /cluster-nas/services/n8n
docker compose up -d
docker ps
```

### Verify Everything Works

```bash
# DNS
dig @localhost dns.ism.la +short

# Local services
curl -I http://localhost:5678  # n8n
curl -I http://localhost:3001  # semaphore

# HTTPS via Caddy
curl -I https://n8n.ism.la
curl -I https://dns.ism.la

# NFS
showmount -e localhost

# Storage
df -h /cluster-nas
```

**If everything works**: Switch back to SD, proceed to final cutover

**If issues**: Fix them on USB before cutover

### Switch Back to SD Temporarily

```bash
# Shutdown USB
sudo shutdown -h now

# Change boot order: SD first
# Power on - should boot from SD
# Verify: lsblk (root should be mmcblk0p2)
```

---

## Final Cutover

**Goal**: Switch from SD to USB with minimal downtime

### Pre-Cutover Verification

```bash
# On SD system (still serving traffic)

# Verify all services healthy
systemctl status caddy pihole-FTL docker nfs-kernel-server
docker ps

# External access working
curl -I https://n8n.ism.la

# Final state sync if needed
cd ~/Projects/crtr-config
./scripts/sync/export-live-state.sh
git diff state/
# If changes, commit them
```

### Execute Cutover

```bash
# Stop services gracefully
cd /cluster-nas/services/n8n
docker compose down

sudo systemctl stop gotty semaphore atuin-server
sudo systemctl stop caddy pihole-FTL docker

# Ensure writes flushed
sync

# Shutdown
sudo shutdown -h now

# Change boot order: USB first, SD second
# Power on (boots from USB)
```

### Start Services on USB

```bash
# SSH to USB system
ssh crtr@192.168.254.10

# Verify /cluster-nas mounted
df -h /cluster-nas

# Start services in order
sudo systemctl start nfs-kernel-server pihole-FTL docker caddy
sudo systemctl start atuin-server semaphore gotty

# Start docker containers
cd /cluster-nas/services/n8n
docker compose up -d
```

### Verify Production

```bash
# All services running
systemctl --failed
systemctl status caddy pihole-FTL docker nfs-kernel-server

# Docker containers
docker ps

# DNS resolution
dig @localhost n8n.ism.la +short

# HTTPS access
curl -I https://n8n.ism.la
curl -I https://dns.ism.la
curl -I https://smp.ism.la

# External access (from another machine)
curl -I https://n8n.ism.la

# No errors
sudo journalctl -p err -b --no-pager

# Boot device
lsblk | grep "/"
# Should show /dev/sdb2 at /
```

---

## Rollback (If Needed)

**If anything goes wrong:**

```bash
# 1. Shutdown USB system
sudo shutdown -h now

# 2. Change boot order: SD first

# 3. Power on (boots from SD)

# 4. Verify services running
systemctl status caddy docker pihole-FTL
curl -I https://n8n.ism.la
```

**Rollback time**: ~5 minutes

**Data loss**: None (all data on /cluster-nas, unchanged)

---

## Post-Migration

### Immediate

```bash
# Update state files with new OS
cd ~/Projects/crtr-config
vim state/node.yml
# Update os.distribution and boot_device

git add state/
git commit -m "Migration complete: Raspberry Pi OS on USB"
git push

# Create USB backup
sudo dd if=/dev/sdb of=/cluster-nas/backups/usb-raspios-$(date +%F).img \
  bs=4M status=progress
sudo gzip /cluster-nas/backups/usb-raspios-$(date +%F).img
```

### Monitor

- [ ] All services running without errors
- [ ] DuckDNS cron updating (check `~/duckdns/duck.log`)
- [ ] Backup cron running
- [ ] External access stable
- [ ] NFS accessible from other nodes

### After 24 Hours

- [ ] No service crashes
- [ ] No unexpected restarts
- [ ] All automated tasks running
- [ ] Declare migration successful
- [ ] Optional: Repurpose SD card

---

## Key Points

**Schema-First**:
- Configs generated from `state/*.yml`
- Never copy configs from backups
- Validate state before generating

**Human-in-the-Loop**:
- You verify each step
- You deploy configs manually
- You decide when to proceed

**Safety**:
- SD card untouched (instant rollback)
- Data on separate NVMe (unchanged)
- Test everything on USB before cutover

**Realistic**:
- No artificial time constraints
- Work at your own pace
- Fix issues as they arise

---

**Ready to proceed?** Start with "Preparation" section.
