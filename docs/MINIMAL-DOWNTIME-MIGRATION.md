# Minimal Downtime Migration Strategy

**Created**: 2025-10-13
**Migration**: Debian (SD Card) → Raspberry Pi OS (USB Drive)
**Target Downtime**: < 15 minutes
**Current System**: Running on 955GB microSD (mmcblk0)
**Target System**: 256GB USB 3.2.2 drive (sdb) with pre-installed Raspberry Pi OS

---

## Executive Summary

This document provides a **minimal downtime migration strategy** that reduces service interruption to under 15 minutes by leveraging the schema-first crtr-config approach and careful orchestration.

### Key Strategy Points

1. **Prepare USB system completely while SD card still running** (no downtime)
2. **Export live configuration to state files** (no downtime)
3. **Pre-install packages and dependencies on USB** (no downtime)
4. **Deploy services on USB while SD still serving** (no downtime)
5. **Quick cutover: Stop services → Change boot → Start services** (< 15 min)
6. **Instant rollback capability** via boot order change

---

## Current System Analysis

### Critical Services (Running)

| Service | Type | Port | Bind | Restart Time | Data Location |
|---------|------|------|------|--------------|---------------|
| **caddy** | systemd | 80, 443, 8443 | 0.0.0.0 | ~5s | /etc/caddy/ |
| **pihole-FTL** | systemd | 53 | 0.0.0.0 | ~3s | /etc/pihole/ |
| **nfs-kernel-server** | systemd | 2049 | 0.0.0.0 | ~2s | /etc/exports |
| **docker** | systemd | - | - | ~10s | /var/lib/docker |
| **atuin-server** | systemd (custom) | 8811 | 192.168.254.10 | ~2s | /home/crtr/.local/share/atuin/ |
| **semaphore** | systemd (custom) | 3001 | 0.0.0.0 | ~3s | /cluster-nas/services/semaphore/ |
| **gotty** | systemd (custom) | 7681 | 0.0.0.0 | ~1s | (no data) |
| **n8n** | docker-compose | 5678 | 127.0.0.1 | ~15s | /cluster-nas/services/n8n/ |
| **n8n-postgres** | docker-compose | 5432 | internal | ~5s | /cluster-nas/services/n8n/ |

**Total estimated restart time**: ~45 seconds (all services can start in parallel)

### Service Dependencies

```
/cluster-nas (NVMe mount) ← MUST BE AVAILABLE FIRST
  ↓
nfs-kernel-server (exports /cluster-nas)
  ↓
docker (container runtime)
  ↓
n8n, n8n-postgres (containers)
semaphore (depends on /cluster-nas)

Parallel startup:
- caddy (reverse proxy)
- pihole-FTL (DNS)
- atuin-server (shell history sync)
- gotty (web terminal)
```

### Network Configuration

```yaml
interface: eth0
ip: 192.168.254.10/24
gateway: 192.168.254.1
method: DHCP with static config
dns: 127.0.0.1 (local pihole)
```

### Storage Configuration

```yaml
Boot (current SD):
  - /dev/mmcblk0p1 → /boot/firmware (512M vfat)
  - /dev/mmcblk0p2 → / (939G ext4, 23GB used)

Data (NVMe - unchanged):
  - /dev/sda1 → /cluster-nas (1.8T xfs, 39GB used)

Target USB:
  - /dev/sdb1 → /boot/firmware (512M vfat)
  - /dev/sdb2 → / (233G ext4)
```

### Cron Jobs

```cron
*/5 * * * * ~/duckdns/duck.sh          # DuckDNS update
0 3 * * * /usr/local/bin/cluster-backup.sh  # Daily backup
```

### Custom Systemd Units

1. `/etc/systemd/system/atuin-server.service`
2. `/etc/systemd/system/semaphore.service`
3. `/etc/systemd/system/gotty.service`

---

## Minimal Downtime Migration Plan

### Phase 0: Pre-Migration (While SD Running) - 2 hours, **0 downtime**

**Goal**: Prepare USB system completely without affecting current operations

#### Step 0.1: Export Current State (15 min)

