# Migration Checklist: Debian SD → Raspberry Pi OS USB

**Quick reference checklist for migration execution**
**Full details**: See [MIGRATION-DEBIAN-TO-RASPIOS.md](MIGRATION-DEBIAN-TO-RASPIOS.md)

---

## Pre-Flight Checks

- [ ] /cluster-nas backed up to external drive
- [ ] State files exported (state/*.yml complete)
- [ ] Current system documented
- [ ] USB drive with Raspberry Pi OS ready
- [ ] Physical access to Pi available
- [ ] Maintenance window scheduled (6-8 hours)
- [ ] Read full migration plan

---

## Phase 0: Pre-Migration (30 min)

- [ ] Verify backup: `ls -lh /cluster-nas/backups/`
- [ ] Export state: `cd ~/Projects/crtr-config && ./scripts/sync/export-live-state.sh`
- [ ] Document packages: `dpkg -l > /cluster-nas/backups/migration-$(date +%F)/packages.txt`
- [ ] Document services: `systemctl list-units > /cluster-nas/backups/migration-$(date +%F)/services.txt`
- [ ] Check SD health: `sudo dmesg | grep -i mmcblk0`

---

## Phase 1: USB Preparation (1 hour)

- [ ] Mount USB: `sudo mount /dev/sdb1 /mnt/usb-boot && sudo mount /dev/sdb2 /mnt/usb-root`
- [ ] Check RPi OS: `cat /mnt/usb-root/etc/os-release`
- [ ] Set hostname: `echo "cooperator" | sudo tee /mnt/usb-root/etc/hostname`
- [ ] Enable SSH: `sudo touch /mnt/usb-boot/ssh`
- [ ] Copy SSH keys: `sudo cp ~/.ssh/authorized_keys /mnt/usb-root/home/pi/.ssh/`
- [ ] Configure fstab: Add `/dev/sda1 /cluster-nas xfs defaults 0 2`
- [ ] Configure static IP in `/mnt/usb-root/etc/dhcpcd.conf`
- [ ] Unmount: `sudo umount /mnt/usb-boot /mnt/usb-root`

---

## Phase 2: First Boot (30 min)

- [ ] Shutdown: `sudo shutdown -h now`
- [ ] Change boot order: USB first, SD second
- [ ] Power on and boot from USB
- [ ] SSH connect: `ssh pi@192.168.254.10` (or `ssh crtr@192.168.254.10`)
- [ ] Verify OS: `cat /etc/os-release` (should be Raspberry Pi OS)
- [ ] Verify boot device: `lsblk` (root should be /dev/sdb2)
- [ ] Verify /cluster-nas: `df -h /cluster-nas` (should be mounted)
- [ ] Verify network: `ip addr` (should be 192.168.254.10)
- [ ] Create user if needed: `sudo useradd -m -s /bin/bash -G sudo,users crtr`

---

## Phase 3: System Preparation (1 hour)

- [ ] Update packages: `sudo apt update`
- [ ] Install essentials: `sudo apt install -y git vim curl wget tmux htop`
- [ ] Install user tools: `sudo apt install -y bat fd-find ripgrep`
- [ ] Install Docker: `curl -fsSL https://get.docker.com | sudo sh`
- [ ] Add to docker group: `sudo usermod -aG docker crtr`
- [ ] Install Caddy: `sudo apt install -y caddy`
- [ ] Install NFS: `sudo apt install -y nfs-kernel-server`
- [ ] Clone crtr-config: `cd ~/Projects && git clone /cluster-nas/repos/crtr-config`

---

## Phase 4: Service Deployment (2-3 hours)

### If Deploy Automation Exists:
- [ ] Validate state: `./tests/test-state.sh`
- [ ] Generate configs: `./scripts/generate/regenerate-all.sh`
- [ ] Deploy all: `./deploy/deploy all`
- [ ] Verify: `./deploy/verify/verify-all.sh`

### If Manual Deployment:
- [ ] Deploy NFS: Copy `/etc/exports`, run `sudo exportfs -ra`
- [ ] Deploy Caddy: Copy Caddyfile, run `sudo systemctl reload caddy`
- [ ] Deploy DNS: Copy dnsmasq config, run `sudo systemctl restart pihole-FTL`
- [ ] Deploy atuin: Copy unit file, `sudo systemctl enable --now atuin-server`
- [ ] Deploy semaphore: Copy unit file, `sudo systemctl enable --now semaphore`
- [ ] Deploy gotty: Copy unit file, `sudo systemctl enable --now gotty`
- [ ] Deploy n8n: `cd /cluster-nas/services/n8n && docker compose up -d`
- [ ] Configure DuckDNS: Copy script, add to cron

---

## Phase 5: Verification (1 hour)

### Service Status
- [ ] Check systemd: `systemctl status caddy pihole-FTL nfs-kernel-server docker`
- [ ] Check custom: `systemctl status atuin-server semaphore gotty`
- [ ] Check Docker: `docker ps` (should show n8n)
- [ ] Check failed: `systemctl --failed` (should be empty)

### Network Tests
- [ ] DNS resolution: `dig @localhost dns.ism.la +short` (should be 192.168.254.10)
- [ ] Local HTTP: `curl -I http://localhost:5678` (n8n)
- [ ] Local HTTP: `curl -I http://localhost:3000` (semaphore)
- [ ] HTTPS domains: `curl -I https://dns.ism.la`
- [ ] HTTPS domains: `curl -I https://n8n.ism.la`
- [ ] HTTPS domains: `curl -I https://smp.ism.la`

### Storage
- [ ] NFS export: `showmount -e localhost`
- [ ] /cluster-nas: `df -h /cluster-nas`
- [ ] Service data: `ls -la /cluster-nas/services/`

### External Access (from outside)
- [ ] DuckDNS: Check crtrcooperator.duckdns.org resolves
- [ ] HTTPS: `curl -I https://n8n.ism.la` (from external)

---

## Phase 6: User Environment (30 min)

- [ ] Install zsh: `sudo apt install -y zsh`
- [ ] Set shell: `chsh -s /bin/zsh`
- [ ] Install starship: `curl -sS https://starship.rs/install.sh | sh`
- [ ] Install chezmoi: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin`
- [ ] Restore dotfiles: `chezmoi init --apply` or copy from backup
- [ ] Install Atuin client: `bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)`
- [ ] Sync Atuin: `atuin login -u <username> && atuin sync`

---

## Phase 7: Final Validation (30 min)

- [ ] All services: `systemctl list-units --type=service --failed`
- [ ] All containers: `docker ps --filter "status=exited"`
- [ ] All domains test:
  ```bash
  for d in dns smp n8n ssh mng acn api dtb; do
    curl -I -k https://$d.ism.la 2>&1 | head -1;
  done
  ```
- [ ] Storage healthy: `df -h && lsblk`
- [ ] Check errors: `sudo journalctl -p err -b`
- [ ] CPU temp: `vcgencmd measure_temp`
- [ ] Memory: `free -h`
- [ ] Network: `ping -c 3 1.1.1.1 && ping -c 3 192.168.254.20`

---

## Post-Migration

- [ ] Update state/node.yml with new OS info
- [ ] Commit changes: `git commit -m "Migration complete: Debian → RPi OS"`
- [ ] Create USB backup: `sudo dd if=/dev/sdb of=/cluster-nas/backups/usb-$(date +%F).img bs=4M`
- [ ] Monitor for 24 hours
- [ ] Verify DuckDNS cron runs successfully
- [ ] Check all domains externally after 24 hours
- [ ] After 1 week: Mark migration complete

---

## Rollback Procedure (if needed)

1. **Shutdown**: `sudo shutdown -h now`
2. **Change boot order**: Enter BIOS, set SD card first
3. **Power on**: System boots from SD card
4. **Verify**: `lsblk` (root should be /dev/mmcblk0p2)
5. **Check services**: `systemctl status caddy docker`
6. **Back to normal**: Everything works as before

**Time to rollback**: 5 minutes
**Risk to data**: None (/cluster-nas unchanged)

---

## Emergency Contacts

- **SD Card UUID**: 519ae0e2-6045-40ab-b068-c4de3f7f7139
- **USB UUID**: 37d2cb52-513e-40e1-b90f-213aa6096cba
- **NVMe Label**: crtr-data
- **Static IP**: 192.168.254.10
- **DuckDNS Domain**: crtrcooperator.duckdns.org

---

## Success Criteria

**Minimum**:
- ✅ Boots from USB
- ✅ SSH works
- ✅ /cluster-nas mounted
- ✅ Caddy serving HTTPS

**Complete**:
- ✅ All services running
- ✅ All domains accessible
- ✅ No critical errors
- ✅ 24-hour uptime

---

**Status**: ⬜ Not Started | 🔄 In Progress | ✅ Complete

**Started**: ____________
**Completed**: ____________
**Notes**:
