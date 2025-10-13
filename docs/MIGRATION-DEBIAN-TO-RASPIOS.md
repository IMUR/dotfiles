# Migration Plan: Debian SD Card → Raspberry Pi OS USB Drive

**Status**: Ready for execution
**Created**: 2025-10-13
**Target**: Migrate cooperator from Debian 13 on 955GB microSD to Raspberry Pi OS on 256GB USB drive
**Safety**: SD card remains intact for rollback

---

## Executive Summary

### Current State
- **Boot Device**: 955GB microSD card (mmcblk0)
- **OS**: Debian 13 (Trixie)
- **Usage**: 23GB used / 939GB available
- **Services**: All running and operational
- **Data Storage**: 1.8TB NVMe at /cluster-nas (39GB used)

### Target State
- **Boot Device**: 256GB USB 3.2.2 drive (sdb)
- **OS**: Raspberry Pi OS (pre-installed)
- **Services**: All migrated and operational
- **Data Storage**: Same NVMe at /cluster-nas (unchanged)

### Migration Strategy
**Schema-First Approach**: Leverage crtr-config repository to:
1. Export current system state to `state/*.yml`
2. Prepare USB drive with Raspberry Pi OS
3. Deploy from state files to USB system
4. Test thoroughly
5. Switch boot device
6. Keep SD card as instant rollback option

### Key Advantages
- **Data safety**: All data on /cluster-nas (not OS drive)
- **Quick rollback**: SD card stays intact, just change boot order
- **Infrastructure-as-Code**: State files ensure consistent deployment
- **Testing**: Can test USB system while SD remains operational
- **Automation**: Schema-first approach automates deployment

---

## System Analysis

### Current Disk Layout

```
┌─────────────────────────────────────────────────────────┐
│ microSD (mmcblk0) - 955GB - CURRENTLY BOOTING          │
├─────────────────────────────────────────────────────────┤
│ ├─ mmcblk0p1 (512M vfat)    /boot/firmware            │
│ └─ mmcblk0p2 (939G ext4)    /  (23GB used)            │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ USB Drive (sdb) - 233GB - TARGET                       │
├─────────────────────────────────────────────────────────┤
│ ├─ sdb1 (512M vfat)         bootfs (RPi OS)           │
│ └─ sdb2 (232G ext4)         rootfs (RPi OS)           │
│   Pre-installed Raspberry Pi OS (not mounted)          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ NVMe (sda) - 1.8TB - DATA STORAGE                      │
├─────────────────────────────────────────────────────────┤
│ └─ sda1 (1.8T xfs)          /cluster-nas               │
│   All service data, configs, repos (39GB used)         │
│   *** THIS DOES NOT CHANGE DURING MIGRATION ***        │
└─────────────────────────────────────────────────────────┘
```

### Partition UUIDs

**Current (SD Card)**:
- mmcblk0p1: `UUID=22FA-0214` (bootfs)
- mmcblk0p2: `UUID=519ae0e2-6045-40ab-b068-c4de3f7f7139` (rootfs)

**Target (USB)**:
- sdb1: `UUID=27E7-00CE` (bootfs)
- sdb2: `UUID=37d2cb52-513e-40e1-b90f-213aa6096cba` (rootfs)

**Data (NVMe - unchanged)**:
- sda1: Label=crtr-data (to be mounted at /cluster-nas)

---

## Migration Phases

### Phase 0: Pre-Migration Preparation (30 min)

**Goal**: Ensure safety and backups

#### Tasks

1. **Verify /cluster-nas data backup**
   ```bash
   # Check recent backup exists
   ls -lh /cluster-nas/backups/

   # If needed, create fresh backup
   sudo rsync -avP /cluster-nas/ /path/to/external/backup/
   ```

2. **Export current system state**
   ```bash
   cd ~/Projects/crtr-config

   # Create state export script (if not exists)
   ./scripts/sync/export-live-state.sh

   # This should capture:
   # - All systemd services
   # - Docker containers
   # - Caddy config
   # - DNS config
   # - Network config
   # - Installed packages
   ```

3. **Verify state files are complete**
   ```bash
   # Check that state files exist and are populated
   ls -lh state/
   cat state/services.yml
   cat state/domains.yml
   cat state/network.yml
   cat state/node.yml

   # Validate if validation script exists
   if [ -f ./tests/test-state.sh ]; then
       ./tests/test-state.sh
   fi
   ```