```bash
# On SD system (still running)
cd ~/Projects/crtr-config

# Export all current configurations to state/*.yml
./scripts/sync/export-live-state.sh

# Capture everything
sudo tar czf /cluster-nas/backups/migration-$(date +%F)/etc-configs.tar.gz \
  /etc/caddy \
  /etc/pihole \
  /etc/dnsmasq.d \
  /etc/systemd/system/*.service \
  /etc/exports \
  /etc/fstab \
  /etc/network/interfaces \
  /etc/dhcpcd.conf

# Backup user configs
tar czf /cluster-nas/backups/migration-$(date +%F)/home-crtr.tar.gz \
  ~/.ssh \
  ~/.config \
  ~/.local/bin \
  ~/duckdns

# Document running state
systemctl list-units --type=service --state=running > \
  /cluster-nas/backups/migration-$(date +%F)/running-services.txt

docker ps -a > /cluster-nas/backups/migration-$(date +%F)/docker-containers.txt

ss -tlnp > /cluster-nas/backups/migration-$(date +%F)/listening-ports.txt
```

**Deliverable**: Complete backup and state export on /cluster-nas

#### Step 0.2: Mount and Prepare USB (30 min)

```bash
# Mount USB partitions (read-write)
sudo mkdir -p /mnt/usb-boot /mnt/usb-root
sudo mount /dev/sdb1 /mnt/usb-boot
sudo mount /dev/sdb2 /mnt/usb-root

# Verify Raspberry Pi OS is intact
ls -la /mnt/usb-root/etc/os-release
cat /mnt/usb-root/etc/os-release

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

# Configure fstab for /cluster-nas
echo "" | sudo tee -a /mnt/usb-root/etc/fstab
echo "# NVMe Data Storage" | sudo tee -a /mnt/usb-root/etc/fstab
echo "UUID=810880b9-6e26-4b18-8246-ca19fd56bc8f /cluster-nas xfs defaults 0 2" | \
  sudo tee -a /mnt/usb-root/etc/fstab

sudo mkdir -p /mnt/usb-root/cluster-nas

# Configure static IP
sudo tee -a /mnt/usb-root/etc/dhcpcd.conf <<EOF

# Static IP for cooperator
interface eth0
static ip_address=192.168.254.10/24
static routers=192.168.254.1
static domain_name_servers=127.0.0.1
EOF

# Unmount
sudo umount /mnt/usb-boot /mnt/usb-root
```

**Deliverable**: USB drive configured and ready for first boot

#### Step 0.3: Boot USB and Install Base Packages (45 min)

**IMPORTANT**: This step requires brief downtime for boot device change

```bash
# 1. Shutdown current system
sudo shutdown -h now

# 2. Change boot order in BIOS/UEFI (3 min)
#    - Set USB first, SD second
#    - Keep SD inserted for safety

# 3. Power on and boot from USB

# 4. SSH to new system
ssh pi@192.168.254.10

# 5. Create crtr user
sudo useradd -m -s /bin/bash -G sudo,users crtr
sudo cp -r ~/.ssh /home/crtr/
sudo chown -R crtr:crtr /home/crtr/.ssh
echo "crtr:yourpassword" | sudo chpasswd

# 6. Switch to crtr user
sudo su - crtr

# 7. Update and install packages (parallel with package manager)
sudo apt update && sudo apt upgrade -y

# Essential packages
sudo apt install -y git vim curl wget tmux htop tree ncdu rsync duf \
  build-essential bat fd-find ripgrep zsh

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

# Install Pi-hole (if not already installed)
# Check first: which pihole
# If needed: curl -sSL https://install.pi-hole.net | bash
```

**Deliverable**: USB system with all required packages installed

#### Step 0.4: Pre-Deploy Configuration (30 min)

**Still on USB system, before switching back to SD**

```bash
# Clone crtr-config repository
mkdir -p ~/Projects
cd ~/Projects
git clone /cluster-nas/repos/crtr-config

# Copy configuration files from /cluster-nas backup
cd /cluster-nas/backups/migration-$(date +%F)/

# NFS exports
sudo cp etc-configs/etc/exports /etc/exports
sudo exportfs -ra

# Caddy config
sudo cp -r etc-configs/etc/caddy/Caddyfile /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile

# DNS config
sudo cp etc-configs/etc/dnsmasq.d/* /etc/dnsmasq.d/
sudo cp etc-configs/etc/pihole/* /etc/pihole/

# Custom systemd services
sudo cp etc-configs/etc/systemd/system/atuin-server.service /etc/systemd/system/
sudo cp etc-configs/etc/systemd/system/semaphore.service /etc/systemd/system/
sudo cp etc-configs/etc/systemd/system/gotty.service /etc/systemd/system/

# Install custom binaries (atuin, semaphore, gotty)
# Copy from /cluster-nas or reinstall:
curl -sL https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-gnu.tar.gz | \
  sudo tar xz -C /usr/local/bin

# Download semaphore
sudo wget -O /usr/local/bin/semaphore \
  https://github.com/ansible-semaphore/semaphore/releases/latest/download/semaphore_linux_arm64
sudo chmod +x /usr/local/bin/semaphore

# Download gotty
sudo wget -O /usr/local/bin/gotty \
  https://github.com/yudai/gotty/releases/latest/download/gotty_linux_arm
sudo chmod +x /usr/local/bin/gotty

# Reload systemd
sudo systemctl daemon-reload

# DON'T start services yet - we'll do that after final cutover
```

