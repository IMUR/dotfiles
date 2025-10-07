# Systemd Aspect - Deployment Strategy

## Deployment

### Phase 1: Install Service Binaries
```bash
# Gateway services
apt install -y caddy nfs-kernel-server
curl -sSL https://install.pi-hole.net | bash
curl -fsSL https://get.docker.com | sh

# Custom service binaries
wget -O /usr/local/bin/atuin <atuin-url>
wget -O /usr/local/bin/semaphore <semaphore-url>
wget -O /usr/local/bin/gotty <gotty-url>
chmod +x /usr/local/bin/{atuin,semaphore,gotty}
```

### Phase 2: Deploy Unit Files
```bash
# Custom services
cp config/systemd/*.service /etc/systemd/system/
systemctl daemon-reload
```

### Phase 3: Enable Services
```bash
systemctl enable caddy pihole-FTL nfs-kernel-server docker
systemctl enable atuin-server semaphore gotty
```

### Phase 4: Start Services
```bash
systemctl start caddy pihole-FTL nfs-kernel-server docker
systemctl start atuin-server semaphore gotty
```

## Implementation

Service configurations in `/etc/systemd/system/`:
- atuin-server.service
- semaphore.service
- gotty.service

## Completion

```bash
# All services enabled
systemctl is-enabled caddy pihole-FTL nfs-kernel-server docker \
  atuin-server semaphore gotty

# All services active
systemctl is-active caddy pihole-FTL nfs-kernel-server docker \
  atuin-server semaphore gotty

# No failed services
systemctl --failed
```

## Persistence

- Services enabled via `systemctl enable` → Start on boot
- Unit files in `/etc/systemd/system/` → Persist across updates
- User services run as crtr → Access to user files

## Growth

### Add New Service
```bash
# Create unit file
cat > /etc/systemd/system/newservice.service <<EOF
[Unit]
Description=New Service
After=network.target

[Service]
Type=simple
User=crtr
ExecStart=/usr/local/bin/newservice
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Deploy
systemctl daemon-reload
systemctl enable newservice
systemctl start newservice
```

### Modify Existing Service
```bash
# Edit unit file
vim /etc/systemd/system/service.service

# Reload and restart
systemctl daemon-reload
systemctl restart service
```