4. **Document current system state**
   ```bash
   # Capture package list
   dpkg -l > /cluster-nas/backups/migration-$(date +%F)/debian-packages.txt

   # Capture systemd services
   systemctl list-units --type=service --all > \
     /cluster-nas/backups/migration-$(date +%F)/systemd-services.txt

   # Capture docker containers
   docker ps -a > /cluster-nas/backups/migration-$(date +%F)/docker-containers.txt

   # Capture network config
   ip addr > /cluster-nas/backups/migration-$(date +%F)/network-config.txt
   cat /etc/resolv.conf > /cluster-nas/backups/migration-$(date +%F)/resolv.conf

   # Capture mount points
   cat /etc/fstab > /cluster-nas/backups/migration-$(date +%F)/fstab
   mount > /cluster-nas/backups/migration-$(date +%F)/mounts.txt
   ```

5. **Test SD card is working correctly**
   ```bash
   # Ensure no disk errors
   sudo dmesg | grep -i "error\|warn" | grep -i "mmcblk0"

   # Check SD card health
   sudo smartctl -a /dev/mmcblk0 || echo "No SMART data for SD card"
   ```

**Deliverable**:
- ✅ Current system state exported to state/*.yml
- ✅ System state documented in /cluster-nas/backups/
- ✅ SD card verified healthy
- ✅ Backups confirmed

---

### Phase 1: USB Drive Preparation (1 hour)

**Goal**: Prepare USB drive with bootable Raspberry Pi OS

#### Tasks

1. **Mount USB drive to inspect**
   ```bash
   # Create mount points
   sudo mkdir -p /mnt/usb-boot
   sudo mkdir -p /mnt/usb-root

   # Mount USB partitions
   sudo mount /dev/sdb1 /mnt/usb-boot
   sudo mount /dev/sdb2 /mnt/usb-root

   # Check what's already there
   ls -la /mnt/usb-boot
   ls -la /mnt/usb-root

   # Check Raspberry Pi OS version
   cat /mnt/usb-root/etc/os-release
   ```

2. **Verify Raspberry Pi OS is bootable**
   ```bash
   # Check boot files exist
   ls -lh /mnt/usb-boot/kernel*.img
   ls -lh /mnt/usb-boot/bcm*.dtb
   ls -lh /mnt/usb-boot/config.txt
   ls -lh /mnt/usb-boot/cmdline.txt

   # Check root filesystem
   ls -lh /mnt/usb-root/bin/bash
   ls -lh /mnt/usb-root/etc/
   ```

3. **Configure USB boot for first run**
   ```bash
   # Set hostname
   echo "cooperator" | sudo tee /mnt/usb-root/etc/hostname

   # Set hosts file
   sudo sed -i 's/raspberrypi/cooperator/g' /mnt/usb-root/etc/hosts

   # Enable SSH (create empty file)
   sudo touch /mnt/usb-boot/ssh

   # Copy SSH keys for access
   sudo mkdir -p /mnt/usb-root/home/pi/.ssh
   sudo cp ~/.ssh/authorized_keys /mnt/usb-root/home/pi/.ssh/
   sudo chmod 700 /mnt/usb-root/home/pi/.ssh
   sudo chmod 600 /mnt/usb-root/home/pi/.ssh/authorized_keys
   sudo chown -R 1000:1000 /mnt/usb-root/home/pi/.ssh
   ```

4. **Configure fstab for /cluster-nas**
   ```bash
   # Add /cluster-nas mount to fstab
   echo "# NVMe data storage" | sudo tee -a /mnt/usb-root/etc/fstab
   echo "/dev/sda1  /cluster-nas  xfs  defaults  0  2" | \
     sudo tee -a /mnt/usb-root/etc/fstab

   # Create mount point
   sudo mkdir -p /mnt/usb-root/cluster-nas

   # Verify fstab
   cat /mnt/usb-root/etc/fstab
   ```

5. **Configure network (static IP)**
   ```bash
   # Configure dhcpcd for static IP
   sudo tee -a /mnt/usb-root/etc/dhcpcd.conf <<EOF

# Static IP for cooperator
interface eth0
static ip_address=192.168.254.10/24
static routers=192.168.254.1
static domain_name_servers=1.1.1.1 1.0.0.1
EOF

   # Verify
   tail -10 /mnt/usb-root/etc/dhcpcd.conf
   ```

6. **Safely unmount USB**
   ```bash
   sudo umount /mnt/usb-boot
   sudo umount /mnt/usb-root
   ```

**Deliverable**:
- ✅ USB drive has bootable Raspberry Pi OS
- ✅ Hostname set to "cooperator"
- ✅ SSH enabled with keys
- ✅ Static IP configured
- ✅ /cluster-nas mount configured in fstab

**Risk Mitigation**: SD card still bootable, no changes made to it

---

### Phase 2: First Boot Test (30 min)

**Goal**: Boot from USB and verify basic functionality

#### Tasks

1. **Prepare for boot switch**
   ```bash
   # Note: We're about to switch boot device
   # SD card remains inserted but won't boot
   # Can revert by changing boot order back
   ```

2. **Change boot order**
   - Shutdown system: `sudo shutdown -h now`
   - Wait for complete shutdown
   - **Leave SD card inserted** (for safety)
   - Ensure USB drive is connected
   - Power on
   - **Enter BIOS/UEFI** (hold DEL or F2 during boot)
   - Change boot order: USB before SD
   - Save and exit
   - System should boot from USB

3. **Connect via SSH**
   ```bash
   # From another machine
   ssh pi@192.168.254.10
   # Or
   ssh crtr@192.168.254.10  # if user already exists
   ```

4. **Verify basic boot**
   ```bash
   # Check OS version
   cat /etc/os-release
   # Should show Raspberry Pi OS

   # Check boot device
   lsblk
   # / should be on /dev/sdb2
   # /boot/firmware should be on /dev/sdb1

   # Check /cluster-nas mount
   df -h /cluster-nas
   # Should be mounted from /dev/sda1

   # Verify network
   ip addr show eth0
   # Should be 192.168.254.10

   ping -c 3 1.1.1.1
   # Should work
   ```

5. **Create migration user if needed**
   ```bash
   # If logged in as 'pi', create 'crtr' user
   sudo useradd -m -s /bin/bash -G sudo,users crtr
   sudo cp -r ~/.ssh /home/crtr/
   sudo chown -R crtr:crtr /home/crtr/.ssh

   # Set password
   sudo passwd crtr

   # Test sudo
   sudo -u crtr sudo whoami
   # Should return: root
   ```

**Deliverable**:
- ✅ System boots from USB
- ✅ SSH access works
- ✅ /cluster-nas is mounted
- ✅ Network configured correctly
- ✅ User account ready

**Rollback**: If boot fails, power off, change boot order back to SD, power on

---

### Phase 3: System Preparation (1 hour)

**Goal**: Install base packages and prepare for service deployment

#### Tasks

1. **Update package list**
   ```bash
   sudo apt update
   ```

2. **Install essential packages**
   ```bash
   # Essential tools
   sudo apt install -y \
     git vim curl wget \
     tmux htop tree ncdu \
     rsync duf \
     build-essential

   # User tools
   sudo apt install -y \
     bat fd-find ripgrep
   ```

3. **Install Docker**
   ```bash
   # Using official Docker install script
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   # Add user to docker group
   sudo usermod -aG docker crtr

   # Verify
   sudo systemctl status docker
   ```

4. **Install Caddy**
   ```bash
   # Add Caddy repository
   sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
     sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
     sudo tee /etc/apt/sources.list.d/caddy-stable.list

   # Install Caddy
   sudo apt update
   sudo apt install -y caddy

   # Verify
   caddy version
   ```

5. **Install NFS server**
   ```bash
   sudo apt install -y nfs-kernel-server

   # Verify
   sudo systemctl status nfs-kernel-server
   ```

6. **Install Pi-hole** (if not pre-installed)
   ```bash
   # Check if Pi-hole exists
   if ! command -v pihole &> /dev/null; then
       curl -sSL https://install.pi-hole.net | bash
       # Follow interactive prompts
   fi
   ```

7. **Clone crtr-config repository**
   ```bash
   # Clone from /cluster-nas
   cd ~
   mkdir -p Projects
   cd Projects

   # If repo exists on /cluster-nas
   if [ -d /cluster-nas/repos/crtr-config ]; then
       git clone /cluster-nas/repos/crtr-config
   else
       # Clone from remote if needed
       git clone <remote-url> crtr-config
   fi

   cd crtr-config
   git status
   ```

**Deliverable**:
- ✅ Package manager updated
- ✅ Essential packages installed
- ✅ Docker installed and running
- ✅ Caddy installed
- ✅ NFS server installed
- ✅ crtr-config repository cloned

---

### Phase 4: Service Deployment (2-3 hours)

**Goal**: Deploy all services using schema-first approach

#### Option A: If deploy automation exists

```bash
cd ~/Projects/crtr-config

# Validate state files
./tests/test-state.sh

# Generate configs
./scripts/generate/regenerate-all.sh

# Deploy all services
./deploy/deploy all

# Verify deployment
./deploy/verify/verify-all.sh
```

#### Option B: Manual deployment (if automation not ready)

1. **Deploy NFS exports**
   ```bash
   # Copy or generate /etc/exports
   sudo cp /cluster-nas/backups/migration-$(date +%F)/fstab /etc/fstab

   # Or create from state
   sudo tee /etc/exports <<EOF
/cluster-nas  192.168.254.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF

   # Restart NFS
   sudo exportfs -ra
   sudo systemctl restart nfs-kernel-server

   # Verify
   showmount -e localhost
   ```

2. **Deploy Caddy config**
   ```bash
   # Generate Caddyfile from state/domains.yml
   # Or copy from backup
   sudo cp ~/Projects/crtr-config/config/caddy/Caddyfile /etc/caddy/Caddyfile

   # Validate config
   sudo caddy validate --config /etc/caddy/Caddyfile

   # Reload Caddy
   sudo systemctl reload caddy

   # Verify
   sudo systemctl status caddy
   curl -I http://localhost
   ```

3. **Deploy DNS config (Pi-hole)**
   ```bash
   # Copy local DNS overrides
   sudo cp ~/Projects/crtr-config/config/pihole/local-dns.conf \
     /etc/dnsmasq.d/02-custom-local-dns.conf

   # Restart Pi-hole
   sudo systemctl restart pihole-FTL

   # Verify
   dig @localhost dns.ism.la +short
   # Should return: 192.168.254.10
   ```

4. **Deploy custom systemd services**
   ```bash
   # Atuin server
   sudo cp ~/Projects/crtr-config/config/systemd/atuin-server.service \
     /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable atuin-server
   sudo systemctl start atuin-server
   sudo systemctl status atuin-server

   # Semaphore
   sudo cp ~/Projects/crtr-config/config/systemd/semaphore.service \
     /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable semaphore
   sudo systemctl start semaphore
   sudo systemctl status semaphore

   # GoTTY
   sudo cp ~/Projects/crtr-config/config/systemd/gotty.service \
     /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable gotty
   sudo systemctl start gotty
   sudo systemctl status gotty
   ```

5. **Deploy Docker services**
   ```bash
   # n8n
   cd /cluster-nas/services/n8n
   docker compose up -d

   # Verify
   docker ps
   docker logs n8n
   curl -I http://localhost:5678
   ```

6. **Configure DuckDNS**
   ```bash
   # Copy DuckDNS script
   mkdir -p ~/duckdns
   cp /cluster-nas/backups/migration-$(date +%F)/duck.sh ~/duckdns/
   chmod +x ~/duckdns/duck.sh

   # Add to cron
   (crontab -l 2>/dev/null; echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1") | crontab -

   # Test
   ~/duckdns/duck.sh
   cat ~/duckdns/duck.log
   ```

**Deliverable**:
- ✅ All services deployed
- ✅ Caddy serving domains
- ✅ DNS resolving correctly
- ✅ Docker containers running
- ✅ Custom services operational

---

### Phase 5: Verification & Testing (1 hour)

**Goal**: Comprehensive verification of all services

#### Service Verification

```bash
# Check all systemd services
systemctl status caddy
systemctl status pihole-FTL
systemctl status nfs-kernel-server
systemctl status docker
systemctl status atuin-server
systemctl status semaphore
systemctl status gotty

# Check Docker containers
docker ps

# Verify no failed services
systemctl --failed
```

#### Network Verification

```bash
# DNS resolution
dig @localhost dns.ism.la +short
dig @localhost n8n.ism.la +short
dig @localhost smp.ism.la +short

# Local service access
curl -I http://localhost:8080  # Pi-hole
curl -I http://localhost:3000  # Semaphore
curl -I http://localhost:5678  # n8n
curl -I http://localhost:7681  # GoTTY

# Caddy reverse proxy
curl -I http://dns.ism.la  # Should redirect to HTTPS
curl -I https://dns.ism.la
curl -I https://smp.ism.la
curl -I https://n8n.ism.la
```

#### Storage Verification

```bash
# Check /cluster-nas
df -h /cluster-nas
ls -la /cluster-nas/services/

# NFS export
showmount -e localhost

# Test NFS from another node (if available)
# From projector:
# sudo mount 192.168.254.10:/cluster-nas /mnt/test
# ls -la /mnt/test
```

#### External Access Verification

```bash
# Test DuckDNS
curl -s "https://www.duckdns.org/update?domains=crtrcooperator&token=dd3810d4-6ea3-497b-832f-ec0beaf679b3&ip="

# Test external domain resolution (from external machine)
# dig crtrcooperator.duckdns.org
# curl -I https://n8n.ism.la
```

#### Data Integrity Check

```bash
# Verify service data is accessible
ls -la /cluster-nas/services/n8n/data/
ls -la /cluster-nas/services/semaphore/

# Check Docker volumes
docker volume ls
docker volume inspect n8n_n8n-data
```

**Deliverable**:
- ✅ All services running
- ✅ DNS resolution working
- ✅ HTTPS certificates obtained
- ✅ External access functional
- ✅ /cluster-nas data accessible

---

### Phase 6: User Environment Setup (30 min)

**Goal**: Restore user environment and dotfiles

```bash
# Install zsh
sudo apt install -y zsh

# Set zsh as default shell
chsh -s /bin/zsh

# Install starship prompt
curl -sS https://starship.rs/install.sh | sh

# Install chezmoi (if used)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# Initialize dotfiles
chezmoi init --apply

# Or manually copy dotfiles
cp /cluster-nas/backups/migration-$(date +%F)/.zshrc ~/
cp /cluster-nas/backups/migration-$(date +%F)/.bashrc ~/
cp /cluster-nas/backups/migration-$(date +%F)/.gitconfig ~/

# Install Atuin client
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)

# Configure Atuin
atuin login -u <username>
atuin sync
```

**Deliverable**:
- ✅ User shell configured
- ✅ Dotfiles restored
- ✅ Prompt configured
- ✅ Atuin synced

---

### Phase 7: Final Validation (30 min)

**Goal**: Complete system validation

#### Comprehensive Check

```bash
# Run verification script (if exists)
cd ~/Projects/crtr-config
./deploy/verify/verify-all.sh

# Or manual checks:

# 1. All services up
systemctl list-units --type=service --failed

# 2. All containers running
docker ps --filter "status=exited"

# 3. All domains accessible
for domain in dns.ism.la smp.ism.la n8n.ism.la ssh.ism.la mng.ism.la; do
    echo "Testing $domain"
    curl -I -k https://$domain 2>&1 | head -1
done

# 4. Cross-node proxies working
curl -I https://acn.ism.la
curl -I https://api.ism.la
curl -I https://dtb.ism.la

# 5. Storage healthy
df -h
lsblk

# 6. System resources
htop
# Check CPU, RAM usage

# 7. Check logs for errors
sudo journalctl -p err -b

# 8. Network connectivity
ping -c 3 1.1.1.1
ping -c 3 192.168.254.20  # projector
ping -c 3 192.168.254.30  # director
```

#### Performance Baseline

```bash
# CPU temperature
vcgencmd measure_temp

# Memory usage
free -h

# Disk I/O
iostat -x 1 5

# Network throughput
iperf3 -s &  # On cooperator
iperf3 -c 192.168.254.10  # From another node
```

**Deliverable**:
- ✅ All services verified operational
- ✅ All domains accessible
- ✅ No critical errors in logs
- ✅ Performance baseline established

---

## Rollback Procedures

### Quick Rollback (5 min)

**If something goes wrong during early phases:**

1. **Shutdown system**
   ```bash
   sudo shutdown -h now
   ```

2. **Change boot order back to SD card**
   - Power off completely
   - Enter BIOS/UEFI (hold DEL or F2)
   - Change boot order: SD before USB
   - Save and exit

3. **Boot from SD card**
   - System boots back to Debian
   - Everything exactly as before
   - /cluster-nas still mounted (unchanged)

4. **Verify SD card system**
   ```bash
   # Check we're on SD
   lsblk
   # / should be on /dev/mmcblk0p2

   # Check services
   systemctl status caddy pihole-FTL docker

   # Check domains
   curl -I https://n8n.ism.la
   ```

**Result**: Back to operational Debian system in 5 minutes

### Selective Rollback

**If only specific services fail:**

1. **Keep USB boot** (don't switch back)
2. **Fix individual service** on USB system
3. **Copy working config** from SD card:
   ```bash
   # Mount SD card partitions
   sudo mkdir -p /mnt/sd-root
   sudo mount /dev/mmcblk0p2 /mnt/sd-root

   # Copy specific config
   sudo cp /mnt/sd-root/etc/caddy/Caddyfile /etc/caddy/
   sudo systemctl reload caddy

   # Unmount
   sudo umount /mnt/sd-root
   ```

### Data Recovery

**If /cluster-nas mount fails:**

```bash
# Check NVMe health
lsblk
sudo smartctl -a /dev/sda

# Manually mount
sudo mount /dev/sda1 /cluster-nas

# Check fstab
cat /etc/fstab

# Fix UUID if needed
sudo blkid /dev/sda1
# Update /etc/fstab with correct UUID
```

### Emergency Rollback (worst case)

**If USB system completely fails:**

1. Boot from SD card (change boot order)
2. USB system is isolated - no risk to SD
3. Can re-attempt migration anytime
4. Can wipe USB and start over
5. /cluster-nas data never at risk

---

## Post-Migration Tasks

### After Successful Migration

1. **Update documentation**
   ```bash
   cd ~/Projects/crtr-config

   # Update node.yml with new OS info
   vim state/node.yml
   # Change: Debian 13 → Raspberry Pi OS
   # Change: mmcblk0 → sdb

   # Commit changes
   git add state/
   git commit -m "Migration complete: Debian SD → Raspberry Pi OS USB"
   git push
   ```

2. **Create new backup**
   ```bash
   # Backup USB system
   sudo dd if=/dev/sdb of=/cluster-nas/backups/usb-raspios-$(date +%F).img bs=4M status=progress

   # Compress
   sudo gzip /cluster-nas/backups/usb-raspios-$(date +%F).img
   ```

3. **Monitor for 24 hours**
   - Check service logs
   - Monitor uptime
   - Watch for any anomalies
   - Verify external access
   - Check automated tasks (DuckDNS cron)

4. **After 1 week of stable operation**
   - Can repurpose SD card
   - Keep one full backup of USB
   - Update disaster recovery procedures

### SD Card Options

**Option 1: Keep as instant rollback** (recommended for 30 days)
- Leave SD card inserted
- Can boot from it anytime by changing boot order
- Zero risk, instant rollback

**Option 2: Create fresh backup SD**
- Clone USB to SD card
- Keep as cold backup
- Store safely

**Option 3: Repurpose SD card**
- Use for another system
- Use for backups
- Use for testing

---

## Timeline Summary

| Phase | Duration | Can Rollback | Risk Level |
|-------|----------|--------------|------------|
| 0. Pre-Migration Prep | 30 min | N/A | None |
| 1. USB Preparation | 1 hour | Yes (no changes yet) | None |
| 2. First Boot Test | 30 min | Yes (instant) | Low |
| 3. System Preparation | 1 hour | Yes (instant) | Low |
| 4. Service Deployment | 2-3 hours | Yes (instant) | Medium |
| 5. Verification & Testing | 1 hour | Yes (instant) | Low |
| 6. User Environment | 30 min | Yes (instant) | Low |
| 7. Final Validation | 30 min | Yes (instant) | Low |
| **Total** | **6-8 hours** | **Yes, always** | **Low** |

### Suggested Schedule

**Day 1 (Phases 0-2)**: 2 hours
- Pre-migration prep
- USB preparation
- First boot test
- **Stop here**: Verify basic boot works
- **Rollback test**: Switch boot order, verify SD still works

**Day 2 (Phases 3-4)**: 4 hours
- System preparation
- Service deployment
- **Stop here**: Core services running
- **Monitor overnight**

**Day 3 (Phases 5-7)**: 2 hours
- Complete verification
- User environment
- Final validation
- **Declare success or rollback**

**Day 4-30**: Monitoring
- 24-hour monitoring
- 1-week stability check
- Keep SD card as rollback option

---

## Success Criteria

### Minimum Viable Migration
- ✅ System boots from USB
- ✅ SSH access works
- ✅ /cluster-nas mounted
- ✅ Caddy serving HTTPS
- ✅ DNS resolution working
- ✅ Docker containers running

### Complete Migration
- ✅ All systemd services operational
- ✅ All Docker containers running
- ✅ All domains accessible (internal)
- ✅ All domains accessible (external)
- ✅ NFS exports working
- ✅ User environment configured
- ✅ No critical errors in logs
- ✅ Performance equivalent or better
- ✅ 24-hour uptime confirmed

### Excellence Criteria
- ✅ Schema-first deployment automated
- ✅ State files up-to-date
- ✅ Documentation complete
- ✅ Rollback tested
- ✅ Backup verified
- ✅ 1-week stability confirmed

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| USB boot fails | Low | High | SD card instant rollback |
| Services fail to start | Medium | Medium | Copy configs from SD |
| /cluster-nas won't mount | Low | High | Data on NVMe, not OS drive |
| Network config wrong | Low | Medium | Serial console access |
| Performance degradation | Low | Low | USB 3.2 > SD card speed |
| Data loss | Very Low | Critical | Data on separate NVMe |
| Complete failure | Very Low | High | SD card untouched |

**Overall Risk Level**: **LOW**
- SD card remains untouched and bootable
- /cluster-nas data never at risk (separate drive)
- Can rollback in 5 minutes at any point
- Can retry migration unlimited times

---

## Notes and Considerations

### Debian vs Raspberry Pi OS

**Key Differences**:
- Package names might differ slightly
- Default configurations may vary
- RPi-specific optimizations in Raspberry Pi OS
- Some packages might need different repositories

**Migration Strategy**:
- Use schema-first approach to abstract differences
- State files describe *what* not *how*
- Deployment scripts handle OS-specific details

### Storage Performance

**Current (SD Card)**:
- Sequential read: ~90 MB/s
- Sequential write: ~40 MB/s
- Random I/O: slow

**Target (USB 3.2)**:
- Sequential read: ~400 MB/s
- Sequential write: ~300 MB/s
- Random I/O: much better

**Expected**: Significant performance improvement

### Boot Order Priority

```
Priority 1: USB drive (sdb)
Priority 2: SD card (mmcblk0)
Priority 3: NVMe (not bootable)
Priority 4: Network boot
```

**For Rollback**: Simply swap priority 1 and 2

### Why This Migration is Low Risk

1. **SD card untouched**: Nothing written to it during migration
2. **Data separate**: /cluster-nas on separate NVMe drive
3. **Instant rollback**: Change boot order in BIOS (5 min)
4. **Can retry**: If USB fails, try again with fresh approach
5. **No data loss risk**: All important data on /cluster-nas
6. **Testing possible**: Can boot USB, test, rollback to SD

---

## Appendix: Quick Commands

### Check Boot Device
```bash
lsblk | grep -E "/$"
# Should show /dev/sdb2 after migration
```

### Check All Services
```bash
systemctl list-units --type=service --state=running | grep -E "caddy|pihole|docker|atuin|semaphore|gotty"
```

### Test All Domains
```bash
for domain in dns.ism.la smp.ism.la n8n.ism.la ssh.ism.la; do
    curl -I -k https://$domain 2>&1 | grep -E "HTTP|failed"
done
```

### Emergency Service Restart
```bash
sudo systemctl restart caddy pihole-FTL docker
docker compose -f /cluster-nas/services/n8n/docker-compose.yml restart
```

### Mount SD Card for Inspection
```bash
sudo mkdir -p /mnt/sd-root
sudo mount /dev/mmcblk0p2 /mnt/sd-root
# Do stuff
sudo umount /mnt/sd-root
```

---

## Questions Before Starting

**Before proceeding, verify:**

1. Is /cluster-nas fully backed up?
2. Are current service configs saved?
3. Is state/*.yml export complete?
4. Do you have physical access to the Pi?
5. Do you have serial console access (if needed)?
6. Is there a maintenance window available?
7. Can services be down for 4-6 hours?

**Ready to proceed?** Start with Phase 0.

---

**Document Version**: 1.0
**Last Updated**: 2025-10-13
**Status**: Ready for execution