**Deliverable**: USB system fully configured but services not started

#### Step 0.5: Switch Back to SD System (5 min)

```bash
# We've prepared USB completely, now switch back to SD to finish prep
sudo shutdown -h now

# Change boot order back to SD first
# Power on - should boot from SD card
# Verify: lsblk (root should be on mmcblk0p2)
```

**Deliverable**: Back on SD system, USB ready for final cutover

---

### Phase 1: Final Cutover - **< 15 minutes downtime**

**Goal**: Switch from SD to USB with minimal service interruption

#### Pre-Cutover Checklist (5 min - no downtime)

```bash
# On SD system (still serving traffic)

# 1. Verify all services healthy
systemctl status caddy pihole-FTL docker nfs-kernel-server \
  atuin-server semaphore gotty
docker ps

# 2. Verify external access working
curl -I https://n8n.ism.la
dig @localhost dns.ism.la

# 3. Final state export
cd ~/Projects/crtr-config
./scripts/sync/export-live-state.sh

# 4. Sync any last-minute changes to /cluster-nas
sudo rsync -av /etc/caddy/ /cluster-nas/backups/migration-$(date +%F)/etc/caddy/
sudo rsync -av /etc/pihole/ /cluster-nas/backups/migration-$(date +%F)/etc/pihole/

# 5. Announce downtime (if needed)
# Post notice to users about 15-minute maintenance
```

#### Cutover Execution (10-15 min downtime)

**CRITICAL SECTION - Minimizing downtime**

```bash
# STEP 1: Graceful service shutdown (2 min)
# Stop services in reverse dependency order

# Stop Docker containers first
cd /cluster-nas/services/n8n
docker compose down

# Stop custom services
sudo systemctl stop gotty
sudo systemctl stop semaphore
sudo systemctl stop atuin-server

# Stop infrastructure services
sudo systemctl stop caddy
sudo systemctl stop pihole-FTL

# NFS can stay running (USB will need it anyway)

# STEP 2: Final sync (1 min)
# Ensure all writes to /cluster-nas are flushed
sync
sudo systemctl stop docker  # Stop Docker daemon

# STEP 3: Shutdown and switch boot (3 min)
sudo shutdown -h now

# Wait for complete shutdown
# Change boot order: USB first, SD second
# Power on

# STEP 4: Boot USB system (2 min)
# System boots from USB
# /cluster-nas should auto-mount from fstab

# STEP 5: Start services in dependency order (5 min)

# SSH to USB system
ssh crtr@192.168.254.10

# Verify /cluster-nas mounted
df -h /cluster-nas

# Start infrastructure services
sudo systemctl start nfs-kernel-server
sudo systemctl start pihole-FTL
sudo systemctl start docker
sudo systemctl start caddy

# Start custom services
sudo systemctl start atuin-server
sudo systemctl start semaphore
sudo systemctl start gotty

# Start Docker containers
cd /cluster-nas/services/n8n
docker compose up -d

# STEP 6: Verify services (2 min)
systemctl status caddy pihole-FTL docker nfs-kernel-server
systemctl status atuin-server semaphore gotty
docker ps

# Check DNS
dig @localhost dns.ism.la

# Check HTTPS
curl -I https://n8n.ism.la
curl -I https://dns.ism.la
curl -I https://smp.ism.la
```

**Total Downtime**: ~10-15 minutes (services offline during cutover)

---

### Phase 2: Post-Cutover Verification (15 min - services running)

