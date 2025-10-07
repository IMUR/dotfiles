# Caddy Reverse Proxy Configuration

**Live Config Location**: `/etc/caddy/Caddyfile`

## Current Configuration Reference

The live Caddyfile on cooperator manages all *.ism.la services.

### Configuration Snippets

Copy reference configurations here for version control.

### Making Changes

1. Edit `/etc/caddy/Caddyfile` directly on cooperator
2. Validate: `sudo caddy validate --config /etc/caddy/Caddyfile`
3. Reload: `sudo systemctl reload caddy`
4. Copy updated config here for reference

### Backup Strategy

Caddy configs are backed up automatically to `/etc/caddy/Caddyfile.backup.*` before changes.
