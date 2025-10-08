# Generated Configuration Files

**DO NOT EDIT FILES IN THIS DIRECTORY MANUALLY**

All configuration files in this directory are **auto-generated** from state files using Jinja2 templates.

## How It Works

```
state/*.yml (edit)
  ↓
.meta/generation/*.j2 (templates)
  ↓
config/* (generated - this directory)
```

## Regenerating Configs

```bash
# Regenerate all configs
./scripts/generate/regenerate-all.sh

# Preview what would be generated (dry-run)
./scripts/generate/regenerate-all.sh --dry-run
```

## Generated Files

- **config/caddy/Caddyfile** - Generated from `state/domains.yml`
- **config/pihole/local-dns.conf** - Generated from `state/network.yml`
- **config/systemd/*.service** - Generated from `state/services.yml`
- **config/docker/*/docker-compose.yml** - Generated from `state/services.yml`

## Making Changes

**❌ Wrong**:
```bash
vim config/caddy/Caddyfile  # Manual edit - will be overwritten!
```

**✅ Right**:
```bash
vim state/domains.yml                    # Edit state
./scripts/generate/regenerate-all.sh     # Regenerate
git diff config/                         # Review changes
./deploy/deploy gateway                  # Deploy (when ready)
```

## Templates

Templates are located in `.meta/generation/`:
- `caddyfile.j2` - Caddy reverse proxy configuration
- `dns-overrides.j2` - Pi-hole local DNS overrides
- `systemd-unit.j2` - Systemd service units
- `docker-compose.j2` - Docker Compose files

## Workflow

1. Edit `state/*.yml` files
2. Validate: `./tests/test-state.sh`
3. Generate: `./scripts/generate/regenerate-all.sh`
4. Review: `git diff config/`
5. Deploy: `./deploy/deploy <target>`

See `.meta/ARCHITECTURE.md` for complete documentation.