```bash
# Comprehensive service verification

# 1. All systemd services running
systemctl --failed
systemctl status caddy pihole-FTL nfs-kernel-server docker \
  atuin-server semaphore gotty

# 2. Docker containers healthy
docker ps
docker logs n8n --tail 50
docker logs n8n-postgres --tail 50

# 3. DNS resolution
dig @localhost dns.ism.la +short
dig @localhost n8n.ism.la +short
dig @localhost smp.ism.la +short

# 4. Local service endpoints
curl -I http://localhost:5678  # n8n
curl -I http://localhost:3001  # semaphore
curl -I http://localhost:7681  # gotty
curl -I http://localhost:8811  # atuin

# 5. HTTPS via Caddy
curl -I https://dns.ism.la
curl -I https://n8n.ism.la
curl -I https://smp.ism.la
curl -I https://ssh.ism.la
curl -I https://mng.ism.la

# 6. Cross-node proxies
curl -I https://acn.ism.la  # projector
curl -I https://api.ism.la  # projector
curl -I https://dtb.ism.la  # projector

# 7. External access (from another machine)
curl -I https://n8n.ism.la

# 8. NFS exports
showmount -e localhost
# From projector: sudo mount 192.168.254.10:/cluster-nas /mnt/test

# 9. Storage health
df -h
lsblk
sudo smartctl -a /dev/sdb || echo "No SMART for USB"

# 10. System resources
htop  # Check CPU/RAM
vcgencmd measure_temp  # CPU temperature

# 11. Cron jobs installed
crontab -l

# 12. No critical errors
sudo journalctl -p err -b --no-pager

# 13. Boot device verification
lsblk | grep "/"
# Should show /dev/sdb2 mounted at /
```

**Deliverable**: All services verified operational on USB system

---

## Rollback Plan (5 min if needed)

**If anything goes wrong during or after cutover:**

### Immediate Rollback

```bash
# 1. Shutdown USB system
sudo shutdown -h now

# 2. Change boot order back to SD first

# 3. Power on

# 4. System boots from SD card (unchanged)

# 5. Verify services (they should auto-start)
systemctl status caddy docker pihole-FTL
docker ps

# 6. Check domains
curl -I https://n8n.ism.la
```

**Rollback Time**: ~5 minutes
**Data Loss Risk**: NONE (all data on /cluster-nas, unchanged)

### Why Rollback is Safe

1. SD card completely untouched during migration
2. All data on separate NVMe drive
3. Configuration backed up to /cluster-nas
4. Just change boot order in BIOS

---

## Downtime Breakdown

| Phase | Activity | Duration | Cumulative |
|-------|----------|----------|------------|
| **Pre-Cutover** | Announce maintenance | 0 min | 0 min |
| **Cutover** | Stop services gracefully | 2 min | 2 min |
| **Cutover** | Final sync | 1 min | 3 min |
| **Cutover** | Shutdown & boot switch | 3 min | 6 min |
| **Cutover** | USB boot | 2 min | 8 min |
| **Cutover** | Start all services | 5 min | 13 min |
| **Verify** | Basic service checks | 2 min | 15 min |
| **Total Downtime** | | **15 minutes** | |

**Services Unavailable**: 13-15 minutes
**External Access Down**: 13-15 minutes
**Data at Risk**: NONE (/cluster-nas unchanged)

---

## Success Criteria

### Minimum Success (after 15 min)

- ✅ System boots from USB
- ✅ SSH access works
- ✅ /cluster-nas mounted
- ✅ All systemd services running
- ✅ All Docker containers running
- ✅ DNS resolution working
- ✅ HTTPS certificates active
- ✅ External domains accessible

### Complete Success (after 24 hours)

- ✅ No critical errors in logs
- ✅ All cron jobs executing
- ✅ No service restarts
- ✅ Performance equivalent or better
- ✅ Backup jobs successful
- ✅ DuckDNS updating correctly

---

## Risk Mitigation

### Risk 1: USB System Won't Boot

**Probability**: Low
**Impact**: High
**Mitigation**:
- Pre-verify USB system boots before final cutover
- Keep SD card as instant rollback
- Test boot from USB in Step 0.3

### Risk 2: Services Fail to Start on USB

**Probability**: Medium
**Impact**: Medium
**Mitigation**:
- Pre-install all packages and dependencies
- Copy all configuration files in advance
- Test service start commands before cutover
- Have configuration backup on /cluster-nas

### Risk 3: Configuration Drift During Prep

**Probability**: Low
**Impact**: Low
**Mitigation**:
- Final state export just before cutover
- Sync latest configs during pre-cutover checklist
- Backup timestamp allows identifying latest changes

### Risk 4: /cluster-nas Mount Fails on USB

**Probability**: Very Low
**Impact**: High
**Mitigation**:
- Use UUID in fstab (not device name)
- NVMe drive independent of boot device
- Test mount during USB prep phase

---

## Performance Expectations

### Current (SD Card)
- Sequential Read: ~90 MB/s
- Sequential Write: ~40 MB/s
- Random IOPS: Limited
- Boot Time: ~60 seconds

### Expected (USB 3.2)
- Sequential Read: ~400 MB/s (4x faster)
- Sequential Write: ~300 MB/s (7x faster)
- Random IOPS: Much better
- Boot Time: ~45 seconds (faster)

**Overall**: Significant performance improvement expected

---

## Post-Migration Tasks

### Immediate (Day 1)

```bash
# 1. Update state files with new OS info
cd ~/Projects/crtr-config
vim state/node.yml
# Change: os.distribution from "Debian 13" to "Raspberry Pi OS"
# Change: boot_device from "mmcblk0" to "sdb"

git add state/
git commit -m "Migration complete: Debian SD → Raspberry Pi OS USB"
git push

# 2. Restore user environment
# Install starship
curl -sS https://starship.rs/install.sh | sh

# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# Initialize dotfiles
chezmoi init --apply

# Configure Atuin client
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
atuin login -u crtr
atuin sync

# Set zsh as default
chsh -s /bin/zsh

# 3. Create USB system backup
sudo dd if=/dev/sdb of=/cluster-nas/backups/usb-raspios-$(date +%F).img \
  bs=4M status=progress
sudo gzip /cluster-nas/backups/usb-raspios-$(date +%F).img
```

### 24-Hour Monitoring

- [ ] Check all service logs for errors
- [ ] Verify DuckDNS cron updating
- [ ] Verify backup cron running
- [ ] Monitor system temperature
- [ ] Monitor memory usage
- [ ] Check external access from multiple locations
- [ ] Verify NFS access from projector/director

### 1-Week Stability Check

- [ ] No service crashes
- [ ] No unexpected restarts
- [ ] All automated tasks running
- [ ] External access stable
- [ ] Performance as expected or better
- [ ] Can declare migration successful
- [ ] Can repurpose SD card (optional)

---

## Emergency Contacts

### System Info
- **Current Boot**: SD Card (mmcblk0)
- **Target Boot**: USB 3.2 (sdb)
- **Data Storage**: NVMe (sda1) at /cluster-nas
- **Static IP**: 192.168.254.10
- **DuckDNS**: crtrcooperator.duckdns.org

### UUIDs
- **SD Card Root**: 519ae0e2-6045-40ab-b068-c4de3f7f7139
- **USB Root**: 37d2cb52-513e-40e1-b90f-213aa6096cba
- **NVMe Data**: 810880b9-6e26-4b18-8246-ca19fd56bc8f

### Service Ports
- Caddy: 80, 443, 8443
- Pi-hole: 53, 8080
- NFS: 2049
- Atuin: 8811
- Semaphore: 3001
- GoTTY: 7681
- n8n: 5678 (127.0.0.1 only)

---

## Timeline Recommendation

### Optimal Migration Window

**Day 1 (Weekend/Off-hours)**:
- Phase 0: Pre-migration prep (2 hours, no downtime)
  - 0.1: Export state (15 min)
  - 0.2: Mount and prepare USB (30 min)
  - 0.3: Boot USB and install packages (45 min)
  - 0.4: Pre-deploy configuration (30 min)
  - 0.5: Switch back to SD (5 min)

**Day 2 (Planned maintenance window)**:
- Announce 15-minute maintenance window
- Phase 1: Final cutover (15 min downtime)
  - Pre-cutover checklist (5 min)
  - Cutover execution (10-15 min)
- Phase 2: Post-cutover verification (15 min)
- **Total user-facing downtime: 15 minutes**

**Day 3-9**:
- 24-hour monitoring
- 1-week stability verification
- Declare success

---

## Conclusion

This minimal downtime migration strategy achieves:

✅ **< 15 minutes total downtime**
✅ **Zero data loss risk** (data on separate drive)
✅ **5-minute rollback** if needed
✅ **Complete preparation before cutover**
✅ **Verified service health before cutover**
✅ **Systematic verification after cutover**

**The key**: Pre-deploy everything on USB while SD card still serves traffic, then execute a quick cutover that's just stop-services → boot-switch → start-services.

---

**Ready to execute?** Follow the phases in order.

**Document Version**: 1.0
**Status**: Ready for execution
